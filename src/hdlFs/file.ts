import * as fs from 'fs';
import * as fspath from 'path';

import { AbsPath, RelPath } from '../global';
import { HdlLangID } from '../global/enum';
import { verilogExts, vhdlExts, systemVerilogExts, hdlExts } from '../global/lang';
import * as hdlPath from './path';
import { HdlFileProjectType } from '../hdlParser/common';
import { opeParam } from '../global';
import { hdlIgnore } from '../manager/ignore';
import { hdlDir } from '.';

/**
 * judge if the path represent a file
 * @param path 
 * @returns 
 */
export function isFile(path: AbsPath): boolean {
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
export function isDir(path: AbsPath): boolean {
    if (!fs.existsSync(path)) {
        return false;
    }

    const state: fs.Stats = fs.statSync(path);
    if (state.isDirectory()) {
        return true;
    }
    return false;
}

export function isVerilogFile(path: AbsPath): boolean {
    if (!isFile(path)) {
        return false;
    }
    const ext = hdlPath.extname(path, false);
    return verilogExts.includes(ext);
}

export function isVhdlFile(path: AbsPath): boolean {
    if (!isFile(path)) {
        return false;
    }
    const ext = hdlPath.extname(path, false);
    return vhdlExts.includes(ext);
}

export function isSystemVerilogFile(path: AbsPath): boolean {
    if (!isFile(path)) {
        return false;
    }
    const ext = hdlPath.extname(path, false);
    return systemVerilogExts.includes(ext);
}

export function isHDLFile(path: AbsPath): boolean {    
    const ext = hdlPath.extname(path, false);    
    return hdlExts.includes(ext);
}

/**
 * @description 获取 path 下所有的 hdl 类型的文件
 * @param path 
 * @returns 
 */
export function getHDLFiles(path: AbsPath | AbsPath[] | Set<AbsPath>): AbsPath[] {
    const allFiles = pickFileRecursive(path, filePath => {
        // 判断是否在 ignore 里面
        if (hdlIgnore.isignore(filePath)) {
            return false;
        }
        // 判断是否为 hdl 文件
        return isHDLFile(filePath);
    });
    const pathSet = new Set<string>(allFiles);
    return [...pathSet];
}

/**
 * @description 从 path 下递归地获取所有文件
 * @param path 
 * @param condition 条件函数，判定为 true 的文件才会出现了返回文件中
 * @returns 
 */
export function pickFileRecursive(
    path: AbsPath | AbsPath[] | Set<AbsPath>,
    condition?: (filePath: string) => boolean | undefined | void
): AbsPath[] {
    if ((path instanceof Array) ||
        (path instanceof Set)) {
        const hdlFiles: AbsPath[] = [];
        path.forEach(p => hdlFiles.push(...pickFileRecursive(p, condition)));
        return hdlFiles;
    }

    if (isDir(path)) {
        const hdlFiles = [];
        for (const file of fs.readdirSync(path)) {
            const filePath = hdlPath.join(path, file);            
            if (isDir(filePath)) {
                const subHdlFiles = pickFileRecursive(filePath, condition);
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
export function getLanguageId(path: AbsPath | RelPath): HdlLangID {
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


export function readFile(path: AbsPath): string | undefined {
    try {
        const content = fs.readFileSync(path, 'utf-8');
        return content;
    } catch (error) {
        console.log(error);
        return undefined;
    }
}

export function writeFile(path: AbsPath, content: string): boolean {
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

export function readJSON(path: AbsPath): any {
    try {        
        const context = fs.readFileSync(path, 'utf-8');
        return JSON.parse(context);
    } catch (err) {
        console.log('fail to read JSON: ', err);
    }
    return {};
}

export function writeJSON(path: AbsPath, obj: object): boolean {
    try {
        const jsonString = JSON.stringify(obj, null, '\t');
        return writeFile(path, jsonString);
    } catch (err) {
        console.log('fail to write to ' + path + ': ', err);
    }
    return false;
}

export function removeFile(path: AbsPath): boolean {
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

export function moveFile(src: AbsPath, dest: AbsPath, cover: boolean = true): boolean {
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

export function copyFile(src: AbsPath, dest: AbsPath, cover: boolean = true): boolean {
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
        const parent = fspath.dirname(dest);
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
export function rmSync(path: AbsPath): void {
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
export function isHasAttr(obj: any, attr: string): boolean{
    if (!obj) {
        return false;
    }
    let tempObj = obj;
    attr = attr.replace(/\[(\w+)\]/g, '.$1');
    attr = attr.replace(/^\./, '');
    
    const keyArr = attr.split('.');
    for (let i = 0; i < keyArr.length; ++ i) {
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


export function isHasValue(obj: any, attr: string, value: any): boolean{
    if (!obj) {
        return false;
    }
    let tempObj = obj;
    attr = attr.replace(/\[(\w+)\]/g, '.$1');
    attr = attr.replace(/^\./, '');
  
    const keyArr = attr.split('.');
    for (let i = 0; i < keyArr.length; ++ i) {
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

export function* walk(path: AbsPath | RelPath, condition?: (filePath: AbsPath) => boolean): Generator<AbsPath> {
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

interface DiffResult {
    /**
     * @description 新文件布局和老的相比，新增了哪些文件
     */
    addFiles: AbsPath[],
    /**
     * @description 新文件布局和老的相比，少了哪些文件
     */
    delFiles: AbsPath[]
}

/**
 * @description 比较新老文件布局，并返回有哪些新增，哪些减少
 * @param newFiles 
 * @param oldFiles 
 * @returns 
 */
export function diffFiles(newFiles: AbsPath[], oldFiles: AbsPath[]): DiffResult {
    const uncheckHdlFileSet = new Set<AbsPath>(oldFiles);
    const addFiles: AbsPath[] = [];
    const delFiles: AbsPath[] = [];
    
    for (const path of newFiles) {
        if (!uncheckHdlFileSet.has(path)) {
            addFiles.push(path);
        } else {
            uncheckHdlFileSet.delete(path);
        }
    }

    for (const path of uncheckHdlFileSet) {
        delFiles.push(path);
    }
    return {
        addFiles, delFiles
    };
}

/**
 * @description 移动 source 到 target 中，target 必须是一个文件夹路径
 * - 如果 source 是一个文件，则移动到 target/source
 * - 如果 source 是一个文件夹，则移动到 target/source
 * @param source 
 * @param target 
 */
export function move(source: AbsPath, target: AbsPath) {
    if (isDir(source)) {
        hdlDir.mvdir(source, target, true);
    } else {
        const filename = fspath.basename(source);
        moveFile(source, hdlPath.join(target, filename));
    }
}