import * as vscode from 'vscode';

import { HdlSymbol } from '../../../hdlParser';

const tokenTypes = ['class', 'interface', 'enum', 'function', 'variable'];
const tokenModifiers = ['declaration', 'documentation'];
const vlogLegend = new vscode.SemanticTokensLegend(tokenTypes, tokenModifiers);

class VlogDocSenmanticProvider implements vscode.DocumentSemanticTokensProvider {
    public async provideDocumentSemanticTokens(document: vscode.TextDocument, token: vscode.CancellationToken): Promise<vscode.SemanticTokens | null | undefined> {
        const tokensBuilder = new vscode.SemanticTokensBuilder(vlogLegend);
        return tokensBuilder.build();
    }
}

const vlogDocSenmanticProvider = new VlogDocSenmanticProvider();

export {    
    vlogDocSenmanticProvider,
    vlogLegend
};