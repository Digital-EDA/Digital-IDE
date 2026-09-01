import * as vscode from 'vscode';
import { LanguageClient } from 'vscode-languageclient/node';
import { DebuggerOutput, ReportType } from '../global/outputs';
import type {
    WaveformCaptureTarget,
    WaveformDebugBootstrap,
    WaveformDebugCommand,
    WaveformDebugState,
    WaveformDebugTriggerConfiguration,
    WaveformPanelManager,
} from '../waveform';
import type { ToolchainReport } from '../toolchain/commands';

export type DebugVendor = 'efinity' | 'vivado';
export type DebugCoreKind = 'ila' | 'vio';

export interface DebugCoreSelector {
    kind: DebugCoreKind;
    id: number;
}

export interface DebugProbe {
    name: string;
    width: number;
    debug_path?: string;
}

export interface DebugProbeComparison {
    probe_index: number;
    signal: string;
    width: number;
    value: string;
}

export interface DebugCompiledCondition {
    synthesis_compiled: boolean;
    reduction: 'all' | 'any';
    comparisons: DebugProbeComparison[];
}

export interface DebugIlaCore {
    id: number;
    label: string;
    module_id: number;
    uuid: string;
    data_depth: number;
    pipe_stages: number;
    clock: DebugProbe;
    probes: DebugProbe[];
    capture_condition?: DebugCompiledCondition | null;
    trigger_condition?: DebugCompiledCondition | null;
}

export interface DebugVioCore {
    id: number;
    label: string;
    module_id: number;
    uuid: string;
    clock: DebugProbe;
    inputs: DebugProbe[];
    outputs: DebugProbe[];
}

export interface DebugManifest {
    version: number;
    top: string;
    vendor: DebugVendor;
    ila: DebugIlaCore[];
    vio: DebugVioCore[];
    hardware_hash: string;
}

export interface DebugArtifactBundle {
    workspace: string;
    outputDir: string;
    manifestPath: string;
    stampPath: string;
    conditionPath: string;
    manifest: DebugManifest;
    stamp: Record<string, unknown>;
}

export interface DebugBuildSelector {
    workspaceUri?: vscode.Uri | string;
    top?: string;
    vendor?: DebugVendor;
    artifactUri?: vscode.Uri | string;
}

export interface DebugCommandOptions extends DebugBuildSelector {
    core?: DebugCoreSelector;
    transport?: Record<string, unknown>;
    waveformUrl?: string;
    values?: Record<string, string>;
    silent?: boolean;
}

export interface DebuggerExtensionApi {
    refresh(options?: DebugBuildSelector): Promise<DebugArtifactBundle>;
    manifest(): DebugArtifactBundle | undefined;
}

class DebugCoreItem extends vscode.TreeItem {
    public readonly selector: DebugCoreSelector;

    constructor(
        public readonly core: DebugIlaCore | DebugVioCore,
        kind: DebugCoreKind,
    ) {
        super(core.label, vscode.TreeItemCollapsibleState.Collapsed);
        this.selector = { kind, id: core.id };
        this.id = `${kind}:${core.id}`;
        this.contextValue = kind === 'ila' ? 'digitalDebuggerIla' : 'digitalDebuggerVio';
        this.description = `${kind.toUpperCase()} ${core.id}`;
        this.tooltip = `${kind.toUpperCase()} ${core.id}, module ${core.module_id}, UUID ${core.uuid}`;
        this.iconPath = new vscode.ThemeIcon(kind === 'ila' ? 'pulse' : 'settings-gear');
    }
}

class DebugProbeItem extends vscode.TreeItem {
    constructor(probe: DebugProbe, role: string) {
        super(probe.name, vscode.TreeItemCollapsibleState.None);
        this.description = `${role}, ${probe.width} bit${probe.width === 1 ? '' : 's'}`;
        this.tooltip = probe.debug_path
            ? `${probe.debug_path}/${probe.name}`
            : probe.name;
        this.contextValue = 'digitalDebuggerProbe';
        this.iconPath = new vscode.ThemeIcon(role === 'clock' ? 'watch' : 'symbol-field');
    }
}

