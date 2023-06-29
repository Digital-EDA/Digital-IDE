import * as vscode from 'vscode';

import { opeParam, MainOutput, ReportType } from './global';
import { hdlParam } from './hdlParser';
import { prjManage, registerManagerCommands } from './manager';
import { registerFunctionCommands, registerLsp } from './function';

async function registerCommand(context: vscode.ExtensionContext) {
    registerFunctionCommands(context);
    registerManagerCommands(context);
    registerLsp(context);
}

async function launch(context: vscode.ExtensionContext) {
    await prjManage.initialise(context);
    await registerCommand(context);
    

    MainOutput.report('Digital-IDE has launched, Version: 0.3.0');
    MainOutput.report('OS: ' + opeParam.os);
}

export function activate(context: vscode.ExtensionContext) {
    launch(context);
}

export function deactivate() {}