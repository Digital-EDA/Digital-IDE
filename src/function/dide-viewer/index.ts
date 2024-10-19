import * as vscode from 'vscode';
import * as fspath from 'path';

import { hdlFile, hdlPath } from '../../hdlFs';
import { opeParam, ReportType, WaveViewOutput } from '../../global';

function getWebviewContent(panel?: vscode.WebviewPanel): string | undefined {
    const dideviewerPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-viewer', 'view');
    const htmlIndexPath = hdlPath.join(dideviewerPath, 'index.html');
    const html = hdlFile.readFile(htmlIndexPath)?.replace(/(<link.+?href="|<script.+?src="|<img.+?src=")(.+?)"/g, (m, $1, $2) => {
        const absLocalPath = fspath.resolve(dideviewerPath, $2);
        const webviewUri = panel?.webview.asWebviewUri(vscode.Uri.file(absLocalPath));
        const replaceHref = $1 + webviewUri?.toString() + '"';
        return replaceHref;
    });
    return html;
}

class WaveViewer {
    context: vscode.ExtensionContext;
    openFileUri?: vscode.Uri;
    panel?: vscode.WebviewPanel;
    constructor(context: vscode.ExtensionContext) {
        this.context = context;
    }

    public async open(uri: vscode.Uri) {
        this.create(uri);
    }

    private create(uri: vscode.Uri) {
        this.openFileUri = uri;
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

        const previewHtml = getWebviewContent(this.panel);
        if (this.panel && previewHtml) {
            const dideviewerPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-viewer', 'view');
            const workerAbsPath = hdlPath.join(dideviewerPath, 'worker.js');
            const webviewUri = this.panel.webview.asWebviewUri(uri);
            const workerUri = this.panel.webview.asWebviewUri(vscode.Uri.file(workerAbsPath));            
            const workerRootUri = this.panel.webview.asWebviewUri(vscode.Uri.file(dideviewerPath));

            let preprocessHtml = previewHtml
                .replace('test.vcd', webviewUri.toString())
                .replace('worker.js', workerUri.toString())
                .replace('<workerRoot>', workerRootUri.toString());
            this.panel.webview.html = preprocessHtml;

            const iconPath = hdlPath.join(opeParam.extensionPath, 'images', 'icon.svg');
            this.panel.iconPath = vscode.Uri.file(iconPath);
            this.registerMessageEvent();
        } else {
            WaveViewOutput.report('preview html in <WaveViewer.create> is empty', ReportType.Warn);
        }
    }

    // vscode 前端向 webview 发送消息
    public send(uri: vscode.Uri) {
        this.panel?.webview.postMessage({

        });
    }

    // vscode 前端接受 webview 的消息
    private registerMessageEvent() {
        this.panel?.webview.onDidReceiveMessage(message => {
            const { command, data } = message;
            
            switch (command) {
                case 'save-view':
                    break;
            
                default:
                    break;
            }
        });
    }
}

async function openWaveViewer(context: vscode.ExtensionContext, uri: vscode.Uri) {
    const viewer = new WaveViewer(context);
    viewer.open(uri);
}

class VcdViewerDocument implements vscode.CustomDocument {
    uri: vscode.Uri;
    constructor(uri: vscode.Uri) {
        this.uri = uri;
    }
    dispose(): void {
        
    }
}

class VcdViewerProvider implements vscode.CustomEditorProvider {
    private readonly _onDidChangeCustomDocument = new vscode.EventEmitter<vscode.CustomDocumentEditEvent<VcdViewerDocument>>();
	public readonly onDidChangeCustomDocument = this._onDidChangeCustomDocument.event;

    async resolveCustomEditor(document: VcdViewerDocument, webviewPanel: vscode.WebviewPanel, token: vscode.CancellationToken) {
        webviewPanel.webview.options = {
            enableScripts: true,
            enableForms: true,
        };

        webviewPanel.onDidDispose(() => {
            webviewPanel.dispose();
        }, null);

        webviewPanel.webview.onDidReceiveMessage(message => {
            console.log(message);
        }, null);
        
        const previewHtml = getWebviewContent(webviewPanel);
        
        if (webviewPanel && previewHtml) {
            const dideviewerPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-viewer', 'view');
            const workerAbsPath = hdlPath.join(dideviewerPath, 'worker.js');
            const webviewUri = webviewPanel.webview.asWebviewUri(document.uri);
            const workerUri = webviewPanel.webview.asWebviewUri(vscode.Uri.file(workerAbsPath));            
            const workerRootUri = webviewPanel.webview.asWebviewUri(vscode.Uri.file(dideviewerPath));

            let preprocessHtml = previewHtml
                .replace('test.vcd', webviewUri.toString())
                .replace('worker.js', workerUri.toString())
                .replace('<workerRoot>', workerRootUri.toString());
            webviewPanel.webview.html = preprocessHtml;

            const iconPath = hdlPath.join(opeParam.extensionPath, 'images', 'icon.svg');
            webviewPanel.iconPath = vscode.Uri.file(iconPath);
        } else {
            WaveViewOutput.report('preview html in <WaveViewer.create> is empty', ReportType.Warn);
        }
    }

    openCustomDocument(uri: vscode.Uri, openContext: vscode.CustomDocumentOpenContext, token: vscode.CancellationToken): VcdViewerDocument | Thenable<VcdViewerDocument> {
        const document = new VcdViewerDocument(uri);
        return document;
    }

    async revertCustomDocument(document: VcdViewerDocument, cancellation: vscode.CancellationToken): Promise<void> {
        return;
    }

    async saveCustomDocument(document: VcdViewerDocument, cancellation: vscode.CancellationToken): Promise<void> {
        
    }


    async saveCustomDocumentAs(document: VcdViewerDocument, destination: vscode.Uri, cancellation: vscode.CancellationToken): Promise<void> {
        
    }


    async backupCustomDocument(document: VcdViewerDocument, context: vscode.CustomDocumentBackupContext, cancellation: vscode.CancellationToken): Promise<vscode.CustomDocumentBackup> {
        return {
            id: -1,
            then(onfulfilled, onrejected) {
                
            },
            delete() {
                
            },
        };
    }
}

const vcdViewerProvider = new VcdViewerProvider();

export {
    openWaveViewer,
    vcdViewerProvider
};