import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { LanguageClient } from 'vscode-languageclient/node';
import { MainOutput, ReportType } from '../global/outputs';
import { t } from '../i18n';
import { normalizeWindowsPath } from '../utils/paths';
import { createNetlistHandshake } from './handshake';

type NetlistMode = 'before' | 'after' | 'RTL';

interface NetlistLayoutConfig {
    nodeGap: number;
    layerGap: number;
    graphPadding: number;
    compoundPadding: number;
    portSpacing: number;
    alignmentTolerance: number;
    minimumSegment: number;
    lineNodeGap: number;
    lineLineGap: number;
    junctionSpacing: number;
    trunkEndpointDistance: number;
    junctionNodeGap: number;
    orthogonalityTolerance: number;
    shapeBufferDistance: number;
    idealNudgingDistance: number;
    segmentPenalty: number;
    crossingPenalty: number;
    feedbackPasses: number;
    deadlineMillis: number;
}

interface NetlistInvocationOptions {
    mode?: string;
    layout?: NetlistLayoutConfig;
}

interface NetlistRevision {
    workspaceEpoch: number;
    configGeneration: number;
    semanticRevision: number;
}

interface NetlistGraphDelta {
    schemaVersion: number;
    kind: 'full' | 'noop' | 'incremental';
    baseRevision?: NetlistRevision;
    nextRevision: NetlistRevision;
    baseInputHash?: string;
    nextInputHash: string;
    operations: Array<Record<string, unknown>>;
}

interface NetlistSceneStats {
    createdScenes: number;
    reusedScenes: number;
    reloadedScenes: number;
    movedShapes: number;
    updatedConnectors: number;
    deletedConnectors: number;
}

interface NetlistResponse {
    success: boolean;
    message: string;
    workspace: string;
    moduleName: string;
    filePath: string;
    mode: NetlistMode;
    outputDirectory: string;
    scriptPath: string;
    rtlilPath: string;
    jsonPath: string;
    renderPath: string;
    logPath: string;
    stdout: string;
    stderr: string;
    exitCode?: number;
    graphDigest: string;
    sourceFiles: string[];
    render?: unknown;
    delta?: NetlistGraphDelta;
    sceneStats?: NetlistSceneStats;
    revision?: NetlistRevision;
}

interface ArchitectureSelection {
    treeView?: unknown;
    path?: unknown;
    name?: unknown;
    file?: unknown;
}

interface NetlistResources {
    webuiRoot: vscode.Uri;
    indexUri: vscode.Uri;
    yosysWasmPath: string;
}

interface NetlistWebviewInput {
    yosysJson: Record<string, unknown>;
    sourceDigest: string;
    sourceLabel: string;
    constraints?: Record<string, Record<string, number>>;
}

export class NetlistPanelManager implements vscode.Disposable {
    private readonly panels = new Set<vscode.WebviewPanel>();
    private readonly commandSubscriptions: vscode.Disposable[] = [];

    constructor(
        private readonly context: vscode.ExtensionContext,
        private readonly client: LanguageClient,
    ) {}

    public get activePanelCount(): number {
        return this.panels.size;
    }

    public register(): void {
        this.commandSubscriptions.push(
            vscode.commands.registerCommand(
                'digital-ide.netlist.treeview',
                (value?: unknown) => this.openTreeNetlist(value),
            ),
            vscode.commands.registerCommand(
                'digital-ide.netlist.show',
                (
                    value?: vscode.Uri | string,
                    moduleName?: string,
                    options?: NetlistInvocationOptions,
                ) => this.openNetlist(value, moduleName, options),
            ),
        );
        this.context.subscriptions.push(...this.commandSubscriptions);
    }

    public dispose(): void {
        for (const panel of [...this.panels]) {
            panel.dispose();
        }
        this.panels.clear();
        for (const subscription of this.commandSubscriptions.splice(0)) {
            subscription.dispose();
        }
    }

