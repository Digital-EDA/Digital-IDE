import * as vscode from 'vscode';

import { hdlPath } from '../../../hdlFs';
import { hdlParam } from '../../../hdlParser';
import { All } from '../../../../resources/hdlParser';
import { vhdlKeyword } from '../util/keyword';
import * as util from '../util';
import { MainOutput, ReportType } from '../../../global';
import { HdlLangID } from '../../../global/enum';
import { hdlSymbolStorage } from '../core';
import { RawSymbol } from '../../../hdlParser/common';


class VhdlHoverProvider implements vscode.HoverProvider {
    public async provideHover(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken): Promise<vscode.Hover | null> {
        // console.log('VhdlHoverProvider');

        // get current words
        const wordRange = document.getWordRangeAtPosition(position, /[`_0-9A-Za-z]+/);
        if (!wordRange) {
            return null;
        }
        const targetWord = document.getText(wordRange);

        // check if need skip
        if (this.needSkip(document, position, targetWord)) {
            return null;
        }

        const keywordHover = this.getKeywordHover(targetWord);
        if (keywordHover) {
            return keywordHover;
        }

        const filePath = document.fileName;
        const vhdlAll = await hdlSymbolStorage.getSymbol(filePath);
        if (!vhdlAll) {
            return null;
        } else {
            const hover = await this.makeHover(document, position, vhdlAll, targetWord, wordRange);
            return hover;
        }
    }

    private getKeywordHover(words: string): vscode.Hover | undefined {
        const content = new vscode.MarkdownString('', true);
        if (vhdlKeyword.compilerKeys().has(words)) {
            content.appendMarkdown('IEEE Library data type');
            return new vscode.Hover(content);
        }
        return undefined;
    }

    private needSkip(document: vscode.TextDocument, position: vscode.Position, targetWord: string): boolean {
        // check keyword
        if (vhdlKeyword.isKeyword(targetWord)) {
            return true;
        }

        // TODO: check comment


        return false;
    }

    private async makeHover(document: vscode.TextDocument, position: vscode.Position, all: All, targetWord: string, targetWordRange: vscode.Range): Promise<vscode.Hover | null> {
        const lineText = document.lineAt(position).text;
        const filePath = hdlPath.toSlash(document.fileName);

        // locate at one entity or architecture
        // TODO: remove it after adjust of backend
        const rawSymbols = [];
        for (const symbol of all.content) {
            const rawSymbol: RawSymbol = {
                name: symbol.name,
                type: symbol.type,
                parent: symbol.parent,
                range: util.transformRange(symbol.range, -1),
                signed: symbol.signed,
                netType: symbol.netType
            };
            rawSymbols.push(rawSymbol);
        }

        const moduleScope = util.locateVhdlSymbol(position, rawSymbols);

        if (!moduleScope) {
            return null;
        }

        const scopeType = moduleScope.module.type;
        if (scopeType === 'architecture') {
            return await this.makeArchitectureHover(filePath, targetWord, targetWordRange, moduleScope);
        } else if (scopeType === 'entity') {
            return await this.makeEntityHover(filePath, targetWord, targetWordRange, moduleScope);
        }

        return null;
    }

    private async makeArchitectureHover(filePath: string, targetWord: string, targetWordRange: vscode.Range, moduleScope: util.ModuleScope): Promise<vscode.Hover | null> {
        const architecture = moduleScope.module;
        const content = new vscode.MarkdownString('', true);

        // point to the entity of the architecture
        if (architecture.parent && architecture.parent === targetWord) {
            const entity = hdlParam.getHdlModule(filePath, architecture.parent);
            if (entity) {
                await util.makeVhdlHoverContent(content, entity);
                return new vscode.Hover(content);
            }
        }

        // filter defined signal
        for (const symbol of moduleScope.symbols) {
            if (symbol.name === targetWord) {
                content.appendCodeblock(symbol.type, 'vhdl');
                return new vscode.Hover(content);
            }
        }

        // inner variable mapping to entity
        if (architecture.parent) {
            const entity = hdlParam.getHdlModule(filePath, architecture.parent);
            if (entity) {
                // find params definitio
                for (const param of entity.params) {
                    if (param.name === targetWord) {
                        const desc = util.makeParamDesc(param);
                        content.appendCodeblock(desc, 'vhdl');
                        return new vscode.Hover(content);
                    }
                }
                // find ports definition
                for (const port of entity.ports) {
                    if (port.name === targetWord) {
                        const desc = util.makePortDesc(port);
                        content.appendCodeblock(desc, 'vhdl');
                        return new vscode.Hover(content);
                    }
                }
            }
        }

        return null;
    }

    private async makeEntityHover(filePath: string, targetWord: string, targetWordRange: vscode.Range, moduleScope: util.ModuleScope): Promise<vscode.Hover | null> {
        const entity = hdlParam.getHdlModule(filePath, moduleScope.module.name);
        const content = new vscode.MarkdownString('', true);
        if (entity) {
            if (targetWord === entity.name) {
                await util.makeVhdlHoverContent(content, entity);
                return new vscode.Hover(content);
            }
            // find params definitio
            for (const param of entity.params) {
                if (param.name === targetWord) {
                    const desc = util.makeParamDesc(param);
                    content.appendCodeblock(desc, 'vhdl');
                    return new vscode.Hover(content);
                }
            }
            // find ports definition
            for (const port of entity.ports) {
                if (port.name === targetWord) {
                    const desc = util.makePortDesc(port);
                    content.appendCodeblock(desc, 'vhdl');
                    return new vscode.Hover(content);
                }
            }
        }
        return null;
    }
}


const vhdlHoverProvider = new VhdlHoverProvider();

export {
    vhdlHoverProvider
};