import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    Executable,
} from "vscode-languageclient/node";

import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { platform } from "os";
import { LspClient } from '../../global';

function getLspServerExecutionName() {
    const osname = platform();
    if (osname === 'win32') {
        return 'digital-lsp.exe';
    }

    return 'digital-lsp';
}


export function activate(context: vscode.ExtensionContext) {
    const lspServerName = getLspServerExecutionName();
    const lspServerPath = context.asAbsolutePath(
        path.join('resources', 'dide-lsp', 'server', lspServerName)
    );

    if (fs.existsSync(lspServerPath)) {
        console.log('lsp server found at ' + lspServerPath);
    } else {
        console.error('cannot found lsp server at ' + lspServerPath);
    }
    
    const run: Executable = {
        command: lspServerPath,
    };

    // If the extension is launched in debug mode then the debug server options are used
    // Otherwise the run options are used
    let serverOptions: ServerOptions = {
        run,
        debug: run,
    };

    let clientOptions: LanguageClientOptions = {
        documentSelector: [
            {
                scheme: 'file',
                language: 'systemverilog' 
            },
            {
                scheme: 'file',
                language: 'verilog'
            },
            {
                scheme: 'file',
                language: 'vhdl'
            }
        ],
    };

    const client = new LanguageClient(
        "Digital LSP",
        "Digital LSP",
        serverOptions,
        clientOptions
    );
    LspClient.MainClient = client;
    
    client.start();
}

export function deactivate(): Thenable<void> | undefined {
    if (!LspClient.MainClient) {
        return undefined;
    }
    return LspClient.MainClient.stop();
}

