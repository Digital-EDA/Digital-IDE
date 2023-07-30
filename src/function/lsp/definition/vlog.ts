import * as vscode from 'vscode';
import * as vsctm from 'vscode-textmate';

import { hdlPath } from '../../../hdlFs';
import { hdlParam } from '../../../hdlParser';
import { All } from '../../../../resources/hdlParser';
import { vlogKeyword } from '../util/keyword';
import * as util from '../util';
import { MainOutput, ReportType } from '../../../global';
import { vlogSymbolStorage } from '../core';


class VlogDefinitionProvider implements vscode.DefinitionProvider {
    public async provideDefinition(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken): Promise<vscode.Location | vscode.LocationLink[] | null> {
        // console.log('VlogDefinitionProvider');
        
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
        const vlogAll = await vlogSymbolStorage.getSymbol(filePath);
        if (!vlogAll) {
            return null;
        } else {
            const location = await this.makeDefinition(document, position, vlogAll, targetWord, wordRange);
            return location;
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

    private async makeDefinition(document: vscode.TextDocument, position: vscode.Position, all: All, targetWord: string, targetWordRange: vscode.Range): Promise<vscode.Location | vscode.LocationLink[] | null> {
        const filePath = hdlPath.toSlash(document.fileName);
        const lineText = document.lineAt(position).text;

        // match `include        
        const includeResult = util.matchInclude(document, position, all.macro.includes);
        
        if (includeResult) {
            const absPath = hdlPath.rel2abs(filePath, includeResult.name);
            const targetFile = vscode.Uri.file(absPath);
            const targetPosition = new vscode.Position(0, 0);
            const targetRange = new vscode.Range(targetPosition, targetPosition);
            const originSelectionRange = document.getWordRangeAtPosition(position, /["\.\\\/_0-9A-Za-z]+/);
            const link: vscode.LocationLink = { targetUri: targetFile, targetRange, originSelectionRange };
            return [link];
        }


        // match macro
        const macroResult = util.matchDefineMacro(position, targetWord, all.macro.defines);
        if (macroResult) {
            const targetRange = util.transformRange(macroResult.range, -1, -1);
            const link: vscode.LocationLink = { targetUri: document.uri, targetRange: targetRange, originSelectionRange: targetWordRange };
            return [link];
        }

        // locate at one module
        const scopeSymbols = util.filterSymbolScope(position, all.content);
        if (!scopeSymbols || !scopeSymbols.module) {
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
                return null;
            }
            const targetFile = vscode.Uri.file(instResult.instModPath);
            const targetRange = util.transformRange(instModule.range, -1, 0, 1);
            const link: vscode.LocationLink = { targetUri: targetFile, targetRange };
            return [link];
        }

        // match port or param definition (position input)
        if (util.isPositionInput(lineText, position.character)) {
            const currentInstResult = util.filterInstanceByPosition(position, scopeSymbols.symbols, currentModule);
            if (!currentInstResult || !currentInstResult.instModPath) {
                return null;
            }
            const instParamPromise = util.getInstParamByPosition(currentInstResult, position, targetWord);
            const instPortPromise = util.getInstPortByPosition(currentInstResult, position, targetWord);

            const instParam = await instParamPromise;
            const instPort = await instPortPromise;
            const instModPathUri = vscode.Uri.file(currentInstResult.instModPath);            

            if (instParam) {
                const targetRange = util.transformRange(instParam.range, -1, 0);
                const link: vscode.LocationLink = { targetUri: instModPathUri, targetRange };
                return [link];
            }
            if (instPort) {
                const targetRange = util.transformRange(instPort.range, -1, 0);
                const link: vscode.LocationLink = { targetUri: instModPathUri, targetRange };
                return [link];
            }
        }    
        

        // match params
        const paramResult = util.matchParams(targetWord, currentModule);
        
        if (paramResult) {
            const targetRange = util.transformRange(paramResult.range, -1, 0);
            const link: vscode.LocationLink = { targetUri: document.uri, targetRange };
            return [link];
        }

        // match ports
        const portResult = util.matchPorts(targetWord, currentModule);        

        if (portResult) {
            const targetRange = util.transformRange(portResult.range, -1, 0);
            const link: vscode.LocationLink = { targetUri: document.uri, targetRange };
            return [link];
        }

        // match others
        const normalResult = util.matchNormalSymbol(targetWord, scopeSymbols.symbols);
        if (normalResult) {
            const targetRange = util.transformRange(normalResult.range, -1, 0);            
            const link: vscode.LocationLink = { targetUri: document.uri, targetRange };
            return [link];
        }

        return null;
    }
}

const vlogDefinitionProvider = new VlogDefinitionProvider();

export {
    vlogDefinitionProvider
};