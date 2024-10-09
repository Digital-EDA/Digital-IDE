import * as vscode from 'vscode';
import { hdlFile } from '../hdlFs';
import { HdlLangID } from '../global/enum';
import { AbsPath, LspClient } from '../global';
import { DoFastRequestType, ITextDocumentItem, CustomParamRequestType, UpdateFastRequestType } from '../global/lsp';
import { Fast, RawHdlModule } from './common';



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

async function updateFastApi(path: string): Promise<Fast | undefined> {
    try {
        const client = LspClient.DigitalIDE;
        const langID = hdlFile.getLanguageId(path);
        if (client) {
            const response = await client.sendRequest(UpdateFastRequestType, { path });            
            response.languageId = langID;
            return response;
        }
    } catch (error) {
        console.error("error happen when run doFastApi, " + error);
        console.error("error file path: " + path);
        return undefined;
    }
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
            case HdlLangID.Verilog:
            case HdlLangID.Vhdl:
            case HdlLangID.SystemVerilog:
                return doFastApi(path);
            default: return new Promise(resolve => resolve(undefined));
        }
    }

    export function updateFast(path: AbsPath): Promise<Fast | undefined> {
        const langID = hdlFile.getLanguageId(path);
        switch (langID) {
            case HdlLangID.Verilog:
            case HdlLangID.Vhdl:
            case HdlLangID.SystemVerilog: 
                return updateFastApi(path);
            default: return new Promise(resolve => resolve(undefined));
        }
    }
}



export {
    HdlSymbol,
};