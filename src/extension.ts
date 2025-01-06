import * as vscode from 'vscode';
import * as fs from 'fs';

import { MainOutput, ReportType, IProgress } from './global';
import { hdlParam } from './hdlParser';
import * as manager from './manager';
import * as lspLinter from './function/lsp/linter';
import * as func from './function';
import { hdlMonitor } from './monitor';

import * as lspClient from './function/lsp-client';
import { refreshArchTree } from './function/treeView';
import { initialiseI18n, t } from './i18n';


async function registerCommand(context: vscode.ExtensionContext, packageJson: any) {
    func.registerFunctionCommands(context);
    func.registerTreeViewDataProvider(context);
    func.registerLsp(context, packageJson.version);
    func.registerToolCommands(context);
    func.registerNetlist(context);
    func.registerWaveViewer(context);

    // onCommand 激活事件中的命令
    context.subscriptions.push(
        vscode.commands.registerCommand('digital-ide.property-json.generate', () => {
            manager.prjManage.generatePropertyJson(context);
        })
    );
    context.subscriptions.push(
        vscode.commands.registerCommand('digital-ide.structure.from-xilinx-to-standard', () => {
            manager.prjManage.transformXilinxToStandard(context);
        })
    );
    context.subscriptions.push(
        vscode.commands.registerCommand('digital-ide.property-json.overwrite', () => {
            manager.prjManage.overwritePropertyJson()
        })
    )
}

function readPackageJson(context: vscode.ExtensionContext): any | undefined {
    const extensionPath = context.extensionPath;
    const packagePath = extensionPath + '/package.json';
    if (!fs.existsSync(packagePath)) {
        vscode.window.showErrorMessage("Digital IDE 安装目录已经被污染，请重新安装！");
        return undefined;
    }
    const packageMeta = fs.readFileSync(packagePath, { encoding: 'utf-8' });
    return JSON.parse(packageMeta);
}

async function launch(context: vscode.ExtensionContext) {
    initialiseI18n(context);

    console.log(t('info.welcome.title'));
    console.log(t('info.welcome.join-qq-group') + ' https://qm.qq.com/q/1M655h3GsA');

    const packageJson = readPackageJson(context);
    MainOutput.report(t('info.launch.digital-ide-current-version') + packageJson.version, {
        level: ReportType.Launch
    });

    if (packageJson === undefined) {
        return;
    }
    
    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('info.progress.register-command')
    }, async () => {
        await registerCommand(context, packageJson);
    });

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('info.progress.initialize-configure')        
    }, async () => {
        // 初始化 OpeParam
        // 包含基本的插件的文件系统信息、用户配置文件和系统配置文件的合并数据结构
        const refreshPrjConfig = await manager.prjManage.initOpeParam(context);
        manager.prjManage.refreshPrjFolder(refreshPrjConfig);
    });

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('info.progress.launch-lsp')
    }, async () => {
        await lspClient.activate(context, packageJson);
    });
        
    const hdlFiles = await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('info.progress.initialization')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        // 初始化解析
        const hdlFiles = await manager.prjManage.initialise(context, progress);
        
        // 这里是因为 pl 对象在 initialise 完成初始化，此处再注册它的行为
        manager.registerManagerCommands(context);

        // 刷新结构树
        refreshArchTree();

        // 启动监视器
        hdlMonitor.start();

        return hdlFiles;
    });


    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Window,
        title: t('info.progress.doing-diagnostic')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        // 完成诊断器初始化
        await lspLinter.initialise(context, hdlFiles, progress);
    });

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
    manager.prjManage.pl?.exit();
}