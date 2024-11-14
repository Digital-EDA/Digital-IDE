import * as vscode from 'vscode';
import { LanguageClient } from 'vscode-languageclient/node';
import { UpdateConfigurationType } from '../../global/lsp';

interface ConfigItem {
    name: string,
    value: CommonValue
}

type CommonValue = string | boolean | number;

export function registerConfigurationUpdater(client: LanguageClient, packageJson: any) {
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

    // 初始化，配置参数全部同步到后端
    client.sendRequest(UpdateConfigurationType, {
        configs: lspConfigures,
        configType: 'lsp'
    });

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
    });
}