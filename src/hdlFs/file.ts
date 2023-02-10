import * as fs from 'fs';
import * as fspath from 'path';

import { AbsPath, RelPath } from '../global';
import { HdlLangID } from '../global/enum';
import { verilogExts, vhdlExts, systemVerilogExts, hdlExts } from '../global/lang';
import * as hdlPath from './path';
import { HdlFileType } from '../hdlParser/common';
import { opeParam } from '../global';

/**
 * judge if the path represent a file
 * @param path 
 * @returns 
 */
function isFile(path: AbsPath): boolean {
    if (!fs.existsSync(path)) {
        return false;
    }
    const state: fs.Stats = fs.statSync(path);
    if (state.isDirectory()) {
        return false;
    }
    return true;
}

/**
 * judge if the path represent a Dir
 * @param path 
 * @returns
 */
function isDir(path: AbsPath): boolean {
    if (!fs.existsSync(path)) {
        return false;
    }

    const state: fs.Stats = fs.statSync(path);
    if (state.isDirectory()) {
        return true;
    }
    return false;
}

function isVerilogFile(path: AbsPath): boolean {
    if (!isFile(path)) {
        return false;
    }
    const ext = hdlPath.extname(path, false);
    return verilogExts.includes(ext);
}

function isVhdlFile(path: AbsPath): boolean {
    if (!isFile(path)) {
        return false;
    }
    const ext = hdlPath.extname(path, false);
    return vhdlExts.includes(ext);
}

function isSystemVerilogFile(path: AbsPath): boolean {
    if (!isFile(path)) {
        return false;
    }
    const ext = hdlPath.extname(path, false);
    return systemVerilogExts.includes(ext);
}

function isHDLFile(path: AbsPath): boolean {
    if (!isFile(path)) {
        return false;
    }
    const ext = hdlPath.extname(path, false);
    return hdlExts.includes(ext);
}


function getHDLFiles(path: AbsPath | AbsPath[] | Set<AbsPath>, ignores?: AbsPath[]) {
    return pickFileRecursive(path, ignores, 
        filePath => isHDLFile(filePath));
}


function pickFileRecursive(path: AbsPath | AbsPath[] | Set<AbsPath>, ignores?: AbsPath[], condition?: (filePath: string) => boolean | undefined | void): AbsPath[] {
    if ((path instanceof Array) ||
        (path instanceof Set)) {
        const hdlFiles: AbsPath[] = [];
        path.forEach(p => hdlFiles.push(...pickFileRecursive(p, ignores, condition)));
        return hdlFiles;
    }

    if (isDir(path)) {
        // return if ignore have path
        if (ignores?.includes(path)) {
            return [];
        }

        const hdlFiles = [];
        for (const file of fs.readdirSync(path)) {
            const filePath = hdlPath.join(path, file);
            if (isDir(filePath)) {
                const subHdlFiles = getHDLFiles(filePath, ignores);
                if (subHdlFiles.length > 0) {
                    hdlFiles.push(...subHdlFiles);
                }
            } else if (!condition || condition(filePath)) {
                hdlFiles.push(filePath);
            }
        }
        return hdlFiles;
    } else if (!condition || condition(path)) {
        return [path];
    } else {
        return [];
    }
}


/**
 * get language id of a file
 * @param path 
 * @returns 
 */
function getLanguageId(path: AbsPath | RelPath): HdlLangID {
    if (!isFile(path)) {
        return HdlLangID.Unknown;
    }
    const ext = hdlPath.extname(path, false);
    if (verilogExts.includes(ext)) {
        return HdlLangID.Verilog;
    } else if (vhdlExts.includes(ext)) {
        return HdlLangID.Vhdl;
    } else if (systemVerilogExts.includes(ext)) {
        return HdlLangID.SystemVerilog;
    } else {
        return HdlLangID.Unknown;
    }
}


function getHdlFileType(path: AbsPath) : HdlFileType {
    const uniformPath = hdlPath.toSlash(path);
    const arch = opeParam.prjInfo.arch;
    const srcPath: AbsPath = arch.hardware.src;
    const simPath: AbsPath = arch.hardware.sim;
    const wsPath: AbsPath = opeParam.workspacePath;
    if (uniformPath.includes(srcPath)) {
        return HdlFileType.Src;
    } else if (uniformPath.includes(simPath)) {
        return HdlFileType.Sim;
    } else if (uniformPath.includes(wsPath)) {
        return HdlFileType.LocalLib;
    } else {
        return HdlFileType.RemoteLib;
    }
}


function readFile(path: AbsPath): string | undefined {
    try {
        const content = fs.readFileSync(path, 'utf-8');
        return content;
    } catch (error) {
        console.log(error);
        return undefined;
    }
}