class DebuggerTreeProvider implements vscode.TreeDataProvider<DebugCoreItem | DebugProbeItem>, vscode.Disposable {
    private readonly changed = new vscode.EventEmitter<void>();
    private bundle: DebugArtifactBundle | undefined;

    public readonly onDidChangeTreeData = this.changed.event;

    public setBundle(bundle: DebugArtifactBundle): void {
        this.bundle = bundle;
        this.changed.fire();
    }

    public current(): DebugArtifactBundle | undefined {
        return this.bundle;
    }

    public dispose(): void {
        this.changed.dispose();
    }

    public getTreeItem(item: DebugCoreItem | DebugProbeItem): vscode.TreeItem {
        return item;
    }

    public getChildren(item?: DebugCoreItem | DebugProbeItem): Array<DebugCoreItem | DebugProbeItem> {
        if (!item) {
            if (!this.bundle) {
                return [];
            }
            return [
                ...this.bundle.manifest.ila.map(core => new DebugCoreItem(core, 'ila')),
                ...this.bundle.manifest.vio.map(core => new DebugCoreItem(core, 'vio')),
            ];
        }
        if (!(item instanceof DebugCoreItem)) {
            return [];
        }
        if (item.selector.kind === 'ila') {
            const core = item.core as DebugIlaCore;
            return [
                new DebugProbeItem(core.clock, 'clock'),
                ...core.probes.map(probe => new DebugProbeItem(probe, 'probe')),
            ];
        }
        const core = item.core as DebugVioCore;
        return [
            new DebugProbeItem(core.clock, 'clock'),
            ...core.inputs.map(probe => new DebugProbeItem(probe, 'input')),
            ...core.outputs.map(probe => new DebugProbeItem(probe, 'output')),
        ];
    }
}

function uriText(value: vscode.Uri | string | undefined): string | undefined {
    return value instanceof vscode.Uri ? value.toString() : value;
}

function workspaceUri(requested?: vscode.Uri | string): string | undefined {
    const explicit = uriText(requested);
    if (explicit) {
        return explicit;
    }
    const active = vscode.window.activeTextEditor?.document.uri;
    return (active && vscode.workspace.getWorkspaceFolder(active)?.uri.toString())
        ?? vscode.workspace.workspaceFolders?.[0]?.uri.toString();
}

function buildParams(options: DebugBuildSelector = {}): Record<string, unknown> {
    return {
        workspaceUri: workspaceUri(options.workspaceUri),
        top: options.top,
        vendor: options.vendor,
        artifactUri: uriText(options.artifactUri),
    };
}

function transport(options: DebugCommandOptions): Record<string, unknown> | undefined {
    return options.transport;
}

function commandOptions(
    itemOrOptions?: DebugCoreItem | DebugCommandOptions,
): DebugCommandOptions {
    if (itemOrOptions instanceof DebugCoreItem) {
        return { core: itemOrOptions.selector };
    }
    return itemOrOptions ?? {};
}

function requireCore(options: DebugCommandOptions, kind?: DebugCoreKind): DebugCoreSelector {
    if (!options.core) {
        throw new Error('A debugger Core must be selected.');
    }
    if (kind && options.core.kind !== kind) {
        throw new Error(`This command requires a ${kind.toUpperCase()} Core.`);
    }
    return options.core;
}

async function reportFailure<T>(silent: boolean, action: () => Promise<T>): Promise<T> {
    try {
        return await action();
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        DebuggerOutput.report(message, { level: ReportType.Error });
        DebuggerOutput.show();
        if (!silent) {
            void vscode.window.showErrorMessage(message);
        }
        throw error;
    }
}

interface DebugCaptureResponse {
    samples: number;
    signals: number;
    timeRange: [number, number];
}

