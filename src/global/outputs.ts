import * as vscode from 'vscode';

enum ReportType {
    /** debug */
    Debug = 'Debug',
    /** Module or subprocess startup information. */
    Launch = 'Launch',
    /** Performance measurements. */
    Performance = 'Performance',
    /** Path resolution and validation. */
    PathCheck = 'Path Check',
    /** General information. */
    Info = 'Info',
    /** Warning information. */
    Warn = 'Warn',
    /** Error information. */
    Error = 'Error',
    /** Runtime progress. */
    Run = 'Run',
    /** Output that already contains its own formatting. */
    PrintOuput = 'PrintOutput',
    /** Completion of a longer operation. */
    Finish = 'Finish'
}

interface ReportOption {
    level?: ReportType;
    /** Also show the message as a VS Code notification. */
    notify?: boolean;
}

const explicitLogLevel = /^\s*(?:\[\s*)?(error|fatal|panic|warn|warning|info|debug|trace|log)\b/i;
const errorMarker = /\b(?:error|failed|failure|fatal|panic|exception|enoent|eacces)\b/i;
const warningMarker = /\b(?:warn|warning|deprecated|timeout|retry)\b/i;
const serverLaunchMarker = /^\s*INFO\s+\[digital_server::server\]\s+launch Digital LSP\b/i;
const serverTarget = /^\s*\w+\s+\[([^\]]+)\]/;

export function classifyLogLevel(
    message: string,
    fallback: ReportType = ReportType.Info,
): ReportType {
    const explicit = explicitLogLevel.exec(message)?.[1]?.toLowerCase();
    if (explicit === 'error' || explicit === 'fatal' || explicit === 'panic') {
        return ReportType.Error;
    }
    if (explicit === 'warn' || explicit === 'warning') {
        return ReportType.Warn;
    }
    if (explicit === 'debug' || explicit === 'trace') {
        return ReportType.Debug;
    }
    if (explicit === 'info' || explicit === 'log') {
        return ReportType.Info;
    }
    if (errorMarker.test(message)) {
        return ReportType.Error;
    }
    if (warningMarker.test(message)) {
        return ReportType.Warn;
    }
    return fallback;
}

export class Output {
    constructor(private readonly channel: vscode.OutputChannel) {}

    public get name(): string {
        return this.channel.name;
    }

    public report(message: string | unknown, option: ReportOption = {}): void {
        if (message === undefined || message === null || message === '') {
            return;
        }
        const level = option.level ?? ReportType.Info;
        const text = String(message);
        if (level === ReportType.PrintOuput) {
            this.channel.appendLine(text);
        } else {
            const prefix = level === ReportType.Finish ? '\n' : '';
            this.channel.appendLine(`${prefix}[${level} - ${this.getCurrentTime()}] ${text}`);
        }
        if (option.notify) {
            this.showNotification(text, level);
        }
    }

    public show(): void {
        this.channel.show(true);
    }

    public clear(): void {
        this.channel.clear();
    }

    private getCurrentTime(): string {
        const date = new Date();
        return [date.getHours(), date.getMinutes(), date.getSeconds()]
            .map(value => value.toString().padStart(2, '0'))
            .join(':');
    }

    private showNotification(message: string, level: ReportType): void {
        if (level === ReportType.Warn) {
            void vscode.window.showWarningMessage(message);
        } else if (level === ReportType.Error) {
            void vscode.window.showErrorMessage(message);
        } else {
            void vscode.window.showInformationMessage(message);
        }
    }
}

const mainOutputChannel = vscode.window.createOutputChannel('Digital-IDE');
const hardwareOutputChannel = vscode.window.createOutputChannel('Digital-IDE Hardware');
const waveOutputChannel = vscode.window.createOutputChannel('Digital-IDE Waveform');

class RoutedServerOutputChannel implements vscode.OutputChannel {
    private pending = '';
    private flushTimer: ReturnType<typeof setTimeout> | undefined;

