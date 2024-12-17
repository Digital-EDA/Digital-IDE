import * as vscode from 'vscode';
import * as fs from 'fs';

import { HdlLangID } from '../../../global/enum';
import { t } from '../../../i18n';
import { LspClient } from '../../../global';
import { LinterStatusRequestType, UpdateConfigurationType } from '../../../global/lsp';
import { LanguageClient } from 'vscode-languageclient/node';

export interface LinterItem extends vscode.QuickPickItem {
    name: SupportLinterName
    linterPath: string
    available: boolean
}

export let _selectVlogLinterItem: LinterItem | undefined = undefined;
export let _selectSvlogLinterItem: LinterItem | undefined = undefined;
export let _selectVhdlLinterItem: LinterItem | undefined = undefined;

// 第三方诊断器路径的相关配置
// iverilog     digital-ide.prj.iverilog.install.path
// vivado       digital-ide.prj.vivado.install.path
// modelsim     digital-ide.prj.modelsim.install.path
// verible      digital-ide.prj.verible.install.path
// verilator    digital-ide.prj.verilator.install.path
export type SupportLinterName = 'iverilog' | 'vivado' | 'modelsim' | 'verible' | 'verilator';
export const SupportLinters: SupportLinterName[] = ['iverilog', 'vivado', 'modelsim', 'verible', 'verilator'];

/**
 * @description 获取指向【当前的 linter 的名字】的配置的名字，比如 `digital-ide.function.lsp.linter.verilog.diagnostor`
 */
export function getLinterConfigurationName(langID: HdlLangID): string {
    return `digital-ide.function.lsp.linter.${langID}.diagnostor`;
}

/**
 * @description 获取当前的 linter 的名字，比如 `vivado`
 */
export function getLinterName(langID: HdlLangID): SupportLinterName {
    const linterConfigurationName = getLinterConfigurationName(langID);
    return vscode.workspace.getConfiguration().get<SupportLinterName>(linterConfigurationName, 'vivado');
}

export function updateLinterConfigurationName(langID: HdlLangID, linterName: SupportLinterName) {
    const sectionName = `digital-ide.function.lsp.linter.${langID}`;
    const linterConfiguration = vscode.workspace.getConfiguration(sectionName);
    linterConfiguration.update('diagnostor', linterName, vscode.ConfigurationTarget.Global);
}

export function getLinterInstallConfigurationName(linterName: SupportLinterName): string {
    return `digital-ide.prj.${linterName}.install.path`;
}

export function getLinterInstallPath(linterName: SupportLinterName): string {
    const configuration = vscode.workspace.getConfiguration();
    const linterInstallConfigurationName = getLinterInstallConfigurationName(linterName);
    return configuration.get<string>(linterInstallConfigurationName, '');
}

/**
 * @description 生成 PickItem，这个过程中会对当前 linterName 的有效性进行校验
 * @param client 
 * @param langID 
 * @param linterName 
 * @returns 
 */
export async function makeLinterNamePickItem(
    client: LanguageClient,
    langID: HdlLangID,
    linterName: SupportLinterName
): Promise<LinterItem> {
    const linterPath = getLinterInstallPath(linterName);
    
    const linterStatus = await client.sendRequest(LinterStatusRequestType, {
        languageId: langID,
        linterName,
        linterPath
    });

    const labelIcon = linterStatus.available ? 'getting-started-beginner': 'extensions-warning-message';

    const detail = linterStatus.available ? 
        t('info.common.some-is-ready', linterStatus.invokeName) :
        t("info.common.not-available", linterStatus.invokeName);
 
    return {
        label: `$(${labelIcon}) ` + linterName,
        name: linterName,
        linterPath,
        available: linterStatus.available,
        description: linterStatus.toolName,
        detail
    }
}

export async function makeLinterOptions(
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

export enum LinterMode {
    Full = 'full',
    Common = 'common',
    Shutdown = 'shutdown'
}

export function getLinterMode(): LinterMode {
    return vscode.workspace.getConfiguration().get<LinterMode>('digital-ide.function.lsp.linter.linter-mode', LinterMode.Full);
}

export interface IConfigReminder {
    title: string,
    value: 'config' | 'download'
}