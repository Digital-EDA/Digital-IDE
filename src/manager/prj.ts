/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';

import { AbsPath, opeParam } from '../global';
import { PathSet } from '../global/util';
import { RawPrjInfo } from '../global/prjInfo';
import { hdlFile, hdlPath } from '../hdlFs';
import { libManage } from './lib';

class PrjManage {
    // generate property template and write it to .vscode/property.json
    public async generatePropertyJson() {
        if (fs.existsSync(opeParam.propertyJsonPath)) {
            vscode.window.showWarningMessage('property file already exists !!!');
            return;
        }
        const template = hdlFile.readJSON(opeParam.propertyInitPath);
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
    public initOpeParam(context: vscode.ExtensionContext) {
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
        }
    }

    public getIgnoreFiles(): AbsPath[] {
        return [];
    }

    public getPrjHardwareFiles(): AbsPath[] {
        const searchPathSet = new PathSet();
        const prjInfo = opeParam.prjInfo;
        const hardwareInfo = prjInfo.arch.hardware;
        
        // handle library first
        libManage.processLibFiles(prjInfo.library);

        // add possible folder to search
        searchPathSet.checkAdd(hardwareInfo.src);
        searchPathSet.checkAdd(hardwareInfo.sim);
        searchPathSet.checkAdd(prjInfo.getLibraryCommonPaths());
        searchPathSet.checkAdd(prjInfo.getLibraryCustomPaths());

        // TODO : make something like .gitignore
        const ignores = this.getIgnoreFiles();

        // do search
        const searchPaths = searchPathSet.files;
        return hdlFile.getHDLFiles(searchPaths, ignores);
    }

    public initialise() {
        
    }
}

const prjManage = new PrjManage();

export {
    prjManage,
    PrjManage
};