    public get name(): string {
        return mainOutputChannel.name;
    }

    public append(value: string): void {
        this.pending += value;
        this.drainCompleteLines();
        this.schedulePendingFlush();
    }

    public appendLine(value: string): void {
        this.flushPending();
        this.routeLine(value);
    }

    public replace(value: string): void {
        this.clearPending();
        for (const line of value.split(/\r?\n/)) {
            this.routeLine(line);
        }
    }

    public clear(): void {
        this.clearPending();
    }

    public show(columnOrPreserveFocus?: vscode.ViewColumn | boolean, preserveFocus?: boolean): void {
        if (typeof columnOrPreserveFocus === 'boolean' || columnOrPreserveFocus === undefined) {
            mainOutputChannel.show(columnOrPreserveFocus);
        } else {
            mainOutputChannel.show(columnOrPreserveFocus, preserveFocus);
        }
    }

    public hide(): void {
        mainOutputChannel.hide();
    }

    public dispose(): void {
        this.clearPending();
    }

    private drainCompleteLines(): void {
        while (true) {
            const newline = this.pending.indexOf('\n');
            if (newline < 0) {
                return;
            }
            const line = this.pending.slice(0, newline).replace(/\r$/, '');
            this.pending = this.pending.slice(newline + 1);
            this.routeLine(line);
        }
    }

    private schedulePendingFlush(): void {
        if (!this.pending) {
            return;
        }
        if (this.flushTimer) {
            clearTimeout(this.flushTimer);
        }
        this.flushTimer = setTimeout(() => this.flushPending(), 25);
    }

    private flushPending(): void {
        if (this.flushTimer) {
            clearTimeout(this.flushTimer);
            this.flushTimer = undefined;
        }
        if (!this.pending) {
            return;
        }
        const line = this.pending.replace(/\r$/, '');
        this.pending = '';
        this.routeLine(line);
    }

    private clearPending(): void {
        if (this.flushTimer) {
            clearTimeout(this.flushTimer);
            this.flushTimer = undefined;
        }
        this.pending = '';
    }

    private routeLine(line: string): void {
        const level = classifyLogLevel(line, ReportType.Debug);
        if (level !== ReportType.Warn
            && level !== ReportType.Error
            && !serverLaunchMarker.test(line)) {
            return;
        }
        const target = serverTarget.exec(line)?.[1]?.toLowerCase() ?? '';
        if (target.startsWith('digital_server::wave')) {
            waveOutputChannel.appendLine(line);
        } else if (target.startsWith('digital_server::manager')
            || target.startsWith('digital_server::debugger')
            || target.startsWith('digital_server::driver')) {
            hardwareOutputChannel.appendLine(line);
        } else {
            mainOutputChannel.appendLine(line);
        }
    }
}

const serverOutputChannel: vscode.OutputChannel = new RoutedServerOutputChannel();
const outputChannels: readonly vscode.OutputChannel[] = [
    mainOutputChannel,
    hardwareOutputChannel,
    waveOutputChannel,
];

const MainOutput = new Output(mainOutputChannel);
const HardwareOutput = new Output(hardwareOutputChannel);
const WaveOutput = new Output(waveOutputChannel);

// Only three channels are exposed. Existing feature names map to their owning channel.
const LinterOutput = MainOutput;
const YosysOutput = MainOutput;
const HardwareErrorOutput = HardwareOutput;
const DebuggerOutput = HardwareOutput;
const WaveViewOutput = WaveOutput;

export {
    ReportType,
    MainOutput,
    LinterOutput,
    YosysOutput,
    HardwareOutput,
    HardwareErrorOutput,
    DebuggerOutput,
    WaveOutput,
    WaveViewOutput,
    mainOutputChannel,
    hardwareOutputChannel,
    waveOutputChannel,
    serverOutputChannel,
    outputChannels,
};
