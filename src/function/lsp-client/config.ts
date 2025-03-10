import * as vscode from 'vscode';
import { LanguageClient } from 'vscode-languageclient/node';
import { UpdateConfigurationType } from '../../global/lsp';
import * as Linter from '../lsp/linter/common';
import { HdlLangID } from '../../global/enum';
import * as lspLinter from '../lsp/linter';
import { t } from '../../i18n';
import { globalLookup, IProgress } from '../../global';
import { clearDiagnostics, publishDiagnostics, refreshWorkspaceDiagonastics } from '../lsp/linter/manager';
import { prjManage } from '../../manager';
import { hdlFile, hdlPath } from '../../hdlFs';

interface ConfigItem {
    name: string,
    value: CommonValue
}

type CommonValue = string | boolean | number;

/**
 * @description 注册配置文件变动时发生的操作
 * 该操作一定发生在 lsp 启动后。
 * @param client 
 * @param packageJson 
 */
export async function registerConfigurationUpdater(client: LanguageClient, packageJson: any) {
    // 常规 lsp 相关的配置
    const lspConfigures: ConfigItem[] = [];
    const properties = packageJson?.contributes?.configuration?.properties;
    const dideConfig = vscode.workspace.getConfiguration('digital-ide');
    for (const propertyName of Object.keys(properties) || []) {
        if (propertyName.includes('function.lsp')) {
            const section = propertyName.slice(12);
            let value = dideConfig.get<CommonValue>(section, '');
            lspConfigures.push({ name: propertyName, value });
        }
    }

    const supportLinters: Linter.SupportLinterName[] = ['iverilog', 'vivado', 'modelsim', 'verible', 'verilator'];

    // 初始化，配置参数全部同步到后端
    await client.sendRequest(UpdateConfigurationType, {
        configs: lspConfigures,
        configType: 'lsp'
    });

    // 初始化，配置全部 linter 到后端
    await updateLinterInstallPathConfiguration(
        client,
        Linter.getLinterConfigurationName(HdlLangID.Verilog)
    );
    await updateLinterConfiguration(
        client,
        Linter.getLinterConfigurationName(HdlLangID.Verilog),
        Linter.getLinterName(HdlLangID.Verilog)
    );

    await updateLinterInstallPathConfiguration(
        client,
        Linter.getLinterConfigurationName(HdlLangID.SystemVerilog)
    );
    await updateLinterConfiguration(
        client,
        Linter.getLinterConfigurationName(HdlLangID.SystemVerilog),
        Linter.getLinterName(HdlLangID.SystemVerilog)
    );

    await updateLinterInstallPathConfiguration(
        client,
        Linter.getLinterConfigurationName(HdlLangID.Vhdl)
    );
    await updateLinterConfiguration(
        client,
        Linter.getLinterConfigurationName(HdlLangID.Vhdl),
        Linter.getLinterName(HdlLangID.Vhdl)
    );

    // 监听配置文件的变化，变化时需要做出的行为
    vscode.workspace.onDidChangeConfiguration(async event => {
        const changeConfigs: ConfigItem[] = [];
        const dideConfig = vscode.workspace.getConfiguration('');
        for (const config of lspConfigures) {
            if (event.affectsConfiguration(config.name)) {
                const lastestValue = dideConfig.get<CommonValue>(config.name, '');
                changeConfigs.push({ name: config.name, value: lastestValue });
            }
        }

        if (changeConfigs.length > 0) {
            await client.sendRequest(UpdateConfigurationType, {
                configs: changeConfigs,
                configType: 'lsp'
            });
        }

        // 本次更新时，当前各个语言正在使用的诊断器的名字的映射表
        // 因为 getLinterName 需要进行一次映射，此处为后续的遍历预缓存一波
        const currentLinterConfiguration: Record<HdlLangID, string> = {
            [HdlLangID.Verilog]: Linter.getLinterName(HdlLangID.Verilog),
            [HdlLangID.SystemVerilog]: Linter.getLinterName(HdlLangID.SystemVerilog),
            [HdlLangID.Vhdl]: Linter.getLinterName(HdlLangID.Vhdl),
            [HdlLangID.Unknown]: HdlLangID.Unknown
        };
        
        const linterManager: Record<HdlLangID, lspLinter.LinterManager> = {
            [HdlLangID.Verilog]: lspLinter.vlogLinterManager,
            [HdlLangID.SystemVerilog]: lspLinter.svlogLinterManager,
            [HdlLangID.Vhdl]: lspLinter.vhdlLinterManager,
            [HdlLangID.Unknown]: lspLinter.reserveLinterManager
        };

        // 需要讨论的可能受到配置文件更新影响 linter 功能的语言列表
        const affectsLangIDs = [HdlLangID.Verilog, HdlLangID.SystemVerilog, HdlLangID.Vhdl];

        // 对于诊断器路径的修改
        for (const linterName of supportLinters) {
            const configuratioName = Linter.getLinterInstallConfigurationName(linterName);
            if (event.affectsConfiguration(configuratioName)) {
                // 查看谁使用了这个诊断器，更新它的基本信息
                for (const langID of affectsLangIDs) {
                    if (linterName === currentLinterConfiguration[langID]) {
                        const linterConfigurationName = Linter.getLinterConfigurationName(langID);
                        // 低频操作，随便糟蹋
                        await updateLinterConfiguration(client, linterConfigurationName, linterName);
                        // 更新当前诊断器状态
                        await linterManager[langID].updateCurrentLinterItem();
                        linterManager[langID].updateStatusBar();
                    }
                }
            }
        }

        // 如果诊断模式发生变化，进行一次刷新
        if (event.affectsConfiguration(Linter.getLinterModeConfigurationName())) {
            await vscode.window.withProgress({
                location: vscode.ProgressLocation.Window,
                title: t('info.progress.doing-diagnostic')
            }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
                const hdlFiles = await prjManage.getPrjHardwareFiles();
                await refreshWorkspaceDiagonastics(client, hdlFiles, false, progress);
            });
        }
    });
}

