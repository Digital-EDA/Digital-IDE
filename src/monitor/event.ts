/* eslint-disable @typescript-eslint/naming-convention */
import assert = require('assert');
import * as chokidar from 'chokidar';
import * as vscode from 'vscode';
import * as fs from 'fs';

import { refreshArchTree } from '../function/treeView';
import { AbsPath, MainOutput, opeParam, PrjInfoDefaults, RelPath, ReportType } from '../global';
import { isSameSet } from '../global/util';
import { hdlFile, hdlPath } from '../hdlFs';
import { hdlParam, HdlSymbol } from '../hdlParser';
import { prjManage } from '../manager';
import { libManage } from '../manager/lib';
import type { HdlMonitor } from './index';
import { HdlLangID, ToolChainType } from '../global/enum';
import { vlogLinterManager, vhdlLinterManager, svlogLinterManager } from '../function/lsp/linter';
import { t } from '../i18n';

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
    abstract selectFSWatcher(m: HdlMonitor): chokidar.FSWatcher | undefined;
    abstract change(path: AbsPath, m: HdlMonitor): Promise<void>;
    abstract add(path: AbsPath, m: HdlMonitor): Promise<void>;
    abstract unlink(path: AbsPath, m: HdlMonitor): Promise<void>;
}

class HdlAction extends BaseAction {
    selectFSWatcher(m: HdlMonitor): chokidar.FSWatcher | undefined {
        return m.hdlMonitor;
    }

    async add(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction add', path);

        path = hdlPath.toSlash(path);
        this.updateLinter(path);

        // check if it has been created
        if (hdlParam.hasHdlFile(path)) {
            MainOutput.report('<HdlAction Add Event> HdlFile ' + path + ' has been created', ReportType.Warn);
            return;
        }

        // create corresponding moduleFile
        await hdlParam.addHdlFile(path);

        refreshArchTree();
    }

    async unlink(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction unlink', path);

        // operation to process unlink of hdl files can be deleted in <processLibFiles>
        path = hdlPath.toSlash(path);
        hdlParam.deleteHdlFile(path);

        refreshArchTree();

        const uri = vscode.Uri.file(path);
        const langID = hdlFile.getLanguageId(path);
        if (langID === HdlLangID.Verilog) {
            vlogLinterManager.remove(uri);
        } else if (langID === HdlLangID.Vhdl) {
            vhdlLinterManager.remove(uri);
        } else if (langID === HdlLangID.SystemVerilog) {
            svlogLinterManager.remove(uri);
        }
    }

    async unlinkDir(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction unlinkDir', path);
        
    }

    async addDir(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction addDir', path);
        
    }

    async change(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction change');
        path = hdlPath.toSlash(path);

        await this.updateHdlParam(path);
        await this.updateLinter(path);

        refreshArchTree();
    }

    // 下一个版本丢弃，完全由后端承担这部分功能
    async updateLinter(path: string) {
        const uri = vscode.Uri.file(path);
        const document = await vscode.workspace.openTextDocument(uri);
        const langID = hdlFile.getLanguageId(path);

        if (langID === HdlLangID.Verilog) {
            vlogLinterManager.lint(document);
        } else if (langID === HdlLangID.Vhdl) {
            vhdlLinterManager.lint(document);
        } else if (langID === HdlLangID.SystemVerilog) {
            svlogLinterManager.lint(document);
        }
    }

    async updateHdlParam(path: string) {
        const moduleFile = hdlParam.getHdlFile(path);

        if (!moduleFile) {
            return;
        }
    
        const fast = await HdlSymbol.fast(path, 'common');
        console.log('update fast: ' + path);
        
        if (!fast) {
            // vscode.window.showErrorMessage('error happen when parse ' + path + '\nFail to update');
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
    }
}


class PpyAction extends BaseAction {
    selectFSWatcher(m: HdlMonitor): chokidar.FSWatcher | undefined {
        return m.ppyMonitor;
    }

