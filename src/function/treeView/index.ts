import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';
import { hdlFile, hdlPath } from '../../hdlFs';

import { clean, hardwareTreeProvider, softwareTreeProvider, toolTreeProvider } from './command';
import { moduleTreeProvider, ModuleDataItem  } from './tree';
import { Range } from '../../hdlParser/common';
import { MainOutput, opeParam, ReportType } from '../../global';
import { t } from '../../i18n';


async function openFileAtPosition(uri: vscode.Uri, range?: Range) {
    if (range === undefined) {
        range = {
            start: { line: 0, character: 0 },
            end: { line: 0, character: 0 }
        }
    }
    const document = await vscode.workspace.openTextDocument(uri);
    const start = new vscode.Position(range.start.line, range.start.character);
    const end = new vscode.Position(range.end.line, range.end.character);

    await vscode.window.showTextDocument(
        document,
        {
            selection: new vscode.Range(start, end)
        }
    );
}

function openFileByUri(path: string, range: Range | undefined, element: ModuleDataItem) {
    // 工程树中的文件节点没有 range（它是文件而非模块），此时直接打开文件
    if (hdlPath.exist(path) && hdlFile.isFile(path)) {
        const uri = vscode.Uri.file(path);
        openFileAtPosition(uri, range);
        return;
    } else {
        if (element.doFastFileType === 'ip') {
            switch (opeParam.prjInfo.toolChain) {
                case 'xilinx':
                    return gotoXilinxIPDefinition(element);
                default:
                    break;
            }
        }
    }
    MainOutput.report("invalid jump uri triggered in treeview, el: " + JSON.stringify(element, null, '  '), {
        level: ReportType.Error
    });
}

function gotoXilinxIPDefinition(element: ModuleDataItem) {
    const folderPath = element.path;
    if (folderPath) {
        const ipName = fspath.basename(folderPath);
        const defPath = hdlPath.join(folderPath, 'synth', ipName + '.vhd');
        if (fs.existsSync(defPath)) {
            openFileAtPosition(vscode.Uri.file(defPath), element.range);
        } else {
            vscode.window.showInformationMessage(t('info.treeview.ip-no-active.message'));
        }
    } else {
        MainOutput.report("[gotoXilinxIPDefinition] path is undefined", {
            level: ReportType.Error
        });
    }
}

function refreshArchTree(element?: ModuleDataItem) {
    // TODO : diff and optimize
    moduleTreeProvider.refresh(element);
}

/**
 * @description 将某个工程设为激活工程。工作区可有多个工程，硬件相关操作
 *              （综合 / 实现 / 下载）同时只作用于激活的那个。
 */
function activateProject(item: ModuleDataItem) {
    void moduleTreeProvider.activateProject(item);
}

function expandTreeView() {
    vscode.commands.executeCommand('setContext', 'TOOL-tree-expand', false);
}

function collapseTreeView() {
    vscode.commands.executeCommand('workbench.actions.treeView.digital-ide-treeView-arch.collapseAll');
    vscode.commands.executeCommand('setContext', 'TOOL-tree-expand', true);
}


export {
    hardwareTreeProvider,
    softwareTreeProvider,
    toolTreeProvider,
    moduleTreeProvider,
    expandTreeView,
    collapseTreeView,
    openFileByUri,
    refreshArchTree,
    activateProject,
    clean
};