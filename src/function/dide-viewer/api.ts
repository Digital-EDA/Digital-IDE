import * as fs from 'fs';
import * as vscode from 'vscode';
import * as url from 'url';
import { BSON } from 'bson';
import * as path from 'path';
import * as os from 'os';
import { getIconConfig } from '../../hdlFs/icons';
import { t } from '../../i18n';

export interface SaveViewData {
    originVcdFile: string,
    originVcdViewFile: string,
    payload: any
}

export interface LaunchFiles {
    vcd: string,
    view: string,
    vcdjs: string,
    worker: string,
    wasm: string,
    root: string
}

const payloadCache = new Map<string, any>();

function mergePayloadCache(file: string, payload: any) {
    if (!payloadCache.has(file)) {
        payloadCache.set(file, payload);
    }
    const originPayload = payloadCache.get(file);
    Object.assign(originPayload, payload);
    return originPayload;
}

function extractFilepath(webviewUri: string) {
    if (webviewUri === undefined || webviewUri.length === 0) {
        return '';
    }
    const parsedUrl = new url.URL(webviewUri);    
    const pathname = decodeURIComponent(parsedUrl.pathname);
    const platform = os.platform();
    if (platform === 'win32' && pathname.startsWith('/')) {
        return pathname.slice(1);
    }

    return pathname;
}

// api 与 https://github.com/Digital-EDA/digital-vcd-backend 同构
export async function saveView(data: any, uri: vscode.Uri, panel: vscode.WebviewPanel) {
    try {
        let { originVcdFile, originVcdViewFile, payload } = data as SaveViewData;

        // webview uri 转换为绝对路径
        originVcdFile = extractFilepath(originVcdFile);
        originVcdViewFile = extractFilepath(originVcdViewFile);

        const rootPath = path.dirname(uri.fsPath);    
        payload.originVcdFile = path.isAbsolute(originVcdFile) ? originVcdFile : path.join(rootPath, originVcdFile).replace(/\\/g, '/');
        const originPayload = mergePayloadCache(originVcdViewFile, payload);

        const savePath = path.isAbsolute(originVcdViewFile) ? originVcdViewFile : path.join(rootPath, originVcdViewFile);
        
        const buffer = BSON.serialize(originPayload);
        fs.writeFileSync(savePath, buffer);
    } catch (error) {
        console.error('error happen in saveView ' + error);
    }
}

function getFilename(file: string) {
    const base = path.basename(file);
    const spls = base.split('.');
    
    if (spls.length === 1) {
        return base;
    }
    return spls[0];
}


export async function saveViewAs(data: any, uri: vscode.Uri, panel: vscode.WebviewPanel) {
    try {
        // 先保存原来的文件 payload 一定是 all
        let { originVcdFile, originVcdViewFile, payload } = data;

        // webview uri 转换为绝对路径
        originVcdFile = extractFilepath(originVcdFile);
        originVcdViewFile = extractFilepath(originVcdViewFile);

        const rootPath = path.dirname(uri.fsPath);
        payload.originVcdFile = path.isAbsolute(originVcdFile) ? originVcdFile : path.join(rootPath, originVcdFile).replace(/\\/g, '/');
        
        const originPayload = mergePayloadCache(originVcdViewFile, payload);

        // 询问新的路径        
        const defaultFilename = getFilename(payload.originVcdFile);
        const vcdFilters: Record<string, string[]> = {};
        vcdFilters[t('info.vcd-viewer.vcd-view-file')] = ['view'];
        vcdFilters[t('info.vcd-viewer.all-file')] = ['*'];
        const saveUri = await vscode.window.showSaveDialog({
            title: t('info.vcd-viewer.save-as-view'),
            defaultUri: vscode.Uri.file(path.join(rootPath, defaultFilename)),
            saveLabel: t('info.vcd-viewer.save'),
            filters: vcdFilters
        });

        if (saveUri) {
            const savePath = saveUri.fsPath;
            const buffer = BSON.serialize(originPayload);            
            fs.writeFileSync(savePath, buffer);

            panel.title = path.basename(savePath);
            panel.iconPath = getIconConfig('view');

            // 创建新的缓存 savePath 会成为新的 originVcdViewFile
            mergePayloadCache(savePath, payload);

            panel.webview.postMessage({
                command: 'save-view-as',
                viewPath: savePath.replace(/\\/g, '/')
            });
        } else {
            panel.webview.postMessage({
                command: 'save-view-as',
                viewPath: undefined
            });
        }
    } catch (error) {
        console.error('error happen in saveViewAs ' + error);
    }
}


export async function loadView(data: any, uri: vscode.Uri, panel: vscode.WebviewPanel) {
    try {
        let { originVcdFile } = data;

        originVcdFile = extractFilepath(originVcdFile);

        const rootPath = path.dirname(uri.fsPath);
        const vcdPath = path.isAbsolute(originVcdFile) ? originVcdFile : path.join(rootPath, originVcdFile).replace(/\\/g, '/');

        const defaultFolder = path.dirname(vcdPath);
        const vcdFilters: Record<string, string[]> = {};
        vcdFilters[t('info.vcd-viewer.vcd-view-file')] = ['view'];
        vcdFilters[t('info.vcd-viewer.all-file')] = ['*'];

        const viewUri = await vscode.window.showOpenDialog({
            title: t('info.vcd-viewer.load.title'),
            defaultUri: vscode.Uri.file(defaultFolder),
            openLabel: t('info.vcd-viewer.load.button'),
            canSelectFiles: true,
            canSelectMany: false,
            canSelectFolders: false,
            filters: vcdFilters
        });

        if (viewUri) {
            const viewPath = viewUri[0].fsPath;
            const buffer = fs.readFileSync(viewPath);
            panel.title = path.basename(viewPath);
            panel.iconPath = getIconConfig('view');

            const recoverJson = BSON.deserialize(buffer);
            panel.webview.postMessage({
                command: 'load-view',
                recoverJson,
                viewPath
            });
        } else {
            panel.webview.postMessage({
                command: 'load-view',
                recoverJson: undefined,
                viewPath: undefined
            });
        }
    } catch (error) {
        console.error('error happen in loadView ' + error);
    }
}