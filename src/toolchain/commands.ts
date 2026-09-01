import * as vscode from 'vscode';
import * as path from 'path';
import type { LanguageClient } from 'vscode-languageclient/node';
import {
    classifyLogLevel,
    HardwareErrorOutput,
    HardwareOutput,
    MainOutput,
    Output,
    ReportType,
} from '../global/outputs';
import { normalizeWindowsPath } from '../utils/paths';

export type HardwareAction =
    | 'launch'
    | 'simulate'
    | 'simulateCli'
    | 'simulateGui'
    | 'refresh'
    | 'build'
    | 'synth'
    | 'impl'
    | 'bitstream'
    | 'program'
    | 'programFlash'
    | 'gui'
    | 'exit';

export type SoftwareAction =
    | 'launch'
    | 'build'
    | 'download'
    | 'reset'
    | 'halt'
    | 'run'
    | 'stop'
    | 'status'
    | 'gdbStart'
    | 'gdbStop';

export type XilinxProcessorKind =
    | 'zynq7000Arm'
    | 'zynqMpAarch64'
    | 'zynqMpArmR5'
    | 'microBlaze'
    | 'microBlaze64';

export interface PsTargetSelection {
    appName?: string;
    elfPath?: string;
    programBitstream: boolean;
}

export interface PsTargetDescriptor {
    appName: string;
    appTemplate: string;
    processor: string;
    processorKind: XilinxProcessorKind;
    elfPath: string;
    elfExists: boolean;
    bitstreamPath?: string;
    bitstreamExists: boolean;
    bitstreamRequired: boolean;
    gdbPath: string;
    gdbExists: boolean;
    gdbHost: string;
    gdbPort: number;
}

export interface PsTargetInventory {
    targets: PsTargetDescriptor[];
    runtime: {
        execution: 'disconnected' | 'unknown' | 'running' | 'stopped';
        processor?: string;
        processorKind?: XilinxProcessorKind;
        appName?: string;
        elfPath?: string;
        lastAction?: string;
        message: string;
    };
    gdbServer: {
        status: 'stopped' | 'starting' | 'runningOwned' | 'runningExternal' | 'failed';
        host: string;
        hwServerPort: number;
        gdbPortBase: number;
        ownedProcessId?: number;
        message: string;
    };
}

export interface ToolchainArtifact {
    kind: string;
    path: string;
}

export interface ToolchainReport {
    taskId: number;
    vendor: string;
    domain: string;
    action: string;
    status: string;
    success: boolean;
    dryRun: boolean;
    message: string;
    stdout: string;
    stderr: string;
    exitCode?: number;
    elapsedMs: number;
    artifacts: ToolchainArtifact[];
}

export interface ToolchainProgressEvent {
    requestId: string;
    taskId: number;
    phase: string;
    stream: 'status' | 'stdout' | 'stderr';
    message: string;
}

export interface ToolchainUserMessage {
    kind: 'success' | 'error' | 'cancelled';
    message: string;
}

export interface ToolchainCommandOptions {
    dryRun?: boolean;
    workspaceUri?: vscode.Uri | string;
    cancellationToken?: vscode.CancellationToken;
    silent?: boolean;
    target?: PsTargetSelection;
    processorKinds?: XilinxProcessorKind[];
    programBitstream?: boolean;
}

interface ActiveToolchainTask {
    progress: vscode.Progress<{ message?: string; increment?: number }>;
    receivedOutput: boolean;
    hardware: boolean;
}

const activeTasks = new Map<string, ActiveToolchainTask>();
const toolchainProgressNotification = 'digital/toolchainProgress';
const progressEmitter = new vscode.EventEmitter<ToolchainProgressEvent>();
const outputEmitter = new vscode.EventEmitter<ToolchainProgressEvent>();
const userMessageEmitter = new vscode.EventEmitter<ToolchainUserMessage>();
let nextRequestId = 1;

export const onDidReceiveToolchainProgress = progressEmitter.event;
export const onDidWriteToolchainOutput = outputEmitter.event;
export const onDidShowToolchainMessage = userMessageEmitter.event;

