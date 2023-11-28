import * as vscode from 'vscode';

import { AllowNull } from '../../../global';
import { RawSymbol, Range } from '../../../hdlParser/common';
import { hdlSymbolStorage } from '../core';

import { positionAfterEqual } from '../util';

interface DocSymbolContainer {
    docSymbol: AllowNull<vscode.DocumentSymbol>,
    range: AllowNull<Range>
};

class VhdlDocSymbolProvider implements vscode.DocumentSymbolProvider {
    public async provideDocumentSymbols(document: vscode.TextDocument, token: vscode.CancellationToken): Promise<vscode.DocumentSymbol[]> {
        
        const path = document.fileName;
        const vhdlAll = await hdlSymbolStorage.getSymbol(path);     
        
        if (!vhdlAll || !vhdlAll.content) {
            return [];
        } else {
            const symbols = vhdlAll.content;
            const symbolInfos = this.makeDocumentSymbols(document, symbols);
            return symbolInfos;
        }
    }


    private makeDocumentSymbols(document: vscode.TextDocument, symbols: RawSymbol[]): vscode.DocumentSymbol[] {
        const docSymbols: vscode.DocumentSymbol[] = [];

        for (const symbol of symbols) {
            const symbolStart = new vscode.Position(symbol.range.start.line - 1, symbol.range.start.character);
            const symbolEnd = new vscode.Position(symbol.range.end.line - 1, symbol.range.end.character);
            const symbolRange = new vscode.Range(symbolStart, symbolEnd);

            if (symbol.type === 'entity') {
                const docSymbol = new vscode.DocumentSymbol(symbol.name, 
                                                            symbol.name, 
                                                            vscode.SymbolKind.Interface, 
                                                            symbolRange,
                                                            symbolRange);
                docSymbols.push(docSymbol);
            } else if (symbol.type === 'port') {
                const parentEntity = docSymbols[docSymbols.length - 1];
                const docSymbol = new vscode.DocumentSymbol(symbol.name, 
                                                            symbol.name, 
                                                            vscode.SymbolKind.Method, 
                                                            symbolRange,
                                                            symbolRange);
                parentEntity.children.push(docSymbol);
            }
        }

        return docSymbols;
    }
}

const vhdlDocSymbolProvider = new VhdlDocSymbolProvider();

export {
    vhdlDocSymbolProvider
};