import * as vscode from 'vscode';
import { hdlPath } from '../../hdlFs';

import { hardwareTreeProvider, softwareTreeProvider, toolTreeProvider } from './command';
import { moduleTreeProvider, ModuleDataItem  } from './tree';
import { Range } from '../../hdlParser/common';


async function openFileAtPosition(uri: vscode.Uri, range: Range) {
    const document = await vscode.workspace.openTextDocument(uri);
    const start = new vscode.Position(range.start.line - 1, range.start.character - 1);
    const end = new vscode.Position(range.end.line - 1, range.end.character - 1);

    await vscode.window.showTextDocument(
        document,
        {
            selection: new vscode.Range(start, end)
        }
    );
}

function openFileByUri(path: string, range: Range) {
    if (range === undefined) {
        vscode.window.showErrorMessage(`${path} not support jump yet`);
        return;
    }

    if (hdlPath.exist(path)) {
        const uri = vscode.Uri.file(path);
        openFileAtPosition(uri, range);
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