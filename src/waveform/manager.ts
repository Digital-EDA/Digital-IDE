import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import { StringDecoder } from 'string_decoder';
import * as vscode from 'vscode';
import type { LanguageClient } from 'vscode-languageclient/node';
import { ReportType, WaveOutput } from '../global/outputs';
import { normalizeWindowsPath } from '../utils/paths';
import WebSocket = require('ws');

export type WaveformSimulatorBackend =
    | 'iverilog'
    | 'verilator'
    | 'cxxrtl'
    | 'vcs'
    | 'modelsim'
    | 'questa';

type WaveformLaunch =
    | { mode: 'file'; filePath: string }
    | { mode: 'state'; statePath: string }
    | { mode: 'simulator'; backend: WaveformSimulatorBackend; executablePath: string }
    | { mode: 'capture'; debug: WaveformDebugBootstrap };

export type WaveformDebugAction =
    | 'resetTrigger'
    | 'programAndTrigger'
    | 'loopTrigger'
    | 'pauseTrigger'
    | 'singleTrigger'
    | 'disconnect'
    | 'configureTrigger';

export interface WaveformDebugTriggerConfiguration {
    expression: string;
    position: number;
}

export interface WaveformDebugBootstrap {
    vendor: 'efinity' | 'vivado';
    coreId: number;
    coreLabel: string;
    dataDepth: number;
    probes: Array<{ name: string; width: number }>;
    triggerCondition: string;
    triggerEditable: boolean;
    triggerPosition: number;
}

export interface WaveformDebugState {
    connected: boolean;
    busy: boolean;
    status: 'idle' | 'programming' | 'arming' | 'waiting' | 'captured' | 'paused' | 'disconnected' | 'error';
    statusMessage: string;
    samplingMode: 'single' | 'continuous';
    completedCaptures: number;
    trigger: WaveformDebugTriggerConfiguration;
    lastCapture?: {
        samples: number;
        signals: number;
        timeRange: [number, number];
    };
}

export interface WaveformDebugCommand {
    command: WaveformDebugAction;
    trigger?: WaveformDebugTriggerConfiguration;
}

interface WaveformHostMessage {
    protocolVersion?: unknown;
    sessionId?: unknown;
    type?: unknown;
    message?: unknown;
    requestId?: unknown;
    requestKind?: unknown;
    defaultPath?: unknown;
    filePath?: unknown;
    command?: unknown;
    trigger?: unknown;
}

type WaveformHostPathRequestKind =
    | 'openWaveform'
    | 'openState'
    | 'openExecutable'
    | 'saveState';

export interface WaveformCaptureTarget {
    waveformUrl: string;
    panel: vscode.WebviewPanel;
    updateDebugState(state: WaveformDebugState): Thenable<boolean>;
}

interface ManagedWaveServer extends vscode.Disposable {
    url: string;
}

type WaveformEndpointResponse =
    | { status: 'ready'; sessionId: string; url: string }
    | { status: 'failed'; message: string };

interface ManagedPanel extends vscode.Disposable {
    server: ManagedWaveServer;
    panel: vscode.WebviewPanel;
}

const supportedWaveformExtensions = new Set(['.vcd', '.fst', '.ghw']);
const waveformStateExtension = '.dws';
const waveformEditorTitle = 'DIDE-WAVE';

type AnsiParserState = 'text' | 'escape' | 'escapeIntermediate' | 'csi' | 'osc' | 'oscEscape';

/** Removes terminal control sequences without corrupting split UTF-8 or ANSI chunks. */
export class AnsiOutputSanitizer {
    private readonly decoder = new StringDecoder('utf8');
    private state: AnsiParserState = 'text';

    public push(data: Buffer | string): string {
        const text = typeof data === 'string' ? data : this.decoder.write(data);
        let output = '';
        for (const character of text) {
            const code = character.charCodeAt(0);
            switch (this.state) {
                case 'text':
                    if (code === 0x1b) {
                        this.state = 'escape';
                    } else if (code === 0x9b) {
                        this.state = 'csi';
                    } else if (code === 0x9d) {
                        this.state = 'osc';
                    } else {
                        output += character;
                    }
                    break;
                case 'escape':
                    if (character === '[') {
                        this.state = 'csi';
                    } else if (character === ']') {
                        this.state = 'osc';
                    } else if (code >= 0x20 && code <= 0x2f) {
                        this.state = 'escapeIntermediate';
                    } else if (code === 0x1b) {
                        this.state = 'escape';
                    } else {
                        this.state = 'text';
                    }
                    break;
                case 'escapeIntermediate':
                    if (code >= 0x30 && code <= 0x7e) {
                        this.state = 'text';
                    } else if (code === 0x1b) {
                        this.state = 'escape';
                    }
                    break;
                case 'csi':
                    if (code >= 0x40 && code <= 0x7e) {
                        this.state = 'text';
                    } else if (code === 0x1b) {
                        this.state = 'escape';
                    }
                    break;
                case 'osc':
                    if (code === 0x07 || code === 0x9c) {
                        this.state = 'text';
                    } else if (code === 0x1b) {
                        this.state = 'oscEscape';
                    }
                    break;
                case 'oscEscape':
                    if (character === '\\' || code === 0x07 || code === 0x9c) {
                        this.state = 'text';
                    } else if (code !== 0x1b) {
                        this.state = 'osc';
                    }
                    break;
            }
        }
        return output;
    }