    private async openTreeNetlist(value?: unknown): Promise<NetlistResponse> {
        const selection = architectureSelection(value);
        if (!selection) {
            throw new Error('Select an HDL module in the Architecture tree');
        }
        return this.openNetlist(selection.path, selection.name);
    }

    private async openNetlist(
        value?: vscode.Uri | string,
        moduleName?: string,
        options?: NetlistInvocationOptions,
    ): Promise<NetlistResponse> {
        const fileUri = value instanceof vscode.Uri
            ? value
            : typeof value === 'string'
                ? value.startsWith('file:') ? vscode.Uri.parse(value) : vscode.Uri.file(value)
                : vscode.window.activeTextEditor?.document.uri;
        if (!fileUri || !moduleName?.trim()) {
            throw new Error('Netlist requires an HDL source and module name');
        }
        const workspaceUri = vscode.workspace.getWorkspaceFolder(fileUri)?.uri
            ?? vscode.workspace.workspaceFolders?.[0]?.uri;
        if (!workspaceUri) {
            throw new Error('Netlist requires an open workspace folder');
        }
        const resources = netlistResources(this.context);
        const configuredMode = vscode.workspace
            .getConfiguration('digital-ide')
            .get<NetlistMode>('function.netlist.schema-mode', 'before');
        const mode = options?.mode ?? (
            ['before', 'after', 'RTL'].includes(configuredMode) ? configuredMode : 'before'
        );
        const response = await vscode.window.withProgress(
            {
                location: vscode.ProgressLocation.Notification,
                title: t('info.netlist.generate-network'),
                cancellable: false,
            },
            () => this.client.sendRequest<NetlistResponse>('digital/netlist', {
                workspaceUri: workspaceUri.toString(),
                fileUri: fileUri.toString(),
                wasmPath: resources.yosysWasmPath,
                moduleName: moduleName.trim(),
                mode,
                layout: options?.layout,
            }),
        );
        if (response.stdout) {
            MainOutput.report(response.stdout, { level: ReportType.PrintOuput });
        }
        if (response.stderr) {
            MainOutput.report(response.stderr, { level: ReportType.Error });
        }
        if (!response.success) {
            void vscode.window.showErrorMessage(response.message);
            throw new Error(response.message);
        }
        const yosysJson = readYosysJson(response);
        await this.openPanel(resources, response.moduleName, {
            yosysJson,
            sourceDigest: response.graphDigest,
            sourceLabel: path.basename(response.jsonPath),
            constraints: webviewConstraints(options?.layout),
        });
        return response;
    }

    private async openPanel(
        resources: NetlistResources,
        moduleName: string,
        input: NetlistWebviewInput,
    ): Promise<void> {
        const panel = vscode.window.createWebviewPanel(
            'digital-ide.netlistViewer',
            `Netlist: ${moduleName}`,
            vscode.ViewColumn.One,
            {
                enableScripts: true,
                retainContextWhenHidden: true,
                localResourceRoots: [resources.webuiRoot],
            },
        );
        panel.iconPath = {
            light: vscode.Uri.joinPath(this.context.extensionUri, 'images', 'svg', 'light', 'view.svg'),
            dark: vscode.Uri.joinPath(this.context.extensionUri, 'images', 'svg', 'dark', 'view.svg'),
        };
        this.panels.add(panel);
        const lifecycle = panel.onDidDispose(() => {
            lifecycle.dispose();
            this.panels.delete(panel);
            MainOutput.report(`Netlist panel closed: ${moduleName}`, { level: ReportType.Info });
        });
        try {
            await attachNetlistWebview(panel, resources, moduleName, input);
            MainOutput.report(`Netlist Webview ready: ${moduleName}`, { level: ReportType.Finish });
        } catch (error) {
            panel.dispose();
            MainOutput.report(`Netlist Webview failed: ${String(error)}`, { level: ReportType.Error });
            throw error;
        }
    }
}

