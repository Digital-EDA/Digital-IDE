/* eslint-disable @typescript-eslint/naming-convention */
const fs     = require('fs');
const vscode = require('vscode');
const fspath = require('path');
const vhd2vl = require("./vhd2vlog");
const formatter = require('../formatter');

/**
 * 
 * @param {string} path
 * @return {string} 
 */
function getFileName(path) {
    const fileName = fspath.basename(path);
    const names = fileName.split('.');
    names.pop();
    return names.join('.');
}

/**
 * 
 * @param {vscode.Uri} uri 
 * @return {Promise<void>}
 */
async function vhdl2vlog(uri) {
    const path = uri.fsPath.replace(/\\/g, '/');
    const fileName = getFileName(path);

    const Module = await vhd2vl();
    let content = fs.readFileSync(path, "utf-8");
    const status = Module.ccall('vhdlParse', '', ['string'], [content]);
    if (!status) {
        content = Module.ccall('getVlog', 'string', ['string'], []);
        // format
        content = await formatter.hdlFormatterProvider.vlogFormatter.format_from_code(content);
        
        const folderPath = fspath.dirname(path);
        const defaultSaveUri = new vscode.Uri('file', '', folderPath + '/' + fileName + '.v', '', '');
        console.log(defaultSaveUri);
        const vscodeDialogConfig = {
            title: 'save the verilog code',
            defaultUri: defaultSaveUri,
            verilog: ["v", "V", "vh", "vl"]
        };
        const fileInfos = await vscode.window.showSaveDialog(vscodeDialogConfig);

        if (fileInfos && fileInfos.path) {
            let savePath = fileInfos.path;
            console.log(savePath);

            if (savePath[0] === '/' && require('os').platform() === 'win32') {
                savePath = savePath.substring(1);
            }
            fs.writeFileSync(savePath, content, "utf-8");
            vscode.window.showInformationMessage("translate successfully");
            const options = {
                preview: false,
                viewColumn: vscode.ViewColumn.Two
            };
            vscode.window.showTextDocument(vscode.Uri.file(savePath), options);
        }
        
    } else {
        const error = Module.ccall('getErr', 'string', ['string'], []);
        vscode.window.showErrorMessage(error);
    }
}

module.exports = {
    vhdl2vlog
};