    public end(): string {
        const output = this.push(this.decoder.end());
        this.state = 'text';
        return output;
    }
}

export class WaveformPanelManager implements vscode.Disposable {
    private readonly sessions = new Set<ManagedPanel>();

    constructor(
        private readonly context: vscode.ExtensionContext,
        private readonly clientReady: Promise<LanguageClient>,
    ) {}

    public get activePanelCount(): number {
        return this.sessions.size;
    }

    public register(): void {
        const provider = new WaveformCustomEditorProvider(this);
        this.context.subscriptions.push(
            vscode.window.registerCustomEditorProvider(
                'digital-ide.waveformViewer',
                provider,
                {
                    webviewOptions: { retainContextWhenHidden: true },
                    supportsMultipleEditorsPerDocument: true,
                },
            ),
        );
        WaveOutput.report('Waveform custom editor and renderer support registered.', {
            level: ReportType.Info,
        });
    }

    public async resolveFile(
        uri: vscode.Uri,
        panel: vscode.WebviewPanel,
    ): Promise<void> {
        panel.title = waveformEditorTitle;
        const filePath = normalizeWindowsPath(uri.fsPath);
        WaveOutput.report(`Opening waveform document: ${filePath}`, {
            level: ReportType.Launch,
        });
        const extension = path.extname(filePath).toLowerCase();
        if (!supportedWaveformExtensions.has(extension) && extension !== waveformStateExtension) {
            panel.dispose();
            throw new Error(`Unsupported waveform document: ${uri.toString()}`);
        }
        if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
            panel.dispose();
            throw new Error(`Waveform file does not exist: ${filePath}`);
        }

