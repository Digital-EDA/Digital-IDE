import * as vscode from 'vscode';
import * as fs from 'fs';

import { AbsPath, opeParam } from '../global';
import { hdlDir, hdlFile, hdlPath } from '../hdlFs';
import { Library } from '../global/prjInfo';
import { Path } from '../../resources/hdlParser';

interface LibFileChange {
    add: AbsPath[],
    del: AbsPath[],
}

interface LibStatus {
    type?: string,
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

    public processLibFiles(library: Library): LibFileChange {
        // 在不设置state属性的时候默认为remote
        this.next.list = this.getLibFiles(library);
        if (!hdlFile.isHasAttr(library, 'state')) {
            this.next.type = 'remote';
        } else {
            if (library.state !== 'remote' && library.state !== 'local') {
                return {
                    'add' : [],
                    'del' : [],
                };
            }
            this.next.type = library.state;
        }

        // 处于初始状态时的情况
        if (!this.curr.type) {
            if (!hdlFile.isDir(this.localLibPath)) {
                this.curr.type = 'local';
            } else {
                this.curr.type = 'remote';
            }
        }

        const state = `${this.curr.type}-${this.next.type}`;
        let add: AbsPath[] = [];
        let del: AbsPath[] = [];
        switch (state) {
            case 'remote-remote':
                add = diffElement(this.next.list, this.curr.list);
                del = diffElement(this.curr.list, this.next.list);
            break;
            case 'remote-local':
                // 删除的内容全是remote的，将curr的交出去即可
                del = this.curr.list;
                
                // 将新增的全部复制到本地，交给monitor进行处理
                this.remote2Local(this.next.list, (src, dist) => {
                    hdlFile.copyFile(src, dist);
                });
            break;   
            case 'local-remote':
                // 本地的lib全部删除，交给monitor进行处理
                const fn = async () => {
                    if (fs.existsSync(this.localLibPath)) {
                        const needNotice = vscode.workspace.getConfiguration('prj.file.structure.notice');
                        if (needNotice) {
                            let select = await vscode.window.showWarningMessage("local lib will be removed.", 'Yes', 'Cancel');
                            if (select === "Yes") {
                                hdlDir.rmdir(this.localLibPath);
                            }
                        } else {
                            hdlDir.rmdir(this.localLibPath);
                        }
                    }
                };
                fn();

                // 增加的内容全是remote的，将next的交出去即可
                add = this.next.list;
            break;
            case 'local-local':
                // 只管理library里面的内容，如果自己再localPath里加减代码，则不去管理
                add = diffElement(this.next.list, this.curr.list);
                del = diffElement(this.curr.list, this.next.list);

                this.remote2Local(add, (src, dist) => {
                    hdlFile.copyFile(src, dist);
                });

                this.remote2Local(del, (src, dist) => {
                    hdlFile.removeFile(dist);
                });
                add = []; del = [];
            break;
            default: break;
        }

        return { add, del };
    }


    getLibFiles(library: Library) {
        const libFileList: AbsPath[] = [];
        const prjInfo = opeParam.prjInfo;

        // collect common libs
        prjInfo.getLibraryCommonPaths().forEach(absPath => libFileList.push(...hdlFile.getHDLFiles(absPath)));

        // collect custom libs
        prjInfo.getLibraryCustomPaths().forEach(absPath => libFileList.push(...hdlFile.getHDLFiles(absPath)));

        // Remove duplicate HDL files
        return removeDuplicates(libFileList);
    }

    remote2Local(remotes: Path[], callback: (src: AbsPath, dist: AbsPath) => void) {
        for (const src of remotes) {
            let dist;
            if (src.includes(this.customerPath)) {
                dist = src.replace(this.customerPath, this.localLibPath);
            } else {
                dist = src.replace(this.sourceLibPath, this.localLibPath);
            }
            callback(src, dist);
        }
    }
};

const libManage = new LibManage();

export {
    libManage,
    LibManage
};