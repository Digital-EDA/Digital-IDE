import * as vscode from 'vscode';
import * as fspath from 'path';
import { Worker } from 'worker_threads';
import { hdlFile, hdlPath } from '../../hdlFs';
import { t } from '../../i18n';
import { gotoDefinition, saveAsPdf, saveAsSvg } from './api';
import { getIconConfig } from '../../hdlFs/icons';
import { AbsPath, opeParam, ReportType, YosysOutput } from '../../global';
import { PathSet } from '../../global/util';

import { hdlParam } from '../../hdlParser';
import { defaultMacro, doFastApi } from '../../hdlParser/util';
import { HdlFile } from '../../hdlParser/core';
type SynthMode = 'before' | 'after' | 'RTL';

interface SimpleOpe {
    workspacePath: string,
    libCommonPath: string,
    prjPath: string,
    extensionPath: string
}

const workerScriptPath = hdlPath.join(__dirname, 'worker.js');

class NetlistRender {
    panel?: vscode.WebviewPanel;
    constructor() {

    }

    public create(moduleName: string) {
        // Create panel
        this.panel = vscode.window.createWebviewPanel(
            'Netlist',
            'Netlist',
            vscode.ViewColumn.One,
            {
                enableScripts: true,
                enableForms: true,
                retainContextWhenHidden: true
            }
        );

        this.panel.onDidDispose(() => {
        });

        const previewHtml = this.getWebviewContent();
        if (this.panel && previewHtml) {
            const netlistPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-netlist', 'view');
            const netlistPayloadFolder = hdlPath.join(opeParam.prjInfo.prjPath, 'netlist');
            const targetJson = hdlPath.join(netlistPayloadFolder, moduleName + '.json');
            const skinPath= hdlPath.join(netlistPath, 'dide.skin');

            const graph = this.panel.webview.asWebviewUri(vscode.Uri.file(targetJson)).toString();
            const skin = this.panel.webview.asWebviewUri(vscode.Uri.file(skinPath)).toString();
            this.panel.iconPath = getIconConfig('view');

            let preprocessHtml = previewHtml
                .replace('test.json', graph)
                .replace('test.module', moduleName)
                .replace('dide.skin', skin);

            this.panel.webview.html = preprocessHtml;

            registerMessageEvent(this.panel);
        } else {
            YosysOutput.report('preview html in <Netlist.create> is empty', {
                level: ReportType.Warn
            });
        }
    }

