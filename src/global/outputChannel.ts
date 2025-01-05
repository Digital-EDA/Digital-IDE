/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';

enum ReportType {
    /**
     * debug
     */
    Debug = 'Debug',
    /**
     * 某些模块或者子进程启动函数中的输出，用来判断子模块是否正常启动
     */
    Launch = 'Launch',
    /**
     * 测量性能相关的输出
     */
    Performance = 'Performance',
    /**
     * debug 查看路径有效性相关的输出
     */
    PathCheck = 'Path Check',
    /**
     * 普通消息的信息
     */
    Info = 'Info',
    /**
     * warn 等级的信息
     */
    Warn = 'Warn',
    /**
     * error 等级的信息
     */
    Error = 'Error',
    /**
     * 某些功能或者子进程在运行中产出的信息
     */
    Run = 'Run',
    /**
     * 展示程序的输出
     */
    PrintOuput = 'PrintOutput',
    /**
     * 代表程序的结束
     */
    Finish = 'Finish'
};

interface ReportOption {
    /**
     * 汇报的等级，类似于日志系统中的 level，详见 
     * [ReportType](https://github.com/Digital-EDA/Digital-IDE/blob/main/src/global/outputChannel.ts#L4)
     */
    level?: ReportType,
    /**
     * 用于控制是否同时也在窗口右下角展示信息。如果为 true，则同时会
     * 调用 vscode.window.showInformationMessage 在右下角展示信息。默认为 false
     */
    notify?: boolean
}

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
     * @description 信息汇报函数，用于将字符串显示在 Output 窗口中，也可可以同时显示右下角的窗口中
     * @param message message
     * @param option 汇报的选项
     */
    public report(message: string | unknown, option?: ReportOption) {
        option = option || { level: ReportType.Info, notify: false } as ReportOption;
        const level = option.level || ReportType.Info;
        const notify = option.notify || false;

        if (!this.skipMessage(level) && message) {
            const currentTime = this.getCurrentTime();

            switch (option.level) {
                case ReportType.PrintOuput:
                    this._output.appendLine(message.toString());
                    break;
                case ReportType.Finish:
                    this._output.appendLine('\n[' + level + ' - ' + currentTime + '] ' + message);
                    break;
            
                default:
                    this._output.appendLine('[' + level + ' - ' + currentTime + '] ' + message);
                    if (notify) {
                        this.showInWindows('' + message, level);
                    }
                    break;
            }
        }
    }

    public show() {
        this._output.show(true);
    }

    public clear() {
        this._output.clear();
    }
}

const MainOutput = new Output('Digital-IDE');
const LinterOutput = new Output('Digital-IDE Linter');
const YosysOutput = new Output('Digital-IDE Yosys');
const WaveViewOutput = new Output('Digital-IDE Wave Viewer');
const HardwareOutput = new Output('Digital-IDE Hareware');
const HardwareErrorOutput = new Output('Digital-IDE Hareware Error');

export {
    ReportType,
    MainOutput,
    LinterOutput,
    YosysOutput,
    WaveViewOutput,
    HardwareOutput,
    HardwareErrorOutput
};