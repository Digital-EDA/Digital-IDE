import * as vscode from 'vscode';
import * as fs from 'fs';

import { AbsPath, opeParam } from '../global';
import { hdlDir, hdlFile, hdlPath } from '../hdlFs';
import { Library } from '../global/prjInfo';
import { Path } from '../../resources/hdlParser';
import { LibraryState } from '../global/enum';
import { PathSet } from '../global/util';
import { hdlIgnore } from './ignore';

interface LibFileChange {
    add: AbsPath[],
    del: AbsPath[],
}

interface LibStatus {
    state?: LibraryState,
    list: AbsPath[]
}


/**
 * a与b的差集
 * @param a 
 * @param b 
 * @returns 
 */
function diffElement<T>(a: T[], b: T[]): T[] {
    const bSet = new Set<T>(b);
    return a.filter(el => !bSet.has(el));
}


function removeDuplicates<T>(a: T[]): T[] {
    const aSet = new Set(a);
    return [...aSet];
}

class LibManage {
    curr: LibStatus;
    next: LibStatus;

    constructor() {
        this.curr = { list : [] };
        this.next = { list : [] };
    }

    public get customerPath(): AbsPath {
        return opeParam.prjInfo.libCustomPath;
    }

    public get srcPath(): AbsPath {
        return opeParam.prjInfo.hardwareSrcPath;
    }

    public get simPath(): AbsPath {
        return opeParam.prjInfo.hardwareSimPath;
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

    public processLibFiles(library: Library): LibFileChange {
        this.next.list = this.getLibFiles();
        if (library.state === LibraryState.Local) {
            this.next.state = LibraryState.Local;
        } else {
            this.next.state = LibraryState.Remote;
        }

        // current disk situation

        if (hdlFile.isDir(this.localLibPath)) {
            this.curr.state = LibraryState.Local;
        } else {
            this.curr.state = LibraryState.Remote;
        }
    
        const add: AbsPath[] = [];
        const del: AbsPath[] = [];
        const statePair = this.curr.state + '-' + this.next.state;
        
        switch (statePair) {
            case 'remote-remote':
                add.push(...diffElement(this.next.list, this.curr.list));
                del.push(...diffElement(this.curr.list, this.next.list));
            break;
            case 'remote-local':
                del.push(...this.curr.list);
                
                // copy file from remote to local
                const remotePathList = this.getLibFiles(LibraryState.Remote);
                this.remote2Local(remotePathList, (src, dist) => {                    
                    hdlFile.copyFile(src, dist);
                });
            break;   
            case 'local-remote':
                add.push(...this.next.list);

                // delete local files (async)
                this.deleteLocalFiles();

            break;
            case 'local-local':
                add.push(...diffElement(this.next.list, this.curr.list));
                del.push(...diffElement(this.curr.list, this.next.list));

                this.remote2Local(add, (src, dist) => {
                    hdlFile.copyFile(src, dist);
                });

                this.remote2Local(del, (src, dist) => {                    
                    hdlFile.removeFile(dist);
                });
            break;
            default: break;
        }

        return { add, del };
    }


    public getLibFiles(state?: LibraryState): AbsPath[] {
        const libPathSet = new PathSet();

        for (const path of opeParam.prjInfo.getLibraryCommonPaths(true, state)) {            
            libPathSet.checkAdd(path);
        }

        for (const path of opeParam.prjInfo.getLibraryCustomPaths()) {
            libPathSet.checkAdd(path);
        }

        const ignores = hdlIgnore.getIgnoreFiles();
        const libPathList = hdlFile.getHDLFiles(libPathSet.files, ignores);        
        return libPathList;
    }

    public async deleteLocalFiles() {
        if (fs.existsSync(this.localLibPath)) {
            const needNotice = vscode.workspace.getConfiguration('prj.file.structure.notice');
            if (needNotice) {
                let select = await vscode.window.showWarningMessage(`Local Lib (${this.localLibPath}) will be removed.`, 'Yes', 'Cancel');
                if (select === "Yes") {
                    hdlDir.rmdir(this.localLibPath);
                }
            } else {
                hdlDir.rmdir(this.localLibPath);
            }
        }
    }

    public remote2Local(remotes: Path[], callback: (src: AbsPath, dist: AbsPath) => void) {
        const localLibPath = this.localLibPath;
        const sourceLibPath = this.sourceLibPath;
        const customerPath = this.customerPath;
        const customerPathValid = hdlFile.isDir(customerPath);

        for (const srcPath of remotes) {
            const replacePath = ( customerPathValid && srcPath.includes(customerPath) ) ? customerPath : sourceLibPath;
            const distPath = srcPath.replace(replacePath, localLibPath);            
            callback(srcPath, distPath);
        }
    }
};

const libManage = new LibManage();

export {
    libManage,
    LibManage
};