import * as vscode from 'vscode';

const tokenTypes = ['class', 'interface', 'enum', 'function', 'variable'];
const tokenModifiers = ['declaration', 'documentation'];
const vlogLegend = new vscode.SemanticTokensLegend(tokenTypes, tokenModifiers);

class VlogDocSenmanticProvider implements vscode.DocumentSemanticTokensProvider {
    public async provideDocumentSemanticTokens(document: vscode.TextDocument, token: vscode.CancellationToken): Promise<vscode.SemanticTokens | null | undefined> {
        // TODO : finish this
        // const tokensBuilder = new vscode.SemanticTokensBuilder(vlogLegend);
        return null;
    }
}

const vlogDocSenmanticProvider = new VlogDocSenmanticProvider();

export {    
    vlogDocSenmanticProvider,
    vlogLegend
};