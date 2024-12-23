import * as vscode from 'vscode';
import * as os from 'os';

import { LspClient, LinterOutput, ReportType, AbsPath, IProgress } from '../../../global';
import { HdlLangID } from '../../../global/enum';
import { hdlFile, hdlPath } from '../../../hdlFs';
import { t } from '../../../i18n';
import { getLinterConfigurationName, getLinterInstallConfigurationName, getLinterName, IConfigReminder, LinterItem, LinterMode, makeLinterNamePickItem, makeLinterOptions, SupportLinterName, updateLinterConfigurationName } from './common';
import { UpdateConfigurationType } from '../../../global/lsp';
import { LanguageClient } from 'vscode-languageclient/node';
import { toEscapePath } from '../../../hdlFs/path';

export class LinterManager {
    /**
     * @description 当前诊断器管理者绑定的语言
     */
    langID: HdlLangID;

    /**
     * @description 描述当前诊断器管理者支持哪些第三方诊断器
     */
    supportLinters: SupportLinterName[];

    /**
     * @description 内部变量，用来存储用户选择的诊断器，也是 picker 操作结果的绑定值
     */
    currentLinterItem: LinterItem | undefined;

    /**
     * @description 诊断器管理者绑定的右下角的 status item
     */
    statusBarItem: vscode.StatusBarItem;
    
    /**
     * @description 用户保证 start 函数的必要操作为幂等的
     */
    started: boolean;

    /**
     * @description 绑定的 lsp，当 started 为 true 时，该值一定不为 undefined
     */
    lspClient: LanguageClient | undefined;

    constructor(langID: HdlLangID, supportLinters: SupportLinterName[]) {
        this.langID = langID;
        this.supportLinters = supportLinters;
        this.started = false;
        this.currentLinterItem = undefined;
        this.lspClient = undefined;
        
        // 在窗体右下角创建一个状态栏，用于显示目前激活的诊断器
        this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right);
        this.statusBarItem.command = this.getLinterPickCommand();

