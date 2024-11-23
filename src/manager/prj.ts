/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';

import { AbsPath, IProgress, LspClient, MainOutput, opeParam, ReportType } from '../global';
import { PathSet } from '../global/util';
import { RawPrjInfo } from '../global/prjInfo';
import { hdlDir, hdlFile, hdlPath } from '../hdlFs';
import { libManage } from './lib';
import { hdlParam } from '../hdlParser';
import { PlManage } from './PL';
import { PsManage } from './PS';
import { hdlIgnore } from './ignore';
import { ppyAction } from '../monitor/event';
import { hdlMonitor } from '../monitor';
import { NotificationType } from 'vscode-jsonrpc';
import { refreshArchTree } from '../function/treeView';
import { Fast } from '../hdlParser/common';
import { t } from '../i18n';

interface RefreshPrjConfig {
    mkdir: boolean
}

class PrjManage {
    pl?: PlManage;
    ps?: PsManage;

    // generate property template and write it to .vscode/property.json
    public async generatePropertyJson() {
        if (fs.existsSync(opeParam.propertyJsonPath)) {
            vscode.window.showWarningMessage('property file already exists !!!');
            return;
        }
        const template = hdlFile.readJSON(opeParam.propertyInitPath) as RawPrjInfo;
        hdlFile.writeJSON(opeParam.propertyJsonPath, template);

        // TODO : this is a bug, that monitor cannot sense the add event of ppy
        // so we need to do <add event> manually here
        await ppyAction.add(opeParam.propertyJsonPath, hdlMonitor);
    }

    // overwrite content in current property.json to property-init.json
    public async overwritePropertyJson() {
        const options = {
            preview: false,
            viewColumn: vscode.ViewColumn.Active
        };
        const uri = vscode.Uri.file(opeParam.propertyInitPath);
        await vscode.window.showTextDocument(uri, options);
    }

    private getWorkspacePath(): AbsPath {
        if (vscode.workspace.workspaceFolders !== undefined &&
            vscode.workspace.workspaceFolders.length !== 0) {
            const wsPath = vscode.workspace.workspaceFolders[0].uri.fsPath;
            return hdlPath.toSlash(wsPath);
        }
        return '';
    }

    /**
     * init opeParam
     * @param context 
     */
    public async initOpeParam(context: vscode.ExtensionContext): Promise<RefreshPrjConfig> {
        const os = process.platform;
        const extensionPath = hdlPath.toSlash(context.extensionPath);
        const workspacePath = this.getWorkspacePath();
        const propertyJsonPath = hdlPath.join(workspacePath, '.vscode', 'property.json');
        const propertySchemaPath = hdlPath.join(extensionPath, 'project', 'property-schema.json');
        const propertyInitPath = hdlPath.join(extensionPath, 'project', 'property-init.json');

        opeParam.setBasicInfo(os, 
                              extensionPath, 
                              workspacePath, 
                              propertyJsonPath, 
                              propertySchemaPath, 
                              propertyInitPath);
        
        // set path for merge in prjInfo        
        opeParam.prjInfo.initContextPath(extensionPath, workspacePath);

        const refreshPrjConfig: RefreshPrjConfig = {mkdir: true};

        // merge prjInfo from propertyJsonPath if exist
        if (fs.existsSync(propertyJsonPath)) {
            const rawPrjInfo = hdlFile.readJSON(propertyJsonPath) as RawPrjInfo;
            opeParam.mergePrjInfo(rawPrjInfo);
        } else {
            refreshPrjConfig.mkdir = false;
        }

        return refreshPrjConfig;
    }

    /**
     * @description 获取所有的用户 hdl 文件，包括：
     * - sim
     * - src
     * - common lib
     * - custom lib
     * @returns 
     */
    public async getPrjHardwareFiles(): Promise<AbsPath[]> {
        const searchPathSet = new PathSet();
        const prjInfo = opeParam.prjInfo;
        const hardwareInfo = prjInfo.arch.hardware;

        // 根据当前的打开模式来判断
        if (opeParam.openMode === 'file') {
            // 如果是单文件模式，需要的操作
        } else {
            // 先处理 lib 文件
            const fileChange = await libManage.processLibFiles(prjInfo.library);
            MainOutput.report(`libManage finish process, add ${fileChange.add.length} files, del ${fileChange.del.length} files`, ReportType.Info);
    
            // 默认搜索路径包括：
            // src, sim, lib
            searchPathSet.checkAdd(prjInfo.hardwareSrcPath);
            searchPathSet.checkAdd(prjInfo.hardwareSimPath);
            searchPathSet.checkAdd(hardwareInfo.sim);
            searchPathSet.checkAdd(prjInfo.getLibraryCommonPaths());
            searchPathSet.checkAdd(prjInfo.getLibraryCustomPaths());
        }

        MainOutput.report('<getPrjHardwareFiles> search folders: ', ReportType.Debug);
        searchPathSet.files.forEach(p => MainOutput.report(p, ReportType.Debug));

        // TODO : make something like .gitignore
        const ignores = hdlIgnore.getIgnoreFiles();

        // do search
        const searchPaths = searchPathSet.files;
        const hdlFiles = hdlFile.getHDLFiles(searchPaths, ignores);

        return hdlFiles;
    }

