import * as vscode from 'vscode';

import { HdlSymbol } from '../../../hdlParser';

class VlogDocSymbolProvider implements vscode.DocumentSymbolProvider {
    
    public provideDocumentSymbols(document: vscode.TextDocument, token: vscode.CancellationToken): vscode.ProviderResult<vscode.SymbolInformation[] | vscode.DocumentSymbol[]> {
        const code = document.getText();
        const symbolResult = HdlSymbol.all(code);
        const symbols = symbolResult.symbols;

        if (!symbols) {
            return [];
        }
        try {
            const symbolInfos = this.makeSymbolInfos(document, symbols);
            return symbolInfos;
        } catch (err) {
            console.log(err);
            return [];
        }   
    }

    /**
     * 
     * @param {vscode.TextDocument} document
     * @param {Array<SymbolResult>} symbols 
     * @returns {Array<vscode.DocumentSymbol>}
     */
    makeSymbolInfos(document: vscode.TextDocument, symbols: SymbolResult[]) {
        let docSymbols = [];
        const visitedSymbols = new Set();
        const moduleSymbols = symbols.filter(symbol => {
            if (symbol.type == 'module') {
                visitedSymbols.add(symbol);
                return true;
            }
            return false;
        });

        for (const moduleSymbol of moduleSymbols) {
            const moduleName = moduleSymbol.name;
            const moduleKind = this.getSymbolKind(moduleSymbol.type);
            const moduleRange = new vscode.Range(moduleSymbol.start, moduleSymbol.end);
            const moduleDocSymbol = new vscode.DocumentSymbol(moduleName, 
                                                              moduleName,
                                                              moduleKind, 
                                                              moduleRange,
                                                              moduleRange);
            docSymbols.push(moduleDocSymbol);
            let paramContainer = {
                docSymbol: null,
                range: null
            };
            let portContainer = {
                docSymbol: null,
                range: null
            };

            // make others in module inner
            for (const symbol of symbols) {
                if (visitedSymbols.has(symbol)) {
                    continue;
                }
                if (!(positionAfterEqual(symbol.start, moduleSymbol.start) &&
                    positionAfterEqual(moduleSymbol.end, symbol.end))) {
                    continue;
                }
                if (!symbol.name) {
                    symbol.name = '???';
                }
                visitedSymbols.add(symbol);
                const symbolRange = new vscode.Range(symbol.start, symbol.end);

                if (symbol.type == 'parameter') {
                    if (!paramContainer.range) {
                        paramContainer.range = symbolRange;
                        paramContainer.docSymbol = new vscode.DocumentSymbol('param',
                                                                             'param description',
                                                                             vscode.SymbolKind.Method,
                                                                             symbolRange,
                                                                             symbolRange);
                        moduleDocSymbol.children.push(paramContainer.docSymbol);
                    }
                    const paramDocSymbol = new vscode.DocumentSymbol(symbol.name,
                                                                     symbol.type,
                                                                     vscode.SymbolKind.Constant,
                                                                     symbolRange,
                                                                     symbolRange);
                    paramContainer.docSymbol.children.push(paramDocSymbol);
                    
                } else if (['input', 'inout', 'output'].includes(symbol.type)) {
                    if (!portContainer.range) {
                        portContainer.range = symbolRange;
                        portContainer.docSymbol = new vscode.DocumentSymbol('port',
                                                                            'port description',
                                                                            vscode.SymbolKind.Method,
                                                                            symbolRange,
                                                                            symbolRange);
                        moduleDocSymbol.children.push(portContainer.docSymbol);
                    }

                    const portDocSymbol = new vscode.DocumentSymbol(symbol.name,
                                                                    symbol.type,
                                                                    vscode.SymbolKind.Interface,
                                                                    symbolRange,
                                                                    symbolRange);
                    portContainer.docSymbol.children.push(portDocSymbol);
                } else {
                    const symbolKind = this.getSymbolKind(symbol.type);
                    const symbolDocSymbol = new vscode.DocumentSymbol(symbol.name,
                                                                      symbol.type,
                                                                      symbolKind,
                                                                      symbolRange,
                                                                      symbolRange);
                    moduleDocSymbol.children.push(symbolDocSymbol);
                }
            }
        }

        return docSymbols;
    }


    getSymbolKind(name) {
        if (name.indexOf('[') != -1) {
            return vscode.SymbolKind.Array;
        }
        switch (name) {
            case 'module': return vscode.SymbolKind.Class;
            case 'program': return vscode.SymbolKind.Module;
            case 'package': return vscode.SymbolKind.Package;
            case 'import': return vscode.SymbolKind.Package;
            case 'always': return vscode.SymbolKind.Operator;
            case 'processe': return vscode.SymbolKind.Operator;

            case 'task': return vscode.SymbolKind.Method;
            case 'function': return vscode.SymbolKind.Function;

            case 'assert': return vscode.SymbolKind.Boolean;
            case 'event': return vscode.SymbolKind.Event;
            case 'instance': return vscode.SymbolKind.Event;

            case 'time': return vscode.SymbolKind.TypeParameter;
            case 'define': return vscode.SymbolKind.TypeParameter;
            case 'typedef': return vscode.SymbolKind.TypeParameter;
            case 'generate': return vscode.SymbolKind.Operator;
            case 'enum': return vscode.SymbolKind.Enum;
            case 'modport': return vscode.SymbolKind.Boolean;
            case 'property': return vscode.SymbolKind.Property;

            // port 
            case 'interface': return vscode.SymbolKind.Interface;
            case 'buffer': return vscode.SymbolKind.Interface;
            case 'output': return vscode.SymbolKind.Interface;
            case 'input': return vscode.SymbolKind.Interface;
            case 'inout': return vscode.SymbolKind.Interface;

            // synth param    
            case 'localparam': return vscode.SymbolKind.Constant;
            case 'parameter': return vscode.SymbolKind.Constant;
            case 'integer': return vscode.SymbolKind.Number;
            case 'char': return vscode.SymbolKind.Number;
            case 'float': return vscode.SymbolKind.Number;
            case 'int': return vscode.SymbolKind.Number;

            // unsynth param
            case 'string': return vscode.SymbolKind.String;
            case 'struct': return vscode.SymbolKind.Struct;
            case 'class': return vscode.SymbolKind.Class;

            case 'logic': return vscode.SymbolKind.Constant;
            case 'wire': return vscode.SymbolKind.Constant;
            case 'reg': return vscode.SymbolKind.Constant;
            case 'net': return vscode.SymbolKind.Variable;
            case 'bit': return vscode.SymbolKind.Boolean;
            default: return vscode.SymbolKind.Event;
        }
        /* Unused/Free SymbolKind icons
            return SymbolKind.Number;
            return SymbolKind.Enum;
            return SymbolKind.EnumMember;
            return SymbolKind.Operator;
            return SymbolKind.Array;
        */
    }
}
