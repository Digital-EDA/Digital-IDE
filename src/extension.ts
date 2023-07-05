import * as vscode from 'vscode';

import { opeParam, MainOutput, ReportType } from './global';
import { hdlParam } from './hdlParser';
import * as manager from './manager';
import * as func from './function';
import { hdlMonitor } from './monitor';

async function registerCommand(context: vscode.ExtensionContext) {
    manager.registerManagerCommands(context);

    func.registerFunctionCommands(context);
    func.registerLsp(context);
    func.registerToolCommands(context);
}

async function launch(context: vscode.ExtensionContext) {    
    await manager.prjManage.initialise(context);
    await registerCommand(context);
    hdlMonitor.start();

    console.log(hdlParam);
    
    MainOutput.report('Digital-IDE has launched, Version: 0.3.0');
    MainOutput.report('OS: ' + opeParam.os);
}

export function activate(context: vscode.ExtensionContext) {
    launch(context);
}

export function deactivate() {}