/* eslint-disable @typescript-eslint/naming-convention */
import assert = require('assert');
import * as chokidar from 'chokidar';
import * as vscode from 'vscode';
import { refreshArchTree } from '../function/treeView';

import { AbsPath, MainOutput, opeParam, RelPath, ReportType } from '../global';
import { isSameSet } from '../global/util';
import { hdlFile, hdlPath } from '../hdlFs';
import { hdlParam, HdlSymbol } from '../hdlParser';
import { prjManage } from '../manager';
import { libManage } from '../manager/lib';

import type { HdlMonitor } from './index';

enum Event {
    Add = 'add',                 // emit when add file
    AddDir = 'addDir',           // emit when add folder
    Unlink = 'unlink',           // emit when delete file
    UnlinkDir = 'unlinkDir',     // emit when delete folder
    Change = 'change',           // emit when file changed
    All = 'all',                 // all the change above
    Ready = 'ready',
    Raw = 'raw',
    Error = 'error'
};


abstract class BaseAction {
    public listenChange(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", ReportType.Error);
            return;
        }
        fSWatcher.on(Event.Change, path => this.change(path, m));
    }

    public listenAdd(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", ReportType.Error);
            return;
        }
        fSWatcher.on(Event.Add, path => this.add(path, m));
    }

    public listenUnlink(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", ReportType.Error);
            return;
        }
        fSWatcher.on(Event.Unlink, path => this.unlink(path, m));
    }

    public listenUnlinkDir(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", ReportType.Error);
            return;
        }
        fSWatcher.on(Event.UnlinkDir, path => this.unlinkDir(path, m));
    }

    // public listenAddDir(m: HdlMonitor) {
    //     const fSWatcher = this.selectFSWatcher(m);
    //     if (!fSWatcher) {
    //         MainOutput.report("FSWatcher hasn't been made!", ReportType.Error);
    //         return;
    //     }
    //     fSWatcher.on(Event.UnlinkDir, path => this.unlinkDir(path, m));
    // }

    abstract selectFSWatcher(m: HdlMonitor): chokidar.FSWatcher | undefined;
    abstract change(path: AbsPath, m: HdlMonitor): Promise<void>;
    abstract add(path: AbsPath, m: HdlMonitor): Promise<void>;
    // abstract addDir(path: AbsPath, m: HdlMonitor): Promise<void>;
    abstract unlink(path: AbsPath, m: HdlMonitor): Promise<void>;
    abstract unlinkDir(path: AbsPath, m: HdlMonitor): Promise<void>;
}

class HdlAction extends BaseAction {
    selectFSWatcher(m: HdlMonitor): chokidar.FSWatcher | undefined {
        return m.hdlMonitor;
    }

    async add(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction add');

        path = hdlPath.toSlash(path);
        // create corresponding moduleFile
        hdlParam.initHdlFiles([path]);
    
        const moduleFile = hdlParam.getHdlFile(path);
        if (!moduleFile) {
            console.log('error happen when create moduleFile', path);
        } else {
            moduleFile.makeInstance();
            for (const module of moduleFile.getAllHdlModules()) {
                module.solveUnhandleInstance();
            }
        }
        refreshArchTree();
    }

    async unlink(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction unlink', path);
        
        path = hdlPath.toSlash(path);
        hdlParam.deleteHdlFile(path);
        refreshArchTree();
    }

    async unlinkDir(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction unlinkDir', path);
        
    }

    async change(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction change');

        path = hdlPath.toSlash(path);
        const moduleFile = hdlParam.getHdlFile(path);
    
        if (!moduleFile) {
            return;
        }
    
        const fast = await HdlSymbol.fast(path);
        if (!fast) {
            vscode.window.showErrorMessage('error happen when parse ' + path + '\nFail to update');
            return;
        }
    
        // 1. update marco directly
        moduleFile.updateMacro(fast.macro);
        
        // 2. update modules one by one
        const uncheckedModuleNames = new Set<string>();
        for (const name of moduleFile.getAllModuleNames()) {
            uncheckedModuleNames.add(name);
        }
    
        for (const rawHdlModule of fast.content) {
            const moduleName = rawHdlModule.name;
            if (uncheckedModuleNames.has(moduleName)) {     
                // match the same module, check then
                const originalModule = moduleFile.getHdlModule(moduleName);
                uncheckedModuleNames.delete(moduleName);
                originalModule?.update(rawHdlModule);
            } else {                                    
                // no matched, create it
                const newModule = moduleFile.createHdlModule(rawHdlModule);
                newModule.makeNameToInstances();
                newModule.solveUnhandleInstance();
            }
        }
    
        // 3. delete module not visited yet
        for (const moduleName of uncheckedModuleNames) {
            moduleFile.deleteHdlModule(moduleName);
        }
        
        refreshArchTree();
    }
}


