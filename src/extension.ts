import * as vscode from 'vscode';
import * as fs from 'fs';

import { opeParam, MainOutput, AbsPath, ReportType, LspClient, IProgress } from './global';
import { hdlParam } from './hdlParser';
import * as manager from './manager';
import * as func from './function';
import { hdlMonitor } from './monitor';

import * as lspClient from './function/lsp-client';
import { refreshArchTree } from './function/treeView';


async function registerCommand(context: vscode.ExtensionContext, version: string) {
    func.registerFunctionCommands(context);
    func.registerLsp(context, version);
    func.registerToolCommands(context);
    func.registerFSM(context);
    func.registerNetlist(context);
    func.registerWaveViewer(context);
}

function getVersion(context: vscode.ExtensionContext): string {
    let extensionPath = context.extensionPath;
    let packagePath = extensionPath + '/package.json';
    if (!fs.existsSync(packagePath)) {
        return '0.4.0';
    }
    let packageMeta = fs.readFileSync(packagePath, { encoding: 'utf-8' });
    let packageJson = JSON.parse(packageMeta);
    return packageJson.version;
}

async function launch(context: vscode.ExtensionContext) {
    const { t } = vscode.l10n;
    console.log(t('info.welcome.title'));
    console.log(t('info.welcome.join-qq-group') + ' https://qm.qq.com/q/1M655h3GsA');   
    const versionString = getVersion(context);
    
    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('info.progress.register-command')
    }, async () => {
        await registerCommand(context, versionString);
    });

    await lspClient.activate(context, versionString);
    await LspClient.DigitalIDE?.onReady();
    
    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('info.progress.initialization')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        // 初始化解析
        await manager.prjManage.initialise(context, progress);
        
        // 这里是因为 pl 对象在 initialise 完成初始化，此处再注册它的行为
        manager.registerManagerCommands(context);

        // 刷新结构树
        refreshArchTree();

        hdlMonitor.start();
    });


    MainOutput.report('Digital-IDE has launched, Version: ' + versionString, ReportType.Launch);
    MainOutput.report('OS: ' + opeParam.os, ReportType.Launch);

    console.log(hdlParam);
    
    // show welcome information (if first install)
    const welcomeSetting = vscode.workspace.getConfiguration('digital-ide.welcome');
    const showWelcome = welcomeSetting.get('show', true);
 
    if (showWelcome) {
        // don't show in next time
        welcomeSetting.update('show', false, vscode.ConfigurationTarget.Global);
        const res = await vscode.window.showInformationMessage(
            t('info.welcome.title'),
            { title: t('info.welcome.star'), value: true },
            { title: t('info.welcome.refuse'), value: false },
        );
        if (res?.value) {
            vscode.env.openExternal(vscode.Uri.parse('https://github.com/Digital-EDA/Digital-IDE'));
        }
    }
}

export function activate(context: vscode.ExtensionContext) {
    launch(context);
}

export function deactivate() {
    lspClient.deactivate();
}