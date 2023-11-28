import * as vscode from 'vscode';

import { opeParam, MainOutput, AbsPath, ReportType } from './global';
import { hdlParam } from './hdlParser';
import * as manager from './manager';
import * as func from './function';
import { hdlMonitor } from './monitor';
import { extensionUrl } from '../resources/hdlParser';

async function registerCommand(context: vscode.ExtensionContext) {
    manager.registerManagerCommands(context);

    func.registerFunctionCommands(context);
    func.registerLsp(context);
    func.registerToolCommands(context);
    func.registerFSM(context);
    func.registerNetlist(context);
}


async function launch(context: vscode.ExtensionContext) {
    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: 'Initialization (Digtial-IDE)'
    }, async () => {
        await manager.prjManage.initialise(context);
        await registerCommand(context);
        hdlMonitor.start();
    });
        
    MainOutput.report('Digital-IDE has launched, Version: 0.3.2', ReportType.Launch);
    MainOutput.report('OS: ' + opeParam.os, ReportType.Launch);

    console.log(hdlParam);
    
    // show welcome information (if first install)
    const welcomeSetting = vscode.workspace.getConfiguration('digital-ide.welcome');
    const showWelcome = welcomeSetting.get('show', true);
    if (showWelcome) {
        // don't show in next time
        welcomeSetting.update('show', false);
        const res = await vscode.window.showInformationMessage(
            'Thanks for using Digital-IDE ❤️. Your star will be our best motivation! 😊',
            { title: 'Star', value: true },
            { title: 'Refuse', value: true },
        );
        if (res?.value) {
            vscode.env.openExternal(vscode.Uri.parse(extensionUrl));
        }
    }
}

export function activate(context: vscode.ExtensionContext) {
    launch(context);
}

export function deactivate() {}