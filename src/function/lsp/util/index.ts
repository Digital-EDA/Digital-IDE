import * as vscode from 'vscode';

import { transferVlogNumber, getSymbolComment, getSymbolComments } from './feature';

const { SymbolResult, Position, CommentResult, Range, Module, Instance, 
        HDLParam, ModPort, ModParam } = require('../../../HDLparser');



const vlogKeyword = new Set([
    '`include', '`define', 'input', 'output', 'inout', 'module', 'endmodule',
    'wire', 'reg', 'parameter', 'always', 'assign', 'if', 'else', 'begin', 'end',
    'case', 'endcase', 'posedge', 'negedge', 'or', 'default', 'while', 'and', '`timescale',
    'or', 'xor', 'initial', 'function', 'endfunction', 'force', 'pulldown'
]);


/**
 * @returns {Array<vscode.CompletionItem>}
 */
function getVlogKeywordItem() {
    const vlogKeywordItem = [];
    for (const keyword of vlogKeyword) {
        const clItem = new vscode.CompletionItem(keyword, vscode.CompletionItemKind.Keyword);
        clItem.detail = "keyword";
        vlogKeywordItem.push(clItem);
    }
    return vlogKeywordItem;
}


/**
 * 
 * @param {string} singleWord 
 * @returns {boolean}
 */
function isVlogKeyword(singleWord) {
    return vlogKeyword.has(singleWord);
}


/**
 * @description get the last single word in current line
 * @param {string} prefixString 
 * @returns {string}
 */
function getLastSingleWord(prefixString) {
    prefixString = prefixString.trim();
    const length = prefixString.length;
    if (length == 0) {
        return '';
    }
    const wordCharacters = [];
    let alphaReg = /[`_0-9A-Za-z]/;
    for (let i = length - 1; i >= 0; -- i) {
        const ch = prefixString[i];
        if (alphaReg.test(ch)) {
            wordCharacters.push(ch);
        } else {
            break;
        }
    }
    return wordCharacters.reverse().join('');
}


/**
 * @description get the single word at hover
 * @param {string} lineText 
 * @param {number} character 
 */
function getSingleWordAtCurrentPosition(lineText, character) {
    let alphaReg = /[`_0-9A-Za-z]/;
    if (alphaReg.test(lineText[character])) {
        const leftPart = [];
        const rightPart = [];
        const length = lineText.length;
        for (let i = character - 1; i >= 0; -- i) {
            const ch = lineText[i];
            if (alphaReg.test(ch)) {
                leftPart.push(ch);
            } else {
                break;
            }
        }

        for (let i = character + 1; i < length; ++ i) {
            const ch = lineText[i];
            if (alphaReg.test(ch)) {
                rightPart.push(ch);
            } else {
                break;
            }
        }

        const leftWord = leftPart.reverse().join('');
        const rightWord = rightPart.join('');
        return leftWord + lineText[character] + rightWord;
    } else {
        return "";
    }
}

/**
 * @param {Position} position_a 
 * @param {Position} position_b 
 * @returns {boolean}
 */
function positionAfter(position_a, position_b) {
    return position_a.line > position_b.line || (
           position_a.line == position_b.line && 
           position_a.character > position_b.character);
}


/**
 * @param {Position} position_a 
 * @param {Position} position_b 
 * @returns {boolean}
 */
function positionEqual(position_a, position_b) {
    return position_a.line == position_b.line &&
           position_a.character == position_b.character;
}


/**
 * @description position_a behind or equal to position_b
 * @param {Position} position_a 
 * @param {Position} position_b 
 * @returns {boolean}
 */
function positionAfterEqual(position_a, position_b) {
    return positionAfter(position_a, position_b) || 
           positionEqual(position_a, position_b);
}



/**
 * @description filter the symbol result item that exceed the scope
 * @param {vscode.Position} position
 * @param {Array<SymbolResult>} symbolResults
 * @returns {{module : SymbolResult, symbols : Array<SymbolResult>}}
 */
function filterSymbolScope(position, symbolResults) {
    if (!symbolResults) {
        return null;
    }
    const parentModules = symbolResults.filter(item => 
        item.type == 'module' && 
        positionAfterEqual(position, item.start) &&
        positionAfterEqual(item.end, position)
    );

    if (parentModules.length == 0) {
        // TODO : macro
        return null;
    }

    const parentModule = parentModules[0];
    const symbols = symbolResults.filter(item => 
        item != parentModule &&
        positionAfterEqual(item.start, parentModule.start) &&
        positionAfterEqual(parentModule.end, item.end));
    
    return {
        module : parentModule,
        symbols : symbols
    };
}



