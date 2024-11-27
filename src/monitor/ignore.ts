import * as vscode from 'vscode';
import { FSWatcher } from "chokidar";
import { HdlMonitor } from ".";
import { BaseAction } from "./event";
import { AbsPath, MainOutput, opeParam } from "../global";
import { hdlIgnore } from "../manager/ignore";
import { prjManage } from "../manager";
import { diffFiles } from "../hdlFs/file";
import { t } from '../i18n';
import { hdlParam } from '../hdlParser';
import { ToolChainType } from '../global/enum';
import { refreshArchTree } from '../function/treeView';

export class IgnoreAction extends BaseAction {
    selectFSWatcher(m: HdlMonitor): FSWatcher | undefined {
        return m.ignoreMonitor;
    }

    // 用户新建了 .dideignore
    async add(path: AbsPath, m: HdlMonitor): Promise<void> {
        const oldFiles = await prjManage.getPrjHardwareFiles();
        hdlIgnore.updatePatterns();
        await this.update(oldFiles);

        refreshArchTree();
    }

    // 用户删除了 .dideignore
    async unlink(path: AbsPath, m: HdlMonitor): Promise<void> {
        const oldFiles = await prjManage.getPrjHardwareFiles();
        hdlIgnore.updatePatterns();
        await this.update(oldFiles);

        refreshArchTree();
    }

    // 用户修改了 .dideignore 中的内容
    async change(path: AbsPath, m: HdlMonitor): Promise<void> {
        const oldFiles = await prjManage.getPrjHardwareFiles();
        hdlIgnore.updatePatterns();
        await this.update(oldFiles);

        refreshArchTree();
    }

    async update(oldFiles: AbsPath[]) {
        const newFiles = await prjManage.getPrjHardwareFiles();
        const { addFiles, delFiles } = diffFiles(newFiles, oldFiles);

        if (addFiles.length + delFiles.length === 0) {
            return;
        }
        
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