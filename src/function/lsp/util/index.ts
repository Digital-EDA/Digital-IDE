import * as vscode from 'vscode';

import { transferVlogNumber, getSymbolComment, getSymbolComments } from './feature';

import { AbsPath, AllowNull } from '../../../global';
import { Position, Range, HdlModulePort, HdlModuleParam, CommentResult, RawSymbol, Define, Include, makeVscodePosition } from '../../../hdlParser/common';
import { HdlModule, HdlInstance, hdlParam } from '../../../hdlParser/core';

// eslint-disable-next-line @typescript-eslint/naming-convention
const Unknown = 'Unknown';

interface MatchedSymbol {
    name: string, 
    value: any, 
    range: Range
};


interface ModuleScope {
    module: RawSymbol,
    symbols: RawSymbol[]
};


function transformRange(range: Range | vscode.Range, lineOffset: number = 0, characterOffset: number = 0, 
                        endLineOffset: number | undefined = undefined, endCharacterOffset: number | undefined = undefined): vscode.Range {
    const start = range.start;
    const end = range.end;
    const startPosition = new vscode.Position(start.line + lineOffset, start.character + characterOffset);
    endLineOffset = endLineOffset ? endLineOffset : lineOffset;
    endCharacterOffset = endCharacterOffset ? endLineOffset : characterOffset;
    const endPosition = new vscode.Position(end.line + endLineOffset, end.character + endCharacterOffset);
    return new vscode.Range(startPosition, endPosition);
}


function positionAfter(positionA: Position, positionB: Position): boolean {
    return positionA.line > positionB.line || (
           positionA.line === positionB.line && 
           positionA.character > positionB.character);
}


function positionEqual(positionA: Position, positionB: Position): boolean {
    return positionA.line === positionB.line &&
           positionA.character === positionB.character;
}


/**
 * @description positionA behind or equal to positionB
 */
function positionAfterEqual(positionA: Position, positionB: Position): boolean {
    return positionAfter(positionA, positionB) || 
           positionEqual(positionA, positionB);
}



/**
 * @description filter the symbol result item that exceed the scope
 */
function filterSymbolScope(position: vscode.Position, rawSymbols: RawSymbol[]): AllowNull<ModuleScope> {
    if (!rawSymbols) {
        return null;
    }
    const parentModules = rawSymbols.filter(item => 
        item.type === 'module' && 
        positionAfterEqual(position, item.range.start) &&
        positionAfterEqual(item.range.end, position)
    );

    if (parentModules.length === 0) {
        // TODO : macro
        return null;
    }

    const parentModule = parentModules[0];
    const symbols = rawSymbols.filter(item => 
        item !== parentModule &&
        positionAfterEqual(item.range.start, parentModule.range.start) &&
        positionAfterEqual(parentModule.range.end, item.range.end));
    
    return {
        module : parentModule,
        symbols : symbols
    };
}


function isInComment(document: vscode.TextDocument, position: Position, comments: CommentResult[]): boolean {
    if (!comments) {
        return false;
    }
    // remove the situation that   <cursor> // comment
    const lineText = document.lineAt(makeVscodePosition(position)).text;
    const singleCommentIndex = lineText.indexOf('//');
    if (singleCommentIndex !== -1) {
        return position.character >= singleCommentIndex;
    }

    const currentLine = position.line + 1;
    for (const comment of comments) {
        const commentLine = comment.start.line;
        if (commentLine > currentLine) {
            continue;
        }
        const startPosition = new vscode.Position(commentLine, 0);
        const startOffset = document.offsetAt(startPosition);
        const endPosition = document.positionAt(startOffset + comment.length);

        const originalPosition: Position = {line: currentLine, character: position.character};

        if (positionAfterEqual(originalPosition, startPosition) &&
            positionAfterEqual(endPosition, originalPosition)) {
            return true;
        }
    }
    return false;
}




function matchInclude(document: vscode.TextDocument, position: vscode.Position, includes: Include[]) : AllowNull<MatchedSymbol> {
    const selectFileRange = document.getWordRangeAtPosition(position, /[\.\\\/_0-9A-Za-z]+/);
    const selectFileName = document.getText(selectFileRange);    

    if (!includes) {
        return null;
    }
    for (const include of includes) {
        const range = include.range;
        if (position.line + 1 === range.start.line && selectFileName === include.path) {
            return {
                name : include.path,
                value: include.path,
                range: range
            };
        }
    }
    return null;
}



function matchDefine(position: vscode.Position, defines: Define[]) : AllowNull<MatchedSymbol> {
    if (!defines) {
        return null;
    }

    for (const define of defines) {
        const range = define.range;
        if (positionAfterEqual(position, range.start) &&
            positionAfterEqual(range.end, position)) {
            return {
                name : define.name,
                value: define.replacement,
                range: range
            };
        }
    }
    return null;
}



function matchDefineMacro(position: vscode.Position, singleWord: string, defines: Define[]) : AllowNull<MatchedSymbol> {
    if (!defines) {
        return null;
    }
    if (singleWord[0] !== '`' || singleWord.length <= 1) {
        return null;
    }
    const targetMacro = singleWord.substring(1);
    for (const define of defines) {
        if (define.name === targetMacro) {
            const range = define.range;
            return {
                name : define.name,
                value : define.replacement,
                range : range
            };
        }
    }
    return null;
}


function matchInstance(singleWord: string, module: HdlModule): AllowNull<HdlInstance> {
    for (const inst of module.getAllInstances()) {
        if (singleWord === inst.type) {
            return inst;
        }
    }
    return null;
}


