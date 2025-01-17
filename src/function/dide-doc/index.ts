import * as vscode from 'vscode';

import { hdlIcon } from "../../hdlFs";
import { exportCurrentFileDocAsMarkdown, exportProjectDocAsMarkdown } from './markdown';
import { exportCurrentFileDocAsHTML, exportProjectDocAsHTML, showDocWebview, makeDocWebview } from './html';
import { exportCurrentFileDocAsPDF, exportProjectDocAsPDF } from './pdf';

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

function registerFileDocExport(context: vscode.ExtensionContext) {
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

function registerProjectDocExport(context: vscode.ExtensionContext) {
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

export {
    registerFileDocExport,
    registerProjectDocExport,
    showDocWebview,
    makeDocWebview
};