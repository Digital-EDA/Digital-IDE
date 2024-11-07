import * as vscode from 'vscode';
import { hdlFile } from '../hdlFs';
import { HdlLangID } from '../global/enum';
import { AbsPath, LspClient, opeParam } from '../global';
import { DoFastRequestType, ITextDocumentItem, CustomParamRequestType, UpdateFastRequestType, DoFastFileType, DoFastToolChainType } from '../global/lsp';
import { Fast, RawHdlModule } from './common';


async function doFastApi(path: string, fileType: DoFastFileType): Promise<Fast | undefined> {
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


namespace HdlSymbol {
    /**
     * @description 计算出模块级的信息
     * @param path 文件绝对路径
     * @returns 
     */
    export function fast(path: AbsPath, fileType: DoFastFileType): Promise<Fast | undefined> {
        return doFastApi(path, fileType);
    }
}



export {
    HdlSymbol,
};