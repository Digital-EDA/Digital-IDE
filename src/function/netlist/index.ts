import * as vscode from 'vscode';
import * as fspath from 'path';

import { NetlistKernel } from '../../../resources/netlist';
import { MainOutput, opeParam, ReportType, YosysOutput } from '../../global';
import { hdlParam } from '../../hdlParser';
import { hdlFile, hdlPath } from '../../hdlFs';


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

        const hdlFile = hdlParam.getHdlFile(path);        
        if (!hdlFile) {
            const errorMsg = `${path} is not a valid hdl file in our parse list, check your property.json to see if arch.hardware.src is set correctly!
            \ncurrent parse list: \n${opeParam.prjInfo.hardwareSrcPath}\n${opeParam.prjInfo.hardwareSimPath}`;
            vscode.window.showErrorMessage(errorMsg);
            return;
        }

        for (const hdlModule of hdlFile.getAllHdlModules()) {
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
                YosysOutput.report('type: ' + type + ', ' + message, ReportType.Error);
            }
        });

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
            YosysOutput.report('preview html in <Netlist.create> is empty', ReportType.Warn);
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