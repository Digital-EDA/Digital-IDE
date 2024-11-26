import * as vscode from 'vscode';
import * as fspath from 'path';

import { NetlistKernel } from '../../../resources/netlist';
import { opeParam, ReportType, YosysOutput } from '../../global';
import { hdlParam } from '../../hdlParser';
import { hdlFile, hdlPath } from '../../hdlFs';
import { defaultMacro, doFastApi } from '../../hdlParser/util';
import { HdlFile } from '../../hdlParser/core';
import { t } from '../../i18n';


class Netlist {
    kernel?: NetlistKernel;
    context: vscode.ExtensionContext;
    panel?: vscode.WebviewPanel;

    constructor(context: vscode.ExtensionContext) {
        this.context = context;
    }

    public async open(uri: vscode.Uri) {

        // get dependence of the current uri
        const prjFiles = [];
        const path = hdlPath.toSlash(uri.fsPath);

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
                // kernel supports `include, so only others are needed
                prjFiles.push(...hdlDependence.others);
            }
        }

        prjFiles.push(path);

        // launch kernel
        this.kernel = new NetlistKernel();
        await this.kernel.launch();

        // set info output in kernel to console
        this.kernel.setMessageCallback((message, type) => {
            if (message !== '') {
                YosysOutput.report('type: ' + type + ', ' + message);
            }
            if (type === "error") {
                vscode.window.showErrorMessage('type: ' + type + ', ' + message);
                YosysOutput.report('type: ' + type + ', ' + message, {
                    level: ReportType.Error
                });
            }
        });

        prjFiles.forEach(file => YosysOutput.report('feed file: ' + file, {
            level: ReportType.Debug
        }));
        this.kernel.load(prjFiles);
        this.create();
    }

    private create() {
        // Create panel
        this.panel = vscode.window.createWebviewPanel(
            'netlist',
            'Schematic viewer',
            vscode.ViewColumn.One, {
                enableScripts: true,
                retainContextWhenHidden: true
            }
        );

        this.panel.onDidDispose(() => {
            // When the panel is closed, cancel any future updates to the webview content
            this.kernel?.exit();
            this.panel?.dispose();

            this.kernel = undefined;
            this.panel = undefined;
        }, null, this.context.subscriptions);

        // Handle messages from the webview
        this.panel.webview.onDidReceiveMessage(message => {
            console.log(message);
            switch (message.command) {
                case 'export':
                    this.export(message.type, message.svg);
                break;
                case 'exec':
                    this.send();
                break;
            }
        }, undefined, this.context.subscriptions);

        const previewHtml = this.getWebviewContent();
        if (this.panel && previewHtml) {
            this.panel.webview.html = previewHtml;
        } else {
            YosysOutput.report('preview html in <Netlist.create> is empty', {
                level: ReportType.Warn
            });
        }
    }
    
    public send() {
        this.kernel?.exec('proc');
        const netlist = this.kernel?.export({type: 'json'});
        
        const command = 'netlist';
        this.panel?.webview.postMessage({command, netlist});
    }

    public getWebviewContent() {
        const netlistPath = hdlPath.join(opeParam.extensionPath, 'resources', 'netlist', 'view');
        const htmlIndexPath = hdlPath.join(netlistPath, 'netlist_viewer.html');

        const html = hdlFile.readFile(htmlIndexPath)?.replace(/(<link.+?href="|<script.+?src="|<img.+?src=")(.+?)"/g, (m, $1, $2) => {
            const absLocalPath = fspath.resolve(netlistPath, $2);
            const webviewUri = this.panel?.webview.asWebviewUri(vscode.Uri.file(absLocalPath));
            const replaceHref = $1 + webviewUri?.toString() + '"';
            return replaceHref;
        });
        return html;
    }

    public async export(type: string, svg: string) {
        switch (type) {
            case "svg":
                await this.exportSvg(svg);
            break;
        
            default: break;
        }
    }

    public async exportSvg(svg: string) {
        const filter = { 'svg': ['svg'] };
        const fileInfos = await vscode.window.showSaveDialog({ filters: filter });

        if (fileInfos && fileInfos.path) {
            let savePath = fileInfos.path;

            if (savePath[0] === '/' && require('os').platform() === 'win32') {
                savePath = savePath.substring(1);
            }

            hdlFile.writeFile(savePath, svg);

            vscode.window.showInformationMessage('Schematic saved in ' + savePath);
            YosysOutput.report('Schematic saved in ' + savePath);
        }
    }
}

async function openNetlistViewer(context: vscode.ExtensionContext, uri: vscode.Uri) {
    const viewer = new Netlist(context);
    viewer.open(uri);
}

export {
    openNetlistViewer
};