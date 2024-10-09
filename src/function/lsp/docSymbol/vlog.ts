import * as vscode from 'vscode';

import { AllowNull } from '../../../global';
import { RawSymbol, Range } from '../../../hdlParser/common';

import { positionAfterEqual } from '../util';

// interface DocSymbolContainer {
//     docSymbol: AllowNull<vscode.DocumentSymbol>,
//     range: AllowNull<Range>
// };

// class VlogDocSymbolProvider implements vscode.DocumentSymbolProvider {
//     public async provideDocumentSymbols(document: vscode.TextDocument, token: vscode.CancellationToken): Promise<vscode.DocumentSymbol[]> {
//         // console.log('VlogDocSymbolProvider');
        
//         const path = document.fileName;
//         const vlogAll = await hdlSymbolStorage.getSymbol(path);     
        
//         if (!vlogAll || !vlogAll.content) {
//             return [];
//         } else {
//             const symbols = vlogAll.content;
//             const symbolInfos = this.makeDocumentSymbols(document, symbols);
//             return symbolInfos;
//         }
//     }


//     private makeDocumentSymbols(document: vscode.TextDocument, symbols: RawSymbol[]): vscode.DocumentSymbol[] {
//         const docSymbols = [];
//         const visitedSymbols = new Set();
//         const moduleSymbols = symbols.filter(symbol => {
//             if (symbol.type === 'module') {
//                 visitedSymbols.add(symbol);
//                 return true;
//             }
//             return false;
//         });

//         for (const moduleSymbol of moduleSymbols) {
//             const moduleName = moduleSymbol.name;
//             const moduleKind = this.getSymbolKind(moduleSymbol.type);
//             const moduleStart = new vscode.Position(moduleSymbol.range.start.line - 1, moduleSymbol.range.start.character);
//             const moduleEnd = new vscode.Position(moduleSymbol.range.end.line - 1, moduleSymbol.range.start.character);
//             const moduleRange = new vscode.Range(moduleStart, moduleEnd);
//             const moduleDocSymbol = new vscode.DocumentSymbol(moduleName, 
//                                                               moduleName,
//                                                               moduleKind, 
//                                                               moduleRange,
//                                                               moduleRange);
//             docSymbols.push(moduleDocSymbol);
//             const paramContainer: DocSymbolContainer = {
//                 docSymbol: null,
//                 range: null
//             };
//             const portContainer: DocSymbolContainer = {
//                 docSymbol: null,
//                 range: null
//             };
//             const portTypes = ['input', 'inout', 'output'];

//             // make others in module inner
//             for (const symbol of symbols) {
//                 if (visitedSymbols.has(symbol)) {
//                     continue;
//                 }
//                 if (!(positionAfterEqual(symbol.range.start, moduleSymbol.range.start) &&
//                     positionAfterEqual(moduleSymbol.range.end, symbol.range.end))) {
//                     continue;
//                 }
//                 if (!symbol.name) {
//                     symbol.name = '???';
//                 }
//                 visitedSymbols.add(symbol);
//                 const symbolStart = new vscode.Position(symbol.range.start.line - 1, symbol.range.start.character);
//                 const symbolEnd = new vscode.Position(symbol.range.end.line - 1, symbol.range.end.character);
//                 const symbolRange = new vscode.Range(symbolStart, symbolEnd);

//                 if (symbol.type === 'parameter') {
//                     if (!paramContainer.range) {
//                         paramContainer.range = symbolRange;
//                         paramContainer.docSymbol = new vscode.DocumentSymbol('param',
//                                                                              'param description',
//                                                                              vscode.SymbolKind.Method,
//                                                                              symbolRange,
//                                                                              symbolRange);
//                         moduleDocSymbol.children.push(paramContainer.docSymbol);
//                     }
//                     const paramDocSymbol = new vscode.DocumentSymbol(symbol.name,
//                                                                      symbol.type,
//                                                                      vscode.SymbolKind.Constant,
//                                                                      symbolRange,
//                                                                      symbolRange);
//                     paramContainer.docSymbol?.children.push(paramDocSymbol);
                    
