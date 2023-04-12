import * as vscode from 'vscode';
import { hdlPath } from '../../hdlFs';

import { hardwareTreeProvider, softwareTreeProvider, toolTreeProvider } from './command';
import { moduleTreeProvider, ModuleDataItem  } from './tree';


function openFileByUri(uri: string) {
    if (hdlPath.exist(uri)) {
        vscode.window.showTextDocument(vscode.Uri.file(uri));
    }
}

function refreshArchTree(element: ModuleDataItem) {
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