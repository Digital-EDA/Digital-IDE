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
import { IProgress, LspClient, MainOutput, ReportType, opeParam } from '../../global';
import axios, { AxiosResponse } from "axios";
import { chooseBestDownloadSource, getLspFileName } from "./cdn";
import { hdlDir, hdlPath } from "../../hdlFs";
import { registerConfigurationUpdater, registerLinter } from "./config";
import { t } from "../../i18n";
import { getPlatformPlatformSignature } from "../../global/util";

function getLspServerExecutionName() {
    const signature = getPlatformPlatformSignature().toString();
    const osname = platform();
    if (osname === 'win32') {
        return `digital-lsp-${signature}.exe`;
    }

    return `digital-lsp-${signature}`;
}

export function getLspServerFolder(context: vscode.ExtensionContext): string {
    return path.join(context.globalStorageUri.fsPath, 'dide-lsp', 'server');
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

    inputStream.pipe(gunzip).pipe(extract as NodeJS.WritableStream);

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

function streamDownload(context: vscode.ExtensionContext, progress: vscode.Progress<IProgress>, response: AxiosResponse<any, any>, targetDir: string): Promise<string> {
    const totalLength = response.headers['content-length'];
    const totalSize = Number.isFinite(parseInt(totalLength)) ? parseInt(totalLength) : 0;
    let downloadSize = 0;
    const tmpDir = targetDir || path.join(context.globalStorageUri.fsPath, 'dide-lsp');
    if (!fs.existsSync(tmpDir)) {
        fs.mkdirSync(tmpDir, { recursive: true });
    }
    const savePath = path.join(tmpDir, 'tmp.tar.gz');
    const fileStream = fs.createWriteStream(savePath);
    response.data.pipe(fileStream);

    return new Promise((resolve, reject) => {
        response.data.on('data', (chunk: Buffer) => {
            downloadSize += chunk.length;
            if (totalSize > 0) {
                const percent = Math.ceil((downloadSize / totalSize) * 100);
                const increment = (chunk.length / totalSize) * 100;
                progress.report({ message: `${percent}%`, increment });
            }
        });

        fileStream.on('finish', () => {
            console.log('finish download to', savePath);
            fileStream.close();
            resolve(savePath);
        });

        fileStream.on('error', (err) => {
            reject(err);
        });
    });
}

async function checkAndDownload(context: vscode.ExtensionContext, version: string): Promise<boolean> {    
    const versionFolderPath = getLspServerFolder(context);

    const serverPath = path.join(versionFolderPath, getLspServerExecutionName());
    if (fs.existsSync(serverPath)) {
        return true;
    }

    hdlDir.mkdir(versionFolderPath);

    return await downloadLsp(context, version, versionFolderPath);
}

export async function downloadLsp(context: vscode.ExtensionContext, version: string, versionFolderPath: string): Promise<boolean> {
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
        return downloadLink;
    });

    const tarGzFilePath = await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('info.progress.download-digital-lsp')
    }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        progress.report({ increment: 0 });
        const response = await axios.get(downloadLink, { responseType: 'stream' });
        return await streamDownload(context, progress, response, versionFolderPath);
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


export async function installLsp(context: vscode.ExtensionContext, version: string, versionFolderPath: string): Promise<boolean> {

    const uri = await vscode.window.showOpenDialog({
        title: t('info.choose.digital-lsp-targz'),
        canSelectFiles: true,
        canSelectFolders: false,
        canSelectMany: false,
        filters: {
            [t('info.digital-lsp.targz')]: ['tar.gz'],
            [t('info.vcd-viewer.all-file')]: ['*']
        }
    });

    if (!uri) {
        return false;
    }

    const tarGzFilePath = uri[0].fsPath;
    const filename = path.basename(tarGzFilePath);
    const signature = getPlatformPlatformSignature().toString();
    const expectFilename = getLspFileName(version, signature);
    if (expectFilename !== filename) {
        vscode.window.showErrorMessage(t('error.digital-lsp.incorrect-filename', filename, expectFilename));
        return false;
    }

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
    const ready = await checkAndDownload(context, version);

    const lspServerName = getLspServerExecutionName();
    const lspServerPath = path.join(getLspServerFolder(context), lspServerName);

    if (fs.existsSync(lspServerPath)) {
        console.log('lsp server found at ' + lspServerPath);
    } else {
        // server 不存在时静默跳过：checkAndDownload 已在上一步处理过
        // （存在即用、缺失才下载）。这里不再重复触发下载，避免每次打开
        // 都弹下载进度；用户可经命令面板手动下载/安装。
        console.error('cannot found lsp server at ' + lspServerPath + ', skip LSP start');
        MainOutput.report(
            '未找到 LSP server，已跳过语言服务器启动（跳转/补全走内置解析）。' +
            '可经命令面板手动下载安装后再 Reload Window。',
            { level: ReportType.Warn }
        );
        return;
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
            toolChain: opeParam.prjInfo.toolChain,
            version: version
        }
    };

    const client = new LanguageClient(
        "Digital LSP",
        "Digital LSP",
        serverOptions,
        clientOptions
    );
    LspClient.DigitalIDE = client;
    
    // 启动 lsp
    await client.start();

    // 检测配置文件变动
    await registerConfigurationUpdater(client, packageJson);

    // 配置诊断器
    await registerLinter(client);
}




export function deactivate(): Thenable<void> | undefined {
    if (!LspClient.DigitalIDE) {
        return undefined;
    }
    return LspClient.DigitalIDE.stop();
}