//                 } else if (portTypes.includes(symbol.type)) {
//                     if (!portContainer.range) {
//                         portContainer.range = symbolRange;
//                         portContainer.docSymbol = new vscode.DocumentSymbol('port',
//                                                                             'port description',
//                                                                             vscode.SymbolKind.Method,
//                                                                             symbolRange,
//                                                                             symbolRange);
//                         moduleDocSymbol.children.push(portContainer.docSymbol);
//                     }

//                     const portDocSymbol = new vscode.DocumentSymbol(symbol.name,
//                                                                     symbol.type,
//                                                                     vscode.SymbolKind.Interface,
//                                                                     symbolRange,
//                                                                     symbolRange);
//                     portContainer.docSymbol?.children.push(portDocSymbol);
//                 } else {
//                     const symbolKind = this.getSymbolKind(symbol.type);
//                     const symbolDocSymbol = new vscode.DocumentSymbol(symbol.name,
//                                                                       symbol.type,
//                                                                       symbolKind,
//                                                                       symbolRange,
//                                                                       symbolRange);
//                     moduleDocSymbol.children.push(symbolDocSymbol);
//                 }
//             }
//         }

//         return docSymbols;
//     }


//     private getSymbolKind(name: string): vscode.SymbolKind {
//         if (name.indexOf('[') !== -1) {
//             return vscode.SymbolKind.Array;
//         }
//         switch (name) {
//             case 'module': return vscode.SymbolKind.Class;
//             case 'program': return vscode.SymbolKind.Module;
//             case 'package': return vscode.SymbolKind.Package;
//             case 'import': return vscode.SymbolKind.Package;
//             case 'always': return vscode.SymbolKind.Operator;
//             case 'processe': return vscode.SymbolKind.Operator;

//             case 'task': return vscode.SymbolKind.Method;
//             case 'function': return vscode.SymbolKind.Function;

//             case 'assert': return vscode.SymbolKind.Boolean;
//             case 'event': return vscode.SymbolKind.Event;
//             case 'instance': return vscode.SymbolKind.Event;

//             case 'time': return vscode.SymbolKind.TypeParameter;
//             case 'define': return vscode.SymbolKind.TypeParameter;
//             case 'typedef': return vscode.SymbolKind.TypeParameter;
//             case 'generate': return vscode.SymbolKind.Operator;
//             case 'enum': return vscode.SymbolKind.Enum;
//             case 'modport': return vscode.SymbolKind.Boolean;
//             case 'property': return vscode.SymbolKind.Property;

//             // port 
//             case 'interface': return vscode.SymbolKind.Interface;
//             case 'buffer': return vscode.SymbolKind.Interface;
//             case 'output': return vscode.SymbolKind.Interface;
//             case 'input': return vscode.SymbolKind.Interface;
//             case 'inout': return vscode.SymbolKind.Interface;

//             // synth param    
//             case 'localparam': return vscode.SymbolKind.Constant;
//             case 'parameter': return vscode.SymbolKind.Constant;
//             case 'integer': return vscode.SymbolKind.Number;
//             case 'char': return vscode.SymbolKind.Number;
//             case 'float': return vscode.SymbolKind.Number;
//             case 'int': return vscode.SymbolKind.Number;

//             // unsynth param
//             case 'string': return vscode.SymbolKind.String;
//             case 'struct': return vscode.SymbolKind.Struct;
//             case 'class': return vscode.SymbolKind.Class;

//             case 'logic': return vscode.SymbolKind.Constant;
//             case 'wire': return vscode.SymbolKind.Constant;
//             case 'reg': return vscode.SymbolKind.Constant;
//             case 'net': return vscode.SymbolKind.Variable;
//             case 'bit': return vscode.SymbolKind.Boolean;
//             default: return vscode.SymbolKind.Event;
//         }
//     }
// }

// const vlogDocSymbolProvider = new VlogDocSymbolProvider();

// export {
//     vlogDocSymbolProvider
// };