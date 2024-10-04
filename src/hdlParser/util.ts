import * as vscode from 'vscode';
import { Fast, vlogAll, vhdlAll, svAll, All } from '../../resources/hdlParser';
import { hdlFile } from '../hdlFs';
import { HdlLangID } from '../global/enum';
import { AbsPath, LspClient } from '../global';
import { DoFastRequestType, ITextDocumentItem, CustomParamRequestType } from '../global/lsp';
import { RawHdlModule } from './common';

async function doFastApi(path: string): Promise<Fast | undefined> {
    try {
        const client = LspClient.DigitalIDE;
        const langID = hdlFile.getLanguageId(path);
        if (client) {
            const response = await client.sendRequest(DoFastRequestType, { path });            
            response.languageId = langID;
            return response;
        }
    } catch (error) {
        console.error("error happen when run doFastApi, " + error);
        console.error("error file path: " + path);
        return undefined;
    }
}

async function vlogFast(path: string): Promise<Fast | undefined> {
    const fast = await doFastApi(path);
    return fast;
}

async function svFast(path: string): Promise<Fast | undefined> {
    const fast = await doFastApi(path);
    return fast;
}

async function vhdlFast(path: string): Promise<Fast | undefined> {
    const fast = await doFastApi(path);
    return fast;
}

namespace HdlSymbol {
    /**
     * @description 计算出模块级的信息
     * @param path 文件绝对路径
     * @returns 
     */
    export function fast(path: AbsPath): Promise<Fast | undefined> {
        const langID = hdlFile.getLanguageId(path);
        switch (langID) {
            case HdlLangID.Verilog: return vlogFast(path);
            case HdlLangID.Vhdl: return vhdlFast(path);
            case HdlLangID.SystemVerilog: return svFast(path);
            default: return new Promise(resolve => resolve(undefined));
        }
    }

    /**
     * @description 0.4.0 后丢弃
     * @param path 文件绝对路径
     * @returns 
     */
    export function all(path: AbsPath): Promise<All | undefined> {
        const langID = hdlFile.getLanguageId(path);
        switch (langID) {
            case HdlLangID.Verilog: return vlogAll(path);
            case HdlLangID.Vhdl: return vhdlAll(path);
            case HdlLangID.SystemVerilog: return svAll(path);
            default: return new Promise(resolve => resolve(undefined));
        }
    }
}



export {
    HdlSymbol,
};