        const server = await this.startWaveServer(undefined, [], undefined, 'waveform document');
        try {
            const launch: WaveformLaunch = extension === waveformStateExtension
                ? { mode: 'state', statePath: filePath }
                : { mode: 'file', filePath };
            // Do not preflight the waveform with a temporary WebSocket here.  A
            // Custom Editor must publish its Webview HTML while VS Code is still
            // resolving the editor; waiting for a full VCD/state parse first leaves
            // the OverlayWebview without content and VS Code disposes it.  The
            // renderer performs the real load and reports parse errors through the
            // normal ready/error handshake.
            //
            // We do, however, wait until the HTML has actually been assigned.
            // Returning before `asExternalUri()` and the HTML publication finish
            // races VS Code's custom-editor handoff and produces
            // "OverlayWebview has been disposed" for directly opened `.dws`
            // documents.  The ready handshake itself remains asynchronous so it
            // can run after VS Code commits the editor.
            let publishResolve!: () => void;
            let publishReject!: (error: unknown) => void;
            const published = new Promise<void>((resolve, reject) => {
                publishResolve = resolve;
                publishReject = reject;
            });
            void this.attachPanel(panel, server, launch, 30_000, undefined, publishResolve)
                .catch(error => {
                    publishReject(error);
                    server.dispose();
                    panel.dispose();
                    const message = error instanceof Error ? error.message : String(error);
                    WaveOutput.report(`Unable to initialize waveform panel: ${message}`, {
                        level: ReportType.Error,
                    });
                    void vscode.window.showErrorMessage(`Unable to open waveform: ${message}`);
                });
            await published;
        } catch (error) {
            server.dispose();
            panel.dispose();
            WaveOutput.report(`Unable to load waveform document: ${String(error)}`, {
                level: ReportType.Error,
            });
            throw error;
        }
    }

    public async openSimulator(
        backend: WaveformSimulatorBackend,
        executablePath: string,
        title?: string,
        args: string[] = [],
        cwd?: string,
    ): Promise<vscode.WebviewPanel> {
        const normalized = validateExecutable(executablePath);
        const normalizedCwd = cwd ? validateWorkingDirectory(cwd) : undefined;
        WaveOutput.report(
            `Starting ${backend.toUpperCase()} interactive waveform session: ${normalized}`,
            { level: ReportType.Launch },
        );
        const server = await this.startWaveServer(
            normalized,
            args,
            normalizedCwd,
            `${backend.toUpperCase()} simulator`,
            true,
        );
        const panel = vscode.window.createWebviewPanel(
            'digital-ide.waveformViewer',
            title ?? `${backend.toUpperCase()} Waveform`,
            vscode.ViewColumn.Beside,
            { enableScripts: true, retainContextWhenHidden: true },
        );
        try {
            await this.attachPanel(panel, server, {
                mode: 'simulator',
                backend,
                executablePath: normalized,
            }, 120_000);
            WaveOutput.report(`${backend.toUpperCase()} waveform renderer is ready.`, {
                level: ReportType.Finish,
            });
            return panel;
        } catch (error) {
            server.dispose();
            panel.dispose();
            WaveOutput.report(
                `${backend.toUpperCase()} waveform session failed: ${String(error)}`,
                { level: ReportType.Error },
            );
            throw error;
        }
    }

    public async openWaveformFile(
        filePath: string,
        viewColumn = vscode.ViewColumn.Beside,
    ): Promise<void> {
        const normalized = validateWaveformDocument(filePath);
        await vscode.commands.executeCommand(
            'vscode.openWith',
            vscode.Uri.file(normalized),
            'digital-ide.waveformViewer',
            { preview: false, viewColumn },
        );
        WaveOutput.report(`Opening captured waveform: ${normalized}`, {
            level: ReportType.Finish,
        });
    }

    public async openCapture(
        debug: WaveformDebugBootstrap,
        onCommand: (command: WaveformDebugCommand) => Promise<void>,
        title = 'Debugger Waveform',
    ): Promise<WaveformCaptureTarget> {
        WaveOutput.report(`Starting hardware capture waveform session: ${title}`, {
            level: ReportType.Launch,
        });
        const server = await this.startWaveServer(undefined, [], undefined, `${title} capture`);
        const panel = vscode.window.createWebviewPanel(
            'digital-ide.waveformViewer',
            title,
            vscode.ViewColumn.Beside,
            { enableScripts: true, retainContextWhenHidden: true },
        );
        try {
            const session = await this.attachPanel(
                panel,
                server,
                { mode: 'capture', debug },
                30_000,
                onCommand,
            );
            WaveOutput.report(`Hardware capture waveform renderer is ready at ${server.url}.`, {
                level: ReportType.Finish,
            });
            return {
                waveformUrl: server.url,
                panel,
                updateDebugState: state => session.postMessage({
                    protocolVersion: 1,
                    sessionId: session.sessionId,
                    type: 'waveform.debugState',
                    state,
                }),
            };
        } catch (error) {
            server.dispose();
            panel.dispose();
            WaveOutput.report(`Hardware capture waveform session failed: ${String(error)}`, {
                level: ReportType.Error,
            });
            throw error;
        }
    }

    public dispose(): void {
        for (const session of [...this.sessions]) session.dispose();
        this.sessions.clear();
        WaveOutput.report('All waveform renderer sessions disposed.', {
            level: ReportType.Info,
        });
    }

    private async startWaveServer(
        allowedExecutable?: string,
        allowedArgs: string[] = [],
        allowedCwd?: string,
        sessionLabel = 'waveform session',
        simulatorSession = false,
    ): Promise<ManagedWaveServer> {
        WaveOutput.report('Requesting the in-process waveform backend endpoint.', {
            level: ReportType.Launch,
        });
        let client: LanguageClient;
        try {
            client = await this.clientReady;
        } catch (error) {
            WaveOutput.report(`Digital Server is unavailable for waveform startup: ${String(error)}`, {
                level: ReportType.Error,
            });
            throw error;
        }
        let endpoint: WaveformEndpointResponse;
        try {
            endpoint = await client.sendRequest<WaveformEndpointResponse>(
                'digital/waveformEndpoint',
                { allowedExecutable, allowedArgs, allowedCwd },
            );
        } catch (error) {
            WaveOutput.report(`Waveform backend endpoint request failed: ${String(error)}`, {
                level: ReportType.Error,
            });
            throw error;
        }
        if (endpoint.status === 'failed') {
            WaveOutput.report(`Waveform backend failed to start: ${endpoint.message}`, {
                level: ReportType.Error,
            });
            throw new Error(`Digital Server could not start its waveform endpoint: ${endpoint.message}`);
        }
        const readyEndpoint = endpoint;
        let endpointUrl: URL;
        try {
            endpointUrl = new URL(readyEndpoint.url);
        } catch (error) {
            WaveOutput.report(
                `Waveform backend returned an invalid endpoint ${readyEndpoint.url}: ${String(error)}`,
                { level: ReportType.Error },
            );
            throw error;
        }
        const address = endpointUrl.port
            ? `${endpointUrl.hostname}:${endpointUrl.port}`
            : endpointUrl.host;
        WaveOutput.report(`Waveform backend is ready; listening on ${address}.`, {
            level: ReportType.Launch,
        });
        WaveOutput.report(`Waveform WebSocket endpoint: ${readyEndpoint.url}`, {
            level: ReportType.Info,
        });
        let disposed = false;
        return {
            url: readyEndpoint.url,
            dispose: () => {
                if (disposed) return;
                disposed = true;
                WaveOutput.report(`Releasing waveform backend endpoint ${readyEndpoint.url}.`, {
                    level: ReportType.Info,
                });
                void client.sendRequest<{ released: boolean }>(
                    'digital/releaseWaveformEndpoint',
                    { sessionId: readyEndpoint.sessionId },
                ).then(result => {
                    WaveOutput.report(
                        result.released
                            ? 'Waveform backend endpoint released.'
                            : 'Waveform backend endpoint was already released.',
                        { level: result.released ? ReportType.Info : ReportType.Warn },
                    );
                    WaveOutput.report(
                        result.released
                            ? simulatorSession
                                ? `${sessionLabel} exited; simulator process and waveform session closed.`
                                : `${sessionLabel} closed.`
                            : simulatorSession
                                ? `${sessionLabel} had already exited; waveform session closed.`
                                : `${sessionLabel} was already closed.`,
                        { level: result.released ? ReportType.Finish : ReportType.Warn },
                    );
                }).catch(error => {
                    WaveOutput.report(
                        `Failed to close ${sessionLabel}: ${String(error)}`,
                        { level: ReportType.Error },
                    );
                });
            },
        };
    }

    private async attachPanel(
        panel: vscode.WebviewPanel,
        server: ManagedWaveServer,
        launch: WaveformLaunch,
        readyTimeoutMs = 30_000,
        debugCommandHandler?: (command: WaveformDebugCommand) => Promise<void>,
        onHtmlPublished?: () => void,
    ): Promise<{
        sessionId: string;
        postMessage(message: unknown): Thenable<boolean>;
    }> {
        const resourceRoot = vscode.Uri.joinPath(this.context.extensionUri, 'resources', 'waveform');
        const indexUri = vscode.Uri.joinPath(resourceRoot, 'index.html');
        const indexPath = normalizeWindowsPath(indexUri.fsPath);
        const resourcePath = normalizeWindowsPath(resourceRoot.fsPath);
        if (!fs.existsSync(indexPath)) {
            WaveOutput.report(`Waveform WebUI publication is missing: ${indexPath}`, {
                level: ReportType.Error,
            });
            throw new Error('Waveform WebUI publication is missing. Run npm run build:waveform.');
        }
        WaveOutput.report(`Waveform WebUI assets: ${resourcePath}`, {
            level: ReportType.PathCheck,
        });
        const sessionId = crypto.randomBytes(24).toString('hex');
        const externalHttp = await vscode.env.asExternalUri(
            vscode.Uri.parse(server.url.replace(/^ws:/, 'http:')),
        );
        const websocketUrl = externalHttp.with({
            scheme: externalHttp.scheme === 'https' ? 'wss' : 'ws',
        }).toString(true);
        WaveOutput.report(`Webview waveform endpoint: ${websocketUrl}`, {
            level: ReportType.Info,
        });
        panel.webview.options = {
            enableScripts: true,
            localResourceRoots: [resourceRoot],
        };
        // Register host commands before publishing the Webview HTML. The Webview
        // installs its Debug listener before sending waveform.ready, so delaying
        // this listener until after the ready handshake could lose the first click.
        const hostRequestSubscription = panel.webview.onDidReceiveMessage((raw: WaveformHostMessage) => {
            if (raw.protocolVersion !== 1 || raw.sessionId !== sessionId) return;
            if (raw.type === 'waveform.selectPath') {
                void handleWaveformHostPathRequest(panel, sessionId, raw);
            } else if (raw.type === 'waveform.openDocument') {
                void replaceWaveformDocument(panel, raw.filePath);
            } else if (raw.type === 'waveform.debugCommand' && debugCommandHandler) {
                const command = parseWaveformDebugCommand(raw);
                if (!command) {
                    WaveOutput.report('Waveform Webview sent an invalid Debug command.', {
                        level: ReportType.Error,
                    });
                    return;
                }
                void debugCommandHandler(command).catch(error => {
                    WaveOutput.report(`Waveform Debug command failed: ${String(error)}`, {
                        level: ReportType.Error,
                    });
                });
            }
        });
        const ready = new Promise<void>((resolve, reject) => {
            let settled = false;
            let timer: ReturnType<typeof setTimeout>;
            let messageSubscription: vscode.Disposable;
            let disposeSubscription: vscode.Disposable;
            const finish = (error?: Error) => {
                if (settled) return;
                settled = true;
                clearTimeout(timer);
                messageSubscription.dispose();
                disposeSubscription.dispose();
                if (error) {
                    hostRequestSubscription.dispose();
                    WaveOutput.report(error.message, { level: ReportType.Error });
                    reject(error);
                } else {
                    resolve();
                }
            };
            messageSubscription = panel.webview.onDidReceiveMessage((raw: WaveformHostMessage) => {
                if (raw.protocolVersion !== 1 || raw.sessionId !== sessionId) return;
                if (raw.type === 'waveform.ready') finish();
                if (raw.type === 'waveform.error') {
                    const detail = typeof raw.message === 'string' ? raw.message : 'unknown error';
                    finish(new Error(`Waveform Webview initialization failed: ${detail}`));
                }
            });
            disposeSubscription = panel.onDidDispose(() => {
                finish(new Error('Waveform Webview was closed before initialization completed'));
            });
            timer = setTimeout(() => {
                finish(new Error('Waveform Webview did not complete its ready handshake'));
            }, readyTimeoutMs);
        });
        panel.webview.html = waveformHtml(
            panel.webview,
            resourceRoot,
            indexUri,
            {
                protocolVersion: 1,
                sessionId,
                websocketUrl,
                ...launch,
                simulator: launch.mode === 'simulator'
                    ? { backend: launch.backend, executablePath: launch.executablePath }
                    : undefined,
            },
        );
        onHtmlPublished?.();
        WaveOutput.report(`Waiting for ${launch.mode} waveform Webview ready handshake.`, {
            level: ReportType.Run,
        });
        await ready;
        WaveOutput.report(`${launch.mode} waveform Webview ready handshake completed.`, {
            level: ReportType.Info,
        });
        let disposed = false;
        const release = (closePanel: boolean) => {
            if (disposed) return;
            disposed = true;
            disposeSubscription.dispose();
            hostRequestSubscription.dispose();
            const sessionLabel = launch.mode === 'simulator'
                ? `${launch.backend.toUpperCase()} simulator`
                : `${launch.mode} waveform`;
            const closeAction = launch.mode === 'simulator'
                ? 'requesting simulator process shutdown'
                : 'releasing waveform session';
            WaveOutput.report(
                `${sessionLabel} Webview closed; ${closeAction}.`,
                { level: ReportType.Run },
            );
            server.dispose();
            if (closePanel) panel.dispose();
            this.sessions.delete(managed);
            WaveOutput.report(`${launch.mode} waveform panel closed.`, {
                level: ReportType.Info,
            });
        };
        const disposeSubscription = panel.onDidDispose(() => release(false));
        const managed: ManagedPanel = {
            panel,
            server,
            dispose: () => release(true),
        };
        this.sessions.add(managed);
        return {
            sessionId,
            postMessage: message => panel.webview.postMessage(message),
        };
    }
}

