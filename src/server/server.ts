import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
} from 'vscode-languageclient/node';
import { ProjectExtensionApi } from '../project/commands';
import { DebuggerExtensionApi } from '../debugger/commands';
import { MainOutput, ReportType, serverOutputChannel } from '../global/outputs';
import type { WaveformPanelManager } from '../waveform';
import type { NetlistPanelManager } from '../netlist/commands';
import {
    handleDiagnosticPublication,
    registerDiagnosticQuickFixes,
} from '../diagnostics/quickFixes';
import {
    isPathSetting,
    normalizePathSettingValue,
    normalizeWindowsPath,
} from '../utils/paths';
import { ServerCrashForensics } from './crashForensics';

export interface DigitalServerExtensionApi {
    client: LanguageClient;
    initializationOptions: Record<string, unknown>;
    serverPath: string;
    project?: ProjectExtensionApi;
    debugger?: DebuggerExtensionApi;
    waveform?: WaveformPanelManager;
    netlist?: NetlistPanelManager;
}

let client: LanguageClient | undefined;
let crashForensics: ServerCrashForensics | undefined;

const hdlExtensions = new Set([
    '.v', '.vh', '.vl', '.sv', '.svh', '.vhd', '.vhdl', '.vho', '.vht',
]);

function pollingSnapshot(): Map<string, string> {
    const snapshot = new Map<string, string>();
    const pending = (vscode.workspace.workspaceFolders ?? [])
        .map(folder => normalizeWindowsPath(folder.uri.fsPath));
    while (pending.length > 0) {
        const directory = pending.pop();
        if (!directory) {
            continue;
        }
        let entries: fs.Dirent[];
        try {
            entries = fs.readdirSync(directory, { withFileTypes: true });
        } catch {
            continue;
        }
        for (const entry of entries) {
            const entryPath = path.join(directory, entry.name);
            if (entry.isDirectory()) {
                pending.push(entryPath);
                continue;
            }
            const isProperty = entry.name === 'property.json'
                && path.basename(directory) === '.vscode';
            if (!entry.isFile()
                || (!isProperty && !hdlExtensions.has(path.extname(entry.name).toLowerCase()))) {
                continue;
            }
            try {
                const stat = fs.statSync(entryPath);
                snapshot.set(entryPath, `${stat.mtimeMs}:${stat.size}`);
            } catch {
                // The next polling pass will observe a concurrent rename or delete.
            }
        }
    }
    return snapshot;
}

function enablePollingWatcher(
    context: vscode.ExtensionContext,
    languageClient: LanguageClient,
): void {
    if (process.env.DIGITAL_VSCODE_TEST_POLLING_WATCHER !== '1') {
        return;
    }
    let previous = pollingSnapshot();
    let previousRoots = (vscode.workspace.workspaceFolders ?? [])
        .map(folder => normalizeWindowsPath(folder.uri.fsPath));
    let running = false;
    const timer = setInterval(() => {
        if (running) {
            return;
        }
        running = true;
        const current = pollingSnapshot();
        const currentRoots = (vscode.workspace.workspaceFolders ?? [])
            .map(folder => normalizeWindowsPath(folder.uri.fsPath));
        const addedRoots = currentRoots.filter(root => !previousRoots.includes(root));
        const changes: Array<{ uri: string; type: number }> = [];
        for (const [filePath, fingerprint] of current) {
            const old = previous.get(filePath);
            if (old === undefined && addedRoots.some(root => isPathInside(filePath, root))) {
                continue;
            }
            if (old === undefined || old !== fingerprint) {
                changes.push({
                    uri: vscode.Uri.file(filePath).toString(),
                    type: old === undefined ? 1 : 2,
                });
            }
        }
        for (const filePath of previous.keys()) {
            if (!current.has(filePath)
                && currentRoots.some(root => isPathInside(filePath, root))) {
                changes.push({ uri: vscode.Uri.file(filePath).toString(), type: 3 });
            }
        }
        previous = current;
        previousRoots = currentRoots;
        const notification = changes.length > 0
            ? languageClient.sendNotification('workspace/didChangeWatchedFiles', { changes })
            : Promise.resolve();
        void notification.finally(() => {
            running = false;
        });
    }, 100);
    context.subscriptions.push({ dispose: () => clearInterval(timer) });
}

function isPathInside(filePath: string, root: string): boolean {
    const relative = path.relative(root, filePath);
    return relative.length === 0
        || (!relative.startsWith('..') && !path.isAbsolute(relative));
}