        // 对切换时间进行监听，如果不是目前的语言，则隐藏
        this.registerActiveTextEditorChangeEvent(langID);
    }

    /**
     * @description 根据 语言 或者对应选择诊断器的 command
     * @param langID 
     * @returns 
     */
    public getLinterPickCommand() {
        switch (this.langID) {
            case HdlLangID.Verilog:
                return 'digital-ide.lsp.vlog.linter.pick';
            case HdlLangID.SystemVerilog:
                return 'digital-ide.lsp.svlog.linter.pick';
            case HdlLangID.Vhdl:
                return 'digital-ide.lsp.vhdl.linter.pick';
            default:
                break;
        }
        return 'digital-ide.lsp.vlog.linter.pick';
    }

    /**
     * @description 手动更新 currentLinterItem，仅在外部更新 status bar 时使用
     * @param client 
     */
    public async updateCurrentLinterItem(client?: LanguageClient) {
        client = client ? client : this.lspClient;
        if (client) {
            const linterName = getLinterName(this.langID);
            this.currentLinterItem = await makeLinterNamePickItem(client, this.langID, linterName);
        }
    }

    /**
     * @description 启动诊断器
     * @returns 
     */
    async start(client: LanguageClient): Promise<void> {
        // 根据配置选择对应的诊断器
        await this.updateCurrentLinterItem(client);

        // 注册内部命令
        if (!this.started) {
            const pickerCommand = this.getLinterPickCommand();
            vscode.commands.registerCommand(pickerCommand, () => {
                this.pickLinter();
            });
        }

        // 保证幂等
        this.started = true;
        this.lspClient = client;

        // 如果当前窗口语言为绑定语言，则显示 bar；否则，隐藏它
        const editor = vscode.window.activeTextEditor;
        if (editor && this.langID === hdlFile.getLanguageId(editor.document.fileName)) {
            this.updateStatusBar();
        } else {
            this.statusBarItem.hide();
        }

        LinterOutput.report(t('info.linter.finish-init', this.langID, this.currentLinterItem?.name || 'unknown'), {
            level: ReportType.Launch
        });
    }

    /**
     * @description 更新右下角 status bar 的状态
     */
    public updateStatusBar() {
        const statusBarItem = this.statusBarItem;
        const currentLinterItem = this.currentLinterItem;
        if (currentLinterItem) {            
            if (currentLinterItem.available) {
                // 当前诊断器正常
                statusBarItem.backgroundColor = new vscode.ThemeColor('statusBar.background');
                statusBarItem.tooltip = t('info.linter.status-bar.tooltip', currentLinterItem.name);
                statusBarItem.text = `$(getting-started-beginner) Linter(${currentLinterItem.name})`;
                LinterOutput.report(t('info.linter.finish-init', this.langID, currentLinterItem.name));
            } else {
                // 当前诊断器不可用
                statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
                statusBarItem.tooltip = t('error.linter.status-bar.tooltip', currentLinterItem.name);
                statusBarItem.text = `$(extensions-warning-message) Linter(${currentLinterItem.name})`;
                LinterOutput.report(t('error.linter.status-bar.tooltip', currentLinterItem.name), {
                    level: ReportType.Error
                });
                // 当前诊断器不可用，遂提醒用户【配置文件】or【下载（如果有的话）】
                vscode.window.showWarningMessage<IConfigReminder>(
                    t('warning.linter.cannot-get-valid-linter-invoker', currentLinterItem.name),
                    { title: t('info.linter.config-linter-install-path'),  value: "config" },
                ).then(async res => {
                    // 用户选择配置
                    if (res?.value === 'config') {
                        const linterInstallConfigurationName = getLinterInstallConfigurationName(currentLinterItem.name);
                        await vscode.commands.executeCommand('workbench.action.openSettings', linterInstallConfigurationName);
                    }
                    // 用户选择下载
                    if (res?.value === 'download') {

                    }
                });

                
            }
            statusBarItem.show();
        }
    }

    private registerActiveTextEditorChangeEvent(langID: HdlLangID) {
        vscode.window.onDidChangeActiveTextEditor(editor => {
            if (!editor) {
                return;
            }
            const currentFileName = hdlPath.toSlash(editor.document.fileName);
            const currentID = hdlFile.getLanguageId(currentFileName);
            if (langID === currentID) {                
                this.updateStatusBar();
            } else {
                this.statusBarItem.hide();
            }
        });
    }

    private makePickTitle() {
        switch (this.langID) {
            case HdlLangID.Verilog:
                return t("info.linter.pick-for-verilog");
            case HdlLangID.SystemVerilog:
                return t("info.linter.pick-for-system-verilog");
            case HdlLangID.Vhdl:
                return t("info.linter.pick-for-vhdl");
            default:
                return t("info.linter.pick-for-verilog");
        }
    }

    /**
     * @description 为当前的语言选择一个诊断器
     */
    public async pickLinter() {
        const pickWidget = vscode.window.createQuickPick<LinterItem>();
        pickWidget.placeholder = this.makePickTitle();
        pickWidget.canSelectMany = false;

        const client = this.lspClient;
        if (!client) {
            return;
        }

        // 制作 pick 的选项卡，选项卡的每一个子项目都经过检查
        await vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: t('info.command.loading'),
            cancellable: true
        }, async () => {
            pickWidget.items = await makeLinterOptions(client, this.langID, this.supportLinters);
        });

        // 激活当前的 linter name 对应的选项卡
        const currentLinterName = getLinterName(this.langID);
        const activeItems = pickWidget.items.filter(item => item.name === currentLinterName);
        pickWidget.activeItems = activeItems;

        pickWidget.onDidChangeSelection(items => {
            this.currentLinterItem = items[0];
        });

        pickWidget.onDidAccept(async () => {
            if (this.currentLinterItem) {

                // 更新后端
                await client.sendRequest(UpdateConfigurationType, {
                    configs: [
                        { name: getLinterConfigurationName(this.langID), value: this.currentLinterItem.name },
                        { name: 'path', value: this.currentLinterItem.linterPath }
                    ],
                    configType: 'linter'
                });
                // 更新 vscode 配置文件，这会改变配置，顺便触发一次 this.updateStatusBar()
                // 详细请见 async function registerLinter(client: LanguageClient)
                updateLinterConfigurationName(this.langID, this.currentLinterItem.name);

                pickWidget.hide();
            }
        });

        pickWidget.show();
    }
}