function triggerExpression(core: DebugIlaCore): string {
    const condition = core.trigger_condition;
    if (!condition || condition.synthesis_compiled) return '';
    const operator = condition.reduction === 'any' ? ' || ' : ' && ';
    return condition.comparisons
        .map(comparison => `${comparison.signal} == ${comparison.value}`)
        .join(operator);
}

class DebugCaptureController {
    private target: WaveformCaptureTarget | undefined;
    private activeRequest: Promise<DebugCaptureResponse> | undefined;
    private loopRequested = false;
    private disposed = false;
    private cancellationExpected = false;
    private completedCaptures = 0;
    private lastCapture: DebugCaptureResponse | undefined;
    private trigger: WaveformDebugTriggerConfiguration;
    private status: WaveformDebugState['status'] = 'idle';
    private statusMessage = 'Ready';
    private samplingMode: WaveformDebugState['samplingMode'] = 'single';

    constructor(
        private readonly client: LanguageClient,
        private readonly options: DebugCommandOptions,
        private readonly core: DebugCoreSelector,
        private readonly debug: WaveformDebugBootstrap,
    ) {
        this.trigger = {
            expression: debug.triggerCondition,
            position: debug.triggerPosition,
        };
    }

    public attach(target: WaveformCaptureTarget): void {
        this.target = target;
        target.panel.onDidDispose(() => {
            this.disposed = true;
            this.loopRequested = false;
            void this.cancelActive('disconnect', false);
        });
        this.publishState();
    }

    public async handle(command: WaveformDebugCommand): Promise<void> {
        try {
            await this.dispatch(command);
        } catch (error) {
            this.loopRequested = false;
            this.status = 'error';
            this.statusMessage = error instanceof Error ? error.message : String(error);
            this.publishState(false);
            throw error;
        }
    }

    private async dispatch(command: WaveformDebugCommand): Promise<void> {
        switch (command.command) {
            case 'configureTrigger':
                this.configureTrigger(command.trigger);
                return;
            case 'resetTrigger':
                await this.retrigger();
                return;
            case 'programAndTrigger':
                await this.programAndTrigger();
                return;
            case 'loopTrigger':
                await this.runLoop();
                return;
            case 'pauseTrigger':
                await this.pause();
                return;
            case 'singleTrigger':
                await this.runSingle();
                return;
            case 'disconnect':
                await this.disconnect();
                return;
        }
    }

    public async runSingle(): Promise<DebugCaptureResponse> {
        await this.cancelActive('restart');
        this.samplingMode = 'single';
        this.loopRequested = false;
        const response = await this.captureOnce(false);
        if (!response) throw new Error(`ILA ${this.core.id} capture was cancelled.`);
        return response;
    }

    public async pause(): Promise<void> {
        await this.cancelActive('pause');
        if (!this.disposed) {
            this.status = 'paused';
            this.statusMessage = 'Trigger capture paused';
            this.publishState();
        }
    }

    private configureTrigger(trigger: WaveformDebugTriggerConfiguration | undefined): void {
        if (!trigger) throw new Error('Debug trigger configuration is missing.');
        if (!this.debug.triggerEditable) {
            throw new Error('This trigger condition is fixed in the Debug Build.');
        }
        if (!Number.isInteger(trigger.position)
            || trigger.position < 0
            || trigger.position >= this.debug.dataDepth) {
            throw new Error(`Trigger position must be between 0 and ${this.debug.dataDepth - 1}.`);
        }
        this.trigger = {
            expression: trigger.expression.trim(),
            position: trigger.position,
        };
        this.statusMessage = 'Trigger configuration applied';
        this.publishState();
    }

    private async retrigger(): Promise<void> {
        await this.cancelActive('restart');
        this.samplingMode = 'single';
        await this.captureOnce(false);
    }

