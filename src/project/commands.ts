import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import type { LanguageClient } from 'vscode-languageclient/node';
import { t } from '../i18n';
import { normalizeWindowsPath } from '../utils/paths';

export type ProjectAction =
    | 'read'
    | 'generateProperty'
    | 'overwriteProperty'
    | 'transformProperty'
    | 'clean'
    | 'convertXilinx'
    | 'setSrcTop'
    | 'setSimTop'
    | 'addFile'
    | 'delFile'
    | 'setLibraries'
    | 'generateInstance';

export interface ProjectCommandOptions {
    workspaceUri?: vscode.Uri | string;
    silent?: boolean;
    [key: string]: unknown;
}

export interface ProjectResponse {
    success: boolean;
    action: string;
    message: string;
    workspace: string;
    workspaceEpoch: number;
    configGeneration: number;
    property?: Record<string, unknown>;
    changes: string[];
    generatedText?: string;
    moduleName?: string;
    sourceUri?: string;
    sourceRange?: RawRange;
    targetUri?: string;
    targetVersion?: number;
}

interface RawPosition {
    line: number;
    character: number;
}

interface RawRange {
    start: RawPosition;
    end: RawPosition;
}

interface DesignArchitectureNode {
    id: string;
    label: string;
    name: string;
    instanceName?: string;
    kind: 'unit' | 'instance' | 'unresolved' | 'ambiguous' | 'cycle';
    description: string;
    sourceUri: string;
    sourceRange: RawRange;
    definitionUri: string;
    definitionRange?: RawRange;
    language?: 'systemverilog' | 'vhdl';
    projectType: string;
    resolution: string;
    children: DesignArchitectureNode[];
}

interface DesignArchitectureSnapshot {
    workspaceEpoch: number;
    configGeneration: number;
    semanticRevision: number;
    digest: string;
    files: string[];
    modules: Array<{
        id: string;
        name: string;
        path: string;
        language: string;
        projectType: string;
        dependencyCount: number;
        instances: string[];
    }>;
    roots: DesignArchitectureNode[];
    unresolvedInstances: string[];
    ambiguousInstances: string[];
}

export interface ArchitectureSnapshot {
    workspaceEpoch: number;
    configGeneration: number;
    semanticRevision: number;
    digest: string;
    files: string[];
    modules: Array<{
        id: string;
        name: string;
        path: string;
        kind: string;
        projectType: string;
        dependencyCount: number;
        instances: string[];
    }>;
    roots: DesignArchitectureNode[];
    unresolvedInstances: string[];
    ambiguousInstances: string[];
    libraries: { mode: string; common: string[]; custom: string[] };
}

export interface ProjectExtensionApi {
    refreshArchitecture(): Promise<ArchitectureSnapshot>;
    architectureRoots(): readonly ArchitectureTreeNode[];
    architectureTreeItem(node: ArchitectureTreeNode): vscode.TreeItem;
    hardwareRoots(): readonly ProjectNode[];
    hardwareTreeItem(node: ProjectNode): vscode.TreeItem;
    softwareRoots(): readonly ProjectNode[];
    softwareTreeItem(node: ProjectNode): vscode.TreeItem;
    staticTreeTrace(): readonly StaticTreeTraceEvent[];
}

export type StaticTreeName = 'hardware' | 'software';

export interface StaticTreeTraceEvent {
    readonly tree: StaticTreeName;
    readonly phase: 'constructed' | 'view-created' | 'visibility' | 'getChildren-enter'
        | 'getChildren-return' | 'getTreeItem';
    readonly wallTime: number;
    readonly monotonicTime: number;
    readonly detail?: string;
}

type NodeKind = 'group' | 'file' | 'module' | 'instance' | 'unresolved' | 'ambiguous' | 'cycle' | 'library' | 'command';

type ArchitectureRootType = 'src' | 'sim';
type CommandIcon = 'cmd' | 'toolBox' | 'branch';
type ArchitectureIcon =
    | 'src'
    | 'sim'
    | 'top'
    | 'current-src-top'
    | 'current-sim-top'
    | 'file'
    | 'verilog'
    | 'systemverilog'
    | 'vhdl'
    | 'remote'
    | 'cells'
    | 'File Error'
    | 'ip'
    | 'bd'
    | 'celllib';

export class ArchitectureTreeNode {
    readonly treeView = 'architecture';

    constructor(
        readonly id: string,
        public icon: ArchitectureIcon,
        readonly name: string,
        readonly type: string,
        readonly doFastFileType: 'common' | 'ip' | 'bd' | 'primitives' | undefined,
        readonly range: vscode.Range | undefined,
        readonly path: string | undefined,
        readonly parent: ArchitectureTreeNode | undefined,
        readonly children: ArchitectureTreeNode[],
        readonly dependencyCount = 0,
    ) {}
}

const architectureItemModes = new Set<ArchitectureIcon>([
    'vhdl',
    'systemverilog',
    'verilog',
    'remote',
    'cells',
]);

const architectureOtherModes = new Set<ArchitectureIcon>([
    'src',
    'sim',
    'File Error',
    'cells',
]);

export class ProjectNode {
    constructor(
        readonly id: string,
        readonly label: string,
        readonly kind: NodeKind,
        readonly children: ProjectNode[] = [],
        readonly uri?: vscode.Uri,
        readonly range?: vscode.Range,
        readonly command?: vscode.Command,
        readonly description?: string,
        readonly icon?: CommandIcon,
    ) {}
}