function parseWaveformDebugCommand(raw: WaveformHostMessage): WaveformDebugCommand | undefined {
    const commands = new Set<WaveformDebugAction>([
        'resetTrigger',
        'programAndTrigger',
        'loopTrigger',
        'pauseTrigger',
        'singleTrigger',
        'disconnect',
        'configureTrigger',
    ]);
    if (typeof raw.command !== 'string' || !commands.has(raw.command as WaveformDebugAction)) {
        return undefined;
    }
    if (raw.command !== 'configureTrigger') {
        return { command: raw.command as WaveformDebugAction };
    }
    if (!raw.trigger || typeof raw.trigger !== 'object') return undefined;
    const trigger = raw.trigger as Record<string, unknown>;
    if (typeof trigger.expression !== 'string'
        || !Number.isInteger(trigger.position)
        || Number(trigger.position) < 0) {
        return undefined;
    }
    return {
        command: 'configureTrigger',
        trigger: {
            expression: trigger.expression,
            position: Number(trigger.position),
        },
    };
}

async function replaceWaveformDocument(
    panel: vscode.WebviewPanel,
    requestedPath: unknown,
): Promise<void> {
    try {
        if (typeof requestedPath !== 'string' || requestedPath.length === 0) {
            throw new Error('Waveform document path is missing');
        }
        const normalized = normalizeWindowsPath(fs.realpathSync(requestedPath));
        const extension = path.extname(normalized).toLowerCase();
        if (!supportedWaveformExtensions.has(extension) && extension !== waveformStateExtension) {
            throw new Error(`Unsupported waveform document: ${requestedPath}`);
        }
        if (!fs.statSync(normalized).isFile()) {
            throw new Error(`Waveform document is not a file: ${requestedPath}`);
        }
        const viewColumn = panel.viewColumn ?? vscode.ViewColumn.Active;
        panel.dispose();
        await vscode.commands.executeCommand(
            'vscode.openWith',
            vscode.Uri.file(normalized),
            'digital-ide.waveformViewer',
            { preview: false, viewColumn },
        );
        WaveOutput.report(`Waveform editor switched to: ${normalized}`, {
            level: ReportType.Info,
        });
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        WaveOutput.report(`Unable to switch the waveform editor document: ${message}`, {
            level: ReportType.Error,
        });
        void vscode.window.showErrorMessage(`Unable to switch waveform file: ${message}`);
    }
}

