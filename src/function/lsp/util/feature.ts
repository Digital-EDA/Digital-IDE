/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import { AbsPath, LinterOutput } from '../../../global';
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

function getFullSymbolInfoVlog(document: vscode.TextDocument, range: Range) {
    const comments = [];
    const currentLine = range.start.line;
    const currentText = document.lineAt(currentLine).text;

    // 往上找到第一个非空行
    let nearestFloatLine = currentLine - 1;    
    while (nearestFloatLine >= 0) {
        const linetext = document.lineAt(nearestFloatLine).text.trim();
        if (linetext.length > 0) {
            break;
        }
        nearestFloatLine --;
    }

    if (nearestFloatLine >= 0) {
        const floatLineText = document.lineAt(nearestFloatLine).text.trim();

        // 情况 1.1：上面的单行注释
        if (floatLineText.includes('//')) {
            const singleLineCommentStartIndex = floatLineText.indexOf('//');
            if (singleLineCommentStartIndex === 0) {
                const comment = floatLineText.substring(singleLineCommentStartIndex + 2);
                if (comment !== undefined && comment.length > 0) {
                    comments.push(comment);
                }
            }
        }

        // 情况 1.2：上面的多行注释
        if (floatLineText.includes('*/')) {
            const commentEndIndex = floatLineText.indexOf('*/');
            if (!floatLineText.includes('/*') || floatLineText.indexOf('/*') === 0) {
                let comment = '';
                for (let lineno = nearestFloatLine; lineno >= 0; -- lineno) {
                    const linetext = document.lineAt(lineno).text;
                    const commentStartIndex = linetext.indexOf('/*');
    
                    if (commentStartIndex > -1 && (lineno < nearestFloatLine || commentEndIndex > commentStartIndex)) {
                        let clearLineText = linetext.substring(commentStartIndex + 2).trim();                        
                        
                        if (lineno === nearestFloatLine) {
                            clearLineText = clearLineText.substring(0, clearLineText.indexOf('*/'));
                        }

                        if (clearLineText.startsWith('*')) {
                            clearLineText = clearLineText.substring(1).trim();
                        }
                        if (clearLineText.length > 0) {
                            comment = clearLineText + '\n\n' + comment;
                        }
                        break;
                    } else {
                        let clearLineText = linetext.trim();
                        if (lineno === nearestFloatLine) {
                            clearLineText = clearLineText.substring(0, clearLineText.indexOf('*/'));
                        }

                        if (clearLineText.startsWith('*')) {
                            clearLineText = clearLineText.substring(1).trim();
                        }

                        if (clearLineText.length > 0) {
                            comment = clearLineText + '\n\n' + comment;
                        }
                    }
                }
                
                comment = comment.trim();
                if (comment.length > 0) {
                    comments.push(comment);
                }
            }

        }
    }

    // 情况 2.1：单行注释
    if (currentText.includes('//')) {
        const singleLineCommentStartIndex = currentText.indexOf('//');
        const comment = currentText.substring(singleLineCommentStartIndex + 2);
        if (comment !== undefined && comment.length > 0) {
            comments.push(comment);
        }
    }

    // 情况 2.2：多行注释
    if (currentText.includes('/*')) {
        const commentStartIndex = currentText.indexOf('/*');
        let comment = '';
        for (let lineno = currentLine; lineno < document.lineCount; ++ lineno) {
            const linetext = document.lineAt(lineno).text;
            const commentEndIndex = linetext.indexOf('*/');
            if (commentEndIndex > -1 && (lineno > currentLine || commentEndIndex > commentStartIndex)) {
                let clearLineText = linetext.substring(0, commentEndIndex).trim();

                if (lineno === currentLine) {
                    clearLineText = clearLineText.substring(clearLineText.indexOf('/*') + 2).trim();
                }

                if (clearLineText.startsWith('*')) {
                    clearLineText = clearLineText.substring(1).trim();
                }
                comment += clearLineText + '\n';
                break;
            } else {
                let clearLineText = linetext.trim();
                if (clearLineText.startsWith('*')) {
                    clearLineText = clearLineText.substring(1).trim();
                }
                comment += clearLineText + '\n';
            }
        }

        comment = comment.trim();
        if (comment.length > 0) {
            comments.push(comment);
        }
    }

    return comments;
}

function getFullSymbolInfoVhdl() {
    const comments = [];

}

async function getFullSymbolInfo(document: vscode.TextDocument, range: Range, nonblank: RegExp, l_comment_symbol: string, l_comment_regExp: RegExp): Promise<string> {
    const comments = [];

    if (document.languageId !== 'vhdl') {
        comments.push(...getFullSymbolInfoVlog(document, range));
        let resultComment = '';
        for (const c of comments) {
            resultComment += c.trim() + '<br>';
        }
    
        return resultComment;
    } 


    let content = '';
    let is_b_comment = false;
    let line = range.start.line + 1;

    // vscode 的行编号从 0 开始算
    const firstLine = range.start.line - 1;
 
    while (line) {
        line --;
        content = document.lineAt(line).text;
        LinterOutput.report(content);
               
        // 首先判断该行是否是空白
        if (content.trim().length === 0) {
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
        // 判断该行是否存在块注释
        let b_comment_end_index = content.indexOf('*/');

        if (l_comment_index >= 0) {
            let before_l_comment = content.slice(0, l_comment_index);
            // 判断当前的行注释的注释前面是不是还有字符串
            if (!before_l_comment.match(nonblank) || line === firstLine) {
                const l_comment = content.slice(l_comment_index, content.length) + '\n';                                
                comments.push(l_comment);
                break; 
            }
            // 否则该行全为该定义的注释
            comments.push(content + '\n');

        } else if (b_comment_end_index >= 0) {
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