class ArchitectureProvider implements vscode.TreeDataProvider<ArchitectureTreeNode> {
    private readonly changed = new vscode.EventEmitter<ArchitectureTreeNode | undefined>();
    readonly onDidChangeTreeData = this.changed.event;
    private readonly firstTop: Partial<Record<ArchitectureRootType, { name: string; path?: string }>> = {};
    private readonly srcRootItem: ArchitectureTreeNode;
    private readonly simRootItem: ArchitectureTreeNode;
    private expansionMode: 'default' | 'expanded' | 'collapsed' = 'default';
    private renderGeneration = 0;
    private primitiveNames = new Set<string>();
    private current: ArchitectureSnapshot = {
        workspaceEpoch: 0,
        configGeneration: 0,
        semanticRevision: 0,
        digest: '',
        files: [],
        modules: [],
        roots: [],
        unresolvedInstances: [],
        ambiguousInstances: [],
        libraries: { mode: 'remote', common: [], custom: [] },
    };

    constructor(
        private readonly clientReady: Promise<LanguageClient>,
        private readonly extensionPath: string,
    ) {
        this.srcRootItem = new ArchitectureTreeNode(
            'architecture:src',
            'src',
            'src',
            'src',
            undefined,
            undefined,
            undefined,
            undefined,
            [],
        );
        this.simRootItem = new ArchitectureTreeNode(
            'architecture:sim',
            'sim',
            'sim',
            'sim',
            undefined,
            undefined,
            undefined,
            undefined,
            [],
        );
    }

    getTreeItem(node: ArchitectureTreeNode): vscode.TreeItem {
        const expandable = node.parent === undefined || node.children.length > 0;
        const state = !expandable
            ? vscode.TreeItemCollapsibleState.None
            : this.expansionMode === 'expanded'
                ? vscode.TreeItemCollapsibleState.Expanded
                : this.expansionMode === 'collapsed'
                    ? vscode.TreeItemCollapsibleState.Collapsed
                    : node.parent === undefined
                        ? vscode.TreeItemCollapsibleState.Expanded
                        : vscode.TreeItemCollapsibleState.Collapsed;
        const label = architectureItemModes.has(node.icon)
            ? `${node.type}(${node.name})`
            : node.name;
        const item = new vscode.TreeItem(label, state);
        item.id = `${this.renderGeneration}:${architectureNodeLineage(node)}`;
        item.contextValue = architectureOtherModes.has(node.icon) ? 'other' : 'file';
        item.tooltip = node.path || 'src';
        item.iconPath = {
            light: vscode.Uri.file(path.join(
                this.extensionPath,
                'images',
                'svg',
                'light',
                `${node.icon}.svg`,
            )),
            dark: vscode.Uri.file(path.join(
                this.extensionPath,
                'images',
                'svg',
                'dark',
                `${node.icon}.svg`,
            )),
        };
        item.command = {
            title: 'Open this HDL File',
            command: 'digital-ide.treeView.arch.openFile',
            arguments: [node.path, node.range, node],
        };
        return item;
    }

    getChildren(node?: ArchitectureTreeNode): ArchitectureTreeNode[] {
        return node?.children ?? [this.srcRootItem, this.simRootItem];
    }

    getParent(node: ArchitectureTreeNode): ArchitectureTreeNode | undefined {
        return node.parent;
    }

    rootNodes(): readonly ArchitectureTreeNode[] {
        return [this.srcRootItem, this.simRootItem];
    }

    moduleNames(): string[] {
        return this.current.modules.map(module => module.name);
    }

    setAllExpanded(expanded: boolean): number {
        this.expansionMode = expanded ? 'expanded' : 'collapsed';
        if (expanded) {
            // New item ids make Expanded an initial state instead of asking VS Code
            // to mutate every rendered row through reveal().
            this.renderGeneration += 1;
            this.changed.fire(undefined);
        }
        return countExpandableArchitectureNodes(this.rootNodes());
    }

    async refresh(workspaceUri?: vscode.Uri): Promise<ArchitectureSnapshot> {
        const client = await this.clientReady;
        const [design, project, primitiveNames] = await Promise.all([
            client.sendRequest<DesignArchitectureSnapshot>('digital/architecture', {
                workspaceUri: workspaceUri?.toString(),
            }),
            sendProjectRequest(client, 'read', {}, workspaceUri),
            client.sendRequest<string[]>('digital/primitives'),
        ]);
        this.primitiveNames = new Set(primitiveNames);
        const modules = design.modules
            .map(module => ({ ...module, kind: module.language }))
            .sort((left, right) => left.name.localeCompare(right.name));
        const property = project.property ?? {};
        const library = objectValue(property.library);
        const hardware = objectValue(library.hardware);
        const libraries = {
            mode: stringValue(library.state, 'remote'),
            common: stringArray(hardware.common),
            custom: stringArray(hardware.custom),
        };
        const moduleById = new Map(design.modules.map(module => [module.id, module]));
        const resolvedWorkspacePath = resolveWorkspaceUri(workspaceUri)?.fsPath;
        const workspacePath = normalizeWindowsPath(
            project.workspace || resolvedWorkspacePath || '',
        );
        const architecture = objectValue(property.arch);
        const configuredHardware = objectValue(architecture.hardware);
        const configuredSrc = stringValue(configuredHardware.src, '');
        const configuredSim = stringValue(configuredHardware.sim, '');
        const sharedRoot = configuredSrc.length > 0 && configuredSrc === configuredSim;
        const rootsWithModules = design.roots.map(root => ({ root, module: moduleById.get(root.id) }));
        const srcRoots = rootsWithModules.filter(({ module, root }) =>
            sharedRoot || (module?.projectType ?? root.projectType) !== 'sim');
        const simRoots = rootsWithModules.filter(({ module, root }) =>
            sharedRoot || (module?.projectType ?? root.projectType) === 'sim');
        this.replaceTopNodes(this.srcRootItem, 'src', srcRoots, workspacePath);
        this.replaceTopNodes(this.simRootItem, 'sim', simRoots, workspacePath);
        this.current = {
            workspaceEpoch: design.workspaceEpoch,
            configGeneration: design.configGeneration,
            semanticRevision: design.semanticRevision,
            digest: design.digest,
            files: design.files,
            modules,
            roots: design.roots,
            unresolvedInstances: design.unresolvedInstances,
            ambiguousInstances: design.ambiguousInstances,
            libraries,
        };
        this.changed.fire(this.simRootItem);
        this.changed.fire(this.srcRootItem);
        return this.current;
    }

