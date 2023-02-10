import * as vscode from 'vscode';

import { hdlIcon } from "../../hdlFs";
import { exportCurrentFileDocAsMarkdown, exportProjectDocAsMarkdown } from './markdown';
import { exportCurrentFileDocAsHTML, exportProjectDocAsHTML, showDocWebview } from './html';
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

function registerFileDocExport(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.hdlDoc.exportFile', () => {
        const option = {
            placeHolder: 'Select an Export Format'
        };
        const items = [
            new ExportFunctionItem('markdown', ' markdown', 'export markdown folder',  exportCurrentFileDocAsMarkdown),
            new ExportFunctionItem('pdf', ' pdf', 'only support light theme', exportCurrentFileDocAsPDF),
            new ExportFunctionItem('html', ' html', 'only support light theme', exportCurrentFileDocAsHTML)
        ];
		
        vscode.window.showQuickPick(items, option).then(item => {
            if (item) {
                item.exportFunc();
            }
        });
	});
}

function registerProjectDocExport(context: vscode.ExtensionContext) {
    vscode.commands.registerCommand('digital-ide.hdlDoc.exportProject', () => {
        const option = {
            placeHolder: 'Select an Export Format'
        };
        const items = [
            new ExportFunctionItem('markdown',' markdown', 'export markdown folder', exportProjectDocAsMarkdown),
            new ExportFunctionItem('pdf', ' pdf', 'only support light theme', exportProjectDocAsPDF),
            new ExportFunctionItem('html', ' html', 'only support light theme', exportProjectDocAsHTML)
        ];
		
        vscode.window.showQuickPick(items, option).then(item => {
            if (item) {
                item.exportFunc();
            }
        });
	});
}

export {
    registerFileDocExport,
    registerProjectDocExport,
    showDocWebview
};