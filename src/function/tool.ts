/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';

import { opeParam } from '../global';
import { hdlFile, hdlPath } from '../hdlFs';
import { ModuleDataItem } from './treeView/tree';
import { hdlParam } from '../hdlParser';

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
    enableShowlog: 'enableShowLog',
    Device: 'device'
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
                oldPpyContent.library[newName] = oldPpyContent.library[oldName];
                delete oldPpyContent.library[oldName];
            }
        }

        for (const oldName of Object.keys(PPY_REPLACE)) {
            const newName = PPY_REPLACE[oldName];
            oldPpyContent[newName] = oldPpyContent[oldName];
            delete oldPpyContent[oldName];
        }

        hdlFile.writeJSON(propertyJsonPath, oldPpyContent);

    } else {
        vscode.window.showErrorMessage('You have\'t create property.json!');
    }
}

async function askUserToSaveFilelist(filelist: string[]) {
    const { t } = vscode.l10n;

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
    const filePath = uri.path;
    const fileContent = filelist.join('\n');

    try {
        fs.writeFileSync(filePath, fileContent);

    } catch (error) {
        vscode.window.showErrorMessage(t('fail.save-file') + ': ' + error);
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