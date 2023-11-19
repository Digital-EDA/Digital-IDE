import * as vscode from 'vscode';
import { All } from '../../../../resources/hdlParser';
import { HdlSymbol } from '../../../hdlParser';
import { hdlSymbolStorage } from '../core';
import { transformRange } from '../util';

const tokenTypes = ['class', 'function', 'variable'];
const tokenModifiers = ['declaration', 'documentation'];
const vlogLegend = new vscode.SemanticTokensLegend(tokenTypes, tokenModifiers);


class VlogDocSenmanticProvider implements vscode.DocumentSemanticTokensProvider {
    public async provideDocumentSemanticTokens(document: vscode.TextDocument, token: vscode.CancellationToken): Promise<vscode.SemanticTokens | null | undefined> {
        // TODO : finish this
        const tokensBuilder = new vscode.SemanticTokensBuilder(vlogLegend);        
        // const filePath = document.fileName;
        // const vlogAll = await HdlSymbol.all(filePath);
        // if (vlogAll) {
        //     this.prepareTokensBuilder(tokensBuilder, vlogAll);
        // }
        return tokensBuilder.build();
    }

    private prepareTokensBuilder(builder: vscode.SemanticTokensBuilder, all: All){
        for (const rawSymbol of all.content) {
            const semanticRange = transformRange(rawSymbol.range, -1, 0);
            const tokenType = this.getTokenTypes(rawSymbol.type);
            if (tokenType) {
                builder.push(semanticRange, tokenType);
            }
        }
    }

    private getTokenTypes(type: string): string | undefined {
        switch (type) {
            case 'input':
                return 'variable';
            case 'output':
                return 'variable';
            case 'wire':
                return 'variable';
            case 'reg':
                return 'variable';
            default:
                return;
        }
    }
    
}

const vlogDocSenmanticProvider = new VlogDocSenmanticProvider();

export {    
    vlogDocSenmanticProvider,
    vlogLegend
};