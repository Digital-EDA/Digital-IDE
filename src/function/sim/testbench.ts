import * as vscode from 'vscode';

import { MainOutput, opeParam } from '../../global';
import { hdlPath, hdlFile} from '../../hdlFs';
import { HdlModule, hdlParam } from '../../hdlParser/core';
import { instanceByLangID, getSelectItem } from './instance';

function overwrite() {
    const options = {
        preview: false,
        viewColumn: vscode.ViewColumn.Active
    };
    const tbSrcPath = hdlPath.join(opeParam.extensionPath, 'lib', 'testbench.v');
    const uri = vscode.Uri.file(tbSrcPath);
    vscode.window.showTextDocument(uri, options);
}

function generateTestbenchFile(module: HdlModule) {
    const tbSrcPath = hdlPath.join(opeParam.extensionPath, 'lib', 'testbench.v');
    const tbDisPath = hdlPath.join(opeParam.prjInfo.arch.hardware.sim, 'testbench.v');

    if (!hdlFile.isFile(tbDisPath)) {
        var temp = hdlFile.readFile(tbSrcPath);
    } else {
        var temp = hdlFile.readFile(tbDisPath);
    }

    if (!temp) {
        return null;
    }

    let content = '';
    const lines = temp.split('\n');
    const len = lines.length;
    for (let index = 0; index < len; index++) {
        const line = lines[index];
        content += line + '\n';
        if (line.indexOf("//Instance ") !== -1) {
            content += instanceByLangID(module) + '\n';
        }
    }
    try {
        hdlFile.writeFile(tbDisPath, content);
        MainOutput.report("Generate testbench to " + tbDisPath);
    } catch (err) {
        vscode.window.showErrorMessage("Generate testbench failed:" + err);
    }
}

async function testbench() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('please select a editor!');
        return;
    }
    const uri = editor.document.uri;
    const option = {
        placeHolder: 'Select a Module to generate testbench'
    };
    const path = hdlPath.toSlash(uri.fsPath);
    
    if (!hdlFile.isHDLFile(path)) {
        return;
    }
    const currentHdlFile = hdlParam.getHdlFile(path);
    if (!currentHdlFile) {
        vscode.window.showErrorMessage('There is no hdlFile respect to ' + path);
        return;
    }
    const currentHdlModules = currentHdlFile.getAllHdlModules();
    const items = getSelectItem(currentHdlModules);
    const select = await vscode.window.showQuickPick(items, option);
    if (select) {
        generateTestbenchFile(items[0].module);
    }
}


export {
    testbench
};