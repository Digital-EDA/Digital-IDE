import * as vscode from 'vscode';

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


export {
    insertTextToUri
};