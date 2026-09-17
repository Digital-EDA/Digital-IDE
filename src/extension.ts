import * as vscode from 'vscode';
import { MainOutput, ReportType, outputChannels } from './global/outputs';
import { t } from './i18n';
import { registerToolchainCommands } from './toolchain/commands';
import { registerProjectCommands } from './project/commands';
import { registerDeviceCompletion } from './project/deviceCompletion';
import type { LanguageClient } from 'vscode-languageclient/node';
import type { ProjectExtensionApi } from './project/commands';
import type { DigitalServerExtensionApi } from './server/server';
import { registerWaveformSupport } from './waveform';
import type { WaveformPanelManager } from './waveform';
import { normalizeWindowsPath } from './utils/paths';

export interface DigitalIdeExtensionApi {
    readonly project: ProjectExtensionApi;
    readonly waveform: WaveformPanelManager;
    readonly ready: Promise<DigitalServerExtensionApi>;
}

let serverModulePromise: Promise<typeof import('./server/server')> | undefined;

export function activate(
    context: vscode.ExtensionContext,
): DigitalIdeExtensionApi {
    context.subscriptions.push(...outputChannels);
    const version = String(context.extension.packageJSON.version ?? 'unknown');
    const workspace = vscode.workspace.workspaceFolders?.[0]
        ? normalizeWindowsPath(vscode.workspace.workspaceFolders[0].uri.fsPath)
        : 'no workspace';
    MainOutput.report(`Digital-IDE ${version} extension activation started.`, {
        level: ReportType.Launch,
    });
    MainOutput.report(`Workspace: ${workspace}`, { level: ReportType.Info });
    let resolveClient!: (client: LanguageClient) => void;
    let rejectClient!: (reason?: unknown) => void;
    const clientReady = new Promise<LanguageClient>((resolve, reject) => {
        resolveClient = resolve;
        rejectClient = reject;
    });

    // These providers contain only static nodes and must be registered before
    // any backend module is loaded or any LSP initialization work begins.
    registerToolchainCommands(context, clientReady);
    registerDeviceCompletion(context);
    const project = registerProjectCommands(context, clientReady);
    const waveform = registerWaveformSupport(context, clientReady);
    MainOutput.report('Static TOOL/HARD/SOFT views and commands registered.', {
        level: ReportType.Info,
    });

    const ready = afterExtensionActivation(() => activateBackend(
        context,
        project,
        waveform,
        resolveClient,
        rejectClient,
    ));
    void ready.catch(error => {
        MainOutput.report(`Digital IDE backend activation failed: ${String(error)}`, {
            level: ReportType.Error,
        });
    });
    return { project, waveform, ready };
}

async function activateBackend(
    context: vscode.ExtensionContext,
    project: ProjectExtensionApi,
    waveform: WaveformPanelManager,
    resolveClient: (client: LanguageClient) => void,
    rejectClient: (reason?: unknown) => void,
): Promise<DigitalServerExtensionApi> {
    MainOutput.report('Loading Digital Server integration.', { level: ReportType.Launch });
    serverModulePromise ??= import('./server/server');
    const server = await serverModulePromise;
    const api = await vscode.window.withProgress(
        {
            location: vscode.ProgressLocation.Window,
            title: t('info.progress.launch-lsp'),
        },
        async () => {
            try {
                const activated = await server.activate(context);
                resolveClient(activated.client);
                return activated;
            } catch (error) {
                rejectClient(error);
                throw error;
            }
        },
    );
    const [filelist, simulation, netlist, debuggerModule] = await Promise.all([
        import('./filelist/commands'),
        import('./simulation/commands'),
        import('./netlist/commands'),
        import('./debugger/commands'),
    ]);
    filelist.registerFilelistCommands(context, api.client);
    simulation.registerSimulationCommands(context, api.client, waveform);
    const netlistManager = netlist.registerNetlistCommands(context, api.client);
    const debuggerApi = debuggerModule.registerDebuggerCommands(context, api.client, waveform);
    MainOutput.report(
        'Filelist, simulation, netlist, and debugger commands registered.',
        { level: ReportType.Info },
    );
    MainOutput.report('Digital-IDE extension activation completed successfully.', {
        level: ReportType.Finish,
    });
    return { ...api, project, debugger: debuggerApi, waveform, netlist: netlistManager };
}

function afterExtensionActivation<T>(task: () => Promise<T>): Promise<T> {
    return new Promise<T>((resolve, reject) => {
        setImmediate(() => {
            void task().then(resolve, reject);
        });
    });
}

export async function deactivate(): Promise<void> {
    if (serverModulePromise) {
        MainOutput.report('Stopping Digital-IDE backend services.', { level: ReportType.Info });
        try {
            await (await serverModulePromise).deactivate();
            MainOutput.report('Digital-IDE backend services stopped.', {
                level: ReportType.Finish,
            });
        } catch (error) {
            MainOutput.report(`Failed to stop Digital-IDE backend services: ${String(error)}`, {
                level: ReportType.Error,
            });
            throw error;
        }
    }
}
