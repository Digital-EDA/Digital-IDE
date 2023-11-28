import * as vscode from 'vscode';

import { hdlPath } from '../../../hdlFs';
import { hdlParam } from '../../../hdlParser';
import { All } from '../../../../resources/hdlParser';
import { vlogKeyword } from '../util/keyword';
import * as util from '../util';
import { MainOutput, ReportType } from '../../../global';
import { HdlLangID } from '../../../global/enum';
import { hdlSymbolStorage } from '../core';


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

        const filePath = document.fileName;
        const vlogAll = await hdlSymbolStorage.getSymbol(filePath);          
        if (!vlogAll) {
            return null;
        } else {
            const hover = await this.makeHover(document, position, vlogAll, targetWord, wordRange);
            return hover;
        }
    }

    private needSkip(document: vscode.TextDocument, position: vscode.Position, targetWord: string): boolean {
        // check keyword
        if (vlogKeyword.isKeyword(targetWord)) {
            return true;
        }

        // TODO: check comment


        return false;
    }

    private async makeHover(document: vscode.TextDocument, position: vscode.Position, all: All, targetWord: string, targetWordRange: vscode.Range): Promise<vscode.Hover | null> {
        const lineText = document.lineAt(position).text;
        const filePath = hdlPath.toSlash(document.fileName);

        // total content rendered on the hover box
        const content = new vscode.MarkdownString('', true);

        // match `include
        const includeResult = util.matchInclude(document, position, all.macro.includes);
        if (includeResult) {
            const absPath = hdlPath.rel2abs(filePath, includeResult.name);
            content.appendCodeblock(`"${absPath}"`, HdlLangID.Verilog);
            const targetRange = document.getWordRangeAtPosition(position, /[1-9a-zA-Z_\.]+/);
            return new vscode.Hover(content, targetRange);
        } else if (lineText.trim().startsWith('`include')) {
            return null;
        }

        // match macro
        const macroResult = util.matchDefineMacro(position, targetWord, all.macro.defines);
        if (macroResult) {
            const name = macroResult.name;
            const value = macroResult.value;
            content.appendCodeblock(`\`define ${name} ${value}`, HdlLangID.Verilog);
            return new vscode.Hover(content, targetWordRange);
        }
        
        // locate at one module
        const scopeSymbols = util.filterSymbolScope(position, all.content);
        if (!scopeSymbols || !scopeSymbols.module || !hdlParam.hasHdlModule(filePath, scopeSymbols.module.name)) {
            return null;
        }
        const currentModule = hdlParam.getHdlModule(filePath, scopeSymbols.module.name);
        if (!currentModule) {
            MainOutput.report('Fail to get HdlModule ' + filePath + ' ' + scopeSymbols.module.name, ReportType.Debug);
            return null;
        }

        // match instance
        const instResult = util.matchInstance(targetWord, currentModule);
        if (instResult) {
            const instModule = instResult.module;
            if (!instModule || !instResult.instModPath) {
                content.appendMarkdown('cannot find the definition of the module');
                return new vscode.Hover(content);
            }
            await util.makeVlogHoverContent(content, instModule);
            return new vscode.Hover(content);
        }


        // match port or param definition (position input)
        /** for example, when you hover the ".clk" below, the branch will be entered
        template u_template(
                 //input
                 .clk        		( clk        		),
             );
         * 
         */
        if (util.isPositionInput(lineText, position.character)) {
            console.log('enter position input');
            const currentInstResult = util.filterInstanceByPosition(position, scopeSymbols.symbols, currentModule);
            if (!currentInstResult || !currentInstResult.instModPath) {
                return null;
            }
            console.log(currentInstResult);
            
            const instParamPromise = util.getInstParamByPosition(currentInstResult, position, targetWord);
            const instPortPromise = util.getInstPortByPosition(currentInstResult, position, targetWord);
            
            const instParam = await instParamPromise;
            const instPort = await instPortPromise;

            if (instParam) {
                const paramComment = await util.searchCommentAround(currentInstResult.instModPath, instParam.range);
                const paramDesc = util.makeParamDesc(instParam);
                content.appendCodeblock(paramDesc, HdlLangID.Verilog);
                if (paramComment) {
                    content.appendCodeblock(paramComment, HdlLangID.Verilog);
                }
                return new vscode.Hover(content);
            }
            if (instPort) {
                const portComment = await util.searchCommentAround(currentInstResult.instModPath, instPort.range);
                const portDesc = util.makePortDesc(instPort);
                content.appendCodeblock(portDesc, HdlLangID.Verilog);
                if (portComment) {
                    content.appendCodeblock(portComment, HdlLangID.Verilog);
                }
                return new vscode.Hover(content);
            }

            return null;
        }
        
        
        // match params
        const paramResult = util.matchParams(targetWord, currentModule);
        if (paramResult) {
            const paramComment = await util.searchCommentAround(filePath, paramResult.range);
            const paramDesc = util.makeParamDesc(paramResult);
            content.appendCodeblock(paramDesc, HdlLangID.Verilog);
            if (paramComment) {
                content.appendCodeblock(paramComment, HdlLangID.Verilog);
            }
            return new vscode.Hover(content);
        }        

        // match ports        
        const portResult = util.matchPorts(targetWord, currentModule);
        if (portResult) {            
            const portComment = await util.searchCommentAround(filePath, portResult.range);
            const portDesc = util.makePortDesc(portResult);
            content.appendCodeblock(portDesc, HdlLangID.Verilog);            
            if (portComment) {
                content.appendCodeblock(portComment, HdlLangID.Verilog);
            }
            return new vscode.Hover(content);
        }

        // match others        
        const normalResult = util.matchNormalSymbol(targetWord, scopeSymbols.symbols);
        if (normalResult) {
            const normalComment = await util.searchCommentAround(filePath, normalResult.range);            
            const normalDesc = util.makeNormalDesc(normalResult);
            
            content.appendCodeblock(normalDesc, HdlLangID.Verilog);
            if (normalComment) {
                content.appendCodeblock(normalComment, HdlLangID.Verilog);
            }
            return new vscode.Hover(content);
        }


        // feature 1. number signed and unsigned number display
        const numberResult = util.transferVlogNumber(lineText, position.character);
        if (numberResult) {
            const bits = targetWord.length - 1;
            content.appendCodeblock(bits + "'" + targetWord, HdlLangID.Verilog);
            content.appendMarkdown("`unsigned` " + numberResult.unsigned);
            content.appendText('\n');
            content.appendMarkdown("`signed` " + numberResult.signed);
        }

        return new vscode.Hover(content);
    }
}


const vhdlHoverProvider = new VhdlHoverProvider();

export {
    vhdlHoverProvider
};