import * as vscode from 'vscode';

import { prjManage } from './prj';
import { pickLibrary } from './libPick';


function registerManagerCommands(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.property-json.generate', prjManage.generatePropertyJson);
    vscode.commands.registerCommand('digital-ide.property-json.overwrite', prjManage.overwritePropertyJson);    

    // libpick 
    vscode.commands.registerCommand('digital-ide.pickLibrary', pickLibrary);

    
}

export {
    prjManage,
    registerManagerCommands
};