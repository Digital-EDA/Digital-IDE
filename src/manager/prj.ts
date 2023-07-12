/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';

import { AbsPath, MainOutput, opeParam, ReportType } from '../global';
import { PathSet } from '../global/util';
import { RawPrjInfo } from '../global/prjInfo';
import { hdlDir, hdlFile, hdlPath } from '../hdlFs';
import { libManage } from './lib';
import { hdlParam } from '../hdlParser';
import { PlManage } from './PL';
import { PsManage } from './PS';
import { hdlIgnore } from './ignore';

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
    public async initOpeParam(context: vscode.ExtensionContext) {
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
                vscode.commands.executeCommand('digital-ide.property-json.generate');
            }
        }
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

    

    public async initialise(context: vscode.ExtensionContext, countTimeCost: boolean = true) {
        if (countTimeCost) {
            console.time('launch');
        }        
        await this.initOpeParam(context);
        MainOutput.report('finish initialise opeParam', ReportType.Info);
        
        const hdlFiles = await this.getPrjHardwareFiles();
        MainOutput.report(`finish collect ${hdlFiles.length} hdl files`, ReportType.Info);
        
        await hdlParam.initialize(hdlFiles);
        const unhandleNum = hdlParam.getUnhandleInstanceNumber();
        MainOutput.report(`finish analyse ${hdlFiles.length} hdl files, find ${unhandleNum} unsolved instances`, ReportType.Info);

        this.pl = new PlManage();
        this.ps = new PsManage();
        MainOutput.report('create pl and ps', ReportType.Info);

        
        if (countTimeCost) {
            console.timeLog('launch');
        }
    }



    public async refreshPrjFolder() {
        // TODO : finish this
        // 无工程配置文件则直接退出
        if (!opeParam.prjInfo) {
            return;
        }

        const prjInfo = opeParam.prjInfo;

        // 如果是用户配置文件结构，检查并生成相关文件夹
        if (prjInfo.arch) {
            hdlDir.mkdir(prjInfo.arch.prjPath);
            const hardware = prjInfo.arch.hardware;
            const software = prjInfo.arch.software;

            if (hardware) {
                hdlDir.mkdir(hardware.src);
                hdlDir.mkdir(hardware.sim);
                hdlDir.mkdir(hardware.data);
            }

            if (software) {
                hdlDir.mkdir(software.src);
                hdlDir.mkdir(software.data);
            }
            return;
        }

        // 先直接创建工程文件夹
        hdlDir.mkdir(`${opeParam.workspacePath}/prj`);

        // 初始化文件结构的路径
        const userPath = `${opeParam.workspacePath}/user`;
        const softwarePath = `${opeParam.workspacePath}/user/Software`;
        const hardwarePath = `${opeParam.workspacePath}/user/Hardware`;

        let nextmode = "PL";
        // 再对源文件结构进行创建
        if (prjInfo.soc.core !== 'none') {
            nextmode = "LS";
        }

        let currmode = "PL";
        if (fs.existsSync(softwarePath) || fs.existsSync(hardwarePath)) {
            currmode = "LS";
        }
        
        if (currmode === nextmode) {
            const hardware = opeParam.prjInfo.ARCH.Hardware;
            const software = opeParam.prjInfo.ARCH.Software;

            hdlDir.mkdir(hardware.src);
            hdlDir.mkdir(hardware.sim);
            hdlDir.mkdir(hardware.data);
            if (currmode === 'LS') {
                hdlDir.mkdir(software.src);
                hdlDir.mkdir(software.data);
            }
            return;
        }

        if (currmode === "PL" && nextmode === "LS") {
            hdlDir.mkdir(hardwarePath);
            hdlDir.readdir(userPath, true, (folder) => {
                if (folder !== "Hardware") {
                    hdlDir.mvdir(folder, hardwarePath);
                }
            });

            hdlDir.mkdir(`${softwarePath}/data`);
            hdlDir.mkdir(`${softwarePath}/src`);
        }
        else if (currmode === "LS" && nextmode === "PL") {
            const needNotice = vscode.workspace.getConfiguration().get('PRJ.file.structure.notice', true);
            if (needNotice) {
                let select = await vscode.window.showWarningMessage("Software will be deleted.", 'Yes', 'No');
                if (select === "Yes") {
                    hdlDir.rmdir(softwarePath);
                }
            } else {
                hdlDir.rmdir(softwarePath);
            }

            if (hdlFile.isExist(hardwarePath)) {
                hdlDir.readdir(hardwarePath, true, (folder) => {
                    hdlDir.mvdir(folder, userPath);
                })
                
                hdlDir.rmdir(hardwarePath);
            } 

            hdlDir.mkdir(`${userPath}/src`);
            hdlDir.mkdir(`${userPath}/sim`);
            hdlDir.mkdir(`${userPath}/data`);
        }
    }
}

const prjManage = new PrjManage();

export {
    prjManage,
    PrjManage
};