import * as chokidar from 'chokidar';
import * as vscode from 'vscode';

import { refreshArchTree } from '../function/treeView';
import { AbsPath, MainOutput, opeParam, ReportType } from '../global';
import { hdlFile, hdlPath } from '../hdlFs';
import { hdlParam, HdlSymbol } from '../hdlParser';
import type { HdlMonitor } from './index';
import { HdlLangID } from '../global/enum';
import { vlogLinterManager, vhdlLinterManager, svlogLinterManager } from '../function/lsp/linter';
import { BaseAction, Event } from './event';
import { hdlIgnore } from '../manager/ignore';


export class HdlAction extends BaseAction {
    selectFSWatcher(m: HdlMonitor): chokidar.FSWatcher | undefined {
        return m.hdlMonitor;
    }

    /**
     * @description 用户新建了 hdl 文件
     * @param path 
     * @param m 
     * @returns 
     */
    async add(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction add', path);

        path = hdlPath.toSlash(path);

        // 如果不是 src 或者 sim 下的直接不管
        if (!this.isvalid(path)) {
            return;
        }

        this.updateLinter(path);

        // check if it has been created
        if (hdlParam.hasHdlFile(path)) {
            MainOutput.report('<HdlAction Add Event> HdlFile ' + path + ' has been created', {
                level: ReportType.Warn
            });
            return;
        }

        // create corresponding moduleFile
        await hdlParam.addHdlFile(path);

        refreshArchTree();
    }

    /**
     * @description 用户删除了 hdl 文件
     * @param path 
     * @param m 
     */
    async unlink(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction unlink', path);

        // operation to process unlink of hdl files can be deleted in <processLibFiles>
        path = hdlPath.toSlash(path);

        // 如果不是 src 或者 sim 下的直接不管
        if (!this.isvalid(path)) {
            return;
        }

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

    /**
     * @description 用户删除了文件夹（文件夹下的所有文件会自动触发 unlink 事件，不需要额外处理）
     * @param path 
     * @param m 
     */
    async unlinkDir(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction unlinkDir', path);   
    }

    /**
     * @description 用户增加了文件夹（文件夹下的所有文件会自动触发 add 事件，不需要额外处理）
     * @param path 
     * @param m 
     */
    async addDir(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction addDir', path);
    }

    /**
     * @description 用户修改了 hdl 文件
     * @param path 
     * @param m 
     */
    async change(path: string, m: HdlMonitor): Promise<void> {
        console.log('HdlAction change');
        path = hdlPath.toSlash(path);

        // 如果不是 src 或者 sim 下的直接不管
        if (!this.isvalid(path)) {
            return;
        }

        // 更新 hdl 文件
        const fast = await HdlSymbol.fast(path, 'common');
        if (fast) {
            hdlParam.updateFast(path, fast);
        }
        
        // 更新 linter
        await this.updateLinter(path);

        refreshArchTree();
    }

    public listenAddDir(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", {
                level: ReportType.Error
            });
            return;
        }
        fSWatcher.on(Event.AddDir, path => this.addDir(path, m));
    }


    public listenUnlinkDir(m: HdlMonitor) {
        const fSWatcher = this.selectFSWatcher(m);
        if (!fSWatcher) {
            MainOutput.report("FSWatcher hasn't been made!", {
                level: ReportType.Error
            });
            return;
        }
        fSWatcher.on(Event.UnlinkDir, path => this.unlinkDir(path, m));
    }

    /**
     * @description 是否为有效的工作区文件（必须在 src/sim 下且不被 ignore 包含）
     * @param path 
     */
    private isvalid(path: AbsPath): boolean {
        const prjInfo = opeParam.prjInfo;        
        if (path.startsWith(prjInfo.hardwareSrcPath) || path.startsWith(prjInfo.hardwareSimPath)) {
            if (!hdlIgnore.isignore(path) && hdlFile.isHDLFile(path)) {
                return true;
            }
        }

        return false;
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
}