    async add(path: string, m: HdlMonitor): Promise<void> {
        console.log('PpyAction add');
        assert.equal(hdlPath.toSlash(path), opeParam.propertyJsonPath);
        await this.updateProperty(Event.Add, m);
    }

    async unlink(path: string, m: HdlMonitor): Promise<void> {
        console.log('PpyAction unlink');
        assert.equal(hdlPath.toSlash(path), opeParam.propertyJsonPath);
        await this.updateProperty(Event.Unlink, m);
    }
    
    async change(path: string, m: HdlMonitor): Promise<void> {
        console.log('PpyAction change');
        assert.equal(hdlPath.toSlash(path), opeParam.propertyJsonPath);
        await this.updateProperty(Event.Change, m);
        console.log(hdlParam);   
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

    public async updateProperty(e: Event, m: HdlMonitor) {
        const originalPathSet = this.getImportantPathSet();
        const originalHdlFiles = await prjManage.getPrjHardwareFiles();
        const originalLibState = opeParam.prjInfo.library.state;
        
        const rawPrjInfo = opeParam.getRawUserPrjInfo();
        // when delete, make ws path to be main parse path
        if (e === Event.Unlink) {
            console.log('unlink ppy, PrjInfoDefaults.arch:', PrjInfoDefaults.arch);
            rawPrjInfo.arch = PrjInfoDefaults.arch;
        }

        opeParam.mergePrjInfo(rawPrjInfo);
        await prjManage.refreshPrjFolder();
        
        const currentPathSet = this.getImportantPathSet();
        const currentLibState = opeParam.prjInfo.library.state;
        
        if (isSameSet(originalPathSet, currentPathSet)) {
            // skip hdl remake
            if (originalLibState !== currentLibState) {
                const fileChange = await libManage.processLibFiles(opeParam.prjInfo.library);
                MainOutput.report(`libManage finish process, add ${fileChange.add.length} files, del ${fileChange.del.length} files`, ReportType.Info);
            }
            
        } else {
            // update hdl monitor
            await this.refreshHdlMonitor(m, originalHdlFiles);
        }

        refreshArchTree();
    }

    public diffNewOld(newFiles: AbsPath[], oldFiles: AbsPath[]) {
        const uncheckHdlFileSet = new Set<AbsPath>(oldFiles);
        const addFiles: AbsPath[] = [];
        const delFiles: AbsPath[] = [];
        
        for (const path of newFiles) {
            if (!uncheckHdlFileSet.has(path)) {
                addFiles.push(path);
            } else {
                uncheckHdlFileSet.delete(path);
            }
        }

        for (const path of uncheckHdlFileSet) {
            hdlParam.deleteHdlFile(path);
            delFiles.push(path);
        }
        return {
            addFiles, delFiles
        };
    }

    public async refreshHdlMonitor(m: HdlMonitor, originalHdlFiles: AbsPath[]) {           
        m.remakeHdlMonitor();
        const newFiles = await prjManage.getPrjHardwareFiles();
        const { addFiles, delFiles } = this.diffNewOld(newFiles, originalHdlFiles);

        const options: vscode.ProgressOptions = { location: vscode.ProgressLocation.Notification };
        options.title = t('info.monitor.update-hdlparam');
        await vscode.window.withProgress(options, async () => await this.updateHdlParam(addFiles, delFiles));

        if (opeParam.prjInfo.toolChain === ToolChainType.Xilinx) {
            options.title = t('info.monitor.update-pl');
            await vscode.window.withProgress(options, async () => await this.updatePL(addFiles, delFiles));
        }
    }

    public async updateHdlParam(addFiles: AbsPath[], delFiles: AbsPath[]) {
        for (const path of addFiles) {
            await hdlParam.addHdlFile(path);
        }
        for (const path of delFiles) {
            hdlParam.deleteHdlFile(path);
        }
    }

    public async updatePL(addFiles: AbsPath[], delFiles: AbsPath[]) {
        // current only support xilinx
        if (prjManage.pl) {
            await prjManage.pl.addFiles(addFiles);
            await prjManage.pl.delFiles(delFiles);
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