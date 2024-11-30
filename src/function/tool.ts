/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';

import { opeParam } from '../global';
import { hdlFile, hdlPath } from '../hdlFs';
import { ModuleDataItem } from './treeView/tree';
import { hdlParam } from '../hdlParser';
import { t } from '../i18n';

async function insertTextToUri(uri: vscode.Uri, text: string, position?: vscode.Position) {
    if (!position) {
        position = new vscode.Position(0, 0);
    }
    const editor = vscode.window.activeTextEditor;
    if (editor) {
        const edit = new vscode.WorkspaceEdit();
        edit.insert(uri, position, text);
        vscode.workspace.applyEdit(edit);
    }
}

const PPY_REPLACE: Record<string, string> = {
    TOOL_CHAIN: 'toolChain',
    PRJ_NAME: 'prjName',
    ARCH: 'arch',
    SOC: 'soc',
    SOC_MODE: 'soc',
    enableShowlog: 'enableShowLog',
    Device: 'device',
    HardwareLIB: 'library'
};

const HARDWARD_LIB_STATE_REPLACE: Record<string, string> = {
    virtual: 'remote',
    real: 'local'
};

const PPY_ARCH_REPLACE: Record<string, string> = {
    PRJ_Path: 'prjPath',
    Hardware: 'hardware',
    Software: 'software'
};

const PPY_LIB_REPLACE: Record<string, string> = {
    Hardware: 'hardware'
};

async function transformOldPpy() {
    const propertyJsonPath = opeParam.propertyJsonPath;
    if (fs.existsSync(propertyJsonPath)) {
        const oldPpyContent = hdlFile.readJSON(propertyJsonPath) as Record<any, any>;
        
        if (oldPpyContent.ARCH) {      
            for (const oldName of Object.keys(PPY_ARCH_REPLACE)) {
                const newName = PPY_ARCH_REPLACE[oldName];
                oldPpyContent.ARCH[newName] = oldPpyContent.ARCH[oldName];
                delete oldPpyContent.ARCH[oldName];
            }
        }

        if (oldPpyContent.library) {
            for (const oldName of Object.keys(PPY_LIB_REPLACE)) {
                const newName = PPY_LIB_REPLACE[oldName];
                if (typeof newName !== 'string') {
                    continue;
                }
                oldPpyContent.library[newName] = oldPpyContent.library[oldName];
                delete oldPpyContent.library[oldName];
            }
        }

        for (const oldName of Object.keys(PPY_REPLACE)) {
            const newName = PPY_REPLACE[oldName];
            oldPpyContent[newName] = oldPpyContent[oldName];
            delete oldPpyContent[oldName];
        }

        // 老版本的是 SOC_MODE.soc，新版本需要变成 soc.core
        if (oldPpyContent.soc && oldPpyContent.soc.soc !== undefined) {
            oldPpyContent.soc.core = oldPpyContent.soc.soc;
            delete oldPpyContent.soc['soc'];
        }

        // 老版本的是 SOC_MODE.bd_file，新版本需要变成 soc.bd
        if (oldPpyContent.soc && oldPpyContent.soc.bd_file !== undefined) {
            oldPpyContent.soc.bd = oldPpyContent.soc.bd_file;
            delete oldPpyContent.soc['bd_file'];
        }

        // 老版本的是 HardwareLIB，新版本需要变成 library
        if (oldPpyContent.library) {
            // 老版本的是 "state": "virtual"
            if (oldPpyContent.library.state) {
                const newState = HARDWARD_LIB_STATE_REPLACE[oldPpyContent.library.state];
                if (typeof newState === 'string') {
                    oldPpyContent.library.state = newState;
                } else {
                    vscode.window.showWarningMessage(t('warn.command.transform-old-ppy.unknown-hardwarelib-state') + oldPpyContent.library.state);
                }
            }
            // 老版本的是 HardwareLIB.common ， 新版本是 library.hardware.common
            if (oldPpyContent.library.common) {
                oldPpyContent.library.hardware = {
                    common: oldPpyContent.library.common
                };
                delete oldPpyContent.library['common'];
            }
        }

        hdlFile.writeJSON(propertyJsonPath, oldPpyContent);

    } else {
        vscode.window.showErrorMessage('You have\'t create property.json!');
    }
}

async function askUserToSaveFilelist(filelist: string[]) {

    const topModulePath = filelist[0];
    const defaultSaveName = fspath.basename(topModulePath, fspath.extname(topModulePath));
    const defaultSavePath = hdlPath.join(opeParam.workspacePath, defaultSaveName + '.f');

    const uri = await vscode.window.showSaveDialog({
        filters: {
            'All Files': ['*']
        },
        saveLabel: 'save',
        defaultUri: vscode.Uri.file(defaultSavePath)
    });

    if (uri === undefined) {
        return;
    }
    const filePath = uri.fsPath;
    const fileContent = filelist.join('\n');

    try {
        fs.writeFileSync(filePath, fileContent);

    } catch (error) {
        vscode.window.showErrorMessage(t('error.filelist.save-file') + ': ' + error);
    }
}

/**
 * @description 导出当前 module 的 filelist
 * @param view treeview 中的模块对象
 */
function exportFilelist(view: ModuleDataItem) {
    const fileset = new Set<string>();
    if (view.path !== undefined) {
        const deps = hdlParam.getAllDependences(view.path, view.name);
        if (deps) {
            deps.others.forEach(path => fileset.add(path));
            deps.include.forEach(path => fileset.add(path));
            const filelist = [view.path];
            filelist.push(...fileset);
            askUserToSaveFilelist(filelist);
        } else {
            vscode.window.showErrorMessage('fail to get deps of view ' + view.name);
        }
    } else {
        vscode.window.showErrorMessage('cannot find path for current module');
    }

}

export {
    insertTextToUri,
    transformOldPpy,
    exportFilelist
};