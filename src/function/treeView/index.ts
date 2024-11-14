import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';
import { hdlFile, hdlPath } from '../../hdlFs';

import { hardwareTreeProvider, softwareTreeProvider, toolTreeProvider } from './command';
import { moduleTreeProvider, ModuleDataItem  } from './tree';
import { Range } from '../../hdlParser/common';
import { MainOutput, opeParam, ReportType } from '../../global';


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

function openFileByUri(path: string, range: Range, element: ModuleDataItem) {
    const { t } = vscode.l10n; 
    if (range === undefined) {
        // vscode.window.showErrorMessage(`${path} not support jump yet`);
        return;
    }

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
    MainOutput.report("invalid jump uri triggered in treeview, el: " + JSON.stringify(element, null, '  '), ReportType.Error);
}

function gotoXilinxIPDefinition(element: ModuleDataItem) {
    const { t } = vscode.l10n;
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
        MainOutput.report("[gotoXilinxIPDefinition] path is undefined", ReportType.Error);
    }
}

function refreshArchTree(element?: ModuleDataItem) {
    // TODO : diff and optimize
    moduleTreeProvider.refresh(element);
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
    refreshArchTree
};