async function handleWaveformHostPathRequest(
    panel: vscode.WebviewPanel,
    sessionId: string,
    raw: WaveformHostMessage,
): Promise<void> {
    if (typeof raw.requestId !== 'string' || raw.requestId.length === 0) return;
    const requestId = raw.requestId;
    const requestKind = parseHostPathRequestKind(raw.requestKind);
    let selectedPath: string | undefined;
    let error: string | undefined;
    try {
        if (!requestKind) {
            throw new Error(`Unsupported waveform path request: ${String(raw.requestKind)}`);
        }
        const defaultPath = typeof raw.defaultPath === 'string' && raw.defaultPath.length > 0
            ? raw.defaultPath
            : undefined;
        selectedPath = await selectWaveformPath(requestKind, defaultPath);
        if (selectedPath) {
            WaveOutput.report(`Waveform ${requestKind} path selected: ${selectedPath}`, {
                level: ReportType.PathCheck,
            });
        }
    } catch (requestError) {
        error = requestError instanceof Error ? requestError.message : String(requestError);
        WaveOutput.report(`Waveform file selection failed: ${error}`, {
            level: ReportType.Error,
        });
    }
    try {
        await panel.webview.postMessage({
            protocolVersion: 1,
            sessionId,
            type: 'waveform.pathResult',
            requestId,
            path: selectedPath,
            error,
        });
    } catch (postError) {
        WaveOutput.report(`Unable to return the waveform file selection: ${String(postError)}`, {
            level: ReportType.Error,
        });
    }
}

