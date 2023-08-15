import * as vscode from 'vscode';
import { All } from '../../../../resources/hdlParser';
import { isVerilogFile } from '../../../hdlFs/file';
import { Position, Range } from '../../../hdlParser/common';
import { hdlSymbolStorage } from '../core';


class VlogLinter {
    diagnostic: vscode.DiagnosticCollection;
    constructor() {
        this.diagnostic = vscode.languages.createDiagnosticCollection();
    }

    async lint(document: vscode.TextDocument) {
        const filePath = document.fileName;
        const vlogAll = await hdlSymbolStorage.getSymbol(filePath);
        // console.log('lint all finish');
        
        if (vlogAll) {
            const diagnostics = this.provideDiagnostics(document, vlogAll);
            this.diagnostic.set(document.uri, diagnostics);
        }
    }

    private provideDiagnostics(document: vscode.TextDocument, all: All): vscode.Diagnostic[] {
        const diagnostics: vscode.Diagnostic[] = [];
        if (all.error && all.error.length > 0) {
            for (const hdlError of all.error) {
                const range = this.makeCorrectRange(document, hdlError.range);
                const diag = new vscode.Diagnostic(range, hdlError.message, hdlError.severity);
                diag.source = hdlError.source;
                diagnostics.push(diag);
            }
        }        
        return diagnostics;
    }

    private makeCorrectRange(document: vscode.TextDocument, range: Position): vscode.Range {
        range.line --;
        if (range.character === 0 && range.line > 0) {
            range.line --;
        }

        while (range.line > 0) {
            const lineContent = document.lineAt(range.line).text;
            if (lineContent.trim().length > 0) {
                break;
            } else {
                range.line --;
            }
        }

        const currentLine = document.lineAt(range.line).text;
        if (range.character === 0 && currentLine.trim().length > 0) {
            range.character = currentLine.trimEnd().length;
        }
        
        const position = new vscode.Position(range.line, range.character);
        const wordRange = document.getWordRangeAtPosition(position, /[`_0-9a-zA-Z]+/);
        if (wordRange) {
            return wordRange;
        } else {
            const errorEnd = new vscode.Position(range.line, range.character + 1);
            const errorRange = new vscode.Range(position, errorEnd);
            return errorRange;
        }
    }

    async remove(document: vscode.TextDocument) {
        this.diagnostic.delete(document.uri);
    }

    public async initialise() {
        for (const doc of vscode.workspace.textDocuments) {
            if (isVerilogFile(doc.fileName)) {
                // TODO : check performance
                await this.lint(doc);
            }
        }
    }
}

const vlogLinter = new VlogLinter();

export {
    vlogLinter
};