export async function registerLinter(client: LanguageClient) {
    // 初始化，配置全部 linter 到 linterManager
    lspLinter.vlogLinterManager.start(client);
    lspLinter.vhdlLinterManager.start(client);
    lspLinter.svlogLinterManager.start(client);

    // 对应配置文件的变动需要修改全局的相关变量
    vscode.workspace.onDidChangeConfiguration(async event => {        
        if (event.affectsConfiguration(Linter.getLinterConfigurationName(HdlLangID.Verilog))) {
            await lspLinter.vlogLinterManager.updateCurrentLinterItem(client);
            lspLinter.vlogLinterManager.updateStatusBar();
        }

        if (event.affectsConfiguration(Linter.getLinterConfigurationName(HdlLangID.SystemVerilog))) {
            await lspLinter.svlogLinterManager.updateCurrentLinterItem(client);
            lspLinter.svlogLinterManager.updateStatusBar();
        }

        if (event.affectsConfiguration(Linter.getLinterConfigurationName(HdlLangID.Vhdl))) {
            await lspLinter.vhdlLinterManager.updateCurrentLinterItem(client);
            lspLinter.vhdlLinterManager.updateStatusBar();
        }
    });

    // 切换标签页时的行为
    vscode.window.onDidChangeActiveTextEditor(async editor => {
        if (!editor) {
            return;
        }
        const linterMode = Linter.getLinterMode();
        const currentPath = hdlPath.toEscapePath(editor.document.fileName);
        if (globalLookup.activeEditor && linterMode === 'common') {
            const previousPath = hdlPath.toEscapePath(globalLookup.activeEditor.document.fileName);
            if (hdlFile.isHDLFile(previousPath)) {
                clearDiagnostics(client, previousPath);
            }
            if (hdlFile.isHDLFile(currentPath)) {
                publishDiagnostics(client, currentPath);
            }
        }

        globalLookup.activeEditor = editor;
    });
}

/**
 * @description 更新所有诊断器的路径信息到后端
 */
async function updateLinterInstallPathConfiguration(
    client: LanguageClient,
    configurationName: string
) {
    for (const linterName of Linter.SupportLinters) {
        await updateLinterConfiguration(client, configurationName, linterName);
    }
}

/**
 * @description 更新当前诊断器的所有信息到后端
 */
async function updateLinterConfiguration(
    client: LanguageClient,
    configurationName: string,
    linterName: Linter.SupportLinterName
) {
    const linterPath = Linter.getLinterInstallPath(linterName);
    await client.sendRequest(UpdateConfigurationType, {
        configs: [
            { name: configurationName, value: linterName },
            { name: 'path', value: linterPath }
        ],
        configType: 'linter'
    });
}