function parseHostPathRequestKind(value: unknown): WaveformHostPathRequestKind | undefined {
    switch (value) {
        case 'openWaveform':
        case 'openState':
        case 'openExecutable':
        case 'saveState':
            return value;
        default:
            return undefined;
    }
}

async function selectWaveformPath(
    requestKind: WaveformHostPathRequestKind,
    defaultPath?: string,
): Promise<string | undefined> {
    if (requestKind === 'saveState') {
        const selected = await vscode.window.showSaveDialog({
            title: 'Save Waveform State',
            saveLabel: 'Save',
            defaultUri: waveformDialogDefaultUri(defaultPath, true),
            filters: { 'Waveform State': ['dws'] },
        });
        return selected ? normalizeWindowsPath(selected.fsPath) : undefined;
    }

    const options: vscode.OpenDialogOptions = {
        title: requestKind === 'openWaveform'
            ? 'Open Waveform File'
            : requestKind === 'openState'
                ? 'Open Waveform State'
                : 'Open Simulator Executable',
        openLabel: 'Open',
        canSelectFiles: true,
        canSelectFolders: false,
        canSelectMany: false,
        defaultUri: waveformDialogDefaultUri(defaultPath, false),
    };
    if (requestKind === 'openWaveform') {
        options.filters = {
            'Waveform Files': ['vcd', 'fst', 'ghw'],
            VCD: ['vcd'],
            FST: ['fst'],
            GHW: ['ghw'],
        };
    } else if (requestKind === 'openState') {
        options.filters = { 'Waveform State': ['dws'] };
    }
    const selected = await vscode.window.showOpenDialog(options);
    return selected?.[0] ? normalizeWindowsPath(selected[0].fsPath) : undefined;
}

function waveformDialogDefaultUri(
    requestedPath: string | undefined,
    preserveFilename: boolean,
): vscode.Uri | undefined {
    if (requestedPath) {
        return vscode.Uri.file(preserveFilename ? requestedPath : path.dirname(requestedPath));
    }
    return vscode.workspace.workspaceFolders?.[0]?.uri;
}

class WaveformCustomEditorProvider implements vscode.CustomReadonlyEditorProvider {
    constructor(private readonly manager: WaveformPanelManager) {}

    public openCustomDocument(uri: vscode.Uri): vscode.CustomDocument {
        return { uri, dispose: () => undefined };
    }

    public async resolveCustomEditor(
        document: vscode.CustomDocument,
        panel: vscode.WebviewPanel,
    ): Promise<void> {
        try {
            await vscode.window.withProgress(
                {
                    location: vscode.ProgressLocation.Window,
                    title: `Opening ${path.basename(document.uri.fsPath)}`,
                },
                () => this.manager.resolveFile(document.uri, panel),
            );
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            void vscode.window.showErrorMessage(`Unable to open waveform: ${message}`);
            throw error;
        }
    }
}

