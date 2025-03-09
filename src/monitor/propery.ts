import assert = require('assert');
import * as chokidar from 'chokidar';
import * as vscode from 'vscode';

import { refreshArchTree } from '../function/treeView';
import { AbsPath, MainOutput, opeParam, PrjInfoDefaults, RelPath, ReportType } from '../global';
import { isSameSet } from '../global/util';
import { hdlPath } from '../hdlFs';
import { hdlParam } from '../hdlParser';
import { prjManage } from '../manager';
import { libManage } from '../manager/lib';
import type { HdlMonitor } from './index';
import { ToolChainType } from '../global/enum';
import { t } from '../i18n';
import { BaseAction, Event } from './event';
import { diffFiles } from '../hdlFs/file';

export class PpyAction extends BaseAction {
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
                MainOutput.report(`libManage finish process, add ${fileChange.add.length} files, del ${fileChange.del.length} files`, {
                    level: ReportType.Info
                });
            }
        } else {
            // update hdl monitor
            await this.refreshHdlMonitor(m, originalHdlFiles);
        }

        refreshArchTree();
    }

    public async refreshHdlMonitor(m: HdlMonitor, originalHdlFiles: AbsPath[]) {
        // 获取布局更新后的新的文件     
        const newFiles = await prjManage.getPrjHardwareFiles();
        const { addFiles, delFiles } = diffFiles(newFiles, originalHdlFiles);
        
        await vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: t('info.monitor.ppy.impl-change-to-project', opeParam.prjInfo.toolChain)
        }, async () => {
            await hdlParam.updateByMonitor(addFiles, delFiles);

            switch (opeParam.prjInfo.toolChain) {
                case ToolChainType.Xilinx:
                    await prjManage.pl?.updateByMonitor(addFiles, delFiles);
                    break;
            
                default:
                    break;
            }
        });
    }
}