    /**
     * @description 获取当前项目中所有的 IP 文件夹
     */
    public async getPrjIPs() {
        const toolchain = opeParam.prjInfo.toolChain;
        
        switch (toolchain) {
            case 'xilinx':
                return this.getXilinxIPs();
                break;
        
            default:
                break;
        }
        return [];
    }

    public getXilinxIPs() {
        const srcFolder = opeParam.prjInfo.arch.hardware.src;
        const ipFolder = hdlPath.resolve(srcFolder, '../ip');
        const validIPs: string[] = [];
        if (fs.existsSync(ipFolder) && hdlFile.isDir(ipFolder)) {
            for (const folder of fs.readdirSync(ipFolder)) {
                const folderPath = hdlPath.join(ipFolder, folder);
                if (this.isValidXilinxIP(folderPath)) {
                    validIPs.push(folderPath);
                }
            }
        }
        return validIPs;
    }

    public isValidXilinxIP(folderPath: string): boolean {
        const folderName = fspath.basename(folderPath);
        const descriptionFile = folderName + '.xci';
        const descriptionFilePath = hdlPath.join(folderPath, descriptionFile);
        return fs.existsSync(descriptionFilePath);
    }

    public async initialise(context: vscode.ExtensionContext, progress: vscode.Progress<IProgress>, countTimeCost: boolean = true) {
        if (countTimeCost) {
            console.time('launch');
        }

        
        // 解析 hdl 文件，构建 hdlParam
        const hdlFiles = await this.getPrjHardwareFiles();                  
        await hdlParam.initializeHdlFiles(hdlFiles, progress);

        // 根据 toolchain 解析合法的 IP，构建 hdlParam
        const IPsPath = await this.getPrjIPs();
        await hdlParam.initializeIPsPath(IPsPath, progress);

        // TODO: 解析原语并构建，向后端索要原语缓存
        

        // 构建 instance 解析
        await hdlParam.makeAllInstance();

        // 分析依赖关系错位情况
        const unhandleNum = hdlParam.getUnhandleInstanceNumber();
        MainOutput.report(`finish analyse ${hdlFiles.length} hdl files, find ${unhandleNum} unsolved instances`, ReportType.Info);


        this.pl = new PlManage();
        // TODO : finish it later
        // this.ps = new PsManage();
        MainOutput.report('create pl', ReportType.Info);

        
        if (countTimeCost) {
            console.timeLog('launch');
        }
    }

    public async refreshPrjFolder(config?: RefreshPrjConfig) {
        if (config && config.mkdir === false) {
            return;
        }
        // read new prj from ppy
        const rawPrjInfo = opeParam.getRawUserPrjInfo();

        if (rawPrjInfo.arch) {
            // configure user's info
            await this.createFolderByRawPrjInfo(rawPrjInfo);
        } else {
            // configure by default            
            await this.createFolderByDefault(rawPrjInfo);
        }

        opeParam.prjInfo.checkArchDirExist();
    }

    public async createFolderByRawPrjInfo(rawPrjInfo: RawPrjInfo) {
        if (rawPrjInfo.arch) {
            hdlDir.mkdir(rawPrjInfo.arch.prjPath);
            
            const hardware = rawPrjInfo.arch.hardware;
            const software = rawPrjInfo.arch.software;

            if (hardware) {
                hdlDir.mkdir(hardware.src);
                hdlDir.mkdir(hardware.sim);
                hdlDir.mkdir(hardware.data);
            }

            if (software) {
                hdlDir.mkdir(software.src);
                hdlDir.mkdir(software.data);
            }
        }
    }


    public async createFolderByDefault(rawPrjInfo: RawPrjInfo) {
        // create prj first
        const defaultPrjPath = hdlPath.join(opeParam.workspacePath, 'prj');
        hdlDir.mkdir(defaultPrjPath);

        // 如果 soc.core 有效，那么就是 LS，否则是 PL
        const nextmode = this.getNextMode(rawPrjInfo);
        
        const hardware = opeParam.prjInfo.arch.hardware;
        const software = opeParam.prjInfo.arch.software;
        
        hdlDir.mkdir(hardware.src);
        hdlDir.mkdir(hardware.sim);
        hdlDir.mkdir(hardware.data);
        if (nextmode === 'LS') {
            hdlDir.mkdir(software.src);
            hdlDir.mkdir(software.data);
        }
    }

    public getNextMode(rawPrjInfo: RawPrjInfo): 'PL' | 'LS' {
        if (rawPrjInfo.soc && rawPrjInfo.soc.core !== 'none') {
            return 'LS';
        }
        return 'PL';
    }

    public getCurrentMode(softwarePath: AbsPath, hardwarePath: AbsPath): 'PL' | 'LS' {
        if (fs.existsSync(softwarePath) || fs.existsSync(hardwarePath)) {
            return 'LS';
        }
        return 'PL';
    }
}

const prjManage = new PrjManage();

export {
    prjManage,
    PrjManage
};