class PpyAction extends BaseAction {
    selectFSWatcher(m: HdlMonitor): chokidar.FSWatcher | undefined {
        return m.ppyMonitor;
    }

    async add(path: string, m: HdlMonitor): Promise<void> {
        console.log('PpyAction add');
        assert.equal(hdlPath.toSlash(path), opeParam.propertyJsonPath);
        this.updateProperty(m);
    }

    async unlink(path: string, m: HdlMonitor): Promise<void> {
        console.log('PpyAction unlink');
        assert.equal(hdlPath.toSlash(path), opeParam.propertyJsonPath);
        this.updateProperty(m);
    }
    
    async unlinkDir(path: string, m: HdlMonitor): Promise<void> {
        
    }

    async change(path: string, m: HdlMonitor): Promise<void> {
        console.log('PpyAction change');
        assert.equal(hdlPath.toSlash(path), opeParam.propertyJsonPath);
        this.updateProperty(m);
    }

    // get path set from opeParam that used to tell if need to remake HdlMonitor
    private getImportantPathSet(): Set<AbsPath | RelPath> {
        const pathSet = new Set<AbsPath | RelPath>();
        pathSet.add(opeParam.prjInfo.hardwareSimPath);
        pathSet.add(opeParam.prjInfo.hardwareSrcPath);
        for (const path of opeParam.prjInfo.getLibraryCommonPaths()) {
            pathSet.add(path);
        }
        for (const path of opeParam.prjInfo.getLibraryCustomPaths()) {
            pathSet.add(path);
        }        
        return pathSet;
    }

    public async updateProperty(m: HdlMonitor) {
        const originalPathSet = this.getImportantPathSet();
        const originalHdlFiles = prjManage.getPrjHardwareFiles();
        const originalLibState = opeParam.prjInfo.library.state;
        
        const rawPrjInfo = opeParam.getRawUserPrjInfo();
        opeParam.mergePrjInfo(rawPrjInfo);
        
        const currentPathSet = this.getImportantPathSet();
        const currentLibState = opeParam.prjInfo.library.state;
            
        if (isSameSet(originalPathSet, currentPathSet)) {
            // skip hdl remake
            if (originalLibState !== currentLibState) {
                const fileChange = libManage.processLibFiles(opeParam.prjInfo.library);
                MainOutput.report(`libManage finish process, add ${fileChange.add.length} files, del ${fileChange.del.length} files`, ReportType.Info);
            }
            
        } else {
            // update hdl monitor
            const options: vscode.ProgressOptions = { location: vscode.ProgressLocation.Notification, title: 'modify the project' };
            vscode.window.withProgress(options, async () => await this.refreshHdlMonitor(m, originalHdlFiles));
        }
    }

    public async refreshHdlMonitor(m: HdlMonitor, originalHdlFiles: AbsPath[]) {           
        m.remakeHdlMonitor();
        
        // update pl
        console.log('current lib state', opeParam.prjInfo.library.state);
        const currentHdlFiles = prjManage.getPrjHardwareFiles();
        await this.updatePL(originalHdlFiles, currentHdlFiles);

        refreshArchTree();    
    }

    public async updatePL(oldFiles: AbsPath[], newFiles: AbsPath[]) {
        if (prjManage.pl) {
            const uncheckHdlFileSet = new Set<AbsPath>(oldFiles);
            const addFiles: AbsPath[] = [];
            const delFiles: AbsPath[] = [];
            
            for (const path of newFiles) {
                if (!uncheckHdlFileSet.has(path)) {
                    await hdlParam.addHdlPath(path);
                    addFiles.push(path);
                } else {
                    uncheckHdlFileSet.delete(path);
                }
            }
            const vivadoAddPromise = prjManage.pl.addFiles(addFiles);
    
            for (const path of uncheckHdlFileSet) {
                hdlParam.deleteHdlFile(path);
                delFiles.push(path);
            }
            const vivadoDelPromise = prjManage.pl.delFiles(delFiles);
            
            await vivadoAddPromise;
            await vivadoDelPromise;
        } else {
            MainOutput.report('PL is not registered', ReportType.Warn);
        }
    }
}

const hdlAction = new HdlAction();
const ppyAction = new PpyAction();

export {
    hdlAction,
    ppyAction
};