function getSettings(context: vscode.ExtensionContext): Record<string, unknown> {
    const config = vscode.workspace.getConfiguration('digital-ide');
    const configuredVhdlLibraryPath = normalizeWindowsPath(
        process.env.DIGITAL_SERVER_VHDL_LIBRARY_PATH
        ?? config.get<string>('lib.vhdl.path', ''),
    );
    const bundledVhdlLibraryPath = normalizeWindowsPath(
        context.asAbsolutePath(path.join('resources', 'vhdl_libraries')),
    );
    const developmentVhdlLibraryPath = normalizeWindowsPath(path.resolve(
        context.extensionPath,
        '..',
        'vhdl',
        'vhdl_libraries',
    ));
    const defaultVhdlLibraryPath = fs.existsSync(bundledVhdlLibraryPath)
        ? bundledVhdlLibraryPath
        : developmentVhdlLibraryPath;
    const vhdlLibraryPath = configuredVhdlLibraryPath.trim() || defaultVhdlLibraryPath;
    const settings: Record<string, unknown> = {
        'digital-ide.standard.systemverilog': config.get<string>(
            'standard.systemverilog',
            '2017',
        ),
        'digital-ide.function.lsp.systemverilog.expandIncludes': config.get<boolean>(
            'function.lsp.systemverilog.expandIncludes',
            true,
        ),
        'digital-ide.standard.vhdl': config.get<string>('standard.vhdl', '2018'),
        'digital-ide.lib.custom.path': config.get<string>('lib.custom.path', ''),
        'digital-ide.lib.vhdl.path': vhdlLibraryPath,
        'digital-ide.function.lsp.linter.mode': config.get<string>(
            'function.lsp.linter.mode',
            'full',
        ),
        'digital-ide.function.lsp.linter.linter-level': config.get<string>(
            'function.lsp.linter.linter-level',
            'warning',
        ),
        'digital-ide.function.lsp.semantic.tokens.port.clk.rst.enable': config.get<boolean>(
            'function.lsp.semantic.tokens.port.clk.rst.enable',
            true,
        ),
        'digital-ide.function.lsp.semantic.tokens.port.input.output.enable': config.get<boolean>(
            'function.lsp.semantic.tokens.port.input.output.enable',
            true,
        ),
        'digital-ide.function.lsp.inlayHints.port.connection.enable': config.get<boolean>(
            'function.lsp.inlayHints.port.connection.enable',
            true,
        ),
        'digital-ide.function.lsp.inlayHints.parameter.assignment.enable': config.get<boolean>(
            'function.lsp.inlayHints.parameter.assignment.enable',
            true,
        ),
        'digital-ide.xilinx.vivado.path': config.get<string>(
            'prj.vivado.install.path',
            '',
        ),
        'digital-ide.debugger.vivado.hwServerUrl': config.get<string>(
            'debugger.vivado.hwServerUrl',
            '',
        ),
        'digital-ide.debugger.vivado.target': config.get<string>(
            'debugger.vivado.target',
            '',
        ),
        'digital-ide.debugger.vivado.programBeforeAccess': config.get<boolean>(
            'debugger.vivado.programBeforeAccess',
            false,
        ),
        'digital-ide.debugger.vivado.timeoutMs': config.get<number>(
            'debugger.vivado.timeoutMs',
            120000,
        ),
        'digital-ide.xilinx.xsct.path': config.get<string>(
            'prj.xsdk.install.path',
            '',
        ),
        'digital-ide.xilinx.ps.hwServer.path': config.get<string>(
            'xilinx.ps.hwServer.path',
            '',
        ),
        'digital-ide.xilinx.ps.hwServer.host': config.get<string>(
            'xilinx.ps.hwServer.host',
            '127.0.0.1',
        ),
        'digital-ide.xilinx.ps.hwServer.port': config.get<number>(
            'xilinx.ps.hwServer.port',
            3121,
        ),
        'digital-ide.xilinx.ps.gdb.portBase': config.get<number>(
            'xilinx.ps.gdb.portBase',
            3000,
        ),
        'digital-ide.xilinx.ps.gdb.arm.path': config.get<string>(
            'xilinx.ps.gdb.arm.path',
            '',
        ),
        'digital-ide.xilinx.ps.gdb.aarch64.path': config.get<string>(
            'xilinx.ps.gdb.aarch64.path',
            '',
        ),
        'digital-ide.xilinx.ps.gdb.armR5.path': config.get<string>(
            'xilinx.ps.gdb.armR5.path',
            '',
        ),
        'digital-ide.xilinx.ps.gdb.microblaze.path': config.get<string>(
            'xilinx.ps.gdb.microblaze.path',
            '',
        ),
        'digital-ide.xilinx.ps.gdb.microblaze64.path': config.get<string>(
            'xilinx.ps.gdb.microblaze64.path',
            '',
        ),
        'digital-ide.prj.efinix.package.path': config.get<string>(
            'prj.efinix.package.path',
            '',
        ),
        'digital-ide.efinity.install.path': config.get<string>(
            'efinity.install.path',
            '',
        ),
        'digital-ide.prj.verilator.install.path': config.get<string>(
            'prj.verilator.install.path',
            '',
        ),
        'digital-ide.prj.modelsim.install.path': config.get<string>(
            'prj.modelsim.install.path',
            '',
        ),
        'digital-ide.prj.iverilog.install.path': config.get<string>(
            'prj.iverilog.install.path',
            '',
        ),
        'digital-ide.function.simulate.fastSimulator': config.get<string>(
            'function.simulate.fastSimulator',
            'verilator',
        ),
        'digital-ide.function.simulate.xilinxLibPath': config.get<string>(
            'function.simulate.xilinxLibPath',
            '',
        ),
        'digital-ide.function.simulate.vendorCachePath': config.get<string>(
            'function.simulate.vendorCachePath',
            '',
        ),
    };

    // Forward newly contributed Digital-IDE settings as well as the settings
    // with explicit server aliases above. This keeps the runtime snapshot in
    // sync when a setting is added without another manual mapping here.
    const properties = context.extension.packageJSON?.contributes?.configuration?.properties;
    if (properties && typeof properties === 'object') {
        for (const key of Object.keys(properties)) {
            if (!key.startsWith('digital-ide.') || key in settings) {
                continue;
            }
            settings[key] = config.get(key.slice('digital-ide.'.length));
        }
    }
    for (const [key, value] of Object.entries(settings)) {
        if (isPathSetting(key)) {
            settings[key] = normalizePathSettingValue(value);
        }
    }
    return settings;
}