const hardwareCommands: ReadonlyArray<[string, HardwareAction]> = [
    ['digital-ide.hard.launch', 'launch'],
    ['digital-ide.hard.simulate', 'simulate'],
    ['digital-ide.hard.simulate.cli', 'simulateCli'],
    ['digital-ide.hard.simulate.gui', 'simulateGui'],
    ['digital-ide.hard.refresh', 'refresh'],
    ['digital-ide.hard.build', 'build'],
    ['digital-ide.hard.build.synth', 'synth'],
    ['digital-ide.hard.build.impl', 'impl'],
    ['digital-ide.hard.build.bitstream', 'bitstream'],
    ['digital-ide.hard.program', 'program'],
    ['digital-ide.hard.program.sram', 'program'],
    ['digital-ide.hard.program.flash', 'programFlash'],
    ['digital-ide.hard.gui', 'gui'],
    ['digital-ide.hard.exit', 'exit'],
];

const simpleSoftwareCommands: ReadonlyArray<[string, SoftwareAction]> = [
    ['digital-ide.soft.launch', 'launch'],
    ['digital-ide.soft.build', 'build'],
    ['digital-ide.soft.gdb.stop', 'gdbStop'],
];

const targetedSoftwareCommands: ReadonlyArray<[string, SoftwareAction, boolean]> = [
    ['digital-ide.soft.download', 'download', true],
    ['digital-ide.soft.reset', 'reset', false],
    ['digital-ide.soft.halt', 'halt', false],
    ['digital-ide.soft.run', 'run', false],
    ['digital-ide.soft.stop', 'stop', false],
    ['digital-ide.soft.status', 'status', false],
    ['digital-ide.soft.gdb.start', 'gdbStart', true],
];

export function registerToolchainCommands(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
): void {
    context.subscriptions.push(
        progressEmitter,
        outputEmitter,
        userMessageEmitter,
    );
    bindProgressNotifications(context, clientReady);
    for (const [command, action] of hardwareCommands) {
        context.subscriptions.push(vscode.commands.registerCommand(
            command,
            (options?: ToolchainCommandOptions) => runToolchainCommand(
                clientReady,
                'digital/hardware',
                action,
                options,
            ),
        ));
    }
    for (const [command, action] of simpleSoftwareCommands) {
        context.subscriptions.push(vscode.commands.registerCommand(
            command,
            (options?: ToolchainCommandOptions) => runToolchainCommand(
                clientReady,
                'digital/software',
                action,
                options,
            ),
        ));
    }
    for (const [command, action, selectElf] of targetedSoftwareCommands) {
        context.subscriptions.push(vscode.commands.registerCommand(
            command,
            (options?: ToolchainCommandOptions) => runPsToolchainCommand(
                context,
                clientReady,
                action,
                selectElf,
                options,
            ),
        ));
    }
    context.subscriptions.push(
        vscode.commands.registerCommand(
            'digital-ide.soft.selectElf',
            (options?: ToolchainCommandOptions) => selectPsElf(
                context,
                clientReady,
                options,
            ),
        ),
        vscode.commands.registerCommand(
            'digital-ide.soft.gdb.generateConfig',
            (options?: ToolchainCommandOptions) => generatePsGdbConfiguration(
                context,
                clientReady,
                options,
            ),
        ),
    );
    HardwareOutput.report('HARD Option commands and hardware log routing registered.', {
        level: ReportType.Info,
    });
}

function bindProgressNotifications(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
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
        const onNotification = client.onNotification.bind(client) as unknown as (
            method: string,
            handler: (event: ToolchainProgressEvent) => void,
        ) => vscode.Disposable;
        notification = onNotification(
            toolchainProgressNotification,
            event => handleProgressEvent(event),
        );
    }).catch(error => MainOutput.report(
        `Unable to register toolchain progress notifications: ${String(error)}`,
        { level: ReportType.Error },
    ));
}

