import * as vscode from 'vscode';

import { AbsPath, opeParam } from '../global';
import { hdlFile, hdlPath } from '../hdlFs';

class LibManage {
    constructor() {

    }

    public get srcPath(): AbsPath {
        return opeParam.prjInfo.arch.hardware.src;
    }

    public get simPath(): AbsPath {
        return opeParam.prjInfo.arch.hardware.sim;
    }

    public get prjPath(): AbsPath {
        return opeParam.prjInfo.arch.prjPath;
    }

    public get localLibPath(): AbsPath {
        return hdlPath.join(this.srcPath, 'lib');
    }

    public get sourceLibPath(): AbsPath {
        return hdlPath.join(opeParam.extensionPath, 'lib');
    }

    public get libCustomPath(): AbsPath {
        return opeParam.prjInfo.libCustomPath;
    }

    public processLibFiles() {
        
    }

};