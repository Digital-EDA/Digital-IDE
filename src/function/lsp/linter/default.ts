import * as vscode from 'vscode';
import { isVerilogFile, isVhdlFile } from '../../../hdlFs/file';
import { All, Position } from '../../../hdlParser/common';
import { BaseLinter } from './base';
import { LspOutput, ReportType } from '../../../global';


class DefaultVlogLinter implements BaseLinter {
    diagnostic: vscode.DiagnosticCollection;
    constructor() {
        this.diagnostic = vscode.languages.createDiagnosticCollection('Digital-IDE Default Linter');
    }

    async lint(document: vscode.TextDocument): Promise<void> {
        const filePath = document.fileName;
        // const vlogAll = await hdlSymbolStorage.getSymbol(filePath);
        // // console.log('lint all finish');

        // if (vlogAll) {
        //     const diagnostics = this.provideDiagnostics(document, vlogAll);
        //     this.diagnostic.set(document.uri, diagnostics);
        // }
    }   

    private provideDiagnostics(document: vscode.TextDocument, all: All): vscode.Diagnostic[] {
        const diagnostics: vscode.Diagnostic[] = [];
        if (all.error && all.error.length > 0) {
            for (const hdlError of all.error) {
                LspOutput.report(`<default linter> line: ${hdlError.range.line}, info: ${hdlError.message}`, ReportType.Run);
                const syntaxInfo = hdlError.message.replace(/\\r\\n/g, '\n');
                const range = this.makeCorrectRange(document, hdlError.range);
                const diag = new vscode.Diagnostic(range, syntaxInfo, hdlError.severity);
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

    async remove(uri: vscode.Uri) {
        this.diagnostic.delete(uri);
    }

    public async initialise() {
        // move code to outer layer
        return true;
    }
}

class DefaultVhdlLinter implements BaseLinter {
    diagnostic: vscode.DiagnosticCollection;
    constructor() {
        this.diagnostic = vscode.languages.createDiagnosticCollection();
    }

    async lint(document: vscode.TextDocument): Promise<void> {
        const filePath = document.fileName;
        // const vhdlAll = await hdlSymbolStorage.getSymbol(filePath);
        // // console.log('lint all finish');
        
        // if (vhdlAll) {
        //     const diagnostics = this.provideDiagnostics(document, vhdlAll);
        //     this.diagnostic.set(document.uri, diagnostics);
        // }
    }

    private provideDiagnostics(document: vscode.TextDocument, all: All): vscode.Diagnostic[] {
        const diagnostics: vscode.Diagnostic[] = [];
        if (all.error && all.error.length > 0) {
            for (const hdlError of all.error) {
                LspOutput.report(`<default linter> line: ${hdlError.range.line}, info: ${hdlError.message}`, ReportType.Run);
                
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

    async remove(uri: vscode.Uri) {
        this.diagnostic.delete(uri);
    }

    public async initialise() {
        // move code to outer layer
        return true;
    }
}

const defaultVlogLinter = new DefaultVlogLinter();
const defaultVhdlLinter = new DefaultVhdlLinter();

export {
    defaultVlogLinter,
    defaultVhdlLinter,
    DefaultVlogLinter,
    DefaultVhdlLinter
};
