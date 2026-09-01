import * as vscode from 'vscode';
import type { LanguageClient } from 'vscode-languageclient/node';
import { WaveformPanelManager } from './manager';

export function registerWaveformSupport(
    context: vscode.ExtensionContext,
    clientReady: Promise<LanguageClient>,
): WaveformPanelManager {
    const manager = new WaveformPanelManager(context, clientReady);
    manager.register();
    context.subscriptions.push(manager);
    return manager;
}

export { WaveformPanelManager } from './manager';
export type {
    WaveformCaptureTarget,
    WaveformDebugBootstrap,
    WaveformDebugCommand,
    WaveformDebugState,
    WaveformDebugTriggerConfiguration,
    WaveformSimulatorBackend,
} from './manager';