async function runToolchainCommand(
    clientReady: Promise<LanguageClient>,
    method: 'digital/hardware' | 'digital/software',
    action: HardwareAction | SoftwareAction,
    options?: ToolchainCommandOptions,
): Promise<ToolchainReport> {
    const hardware = method === 'digital/hardware';
    const output = hardware ? HardwareOutput : MainOutput;
    const errorOutput = hardware ? HardwareErrorOutput : MainOutput;
    const domain = hardware ? 'Hardware' : 'Software';
    const workspaceUri = resolveWorkspaceUri(options?.workspaceUri);
    if (!workspaceUri) {
        const message = 'Digital IDE toolchain commands require an open workspace folder.';
        errorOutput.report(message, { level: ReportType.Error });
        errorOutput.show();
        void vscode.window.showErrorMessage(message);
        throw new Error(message);
    }

    const requestId = createRequestId(domain, action);
    const workspacePath = normalizeWindowsPath(workspaceUri.fsPath);
    output.report(
        `[request ${requestId}] ${domain}/${action} requested for ${workspacePath}.`,
        { level: ReportType.Launch },
    );
    let client: LanguageClient;
    try {
        client = await clientReady;
    } catch (error) {
        errorOutput.report(
            `[request ${requestId}] Digital Server is unavailable: ${String(error)}`,
            { level: ReportType.Error },
        );
        errorOutput.show();
        throw error;
    }
    return vscode.window.withProgress(
        {
            location: vscode.ProgressLocation.Notification,
            title: `${domain}: ${action}`,
            cancellable: true,
        },
        async (progress, progressCancellation) => {
            const active: ActiveToolchainTask = { progress, receivedOutput: false, hardware };
            activeTasks.set(requestId, active);
            progress.report({ message: workspacePath });
            output.report(`[request ${requestId}] ${domain}/${action} started.`, {
                level: ReportType.Run,
            });
            let cancellationSent = false;
            const cancel = (): void => {
                if (cancellationSent) {
                    return;
                }
                cancellationSent = true;
                progress.report({ message: 'Cancelling...' });
                output.report(`[request ${requestId}] Cancellation requested.`, {
                    level: ReportType.Warn,
                });
                void client.sendRequest('digital/cancelToolchain', { requestId });
            };
            const progressCancellationDisposable = progressCancellation.onCancellationRequested(cancel);
            const externalCancellationDisposable = options?.cancellationToken
                ?.onCancellationRequested(cancel);
            if (options?.cancellationToken?.isCancellationRequested) {
                cancel();
            }
            try {
                let report: ToolchainReport;
                try {
                    report = await client.sendRequest<ToolchainReport>(method, {
                        action,
                        requestId,
                        dryRun: options?.dryRun ?? false,
                        workspaceUri: workspaceUri.toString(),
                        target: options?.target,
                    });
                } catch (error) {
                    errorOutput.report(
                        `[request ${requestId}] ${domain}/${action} request failed: ${String(error)}`,
                        { level: ReportType.Error },
                    );
                    errorOutput.show();
                    throw error;
                }
                writeReport(report, active.receivedOutput, output, errorOutput);
                if (report.status === 'cancelled') {
                    showUserMessage('cancelled', report.message, options?.silent ?? false);
                    return report;
                }
                if (!report.success) {
                    errorOutput.show();
                    showUserMessage('error', report.message, options?.silent ?? false);
                    throw new Error(report.message);
                }
                showUserMessage('success', report.message, options?.silent ?? false);
                return report;
            } finally {
                progressCancellationDisposable.dispose();
                externalCancellationDisposable?.dispose();
                activeTasks.delete(requestId);
            }
        },
    );
}

interface ResolvedPsTarget {
    inventory: PsTargetInventory;
    descriptor: PsTargetDescriptor;
    selection: PsTargetSelection;
}

interface PsTargetQuickPickItem extends vscode.QuickPickItem {
    target?: PsTargetDescriptor;
}

async function runPsToolchainCommand(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
    action: SoftwareAction,
    selectElf: boolean,
    options?: ToolchainCommandOptions,
): Promise<ToolchainReport> {
    if (options?.dryRun && !options.target) {
        return runToolchainCommand(clientReady, 'digital/software', action, options);
    }
    const resolved = await resolvePsTarget(
        context,
        clientReady,
        selectElf,
        false,
        options,
    );
    const report = await runToolchainCommand(clientReady, 'digital/software', action, {
        ...options,
        workspaceUri: resolvedWorkspaceUri(options?.workspaceUri),
        target: resolved.selection,
    });
    if (action === 'gdbStart') {
        await writePsGdbConfiguration(
            resolvedWorkspaceUri(options?.workspaceUri),
            resolved.descriptor,
            resolved.selection,
            options?.silent ?? false,
        );
    }
    return report;
}

async function selectPsElf(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
    options?: ToolchainCommandOptions,
): Promise<PsTargetSelection> {
    const resolved = await resolvePsTarget(context, clientReady, true, true, options);
    if (!(options?.silent ?? false)) {
        void vscode.window.showInformationMessage(
            `Selected ${path.basename(resolved.selection.elfPath ?? '')} for ${resolved.descriptor.processor}.`,
        );
    }
    return resolved.selection;
}

