import * as vscode from 'vscode';
import * as fs from 'fs';

import * as util from '../util';
import { hdlParam } from '../../../hdlParser';
import { AbsPath, MainOutput, RelPath, ReportType } from '../../../global';
import { Define, Include, RawSymbol } from '../../../hdlParser/common';
import { HdlInstance, HdlModule } from '../../../hdlParser/core';
import { vhdlKeyword } from '../util/keyword';
import { hdlPath } from '../../../hdlFs';
import { hdlSymbolStorage } from '../core';

class VhdlCompletionProvider implements vscode.CompletionItemProvider {
    public async provideCompletionItems(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken, context: vscode.CompletionContext): Promise<vscode.CompletionItem[] | vscode.CompletionList<vscode.CompletionItem> | null | undefined> {
        // console.log('VhdlCompletionProvider');
        
        try {
            const filePath = hdlPath.toSlash(document.fileName);

            // 1. provide keyword
            const completions = this.makeKeywordItems(document, position);
            completions.push(...this.makeCompilerKeywordItems(document, position));
            completions.push(...this.makeSystemKeywordItems(document, position));

            const symbolResult = await hdlSymbolStorage.getSymbol(filePath);
            if (!symbolResult) {
                return completions;
            }

            console.log('vhdl symbol result');
            
            
            // locate at one module
            const scopeSymbols = util.filterSymbolScope(position, symbolResult.content);
            if (!scopeSymbols || 
                !scopeSymbols.module || 
                !hdlParam.hasHdlModule(filePath, scopeSymbols.module.name)) {
                // MainOutput.report('Fail to get HdlModule ' + filePath + ' ' + scopeSymbols?.module.name, ReportType.Debug);
                return completions;
            }

            // find wrapper module
            const currentModule = hdlParam.getHdlModule(filePath, scopeSymbols.module.name);
            if (!currentModule) {
                return completions;
            }

            // 3. provide modules
            const suggestModulesPromise = this.provideModules(document, position, filePath, symbolResult.macro.includes);

            // 4. provide params and ports of wrapper module
            const suggestParamsPortsPromise = this.provideParamsPorts(currentModule);

            // 5. provide nets
            const suggestNetsPromise = this.provideNets(scopeSymbols.symbols);

            // collect
            completions.push(...await suggestModulesPromise);
            completions.push(...await suggestParamsPortsPromise);
            completions.push(...await suggestNetsPromise);
            
            return completions;

        } catch (err) {
            console.log(err);
        }
    }

    private makeKeywordItems(document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
        const vhdlKeywordItem = [];
        for (const keyword of vhdlKeyword.keys()) {
            const clItem = this.makekeywordCompletionItem(keyword);
            vhdlKeywordItem.push(clItem);
        }

        return vhdlKeywordItem;
    }

