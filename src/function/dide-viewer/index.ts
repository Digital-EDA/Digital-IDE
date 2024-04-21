import * as vscode from 'vscode';
import * as fspath from 'path';

import { hdlFile, hdlPath } from '../../hdlFs';
import { opeParam, ReportType, WaveViewOutput } from '../../global';

class WaveViewer {
    context: vscode.ExtensionContext;
    panel?: vscode.WebviewPanel;
    constructor(context: vscode.ExtensionContext) {
        this.context = context;
    }

    public async open(uri: vscode.Uri) {
        this.create(uri);
    }

    private create(uri: vscode.Uri) {
        this.panel = vscode.window.createWebviewPanel(
            'Wave Viewer',
            'Wave Viewer',
            vscode.ViewColumn.One,
            {
                enableScripts: true,
                enableForms: true,
                retainContextWhenHidden: true
            }
        );

        this.panel.onDidDispose(() => {
            this.panel?.dispose();
            this.panel = undefined;
        }, null, this.context.subscriptions);

        this.panel.webview.onDidReceiveMessage(message => {
            console.log(message);
        }, null, this.context.subscriptions);

        const previewHtml = this.getWebviewContent();
        if (this.panel && previewHtml) {
            const webviewUri = this.panel.webview.asWebviewUri(uri);
            this.panel.webview.html = previewHtml.replace('test.vcd', webviewUri.toString());
                        
            const iconPath = hdlPath.join(opeParam.extensionPath, 'images', 'icon.svg');
            this.panel.iconPath = vscode.Uri.file(iconPath);
        } else {
            WaveViewOutput.report('preview html in <WaveViewer.create> is empty', ReportType.Warn);
        }
    }

    public send(uri: vscode.Uri) {
        this.panel?.webview.postMessage({

        });
    }

    public getWebviewContent(): string | undefined {
        const dideviewerPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-viewer', 'view');
        const htmlIndexPath = hdlPath.join(dideviewerPath, 'index.html');
        const html = hdlFile.readFile(htmlIndexPath)?.replace(/(<link.+?href="|<script.+?src="|<img.+?src=")(.+?)"/g, (m, $1, $2) => {
            const absLocalPath = fspath.resolve(dideviewerPath, $2);
            const webviewUri = this.panel?.webview.asWebviewUri(vscode.Uri.file(absLocalPath));
            const replaceHref = $1 + webviewUri?.toString() + '"';
            return replaceHref;
        });
        return html;
    }
}

async function openWaveViewer(context: vscode.ExtensionContext, uri: vscode.Uri) {
    const viewer = new WaveViewer(context);
    viewer.open(uri);
}

export {
    openWaveViewer
};