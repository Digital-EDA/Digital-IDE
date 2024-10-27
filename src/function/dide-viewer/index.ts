import * as vscode from 'vscode';
import * as fspath from 'path';
import * as fs from 'fs';

import { hdlFile, hdlPath } from '../../hdlFs';
import { opeParam, ReportType, WaveViewOutput } from '../../global';
import { LaunchFiles, loadView, saveView, saveViewAs } from './api';
import { BSON } from 'bson';
import { getIconConfig } from '../../hdlFs/icons';

function getWebviewContent(context: vscode.ExtensionContext, panel?: vscode.WebviewPanel): string | undefined {
    const dideviewerPath = hdlPath.join(context.extensionPath, 'resources', 'dide-viewer', 'view');
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

        const context = this.context;
        const previewHtml = getWebviewContent(context, this.panel);
        if (this.panel && previewHtml) {
            const launchFiles = getViewLaunchFiles(context, uri, this.panel);
            if (launchFiles instanceof Error) {
                vscode.window.showErrorMessage(launchFiles.message);
                return;
            }

            const { vcd, view, worker, root } = launchFiles;
            let preprocessHtml = previewHtml
                .replace('test.vcd', vcd)
                .replace('test.view', view)
                .replace('worker.js', worker)
                .replace('<root>', root);
            this.panel.webview.html = preprocessHtml;
            this.panel.iconPath = getIconConfig('view');
            registerMessageEvent(this.panel, uri);
        } else {
            WaveViewOutput.report('preview html in <WaveViewer.create> is empty', ReportType.Warn);
        }
    }

    // vscode 前端向 webview 发送消息
    public send(uri: vscode.Uri) {
        this.panel?.webview.postMessage({

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
    context: vscode.ExtensionContext;
    constructor(context: vscode.ExtensionContext) {
        this.context = context;
    }

    async resolveCustomEditor(document: VcdViewerDocument, webviewPanel: vscode.WebviewPanel, token: vscode.CancellationToken) {        
        webviewPanel.webview.options = {
            enableScripts: true,
            enableForms: true,
        };

        webviewPanel.onDidDispose(() => {
            webviewPanel.dispose();
        }, null);

        const context = this.context;
        const previewHtml = getWebviewContent(context, webviewPanel);
        registerMessageEvent(webviewPanel, document.uri);

        if (webviewPanel && previewHtml) {
            const launchFiles = getViewLaunchFiles(context, document.uri, webviewPanel);
            if (launchFiles instanceof Error) {
                vscode.window.showErrorMessage(launchFiles.message);
                return;
            }

            const { vcd, view, worker, root } = launchFiles;
            let preprocessHtml = previewHtml
                .replace('test.vcd', vcd)
                .replace('test.view', view)
                .replace('worker.js', worker)
                .replace('<root>', root);
            webviewPanel.webview.html = preprocessHtml;
            webviewPanel.iconPath = getIconConfig('view');
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

// vscode 前端接受 webview 的消息
function registerMessageEvent(panel: vscode.WebviewPanel, uri: vscode.Uri) {
    panel.webview.onDidReceiveMessage(message => {
        const { command, data } = message;

        switch (command) {
            case 'save-view':
                saveView(data, uri, panel);
                break;
            case 'save-view-as':
                saveViewAs(data, uri, panel);
                break;
            case 'load-view':
                loadView(data, uri, panel);
            default:
                break;
        }
    });
}


/**
 * @description 准备启动 webview 的基础资源
 * @param context 
 * @param uri 
 * @param panel 
 * @returns 
 */
function getViewLaunchFiles(context: vscode.ExtensionContext, uri: vscode.Uri, panel: vscode.WebviewPanel): LaunchFiles | Error {
    const { t } = vscode.l10n;
    console.log(uri.fsPath);
    
    const entryPath = uri.fsPath;
    const dideviewerPath = hdlPath.join(context.extensionPath, 'resources', 'dide-viewer', 'view');
    const workerAbsPath = hdlPath.join(dideviewerPath, 'worker.js');
    const worker = panel.webview.asWebviewUri(vscode.Uri.file(workerAbsPath)).toString();
    const root = panel.webview.asWebviewUri(vscode.Uri.file(dideviewerPath)).toString();

    // 根据打开文件的类型来判断资源加载方案
    if (entryPath.endsWith('.vcd')) {
        const defaultViewPath = entryPath.slice(0, -4) + '.view';
        const vcd = panel.webview.asWebviewUri(uri).toString();
        const view = panel.webview.asWebviewUri(vscode.Uri.file(defaultViewPath)).toString();

        return { vcd, view, worker, root };
    } else if (entryPath.endsWith('.view')) {
        const buffer = fs.readFileSync(entryPath);
        const recoverJson = BSON.deserialize(buffer);
        if (recoverJson.originVcdFile) {
            const vcdPath = recoverJson.originVcdFile;
            if (!fs.existsSync(vcdPath)) {
                return new Error(t('error.unexist-direct-vcd-file') + ':' + vcdPath);
            }
            const vcd = panel.webview.asWebviewUri(vscode.Uri.file(recoverJson.originVcdFile)).toString();
            const view = panel.webview.asWebviewUri(uri).toString();

            return { vcd, view, worker, root };
        } else {
            return new Error(t('bad-view-file') + ':' + entryPath);
        }
    }
    return new Error('unsupported languages');
}

export {
    openWaveViewer,
    VcdViewerProvider
};