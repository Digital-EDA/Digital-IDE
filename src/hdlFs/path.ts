import * as fspath from 'path';

import { AbsPath, RelPath } from '../global';

/**
 * @param path
 * @returns 
 */
function toSlash(path: AbsPath | RelPath): AbsPath | RelPath {
    return path.replace(/\\/g,"\/");
}

/**
 * resolve an absolute path of a relative path in an absolute path 
 * @param curPath current path of the file 
 * @param relPath relative path in curPath
 * @returns 
 */
function rel2abs(curPath: AbsPath, relPath: RelPath): AbsPath {
    if (fspath.isAbsolute(relPath)) {
        return relPath;
    }
    const curDirPath = fspath.dirname(curPath);
    const absPath = fspath.resolve(curDirPath, relPath);
    return toSlash(absPath);
}

/**
 * cat paths with '/'
 * @param paths 
 * @returns 
 */
function join(...paths: string[]): AbsPath | RelPath {
    return paths.join('/');
}


/**
 * resolve paths with '/'
 * @param paths 
 * @returns 
 */
function resolve(...paths: string[]): AbsPath | RelPath {
    const absPath = fspath.resolve(...paths);
    return toSlash(absPath);
}


/**
 * get the extname of a path
 * @param path 
 * @param reserveSplitor 
 * @returns reserveSplitor=true  src/file.txt -> .txt
 *          reserveSplitor=false src/file.txt -> txt
 */
function extname(path: AbsPath | RelPath, reserveSplitor: boolean = true): string {
    let ext = fspath.extname(path).toLowerCase();
    if (!reserveSplitor && ext.startsWith('.')) {
        ext = ext.substring(1);
    }
    return ext;
}

function basename(path: AbsPath | RelPath) {
    return fspath.basename(path, extname(path, true));
}


/**
 * get the file name of a path
 * @param path 
 * @returns src/file.txt -> file
 */
function filename(path: AbsPath | RelPath): string {
    const ext = extname(path, true);
    return fspath.basename(path, ext);
}

export {
    toSlash,
    rel2abs,
    join,
    resolve,
    filename,
    extname,
    basename
};