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

let client: LanguageClient;
let vhdlClient: LanguageClient;

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
            }
        ],
    };

    client = new LanguageClient(
        "Digital LSP",
        "Digital LSP",
        serverOptions,
        clientOptions
    );

    client.start();
}

export function deactivate(): Thenable<void> | undefined {
    if (!client) {
        return undefined;
    }
    return client.stop();
}


function getLspServerExecutionNameVHDL() {
    const osname = platform();
    if (osname === 'win32') {
        return 'vhdl_ls.exe';
    }

    return 'vhdl_ls';
}

export function activateVHDL(context: vscode.ExtensionContext) {
    const lspServerName = getLspServerExecutionNameVHDL();
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
                language: 'vhdl' 
            }
        ],
    };

    client = new LanguageClient(
        "Digital LSP VHDL",
        "Digital LSP VHDL",
        serverOptions,
        clientOptions
    );

    client.start();
}

export function deactivateVHDL(): Thenable<void> | undefined {
    if (!vhdlClient) {
        return undefined;
    }
    return vhdlClient.stop();
}