function validateExecutable(value: string): string {
    const executable = resolveExecutable(value);
    const stat = fs.statSync(executable);
    if (!stat.isFile()) throw new Error(`Simulator executable is not a file: ${value}`);
    if (process.platform !== 'win32' && (stat.mode & 0o111) === 0) {
        throw new Error(`Simulator file is not executable: ${value}`);
    }
    return executable;
}

function validateWaveformDocument(value: string): string {
    const normalized = normalizeWindowsPath(fs.realpathSync(normalizeWindowsPath(value)));
    const extension = path.extname(normalized).toLowerCase();
    if (!supportedWaveformExtensions.has(extension)) {
        throw new Error(`Unsupported waveform document: ${value}`);
    }
    const stat = fs.statSync(normalized);
    if (!stat.isFile()) {
        throw new Error(`Waveform document is not a file: ${value}`);
    }
    return normalized;
}

function resolveExecutable(value: string): string {
    value = normalizeWindowsPath(value);
    const hasDirectory = path.isAbsolute(value)
        || value.includes(path.sep)
        || (path.sep !== '/' && value.includes('/'));
    const baseCandidates = hasDirectory
        ? [normalizeWindowsPath(path.resolve(value))]
        : (process.env.PATH ?? '')
            .split(path.delimiter)
            .filter(Boolean)
            .map(directory => path.join(directory, value));
    const extensions = process.platform === 'win32' && path.extname(value) === ''
        ? (process.env.PATHEXT ?? '.EXE;.CMD;.BAT;.COM').split(';')
        : [''];
    for (const candidate of baseCandidates) {
        for (const extension of extensions) {
            const executable = `${candidate}${extension}`;
            if (fs.existsSync(executable) && fs.statSync(executable).isFile()) {
                return normalizeWindowsPath(executable);
            }
        }
    }
    throw new Error(`Simulator executable does not exist: ${value}`);
}

function validateWorkingDirectory(value: string): string {
    const directory = normalizeWindowsPath(fs.realpathSync(normalizeWindowsPath(value)));
    if (!fs.statSync(directory).isDirectory()) {
        throw new Error(`Simulator working directory is not a directory: ${value}`);
    }
    return directory;
}

function connectWebSocket(url: string, timeoutMs: number): Promise<WebSocket> {
    return new Promise((resolve, reject) => {
        const socket = new WebSocket(url);
        const timer = setTimeout(() => {
            socket.terminate();
            reject(new Error('WebSocket connection timed out'));
        }, timeoutMs);
        socket.once('open', () => {
            clearTimeout(timer);
            resolve(socket);
        });
        socket.once('error', error => {
            clearTimeout(timer);
            reject(error);
        });
    });
}

async function preflightWaveform(url: string, filePath: string): Promise<void> {
    const socket = await connectWebSocket(url, 3_000);
    try {
        await sendWaveRequest(socket, { type: 'loadFile', path: filePath }, 'fileLoaded');
        await sendWaveRequest(socket, { type: 'loadBody' }, 'bodyLoaded', 120_000);
        await verifyTrackDataProtocol(socket);
    } finally {
        socket.close();
    }
}

async function preflightWaveState(url: string, statePath: string): Promise<void> {
    const socket = await connectWebSocket(url, 3_000);
    let sourcePath: string;
    try {
        const response = await sendWaveRequest(
            socket,
            { type: 'loadState', path: statePath },
            'loadStateResult',
        );
        if (response.success !== true) {
            throw new Error(`Unable to load waveform state: ${String(response.error ?? 'unknown error')}`);
        }
        if (!response.state || typeof response.state !== 'object') {
            throw new Error('Waveform state did not contain a state object');
        }
        const filePath = (response.state as Record<string, unknown>).file_path;
        if (typeof filePath !== 'string' || filePath.trim().length === 0) {
            throw new Error('Waveform state does not reference a source waveform file');
        }
        sourcePath = filePath;
    } finally {
        socket.close();
    }

    const sourceExtension = path.extname(sourcePath).toLowerCase();
    if (!supportedWaveformExtensions.has(sourceExtension)) {
        throw new Error(`Waveform state references an unsupported source: ${sourcePath}`);
    }
    if (!fs.existsSync(sourcePath) || !fs.statSync(sourcePath).isFile()) {
        throw new Error(`Waveform state source does not exist: ${sourcePath}`);
    }
    await preflightWaveform(url, sourcePath);
}

