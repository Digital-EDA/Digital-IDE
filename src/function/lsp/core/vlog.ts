import * as vscode from 'vscode';
import { All } from '../../../../resources/hdlParser';
import { AbsPath } from '../../../global';
import { hdlPath } from '../../../hdlFs';
import { isVerilogFile } from '../../../hdlFs/file';
import { HdlSymbol } from '../../../hdlParser';

type ThenableAll = Promise<All | undefined>;

class VlogSymbolStorage {
    private symbolMap: Map<AbsPath, ThenableAll>;
    constructor() {
        this.symbolMap = new Map<AbsPath, ThenableAll>();
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
        const vlogAllPromise = HdlSymbol.all(path);
        this.symbolMap.set(path, vlogAllPromise);
    }

    public async deleteSymbol(path: AbsPath) {
        path = hdlPath.toSlash(path);
        this.symbolMap.delete(path);
    }


    public async initialise() {
        for (const doc of vscode.workspace.textDocuments) {
            if (isVerilogFile(doc.fileName)) {
                // TODO : check performance
                await this.updateSymbol(doc.fileName);
            }
        }
    }
}

const vlogSymbolStorage = new VlogSymbolStorage();

export {
    vlogSymbolStorage
};