import * as vscode from 'vscode';
import { hdlPath } from '../../hdlFs';

import { hardwareTreeProvider, softwareTreeProvider, toolTreeProvider } from './command';
import { moduleTreeProvider, ModuleDataItem  } from './tree';
import { Range } from '../../hdlParser/common';

async function openFileAtPosition(uri: vscode.Uri, line: number, character: number) {
    const document = await vscode.workspace.openTextDocument(uri);
    const editor = await vscode.window.showTextDocument(document);
    const position = new vscode.Position(line, character);
    editor.selection = new vscode.Selection(position, position);
    editor.revealRange(new vscode.Range(position, position));
}

function openFileByUri(path: string, range: Range) {
    if (range === undefined) {
        vscode.window.showErrorMessage(`${path} not support jump yet`);
        return;
    }
    if (hdlPath.exist(path)) {
        const uri = vscode.Uri.file(path);
        const start = range.start;
        openFileAtPosition(uri, start.line - 1, start.character);
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