function resolveServerPath(context: vscode.ExtensionContext): string {
    const executable = process.platform === 'win32' ? 'digital-server.exe' : 'digital-server';
    const configured = process.env.DIGITAL_SERVER_PATH
        ? normalizeWindowsPath(process.env.DIGITAL_SERVER_PATH)
        : undefined;
    const packaged = normalizeWindowsPath(context.asAbsolutePath(
        path.join('resources', 'server', process.platform, process.arch, executable),
    ));
    const debugBuild = normalizeWindowsPath(
        path.resolve(context.extensionPath, '..', '..', 'target', 'debug', executable),
    );
    const releaseBuild = normalizeWindowsPath(
        path.resolve(context.extensionPath, '..', '..', 'target', 'release', executable),
    );
    const automaticCandidates = context.extensionMode === vscode.ExtensionMode.Development
        ? [debugBuild, packaged, releaseBuild]
        : [packaged, releaseBuild, debugBuild];
    const candidates = [
        configured,
        ...automaticCandidates,
    ].filter((candidate): candidate is string => Boolean(candidate));

    const serverPath = candidates.find(candidate => fs.existsSync(candidate));
    if (!serverPath) {
        throw new Error(
            `Digital Server executable was not found. Checked: ${candidates.join(', ')}`,
        );
    }
    return normalizeWindowsPath(serverPath);
}

function serverEnvironment(): NodeJS.ProcessEnv {
    const env = { ...process.env };
    delete env.ELECTRON_RUN_AS_NODE;
    return env;
}

