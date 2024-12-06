import * as vscode from 'vscode';
import { LanguageClient } from 'vscode-languageclient/node';
import { UpdateConfigurationType } from '../../global/lsp';
import * as linterCommand from '../../function/lsp/linter/command';
import { HdlLangID } from '../../global/enum';

interface ConfigItem {
    name: string,
    value: CommonValue
}

type CommonValue = string | boolean | number;

export function registerConfigurationUpdater(client: LanguageClient, packageJson: any) {
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

    const supportLinters: linterCommand.SupportLinterName[] = ['iverilog', 'vivado', 'modelsim', 'verible', 'verilator'];

    // 初始化，配置参数全部同步到后端
    client.sendRequest(UpdateConfigurationType, {
        configs: lspConfigures,
        configType: 'lsp'
    });

    // 初始化，配置全部 linter 到后端
    updateLinterConfiguration(
        client,
        linterCommand.VLOG_LINTER_CONFIG_NAME + '.diagnostor',
        getCurrentLinterName(HdlLangID.Verilog)
    );

    updateLinterConfiguration(
        client,
        linterCommand.SVLOG_LINTER_CONFIG_NAME + '.diagnostor',
        getCurrentLinterName(HdlLangID.SystemVerilog)
    );

    updateLinterConfiguration(
        client,
        linterCommand.VHDL_LINTER_CONFIG_NAME + '.diagnostor',
        getCurrentLinterName(HdlLangID.Vhdl)
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

        const currentLinterConfiguration = {
            vlog: getCurrentLinterName(HdlLangID.Verilog),
            svlog: getCurrentLinterName(HdlLangID.SystemVerilog),
            vhdl: getCurrentLinterName(HdlLangID.Vhdl)
        };

        // 对于诊断器路径的修改
        for (const linterName of supportLinters) {
            const configuratioName = linterCommand.LinterInstallPathConfigurationNames[linterName];
            if (event.affectsConfiguration(configuratioName)) {
                // 查看谁使用了这个诊断器，更新它的基本信息
                if (linterName === currentLinterConfiguration.vlog) {
                    await updateLinterConfiguration(
                        client,
                        linterCommand.VLOG_LINTER_CONFIG_NAME + '.diagnostor',
                        linterName
                    );
                }

                if (linterName === currentLinterConfiguration.svlog) {
                    await updateLinterConfiguration(
                        client,
                        linterCommand.SVLOG_LINTER_CONFIG_NAME + '.diagnostor',
                        linterName
                    );
                }

                if (linterName === currentLinterConfiguration.vhdl) {
                    await updateLinterConfiguration(
                        client,
                        linterCommand.VHDL_LINTER_CONFIG_NAME + '.diagnostor',
                        linterName
                    );
                }
            }
        }

    });
}

function getCurrentLinterName(langID: HdlLangID): linterCommand.SupportLinterName {
    switch (langID) {
        case HdlLangID.Verilog:
            return vscode.workspace.getConfiguration().get<linterCommand.SupportLinterName>(
                linterCommand.VLOG_LINTER_CONFIG_NAME + '.diagnostor',
                'vivado'
            );

        case HdlLangID.Vhdl:
            return vscode.workspace.getConfiguration().get<linterCommand.SupportLinterName>(
                linterCommand.VHDL_LINTER_CONFIG_NAME + '.diagnostor',
                'vivado'
            );
        
        case HdlLangID.SystemVerilog:
            return vscode.workspace.getConfiguration().get<linterCommand.SupportLinterName>(
                linterCommand.SVLOG_LINTER_CONFIG_NAME + '.diagnostor',
                'vivado'
            );

        default:
            break;
    }
    return 'vivado';
}

async function updateLinterConfiguration(
    client: LanguageClient,
    configurationName: string,
    linterName: linterCommand.SupportLinterName
) {
    const configuratioName = linterCommand.LinterInstallPathConfigurationNames[linterName];
    const linterPath = vscode.workspace.getConfiguration().get<string>(configuratioName, '');

    await client.sendRequest(UpdateConfigurationType, {
        configs: [
            { name: configurationName, value: linterName },
            { name: 'path', value: linterPath }
        ],
        configType: 'linter'
    });
}