    setFirstTop(type: ArchitectureRootType, node: ArchitectureTreeNode): void {
        this.firstTop[type] = { name: node.name, path: node.path };
        const root = type === 'src' ? this.srcRootItem : this.simRootItem;
        for (const child of root.children) {
            child.icon = topIcon(child.doFastFileType);
        }
        const selected = root.children.find(child =>
            child.name === node.name && child.path === node.path);
        if (selected) {
            selected.icon = type === 'src' ? 'current-src-top' : 'current-sim-top';
            root.children.splice(root.children.indexOf(selected), 1);
            root.children.unshift(selected);
        }
        this.changed.fire(root);
    }

    getItemType(node: ArchitectureTreeNode): ArchitectureRootType | undefined {
        let root = node;
        while (root.parent) {
            root = root.parent;
        }
        return root.name === 'src' || root.name === 'sim' ? root.name : undefined;
    }

    private replaceTopNodes(
        root: ArchitectureTreeNode,
        type: ArchitectureRootType,
        values: Array<{
            root: DesignArchitectureNode;
            module: DesignArchitectureSnapshot['modules'][number] | undefined;
        }>,
        workspacePath: string,
    ): void {
        const nodes = values
            .map(({ root: designRoot, module }) => architectureNode(
                designRoot,
                root,
                workspacePath,
                true,
                type,
                this.primitiveNames,
                module?.dependencyCount ?? 0,
            ))
            .sort((left, right) => left.name.localeCompare(right.name));
        root.children.splice(0, root.children.length, ...nodes);

        const remembered = this.firstTop[type];
        let selected = remembered
            ? nodes.find(node => node.name === remembered.name && node.path === remembered.path)
            : undefined;
        if (!selected) {
            delete this.firstTop[type];
            let maxDependencies = 0;
            for (const node of nodes) {
                if (node.dependencyCount > maxDependencies) {
                    maxDependencies = node.dependencyCount;
                    selected = node;
                }
            }
            if (selected) {
                this.firstTop[type] = { name: selected.name, path: selected.path };
            }
        }
        if (selected) {
            selected.icon = type === 'src' ? 'current-src-top' : 'current-sim-top';
            nodes.splice(nodes.indexOf(selected), 1);
            nodes.unshift(selected);
        }
        root.children.splice(0, root.children.length, ...nodes);
    }
}

class StaticTreeTrace {
    private readonly events: StaticTreeTraceEvent[] = [];

    record(
        tree: StaticTreeName,
        phase: StaticTreeTraceEvent['phase'],
        detail?: string,
    ): void {
        this.events.push({
            tree,
            phase,
            wallTime: Date.now(),
            monotonicTime: performance.now(),
            detail,
        });
    }

    snapshot(): readonly StaticTreeTraceEvent[] {
        return this.events.map(event => ({ ...event }));
    }
}

class CommandProvider implements vscode.TreeDataProvider<ProjectNode> {
    constructor(
        private readonly nodes: ProjectNode[],
        private readonly extensionPath?: string,
        private readonly contextValue?: string,
        private readonly trace?: StaticTreeTrace,
        private readonly tree?: StaticTreeName,
    ) {
        this.record('constructed', `${nodes.length}`);
    }

    getTreeItem(node: ProjectNode): vscode.TreeItem {
        this.record('getTreeItem', node.label);
        const state = node.children.length > 0
            ? vscode.TreeItemCollapsibleState.Collapsed
            : vscode.TreeItemCollapsibleState.None;
        const item = new vscode.TreeItem(node.label, state);
        item.contextValue = this.contextValue ?? node.kind;
        item.command = node.command;
        item.tooltip = node.description;
        item.iconPath = node.icon && this.extensionPath
            ? {
                light: vscode.Uri.file(path.join(
                    this.extensionPath,
                    'images',
                    'svg',
                    'light',
                    `${node.icon}.svg`,
                )),
                dark: vscode.Uri.file(path.join(
                    this.extensionPath,
                    'images',
                    'svg',
                    'dark',
                    `${node.icon}.svg`,
                )),
            }
            : new vscode.ThemeIcon('play');
        return item;
    }

    getChildren(node?: ProjectNode): ProjectNode[] {
        this.record('getChildren-enter', node?.label ?? '<root>');
        const children = node?.children ?? this.nodes;
        this.record('getChildren-return', `${node?.label ?? '<root>'}:${children.length}`);
        return children;
    }

    rootNodes(): readonly ProjectNode[] {
        return this.nodes;
    }

    private record(phase: StaticTreeTraceEvent['phase'], detail?: string): void {
        if (this.trace && this.tree) {
            this.trace.record(this.tree, phase, detail);
        }
    }
}

