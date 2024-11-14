import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    Executable,
} from "vscode-languageclient/node";

import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import * as zlib from 'zlib';
import * as tar from 'tar';
import { platform } from "os";
import { IProgress, LspClient, opeParam } from '../../global';
import axios, { AxiosResponse } from "axios";
import { chooseBestDownloadSource, getGiteeDownloadLink, getGithubDownloadLink, getPlatformPlatformSignature } from "./cdn";
import { hdlDir, hdlPath } from "../../hdlFs";
import { registerConfigurationUpdater } from "./config";

function getLspServerExecutionName() {
    const osname = platform();
    if (osname === 'win32') {
        return 'digital-lsp.exe';
    }

    return 'digital-lsp';
}

function extractTarGz(filePath: string, outputDir: string): Promise<void> {
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    const inputStream = fs.createReadStream(filePath);
    const gunzip = zlib.createGunzip();
    const extract = tar.extract({
        cwd: outputDir, // 解压到指定目录
    });

    inputStream.pipe(gunzip).pipe(extract);

    return new Promise((resolve, reject) => {
        extract.on('finish', () => {
            for (const file of fs.readdirSync(outputDir)) {
                const filePath = hdlPath.join(outputDir, file);
                fs.chmodSync(filePath, '755');
            }
            resolve();
        });
        extract.on('error', reject);
    })
}

function streamDownload(context: vscode.ExtensionContext, progress: vscode.Progress<IProgress>, response: AxiosResponse<any, any>): Promise<string> {    
    const totalLength = response.headers['content-length'];    
    const totalSize = parseInt(totalLength);
    let downloadSize = 0;
    const savePath = context.asAbsolutePath(
        path.join('resources', 'dide-lsp', 'server', 'tmp.tar.gz')
    );
    const fileStream = fs.createWriteStream(savePath);
    response.data.pipe(fileStream);

    return new Promise((resolve, reject) => {
        response.data.on('data', (chunk: Buffer) => {
            downloadSize += chunk.length;            
            let precent = Math.ceil(downloadSize / totalSize * 100);
            let increment = chunk.length / totalSize * 100;                
            progress.report({ message: `${precent}%`, increment });
        });

        fileStream.on('finish', () => {
            console.log('finish download');
            fileStream.close();
            resolve(savePath);
        });

        fileStream.on('error', reject);
    });
}

async function checkAndDownload(context: vscode.ExtensionContext, version: string): Promise<boolean> {    
    const versionFolderPath = context.asAbsolutePath(
        path.join('resources', 'dide-lsp', 'server', version)
    );

    const serverPath = path.join(versionFolderPath, getLspServerExecutionName());
    if (fs.existsSync(versionFolderPath) && fs.existsSync(serverPath)) {
        return true;
    }

    const serverFolder = context.asAbsolutePath(
        path.join('resources', 'dide-lsp', 'server')
    );
    hdlDir.mkdir(serverFolder);

    return await downloadLsp(context, version, versionFolderPath);
}

export async function downloadLsp(context: vscode.ExtensionContext, version: string, versionFolderPath: string): Promise<boolean> {
    const { t } = vscode.l10n;
    
    const downloadLink = await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('info.progress.choose-best-download-source')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        let timeout = 3000;
        let reportInterval = 500;
        const intervalHandler = setInterval(() => {
            progress.report({ increment: reportInterval / timeout * 100 });
        }, reportInterval);

        const signature = getPlatformPlatformSignature().toString();
        const downloadLink = await chooseBestDownloadSource(signature, version, timeout);
        console.log('choose download link: ' + downloadLink);
              
        clearInterval(intervalHandler);
        return downloadLink
    });

    const tarGzFilePath = await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('info.progress.download-digital-lsp')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        progress.report({ increment: 0 });
        const response = await axios.get(downloadLink, { responseType: 'stream' });
        return await streamDownload(context, progress, response);
    });

    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('info.progress.extract-digital-lsp')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        if (fs.existsSync(tarGzFilePath)) {
            console.log('check finish, begin to extract');
            await extractTarGz(tarGzFilePath, versionFolderPath);
        } else {
            vscode.window.showErrorMessage(t('error.lsp.download-digital-lsp') + version);
        }
    });

    return false;
}

export async function activate(context: vscode.ExtensionContext, packageJson: any) {
    const version = packageJson.version;
    await checkAndDownload(context, version);

    const lspServerName = getLspServerExecutionName();
    const lspServerPath = context.asAbsolutePath(
        path.join('resources', 'dide-lsp', 'server', version, lspServerName)
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

    let workspaceFolder: undefined | { uri: vscode.Uri, name: string, index: number } = undefined;
    if (vscode.workspace.workspaceFolders) {
        const currentWsFolder = vscode.workspace.workspaceFolders[0];
        workspaceFolder = currentWsFolder;
    }

    let extensionPath = hdlPath.toSlash(context.extensionPath);

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
        progressOnInitialization: true,
        markdown: {
            isTrusted: true,
            supportHtml: true
        },
        workspaceFolder,
        initializationOptions: {
            extensionPath,
            toolChain: opeParam.prjInfo.toolChain
        }
    };

    const client = new LanguageClient(
        "Digital LSP",
        "Digital LSP",
        serverOptions,
        clientOptions
    );
    LspClient.DigitalIDE = client;
    
    await client.start();

    registerConfigurationUpdater(client, packageJson);
}




export function deactivate(): Thenable<void> | undefined {
    if (!LspClient.DigitalIDE) {
        return undefined;
    }
    return LspClient.DigitalIDE.stop();
}

