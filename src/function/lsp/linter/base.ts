import * as vscode from 'vscode';

interface BaseLinter {
    diagnostic: vscode.DiagnosticCollection;
    lint(document: vscode.TextDocument): Promise<void>;
}

interface BaseManager {
    initialise(): Promise<void>;
}


export {
    BaseLinter,
    BaseManager
};