/**
 * @param {vscode.TextDocument} document
 * @param {Position} position 
 * @param {Array<CommentResult>} comments 
 */
function isInComment(document, position, comments) {
    if (!comments) {
        return false;
    }
    // remove the situation that   <cursor> // comment
    const lineText = document.lineAt(position).text;
    const singleCommentIndex = lineText.indexOf('//');
    if (singleCommentIndex != -1) {
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

        const originalPosition = new Position(currentLine, position.character);

        if (positionAfterEqual(originalPosition, startPosition) &&
            positionAfterEqual(endPosition, originalPosition)) {
            return true;
        }
    }
    return false;
}



/**
 * @param {vscode.Position} position 
 * @param {object} includes 
 * @returns {{name: string, start: Position, end: Position}}
 */
function matchInclude(position, includes) {
    if (!includes) {
        return null;
    }
    for (const includeString of Object.keys(includes)) {
        const range = includes[includeString];
        // TODO : remove - 1 if bug is fixed
        range.start.line -= 1;
        range.end.line -= 1;
        if (positionAfterEqual(position, range.start) &&
            positionAfterEqual(range.end, position)) {

            return {
                name : includeString,
                start: range.start,
                end: range.end
            };
        }
    }
    return null;
}



/**
 * @param {vscode.Position} position 
 * @param {string} singleWord 
 * @param {object} defines
 * @returns {{name: string, value: any, range: Range}}
 */
function matchDefine(position, defines) {
    if (!defines) {
        return null;
    }

    for (const macro of Object.keys(defines)) {
        const range = defines[macro].range;
        range.start.line -= 1;
        range.end.line -= 1;
        if (positionAfterEqual(position, range.start) &&
            positionAfterEqual(range.end, position)) {
            return {
                name : macro,
                value: defines[macro].value,
                range: range
            };
        }
    }
    return null;
}




/**
 * @param {vscode.Position} position 
 * @param {string} singleWord 
 * @param {object} defines
 * @returns {{name: string, value: any, range: Range}}
 */
function matchDefineMacro(position, singleWord, defines) {
    if (!defines) {
        return null;
    }
    if (singleWord[0] != '`' || singleWord.length <= 1) {
        return null;
    }
    const targetMacro = singleWord.substring(1);
    for (const macro of Object.keys(defines)) {
        if (macro == targetMacro) {
            const range = defines[macro].range;
            const value = defines[macro].value;
            // TODO : remove - 1 if bug is fixed
            range.start.line -= 1;
            range.end.line -= 1;
            return {
                name : macro,
                value : value,
                range : range
            };
        }
    }
    return null;
}


/**
 * @param {string} singleWord single word to be matched
 * @param {Module} module
 * @returns {Instance}
 */
function matchInstance(singleWord, module) {
    if (!module) {
        console.log('warning, cannot locate module', singleWord);
        return null;
    }

    for (const inst of module.getInstances()) {
        if (singleWord == inst.type) {
            return inst;
        }
    }
    return null;
}

/**
 * @param {vscode.Position} position current cursor position
 * @param {Array<SymbolResult>} symbols all the symbols in the wrapper module
 * @param {Module} module  wrapper module
 * @param {Instance}
 */
function filterInstanceByPosition(position, symbols, module) {
    if (!symbols) {
        return null;
    }
    for (const symbol of symbols) {
        const inst = module.findInstance(symbol.name);
        if (positionAfterEqual(position, symbol.start) && 
            positionAfterEqual(symbol.end, position) &&
            inst) {
            return inst;
        }
    }
    return null;
}


/**
 * @param {Instance} inst 
 * @param {vscode.Position} position 
 * @param {string} singleWord
 * @returns {Promise<ModPort>}
 */
async function getInstPortByPosition(inst, position, singleWord) {
    if (!inst.module || !inst.instports) {
        return null;
    }
    if (positionAfterEqual(position, inst.instports.start) &&
        positionAfterEqual(inst.instports.end, position)) {
        for (const port of inst.module.ports) {
            if (port.name == singleWord) {
                return port;
            }
        }
    }
    return null;
}


/**
 * @param {Instance} inst 
 * @param {vscode.Position} position 
 * @param {string} singleWord
 * @returns {Promise<ModParam>}
 */