async function generatePsGdbConfiguration(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
    options?: ToolchainCommandOptions,
): Promise<vscode.DebugConfiguration> {
    const resolved = await resolvePsTarget(context, clientReady, true, false, options);
    return writePsGdbConfiguration(
        resolvedWorkspaceUri(options?.workspaceUri),
        resolved.descriptor,
        resolved.selection,
        options?.silent ?? false,
    );
}

async function resolvePsTarget(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
    selectElf: boolean,
    forcePrompt: boolean,
    options?: ToolchainCommandOptions,
): Promise<ResolvedPsTarget> {
    const workspaceUri = resolvedWorkspaceUri(options?.workspaceUri);
    const client = await clientReady;
    const inventory = await client.sendRequest<PsTargetInventory>('digital/softwareTargets', {
        workspaceUri: workspaceUri.toString(),
    });
    const allowedKinds = new Set(options?.processorKinds ?? []);
    const targets = inventory.targets.filter(target =>
        allowedKinds.size === 0 || allowedKinds.has(target.processorKind));
    if (targets.length === 0) {
        const scope = allowedKinds.size === 0
            ? 'this workspace'
            : [...allowedKinds].map(processorKindLabel).join(', ');
        throw new Error(`No Xilinx PS targets are available for ${scope}.`);
    }

    const requested = options?.target;
    if (requested) {
        const descriptor = descriptorForSelection(targets, requested);
        if (!descriptor) {
            throw new Error('The requested ELF target is not present in this workspace.');
        }
        const selection = normalizeSelection(descriptor, requested, options?.programBitstream);
        await rememberPsSelection(context, workspaceUri, selection);
        return { inventory, descriptor, selection };
    }

    if (!forcePrompt) {
        const remembered = context.workspaceState.get<PsTargetSelection>(psSelectionKey(workspaceUri));
        const descriptor = remembered && descriptorForSelection(targets, remembered);
        if (descriptor && (!selectElf || isElfPath(remembered?.elfPath))) {
            return { inventory, descriptor, selection: normalizeSelection(descriptor, remembered) };
        }
    }

    const descriptor = await pickPsTarget(targets);
    const elfPath = selectElf ? await pickElf(descriptor, workspaceUri) : descriptor.elfPath;
    const programBitstream = selectElf
        ? await pickBitstreamMode(descriptor, options?.programBitstream)
        : descriptor.bitstreamRequired;
    const selection: PsTargetSelection = {
        appName: descriptor.appName,
        elfPath,
        programBitstream,
    };
    await rememberPsSelection(context, workspaceUri, selection);
    return { inventory, descriptor, selection };
}

function descriptorForSelection(
    targets: readonly PsTargetDescriptor[],
    selection: PsTargetSelection,
): PsTargetDescriptor | undefined {
    if (selection.appName) {
        return targets.find(target => target.appName === selection.appName);
    }
    return targets.find(target => target.elfPath === selection.elfPath);
}

function normalizeSelection(
    descriptor: PsTargetDescriptor,
    selection: PsTargetSelection,
    programBitstream?: boolean,
): PsTargetSelection {
    const elfPath = selection.elfPath ?? descriptor.elfPath;
    if (!isElfPath(elfPath)) {
        throw new Error(`Selected program is not an ELF file: ${elfPath}`);
    }
    return {
        appName: descriptor.appName,
        elfPath,
        programBitstream: descriptor.bitstreamRequired
            || programBitstream
            || selection.programBitstream,
    };
}

async function pickPsTarget(
    targets: readonly PsTargetDescriptor[],
): Promise<PsTargetDescriptor> {
    const groups: ReadonlyArray<[string, XilinxProcessorKind[]]> = [
        ['Zynq-7000', ['zynq7000Arm']],
        ['Zynq UltraScale+ MPSoC', ['zynqMpAarch64', 'zynqMpArmR5']],
        ['MicroBlaze', ['microBlaze', 'microBlaze64']],
    ];
    const items: PsTargetQuickPickItem[] = [];
    for (const [label, kinds] of groups) {
        const grouped = targets.filter(target => kinds.includes(target.processorKind));
        if (grouped.length === 0) {
            continue;
        }
        items.push({ label, kind: vscode.QuickPickItemKind.Separator });
        for (const target of grouped) {
            items.push({
                label: target.appName,
                description: `${target.processor} (${processorKindLabel(target.processorKind)})`,
                detail: `${target.elfExists ? 'ELF' : 'Missing ELF'}: ${target.elfPath}`,
                target,
            });
        }
    }
    const picked = await vscode.window.showQuickPick(items, {
        title: 'Select Xilinx Processor and Application',
        placeHolder: 'Targets are grouped by processor family',
        matchOnDescription: true,
        matchOnDetail: true,
    });
    if (!picked?.target) {
        throw new Error('No Xilinx processor target was selected.');
    }
    return picked.target;
}

