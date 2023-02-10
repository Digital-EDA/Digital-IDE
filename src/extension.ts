import * as vscode from 'vscode';

import { opeParam, MainOutput, ReportType } from './global';
import { hdlParam } from './hdlParser';
import { prjManage } from './manager';

import { registerAllCommands } from './function';

async function registerCommand(context: vscode.ExtensionContext) {
    registerAllCommands(context);
}

async function launch(context: vscode.ExtensionContext) {
    console.time('launch');
    prjManage.initOpeParam(context);
    console.log(opeParam.prjInfo);
    const hdlFiles = prjManage.getPrjHardwareFiles();
    await hdlParam.initialize(hdlFiles);
    console.timeLog('launch');
    
    await registerCommand(context);
    MainOutput.report('Digital-IDE has launched, version: 0.3.0');
    MainOutput.report('OS: ' + opeParam.os);
}

export function activate(context: vscode.ExtensionContext) {
    launch(context);
}

export function deactivate() {}