export function registerProjectCommands(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
): ProjectExtensionApi {
    const staticTrace = new StaticTreeTrace();
    const architecture = new ArchitectureProvider(clientReady, context.extensionPath);
    const architectureView = vscode.window.createTreeView('digital-ide-treeView-arch', {
        treeDataProvider: architecture,
    });
    const toolView = vscode.window.createTreeView('digital-ide-treeView-tool', {
        treeDataProvider: new CommandProvider([
            commandNode('tool:instance', 'Instantiate Module', 'digital-ide.tool.instance'),
            commandNode('tool:property', 'Create Project Configuration', 'digital-ide.property-json.generate'),
            commandNode('tool:clean', 'Clean Generated Files', 'digital-ide.tool.clean'),
        ]),
    });
    const hardware = new CommandProvider(
        hardwareCommandNodes(),
        context.extensionPath,
        'HARD',
        staticTrace,
        'hardware',
    );
    const hardwareView = vscode.window.createTreeView('digital-ide-treeView-hardware', {
        treeDataProvider: hardware,
    });
    staticTrace.record('hardware', 'view-created', String(hardwareView.visible));
    const software = new CommandProvider(
        softwareCommandNodes(),
        context.extensionPath,
        'SOFT',
        staticTrace,
        'software',
    );
    const softwareView = vscode.window.createTreeView('digital-ide-treeView-software', {
        treeDataProvider: software,
    });
    staticTrace.record('software', 'view-created', String(softwareView.visible));
    context.subscriptions.push(
        architectureView,
        toolView,
        hardwareView,
        softwareView,
        hardwareView.onDidChangeVisibility(event => {
            staticTrace.record('hardware', 'visibility', String(event.visible));
        }),
        softwareView.onDidChangeVisibility(event => {
            staticTrace.record('software', 'visibility', String(event.visible));
        }),
    );
    bindDesignGraphUpdates(context, clientReady, architecture);

    registerWithClient(context, clientReady, 'digital-ide.property-json.generate', runPropertyGenerate);
    registerWithClient(context, clientReady, 'digital-ide.property-json.overwrite',
        (client, options) => runProjectAction(client, 'overwriteProperty', options));
    registerWithClient(context, clientReady, 'digital-ide.lsp.tool.transformOldPropertyFile',
        (client, options) => runProjectAction(client, 'transformProperty', options));
    registerWithClient(context, clientReady, 'digital-ide.tool.clean',
        (client, options) => runPreviewableAction(client, 'clean', options));
    registerWithClient(context, clientReady, 'digital-ide.structure.from-xilinx-to-standard',
        (client, options) => runPreviewableAction(client, 'convertXilinx', options));
    registerWithClient(context, clientReady, 'digital-ide.pl.setSrcTop',
        (client, options) => setTop(client, architecture, 'setSrcTop', options));
    registerWithClient(context, clientReady, 'digital-ide.pl.setSimTop',
        (client, options) => setTop(client, architecture, 'setSimTop', options));
    registerWithClient(context, clientReady, 'digital-ide.pl.addFile',
        (client, options) => changeProjectFile(client, 'addFile', options));
    registerWithClient(context, clientReady, 'digital-ide.pl.delFile',
        (client, options) => changeProjectFile(client, 'delFile', options));
    registerWithClient(context, clientReady, 'digital-ide.pickLibrary',
        (client, options) => pickLibrary(client, architecture, options));
    register(context, 'digital-ide.treeView.arch.refresh', async options => architecture.refresh(resolveWorkspaceUri(options?.workspaceUri)));
    register(context, 'digital-ide.treeView.arch.expand', async () => {
        const expanded = await expandArchitectureTree(architectureView, architecture);
        await vscode.commands.executeCommand('setContext', 'TOOL-tree-expand', false);
        return expanded;
    });
    register(context, 'digital-ide.treeView.arch.collapse', async () => {
        architecture.setAllExpanded(false);
        await vscode.commands.executeCommand(
            'workbench.actions.treeView.digital-ide-treeView-arch.collapseAll',
        ).then(undefined, () => undefined);
        await vscode.commands.executeCommand('setContext', 'TOOL-tree-expand', true);
    });
    context.subscriptions.push(vscode.commands.registerCommand(
        'digital-ide.treeView.arch.openFile',
        (
            target?: ProjectCommandOptions | ArchitectureTreeNode | string,
            range?: vscode.Range,
            node?: ArchitectureTreeNode,
        ) => openArchitectureFile(target, range, node),
    ));
    register(context, 'digital-ide.lsp.tool.insertTextToUri', options => insertTextToUri(options));
    registerWithClient(context, clientReady, 'digital-ide.tool.instance',
        (client, options) => insertInstance(client, architecture, options));

    void vscode.commands.executeCommand('setContext', 'TOOL-tree-expand', false);
    void architecture.refresh().catch(() => undefined);
    return {
        refreshArchitecture: () => architecture.refresh(),
        architectureRoots: () => architecture.rootNodes(),
        architectureTreeItem: node => architecture.getTreeItem(node),
        hardwareRoots: () => hardware.rootNodes(),
        hardwareTreeItem: node => hardware.getTreeItem(node),
        softwareRoots: () => software.rootNodes(),
        softwareTreeItem: node => software.getTreeItem(node),
        staticTreeTrace: () => staticTrace.snapshot(),
    };
}

function bindDesignGraphUpdates(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
    architecture: ArchitectureProvider,
): void {
    let disposed = false;
    let notification: vscode.Disposable | undefined;
    context.subscriptions.push({
        dispose: () => {
            disposed = true;
            notification?.dispose();
        },
    });
    void clientReady.then(client => {
        if (disposed) {
            return;
        }
        notification = client.onNotification('custom/designGraphUpdated', () => {
            void architecture.refresh().catch(() => undefined);
        });
    }).catch(() => undefined);
}

async function expandArchitectureTree(
    view: vscode.TreeView<ArchitectureTreeNode>,
    provider: ArchitectureProvider,
): Promise<number> {
    const firstRoot = provider.rootNodes()[0];
    if (firstRoot) {
        await view.reveal(firstRoot, { select: false, focus: false, expand: false });
    }
    return provider.setAllExpanded(true);
}

function architectureNodeLineage(node: ArchitectureTreeNode): string {
    const lineage: string[] = [];
    let current: ArchitectureTreeNode | undefined = node;
    while (current) {
        lineage.push(current.id);
        current = current.parent;
    }
    return JSON.stringify(lineage.reverse());
}

function countExpandableArchitectureNodes(nodes: readonly ArchitectureTreeNode[]): number {
    let count = 0;
    for (const node of nodes) {
        if (node.children.length > 0) {
            count += 1;
            count += countExpandableArchitectureNodes(node.children);
        }
    }
    return count;
}

function register(
    context: vscode.ExtensionContext,
    command: string,
    handler: (options?: ProjectCommandOptions) => unknown,
): void {
    context.subscriptions.push(vscode.commands.registerCommand(command, handler));
}

