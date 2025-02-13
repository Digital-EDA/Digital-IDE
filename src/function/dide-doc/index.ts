import * as vscode from 'vscode';
import * as fspath from 'path';

import { hdlFile, hdlIcon, hdlPath } from "../../hdlFs";
import { exportCurrentFileDocAsMarkdown, exportProjectDocAsMarkdown } from './markdown';
import { exportCurrentFileDocAsHTML, exportProjectDocAsHTML, makeDocWebview } from './html';
import { exportCurrentFileDocAsPDF, exportProjectDocAsPDF } from './pdf';
import { downloadSvg, exportDocHtml, exportDocMarkdown, exportDocPdf, getDocIR } from './codedoc';
import { opeParam } from '../../global';
import { t } from '../../i18n';

const availableFormat = [
    'markdown', 'pdf', 'html'
];

class ExportFunctionItem {
    label: string;
    format: string;
    exportFunc: Function;
    detail: string;

    constructor(format: string, title: string, detail: string, exportFunc: Function) {
        // TODO : 等到sv的解析做好后，写入对于不同hdl的图标
        let iconID = '$(export-' + format + ') ';
        this.label = iconID + title;
        this.format = format;
        this.exportFunc = exportFunc;
        this.detail = detail;
    }
};

export interface IDocManagerItem {
    panel: vscode.WebviewPanel,
    fileChangeDisposer: vscode.Disposable
}

export const docManager = new Map<string, IDocManagerItem>();

export function registerFileDocExport(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.hdlDoc.exportFile', async uri => {
        const option = {
            placeHolder: 'Select an Export Format'
        };
        const items = [
            new ExportFunctionItem('markdown', ' markdown', 'export markdown folder',  exportCurrentFileDocAsMarkdown),
            new ExportFunctionItem('pdf', ' pdf', 'only support light theme', exportCurrentFileDocAsPDF),
            new ExportFunctionItem('html', ' html', 'only support light theme', exportCurrentFileDocAsHTML)
        ];

        if (uri === undefined && vscode.window.activeTextEditor) {
            // TODO: 制作新的 doc UI
            uri = vscode.Uri.file(vscode.window.activeTextEditor.document.fileName);
        }
        
        const item = await vscode.window.showQuickPick(items, option);
		if (item) {
            item.exportFunc(uri);
        }
	});
}

export function registerProjectDocExport(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.hdlDoc.exportProject', async () => {
        const option = {
            placeHolder: 'Select an Export Format'
        };
        const items = [
            new ExportFunctionItem('markdown',' markdown', 'export markdown folder', exportProjectDocAsMarkdown),
            new ExportFunctionItem('pdf', ' pdf', 'only support light theme', exportProjectDocAsPDF),
            new ExportFunctionItem('html', ' html', 'only support light theme', exportProjectDocAsHTML)
        ];

        const item = await vscode.window.showQuickPick(items, option);
        if (item) {
            item.exportFunc();
        }
	});
}


function getWebviewContent(panel: vscode.WebviewPanel) {
    const netlistPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-doc', 'view');
    const htmlIndexPath = hdlPath.join(netlistPath, 'index.html');
    
    const html = hdlFile.readFile(htmlIndexPath)?.replace(/(<link.+?href="|<script.+?src="|<img.+?src=")(.+?)"/g, (m, $1, $2) => {
        const absLocalPath = fspath.resolve(netlistPath, $2);
        const webviewUri = panel.webview.asWebviewUri(vscode.Uri.file(absLocalPath));
        const replaceHref = $1 + webviewUri?.toString() + '"';
        return replaceHref;
    });
    return html;
}

export async function showDocWebview(uri: vscode.Uri) {
    const panel = vscode.window.createWebviewPanel(
        'CodeDoc', 
        'CodeDoc',
        vscode.ViewColumn.Two,
        {
            enableScripts: true,
            enableForms: true,
            retainContextWhenHidden: true
        }
    );

    panel.iconPath = hdlIcon.getIconConfig('documentation');
    panel.onDidDispose(() => {});
    
    const html = getWebviewContent(panel);
    if (html) {
        panel.webview.html = html;
        registerMessageEvent(panel);
    } else {
        vscode.window.showErrorMessage(t('dide-doc.error.loading-html'));
    }
}

function registerMessageEvent(panel: vscode.WebviewPanel) {
    panel.webview.onDidReceiveMessage(message => {
        const { command, data } = message;

        // TODO: finish this
        const codeDocIr = {};

        switch (command) {
            case 'get-doc-ir':
                getDocIR(data, panel, codeDocIr);
                break;
            case 'download-svg':
                downloadSvg(data, panel);
            case 'export-doc-html':
                exportDocHtml(data, panel);
                break;
            case 'export-doc-pdf':
                exportDocPdf(data, panel);
                break;
            case 'export-doc-markdown':
                exportDocMarkdown(data, panel);
                break;
            default:
                break;
        }
    });
}