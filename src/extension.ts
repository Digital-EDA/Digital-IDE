import * as vscode from 'vscode';

import { opeParam } from './global';
import { prjManage } from './manager';
import { hdlPath } from './hdlFs';

function launch(context: vscode.ExtensionContext) {
    prjManage.initOpeParam(context);
    console.log(opeParam.prjInfo);
}

export function activate(context: vscode.ExtensionContext) {
    console.log('Digital-IDE 0.3.0 is launched');
    launch(context);
    
}

export function deactivate() {}