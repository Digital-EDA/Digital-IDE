/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import { AbsPath } from '../../../global';
import { HdlLangID } from '../../../global/enum';
import { hdlPath, hdlFile } from '../../../hdlFs';
import { Range } from '../../../hdlParser/common';

const vlogNumberReg = {
    'h' : /[0-9]+?'h([0-9a-fA-F_]+)/g,
    'b' : /[0-9]+?'b([0-1_]+)/g,
    'o' : /[0-9]+?'o([0-7_]+)/g,
};

const vhdlNumberReg = {
    'h' : /x"([0-9a-fA-F_]+)"/g,
    'b' : /([0-1_]+)"/g,
};

interface vlogNumber {
    unsigned: number
    signed: number
};

/**
 * @description recognize and transfer number
 * @param lineText 
 * @param character
 */
function transferVlogNumber(lineText: string, character: number): vlogNumber | undefined {
    let numberReg = /[0-9]/;
    let opt = null;
    let numberString = null;

    if (numberReg.test(lineText[character])) {
        const leftPart = [];
        const rightPart = [];
        const length = lineText.length;
        for (let i = character - 1; i >= 0; -- i) {
            const ch = lineText[i];
            if (numberReg.test(ch)) {
                leftPart.push(ch);
            } else if (Object.keys(vlogNumberReg).includes(ch)) {
                if (i === 0) {
                    return undefined;
                } else if (lineText[i - 1] === "'") {
                    opt = ch;
                    break;
                } else {
                    return undefined;
                }
            } else {
                return undefined;
            }
        }

        for (let i = character + 1; i < length; ++ i) {
            const ch = lineText[i];
            if (numberReg.test(ch)) {
                rightPart.push(ch);
            } else {
                break;
            }
        }

        const leftWord = leftPart.reverse().join('');
        const rightWord = rightPart.join('');
        numberString = leftWord + lineText[character] + rightWord;
    } else {
        return undefined;
    }

    if (opt && numberString) {
        return string2num(numberString, opt);
    } else {
        return undefined;
    }
}

/**
 * @description 将数字字符串转数字(包括有符号与无符号)
 * @param str 数字字符串
 * @param opt 需要转换的进制 hex | bin | oct
 */
function string2num(str: string, opt: string): vlogNumber {
    let optNumber = -1;
    switch (opt) {
        case 'h':
            optNumber = 16;
        break;
        case 'b':
            optNumber = 2;
        break;
        case 'o':
            optNumber = 8;
        break;
        default: break;
    }

    let unsigned = parseInt(str, optNumber);
    let pow = Math.pow(optNumber, str.length);

    let signed = unsigned;
    if (unsigned >= pow >> 1) {
        signed = unsigned - pow;
    }

    return {
        'unsigned' : unsigned,
        'signed' : signed,
    };
}

/**
 * @description 将二进制字符串转浮点数
 * @param bin 
 * @param exp 
 * @param fra 
 */
function bin2float(bin: string, exp: number, fra: number): number | undefined {
    if (bin.length < exp + fra +1) {
        return;
    } else {
        const bais = Math.pow(2, (exp-1))-1;
        exp = exp - bais;
        return exp;
    }
}