function filterInstanceByPosition(position: vscode.Position, symbols: RawSymbol[], module: HdlModule): AllowNull<HdlInstance> {
    if (!symbols) {
        return null;
    }
    for (const symbol of symbols) {
        const inst = module.getInstance(symbol.name);
                
        if (positionAfterEqual(position, symbol.range.start) && 
            positionAfterEqual(symbol.range.end, position) &&
            inst) {
            
            return inst;
        }
    }
    return null;
}


async function getInstPortByPosition(inst: HdlInstance, position: vscode.Position, singleWord: string): Promise<AllowNull<HdlModulePort>> {
    if (!inst.module || !inst.instports) {
        return null;
    }

    const instportRange = transformRange(inst.instports, -1, 0);

    if (positionAfterEqual(position, instportRange.start) &&
        positionAfterEqual(instportRange.end, position)) {
        for (const port of inst.module.ports) {
            if (port.name === singleWord) {
                return port;
            }
        }
    }
    return null;
}


async function getInstParamByPosition(inst: AllowNull<HdlInstance>, position: vscode.Position, singleWord: string): Promise<AllowNull<HdlModuleParam>> {
    if (!inst || !inst.module || !inst.instparams) {
        return null;
    }

    const instParamRange = transformRange(inst.instparams, -1, 0);

    if (positionAfterEqual(position, instParamRange.start) &&
        positionAfterEqual(instParamRange.end, position)) {
        for (const param of inst.module.params) {
            if (param.name === singleWord) {
                return param;
            }
        }
    }
    return null;
}


function isPositionInput(lineText: string, character: number): boolean {
    const alphaReg = /[_0-9A-Za-z]/;
    for (let i = character; i >= 0; -- i) {
        const ch = lineText[i];
        if (alphaReg.test(ch)) {
            continue;
        } else if (ch === '.') {
            if (i === 0) {
                return true;
            } else if (lineText[i - 1] === ' ') {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
    return false;
}


function matchPorts(singleWord: string, module: HdlModule): AllowNull<HdlModulePort> {    
    if (!module || module.ports.length === 0) {
        return null;
    }
    const targetPorts = module.ports.filter(port => port.name === singleWord);
    if (targetPorts.length === 0) {
        return null;
    }
    return targetPorts[0];
}


function matchParams(singleWord: string, module: HdlModule): AllowNull<HdlModuleParam> {    
    if (module.params.length === 0) {
        return null;
    }
    
    const targetParams = module.params.filter(param => param.name === singleWord);
    if (targetParams.length === 0) {
        return null;
    }
    return targetParams[0];
}


function makePortDesc(port: HdlModulePort): string {
    let portDesc: string = port.type;
    if (port.width && port.width !== Unknown) {
        portDesc += ' ' + port.width;
    }
    portDesc += ' ' + port.name;
    return portDesc;
}


function makeParamDesc(param: HdlModuleParam): string {
    let paramDesc = 'parameter ' + param.name;
    if (param.init && param.init !== Unknown) {
        paramDesc += ' = ' + param.init;
    }
    return paramDesc;
}

function makeNormalDesc(normal: RawSymbol): string {
    const width = normal.width ? normal.width : '';
    const signed = normal.signed === 1 ? 'signed' : '';
    let desc = normal.type + ' ' + signed + ' ' + width + ' ' + normal.name;
    if (normal.init) {
        desc += ' = ' + normal.init;
    }
    return desc;
}


function matchNormalSymbol(singleWord: string, symbols: RawSymbol[]): AllowNull<RawSymbol> {
    if (!symbols || Object.keys(symbols).length === 0) {
        return null;
    }
    for (const symbol of symbols) {
        if (singleWord === symbol.name) {
            return symbol;
        }
    }

    return null;
}


async function makeVlogHoverContent(content: vscode.MarkdownString, module: HdlModule) {
    const portNum = module.ports.length;
    const paramNum = module.params.length;
    const instNum = module.getInstanceNum();

    const moduleUri = vscode.Uri.file(module.path);
    const thenableFileDocument = vscode.workspace.openTextDocument(moduleUri);

    const portDesc =  ' $(instance-param) ' + paramNum +
                      ' $(instance-port) ' + portNum +
                      ' $(instance-module)' + instNum;


    content.appendMarkdown(portDesc);
    content.appendText('   |   ');

    const count = {
        input: 0,
        output: 0,
        inout: 0
    };
    for (const port of module.ports) {
        count[port.type as keyof typeof count] += 1;
    }
    const ioDesc = ' $(instance-input) ' + count.input +
                   ' $(instance-output) ' + count.output +
                   ' $(instance-inout)' + count.inout;
    content.appendMarkdown(ioDesc);
    content.appendText('\n');

    content.appendMarkdown('---');

    // make document
    const fileDocument = await thenableFileDocument;
    const range = transformRange(module.range, -1, 0, 1);    
    const moduleDefinitionCode = fileDocument.getText(range);
    content.appendCodeblock(moduleDefinitionCode, 'verilog');
}


async function searchCommentAround(path: AbsPath, range: Range): Promise<string | null> {
    const targetRange = transformRange(range, -1, 0);
    const comment = await getSymbolComment(path, targetRange);
    return comment;
}

export {
    transformRange,
    filterSymbolScope,
    filterInstanceByPosition,
    isPositionInput,
    isInComment,
    matchInclude,
    matchDefine,
    matchDefineMacro,
    matchInstance,
    matchPorts,
    matchParams,
    matchNormalSymbol,
    makeVlogHoverContent,
    positionAfterEqual,
    getInstPortByPosition,
    getInstParamByPosition,
    makePortDesc,
    makeParamDesc,
    makeNormalDesc,
    transferVlogNumber,
    searchCommentAround,
};