import * as vscode from 'vscode';
import { hdlFile } from '../hdlFs';
import { AbsPath, LspClient, opeParam } from '../global';
import { DoFastRequestType, DoFastFileType, DoFastToolChainType, DoPrimitivesJudgeType } from '../global/lsp';
import { Fast, Macro, Range } from './common';


export async function doFastApi(path: string, fileType: DoFastFileType): Promise<Fast | undefined> {
    try {
        const client = LspClient.DigitalIDE;
        const langID = hdlFile.getLanguageId(path);
        const toolChain = opeParam.prjInfo.toolChain as DoFastToolChainType;
        if (client) {
            const response = await client.sendRequest(DoFastRequestType, { path, fileType, toolChain });
            response.languageId = langID;
            return response;
        }
    } catch (error) {
        console.error("error happen when run doFastApi, " + error);
        console.error("error file path: " + path);
        return undefined;
    }
}

export async function doPrimitivesJudgeApi(primitiveName: string): Promise<boolean> {
    try {
        const client = LspClient.DigitalIDE;
        if (client) {
            const response = await client.sendRequest(DoPrimitivesJudgeType, { name: primitiveName });
            return response;
        }
    } catch (error) {
        console.error("error happen when run judgePrimitivesApi, " + error);
        console.error("error query primitive name: " + primitiveName);
        return false;
    }
    return false;
}


export namespace HdlSymbol {
    /**
     * @description 计算出模块级的信息
     * @param path 文件绝对路径
     * @returns 
     */
    export function fast(path: AbsPath, fileType: DoFastFileType): Promise<Fast | undefined> {
        return doFastApi(path, fileType);
    }
}

export const defaultRange: Range = {
    start: { line: 0, character: 0 },
    end: { line: 0, character: 0 }
};

export const defaultMacro: Macro = {
    errors: [],
    includes: [],
    defines: [],
    invalid: []
};