import * as vscode from 'vscode';
import { All } from '../../../../resources/hdlParser';
import { AbsPath } from '../../../global';
import { hdlPath } from '../../../hdlFs';
import { isHDLFile, isVerilogFile, isVhdlFile } from '../../../hdlFs/file';
import { HdlSymbol } from '../../../hdlParser';

type ThenableAll = Promise<All | undefined>;

class SymbolStorage {
    private symbolMap: Map<AbsPath, ThenableAll>;
    private isHdlFile: (file: AbsPath) => boolean;
    constructor(isHdlFile: (file: AbsPath) => boolean) {
        this.symbolMap = new Map<AbsPath, ThenableAll>();
        this.isHdlFile = isHdlFile;
    }

    public async getSymbol(path: AbsPath): ThenableAll {
        path = hdlPath.toSlash(path);
        const allP = this.symbolMap.get(path);
        if (allP) {
            return await allP;
        }
        this.updateSymbol(path);
        const all = await this.symbolMap.get(path);
        return all;
    }

    public async updateSymbol(path: AbsPath) {
        path = hdlPath.toSlash(path);
        const allPromise = HdlSymbol.all(path);
        this.symbolMap.set(path, allPromise);
    }

    public async deleteSymbol(path: AbsPath) {
        path = hdlPath.toSlash(path);
        this.symbolMap.delete(path);
    }

    public async initialise() {
        for (const doc of vscode.workspace.textDocuments) {
            // TODO : check support for sv
            // TODO : check performance
            if (isHDLFile(doc.fileName)) {
                await this.updateSymbol(doc.fileName);
            }
        }
    }
}

const hdlSymbolStorage = new SymbolStorage(isVerilogFile);

export {
    hdlSymbolStorage
};