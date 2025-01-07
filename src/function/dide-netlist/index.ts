import * as vscode from 'vscode';
import * as fspath from 'path';
import * as fs from 'fs';
import * as os from 'os';

import { WASI } from 'wasi';

import { AbsPath, opeParam, ReportType, YosysOutput } from '../../global';
import { hdlParam } from '../../hdlParser';
import { hdlDir, hdlFile, hdlPath } from '../../hdlFs';
import { defaultMacro, doFastApi } from '../../hdlParser/util';
import { HdlFile } from '../../hdlParser/core';
import { t } from '../../i18n';
import { HdlLangID } from '../../global/enum';
import { getIconConfig } from '../../hdlFs/icons';
import { getDiskLetters, PathSet } from '../../global/util';
import { gotoDefinition, saveAsPdf, saveAsSvg } from './api';
import { Worker } from 'worker_threads';

type SynthMode = 'before' | 'after' | 'RTL';


class Netlist {
    context: vscode.ExtensionContext;
    wsName: string;
    libName: string;
    panel?: vscode.WebviewPanel;
    wasm?: WebAssembly.Module;

    constructor(context: vscode.ExtensionContext) {
        this.context = context;
        this.wsName = '{workspace}';
        this.libName = '{library}';
    }

    public async open(uri: vscode.Uri, moduleName: string, option = {}) {
        const pathset = new PathSet();
        const path = hdlPath.toSlash(uri.fsPath);

        let moduleFile = hdlParam.getHdlFile(path);
        // 没有说明是单文件模式，直接打开解析
        if (!moduleFile) {
            const standardPath = hdlPath.toSlash(path);
            const response = await doFastApi(standardPath, 'common');
            const langID = hdlFile.getLanguageId(standardPath);
            const projectType = hdlParam.getHdlFileProjectType(standardPath, 'common');
            moduleFile = new HdlFile(
                standardPath, langID,
                response?.macro || defaultMacro,
                response?.content || [],
                projectType,
                'common'
            );
            // 从 hdlParam 中去除，避免干扰全局
            hdlParam.removeFromHdlFile(moduleFile);
    
            // const message = t('error.common.not-valid-hdl-file');
            // const errorMsg = path + ' ' + message + ' ' + opeParam.prjInfo.hardwareSrcPath + '\n' + opeParam.prjInfo.hardwareSimPath;
            // vscode.window.showErrorMessage(errorMsg);
            // return undefined;
        }

        for (const hdlModule of moduleFile.getAllHdlModules()) {
            const hdlDependence = hdlParam.getAllDependences(path, hdlModule.name);
            if (hdlDependence) {
                // include 宏在后续会被正确处理，所以只需要处理 others 即可
                hdlDependence.others.forEach(path => pathset.add(path));
            }
        }
        pathset.add(path);
        
        const prjFiles = [...pathset.files];

        console.log(prjFiles);
        console.log(opeParam.prjInfo.prjPath);

        if (!this.wasm) {
            const wasm = await this.loadWasm();
            this.wasm = wasm;
        }

        const targetYs = this.makeYs(prjFiles, moduleName);
        if (!targetYs || !this.wasm) {
            return;
        }

        const wasm = this.wasm;
        const wasiResult = await this.makeWasi(targetYs, moduleName);
        
        if (wasiResult === undefined) {
            return;
        }
        const { wasi, fd } = wasiResult;

        const netlistPayloadFolder = hdlPath.join(opeParam.prjInfo.prjPath, 'netlist');
        const targetJson = hdlPath.join(netlistPayloadFolder, moduleName + '.json');
        hdlFile.rmSync(targetJson);

        await vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: t('info.netlist.generate-network'),
            cancellable: true
        }, async (_, token) => {
            token.onCancellationRequested(() => {
                console.log('cancel');
                fs.closeSync(fd);
            });

            const instance = WebAssembly.instantiate(wasm, {
                wasi_snapshot_preview1: wasi.wasiImport
            });
            try {
                const exitCode = wasi.start(instance);
            } catch (error) {
                console.error(error);
            }
        });

        if (!fs.existsSync(targetJson)) {
            fs.closeSync(fd);
            const logFilePath = hdlPath.join(opeParam.prjInfo.prjPath, 'netlist', moduleName + '.log');
            const res = await vscode.window.showErrorMessage(
                t('error.cannot-gen-netlist'),
                { title: t('error.look-up-log'), value: true }
            )
            if (res?.value) {
                const document = await vscode.workspace.openTextDocument(vscode.Uri.file(logFilePath));
                await vscode.window.showTextDocument(document);
            }
            return;
        }

        this.create(moduleName, fd);
    }

    private getSynthMode(): SynthMode {
        const configuration = vscode.workspace.getConfiguration();
        return configuration.get<SynthMode>('digital-ide.function.netlist.schema-mode') || 'before';
    }

    private makeYs(files: AbsPath[], topModule: string) {
        const netlistPayloadFolder = hdlPath.join(opeParam.prjInfo.prjPath, 'netlist');
        hdlDir.mkdir(netlistPayloadFolder);
        const target = hdlPath.join(netlistPayloadFolder, topModule + '.ys');
        const targetJson = hdlPath.join(netlistPayloadFolder, topModule + '.json').replace(opeParam.workspacePath, this.wsName);

        const scripts: string[] = [];
        for (const file of files) {
            const langID = hdlFile.getLanguageId(file);
            if (langID === HdlLangID.Unknown || langID === HdlLangID.Vhdl) {
                vscode.window.showErrorMessage(t('info.netlist.not-support-vhdl'));
                return undefined;
            }

            if (file.startsWith(opeParam.workspacePath)) {
                const constraintPath = file.replace(opeParam.workspacePath, this.wsName);
                scripts.push(`read_verilog -sv -formal -overwrite ${constraintPath}`);
            } else if (file.startsWith(opeParam.prjInfo.libCommonPath)) {
                const constraintPath = file.replace(opeParam.prjInfo.libCommonPath, this.libName);
                scripts.push(`read_verilog -sv -formal -overwrite ${constraintPath}`);
            }
        }

        const mode = this.getSynthMode();
        switch (mode) {
        case 'before':
            scripts.push('design -reset-vlog; proc;');
            break;
        case 'after':
            scripts.push('design -reset-vlog; proc; opt_clean;');
            break;
        case 'RTL':
            scripts.push('synth -run coarse;');
            break;
        }
        scripts.push(`write_json ${targetJson}`);
        const ysCode = scripts.join('\n');
        hdlFile.writeFile(target, ysCode);
        return target.replace(opeParam.workspacePath, this.wsName);
    }

    public async getPreopens() {
        const basepreopens = {
            '/share': hdlPath.join(opeParam.extensionPath, 'resources', 'dide-netlist', 'static', 'share'),
            [this.wsName ]: opeParam.workspacePath,
            [this.libName]: opeParam.prjInfo.libCommonPath
        };
        if (os.platform() === 'win32') {
            const mounts = await getDiskLetters();
            for (const mountName of mounts) {
                const realMount = mountName + '/';
                basepreopens[realMount.toLowerCase()] = realMount;
                basepreopens[realMount.toUpperCase()] = realMount;
            }
        } else {
            basepreopens['/'] = '/';
        }
        return basepreopens;
    }

    private async makeWasi(target: string, logName: string) {
        // 创建日志文件路径
        const logFilePath = hdlPath.join(opeParam.prjInfo.prjPath, 'netlist', logName + '.log');
        hdlFile.removeFile(logFilePath);
        const logFd = fs.openSync(logFilePath, 'a');

        try {
            const wasiOption = {
                version: 'preview1',
                args: [
                    'yosys',
                    '-s',
                    target
                ],
                preopens: await this.getPreopens(),
                stdin: process.stdin.fd,
                stdout: process.stdout.fd,
                stderr: logFd,
                env: process.env
            };

            const wasi = new WASI(wasiOption);
            return { wasi, fd: logFd };
        } catch (error) {
            fs.closeSync(logFd);
            return undefined;
        }
    }

    private async loadWasm() {
        const netlistWasmPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-netlist', 'static', 'yosys.wasm');
        if (!hdlPath.exist(netlistWasmPath)) {
            vscode.window.showErrorMessage(t('info.netlist.not-found-payload'));
            throw Error(t('info.netlist.not-found-payload'));
        }
        const binary = fs.readFileSync(netlistWasmPath);
        const wasm = await WebAssembly.compile(binary);
        return wasm;
    }
 
    private create(moduleName: string, fd: number) {
        // Create panel
        this.panel = vscode.window.createWebviewPanel(
            'Netlist',
            'Netlist',
            vscode.ViewColumn.One,
            {
                enableScripts: true,
                enableForms: true,
                retainContextWhenHidden: true
            }
        );

        this.panel.onDidDispose(() => {
            fs.closeSync(fd);
        });

        const previewHtml = this.getWebviewContent();
        if (this.panel && previewHtml) {
            const netlistPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-netlist', 'view');
            const netlistPayloadFolder = hdlPath.join(opeParam.prjInfo.prjPath, 'netlist');
            const targetJson = hdlPath.join(netlistPayloadFolder, moduleName + '.json');
            const skinPath= hdlPath.join(netlistPath, 'dide.skin');

            const graph = this.panel.webview.asWebviewUri(vscode.Uri.file(targetJson)).toString();
            const skin = this.panel.webview.asWebviewUri(vscode.Uri.file(skinPath)).toString();
            this.panel.iconPath = getIconConfig('view');

            let preprocessHtml = previewHtml
                .replace('test.json', graph)
                .replace('test.module', moduleName)
                .replace('dide.skin', skin);

            this.panel.webview.html = preprocessHtml;

            registerMessageEvent(this.panel);
        } else {
            YosysOutput.report('preview html in <Netlist.create> is empty', {
                level: ReportType.Warn
            });
        }
    }
    
    public send() {

    }

    public getWebviewContent() {
        const netlistPath = hdlPath.join(opeParam.extensionPath, 'resources', 'dide-netlist', 'view');
        const htmlIndexPath = hdlPath.join(netlistPath, 'index.html');

        const html = hdlFile.readFile(htmlIndexPath)?.replace(/(<link.+?href="|<script.+?src="|<img.+?src=")(.+?)"/g, (m, $1, $2) => {
            const absLocalPath = fspath.resolve(netlistPath, $2);
            const webviewUri = this.panel?.webview.asWebviewUri(vscode.Uri.file(absLocalPath));
            const replaceHref = $1 + webviewUri?.toString() + '"';
            return replaceHref;
        });
        return html;
    }

    public getJsonPathFromYs(path: AbsPath): AbsPath | undefined {
        for (const line of fs.readFileSync(path, { encoding: 'utf-8' }).split('\n')) {
            if (line.trim().startsWith('write_json')) {
                const path = line.split(/\s+/).at(1);
                if (path) {
                    const realPath = path
                        .replace(this.wsName, opeParam.workspacePath)
                        .replace(this.libName, opeParam.prjInfo.libCommonPath);
                    return hdlPath.toSlash(realPath);
                }
            }
        }
        return undefined;
    }

    public async runYs(uri: vscode.Uri) {
        const ysPath = hdlPath.toSlash(uri.fsPath);
        const targetJson = this.getJsonPathFromYs(ysPath);
        const name = ysPath.split('/').at(-1) as string;
        const wasiResult = await this.makeWasi(ysPath, name);
        
        if (wasiResult === undefined) {
            return;
        }
        const { wasi, fd } = wasiResult;

        if (targetJson) {
            hdlFile.rmSync(targetJson);
        }

        if (!this.wasm) {
            const wasm = await this.loadWasm();
            this.wasm = wasm;
        }
        const wasm = this.wasm;

        await vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: t('info.netlist.generate-network'),
            cancellable: true
        }, async () => {
            const instance = await WebAssembly.instantiate(wasm, {
                wasi_snapshot_preview1: wasi.wasiImport
            });
            const exitCode = wasi.start(instance);
        });

        if (targetJson && !fs.existsSync(targetJson)) {
            fs.closeSync(fd);
            const logFilePath = hdlPath.join(opeParam.prjInfo.prjPath, 'netlist', name + '.log');
            const res = await vscode.window.showErrorMessage(
                t('error.cannot-gen-netlist'),
                { title: t('error.look-up-log'), value: true }
            )
            if (res?.value) {
                const document = await vscode.workspace.openTextDocument(vscode.Uri.file(logFilePath));
                await vscode.window.showTextDocument(document);
            }
        }
    }
}

export async function openNetlistViewer(context: vscode.ExtensionContext, uri: vscode.Uri, moduleName: string) {
    const viewer = new Netlist(context);
    viewer.open(uri, moduleName);
}

export async function runYsScript(context: vscode.ExtensionContext, uri: vscode.Uri) {
    const viewer = new Netlist(context);
    viewer.runYs(uri);
}


function registerMessageEvent(panel: vscode.WebviewPanel) {
    panel.webview.onDidReceiveMessage(message => {
        const { command, data } = message;

        switch (command) {
            case 'save-as-svg':
                saveAsSvg(data, panel);
                break;
            case 'save-as-pdf':
                saveAsPdf(data, panel);
                break;
            case 'goto-definition':
                gotoDefinition(data, panel);
                break;
            default:
                break;
        }
    });
}