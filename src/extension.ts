import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';

import { opeParam, MainOutput, AbsPath } from './global';
import { hdlParam } from './hdlParser';
import * as manager from './manager';
import * as func from './function';
import { hdlMonitor } from './monitor';
import { hdlPath } from './hdlFs';
import { vlogFast } from '../resources/hdlParser';

async function registerCommand(context: vscode.ExtensionContext) {
    manager.registerManagerCommands(context);

    func.registerFunctionCommands(context);
    func.registerLsp(context);
    func.registerToolCommands(context);
    func.registerFSM(context);
    func.registerNetlist(context);
}

function* walk(path: AbsPath, ext: string): Generator {
    if (fs.lstatSync(path).isFile()) {
        if (path.endsWith(ext)) {
            yield path;
        }
    } else {
        for (const file of fs.readdirSync(path)) {
            const stat = fs.lstatSync(path);
            const filePath = fspath.join(path, file);
            if (stat.isDirectory()) {
                for (const targetPath of walk(filePath, ext)) {
                    yield targetPath;
                }
            } else if (stat.isFile()) {
                if (filePath.endsWith(ext)) {
                    yield filePath;
                }
            }
        }
    }
}


async function test(context: vscode.ExtensionContext) {
    if (vscode.workspace.workspaceFolders !== undefined &&
        vscode.workspace.workspaceFolders.length !== 0) {
        const wsPath = hdlPath.toSlash(vscode.workspace.workspaceFolders[0].uri.fsPath);
        for (const file of walk(wsPath, '.v')) {
            if (typeof file === 'string') {
                await vlogFast(file);
            }
        }
    }
}

async function launch(context: vscode.ExtensionContext) {
    await manager.prjManage.initialise(context);
    await registerCommand(context);
    hdlMonitor.start();
    // await vlogFast("e:/Project/Digial-IDE/TestWs/simulate/user/sim/tb_file/scc018ug_hd_rvt.v");
        
    MainOutput.report('Digital-IDE has launched, Version: 0.3.0');
    MainOutput.report('OS: ' + opeParam.os);

    console.log(hdlParam);
    
}

export function activate(context: vscode.ExtensionContext) {
    launch(context);
}

export function deactivate() {}