export function registerNetlistCommands(
    context: vscode.ExtensionContext,
    client: LanguageClient,
): NetlistPanelManager {
    const manager = new NetlistPanelManager(context, client);
    manager.register();
    context.subscriptions.push(manager);
    return manager;
}

function architectureSelection(value: unknown): { path: string; name: string } | undefined {
    if (!value || typeof value !== 'object') {
        return undefined;
    }
    const candidate = value as ArchitectureSelection;
    if (candidate.file !== undefined) {
        return architectureSelection(candidate.file);
    }
    return candidate.treeView === 'architecture'
        && typeof candidate.path === 'string'
        && typeof candidate.name === 'string'
        ? { path: candidate.path, name: candidate.name }
        : undefined;
}

function netlistResources(context: vscode.ExtensionContext): NetlistResources {
    const webuiRoot = vscode.Uri.joinPath(context.extensionUri, 'resources', 'netlist');
    const indexUri = vscode.Uri.joinPath(webuiRoot, 'index.html');
    const kernelRoot = path.join(
        normalizeWindowsPath(context.extensionPath),
        'resources',
        'kernel',
    );
    const paths = {
        index: normalizeWindowsPath(indexUri.fsPath),
        yosys: path.join(kernelRoot, 'yosys.wasm'),
    };
    for (const [name, value] of Object.entries(paths)) {
        if (!fs.existsSync(value) || !fs.statSync(value).isFile()) {
            throw new Error(`Netlist ${name} publication is missing: ${value}. Run npm run build:netlist.`);
        }
    }
    return {
        webuiRoot,
        indexUri,
        yosysWasmPath: paths.yosys,
    };
}

async function attachNetlistWebview(
    panel: vscode.WebviewPanel,
    resources: NetlistResources,
    moduleName: string,
    input: NetlistWebviewInput,
): Promise<void> {
    const sessionId = crypto.randomBytes(24).toString('hex');
    const handshake = createNetlistHandshake(sessionId, stage => {
        MainOutput.report(`Netlist ${moduleName}: ${stage}`, { level: ReportType.Run });
    });
    const messages = panel.webview.onDidReceiveMessage(handshake.receive);
    const disposal = panel.onDidDispose(() => {
        handshake.cancel(new Error('Netlist Webview was closed before initialization completed'));
    });
    try {
        panel.webview.html = netlistHtml(panel.webview, resources.webuiRoot, resources.indexUri, {
            protocolVersion: 2,
            sessionId,
            assetBaseUri: `${panel.webview.asWebviewUri(resources.webuiRoot).toString().replace(/\/$/, '')}/`,
            moduleName,
            yosysJson: input.yosysJson,
            sourceDigest: input.sourceDigest,
            sourceLabel: input.sourceLabel,
            constraints: input.constraints,
        });
        MainOutput.report('Waiting for netlist Webview initialization.', { level: ReportType.Run });
        await handshake.ready;
    } catch (error) {
        handshake.cancel(error instanceof Error ? error : new Error(String(error)));
        await handshake.ready.catch(() => undefined);
        throw error;
    } finally {
        messages.dispose();
        disposal.dispose();
    }
}