    private async programAndTrigger(): Promise<void> {
        await this.cancelActive('restart');
        this.status = 'programming';
        this.statusMessage = 'Programming device';
        this.publishState(true);
        const report = await vscode.commands.executeCommand<ToolchainReport>(
            'digital-ide.hard.program',
            {
                workspaceUri: this.options.workspaceUri,
                silent: true,
            },
        );
        if (!report?.success) {
            throw new Error(report?.message || 'Device programming failed.');
        }
        this.samplingMode = 'single';
        await this.captureOnce(false);
    }

    private async runLoop(): Promise<void> {
        await this.cancelActive('restart');
        this.loopRequested = true;
        this.samplingMode = 'continuous';
        this.publishState();
        while (this.loopRequested && !this.disposed) {
            const response = await this.captureOnce(true);
            if (!response || !this.loopRequested) break;
            await new Promise(resolve => setTimeout(resolve, 0));
        }
    }

    private async disconnect(): Promise<void> {
        await this.cancelActive('disconnect');
        await this.client.sendRequest('digital/debuggerDisconnect', buildParams(this.options));
        this.status = 'disconnected';
        this.statusMessage = 'Hardware debugger disconnected';
        this.publishState(false, false);
    }

    private async captureOnce(continuous: boolean): Promise<DebugCaptureResponse | undefined> {
        if (this.disposed) return undefined;
        this.cancellationExpected = false;
        this.status = 'arming';
        this.statusMessage = continuous ? 'Arming next loop trigger' : 'Arming single trigger';
        this.publishState(true);
        const request = this.client.sendRequest<DebugCaptureResponse>(
            'digital/debuggerCapture',
            {
                ...buildParams(this.options),
                core: this.core,
                transport: transport(this.options),
                waveformUrl: this.target?.waveformUrl,
                options: {
                    triggerPosition: this.trigger.position,
                    continuous,
                },
                triggerOverride: this.debug.triggerEditable
                    ? { expression: this.trigger.expression || null }
                    : undefined,
            },
        );
        this.activeRequest = request;
        this.status = 'waiting';
        this.statusMessage = 'Waiting for hardware trigger condition';
        this.publishState(true);
        try {
            const response = await request;
            this.completedCaptures += 1;
            this.lastCapture = response;
            this.status = 'captured';
            this.statusMessage = `Captured ${response.samples} samples`;
            this.publishState(false);
            return response;
        } catch (error) {
            if (this.cancellationExpected) return undefined;
            this.loopRequested = false;
            this.status = 'error';
            this.statusMessage = error instanceof Error ? error.message : String(error);
            this.publishState(false);
            throw error;
        } finally {
            if (this.activeRequest === request) this.activeRequest = undefined;
        }
    }

    private async cancelActive(
        reason: 'pause' | 'restart' | 'disconnect',
        publish = true,
    ): Promise<void> {
        this.loopRequested = false;
        const active = this.activeRequest;
        if (active) {
            this.cancellationExpected = true;
            await this.client.sendRequest('digital/debuggerStop', {
                ...buildParams(this.options),
                core: this.core,
            });
            await active.catch(() => undefined);
        }
        if (publish && reason === 'pause') {
            this.status = 'paused';
            this.statusMessage = 'Trigger capture paused';
            this.publishState();
        }
    }

    private publishState(busy = false, connected = true): void {
        if (!this.target || this.disposed) return;
        const state: WaveformDebugState = {
            connected,
            busy,
            status: this.status,
            statusMessage: this.statusMessage,
            samplingMode: this.samplingMode,
            completedCaptures: this.completedCaptures,
            trigger: { ...this.trigger },
            lastCapture: this.lastCapture,
        };
        void Promise.resolve(this.target.updateDebugState(state)).catch(error => {
            DebuggerOutput.report(`Unable to update Debug Webview state: ${String(error)}`, {
                level: ReportType.Error,
            });
        });
    }
}

