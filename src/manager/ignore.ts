import * as vscode from 'vscode';
import { AbsPath } from '../global';


class HdlIgnore {
    constructor() {

    }

    public getIgnoreFiles(): AbsPath[] {
        return [];
    }
}


const hdlIgnore = new HdlIgnore();

export {
    hdlIgnore
};