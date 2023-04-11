import * as vscode from 'vscode';

import * as hdlDoc from './hdlDoc';
import * as sim from './sim';
import * as treeView from './treeView';

function registerDocumentation(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.hdlDoc.showWebview', hdlDoc.showDocWebview);
    hdlDoc.registerFileDocExport(context);
    hdlDoc.registerProjectDocExport(context);
}


function registerSimulation(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.tool.instance', sim.instantiation);
    vscode.commands.registerCommand('digital-ide.tool.testbench', sim.testbench);
    vscode.commands.registerCommand('digital-ide.tool.icarus.simulateFile', sim.Icarus.simulateFile);
}

function registerAllCommands(context: vscode.ExtensionContext) {
    registerDocumentation(context);
    registerSimulation(context);
    registerTreeView(context);
}

function registerTreeView(context: vscode.ExtensionContext) {
    // register normal tree
    vscode.window.registerTreeDataProvider('digital-ide.treeView.arch', treeView.moduleTreeProvider);
    vscode.window.registerTreeDataProvider('digital-ide.treeView.tool', treeView.toolTreeProvider);
    vscode.window.registerTreeDataProvider('digital-ide.treeView.hardware', treeView.hardwareTreeProvider);
    vscode.window.registerTreeDataProvider('digital-ide.treeView.software', treeView.softwareTreeProvider);

    // constant used in tree
    vscode.commands.executeCommand('setContext', 'TOOL-tree-expand', false);

    // register command in tree
    vscode.commands.registerCommand('digital-ide.treeView.arch.expand', treeView.expandTreeView);
    vscode.commands.registerCommand('digital-ide.treeView.arch.collapse', treeView.collapseTreeView);
    vscode.commands.registerCommand('digital-ide.treeView.arch.refresh', treeView.refreshArchTree);
    vscode.commands.registerCommand('digital-ide.treeView.arch.openFile', treeView.openFileByUri);

}


export {
    registerAllCommands
};