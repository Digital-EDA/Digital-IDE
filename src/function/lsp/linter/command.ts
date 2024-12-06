import * as vscode from 'vscode';
import * as fs from 'fs';

import { vivadoLinter } from './vivado';
import { modelsimLinter } from './modelsim';
import { HdlLangID } from '../../../global/enum';
import { t } from '../../../i18n';
import { LspClient } from '../../../global';
import { LinterStatusRequestType, UpdateConfigurationType } from '../../../global/lsp';
import { LanguageClient } from 'vscode-languageclient/node';

export let _selectVlogLinterItem: LinterItem | null = null;
export let _selectSvlogLinterItem: LinterItem | null = null;
export let _selectVhdlLinterItem: LinterItem | null = null;

export const VLOG_LINTER_CONFIG_NAME = 'digital-ide.function.lsp.linter.vlog';
export const VHDL_LINTER_CONFIG_NAME = 'digital-ide.function.lsp.linter.vhdl';
export const SVLOG_LINTER_CONFIG_NAME = 'digital-ide.function.lsp.linter.svlog';

// 第三方诊断器路径的相关配置
// iverilog     digital-ide.prj.iverilog.install.path
// vivado       digital-ide.prj.vivado.install.path
// modelsim     digital-ide.prj.modelsim.install.path
// verible      digital-ide.prj.verible.install.path
// verilator    digital-ide.prj.verilator.install.path
export type SupportLinterName = 'iverilog' | 'vivado' | 'modelsim' | 'verible' | 'verilator';
export const LinterInstallPathConfigurationNames: Record<SupportLinterName, string> = {
    iverilog: 'digital-ide.prj.iverilog.install.path',
    vivado: 'digital-ide.prj.vivado.install.path',
    modelsim: 'digital-ide.prj.modelsim.install.path',
    verible: 'digital-ide.prj.verible.install.path',
    verilator: 'digital-ide.prj.verilator.install.path'
};

interface LinterItem extends vscode.QuickPickItem {
    name: string
    linterPath: string
    available: boolean
}

async function makeLinterNamePickItem(
    client: LanguageClient,
    langID: HdlLangID,
    linterName: SupportLinterName
): Promise<LinterItem> {
    const configuration = vscode.workspace.getConfiguration();
    const linterInstallConfigurationName = LinterInstallPathConfigurationNames[linterName];
    const linterPath = configuration.get<string>(linterInstallConfigurationName, '');

    const linterStatus = await client.sendRequest(LinterStatusRequestType, {
        languageId: langID,
        linterName,
        linterPath
    });
    
    return {
        label: '$(getting-started-beginner) ' + linterName,
        name: linterName,
        linterPath,
        available: linterStatus.available,
        description: linterName + ' ' + t('info.common.linter-name') + ' ' + linterStatus.toolName,
        detail: t('info.common.some-is-ready', linterStatus.invokeName)
    }
}



async function makeLinterOptions(
    client: LanguageClient,
    langID: HdlLangID,
    linters: SupportLinterName[]
) {
    const pools = [];
    for (const name of linters) {
        pools.push(makeLinterNamePickItem(client, langID, name))
    }

    const items = [];
    for (const p of pools) {
        items.push(await p);
    }
    return items;
}

/**
 * @description 选择 verilog 的诊断器
 */
export async function pickVlogLinter() {
    const pickWidget = vscode.window.createQuickPick<LinterItem>();
    pickWidget.placeholder = t('info.linter.pick-for-verilog');
    pickWidget.canSelectMany = false;

    const client = LspClient.DigitalIDE;
    if (!client) {
        // 尚未启动，退出
        return;
    }

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('info.command.loading'),
        cancellable: true
    }, async () => {
        pickWidget.items = await makeLinterOptions(client, HdlLangID.Verilog, [
            'iverilog',
            'modelsim',
            'verible',
            'verilator',
            'vivado'
        ]);
    });
    
    pickWidget.onDidChangeSelection(items => {
        _selectVlogLinterItem = items[0];
    });

    pickWidget.onDidAccept(async () => {
        if (_selectVlogLinterItem) {
            const linterConfiguration = vscode.workspace.getConfiguration(VLOG_LINTER_CONFIG_NAME);
            linterConfiguration.update('diagnostor', _selectVlogLinterItem.name);
            
            await LspClient.DigitalIDE?.sendRequest(UpdateConfigurationType, {
                configs: [
                    { name: VLOG_LINTER_CONFIG_NAME + '.diagnostor', value: _selectVlogLinterItem.name },
                    { name: 'path', value: _selectVlogLinterItem.linterPath }
                ],
                configType: 'linter'
            });

            pickWidget.hide();
        }
    });

    pickWidget.show();
}

/**
 * @description 选择 system verilog 的诊断器
 */
export async function pickSvlogLinter() {
    const pickWidget = vscode.window.createQuickPick<LinterItem>();
    pickWidget.placeholder = t('info.linter.pick-for-system-verilog');
    pickWidget.canSelectMany = false;

    const client = LspClient.DigitalIDE;
    if (!client) {
        // 尚未启动，退出
        return;
    }

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t("info.command.loading"),
        cancellable: true
    }, async () => {
        pickWidget.items = await makeLinterOptions(client, HdlLangID.SystemVerilog, [
            'modelsim',
            'verible',
            'verilator',
            'vivado'
        ]);
    });
    
    pickWidget.onDidChangeSelection(items => {
        _selectSvlogLinterItem = items[0];
    });

    pickWidget.onDidAccept(async () => {
        if (_selectSvlogLinterItem) {
            const linterConfiguration = vscode.workspace.getConfiguration(SVLOG_LINTER_CONFIG_NAME);
            linterConfiguration.update('diagnostor', _selectSvlogLinterItem.name);
            
            await LspClient.DigitalIDE?.sendRequest(UpdateConfigurationType, {
                configs: [
                    { name: SVLOG_LINTER_CONFIG_NAME + '.diagnostor', value: _selectSvlogLinterItem.name },
                    { name: 'path', value: _selectSvlogLinterItem.linterPath }
                ],
                configType: 'linter'
            });

            pickWidget.hide();
        }
    });

    pickWidget.show();
}

/**
 * @description 选择 vhdl 的诊断器
 */
export async function pickVhdlLinter() {
    const pickWidget = vscode.window.createQuickPick<LinterItem>();
    pickWidget.placeholder = t('info.linter.pick-for-vhdl');
    pickWidget.canSelectMany = false;

    const client = LspClient.DigitalIDE;
    if (!client) {
        // 尚未启动，退出
        return;
    }

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t("info.command.loading"),
        cancellable: true
    }, async () => {
        pickWidget.items = await makeLinterOptions(client, HdlLangID.Vhdl, [
            'modelsim',
            'vivado'
        ]);
    });
    
    pickWidget.onDidChangeSelection(items => {
        _selectVhdlLinterItem = items[0];
    });

    pickWidget.onDidAccept(async () => {
        if (_selectVhdlLinterItem) {
            const linterConfiguration = vscode.workspace.getConfiguration(VHDL_LINTER_CONFIG_NAME);
            linterConfiguration.update('diagnostor', _selectVhdlLinterItem.name);

            await LspClient.DigitalIDE?.sendRequest(UpdateConfigurationType, {
                configs: [
                    { name: VHDL_LINTER_CONFIG_NAME + '.diagnostor', value: _selectVhdlLinterItem.name },
                    { name: 'path', value: _selectVhdlLinterItem.linterPath },
                ],
                configType: 'linter'
            });

            pickWidget.hide();
        }
    });

    pickWidget.show();
}
