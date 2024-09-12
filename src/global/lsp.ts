import { LanguageClient, RequestType, ProtocolConnection } from 'vscode-languageclient/node';


interface IDigitalIDELspClient {
    MainClient?: LanguageClient,
    VhdlClient?: LanguageClient
}

export const LspClient: IDigitalIDELspClient = {
    MainClient: undefined,
    VhdlClient: undefined
};

export const CustomRequestType = new RequestType<string[], void, void>('custom/request');
