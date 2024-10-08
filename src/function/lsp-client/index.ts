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
import axios, { AxiosResponse } from "axios";
import { getGiteeDownloadLink, getPlatformPlatformSignature } from "./cdn";


function getLspServerExecutionName() {
    const osname = platform();
    if (osname === 'win32') {
        return 'digital-lsp.exe';
    }

    return 'digital-lsp';
}

async function checkAndDownload(context: vscode.ExtensionContext, version: string): boolean {
    const { t } = vscode.l10n;
    
    const versionFolderPath = context.asAbsolutePath(
        path.join('resources', 'dide-lsp', 'server', version)
    );

    const serverPath = path.join(versionFolderPath, getLspServerExecutionName());
    if (fs.existsSync(versionFolderPath) && fs.existsSync(serverPath)) {
        return true;
    }

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('progress.download-digital-lsp')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        progress.report({ increment: 0 });
        const signature = getPlatformPlatformSignature().toString();
        const downloadLink = getGiteeDownloadLink(signature, version);
        const response = await axios.get(downloadLink, { responseType: 'stream' });
        
    });

    function streamDownload(progress: vscode.Progress<IProgress>, response: AxiosResponse<any, any>): Promise<void> {
        const totalLength = response.headers['content-length'];
        const totalSize = parseInt(totalLength);
        let downloadSize = 0;
        const savePath = context.asAbsolutePath(
            path.join('resources', 'dide-lsp', 'server', 'tmp.tar.gz')
        );
        const fileStream = fs.createWriteStream(savePath);

        response.data.on('data', (chunk: Buffer) => {
            downloadSize += chunk.length;
            let increment = Math.ceil(downloadSize / totalSize * 100);
            progress.report({ message: t('progress.download-digital-lsp'), increment });
        });
        return new Promise((resolve, reject) => {
            fileStream.on('finish', () => {
                resolve();
            });
    
            fileStream.on('error', (error) => {
                reject(error);
            });
        });
    }

    return false;
}

export async function activate(context: vscode.ExtensionContext, version: string) {
    await checkAndDownload(context, version);


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

