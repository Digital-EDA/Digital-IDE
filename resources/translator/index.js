/* eslint-disable @typescript-eslint/naming-convention */
const fs     = require('fs');
const vscode = require('vscode');
const vhd2vl = require("./vhd2vlog");

/**
 * 
 * @param {vscode.Uri} uri 
 * @return {Promise<void>}
 */
async function vhdl2vlog(uri) {
    const path = uri.fsPath.replace(/\\/g, '/');
    const Module = await vhd2vl();
    const content = fs.readFileSync(path, "utf-8");
    const status = Module.ccall('vhdlParse', '', ['string'], [content]);
    if (!status) {
        content = Module.ccall('getVlog', 'string', ['string'], []);
        vscode.window.showSaveDialog({ 
            filters: {
                verilog: ["v", "V", "vh", "vl"], // 文件类型过滤
            },
        }).then(fileInfos => {
            let path_full = fileInfos === null || fileInfos === void 0 ? void 0 : fileInfos.path;
            if (path_full !== undefined) {
                if (path_full[0] === '/' && require('os').platform() === 'win32') {
                    path_full = path_full.substring(1);
                }
                fs.writeFileSync(path_full, content, "utf-8");
                vscode.window.showInformationMessage("translate successfully");
                const options = {
                    preview: false,
                    viewColumn: vscode.ViewColumn.Two
                };
                vscode.window.showTextDocument(vscode.Uri.file(path_full), options);
            }
        });
    } else {
        const error = Module.ccall('getErr', 'string', ['string'], []);
        vscode.window.showErrorMessage(error);
    }
}

module.exports = {
    vhdl2vlog
};
