import * as vscode from 'vscode';
import * as assert from 'assert'; 

import { prjManage } from './prj';
import { pickLibrary } from './libPick';

export function registerManagerCommands(context: vscode.ExtensionContext) {
    // make ps and ps have been prepared
    assert(prjManage.pl, 'pl is undefined');
    assert(prjManage.ps, 'ps is undefined');

    const plManage = prjManage.pl;
    const psManage = prjManage.ps;

    // libpick 
    vscode.commands.registerCommand('digital-ide.pickLibrary', pickLibrary);

    // ps toolbox commands (soft tool in treeView)
    // TODO : finish digital-ide.soft.download
    vscode.commands.registerCommand('digital-ide.soft.launch', () => psManage.launch());
    vscode.commands.registerCommand('digital-ide.soft.build', () => psManage.build());
    vscode.commands.registerCommand('digital-ide.soft.download', () => psManage.program());

    // pl functional commands
    vscode.commands.registerCommand('digital-ide.pl.setSrcTop', (item) => plManage.setSrcTop(item));
    vscode.commands.registerCommand('digital-ide.pl.setSimTop', (item) => plManage.setSimTop(item));
    vscode.commands.registerCommand('digital-ide.pl.addDevice', () => plManage.addDevice());
    vscode.commands.registerCommand('digital-ide.pl.delDevice', () => plManage.delDevice());
    vscode.commands.registerCommand('digital-ide.pl.addFile', files => plManage.addFiles(files));
    vscode.commands.registerCommand('digital-ide.pl.delFile', files => plManage.delFiles(files));

    // pl toolbox commands (hard tool in treeView)
    vscode.commands.registerCommand('digital-ide.hard.launch', () => plManage.launch());
    vscode.commands.registerCommand('digital-ide.hard.simulate', () => plManage.simulate());
    vscode.commands.registerCommand('digital-ide.hard.simulate.cli', () => plManage.simulateCli());
    vscode.commands.registerCommand('digital-ide.hard.simulate.gui', () => plManage.simulateGui());
    vscode.commands.registerCommand('digital-ide.hard.refresh', () => plManage.refresh());
    vscode.commands.registerCommand('digital-ide.hard.build', () => plManage.build());
    vscode.commands.registerCommand('digital-ide.hard.build.synth', () => plManage.synth());
    vscode.commands.registerCommand('digital-ide.hard.build.impl', () => plManage.impl());
    vscode.commands.registerCommand('digital-ide.hard.build.bitstream', () => plManage.bitstream());
    vscode.commands.registerCommand('digital-ide.hard.program', () => plManage.program());
    vscode.commands.registerCommand('digital-ide.hard.gui', () => plManage.gui());
    vscode.commands.registerCommand('digital-ide.hard.exit', () => plManage.exit());
}

export {
    prjManage
};