export function netlistHtml(
    webview: vscode.Webview,
    resourceRoot: vscode.Uri,
    indexUri: vscode.Uri,
    bootstrap: Record<string, unknown>,
): string {
    const nonce = crypto.randomBytes(24).toString('base64');
    let html = fs.readFileSync(normalizeWindowsPath(indexUri.fsPath), 'utf8');
    html = html.replace(/<meta[^>]+http-equiv=["']Content-Security-Policy["'][^>]*>/gi, '');
    html = html.replace(/\b(src|href)=(["'])([^"']+)\2/gi, (match, attribute, quote, value) => {
        if (/^(?:[a-z]+:|#|\/\/)/i.test(value)) {
            return match;
        }
        const normalized = path.posix.normalize(value.replace(/^\.\//, '').replace(/^\//, ''));
        if (normalized.startsWith('../') || normalized === '..') {
            throw new Error(`Netlist asset escapes its publication root: ${value}`);
        }
        const resource = vscode.Uri.joinPath(resourceRoot, ...normalized.split('/'));
        return `${attribute}=${quote}${webview.asWebviewUri(resource).toString()}${quote}`;
    });
    html = html.replace(/<script\b(?![^>]*\bnonce=)/gi, `<script nonce="${nonce}"`);
    const serialized = JSON.stringify(bootstrap).replace(/</g, '\\u003c');
    const policy = [
        "default-src 'none'",
        `img-src ${webview.cspSource} data:`,
        `font-src ${webview.cspSource}`,
        `style-src ${webview.cspSource}`,
        `script-src 'nonce-${nonce}' 'wasm-unsafe-eval' 'unsafe-eval' ${webview.cspSource}`,
        `connect-src ${webview.cspSource}`,
        `worker-src ${webview.cspSource} blob:`,
        "object-src 'none'",
        "base-uri 'none'",
        "form-action 'none'",
    ].join('; ');
    const head = `<meta http-equiv="Content-Security-Policy" content="${policy}">\n`
        + `<script nonce="${nonce}">window.__DIGITAL_NETLIST_BOOTSTRAP__=${serialized};</script>`;
    return html.replace(/<head>/i, `<head>${head}`);
}

function readYosysJson(response: NetlistResponse): Record<string, unknown> {
    const jsonPath = normalizeWindowsPath(response.jsonPath);
    const outputDirectory = normalizeWindowsPath(response.outputDirectory);
    if (!path.isAbsolute(jsonPath) || !path.isAbsolute(outputDirectory)) {
        throw new Error('Digital Server returned a non-absolute Yosys JSON path');
    }
    const relative = path.relative(outputDirectory, jsonPath);
    if (!relative || relative.startsWith('..') || path.isAbsolute(relative)) {
        throw new Error('Digital Server returned a Yosys JSON path outside its output directory');
    }
    const stat = fs.statSync(jsonPath);
    if (!stat.isFile() || stat.size === 0 || stat.size > 64 * 1024 * 1024) {
        throw new Error('Digital Server returned an invalid Yosys JSON artifact');
    }
    let parsed: unknown;
    try {
        parsed = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    } catch (error) {
        throw new Error(`Digital Server returned malformed Yosys JSON: ${String(error)}`);
    }
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
        throw new Error('Digital Server returned a non-object Yosys JSON design');
    }
    const design = parsed as Record<string, unknown>;
    const modules = design.modules;
    if (!modules || typeof modules !== 'object' || Array.isArray(modules)
        || !(response.moduleName in modules)) {
        throw new Error(`Yosys JSON does not contain module ${response.moduleName}`);
    }
    return design;
}

function webviewConstraints(
    layout?: NetlistLayoutConfig,
): Record<string, Record<string, number>> | undefined {
    if (!layout) {
        return undefined;
    }
    return {
        placement: {
            nodeGap: layout.nodeGap,
            layerGap: layout.layerGap,
            graphPadding: layout.graphPadding,
            compoundPadding: layout.compoundPadding,
            portSpacing: layout.portSpacing,
            alignmentTolerance: layout.alignmentTolerance,
        },
        routing: {
            minimumSegment: layout.minimumSegment,
            lineNodeGap: layout.lineNodeGap,
            lineLineGap: layout.lineLineGap,
            junctionSpacing: layout.junctionSpacing,
            trunkEndpointDistance: layout.trunkEndpointDistance,
            junctionNodeGap: layout.junctionNodeGap,
            orthogonalityTolerance: layout.orthogonalityTolerance,
        },
        router: {
            shapeBufferDistance: layout.shapeBufferDistance,
            idealNudgingDistance: layout.idealNudgingDistance,
            segmentPenalty: layout.segmentPenalty,
            crossingPenalty: layout.crossingPenalty,
            feedbackPasses: layout.feedbackPasses,
        },
    };
}
