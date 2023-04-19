import * as vscode from 'vscode';
import * as assert from 'assert'; 

import { prjManage } from './prj';
import { pickLibrary } from './libPick';

function registerManagerCommands(context: vscode.ExtensionContext) {
    // make ps and ps have been prepared
    assert(prjManage.pl, 'pl is undefined');
    assert(prjManage.ps, 'ps is undefined');

    const plManage = prjManage.pl;
    const psManage = prjManage.ps;

    vscode.commands.registerCommand('digital-ide.property-json.generate', prjManage.generatePropertyJson);
    vscode.commands.registerCommand('digital-ide.property-json.overwrite', prjManage.overwritePropertyJson);    

    // libpick 
    vscode.commands.registerCommand('digital-ide.pickLibrary', pickLibrary);

    // ps
    vscode.commands.registerCommand('digital-ide.pl.setSrcTop', (item) => plManage.setSrcTop(item));
    vscode.commands.registerCommand('digital-ide.pl.setSimTop', (item) => plManage.setSimTop(item));
    vscode.commands.registerCommand('digital-ide.pl.addDevice', () => plManage.addDevice());
    vscode.commands.registerCommand('digital-ide.pl.delDevice', () => plManage.delDevice());
    vscode.commands.registerCommand('digital-ide.pl.addFile', files => plManage.addFiles(files));
    vscode.commands.registerCommand('digital-ide.pl.delFile', files => plManage.delFiles(files));
    
    // pl

}

export {
    prjManage,
    registerManagerCommands
};