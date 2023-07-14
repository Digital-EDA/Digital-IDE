import * as vscode from 'vscode';
import { All } from '../../../../resources/hdlParser';
import { getLanguageId, isVerilogFile } from '../../../hdlFs/file';
import { hdlParam, HdlSymbol } from '../../../hdlParser';
import { Position, Range } from '../../../hdlParser/common';


class VlogLinter {
    diagnostic: vscode.DiagnosticCollection;
    constructor() {
        this.diagnostic = vscode.languages.createDiagnosticCollection();
    }

    async lint(document: vscode.TextDocument) {
        const filePath = document.fileName;
        const vlogAll = await HdlSymbol.all(filePath);
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
        console.log(diagnostics);
        
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
        console.log(range);
        
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
}

function registerVlogLinterServer(): VlogLinter {
    const linter = new VlogLinter();
    vscode.workspace.onDidOpenTextDocument(doc => {
        if (isVerilogFile(doc.fileName)) {
            linter.lint(doc);
        }
    });
    vscode.workspace.onDidSaveTextDocument(doc => {
        if (isVerilogFile(doc.fileName)) {
            linter.lint(doc);
        }
    });
    vscode.workspace.onDidCloseTextDocument(doc => {
        if (isVerilogFile(doc.fileName)) {
            linter.remove(doc);
        }
    });
    return linter;
}

async function firstLinter(linter: VlogLinter) {
    for (const doc of vscode.workspace.textDocuments) {
        if (isVerilogFile(doc.fileName)) {
            linter.lint(doc);
        }
    }
}

export {
    registerVlogLinterServer,
    firstLinter
};