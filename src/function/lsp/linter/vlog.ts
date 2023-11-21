import * as vscode from 'vscode';
import { BaseManager } from './base';

class VlogLinterManager implements BaseManager {
    constructor() {
        const vlogLspConfig = vscode.workspace.getConfiguration('digital-ide.lsp.verilog.linter');
        const     
    }

    async initialise(): Promise<void> {
        
    }
}

const vlogLinterManager = new VlogLinterManager();

export {
    vlogLinterManager
};
