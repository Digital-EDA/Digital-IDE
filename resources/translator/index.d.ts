import type * as vscode from 'vscode'; 

declare module Translator {
    export async function vhdl2vlog(uri: vscode.Uri): Promise<void>;
}

export = Translator;