export function registerDebuggerCommands(
    context: vscode.ExtensionContext,
    client: LanguageClient,
    waveform: WaveformPanelManager,
): DebuggerExtensionApi {
    const tree = new DebuggerTreeProvider();
    context.subscriptions.push(
        tree,
        vscode.window.registerTreeDataProvider('digital-ide-treeView-debugger', tree),
    );

    const refresh = async (options: DebugBuildSelector = {}): Promise<DebugArtifactBundle> => {
        DebuggerOutput.report('Refreshing hardware debugger artifacts.', {
            level: ReportType.Launch,
        });
        const bundle = await client.sendRequest<DebugArtifactBundle>(
            'digital/debuggerManifest',
            buildParams(options),
        );
        tree.setBundle(bundle);
        DebuggerOutput.report(
            `Loaded ${bundle.manifest.vendor} Debug Build ${bundle.manifest.top} (${bundle.manifest.hardware_hash}).`,
            { level: ReportType.Info },
        );
        return bundle;
    };

    context.subscriptions.push(vscode.commands.registerCommand(
        'digital-ide.debugger.refresh',
        (options?: DebugBuildSelector) => reportFailure(false, () => refresh(options)),
    ));

    context.subscriptions.push(vscode.commands.registerCommand(
        'digital-ide.debugger.status',
        (itemOrOptions?: DebugCoreItem | DebugCommandOptions) => {
            const options = commandOptions(itemOrOptions);
            return reportFailure(options.silent ?? false, async () => {
                const core = requireCore(options);
                DebuggerOutput.report(
                    `Reading hardware debugger status for ${core.kind.toUpperCase()} ${core.id}.`,
                    { level: ReportType.Run },
                );
                const status = await client.sendRequest<Record<string, unknown>>(
                    'digital/debuggerStatus',
                    { ...buildParams(options), core, transport: transport(options) },
                );
                DebuggerOutput.report(JSON.stringify(status), { level: ReportType.PrintOuput });
                return status;
            });
        },
    ));

    context.subscriptions.push(vscode.commands.registerCommand(
        'digital-ide.debugger.capture',
        (itemOrOptions?: DebugCoreItem | DebugCommandOptions) => {
            const options = commandOptions(itemOrOptions);
            return reportFailure(options.silent ?? false, async () => vscode.window.withProgress(
                {
                    location: vscode.ProgressLocation.Notification,
                    title: 'Debugger capture',
                    cancellable: true,
                },
                async (progress, cancellation) => {
                    const core = requireCore(options, 'ila');
                    const bundle = await refresh(options);
                    const ila = bundle.manifest.ila.find(candidate => candidate.id === core.id);
                    if (!ila) {
                        throw new Error(`Debug Build contains no ILA ${core.id}.`);
                    }
                    const fixedTrigger = ila.trigger_condition?.synthesis_compiled === true;
                    const debug: WaveformDebugBootstrap = {
                        vendor: bundle.manifest.vendor,
                        coreId: ila.id,
                        coreLabel: ila.label,
                        dataDepth: ila.data_depth,
                        probes: ila.probes.map(probe => ({ name: probe.name, width: probe.width })),
                        triggerCondition: triggerExpression(ila),
                        triggerEditable: !fixedTrigger,
                        triggerPosition: Math.floor(ila.data_depth / 2),
                    };
                    DebuggerOutput.report(`Starting ILA ${core.id} hardware capture.`, {
                        level: ReportType.Launch,
                    });
                    progress.report({ message: `Arming ILA ${core.id}` });
                    const controller = new DebugCaptureController(client, options, core, debug);
                    const stop = cancellation.onCancellationRequested(() => {
                        DebuggerOutput.report(`Cancellation requested for ILA ${core.id} capture.`, {
                            level: ReportType.Warn,
                        });
                        void controller.pause();
                    });
                    const captureTarget = await waveform.openCapture(
                        debug,
                        command => controller.handle(command),
                        `ILA ${core.id} Capture`,
                    );
                    controller.attach(captureTarget);
                    try {
                        const response = await controller.runSingle();
                        DebuggerOutput.report(JSON.stringify(response), {
                            level: ReportType.PrintOuput,
                        });
                        DebuggerOutput.report(`ILA ${core.id} hardware capture completed.`, {
                            level: ReportType.Finish,
                        });
                        if (!options.silent) {
                            void vscode.window.showInformationMessage(`ILA ${core.id} capture completed.`);
                        }
                        return response;
                    } catch (error) {
                        captureTarget.panel.dispose();
                        throw error;
                    } finally {
                        stop.dispose();
                    }
                },
            ));
        },
    ));

    context.subscriptions.push(vscode.commands.registerCommand(
        'digital-ide.debugger.stop',
        (itemOrOptions?: DebugCoreItem | DebugCommandOptions) => {
            const options = commandOptions(itemOrOptions);
            return reportFailure(options.silent ?? false, async () => {
                const core = requireCore(options, 'ila');
                DebuggerOutput.report(`Stopping ILA ${core.id} hardware capture.`, {
                    level: ReportType.Run,
                });
                const response = await client.sendRequest(
                    'digital/debuggerStop',
                    { ...buildParams(options), core },
                );
                DebuggerOutput.report(`ILA ${core.id} hardware capture stopped.`, {
                    level: ReportType.Finish,
                });
                return response;
            });
        },
    ));

    context.subscriptions.push(vscode.commands.registerCommand(
        'digital-ide.debugger.vioRead',
        (itemOrOptions?: DebugCoreItem | DebugCommandOptions) => {
            const options = commandOptions(itemOrOptions);
            return reportFailure(options.silent ?? false, async () => {
                const core = requireCore(options, 'vio');
                DebuggerOutput.report(`Reading VIO ${core.id} hardware inputs.`, {
                    level: ReportType.Run,
                });
                const response = await client.sendRequest<Record<string, unknown>>(
                    'digital/debuggerVioRead',
                    {
                        ...buildParams(options),
                        core,
                        transport: transport(options),
                    },
                );
                DebuggerOutput.report(JSON.stringify(response), { level: ReportType.PrintOuput });
                DebuggerOutput.report(`VIO ${core.id} hardware inputs read successfully.`, {
                    level: ReportType.Finish,
                });
                return response;
            });
        },
    ));

    context.subscriptions.push(vscode.commands.registerCommand(
        'digital-ide.debugger.vioWrite',
        (itemOrOptions?: DebugCoreItem | DebugCommandOptions) => {
            const options = commandOptions(itemOrOptions);
            return reportFailure(options.silent ?? false, async () => {
                const core = requireCore(options, 'vio');
                DebuggerOutput.report(`Preparing VIO ${core.id} hardware output update.`, {
                    level: ReportType.Run,
                });
                let values = options.values;
                if (!values) {
                    const manifest = tree.current()?.manifest.vio.find(candidate => candidate.id === core.id);
                    if (!manifest) {
                        throw new Error(`Refresh the Debugger view before editing VIO ${core.id}.`);
                    }
                    values = {};
                    for (const probe of manifest.outputs) {
                        const value = await vscode.window.showInputBox({
                            title: `VIO ${core.id}: ${probe.name}`,
                            prompt: `Enter exactly ${probe.width} bits in shift order or hexadecimal`,
                            value: '0x0',
                            ignoreFocusOut: true,
                        });
                        if (value === undefined) {
                            throw new Error(`VIO ${core.id} write was cancelled.`);
                        }
                        values[probe.name] = value;
                    }
                }
                const response = await client.sendRequest<Record<string, unknown>>(
                    'digital/debuggerVioWrite',
                    {
                        ...buildParams(options),
                        core,
                        transport: transport(options),
                        values,
                    },
                );
                DebuggerOutput.report(JSON.stringify(response), { level: ReportType.PrintOuput });
                DebuggerOutput.report(`VIO ${core.id} hardware outputs committed.`, {
                    level: ReportType.Finish,
                });
                if (!options.silent) {
                    void vscode.window.showInformationMessage(`VIO ${core.id} outputs committed.`);
                }
                return response;
            });
        },
    ));

    return {
        refresh,
        manifest: () => tree.current(),
    };
}
