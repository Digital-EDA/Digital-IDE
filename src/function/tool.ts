/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';

import { opeParam } from '../global';
import { hdlFile } from '../hdlFs';

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


export {
    insertTextToUri,
    transformOldPpy
};