async function pickElf(
    descriptor: PsTargetDescriptor,
    workspaceUri: vscode.Uri,
): Promise<string> {
    const expectedDirectory = path.dirname(descriptor.elfPath);
    const defaultUri = path.isAbsolute(expectedDirectory)
        ? vscode.Uri.file(expectedDirectory)
        : vscode.Uri.joinPath(workspaceUri, expectedDirectory);
    const selected = await vscode.window.showOpenDialog({
        title: `Select ELF for ${descriptor.processor}`,
        defaultUri,
        canSelectFiles: true,
        canSelectFolders: false,
        canSelectMany: false,
        filters: { 'Executable and Linkable Format': ['elf'] },
        openLabel: 'Select ELF',
    });
    const elfPath = selected?.[0]
        ? normalizeWindowsPath(selected[0].fsPath)
        : undefined;
    if (!elfPath) {
        throw new Error('ELF selection was cancelled.');
    }
    if (!isElfPath(elfPath)) {
        throw new Error(`Selected program is not an ELF file: ${elfPath}`);
    }
    return elfPath;
}

async function pickBitstreamMode(
    descriptor: PsTargetDescriptor,
    requested?: boolean,
): Promise<boolean> {
    if (descriptor.bitstreamRequired) {
        return true;
    }
    if (typeof requested === 'boolean') {
        return requested;
    }
    const picked = await vscode.window.showQuickPick([
        {
            label: 'ELF only',
            description: 'Use the processor configuration already present on the board',
            value: false,
        },
        {
            label: 'Program bitstream and ELF',
            description: descriptor.bitstreamExists
                ? descriptor.bitstreamPath
                : 'The project bitstream is currently missing',
            value: true,
        },
    ], {
        title: `${processorKindLabel(descriptor.processorKind)} Download Mode`,
        placeHolder: 'ELF only is recommended when the connected board differs from the project device',
    });
    if (!picked) {
        throw new Error('Xilinx download mode selection was cancelled.');
    }
    return picked.value;
}

async function writePsGdbConfiguration(
    workspaceUri: vscode.Uri,
    descriptor: PsTargetDescriptor,
    selection: PsTargetSelection,
    silent: boolean,
): Promise<vscode.DebugConfiguration> {
    const elfPath = selection.elfPath ?? descriptor.elfPath;
    const name = `Digital IDE: ${processorKindLabel(descriptor.processorKind)} ${descriptor.appName}`;
    const configuration: vscode.DebugConfiguration = {
        name,
        type: 'cppdbg',
        request: 'launch',
        program: elfPath,
        cwd: '${workspaceFolder}',
        MIMode: 'gdb',
        miDebuggerPath: descriptor.gdbPath,
        miDebuggerServerAddress: `${descriptor.gdbHost}:${descriptor.gdbPort}`,
        stopAtEntry: true,
        externalConsole: false,
        setupCommands: [{
            description: 'Download the selected ELF through the Xilinx GDB server',
            text: 'load',
            ignoreFailures: false,
        }],
    };
    const launch = vscode.workspace.getConfiguration('launch', workspaceUri);
    const existing = launch.get<vscode.DebugConfiguration[]>('configurations', []);
    const configurations = existing.filter(candidate => candidate.name !== name);
    configurations.push(configuration);
    await launch.update(
        'configurations',
        configurations,
        vscode.ConfigurationTarget.WorkspaceFolder,
    );
    if (!silent) {
        void vscode.window.showInformationMessage(
            `Generated ${name} on ${descriptor.gdbHost}:${descriptor.gdbPort}.`,
        );
    }
    return configuration;
}

function resolvedWorkspaceUri(requested?: vscode.Uri | string): vscode.Uri {
    const workspaceUri = resolveWorkspaceUri(requested);
    if (!workspaceUri) {
        throw new Error('Digital IDE toolchain commands require an open workspace folder.');
    }
    return workspaceUri;
}