function registerWithClient(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
    command: string,
    handler: (
        client: LanguageClient,
        options?: ProjectCommandOptions,
    ) => unknown,
): void {
    register(context, command, async options => handler(await clientReady, options));
}

async function runPropertyGenerate(
    client: LanguageClient,
    options?: ProjectCommandOptions,
): Promise<ProjectResponse> {
    if (options) {
        return runProjectAction(client, 'generateProperty', options);
    }
    const projectName = await vscode.window.showInputBox({
        title: 'Project Name',
        value: path.basename(resolveWorkspaceUri()?.fsPath ?? 'template'),
        validateInput: value => value.trim() ? undefined : 'Project name is required',
    });
    if (!projectName) {
        throw new Error('Project creation was cancelled');
    }
    const toolChain = await vscode.window.showQuickPick(['xilinx', 'efinity'], {
        title: 'Toolchain',
    });
    if (!toolChain) {
        throw new Error('Project creation was cancelled');
    }
    return runProjectAction(client, 'generateProperty', { projectName, toolChain });
}

async function runPreviewableAction(
    client: LanguageClient,
    action: 'clean' | 'convertXilinx',
    options?: ProjectCommandOptions,
): Promise<ProjectResponse> {
    if (typeof options?.apply === 'boolean') {
        return runProjectAction(client, action, options);
    }
    const preview = await runProjectAction(client, action, { ...options, apply: false, silent: true });
    if (preview.changes.length === 0) {
        return preview;
    }
    const choice = await vscode.window.showWarningMessage(
        preview.changes.join('\n'),
        { modal: true },
        action === 'clean' ? 'Clean' : 'Convert',
    );
    if (!choice) {
        return preview;
    }
    return runProjectAction(client, action, { ...options, apply: true });
}

async function setTop(
    client: LanguageClient,
    architecture: ArchitectureProvider,
    action: 'setSrcTop' | 'setSimTop',
    options?: ProjectCommandOptions | ArchitectureTreeNode,
): Promise<ProjectResponse> {
    const node = options instanceof ArchitectureTreeNode ? options : undefined;
    const commandOptions: ProjectCommandOptions | undefined =
        options instanceof ArchitectureTreeNode ? undefined : options;
    let top = node?.name
        ?? (typeof commandOptions?.top === 'string' ? commandOptions.top : undefined);
    if (!top) {
        const snapshot = await architecture.refresh(resolveWorkspaceUri(commandOptions?.workspaceUri));
        top = await vscode.window.showQuickPick(
            snapshot.modules.map(module => module.name),
            { title: action === 'setSrcTop' ? 'Select Design Top' : 'Select Simulation Top' },
        );
    }
    if (!top) {
        throw new Error('No module or entity was selected');
    }
    const response = await runProjectAction(client, action, { ...commandOptions, top });
    const treeType = action === 'setSrcTop' ? 'src' : 'sim';
    if (node && architecture.getItemType(node) === treeType) {
        architecture.setFirstTop(treeType, node);
    }
    return response;
}

async function changeProjectFile(
    client: LanguageClient,
    action: 'addFile' | 'delFile',
    options?: ProjectCommandOptions,
): Promise<ProjectResponse> {
    const requested = options?.path;
    let filePath = requested instanceof vscode.Uri
        ? normalizeWindowsPath(requested.fsPath)
        : typeof requested === 'string' ? normalizeWindowsPath(requested) : undefined;
    if (!filePath) {
        const activePath = vscode.window.activeTextEditor?.document.uri.fsPath;
        filePath = activePath ? normalizeWindowsPath(activePath) : undefined;
    }
    if (!filePath) {
        throw new Error('No HDL file was selected');
    }
    const kind = options?.kind === 'sim' ? 'sim' : 'src';
    return runProjectAction(client, action, { ...options, path: filePath, kind });
}

async function pickLibrary(
    client: LanguageClient,
    architecture: ArchitectureProvider,
    options?: ProjectCommandOptions,
): Promise<ProjectResponse> {
    let request = options;
    if (!request || (!Array.isArray(request.common) && !Array.isArray(request.custom))) {
        const selected = await vscode.window.showOpenDialog({
            canSelectFiles: false,
            canSelectFolders: true,
            canSelectMany: true,
            title: 'Select Custom HDL Libraries',
        });
        if (!selected) {
            throw new Error('Library selection was cancelled');
        }
        request = {
            ...options,
            mode: 'local',
            custom: selected.map(uri => normalizeWindowsPath(uri.fsPath)),
        };
    }
    const response = await runProjectAction(client, 'setLibraries', request);
    await architecture.refresh(resolveWorkspaceUri(request.workspaceUri));
    return response;
}

async function insertInstance(
    client: LanguageClient,
    architecture: ArchitectureProvider,
    options?: ProjectCommandOptions,
): Promise<ProjectResponse> {
    const targetUri = uriValue(options?.targetUri)
        ?? vscode.window.activeTextEditor?.document.uri;
    if (!targetUri) {
        throw new Error('Open a target HDL document before generating an instance');
    }
    const document = await vscode.workspace.openTextDocument(targetUri);
    let moduleName = typeof options?.moduleName === 'string' ? options.moduleName : undefined;
    if (!moduleName) {
        await architecture.refresh(resolveWorkspaceUri(options?.workspaceUri));
        moduleName = await vscode.window.showQuickPick(architecture.moduleNames(), {
            title: 'Select Module or Entity',
        });
    }
    if (!moduleName) {
        throw new Error('No module or entity was selected');
    }
    const response = await runProjectAction(client, 'generateInstance', {
        ...options,
        moduleName,
        targetUri: targetUri.toString(),
        expectedVersion: document.version,
    });
    if (!response.generatedText) {
        throw new Error('The server did not generate instance text');
    }
    await insertTextToUri({
        uri: targetUri,
        text: response.generatedText,
        expectedVersion: response.targetVersion,
        position: options?.position,
    });
    return response;
}