async function getInstParamByPosition(inst, position, singleWord) {
    if (!inst.module || !inst.instparams) {
        return null;
    }

    if (positionAfterEqual(position, inst.instparams.start) &&
        positionAfterEqual(inst.instparams.end, position)) {
        for (const param of inst.module.params) {
            if (param.name == singleWord) {
                return param;
            }
        }
    }
    return null;
}


/**
 * @param {string} lineText
 * @param {number} character
 * @returns {boolean}
 */
function isPositionInput(lineText, character) {
    let alphaReg = /[_0-9A-Za-z]/;
    for (let i = character; i >= 0; -- i) {
        const ch = lineText[i];
        if (alphaReg.test(ch)) {
            continue;
        } else if (ch == '.') {
            if (i == 0) {
                return true;
            } else if (lineText[i - 1] == ' ') {
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


/**
 * @param {string} singleWord 
 * @param {Module} module
 * @returns {ModPort} 
 */
function matchPorts(singleWord, module) {
    if (!module || module.ports.length == 0) {
        return null;
    }
    const targetPorts = module.ports.filter(port => port.name == singleWord);
    if (targetPorts.length == 0) {
        return null;
    }
    return targetPorts[0];
}


/**
 * @param {string} singleWord 
 * @param {Module} module
 * @returns {ModParam} 
 */
function matchParams(singleWord, module) {
    if (!module || module.params.length == 0) {
        return null;
    }
    const targetParams = module.params.filter(param => param.name == singleWord);
    if (targetParams.length == 0) {
        return null;
    }
    return targetParams[0];
}

/**
 * 
 * @param {ModPort} port
 * @returns {string} 
 */
function makePortDesc(port) {
    let portDesc = port.type;
    if (port.width) {
        portDesc += ' ' + port.width;
    }
    portDesc += ' ' + port.name;
    return portDesc;
}

/**
 * 
 * @param {ModParam} param
 * @returns {string} 
 */
function makeParamDesc(param) {
    let paramDesc = 'parameter ' + param.name;
    if (param.init) {
        paramDesc += ' = ' + param.init;
    }
    return paramDesc;
}


/**
 * @param {string} singleWord 
 * @param {Array<SymbolResult>} symbols
 * @returns {SymbolResult}
 */
function matchNormalSymbol(singleWord, symbols) {
    if (!symbols || Object.keys(symbols).length == 0) {
        return null;
    }
    for (const symbol of symbols) {
        if (singleWord == symbol.name) {
            return symbol;
        }
    }

    return null;
}


/**
 * @param {vscode.MarkdownString} content 
 * @param {Module} module 
 */
async function makeVlogHoverContent(content, module) {
    const portNum = module.ports.length;
    const paramNum = module.params.length;
    const instNum = module.getInstanceNum();

    const moduleUri = vscode.Uri.file(module.path);
    const thenableFileDocument = vscode.workspace.openTextDocument(moduleUri);

    const portDesc = paramNum + ' $(instance-param) ' + 
                     portNum + ' $(instance-port) ' +
                     instNum + ' $(instance-module)';


    content.appendCodeblock('module ' + module.name, 'verilog');
    content.appendText('\n');
    content.appendMarkdown(portDesc);
    content.appendText('   |   ');

    const count = {
        input: 0,
        output: 0,
        inout: 0
    };
    for (const port of module.ports) {
        count[port.type] += 1;
    }
    const ioDesc = count.input + ' $(instance-input) ' + 
                   count.output + ' $(instance-output) ' +
                   count.inout + ' $(instance-inout)';
    content.appendMarkdown(ioDesc);
    content.appendText('\n');

    content.appendMarkdown('---');

    // make document
    const fileDocument = await thenableFileDocument;
    const range = new vscode.Range(module.range.start, module.range.end);
    const moduleDefinitionCode = fileDocument.getText(range);
    content.appendCodeblock(moduleDefinitionCode, 'verilog');
}


async function searchCommentAround(uri, range) {

}

module.exports = {
    getVlogKeywordItem,
    getLastSingleWord,
    getSingleWordAtCurrentPosition,
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
    isVlogKeyword,
    makeVlogHoverContent,
    positionAfterEqual,
    getInstPortByPosition,
    getInstParamByPosition,
    makePortDesc,
    makeParamDesc,
    transferVlogNumber,
    getSymbolComment,
    getSymbolComments
};