function psSelectionKey(workspaceUri: vscode.Uri): string {
    return `digital-ide.xilinx.ps.selection:${workspaceUri.toString()}`;
}

async function rememberPsSelection(
    context: vscode.ExtensionContext,
    workspaceUri: vscode.Uri,
    selection: PsTargetSelection,
): Promise<void> {
    await context.workspaceState.update(psSelectionKey(workspaceUri), selection);
}

function isElfPath(value: string | undefined): value is string {
    return typeof value === 'string' && path.extname(value).toLowerCase() === '.elf';
}

function processorKindLabel(kind: XilinxProcessorKind): string {
    switch (kind) {
        case 'zynq7000Arm': return 'Zynq-7000 ARM Cortex-A9';
        case 'zynqMpAarch64': return 'ZynqMP ARM Cortex-A53';
        case 'zynqMpArmR5': return 'ZynqMP ARM Cortex-R5';
        case 'microBlaze': return 'MicroBlaze';
        case 'microBlaze64': return 'MicroBlaze 64-bit';
    }
}

function createRequestId(domain: string, action: string): string {
    const sequence = nextRequestId++;
    return `${Date.now()}-${sequence}-${domain.toLowerCase()}-${action}`;
}

function handleProgressEvent(event: ToolchainProgressEvent): void {
    progressEmitter.fire(event);
    const active = activeTasks.get(event.requestId);
    if (!active) {
        return;
    }
    active.progress.report({ message: event.message });
    const prefix = `[task ${event.taskId}] [${event.phase}]`;
    const output = active.hardware ? HardwareOutput : MainOutput;
    if (event.stream === 'stderr' || event.stream === 'stdout') {
        active.receivedOutput = true;
    }
    const fallback = event.stream === 'stderr' ? ReportType.Warn : ReportType.Info;
    const level = event.phase === 'failed'
        ? ReportType.Error
        : classifyLogLevel(event.message, fallback);
    output.report(`${prefix} ${event.message}`, {
        level,
    });
    outputEmitter.fire(event);
}

function showUserMessage(
    kind: ToolchainUserMessage['kind'],
    message: string,
    silent: boolean,
): void {
    userMessageEmitter.fire({ kind, message });
    if (silent) {
        return;
    }
    if (kind === 'error') {
        void vscode.window.showErrorMessage(message);
    } else {
        void vscode.window.showInformationMessage(message);
    }
}

function resolveWorkspaceUri(requested?: vscode.Uri | string): vscode.Uri | undefined {
    if (requested instanceof vscode.Uri) {
        return requested;
    }
    if (typeof requested === 'string') {
        return vscode.Uri.parse(requested);
    }
    const active = vscode.window.activeTextEditor?.document.uri;
    const activeFolder = active && vscode.workspace.getWorkspaceFolder(active);
    return activeFolder?.uri ?? vscode.workspace.workspaceFolders?.[0]?.uri;
}

function writeReport(
    report: ToolchainReport,
    receivedOutput: boolean,
    output: Output,
    errorOutput: Output,
): void {
    const resultLevel = report.status === 'cancelled'
        ? ReportType.Warn
        : report.success ? ReportType.Finish : ReportType.Error;
    output.report(
        `[task ${report.taskId}] ${report.vendor} ${report.domain}/${report.action}: ${report.status}`,
        { level: resultLevel },
    );
    if (report.message) {
        output.report(report.message, {
            level: classifyLogLevel(
                report.message,
                report.success ? ReportType.Info : ReportType.Error,
            ),
        });
    }
    if (report.stdout && !receivedOutput) {
        writeToolOutput(output, report.stdout, ReportType.Info);
    }
    if (report.stderr && !receivedOutput) {
        writeToolOutput(
            errorOutput,
            report.stderr,
            report.success ? ReportType.Warn : ReportType.Error,
        );
    }
    for (const artifact of report.artifacts) {
        output.report(`${artifact.kind}: ${artifact.path}`, {
            level: ReportType.Info,
        });
    }
}

function writeToolOutput(output: Output, text: string, fallback: ReportType): void {
    for (const line of text.split(/\r?\n/)) {
        if (!line) {
            continue;
        }
        output.report(line, { level: classifyLogLevel(line, fallback) });
    }
}
