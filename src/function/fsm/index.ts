import * as vscode from 'vscode';

import { FsmViewer } from '../../../resources/fsm';

async function openFsmViewer(context: vscode.ExtensionContext, uri: vscode.Uri) {
    const viewer = new FsmViewer(context);
    viewer.open(uri);
}

export {
    openFsmViewer
};