export async function activate(
    context: vscode.ExtensionContext,
): Promise<DigitalServerExtensionApi> {
    const serverPath = resolveServerPath(context);
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    const extensionPath = normalizeWindowsPath(context.extensionPath);
    const serverCwd = normalizeWindowsPath(workspaceFolder?.uri.fsPath ?? extensionPath);
    MainOutput.report(`Digital Server executable: ${serverPath}`, {
        level: ReportType.PathCheck,
    });
    MainOutput.report(`Digital Server working directory: ${serverCwd}`, {
        level: ReportType.Info,
    });
    const hdlWatcher = vscode.workspace.createFileSystemWatcher(
        '**/*.{v,V,vh,vl,sv,svh,SV,vhd,vhdl,vho,vht}',
    );
    const propertyWatcher = vscode.workspace.createFileSystemWatcher('**/.vscode/property.json');
    context.subscriptions.push(hdlWatcher, propertyWatcher);

    const initializationOptions: Record<string, unknown> = {
        extensionPath,
        'digital-ide.extension.path': extensionPath,
        toolChain: 'xilinx',
        version: context.extension.packageJSON.version,
        ...getSettings(context),
    };
    crashForensics?.dispose();
    crashForensics = new ServerCrashForensics(context, {
        serverPath,
        serverCwd,
        serverEnv: serverEnvironment(),
        initializationOptions,
    });
    context.subscriptions.push(crashForensics);
    const serverOptions = crashForensics.serverOptions();
    const clientOptions: LanguageClientOptions = {
        documentSelector: [
            { scheme: 'file', language: 'systemverilog' },
            { scheme: 'file', language: 'verilog' },
            { scheme: 'file', language: 'vhdl' },
        ],
        progressOnInitialization: true,
        markdown: {
            isTrusted: true,
            supportHtml: true,
        },
        initializationOptions,
        outputChannel: serverOutputChannel,
        traceOutputChannel: serverOutputChannel,
        middleware: {
            handleDiagnostics(uri, diagnostics, next) {
                next(uri, handleDiagnosticPublication(uri, diagnostics));
            },
        },
        synchronize: {
            fileEvents: [hdlWatcher, propertyWatcher],
        },
    };

    const languageClient = new LanguageClient(
        'digital-server',
        'Digital Server',
        serverOptions,
        clientOptions,
    );
    client = languageClient;
    languageClient.onRequest(
        'digital/requestFullText',
        async (params: { uri: string; sequence: number }) => {
            const uri = vscode.Uri.parse(params.uri);
            const document = vscode.workspace.textDocuments.find(
                candidate => candidate.uri.toString() === uri.toString(),
            ) ?? await vscode.workspace.openTextDocument(uri);
            const text = document.getText();
            return {
                uri: document.uri.toString(),
                version: document.version,
                text,
                textHash: crypto.createHash('sha256').update(text, 'utf8').digest('hex'),
                hashAlgorithm: 'sha256',
                sequence: params.sequence,
            };
        },
    );
    MainOutput.report('Starting Digital Server language client.', {
        level: ReportType.Launch,
    });
    try {
        await languageClient.start();
    } catch (error) {
        MainOutput.report(`Digital Server language client failed to start: ${String(error)}`, {
            level: ReportType.Error,
        });
        throw error;
    }
    const serverInfo = languageClient.initializeResult?.serverInfo;
    const serverName = serverInfo?.name ?? 'Digital Server';
    const serverVersion = serverInfo?.version ? ` ${serverInfo.version}` : '';
    MainOutput.report(`${serverName}${serverVersion} language service is ready.`, {
        level: ReportType.Launch,
    });
    registerDiagnosticQuickFixes(context, languageClient);
    enablePollingWatcher(context, languageClient);
    MainOutput.report('HDL source and project configuration watchers are active.', {
        level: ReportType.Info,
    });

    const workspaceFolderSubscription = vscode.workspace.onDidChangeWorkspaceFolders(event => {
        MainOutput.report(
            `Workspace folders changed: ${event.added.length} added, ${event.removed.length} removed.`,
            { level: ReportType.Info },
        );
        void languageClient.sendNotification('workspace/didChangeWorkspaceFolders', {
            event: {
                added: event.added.map(folder => ({
                    uri: folder.uri.toString(),
                    name: folder.name,
                })),
                removed: event.removed.map(folder => ({
                    uri: folder.uri.toString(),
                    name: folder.name,
                })),
            },
        }).catch(error => MainOutput.report(
            `Failed to synchronize workspace folders: ${String(error)}`,
            { level: ReportType.Error },
        ));
    });
    const configurationSubscription = vscode.workspace.onDidChangeConfiguration(event => {
        if (!event.affectsConfiguration('digital-ide')) {
            return;
        }
        const settings = {
            'digital-ide.extension.path': extensionPath,
            'digital-ide.extensionPath': extensionPath,
            ...getSettings(context),
        };
        Object.assign(initializationOptions, settings);
        void languageClient.sendNotification('workspace/didChangeConfiguration', {
            settings,
        }).catch(error => MainOutput.report(
            `Failed to synchronize Digital-IDE settings: ${String(error)}`,
            { level: ReportType.Error },
        ));
    });
    context.subscriptions.push(workspaceFolderSubscription, configurationSubscription);

    return { client: languageClient, initializationOptions, serverPath };
}

export async function deactivate(): Promise<void> {
    const activeClient = client;
    client = undefined;
    crashForensics?.markExpectedShutdown();
    if (activeClient) {
        MainOutput.report('Stopping Digital Server language client.', {
            level: ReportType.Info,
        });
        try {
            await activeClient.stop();
            MainOutput.report('Digital Server language client stopped.', {
                level: ReportType.Info,
            });
        } catch (error) {
            MainOutput.report(`Digital Server language client failed to stop: ${String(error)}`, {
                level: ReportType.Error,
            });
            throw error;
        }
    }
    crashForensics?.dispose();
    crashForensics = undefined;
}