async function insertTextToUri(options?: ProjectCommandOptions): Promise<boolean> {
    const uri = uriValue(options?.uri);
    const text = typeof options?.text === 'string' ? options.text : undefined;
    if (!uri || text === undefined) {
        throw new Error('uri and text are required');
    }
    const document = await vscode.workspace.openTextDocument(uri);
    if (typeof options?.expectedVersion === 'number'
        && document.version !== options.expectedVersion) {
        throw new Error(
            `Target document version changed: expected ${options.expectedVersion}, current ${document.version}`,
        );
    }
    const editor = await vscode.window.showTextDocument(document, { preview: false });
    const position = rawPosition(options?.position)
        ?? (editor.document.uri.toString() === uri.toString() ? editor.selection.active : undefined)
        ?? new vscode.Position(document.lineCount, 0);
    const edit = new vscode.WorkspaceEdit();
    edit.insert(uri, position, text);
    const applied = await vscode.workspace.applyEdit(edit);
    if (!applied) {
        throw new Error(`Failed to insert generated text into ${normalizeWindowsPath(uri.fsPath)}`);
    }
    return true;
}

async function openArchitectureFile(
    target?: ProjectCommandOptions | ArchitectureTreeNode | string,
    requestedRange?: vscode.Range,
    requestedNode?: ArchitectureTreeNode,
): Promise<vscode.TextEditor | undefined> {
    const node = target instanceof ArchitectureTreeNode ? target : requestedNode;
    const options = target && typeof target === 'object' && !(target instanceof ArchitectureTreeNode)
        ? target as ProjectCommandOptions
        : undefined;
    const range = requestedRange
        ?? node?.range
        ?? rawRange(options?.range);
    if (!range) {
        return undefined;
    }
    const uri = typeof target === 'string'
        ? vscode.Uri.file(target)
        : node?.path
            ? vscode.Uri.file(node.path)
            : uriValue(options?.uri);
    if (!uri) {
        return undefined;
    }
    const filePath = normalizeWindowsPath(uri.fsPath);
    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
        if (node?.doFastFileType === 'ip') {
            return openXilinxIpDefinition(node);
        }
        return undefined;
    }
    const document = await vscode.workspace.openTextDocument(uri);
    return vscode.window.showTextDocument(document, { selection: range });
}

async function openXilinxIpDefinition(
    node: ArchitectureTreeNode,
): Promise<vscode.TextEditor | undefined> {
    if (!node.path) {
        return undefined;
    }
    const ipName = path.basename(node.path);
    const definitionPath = path.join(node.path, 'synth', `${ipName}.vhd`);
    if (!fs.existsSync(definitionPath)) {
        void vscode.window.showInformationMessage(t('info.treeview.ip-no-active.message'));
        return undefined;
    }
    const document = await vscode.workspace.openTextDocument(vscode.Uri.file(definitionPath));
    return vscode.window.showTextDocument(document, { selection: node.range });
}

async function runProjectAction(
    client: LanguageClient,
    action: ProjectAction,
    options?: ProjectCommandOptions,
): Promise<ProjectResponse> {
    const workspaceUri = resolveWorkspaceUri(options?.workspaceUri);
    if (!workspaceUri) {
        throw new Error('Digital IDE project commands require an open Workspace Folder');
    }
    const payload = { ...(options ?? {}) };
    delete payload.workspaceUri;
    delete payload.silent;
    const response = await sendProjectRequest(client, action, payload, workspaceUri);
    if (!response.success) {
        if (!options?.silent) {
            void vscode.window.showErrorMessage(response.message);
        }
        throw new Error(response.message);
    }
    if (!options?.silent && action !== 'read') {
        void vscode.window.showInformationMessage(response.message);
    }
    return response;
}

async function sendProjectRequest(
    client: LanguageClient,
    action: ProjectAction,
    payload: Record<string, unknown>,
    workspaceUri?: vscode.Uri,
): Promise<ProjectResponse> {
    return client.sendRequest<ProjectResponse>('digital/project', {
        action,
        workspaceUri: workspaceUri?.toString(),
        payload,
    });
}

function resolveWorkspaceUri(requested?: vscode.Uri | string): vscode.Uri | undefined {
    const parsed = uriValue(requested);
    if (parsed) {
        return parsed;
    }
    const active = vscode.window.activeTextEditor?.document.uri;
    return (active && vscode.workspace.getWorkspaceFolder(active)?.uri)
        ?? vscode.workspace.workspaceFolders?.[0]?.uri;
}

function uriValue(value: unknown): vscode.Uri | undefined {
    if (value instanceof vscode.Uri) {
        return value;
    }
    if (typeof value === 'string') {
        return vscode.Uri.parse(value);
    }
    return undefined;
}

function rawPosition(value: unknown): vscode.Position | undefined {
    if (!value || typeof value !== 'object') {
        return undefined;
    }
    const position = value as Partial<RawPosition>;
    return typeof position.line === 'number' && typeof position.character === 'number'
        ? new vscode.Position(position.line, position.character)
        : undefined;
}

function rawRange(value: unknown): vscode.Range | undefined {
    if (!value || typeof value !== 'object') {
        return undefined;
    }
    const range = value as Partial<RawRange>;
    const start = rawPosition(range.start);
    const end = rawPosition(range.end);
    return start && end ? new vscode.Range(start, end) : undefined;
}

function toRange(range?: RawRange): vscode.Range | undefined {
    return range
        ? new vscode.Range(
            range.start.line,
            range.start.character,
            range.end.line,
            range.end.character,
        )
        : undefined;
}

