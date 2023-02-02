import * as fs from 'fs';
import * as fspath from 'path';
import { AbsPath } from '../global';
import * as hdlPath from './path';

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

function mkdir(path: AbsPath): boolean {
    if (!path) {
        return false;
    }
    // 如果存在则直接退出
    if (fs.existsSync(path)) {
        return true;
    }

    try {
        fs.mkdirSync(path, {recursive:true});
        return true;
    } 
    catch (error) {
        fs.mkdirSync(path, {recursive:true});
    }
    return false;
}

function rmdir(path: AbsPath): void {
    if (fs.existsSync(path)) {
        if (fs.statSync(path).isDirectory()) {
            const files = fs.readdirSync(path);
            for (const file of files) {
                const curPath = hdlPath.join(path, file);
                if (fs.statSync(curPath).isDirectory()) { // recurse
                    rmdir(curPath);
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

function mvdir(src: AbsPath, dest: AbsPath, cover: boolean): boolean {
    if (src === dest) {
        return false;
    }

    if (cpdir(src, dest, cover)) {
        rmdir(src);
        return true;
    } else {
        return false;
    }
}

function cpdir(src: AbsPath, dest: AbsPath, cover: boolean) {
    if (src === dest) {
        return false;
    }

    // 如果不存在或者不为dir则先构建目的文件夹再退出
    if (!isDir(src)) {
        mkdir(dest);
        return false;
    }

    if (!cover) {
        cover = true;
    }

    let srcName = fspath.basename(src);
    dest = fspath.join(dest, srcName);

    let children = fs.readdirSync(src);

    if (!children.length) {
        mkdir(dest);
        return true;
    }

    for (let i = 0; i < children.length; i++) {
        const element = children[i];
        // child: path/src/element
        const child = fspath.join(src, element);
        const state = fs.statSync(child);
        if (state.isFile()) {
            if (!mkdir(dest)) {
                return false;
            }
            // element is file under src, dest: path/dest/src
            const destPath = fspath.join(dest, element);
            try {
                if (!fs.existsSync(child)) {
                    fs.copyFileSync(child, destPath);
                } else {
                    if (cover) {
                        fs.copyFileSync(child, destPath);
                    }
                }
            } 
            catch (error) {
                console.log(error);
            }
        }
        if (state.isDirectory()) {
            cpdir(child, dest, false);
        }
    }

    return true;
}

export {
    mkdir,
    rmdir,
    cpdir
};