import * as vscode from 'vscode';

import * as hdlDoc from './hdlDoc';
import * as Sim from './sim';

function registerDocumentation(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.hdlDoc.showWebview', hdlDoc.showDocWebview);
    hdlDoc.registerFileDocExport(context);
    hdlDoc.registerProjectDocExport(context);
}


function registerSimulation(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.tool.instance', Sim.instantiation);
    vscode.commands.registerCommand('digital-ide.tool.testbench', Sim.testbench);
    vscode.commands.registerCommand('digital-ide.tool.icarus.simulateFile', Sim.Icarus.simulateFile);
}

function registerAllCommands(context: vscode.ExtensionContext) {
    registerDocumentation(context);
    registerSimulation(context);
}


export {
    registerAllCommands
};