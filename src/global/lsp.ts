import * as vscode from 'vscode';
import { LanguageClient, RequestType, ProtocolConnection } from 'vscode-languageclient/node';
import { Fast } from '../hdlParser/common';


interface IDigitalIDELspClient {
    DigitalIDE?: LanguageClient,
    VhdlClient?: LanguageClient
}

export const LspClient: IDigitalIDELspClient = {
    DigitalIDE: undefined,
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
export const CustomRequestType =        new RequestType<void, number, void>('custom/request');
export const CustomParamRequestType =   new RequestType<ICommonParam, number, void>('custom/paramRequest');
export const DoFastRequestType =        new RequestType<IDoFastParam, Fast, void>('api/fast');
export const UpdateConfigurationType =  new RequestType<IUpdateConfigurationParam, void, void>('api/update-configuration');
export const DoPrimitivesJudgeType =    new RequestType<IDoPrimitivesJudgeParam, boolean, void>('api/do-primitives-judge');
export const SyncFastRequestType =      new RequestType<ISyncFastParam, Fast, void>('api/sync-fast');
export const LinterStatusRequestType =  new RequestType<ILinterStatusRequestType, LinterToolStatus, void>('api/linter-status');

export interface ITextDocumentItem {
    uri: vscode.Uri,
    languageId: string,
    version: number,
    text: string
}

export interface ISyncFastParam {
    path: string,
    fileType: DoFastFileType,
    toolChain: DoFastToolChainType
}

export interface ICommonParam {
    param: string
}


export interface IUpdateConfigurationParam {
    configs: {
        name: string,
        value: string | boolean | number
    }[],
    configType: string
}

export interface ILinterStatusRequestType {
    languageId: string,
    linterName: string,
    linterPath: string
}

interface LinterToolStatus {
    toolName: string,
    available: boolean,
    invokeName: string
}

export interface IDoPrimitivesJudgeParam {
    name: string
}

export type DoFastFileType = 'common' | 'ip' | 'primitives';
export type DoFastToolChainType = 'xilinx' | 'efinity' | 'intel';

export interface IDoFastParam {
    path: string,
    fileType: DoFastFileType,
    toolChain: DoFastToolChainType
}