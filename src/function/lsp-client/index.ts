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
import { IProgress, LspClient } from '../../global';
import axios from "axios";
import { getGiteeDownloadLink, getPlatformPlatformSignature } from "./cdn";


function getLspServerExecutionName() {
    const osname = platform();
    if (osname === 'win32') {
        return 'digital-lsp.exe';
    }

    return 'digital-lsp';
}

async function checkAndDownload(context: vscode.ExtensionContext, progress: vscode.Progress<IProgress>, version: string): boolean {
    const { t } = vscode.l10n;
    
    const versionFolderPath = context.asAbsolutePath(
        path.join('resources', 'dide-lsp', 'server', version)
    );

    const serverPath = path.join(versionFolderPath, getLspServerExecutionName());
    if (fs.existsSync(versionFolderPath) && fs.existsSync(serverPath)) {
        return true;
    }

    // 流式下载
    progress.report({ message: t('progress.download-digital-lsp') });
    const signature = getPlatformPlatformSignature().toString();
    const giteeDownloadLink = getGiteeDownloadLink(signature, version)
    console.log('download link ', giteeDownloadLink);
    
    const response = await axios.get(giteeDownloadLink, { responseType: 'stream' });
    const totalLength = response.headers['content-length'];
    console.log('totalLength ', totalLength);
    

    return false;
}

export async function activate(context: vscode.ExtensionContext, progress: vscode.Progress<IProgress>, version: string) {
    await checkAndDownload(context, progress, version);


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
        markdown: {
            isTrusted: true
        }
    };

    const client = new LanguageClient(
        "Digital LSP",
        "Digital LSP",
        serverOptions,
        clientOptions
    );
    LspClient.DigitalIDE = client;
    
    client.start();
}

export function deactivate(): Thenable<void> | undefined {
    if (!LspClient.DigitalIDE) {
        return undefined;
    }
    return LspClient.DigitalIDE.stop();
}