function writeFile(path: AbsPath, content: string): boolean {
    try {
        const parent = fspath.dirname(path);
        fs.mkdirSync(parent, {recursive: true});
        fs.writeFileSync(path, content);
        return true;
    } catch (error) {
        console.log(error);
        return false;
    }
}

function readJSON(path: AbsPath): object {
    try {
        const context = fs.readFileSync(path, 'utf-8');
        return JSON.parse(context);
    } catch (err) {
        console.log('fail to read JSON: ', err);
    }
    return {};
}

function writeJSON(path: AbsPath, obj: object): boolean {
    try {
        const jsonString = JSON.stringify(obj, null, '\t');
        return writeFile(path, jsonString);
    } catch (err) {
        console.log('fail to write to ' + path + ': ', err);
    }
    return false;
}

function removeFile(path: AbsPath): boolean {
    if (!isFile(path)) {
        return false;
    }

    try {
        fs.unlinkSync(path);
        return true;
    } catch (error) {
        console.log(error);
    }
    return false;
}

function moveFile(src: AbsPath, dest: AbsPath, cover: boolean = true): boolean {
    if (src === dest) {
        return false;
    }

    if (!isFile(src)) {
        return false;
    }

    if (!cover) {
        cover = true;
    }
    
    copyFile(src, dest, cover);
    try {
        fs.unlinkSync(src);
        return true;
    } catch (error) {
        console.log(error);
    }
    return false;
}

function copyFile(src: AbsPath, dest: AbsPath, cover: boolean = true): boolean {
    if (src === dest) {
        return false;
    }

    if (!isFile(src)) {
        return false;
    }

    if (!cover) {
        cover = true;
    }

    try {
        let parent = fspath.dirname(dest);
        fs.mkdirSync(parent, {recursive: true});
        if (!fs.existsSync(dest) || cover) {
            fs.copyFileSync(src, dest);
        }
        return true;
    } catch (error) {
        console.log(error);
        return false;
    }
}

/**
 * remove folder or file by path
 * @param path 
*/
function rmSync(path: AbsPath): void {
    if (fs.existsSync(path)) {
        if (fs.statSync(path).isDirectory()) {
            const files = fs.readdirSync(path);
            for (const file of files) {
                const curPath = hdlPath.join(path, file);
                if (fs.statSync(curPath).isDirectory()) { // recurse
                    rmSync(curPath);
                } else {                                  // delete file
                    fs.unlinkSync(curPath);
                }
            }
            fs.rmdirSync(path);
        } else {
            fs.unlinkSync(path);
        }
    }
}

/**
 * check if obj have attr
 * @param obj 
 * @param attr attribution or attributions, split by '.' 
 * @returns 
 */
function isHasAttr(obj: any, attr: string): boolean{
    if (!obj) {
        return false;
    }
    let tempObj = obj;
    attr = attr.replace(/\[(\w+)\]/g, '.$1');
    attr = attr.replace(/^\./, '');
    
    let keyArr = attr.split('.');
    for (let i = 0; i < keyArr.length; i++) {
        const element = keyArr[i];
        if (!tempObj) {
            return false;
        }
        if (element in tempObj) {
            tempObj = tempObj[element];
        } else {
            return false;
        }
    }
    return true;
}


function isHasValue(obj: any, attr: string, value: any): boolean{
    if (!obj) {
        return false;
    }
    let tempObj = obj;
    attr = attr.replace(/\[(\w+)\]/g, '.$1');
    attr = attr.replace(/^\./, '');
  
    let keyArr = attr.split('.');
    for (let i = 0; i < keyArr.length; i++) {
        const element = keyArr[i];
        if (!tempObj) {
            return false;
        }
        if (element in tempObj) {
            tempObj = tempObj[element];
            if (i === keyArr.length - 1 && tempObj !== value) {
                return false;
            }
        } else {
            return false;
        }
    }
    return true;
}

function* walk(path: AbsPath | RelPath, condition?: (filePath: AbsPath) => boolean): Generator<AbsPath> {
    if (isFile(path)) {
        if (!condition || condition(path)) {
            yield path;
        }
    } else {
        for (const file of fs.readdirSync(path)) {
            const filePath = hdlPath.join(path, file);
            if (isDir(filePath)) {
                for (const targetPath of walk(filePath, condition)) {
                    yield targetPath;
                }
            } else if (isFile(filePath)) {
                if (!condition || condition(filePath)) {
                    yield filePath;
                }
            }
        }
    }
}

export {
    isFile,
    isDir,
    isVerilogFile,
    isVhdlFile,
    isSystemVerilogFile,
    isHDLFile,
    getHDLFiles,
    getLanguageId,
    readFile,
    writeFile,
    readJSON,
    writeJSON,
    rmSync,
    getHdlFileType,
    pickFileRecursive,
    isHasAttr,
    isHasValue,
    copyFile,
    removeFile,
    moveFile,
    walk
};