async function getFullSymbolInfo(document: vscode.TextDocument, range: Range, nonblank: RegExp, l_comment_symbol: string, l_comment_regExp: RegExp): Promise<string> {
    const comments = [];

    let content = '';
    let is_b_comment = false;
    let line = range.start.line + 1;
    const firstLine = range.start.line - 1;
    console.log('enter getFullSymbolInfo');
    
    while (line) {
        line --;
        content = document.lineAt(line).text;

        // 首先判断该行是否是空白
        let isblank = content.match(nonblank);
        if (!isblank) {
            continue; 
        }

        if (is_b_comment) {
            let b_comment_begin_index = content.indexOf('/*');
            if (b_comment_begin_index === -1) {
                comments.push(content + '\n');
                continue;
            }
            comments.push(content.slice(b_comment_begin_index, content.length) + '\n');
            is_b_comment = false;
            content = content.slice(0, b_comment_begin_index);
            if (content.match(nonblank)) {
                break;
            }
            continue;
        }

        // 判断该行是否存在行注释
        let l_comment_index = content.indexOf(l_comment_symbol);    
        
        if (l_comment_index >= 0) {
            let before_l_comment = content.slice(0, l_comment_index);
            if (before_l_comment.match(nonblank)) {
                // TODO : check again if bug takes place 
                comments.push(content.slice(l_comment_index, content.length) + '\n');
                break; 
            }

            // 否则该行全为该定义的注释
            comments.push(content + '\n');
            continue;
        }

        // 判断该行是否存在块注释
        let b_comment_end_index = content.indexOf('*/');
        if (b_comment_end_index >= 0) {
            b_comment_end_index += 2; 
            let behind_b_comment = content.slice(b_comment_end_index, content.length);
            behind_b_comment = del_comments(behind_b_comment, l_comment_regExp);
            if (behind_b_comment.match(nonblank)) {
                // 如果去除块注释之后还有字符则认为该注释不属于所要的
                if (line === firstLine) {
                    comments.push(content.slice(0, b_comment_end_index) + '\n');
                    is_b_comment = true;
                    continue;
                }
                break; 
            }

            comments.push(content + '\n');
            is_b_comment = true;
            continue;
        }

        // 说明既不是块注释又不是行注释所以就是到了代码块
        if (line !== firstLine) {
            break;
        }
    }

    // 清除空前行
    let resultComment = '';
    for (const c of comments.reverse()) {
        resultComment += c.trim() + '\n';
    }

    return resultComment;
}

/**
 * @description  get definition and comment of a range
 * @param path
 * @param range
 */
async function getSymbolComment(path: AbsPath, range: Range): Promise<string | null> {
    const languageId = hdlFile.getLanguageId(path);
    const uri = vscode.Uri.file(path);
    const documentPromise = vscode.workspace.openTextDocument(uri);

    // get comment reg util
    const nonblank = /\S+/g;
    const l_comment = getCommentUtilByLanguageId(languageId);
    if (l_comment) {
        const l_comment_symbol = l_comment.l_comment_symbol;
        const l_comment_regExp = l_comment.l_comment_regExp;
    
        // add definition first
        const document = await documentPromise;
        const symbolInfo = await getFullSymbolInfo(document, range, nonblank, l_comment_symbol, l_comment_regExp);        
        return symbolInfo;
    }
    return null;
}

/**
 * @description get definition and comment of a range
 * @param path
 * @param ranges
 */
async function getSymbolComments(path: string, ranges: Range[]): Promise<string[]> {
    let languageId = hdlFile.getLanguageId(path);
    const uri = vscode.Uri.file(path);
    const documentPromise = vscode.workspace.openTextDocument(uri);

    // get comment reg util
    const nonblank = /\S+/g;
    const l_comment = getCommentUtilByLanguageId(languageId);
    if (!l_comment) {
        return [];
    }
    let l_comment_symbol = l_comment.l_comment_symbol;
    let l_comment_regExp = l_comment.l_comment_regExp;

    // add definition first
    const document = await documentPromise;
    const commentPromises = [];
    const comments = [];
    for (const range of ranges) {
        const commentP = getFullSymbolInfo(document, range, nonblank, l_comment_symbol, l_comment_regExp);
        commentPromises.push(commentP);
    }

    for (const cp of commentPromises) {
        comments.push(await cp);
    }
    
    return comments;
}


interface CommentUtil {
    l_comment_symbol: string
    l_comment_regExp: RegExp
}

function getCommentUtilByLanguageId(languageId: HdlLangID): CommentUtil | undefined {
    switch (languageId) {
        case "verilog":
        case "systemverilog":
            return {
                l_comment_symbol: '//',
                l_comment_regExp:  /\/\/.*/g
            };
        case "vhdl":
            return {
                l_comment_symbol: '--',
                l_comment_regExp:  /--.*/g
            };
        default: return undefined;
    }
}

/**
 * @description delete all comment form verilog code
 * @param {string} text Verilog code input
 * @returns Verilog code output after deleting all comment content
 */
function del_comments(text: string, regExp: RegExp): string {
    let match = text.match(regExp);
    if (match !== null) {
        for (let i = 0; i < match.length; i++) {
            const element = match[i];
            const newElement = ' '.repeat(element.length);
            text = text.replace(element,newElement);
        }
    }
    return text;
}


export {
    transferVlogNumber,
    getSymbolComment,
    getSymbolComments
};