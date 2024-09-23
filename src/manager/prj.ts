/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';

import { AbsPath, IProgress, MainOutput, opeParam, ReportType } from '../global';
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
            const res = await vscode.window.showInformationMessage(
                "property.json is not detected, do you want to create one ?",
                { title: 'Yes', value: true },
                { title: 'No', value: false }
            );
            if (res?.value) {
                await this.generatePropertyJson();
                const rawPrjInfo = hdlFile.readJSON(propertyJsonPath) as RawPrjInfo;
                opeParam.mergePrjInfo(rawPrjInfo);
            } else {
                refreshPrjConfig.mkdir = false;
            }
        }

        return refreshPrjConfig;
    }

    /**
     * get all the hdl files that to be parsed in the project
     * @returns 
     */
    public async getPrjHardwareFiles(): Promise<AbsPath[]> {
        const searchPathSet = new PathSet();
        const prjInfo = opeParam.prjInfo;
        const hardwareInfo = prjInfo.arch.hardware;
        
        // handle library first
        const fileChange = await libManage.processLibFiles(prjInfo.library);
        MainOutput.report(`libManage finish process, add ${fileChange.add.length} files, del ${fileChange.del.length} files`, ReportType.Info);

        // add possible folder to search
        searchPathSet.checkAdd(prjInfo.hardwareSrcPath);
        searchPathSet.checkAdd(prjInfo.hardwareSimPath);
        searchPathSet.checkAdd(hardwareInfo.sim);
        searchPathSet.checkAdd(prjInfo.getLibraryCommonPaths());
        searchPathSet.checkAdd(prjInfo.getLibraryCustomPaths());
                
        MainOutput.report('<getPrjHardwareFiles> search folders: ', ReportType.Debug);
        searchPathSet.files.forEach(p => MainOutput.report(p, ReportType.Debug));

        // TODO : make something like .gitignore
        const ignores = hdlIgnore.getIgnoreFiles();

        // do search
        const searchPaths = searchPathSet.files;
        
        const hdlFiles = hdlFile.getHDLFiles(searchPaths, ignores);        
        return hdlFiles;
    }

    

    public async initialise(context: vscode.ExtensionContext, progress: vscode.Progress<IProgress>, countTimeCost: boolean = true) {
        if (countTimeCost) {
            console.time('launch');
        }        
        const refreshPrjConfig = await this.initOpeParam(context);
        MainOutput.report('finish initialise opeParam', ReportType.Info);
        prjManage.refreshPrjFolder(refreshPrjConfig);
        
        const hdlFiles = await this.getPrjHardwareFiles();
        MainOutput.report(`finish collect ${hdlFiles.length} hdl files`, ReportType.Info);
        
        await hdlParam.initialize(hdlFiles, progress);
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

        // basic path
        const userPath = hdlPath.join(opeParam.workspacePath, 'user');
        const softwarePath = hdlPath.join(userPath, 'Software');
        const hardwarePath = hdlPath.join(userPath, 'Hardware');

        const nextmode = this.getNextMode(rawPrjInfo);        
        const currmode = this.getCurrentMode(softwarePath, hardwarePath);
        
        if (currmode === nextmode) {
            const hardware = opeParam.prjInfo.arch.hardware;
            const software = opeParam.prjInfo.arch.software;
            
            hdlDir.mkdir(hardware.src);
            hdlDir.mkdir(hardware.sim);
            hdlDir.mkdir(hardware.data);
            if (currmode === 'LS') {
                hdlDir.mkdir(software.src);
                hdlDir.mkdir(software.data);
            }
        } else if (currmode === "PL" && nextmode === "LS") {
            hdlDir.mkdir(hardwarePath);

            for (const path of fs.readdirSync(userPath)) {
                const filePath = hdlPath.join(userPath, path);
                if (filePath !== 'Hardware') {
                    hdlDir.mvdir(filePath, hardwarePath, true);
                }
            }

            const softwareDataPath = hdlPath.join(softwarePath, 'data');
            const softwareSrcPath = hdlPath.join(softwarePath, 'src');

            hdlDir.mkdir(softwareDataPath);
            hdlDir.mkdir(softwareSrcPath);
        }
        else if (currmode === "LS" && nextmode === "PL") {
            const needNotice = vscode.workspace.getConfiguration().get('digital-ide.prj.file.structure.notice', true);
            if (needNotice) {
                const res = await vscode.window.showWarningMessage(
                    "Software will be deleted.",
                    { modal: true },
                    { title: 'Yes', value: true },
                    { title: 'No', value: false }
                );
                if (res?.value) {
                    hdlDir.rmdir(softwarePath);
                }
            } else {
                hdlDir.rmdir(softwarePath);
            }

            if (fs.existsSync(hardwarePath)) {
                for (const path of fs.readdirSync(hardwarePath)) {
                    const filePath = hdlPath.join(hardwarePath, path);
                    hdlDir.mvdir(filePath, userPath, true);
                }
                hdlDir.rmdir(hardwarePath);
            }

            const userSrcPath = hdlPath.join(userPath, 'src');
            const userSimPath = hdlPath.join(userPath, 'sim');
            const userDataPath = hdlPath.join(userPath, 'data');

            hdlDir.mkdir(userSrcPath);
            hdlDir.mkdir(userSimPath);
            hdlDir.mkdir(userDataPath);
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