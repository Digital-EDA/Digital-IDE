import * as vscode from 'vscode';


declare module formatterProvider {
    export const hdlFormatterProvider: vscode.DocumentFormattingEditProvider;
}

export = formatterProvider;