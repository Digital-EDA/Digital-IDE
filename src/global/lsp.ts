import * as vscode from 'vscode';
import { LanguageClient, RequestType, ProtocolConnection } from 'vscode-languageclient/node';
import { Fast } from '../../resources/hdlParser';


interface IDigitalIDELspClient {
    MainClient?: LanguageClient,
    VhdlClient?: LanguageClient
}

export const LspClient: IDigitalIDELspClient = {
    MainClient: undefined,
    VhdlClient: undefined
};

/**
 * @description 构造请求参数
 * RequestType<P, R, E, RO>
 * P: 请求的参数类型。
 * R: 请求的响应类型。
 * E: 请求的错误类型。
 * RO: 请求的可选参数类型。
 */
export const CustomRequestType = new RequestType<void, number, void>('custom/request');
export const CustomParamRequestType = new RequestType<ICommonParam, number, void>('custom/paramRequest');
export const DoFastRequestType = new RequestType<IDoFastParam, Fast, void>('api/fast');

export interface ITextDocumentItem {
    uri: vscode.Uri,
    languageId: string,
    version: number,
    text: string
}

export interface ICommonParam {
    param: string
}

export interface IDoFastParam {
    path: string
}