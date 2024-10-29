/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';

enum ReportType {
    Debug = 'Debug',
    Launch = 'Launch',
    Performance = 'Performance',
    PathCheck = 'Path Check',
    Info = 'Info',
    Warn = 'Warn',
    Error = 'Error',
    Run = 'Run'
};

class Output {
    private _output: vscode.OutputChannel;
    private _ignoreTypes: ReportType[];

    constructor(title: string, ignoreType: ReportType[] = []) {
        this._output = vscode.window.createOutputChannel(title);
        this._ignoreTypes = ignoreType;
    }

    private alignTime(s: number): string {
        const sstr: string = s + '';
        if (sstr.length === 1) {
            return '0' + sstr;
        } else {
            return sstr;
        }
    }

    private getCurrentTime() {
        const date = new Date();
        const hms = [date.getHours(), date.getMinutes(), date.getSeconds()];
        return hms.map(this.alignTime).join(':');
    }

    private skipMessage(type: ReportType) : boolean {
        return this._ignoreTypes.includes(type);
    }

    private showInWindows(message: string, type: ReportType = ReportType.Info) {
        if (type === ReportType.Warn) {
            vscode.window.showWarningMessage(message);
        } else if (type === ReportType.Error) {
            vscode.window.showErrorMessage(message);
        } else {
            vscode.window.showInformationMessage(message);
        }
    }

    /**
     * 
     * @param message message
     * @param type report type
     * @param reportInWindows whether use vscode.windows.<api> to show info
     */
    public report(message: string | unknown, type: ReportType = ReportType.Info, reportInWindows: boolean = false) {
        if (!this.skipMessage(type) && message) {
            // this._output.show(true);
            const currentTime = this.getCurrentTime();
            this._output.appendLine('[' + type + ' - ' + currentTime + '] ' + message);

            if (reportInWindows) {
                this.showInWindows('' + message, type);
            }
        }
    }

    public show() {
        this._output.show(true);
    }
}

const MainOutput = new Output('Digital-IDE');
const LspOutput = new Output('Digital-IDE Linter');
const YosysOutput = new Output('Digital-IDE Yosys');
const WaveViewOutput = new Output('Digital-IDE Wave Viewer');

export {
    ReportType,
    MainOutput,
    LspOutput,
    YosysOutput,
    WaveViewOutput
};