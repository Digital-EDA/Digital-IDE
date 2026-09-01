import * as path from 'path';
import * as vscode from 'vscode';
import { LanguageClient } from 'vscode-languageclient/node';
import { MainOutput, ReportType } from '../global/outputs';
import { normalizeWindowsPath } from '../utils/paths';
import type { WaveformPanelManager } from '../waveform';

export type SimulationBackend =
    | 'iverilog'
    | 'verilator'
    | 'cxxrtl'
    | 'vcs'
    | 'modelsim'
    | 'questa';

export interface SimulationCommandOptions {
    backend?: SimulationBackend;
    workspaceUri?: vscode.Uri | string;
    fileUri?: vscode.Uri | string;
    filePath?: vscode.Uri | string;
    path?: vscode.Uri | string;
    file?: unknown;
    moduleName?: string;
    name?: string;
    dryRun?: boolean;
    options?: Record<string, unknown>;
    silent?: boolean;
}

export interface SimulationResponse {
    success: boolean;
    backend: SimulationBackend;
    message: string;
    workspace: string;
    moduleName: string;
    filePath: string;
    dryRun: boolean;
    simulationHome: string;
    stdout: string;
    stderr: string;
    exitCode?: number;
    artifacts: Array<{ kind: string; path: string; args?: string[]; cwd?: string }>;
    report?: Record<string, unknown>;
}

export function registerSimulationCommands(
    context: vscode.ExtensionContext,
    client: LanguageClient,
    waveform: WaveformPanelManager,
): void {
    const handler = (options?: SimulationCommandOptions): Promise<SimulationResponse> =>
        runSimulation(client, waveform, options);
    const compatibilityHandler = (options?: SimulationCommandOptions): Promise<SimulationResponse> =>
        runSimulation(client, waveform, options);
    context.subscriptions.push(
        vscode.commands.registerCommand('digital-ide.tool.simulateFile', handler),
        vscode.commands.registerCommand(
            'digital-ide.tool.icarus.simulateFile',
            compatibilityHandler,
        ),
    );
}

async function runSimulation(
    client: LanguageClient,
    waveform: WaveformPanelManager,
    options?: SimulationCommandOptions,
): Promise<SimulationResponse> {
    const treeNode = architectureTreeNode(options?.file);
    const fileUri = resolveFileUri(options);
    if (!fileUri) {
        throw new Error('Open or select an HDL source before starting simulation');
    }
    const workspaceUri = resolveWorkspaceUri(options?.workspaceUri, fileUri);
    if (!workspaceUri) {
        throw new Error('Simulation requires an open workspace folder');
    }
    const moduleName = options?.moduleName?.trim()
        || options?.name?.trim()
        || treeNode?.name
        || path.basename(fileUri.fsPath, path.extname(fileUri.fsPath));
    const backend = options?.backend ?? defaultBackend(fileUri);
    return vscode.window.withProgress(
        {
            location: vscode.ProgressLocation.Notification,
            title: `正在启动 ${backend.toUpperCase()} 仿真`,
            cancellable: false,
        },
        async progress => {
            progress.report({ message: '正在准备仿真环境，请稍候...' });
            const response = await client.sendRequest<SimulationResponse>('digital/simulate', {
                backend,
                workspaceUri: workspaceUri.toString(),
                fileUri: fileUri.toString(),
                moduleName,
                dryRun: options?.dryRun ?? false,
                interactive: isInteractiveBackend(backend),
                options: options?.options ?? {},
            });
            if (response.stdout) {
                MainOutput.report(response.stdout, { level: ReportType.PrintOuput });
            }
            if (response.stderr) {
                MainOutput.report(response.stderr, { level: ReportType.Error });
            }
            if (!response.success) {
                if (!options?.silent) {
                    void vscode.window.showErrorMessage(response.message);
                }
                throw new Error(response.message);
            }
            if (!response.dryRun && isInteractiveBackend(response.backend)) {
                const executable = response.artifacts.find(artifact => artifact.kind === 'executable');
                if (!executable?.path) {
                    throw new Error(
                        `${response.backend} did not return an interactive simulator executable`,
                    );
                }
                progress.report({ message: '正在启动交互式波形会话，请稍候...' });
                await waveform.openSimulator(
                    response.backend,
                    executable.path,
                    `${response.moduleName} (${response.backend.toUpperCase()})`,
                    executable.args ?? [],
                    executable.cwd ?? response.simulationHome,
                );
            }
            if (!options?.silent) {
                void vscode.window.showInformationMessage(response.message);
            }
            return response;
        },
    );
}

function isInteractiveBackend(
    backend: SimulationBackend,
): boolean {
    return ['iverilog', 'verilator', 'cxxrtl', 'vcs', 'modelsim', 'questa'].includes(backend);
}

function resolveFileUri(options?: SimulationCommandOptions): vscode.Uri | undefined {
    const treeNode = architectureTreeNode(options?.file);
    for (const value of [options?.fileUri, options?.filePath, options?.path, treeNode?.path]) {
        if (value instanceof vscode.Uri) {
            return value;
        }
        if (typeof value === 'string') {
            return value.startsWith('file:')
                ? vscode.Uri.parse(value)
                : vscode.Uri.file(normalizeWindowsPath(value));
        }
    }
    return vscode.window.activeTextEditor?.document.uri;
}

function architectureTreeNode(value: unknown): { path: string; name: string } | undefined {
    if (!value || typeof value !== 'object') {
        return undefined;
    }
    const candidate = value as { treeView?: unknown; path?: unknown; name?: unknown };
    return candidate.treeView === 'architecture'
        && typeof candidate.path === 'string'
        && typeof candidate.name === 'string'
        ? { path: candidate.path, name: candidate.name }
        : undefined;
}

function resolveWorkspaceUri(
    requested: vscode.Uri | string | undefined,
    fileUri: vscode.Uri,
): vscode.Uri | undefined {
    if (requested instanceof vscode.Uri) {
        return requested;
    }
    if (typeof requested === 'string') {
        return vscode.Uri.parse(requested);
    }
    return vscode.workspace.getWorkspaceFolder(fileUri)?.uri
        ?? vscode.workspace.workspaceFolders?.[0]?.uri;
}

function defaultBackend(fileUri: vscode.Uri): SimulationBackend {
    const extension = path.extname(fileUri.fsPath).toLowerCase();
    if (['.vhd', '.vhdl', '.vho', '.vht'].includes(extension)) {
        return 'modelsim';
    }
    const configured = vscode.workspace
        .getConfiguration('digital-ide')
        .get<SimulationBackend>('function.simulate.fastSimulator', 'verilator');
    return ['iverilog', 'cxxrtl', 'vcs', 'modelsim', 'questa'].includes(configured)
        ? configured
        : 'verilator';
}