    public getWebviewContent() {
        const netlistPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-netlist', 'view');
        const htmlIndexPath = hdlPath.join(netlistPath, 'index.html');
        
        const html = hdlFile.readFile(htmlIndexPath)?.replace(/(<link.+?href="|<script.+?src="|<img.+?src=")(.+?)"/g, (m, $1, $2) => {
            const absLocalPath = fspath.resolve(netlistPath, $2);
            const webviewUri = this.panel?.webview.asWebviewUri(vscode.Uri.file(absLocalPath));
            const replaceHref = $1 + webviewUri?.toString() + '"';
            return replaceHref;
        });
        return html;
    }
}

async function generateFilelist(path: AbsPath): Promise<AbsPath[]> {
    const pathset = new PathSet();
    path = hdlPath.toSlash(path);

    let moduleFile = hdlParam.getHdlFile(path);
    // 没有说明是单文件模式，直接打开解析
    if (!moduleFile) {
        const standardPath = hdlPath.toSlash(path);
        const response = await doFastApi(standardPath, 'common');
        const langID = hdlFile.getLanguageId(standardPath);
        const projectType = hdlParam.getHdlFileProjectType(standardPath, 'common');
        moduleFile = new HdlFile(
            standardPath, langID,
            response?.macro || defaultMacro,
            response?.content || [],
            projectType,
            'common'
        );
        // 从 hdlParam 中去除，避免干扰全局
        hdlParam.removeFromHdlFile(moduleFile);

        // const message = t('error.common.not-valid-hdl-file');
        // const errorMsg = path + ' ' + message + ' ' + opeParam.prjInfo.hardwareSrcPath + '\n' + opeParam.prjInfo.hardwareSimPath;
        // vscode.window.showErrorMessage(errorMsg);
        // return undefined;
    }

    for (const hdlModule of moduleFile.getAllHdlModules()) {
        const hdlDependence = hdlParam.getAllDependences(path, hdlModule.name);
        if (hdlDependence) {
            // include 宏在后续会被正确处理，所以只需要处理 others 即可
            hdlDependence.others.forEach(path => pathset.add(path));
        }
    }
    pathset.add(path);
    
    const filelist = [...pathset.files];

    console.log(filelist);
    console.log(opeParam.prjInfo.prjPath);

    return filelist;
}

function generateOpe(): SimpleOpe {
    return {
        workspacePath: opeParam.workspacePath,
        extensionPath: opeParam.extensionPath,
        libCommonPath: opeParam.prjInfo.libCommonPath,
        prjPath: opeParam.prjInfo.prjPath
    };
}

function registerMessageEvent(panel: vscode.WebviewPanel) {
    panel.webview.onDidReceiveMessage(message => {
        const { command, data } = message;

        switch (command) {
            case 'save-as-svg':
                saveAsSvg(data, panel);
                break;
            case 'save-as-pdf':
                saveAsPdf(data, panel);
                break;
            case 'goto-definition':
                gotoDefinition(data, panel);
                break;
            default:
                break;
        }
    });
}

function waitForFinish(worker: Worker): Promise<void> {
    return new Promise<void>(resolve => {
        worker.on('message', message => {
            if (message.command === 'finish') {
                resolve();
            }
        });
    });
}

function checkResource() {
    const netlistWasmPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-netlist', 'static', 'yosys.wasm');
    if (!hdlPath.exist(netlistWasmPath)) {
        vscode.window.showErrorMessage(t('info.netlist.not-found-payload'));
        throw Error(t('info.netlist.not-found-payload'));
    }
}

export async function openNetlistViewer(context: vscode.ExtensionContext, uri: vscode.Uri, moduleName: string) {
    checkResource();
    const worker = new Worker(workerScriptPath);
    
    worker.on('message', message => {
        const command = message.command;
        const data = message.data;
        switch (command) {
            case 'error-log-file':
                showErrorLogFile(data);
                break;
        
            default:
                break;
        }
    });

    const configuration = vscode.workspace.getConfiguration();
    const mode = configuration.get<SynthMode>('digital-ide.function.netlist.schema-mode') || 'before';
    const filelist = await generateFilelist(uri.fsPath);
    const ope = generateOpe();

    worker.postMessage({
        command: 'open',
        data: {
            path: uri.fsPath,
            moduleName, mode,
            filelist,
            ope
        }
    });

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('info.netlist.generate-network'),
        cancellable: true
    }, async (_, token) => {
        token.onCancellationRequested(() => {
            worker.terminate();
        });

        await waitForFinish(worker);
    });

    worker.terminate();

    const render = new NetlistRender();
    render.create(moduleName);
}

async function showErrorLogFile(data: any) {
    const { logFilePath } = data;
    const res = await vscode.window.showErrorMessage(
        t('error.cannot-gen-netlist'),
        { title: t('error.look-up-log'), value: true }
    )
    if (res?.value) {
        const document = await vscode.workspace.openTextDocument(vscode.Uri.file(logFilePath));
        await vscode.window.showTextDocument(document);
    }
}

export async function runYsScript(context: vscode.ExtensionContext, uri: vscode.Uri) {
    checkResource();
    const worker = new Worker(workerScriptPath);

    worker.on('message', message => {
        const command = message.command;
        const data = message.data;
        switch (command) {
            case 'error-log-file':
                showErrorLogFile(data);
                break;
        
            default:
                break;
        }
    });

    const ope = generateOpe();

    worker.postMessage({
        command: 'run',
        data: {
            path: uri.fsPath,
            ope
        }
    });

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('info.netlist.generate-network'),
        cancellable: true
    }, async (_, token) => {
        token.onCancellationRequested(() => {
            worker.terminate();
        });

        await waitForFinish(worker);
    });

    worker.terminate();
}
