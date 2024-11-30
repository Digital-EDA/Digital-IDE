import * as vscode from 'vscode';
import { AbsPath, opeParam } from '../global';
import { hdlFile, hdlPath } from '../hdlFs';
import * as fs from 'fs';
import * as fspath from 'path';
import { minimatch } from 'minimatch';
import { toPureRelativePath } from '../hdlFs/path';


class HdlIgnore {
    // 用于进行 glob 匹配的模式
    public patterns: string[]
    constructor() {
        this.patterns = [];
    }

    /**
     * @description 判断输入的路径是否为 ignore
     */
    public isignore(path: AbsPath): boolean {
        const workspace = opeParam.workspacePath;
        // 转换成相对于 ws 的相对路径，形如 ./src/test.py
        let relativePath = hdlPath.toPureRelativePath(hdlPath.relative(workspace, path));
        
        for (const pattern of this.patterns) {
            const matched = minimatch(relativePath, pattern);
            if (matched) {
                return true;
            }
        }
        return false;
    }


    public updatePatterns() {
        // ignore 文件一般不会很大，直接全量解析即可
        const ignorePath = opeParam.dideignorePath;

        if (fs.existsSync(ignorePath)) {
            const validGlobStrings = new Set<string>();
            const ignoreContent = fs.readFileSync(ignorePath, { encoding: 'utf-8' });
            for (const line of ignoreContent.split('\n')) {
                const lineText = line.trim();
                // 如果是空行或者 # 注释，则跳过
                if (lineText.length === 0 || lineText.startsWith('#')) {
                    continue;
                }
                
                const commentTagIndex = lineText.indexOf('#');
                if (commentTagIndex > -1) {
                    // 存在注释， # 往后都是注释
                    validGlobStrings.add(lineText.slice(0, commentTagIndex));
                } else {
                    // index 为 -1 说明本行没有注释，直接加入即可
                    validGlobStrings.add(lineText);
                }
            }
            this.patterns = [...validGlobStrings];
            this.makeClearPattern();
        } else {
            // .dideignore 不存在直接赋值为空
            this.patterns = [];
        }
    }

    /**
     * @description 构建可直接使用的 patterns
     * 该操作是幂等的
     */
    private makeClearPattern() {
        for (let i = 0; i < this.patterns.length; ++ i) {
            let pattern = this.patterns[i];
            if (fspath.isAbsolute(pattern)) {
                pattern = hdlPath.relative(opeParam.workspacePath, pattern);
            }
            this.patterns[i] = toPureRelativePath(pattern);
        }
    }
}

const hdlIgnore = new HdlIgnore();

export {
    hdlIgnore
};