export async function publishDiagnostics(
    client: LanguageClient,
    path: string
) {
    await client.sendRequest("workspace/executeCommand", {
        command: 'publish-diagnostics',
        arguments: [path]
    });
}

export async function clearDiagnostics(
    client: LanguageClient,
    path: string
) {
    await client.sendRequest("workspace/executeCommand", {
        command: 'clear-diagnostics',
        arguments: [path]
    });
}

/**
 * @description 异步方法的受限并发消费
 * @param arrays 
 * @param consumer 
 * @param poolNum 
 */
export async function asyncConsumer<T, R>(
    arrays: T[],
    consumer: (item: T) => Promise<R>,
    poolNum: number,
    progress?: vscode.Progress<IProgress>
): Promise<R[]> {
    const rets: R[] = [];
    const pools = [];
    let i = 0;

    progress?.report({ message: `${1}/${arrays.length}`, increment: 0 });

    while (i < arrays.length) {
        const p = consumer(arrays[i]);
        pools.push({ id: i + 1, promise: p });
        if (pools.length % poolNum === 0) {
            for (const p of pools) {
                const ret = await p.promise;
                const increment = Math.floor(p.id / arrays.length * 100);
                progress?.report({ message: `${p.id}/${arrays.length}`, increment });
                rets.push(ret);
            }
            pools.length = 0;
        }
        i ++;
    }
    
    for (const p of pools) {
        const ret = await p.promise;
        const increment = Math.floor(p.id / arrays.length * 100);
        progress?.report({ message: `${p.id}/${arrays.length}`, increment });
        rets.push(ret);
    }

    return rets;
}

/**
 * @description 刷新当前工作区所有文件的 linter 状态。仅仅在初始化和更新配置文件时需要使用。
 */
export async function refreshWorkspaceDiagonastics(
    client: LanguageClient,
    lintPaths: AbsPath[],
    isInitialise: boolean,
    progress: vscode.Progress<IProgress>
) {
    const parallelChunk = Math.min(os.cpus().length, 32);
    const configuration = vscode.workspace.getConfiguration();
    const linterMode = configuration.get<LinterMode>('digital-ide.function.lsp.linter.linter-mode', LinterMode.Common);
        
    if (linterMode === LinterMode.Full) {
        // full，对工作区所有文件进行诊断
        const consumer = async (path: string) => {
            await publishDiagnostics(client, path);
        }
        await asyncConsumer(lintPaths, consumer, parallelChunk, progress);
    } else if (linterMode === LinterMode.Common) {
        // common, 只对打开文件进行操作
        // 先清除所有的诊断结果
        const clearConsumer = async (path: string) => {
            await clearDiagnostics(client, path);
        }
        await asyncConsumer(lintPaths, clearConsumer, parallelChunk);

        // 再对激活区域进行诊断
        const consumer = async (path: string) => {
            await publishDiagnostics(client, path);
        }

        const tabs = vscode.window.tabGroups.all;
        const tabArray = tabs.flatMap<AbsPath>(group => {
            const files = [];
            for (const tab of group.tabs) {
                if (tab.input) {
                    const doc = tab.input as vscode.TabInputText;
                    if (doc.uri) {
                        const absPath = hdlPath.toEscapePath(doc.uri.fsPath);
                        files.push(absPath);
                    }
                }
            }
            return files;
        });
        
        await asyncConsumer(tabArray, consumer, parallelChunk, progress);
    } else {
        // shutdown, 如果是初始化阶段，什么都不需要做
        const consumer = async (path: string) => {
            await clearDiagnostics(client, path);
        };
        if (!isInitialise) {
            await asyncConsumer(lintPaths, consumer, parallelChunk, progress);
        }
    }
}

export const vlogLinterManager = new LinterManager(HdlLangID.Verilog, [
    'iverilog',
    'modelsim',
    'verible',
    'verilator',
    'vivado'
]);
export const vhdlLinterManager = new LinterManager(HdlLangID.Vhdl, [
    'modelsim',
    'vivado'
]);
export const svlogLinterManager = new LinterManager(HdlLangID.SystemVerilog, [
    'modelsim',
    'verible',
    'verilator',
    'vivado'
]);
export const reserveLinterManager = new LinterManager(HdlLangID.Unknown, []);