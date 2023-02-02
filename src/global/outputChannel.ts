/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';

enum ReportType {
    Debug = 'Debug',
    Launch = 'Launch',
    Performance = 'Performance',
    PathCheck = 'Path Check',
    Info = 'Info',
    Warn = 'Warn',
    Error = 'Error'
};

class Output {
    private _output: vscode.OutputChannel;
    private _ignoreTypes: ReportType[];

    constructor(title: string, ignoreType: ReportType[] = []) {
        this._output = vscode.window.createOutputChannel(title);
        this._ignoreTypes = ignoreType;
    }

    skipMessage(type: ReportType) : boolean {
        return this._ignoreTypes.includes(type);
    }

    report(message: string, type: ReportType = ReportType.Debug) {
        if (!this.skipMessage(type) && message) {
            this._output.show(true);
            this._output.appendLine('[' + type + '] ' + message);
        }
    }
}

const MainOutput = new Output('Digital-IDE');
const YosysOutput = new Output('Yosys');

export {
    ReportType,
    MainOutput,
    YosysOutput
};