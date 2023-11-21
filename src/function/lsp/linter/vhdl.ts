import * as vscode from 'vscode';
import { BaseManager } from './base';

class VhdlLinterManager implements BaseManager {
    constructor() {

    }

    async initialise(): Promise<void> {
        
    }
}

const vhdlLinterManager = new VhdlLinterManager();

export {
    vhdlLinterManager
};