function architectureNode(
    node: DesignArchitectureNode,
    parent: ArchitectureTreeNode,
    workspacePath: string,
    isTop: boolean,
    rootType: ArchitectureRootType,
    primitiveNames: ReadonlySet<string>,
    dependencyCount = 0,
): ArchitectureTreeNode {
    const definitionPath = uriPath(node.definitionUri || (node.kind === 'unit' ? node.sourceUri : ''));
    const doFastFileType = architectureSourceKind(node.projectType);
    const presentationPath = doFastFileType === 'ip'
        ? xilinxIpFolder(definitionPath) ?? definitionPath
        : definitionPath;
    const name = isTop ? legacyTopName(node.name || node.label, node.language) : node.name || node.label;
    const icon = isTop
        ? topIcon(doFastFileType)
        : architectureInstanceIcon(
            node,
            definitionPath,
            workspacePath,
            doFastFileType,
            primitiveNames,
        );
    const item = new ArchitectureTreeNode(
        node.id,
        icon,
        name,
        isTop ? parent.name : node.instanceName || node.name || node.label,
        doFastFileType,
        toRange(node.definitionRange),
        presentationPath,
        parent,
        [],
        dependencyCount,
    );
    // IP wrappers are the public design boundary. Their generated implementation
    // hierarchy is not a user source tree and must not be rendered as ordinary
    // instances. A simulation root keeps every dependency in its elaborated
    // hierarchy, regardless of where the dependency definition is classified.
    if (doFastFileType !== 'ip') {
        const children = rootType === 'sim'
            ? node.children
            : node.children.filter(child => child.projectType !== 'sim');
        item.children.push(...children.map(child => architectureNode(
            child,
            item,
            workspacePath,
            false,
            rootType,
            primitiveNames,
        )));
    }
    return item;
}

function xilinxIpFolder(definitionPath: string | undefined): string | undefined {
    if (!definitionPath || path.basename(path.dirname(definitionPath)) !== 'synth') {
        return undefined;
    }
    const folder = path.dirname(path.dirname(definitionPath));
    return path.basename(definitionPath, path.extname(definitionPath)) === path.basename(folder)
        ? folder
        : undefined;
}

function legacyTopName(name: string, language: DesignArchitectureNode['language']): string {
    if (language !== 'vhdl') {
        return name;
    }
    return name.replace(/\[([^\[\]]+)\]$/, '($1)');
}

function architectureSourceKind(
    projectType: string,
): 'common' | 'ip' | 'bd' | 'primitives' | undefined {
    if (projectType === 'ip') {
        return 'ip';
    }
    if (projectType === 'bd' || projectType === 'bd_hdl') {
        return 'bd';
    }
    if (projectType === 'primitives') {
        return 'primitives';
    }
    return projectType ? 'common' : undefined;
}

function topIcon(
    doFastFileType: ArchitectureTreeNode['doFastFileType'],
): ArchitectureIcon {
    if (doFastFileType === 'ip') {
        return 'ip';
    }
    if (doFastFileType === 'bd') {
        return 'bd';
    }
    if (doFastFileType === 'primitives') {
        return 'celllib';
    }
    return 'top';
}

function architectureInstanceIcon(
    node: DesignArchitectureNode,
    definitionPath: string | undefined,
    workspacePath: string,
    doFastFileType: ArchitectureTreeNode['doFastFileType'],
    primitiveNames: ReadonlySet<string>,
): ArchitectureIcon {
    if (isArchitecturePrimitive(node.name, primitiveNames)) {
        return 'cells';
    }
    if (!definitionPath) {
        return 'File Error';
    }
    if (doFastFileType === 'ip') {
        return 'ip';
    }
    if (doFastFileType === 'bd') {
        return 'bd';
    }
    if (doFastFileType === 'primitives') {
        return 'celllib';
    }
    if (!pathIsInside(workspacePath, definitionPath)) {
        return 'remote';
    }
    if (node.language === 'vhdl') {
        return 'vhdl';
    }
    return ['.v', '.vh', '.vl'].includes(path.extname(definitionPath).toLowerCase())
        ? 'verilog'
        : 'systemverilog';
}

function isArchitecturePrimitive(name: string, primitiveNames: ReadonlySet<string>): boolean {
    return primitiveNames.has(name);
}

function uriPath(value: string): string | undefined {
    if (!value) {
        return undefined;
    }
    try {
        return normalizeWindowsPath(vscode.Uri.parse(value).fsPath);
    } catch {
        return undefined;
    }
}

function pathIsInside(workspacePath: string, candidate: string): boolean {
    if (!workspacePath) {
        return false;
    }
    const relative = path.relative(
        path.resolve(normalizeWindowsPath(workspacePath)),
        path.resolve(normalizeWindowsPath(candidate)),
    );
    return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
}

function commandNode(
    id: string,
    label: string,
    command: string,
    icon?: CommandIcon,
    description?: string,
    children: ProjectNode[] = [],
    commandArguments?: unknown[],
): ProjectNode {
    return new ProjectNode(
        id,
        label,
        'command',
        children,
        undefined,
        undefined,
        { command, title: command, arguments: commandArguments },
        description,
        icon,
    );
}