function verifyTrackDataProtocol(socket: WebSocket, timeoutMs = 5_000): Promise<void> {
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            cleanup();
            reject(new Error('Wave Server WTD1 protocol probe timed out'));
        }, timeoutMs);
        const onMessage = (data: WebSocket.RawData, isBinary: boolean) => {
            if (isBinary) {
                const frame = Array.isArray(data)
                    ? Buffer.concat(data)
                    : Buffer.isBuffer(data) ? data : Buffer.from(data);
                if (frame.length >= 4 && frame.readUInt32LE(0) === 0x31445457) {
                    cleanup();
                    resolve();
                } else {
                    cleanup();
                    reject(new Error('Wave Server returned an incompatible track-data frame'));
                }
                return;
            }
            let response: Record<string, unknown>;
            try {
                response = JSON.parse(data.toString()) as Record<string, unknown>;
            } catch {
                return;
            }
            if (response.type === 'error') {
                cleanup();
                reject(new Error(
                    `Wave Server does not support the required WTD1 protocol: ${String(response.message ?? '')}`,
                ));
            }
        };
        const onClose = () => {
            cleanup();
            reject(new Error('Wave Server closed during WTD1 protocol probe'));
        };
        const cleanup = () => {
            clearTimeout(timer);
            socket.off('message', onMessage);
            socket.off('close', onClose);
        };
        socket.on('message', onMessage);
        socket.once('close', onClose);
        const request: Record<string, unknown> = {
            type: 'requestTrackData',
            generation: 0,
            tracks: [],
            source: 'file',
        };
        request['track_start_idx'] = 0;
        socket.send(JSON.stringify(request));
    });
}

function sendWaveRequest(
    socket: WebSocket,
    request: Record<string, unknown>,
    successType: string,
    timeoutMs = 30_000,
): Promise<Record<string, unknown>> {
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            cleanup();
            reject(new Error(`Wave Server request timed out: ${request.type}`));
        }, timeoutMs);
        const onMessage = (data: WebSocket.RawData) => {
            let response: Record<string, unknown>;
            try {
                response = JSON.parse(data.toString()) as Record<string, unknown>;
            } catch {
                return;
            }
            if (response.type === 'error') {
                cleanup();
                reject(new Error(`[${String(response.code ?? 'ERROR')}] ${String(response.message ?? '')}`));
            } else if (response.type === successType) {
                cleanup();
                resolve(response);
            }
        };
        const onClose = () => {
            cleanup();
            reject(new Error(`Wave Server closed during ${String(request.type)}`));
        };
        const cleanup = () => {
            clearTimeout(timer);
            socket.off('message', onMessage);
            socket.off('close', onClose);
        };
        socket.on('message', onMessage);
        socket.once('close', onClose);
        socket.send(JSON.stringify(request));
    });
}

function waveformHtml(
    webview: vscode.Webview,
    resourceRoot: vscode.Uri,
    indexUri: vscode.Uri,
    bootstrap: Record<string, unknown>,
): string {
    const nonce = crypto.randomBytes(24).toString('base64');
    let html = fs.readFileSync(normalizeWindowsPath(indexUri.fsPath), 'utf8');
    html = html.replace(/<meta[^>]+http-equiv=["']Content-Security-Policy["'][^>]*>/gi, '');
    html = html.replace(/\b(src|href)=(["'])([^"']+)\2/gi, (match, attribute, quote, value) => {
        if (/^(?:[a-z]+:|#|\/\/)/i.test(value)) return match;
        const normalized = path.posix.normalize(value.replace(/^\.\//, '').replace(/^\//, ''));
        if (normalized.startsWith('../') || normalized === '..') {
            throw new Error(`Waveform asset escapes its publication root: ${value}`);
        }
        const resource = vscode.Uri.joinPath(resourceRoot, ...normalized.split('/'));
        return `${attribute}=${quote}${webview.asWebviewUri(resource).toString()}${quote}`;
    });
    html = html.replace(/<script\b(?![^>]*\bnonce=)/gi, `<script nonce="${nonce}"`);
    const websocketUrl = String(bootstrap.websocketUrl);
    const connectOrigin = new URL(websocketUrl).origin;
    const serialized = JSON.stringify(bootstrap).replace(/</g, '\\u003c');
    // Pixi's explicitly selected `pixi.js/unsafe-eval` build is required by
    // the waveform renderer.  Without the corresponding CSP permission the
    // module is rejected before Vue mounts, so the host never receives the
    // ready/error handshake and waits until its timeout.
    const head = `<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src ${webview.cspSource} data:; font-src ${webview.cspSource}; style-src ${webview.cspSource} 'unsafe-inline'; script-src 'nonce-${nonce}' ${webview.cspSource} 'unsafe-eval'; connect-src ${connectOrigin}; worker-src blob:; object-src 'none'; base-uri 'none'; form-action 'none'">\n<script nonce="${nonce}">window.__DIGITAL_WAVEFORM_BOOTSTRAP__=${serialized};</script>`;
    return html.replace(/<head>/i, `<head>${head}`);
}
