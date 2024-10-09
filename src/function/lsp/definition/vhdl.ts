import * as vscode from 'vscode';

import { hdlPath } from '../../../hdlFs';
import { hdlParam } from '../../../hdlParser';
import { vlogKeyword } from '../util/keyword';
import * as util from '../util';
import { MainOutput, ReportType } from '../../../global';
import { RawSymbol } from '../../../hdlParser/common';


// class VhdlDefinitionProvider implements vscode.DefinitionProvider {
//     public async provideDefinition(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken): Promise<vscode.Location | vscode.LocationLink[] | null> {
//         // console.log('VhdlDefinitionProvider');

//         // get current words
//         const wordRange = document.getWordRangeAtPosition(position, /[`_0-9A-Za-z]+/);
//         if (!wordRange) {
//             return null;
//         }
//         const targetWord = document.getText(wordRange);

//         // check if need skip
//         if (this.needSkip(document, position, targetWord)) {
//             return null;
//         }

//         const filePath = document.fileName;
//         const vlogAll = await hdlSymbolStorage.getSymbol(filePath);
//         if (!vlogAll) {
//             return null;
//         } else {
//             const location = await this.makeDefinition(document, position, vlogAll, targetWord, wordRange);
//             return location;
//         }
//     }

//     private needSkip(document: vscode.TextDocument, position: vscode.Position, targetWord: string): boolean {
//         // check keyword
//         if (vlogKeyword.isKeyword(targetWord)) {
//             return true;
//         }

//         // TODO: check comment


//         return false;
//     }

//     private async makeDefinition(document: vscode.TextDocument, position: vscode.Position, all: All, targetWord: string, targetWordRange: vscode.Range): Promise<vscode.Location | vscode.LocationLink[] | null> {
//         const filePath = hdlPath.toSlash(document.fileName);
//         const lineText = document.lineAt(position).text;

//         // locate at one entity or architecture
//         // TODO: remove it after adjust of backend
//         const rawSymbols = [];
//         for (const symbol of all.content) {
//             const rawSymbol: RawSymbol = {
//                 name: symbol.name,
//                 type: symbol.type,
//                 parent: symbol.parent,
//                 range: util.transformRange(symbol.range, -1),
//                 signed: symbol.signed,
//                 netType: symbol.netType
//             };
//             rawSymbols.push(rawSymbol);
//         }

//         const moduleScope = util.locateVhdlSymbol(position, rawSymbols);

//         if (!moduleScope) {
//             return null;
//         }

//         const scopeType = moduleScope.module.type;
//         if (scopeType === 'architecture') {
//             return await this.makeArchitectureDefinition(filePath, targetWord, targetWordRange, moduleScope);
//         } else if (scopeType === 'entity') {
//             return await this.makeEntityDefinition(filePath, targetWord, targetWordRange, moduleScope);
//         }

//         return null;
//     }

//     private async makeArchitectureDefinition(filePath: string, targetWord: string, targetWordRange: vscode.Range, moduleScope: util.ModuleScope): Promise<vscode.Location | vscode.LocationLink[] | null> {
//         const architecture = moduleScope.module;
//         // point to the entity of the architecture
//         if (architecture.parent && architecture.parent === targetWord) {
//             const entity = hdlParam.getHdlModule(filePath, architecture.parent);
//             if (entity) {
//                 const targetUri = vscode.Uri.file(entity.path);
//                 const targetRange = util.transformRange(entity.range, -1, 0);
//                 const link: vscode.LocationLink = { targetUri, targetRange, originSelectionRange: targetWordRange };
//                 return [ link ];
//             }
//         }

//         // filter defined signal
//         for (const symbol of moduleScope.symbols) {
//             if (symbol.name === targetWord) {
//                 const targetUri = vscode.Uri.file(filePath);
//                 const targetRange = util.transformRange(symbol.range, 0, 0);
//                 const link: vscode.LocationLink = { targetUri, targetRange, originSelectionRange: targetWordRange };
//                 return [ link ];
//             }
//         }

//         // inner variable mapping to entity
//         if (architecture.parent) {
//             const entity = hdlParam.getHdlModule(filePath, architecture.parent);
//             if (entity) {
//                 // find params definitio
//                 for (const param of entity.params) {
//                     if (param.name === targetWord) {
//                         const targetUri = vscode.Uri.file(entity.path);
//                         const targetRange = util.transformRange(param.range, -1, 0);
//                         const link: vscode.LocationLink = { targetUri, targetRange, originSelectionRange: targetWordRange };
//                         return [ link ];
//                     }
//                 }
//                 // find ports definition
//                 for (const port of entity.ports) {
//                     if (port.name === targetWord) {
//                         const targetUri = vscode.Uri.file(entity.path);
//                         const targetRange = util.transformRange(port.range, -1, 0);
//                         const link: vscode.LocationLink = { targetUri, targetRange, originSelectionRange: targetWordRange };
//                         return [ link ];
//                     }
//                 }
//             }
//         }
//         return null;
//     }

//     private async makeEntityDefinition(filePath: string, targetWord: string, targetWordRange: vscode.Range, moduleScope: util.ModuleScope): Promise<vscode.Location | vscode.LocationLink[] | null> {
//         const entity = hdlParam.getHdlModule(filePath, moduleScope.module.name);
//         if (entity) {
//             if (targetWord === entity.name) {
//                 const targetUri = vscode.Uri.file(entity.path);
//                 const targetRange = util.transformRange(entity.range, -1, 0);
//                 const link: vscode.LocationLink = { targetUri, targetRange, originSelectionRange: targetWordRange };
//                 return [ link ];
//             }
//             // find params definitio
//             for (const param of entity.params) {
//                 if (param.name === targetWord) {
//                     const targetUri = vscode.Uri.file(entity.path);
//                     const targetRange = util.transformRange(param.range, -1, 0);
//                     const link: vscode.LocationLink = { targetUri, targetRange, originSelectionRange: targetWordRange };
//                     return [ link ];
//                 }
//             }
//             // find ports definition
//             for (const port of entity.ports) {
//                 if (port.name === targetWord) {
//                     const targetUri = vscode.Uri.file(entity.path);
//                     const targetRange = util.transformRange(port.range, -1, 0);
//                     const link: vscode.LocationLink = { targetUri, targetRange, originSelectionRange: targetWordRange };
//                     return [ link ];
//                 }
//             }
//         }
//         return null;
//     }
// }

// const vhdlDefinitionProvider = new VhdlDefinitionProvider();

// export {
//     vhdlDefinitionProvider
// };