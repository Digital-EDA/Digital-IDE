import * as vscode from 'vscode';

import { opeParam, MainOutput, AbsPath, ReportType, LspClient, IProgress } from './global';
import { hdlParam } from './hdlParser';
import * as manager from './manager';
import * as func from './function';
import { hdlMonitor } from './monitor';
import { extensionUrl } from '../resources/hdlParser';

import * as lspClient from './function/lsp-client';
import { refreshArchTree } from './function/treeView';



async function registerCommand(context: vscode.ExtensionContext) {
    func.registerFunctionCommands(context);
    func.registerLsp(context);
    func.registerToolCommands(context);
    func.registerFSM(context);
    func.registerNetlist(context);
    func.registerWaveViewer(context);

    lspClient.activate(context);
    await LspClient.MainClient?.onReady();
    // lspClient.activateVHDL(context);
}

async function launch(context: vscode.ExtensionContext) {
    const { t } = vscode.l10n;

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('progress.register-command')
    }, async () => {
        await registerCommand(context);
    });

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('progress.initialization')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        // 初始化解析
        await manager.prjManage.initialise(context, progress);
        
        // 这里是因为 pl 对象在 initialise 完成初始化，此处再注册它的行为
        manager.registerManagerCommands(context);

        // 刷新结构树
        refreshArchTree();

        hdlMonitor.start();
    });


    MainOutput.report('Digital-IDE has launched, Version: 0.4.0', ReportType.Launch);
    MainOutput.report('OS: ' + opeParam.os, ReportType.Launch);

    console.log(hdlParam);
    
    // show welcome information (if first install)
    const welcomeSetting = vscode.workspace.getConfiguration('digital-ide.welcome');
    const showWelcome = welcomeSetting.get('show', true);
 
    if (showWelcome) {
        // don't show in next time
        welcomeSetting.update('show', false, vscode.ConfigurationTarget.Global);
        const res = await vscode.window.showInformationMessage(
            t('welcome.title'),
            { title: t('welcome.star'), value: true },
            { title: t('welcome.refuse'), value: false },
        );
        if (res?.value) {
            vscode.env.openExternal(vscode.Uri.parse(extensionUrl));
        }
    }
}

export function activate(context: vscode.ExtensionContext) {
    launch(context);
}

export function deactivate() {
    lspClient.deactivate();
    // lspClient.deactivateVHDL();
}