function hardwareCommandNodes(): ProjectNode[] {
    return [
        commandNode(
            'hardware:launch',
            'Launch',
            'digital-ide.hard.launch',
            'cmd',
            'Launch FPGA development assist function',
        ),
        commandNode(
            'hardware:simulate',
            'Simulate',
            'digital-ide.hard.simulate',
            'toolBox',
            'Launch the manufacturer Simulation',
            [
                commandNode(
                    'hardware:simulate:cli',
                    'CLI',
                    'digital-ide.hard.simulate.cli',
                    'branch',
                    'Launch the manufacturer Simulation in CLI',
                ),
                commandNode(
                    'hardware:simulate:gui',
                    'GUI',
                    'digital-ide.hard.simulate.gui',
                    'branch',
                    'Launch the manufacturer Simulation in GUI',
                ),
            ],
        ),
        commandNode(
            'hardware:refresh',
            'Refresh',
            'digital-ide.hard.refresh',
            'cmd',
            'Refresh the current project file',
        ),
        commandNode(
            'hardware:build',
            'Build',
            'digital-ide.hard.build',
            'toolBox',
            'Build the current fpga project',
            [
                commandNode(
                    'hardware:build:synth',
                    'Synth',
                    'digital-ide.hard.build.synth',
                    'branch',
                    'Synth the current project',
                ),
                commandNode(
                    'hardware:build:impl',
                    'Impl',
                    'digital-ide.hard.build.impl',
                    'branch',
                    'Impl the current project',
                ),
                commandNode(
                    'hardware:build:bitstream',
                    'BitStream',
                    'digital-ide.hard.build.bitstream',
                    'branch',
                    'Generate the BIT File',
                ),
            ],
        ),
        new ProjectNode(
            'hardware:program',
            'Program',
            'group',
            [
                commandNode(
                    'hardware:program:sram',
                    'SRAM',
                    'digital-ide.hard.program.sram',
                    'branch',
                    'Download the bitstream into FPGA SRAM',
                ),
                commandNode(
                    'hardware:program:flash',
                    'FLASH',
                    'digital-ide.hard.program.flash',
                    'branch',
                    'Program the persistent FPGA configuration Flash',
                ),
            ],
            undefined,
            undefined,
            undefined,
            'Program the FPGA SRAM or configuration Flash',
            'toolBox',
        ),
        commandNode(
            'hardware:gui',
            'GUI',
            'digital-ide.hard.gui',
            'cmd',
            'Open the GUI',
        ),
        commandNode(
            'hardware:exit',
            'Exit',
            'digital-ide.hard.exit',
            'cmd',
            'Exit the current project',
        ),
    ];
}

function softwareCommandNodes(): ProjectNode[] {
    return [
        commandNode(
            'software:launch',
            'Launch',
            'digital-ide.soft.launch',
            'cmd',
            'Launch SDK development assist function',
        ),
        commandNode(
            'software:build',
            'Build',
            'digital-ide.soft.build',
            'cmd',
            'Build the current SDK project',
        ),
        commandNode(
            'software:select-elf',
            'Select ELF',
            'digital-ide.soft.selectElf',
            'cmd',
            'Select and remember an ELF for the active processor target',
        ),
        processorCommandGroup(
            'zynq-7000',
            'Zynq-7000',
            ['zynq7000Arm'],
        ),
        processorCommandGroup(
            'zynqmp',
            'Zynq UltraScale+ MPSoC',
            ['zynqMpAarch64', 'zynqMpArmR5'],
        ),
        processorCommandGroup(
            'microblaze',
            'MicroBlaze',
            ['microBlaze', 'microBlaze64'],
        ),
        commandNode(
            'software:gdb',
            'GDB Server',
            'digital-ide.soft.gdb.start',
            'toolBox',
            'Manage the Xilinx PS GDB server and VS Code debug configuration',
            [
                commandNode(
                    'software:gdb:start',
                    'Start and Prepare',
                    'digital-ide.soft.gdb.start',
                    'branch',
                    'Start the Xilinx GDB server and generate a debug configuration',
                ),
                commandNode(
                    'software:gdb:config',
                    'Generate Configuration',
                    'digital-ide.soft.gdb.generateConfig',
                    'branch',
                    'Generate or update the selected processor debug configuration',
                ),
                commandNode(
                    'software:gdb:stop',
                    'Stop Managed Server',
                    'digital-ide.soft.gdb.stop',
                    'branch',
                    'Stop only the hw_server process managed by Digital IDE',
                ),
            ],
        ),
    ];
}

function processorCommandGroup(
    id: string,
    label: string,
    processorKinds: string[],
): ProjectNode {
    const options = { processorKinds };
    return commandNode(
        `software:processor:${id}`,
        label,
        'digital-ide.soft.selectElf',
        'toolBox',
        `Manage downloads and execution state for ${label} processors`,
        [
            commandNode(
                `software:processor:${id}:download`,
                'Download and Run',
                'digital-ide.soft.download',
                'branch',
                'Download the selected ELF and continue execution',
                [],
                [options],
            ),
            commandNode(
                `software:processor:${id}:reset`,
                'Reset',
                'digital-ide.soft.reset',
                'branch',
                'Reset the selected processor and leave it stopped',
                [],
                [options],
            ),
            commandNode(
                `software:processor:${id}:halt`,
                'Halt',
                'digital-ide.soft.halt',
                'branch',
                'Halt the selected processor',
                [],
                [options],
            ),
            commandNode(
                `software:processor:${id}:run`,
                'Run',
                'digital-ide.soft.run',
                'branch',
                'Continue the selected processor',
                [],
                [options],
            ),
            commandNode(
                `software:processor:${id}:stop`,
                'Stop',
                'digital-ide.soft.stop',
                'branch',
                'Stop the selected processor',
                [],
                [options],
            ),
            commandNode(
                `software:processor:${id}:status`,
                'Status',
                'digital-ide.soft.status',
                'branch',
                'Read the selected processor execution state',
                [],
                [options],
            ),
        ],
        [options],
    );
}

function iconForNode(kind: NodeKind): string {
    switch (kind) {
        case 'group': return 'folder';
        case 'file': return 'file-code';
        case 'module': return 'symbol-class';
        case 'instance': return 'symbol-field';
        case 'unresolved': return 'question';
        case 'ambiguous': return 'warning';
        case 'cycle': return 'sync';
        case 'library': return 'library';
        case 'command': return 'play';
    }
}

function objectValue(value: unknown): Record<string, unknown> {
    return value && typeof value === 'object' && !Array.isArray(value)
        ? value as Record<string, unknown>
        : {};
}

function stringValue(value: unknown, fallback: string): string {
    return typeof value === 'string' ? value : fallback;
}

function stringArray(value: unknown): string[] {
    return Array.isArray(value)
        ? value.filter((item): item is string => typeof item === 'string')
        : [];
}