    private makeCompilerKeywordItems(document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
        const items = [];
        const targetRange = document.getWordRangeAtPosition(position, /[`_0-9a-zA-Z]+/);
        const targetWord = document.getText(targetRange);
        const prefix = targetWord.startsWith('`') ? '' : '`';
        for (const keyword of vhdlKeyword.compilerKeys()) {
            const clItem = new vscode.CompletionItem(keyword, vscode.CompletionItemKind.Keyword);
            clItem.insertText = new vscode.SnippetString(prefix + keyword);
            clItem.detail = 'compiler directive';       
            items.push(clItem);
        }
        return items;
    }

    private makeSystemKeywordItems(document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
        const items = [];
        for (const keyword of vhdlKeyword.systemKeys()) {
            const clItem = new vscode.CompletionItem(keyword, vscode.CompletionItemKind.Method);
            clItem.insertText = new vscode.SnippetString('\\$' + keyword + '($1);');
            clItem.detail = 'system task';
            items.push(clItem);
        }
        return items;
    }


    private makekeywordCompletionItem(keyword: string): vscode.CompletionItem {
        const clItem = new vscode.CompletionItem(keyword, vscode.CompletionItemKind.Keyword);
        clItem.detail = 'keyword';

        switch (keyword) {
            case 'begin': clItem.insertText = new vscode.SnippetString("begin$1\nend"); break;
            case 'function': clItem.insertText = new vscode.SnippetString("function ${1:name}\n\nendfunction"); break;
            default: break;
        }
        return clItem;
    }

    private async provideModules(document: vscode.TextDocument, position: vscode.Position, filePath: AbsPath, includes: Include[]): Promise<vscode.CompletionItem[]> {
        const suggestModules: vscode.CompletionItem[] = [];

        const lspVhdlConfig = vscode.workspace.getConfiguration('function.lsp.completion.vhdl');
        const autoAddInclude: boolean = lspVhdlConfig.get('autoAddInclude', true);
        const completeWholeInstante: boolean = lspVhdlConfig.get('completeWholeInstante', true);
        
        const includePaths = new Set<AbsPath>();
        let lastIncludeLine = 0;
        for (const include of includes) {
            const absIncludePath = hdlPath.rel2abs(filePath, include.path);
            includePaths.add(absIncludePath);
            lastIncludeLine = Math.max(include.range.end.line, lastIncludeLine);
        }
        const insertPosition = new vscode.Position(lastIncludeLine, 0);
        const insertRange = new vscode.Range(insertPosition, insertPosition);
        const fileFolder = hdlPath.resolve(filePath, '..');

        // used only when completeWholeInstante is true
        let completePrefix = '';
        if (completeWholeInstante) {
            const wordRange = document.getWordRangeAtPosition(position);
            const countStart = wordRange ? wordRange.start.character : position.character;
            const spaceNumber = Math.floor(countStart / 4) * 4;
            console.log(wordRange, countStart, spaceNumber);
            
            completePrefix = ' '.repeat(spaceNumber);
        }


        // for (const module of hdlParam.getAllHdlModules()) {            
        //     const clItem = new vscode.CompletionItem(module.name, vscode.CompletionItemKind.Class);

        //     // feature 1 : auto add include path if there's no corresponding include path
        //     if (autoAddInclude && !includePaths.has(module.path)) {
        //         const relPath: RelPath = hdlPath.relative(fileFolder, module.path);
        //         const includeString = '`include "' + relPath + '"\n';
        //         const textEdit = new vscode.TextEdit(insertRange, includeString);
        //         clItem.additionalTextEdits = [textEdit];
        //     }

        //     // feature 2 : auto complete instance
        //     if (completeWholeInstante) {
        //         const snippetString = instanceVhdlCode(module, '', true);
        //         clItem.insertText = new vscode.SnippetString(snippetString);
        //     }

        //     clItem.detail = 'module';
        //     suggestModules.push(clItem);
        // }
    
        return suggestModules;
    }

    private async provideParamsPorts(module: HdlModule): Promise<vscode.CompletionItem[]> {
        if (!module) {
            return [];
        }
        const suggestParamsPorts = [];
        for (const param of module.params) {
            const clItem = new vscode.CompletionItem(param.name, vscode.CompletionItemKind.Constant);
            clItem.detail = 'param';
            suggestParamsPorts.push(clItem);
        }
    
        for (const port of module.ports) {
            const clItem = new vscode.CompletionItem(port.name, vscode.CompletionItemKind.Interface);
            clItem.detail = 'port';
            suggestParamsPorts.push(clItem);
        }
    
        return suggestParamsPorts;
    }

    private async provideNets(symbols: RawSymbol[]): Promise<vscode.CompletionItem[]> {        
        if (!symbols) {
            return [];
        }
        const suggestNets = [];
        for (const symbol of symbols) {
            if (symbol.type === 'wire' || symbol.type === 'reg') {
                const clItem = new vscode.CompletionItem(symbol.name, vscode.CompletionItemKind.Variable);
                clItem.sortText = '';
                clItem.detail = symbol.type;
                suggestNets.push(clItem);
            }
        }
        return suggestNets;
    }
};

const vhdlCompletionProvider = new VhdlCompletionProvider();

export {
    vhdlCompletionProvider
};