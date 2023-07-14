import type * as vscode from 'vscode'; 

declare module FSM {
    export class FsmViewer {
        constructor(context: vscode.ExtensionContext);
        public open(uri: vscode.Uri);
    }
}

export = FSM;