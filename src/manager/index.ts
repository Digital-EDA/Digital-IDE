import * as vscode from 'vscode';

import { prjManage } from './prj';


function registerManagerCommands(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.property-json.generate', prjManage.generatePropertyJson);
    vscode.commands.registerCommand('digital-ide.property-json.overwrite', prjManage.overwritePropertyJson);    
}

export {
    prjManage,
    registerManagerCommands
};