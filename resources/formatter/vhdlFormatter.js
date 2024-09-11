"use strict";

class Beautifuler {
    beauty(input, options) {
        let new_line_after_symbols = new NewLineSettings();
        new_line_after_symbols.newLineAfter = ["then", ";"];
        new_line_after_symbols.noNewLineAfter = ["port", "generic"];
        let settings = this.getDefaultBeautifierSettings(new_line_after_symbols);
        settings.SignAlignSettings = new signAlignSettings(true, true, "local", ["PORT", "GENERIC"]);

        const result = this.beautifyIntern(input, options);
        if (result.err !== null) {
            console.error(`-- [ERROR]: could not beautify`);
        }
        return result.data;
    }

    beautifyIntern(input, settings) {
        try {
            const data = beautify(input, settings);
            return {
                data,
                err: null,
            };
        }
        catch (err) {
            return {
                data: null,
                err,
            };
        }
    }

    getDefaultBeautifierSettings(newLineSettings, signAlignSettings = null, indentation = "  ") {
        return new BeautifierSettings(false, false, false, signAlignSettings, "lowercase", "lowercase", indentation, newLineSettings, "\r\n");
    }
}
exports.Beautifuler = Beautifuler;

// VHDLFormatter
const ILEscape = "@@";
const ILCommentPrefix = ILEscape + "comments";
const ILIndentedReturnPrefix = ILEscape;
const ILQuote = "⨵";
const ILSingleQuote = "⦼";
const ILBackslash = "⨸";
const ILSemicolon = "⨴";
var FormatMode;
(function (FormatMode) {
    FormatMode[FormatMode["Default"] = 0] = "Default";
    FormatMode[FormatMode["EndsWithSemicolon"] = 1] = "EndsWithSemicolon";
    FormatMode[FormatMode["CaseWhen"] = 2] = "CaseWhen";
    FormatMode[FormatMode["IfElse"] = 3] = "IfElse";
    FormatMode[FormatMode["PortGeneric"] = 4] = "PortGeneric";
})(FormatMode || (FormatMode = {}));
let Mode = FormatMode.Default;
exports.RemoveAsserts = exports.ApplyNoNewLineAfter = exports.beautify3 = exports.beautifySemicolonBlock = exports.beautifyPackageIsNewBlock = exports.beautifyComponentBlock = exports.beautifyCaseBlock = exports.AlignSign = exports.AlignSigns = exports.beautifyPortGenericBlock = exports.FormattedLineToString = exports.FormattedLine = exports.beautify = exports.BeautifierSettings = exports.signAlignSettings = exports.SetNewLinesAfterSymbols = exports.NewLineSettings = void 0;
class NewLineSettings {
    constructor() {
        this.newLineAfter = [];
        this.noNewLineAfter = [];
    }
    newLineAfterPush(keyword) {
        this.newLineAfter.push(keyword);
    }
    noNewLineAfterPush(keyword) {
        this.noNewLineAfter.push(keyword);
    }
    push(keyword, addNewLine) {
        let str = addNewLine.toLowerCase();
        if (str == "none") {
            return;
        }
        else if (!str.startsWith("no")) {
            this.newLineAfterPush(keyword);
        }
        else {
            this.noNewLineAfterPush(keyword);
        }
    }
}
exports.NewLineSettings = NewLineSettings;
function ConstructNewLineSettings(dict) {
    let settings = new NewLineSettings();
    for (let key in dict) {
        settings.push(key, dict[key]);
    }
    return settings;
}
String.prototype.regexCount = function (pattern) {
    if (pattern.flags.indexOf("g") < 0) {
        pattern = new RegExp(pattern.source, pattern.flags + "g");
    }
    return (this.match(pattern) || []).length;
};
String.prototype.count = function (text) {
    return this.split(text).length - 1;
};
String.prototype.regexStartsWith = function (pattern) {
    var searchResult = this.search(pattern);
    return searchResult == 0;
};
String.prototype.regexIndexOf = function (pattern, startIndex) {
    startIndex = startIndex || 0;
    var searchResult = this.substr(startIndex).search(pattern);
    return (-1 === searchResult) ? -1 : searchResult + startIndex;
};
String.prototype.regexLastIndexOf = function (pattern, startIndex) {
    pattern = (pattern.global) ? pattern :
        new RegExp(pattern.source, 'g' + (pattern.ignoreCase ? 'i' : '') + (pattern.multiline ? 'm' : ''));
    if (typeof (startIndex) === 'undefined') {
        startIndex = this.length;
    }
    else if (startIndex < 0) {
        startIndex = 0;
    }
    const stringToWorkWith = this.substring(0, startIndex + 1);
    let lastIndexOf = -1;
    let nextStop = 0;
    let result;
    while ((result = pattern.exec(stringToWorkWith)) != null) {
        lastIndexOf = result.index;
        pattern.lastIndex = ++nextStop;
    }
    return lastIndexOf;
};
String.prototype.reverse = function () {
    return this.split('').reverse().join('');
};
String.prototype.convertToRegexBlockWords = function () {
    let result = new RegExp("(" + this + ")([^\\w]|$)");
    return result;
};
Array.prototype.convertToRegexBlockWords = function () {
    let wordsStr = this.join("|");
    let result = new RegExp("(" + wordsStr + ")([^\\w]|$)");
    return result;
};
function EscapeComments(arr) {
    var comments = [];
    var count = 0;
    for (var i = 0; i < arr.length; i++) {
        var line = arr[i];
        var commentStartIndex = line.indexOf("--");
        if (commentStartIndex >= 0) {
            comments.push(line.substr(commentStartIndex));
            arr[i] = line.substr(0, commentStartIndex) + ILCommentPrefix + count;
            count++;
        }
    }
    var isInComment = false;
    var commentRegex = new RegExp("(?<=" + ILCommentPrefix + "[\\d]+).");
    for (var i = 0; i < arr.length; i++) {
        var commentStartIndex = 0;
        var hasComment = true;
        var commentEndInlineIndex = 0;
        while (hasComment) {
            var line = arr[i];
            if (!isInComment) {
                commentStartIndex = line.indexOf("/*");
                var commentEndIndex = line.indexOf("*/", commentStartIndex);
                if (commentStartIndex >= 0) {
                    if (commentEndIndex >= 0) {
                        commentEndInlineIndex = commentEndIndex + 2;
                        isInComment = false;
                        comments.push(line.substring(commentStartIndex, commentEndInlineIndex));
                        arr[i] = line.substr(0, commentStartIndex) + ILCommentPrefix + count + line.substr(commentEndInlineIndex);
                        count++;
                        hasComment = true;
                        if (commentStartIndex + 2 == line.length) {
                            hasComment = false;
                        }
                    }
                    else {
                        isInComment = true;
                        comments.push(line.substr(commentStartIndex));
                        arr[i] = line.substr(0, commentStartIndex) + ILCommentPrefix + count;
                        count++;
                        hasComment = false;
                    }
                }
                else {
                    hasComment = false;
                }
                continue;
            }
            if (isInComment) {
                var lastCommentEndIndex = line.regexLastIndexOf(commentRegex, line.length);
                if (commentStartIndex == 0) {
                    var commentEndIndex = line.indexOf("*/", lastCommentEndIndex);
                }
                else {
                    var commentEndIndex = line.indexOf("*/", commentStartIndex);
                }
                if (commentEndIndex >= 0) {
                    isInComment = false;
                    comments.push(line.substr(0, commentEndIndex + 2));
                    arr[i] = ILCommentPrefix + count + line.substr(commentEndIndex + 2);
                    count++;
                    hasComment = true;
                }
                else {
                    comments.push(line);
                    arr[i] = ILCommentPrefix + count;
                    count++;
                    hasComment = false;
                }
            }
        }
    }
    return comments;
}
function ToLowerCases(arr) {
    for (var i = 0; i < arr.length; i++) {
        arr[i] = arr[i].toLowerCase();
    }
}
function ToUpperCases(arr) {
    for (var i = 0; i < arr.length; i++) {
        arr[i] = arr[i].toUpperCase();
    }
}
function ToCamelCases(arr) {
    for (var i = 0; i < arr.length; i++) {
        arr[i] = arr[i].charAt(0) + arr[i].slice(1).toLowerCase();
    }
}
function ReplaceKeyWords(text, keywords) {
    for (var k = 0; k < keywords.length; k++) {
        text = text.replace(new RegExp("([^a-zA-Z0-9_@]|^)" + keywords[k] + "([^a-zA-Z0-9_]|$)", 'gi'), "$1" + keywords[k] + "$2");
    }
    return text;
}
function SetKeywordCase(input, keywordcase, keywords) {
    let inputcase = keywordcase.toLowerCase();
    switch (inputcase) {
        case "lowercase":
            ToLowerCases(keywords);
            break;
        case "defaultcase":
            ToCamelCases(keywords);
            break;
        case "uppercase":
            ToUpperCases(keywords);
    }
    input = ReplaceKeyWords(input, keywords);
    return input;
}
function SetNewLinesAfterSymbols(text, newLineSettings) {
    if (newLineSettings == null) {
        return text;
    }
    if (newLineSettings.newLineAfter != null) {
        newLineSettings.newLineAfter.forEach(symbol => {
            let upper = symbol.toUpperCase();
            var rexString = "(" + upper + ")[ ]?([^ \r\n@])";
            let regex = null;
            if (upper.regexStartsWith(/\w/)) {
                regex = new RegExp("\\b" + rexString, "g");
            }
            else {
                regex = new RegExp(rexString, "g");
            }
            text = text.replace(regex, '$1\r\n$2');
            if (upper == "PORT") {
                text = text.replace(/\bPORT\b\s+MAP/, "PORT MAP");
            }
        });
    }
    if (newLineSettings.noNewLineAfter != null) {
        newLineSettings.noNewLineAfter.forEach(symbol => {
            let rexString = "(" + symbol.toUpperCase() + ")[ \r\n]+([^@])";
            let regex = null;
            if (symbol.regexStartsWith(/\w/)) {
                regex = new RegExp("\\b" + rexString, "g");
                text = text.replace(regex, '$1 $2');
            }
            else {
                regex = new RegExp(rexString, "g");
            }
            text = text.replace(regex, '$1 $2');
        });
    }
    return text;
}
exports.SetNewLinesAfterSymbols = SetNewLinesAfterSymbols;
class signAlignSettings {
    constructor(isRegional, isAll, mode, keyWords) {
        this.isRegional = isRegional;
        this.isAll = isAll;
        this.mode = mode;
        this.keyWords = keyWords;
    }
}
exports.signAlignSettings = signAlignSettings;
class BeautifierSettings {
    constructor(removeComments, removeReport, checkAlias, alignComments, signAlignSettings, keywordCase, typeNameCase, indentation, newLineSettings, endOfLine, addNewLine) {
        this.RemoveComments = removeComments;
        this.RemoveAsserts = removeReport;
        this.CheckAlias = checkAlias;
        this.AlignComments = alignComments;
        this.SignAlignSettings = signAlignSettings;
        this.KeywordCase = keywordCase;
        this.TypeNameCase = typeNameCase;
        this.Indentation = indentation;
        this.NewLineSettings = newLineSettings;
        this.EndOfLine = endOfLine;
        this.AddNewLine = addNewLine;
    }
}
exports.BeautifierSettings = BeautifierSettings;
let KeyWords = ["ABS", "ACCESS", "AFTER", "ALIAS", "ALL", "AND", "ARCHITECTURE", "ARRAY", "ASSERT", "ATTRIBUTE", "BEGIN", "BLOCK", "BODY", "BUFFER", "BUS", "CASE", "COMPONENT", "CONFIGURATION", "CONSTANT", "CONTEXT", "COVER", "DISCONNECT", "DOWNTO", "DEFAULT", "ELSE", "ELSIF", "END", "ENTITY", "EXIT", "FAIRNESS", "FILE", "FOR", "FORCE", "FUNCTION", "GENERATE", "GENERIC", "GROUP", "GUARDED", "IF", "IMPURE", "IN", "INERTIAL", "INOUT", "IS", "LABEL", "LIBRARY", "LINKAGE", "LITERAL", "LOOP", "MAP", "MOD", "NAND", "NEW", "NEXT", "NOR", "NOT", "NULL", "OF", "ON", "OPEN", "OR", "OTHERS", "OUT", "PACKAGE", "PORT", "POSTPONED", "PROCEDURE", "PROCESS", "PROPERTY", "PROTECTED", "PURE", "RANGE", "RECORD", "REGISTER", "REJECT", "RELEASE", "REM", "REPORT", "RESTRICT", "RESTRICT_GUARANTEE", "RETURN", "ROL", "ROR", "SELECT", "SEQUENCE", "SEVERITY", "SHARED", "SIGNAL", "SLA", "SLL", "SRA", "SRL", "STRONG", "SUBTYPE", "THEN", "TO", "TRANSPORT", "TYPE", "UNAFFECTED", "UNITS", "UNTIL", "USE", "VARIABLE", "VMODE", "VPROP", "VUNIT", "WAIT", "WHEN", "WHILE", "WITH", "XNOR", "XOR"];
let TypeNames = ["BOOLEAN", "BIT", "CHARACTER", "INTEGER", "TIME", "NATURAL", "POSITIVE", "STD_LOGIC", "STD_LOGIC_VECTOR", "STD_ULOGIC", "STD_ULOGIC_VECTOR", "STRING"];
function beautify(input, settings) {
    input = input.replace(/\r\n/g, "\n");
    input = input.replace(/\n/g, "\r\n");
    var arr = input.split("\r\n");
    var comments = EscapeComments(arr);
    var backslashes = escapeText(arr, "\\\\[^\\\\]+\\\\", ILBackslash);
    let quotes = escapeText(arr, '"([^"]+)"', ILQuote);
    let singleQuotes = escapeText(arr, "'[^']'", ILSingleQuote);
    RemoveLeadingWhitespaces(arr);
    input = arr.join("\r\n");
    if (settings.RemoveComments) {
        input = input.replace(/\r\n[ \t]*@@comments[0-9]+[ \t]*\r\n/g, '\r\n');
        input = input.replace(/@@comments[0-9]+/g, '');
        comments = [];
    }
    input = SetKeywordCase(input, "uppercase", KeyWords);
    input = SetKeywordCase(input, "uppercase", TypeNames);
    input = RemoveExtraNewLines(input);
    input = input.replace(/[\t ]+/g, ' ');
    input = input.replace(/\([\t ]+/g, '\(');
    input = input.replace(/[ ]+;/g, ';');
    input = input.replace(/:[ ]*(PROCESS|ENTITY)/gi, ':$1');
    arr = input.split("\r\n");
    if (settings.RemoveAsserts) {
        RemoveAsserts(arr); //RemoveAsserts must be after EscapeQuotes
    }
    ReserveSemicolonInKeywords(arr);
    input = arr.join("\r\n");
    input = input.replace(/\b(PORT|GENERIC)\b\s+MAP/g, '$1 MAP');
    input = input.replace(/\b(PORT|PROCESS|GENERIC)\b[\s]*\(/g, '$1 (');
    let newLineSettings = settings.NewLineSettings;
    if (newLineSettings != null) {
        input = SetNewLinesAfterSymbols(input, newLineSettings);
        arr = input.split("\r\n");
        ApplyNoNewLineAfter(arr, newLineSettings.noNewLineAfter);
        input = arr.join("\r\n");
    }
    input = input.replace(/([a-zA-Z0-9\); ])\);(@@comments[0-9]+)?@@end/g, '$1\r\n);$2@@end');
    input = input.replace(/[ ]?([&=:\-\+|\*]|[<>]+)[ ]?/g, ' $1 ');
    input = input.replace(/(\d+e) +([+\-]) +(\d+)/g, '$1$2$3'); // fix exponential notation format broken by previous step
    input = input.replace(/[ ]?([,])[ ]?/g, '$1 ');
    input = input.replace(/[ ]?(['"])(THEN)/g, '$1 $2');
    input = input.replace(/[ ]?(\?)?[ ]?(<|:|>|\/)?[ ]+(=)?[ ]?/g, ' $1$2$3 ');
    input = input.replace(/(IF)[ ]?([\(\)])/g, '$1 $2');
    input = input.replace(/([\(\)])[ ]?(THEN)/gi, '$1 $2');
    input = input.replace(/(^|[\(\)])[ ]?(AND|OR|XOR|XNOR)[ ]*([\(])/g, '$1 $2 $3');
    input = input.replace(/ ([\-\*\/=+<>])[ ]*([\-\*\/=+<>]) /g, " $1$2 ");
    //input = input.replace(/\r\n[ \t]+--\r\n/g, "\r\n");
    input = input.replace(/[ ]+/g, ' ');
    input = input.replace(/[ \t]+\r\n/g, "\r\n");
    input = input.replace(/\r\n\r\n\r\n/g, '\r\n');
    input = input.replace(/[\r\n\s]+$/g, '');
    input = input.replace(/[ \t]+\)/g, ')');
    input = input.replace(/\s*\)\s+RETURN\s+([\w]+;)/g, '\r\n) RETURN $1'); //function(..)\r\nreturn type; -> function(..\r\n)return type;
    input = input.replace(/\)\s*(@@\w+)\r\n\s*RETURN\s+([\w]+;)/g, ') $1\r\n' + ILIndentedReturnPrefix + 'RETURN $2'); //function(..)\r\nreturn type; -> function(..\r\n)return type;
    let keywordAndSignRegex = new RegExp("(\\b" + KeyWords.join("\\b|\\b") + "\\b) +([\\-+]) +(\\w)", "g");
    input = input.replace(keywordAndSignRegex, "$1 $2$3"); // `WHEN - 2` -> `WHEN -2`
    input = input.replace(/([,|]) +([+\-]) +(\w)/g, '$1 $2$3'); // `1, - 2)` -> `1, -2)`
    input = input.replace(/(\() +([+\-]) +(\w)/g, '$1$2$3'); // `( - 2)` -> `(-2)`
    arr = input.split("\r\n");
    let result = [];
    beautify3(arr, result, settings, 0, 0);
    var alignSettings = settings.SignAlignSettings;
    if (alignSettings != null && alignSettings.isAll) {
        AlignSigns(result, 0, result.length - 1, alignSettings.mode, settings.AlignComments);
    }
    arr = FormattedLineToString(result, settings.Indentation);
    input = arr.join("\r\n");
    input = input.replace(/@@RETURN/g, "RETURN");
    input = SetKeywordCase(input, settings.KeywordCase, KeyWords);
    input = SetKeywordCase(input, settings.TypeNameCase, TypeNames);
    input = replaceEscapedWords(input, quotes, ILQuote);
    input = replaceEscapedWords(input, singleQuotes, ILSingleQuote);
    input = replaceEscapedComments(input, comments, ILCommentPrefix);
    input = replaceEscapedWords(input, backslashes, ILBackslash);
    input = input.replace(new RegExp(ILSemicolon, "g"), ";");
    input = input.replace(/@@[a-z]+/g, "");
    var escapedTexts = new RegExp("[" + ILBackslash + ILQuote + ILSingleQuote + "]", "g");
    input = input.replace(escapedTexts, "");
    input = input.replace(/\r\n/g, settings.EndOfLine);
    if (settings.AddNewLine && !input.endsWith(settings.EndOfLine)) {
        input += settings.EndOfLine;
    }
    return input;
}
exports.beautify = beautify;
function replaceEscapedWords(input, arr, prefix) {
    for (var i = 0; i < arr.length; i++) {
        var text = arr[i];
        var regex = new RegExp("(" + prefix + "){" + text.length + "}");
        input = input.replace(regex, text);
    }
    return input;
}
function replaceEscapedComments(input, arr, prefix) {
    for (var i = 0; i < arr.length; i++) {
        input = input.replace(prefix + i, arr[i]);
    }
    return input;
}
function RemoveLeadingWhitespaces(arr) {
    for (var i = 0; i < arr.length; i++) {
        arr[i] = arr[i].replace(/^\s+/, "");
    }
}
class FormattedLine {
    constructor(line, indent) {
        this.Line = line;
        this.Indent = indent;
    }
}
exports.FormattedLine = FormattedLine;
function FormattedLineToString(arr, indentation) {
    let result = [];
    if (arr == null) {
        return result;
    }
    if (indentation == null) {
        indentation = "";
    }
    arr.forEach(i => {
        if (i instanceof FormattedLine) {
            if (i.Line.length > 0) {
                result.push((Array(i.Indent + 1).join(indentation)) + i.Line);
            }
            else {
                result.push("");
            }
        }
        else {
            result = result.concat(FormattedLineToString(i, indentation));
        }
    });
    return result;
}
exports.FormattedLineToString = FormattedLineToString;
function GetCloseparentheseEndIndex(inputs, startIndex) {
    let openParentheseCount = 0;
    let closeParentheseCount = 0;
    for (let i = startIndex; i < inputs.length; i++) {
        let input = inputs[i];
        openParentheseCount += input.count("(");
        closeParentheseCount += input.count(")");
        if (openParentheseCount > 0
            && openParentheseCount <= closeParentheseCount) {
            return i;
        }
    }
    return startIndex;
}
function beautifyPortGenericBlock(inputs, result, settings, startIndex, parentEndIndex, indent, mode) {
    let firstLine = inputs[startIndex];
    let regex = new RegExp("[\\w\\s:]*(" + mode + ")([\\s]|$)");
    if (!firstLine.regexStartsWith(regex)) {
        return [startIndex, parentEndIndex];
    }
    let firstLineHasParenthese = firstLine.indexOf("(") >= 0;
    let hasParenthese = firstLineHasParenthese;
    let blockBodyStartIndex = startIndex;
    let secondLineHasParenthese = startIndex + 1 < inputs.length && inputs[startIndex + 1].startsWith("(");
    if (secondLineHasParenthese) {
        hasParenthese = true;
        blockBodyStartIndex++;
    }
    let endIndex = hasParenthese ? GetCloseparentheseEndIndex(inputs, startIndex) : startIndex;
    if (endIndex != startIndex && firstLineHasParenthese) {
        inputs[startIndex] = inputs[startIndex].replace(/\b(PORT|GENERIC|PROCEDURE)\b([\w ]+)\(([\w\(\) ]+)/, '$1$2(\r\n$3');
        let newInputs = inputs[startIndex].split("\r\n");
        if (newInputs.length == 2) {
            inputs[startIndex] = newInputs[0];
            inputs.splice(startIndex + 1, 0, newInputs[1]);
            endIndex++;
            parentEndIndex++;
        }
    }
    else if (endIndex > startIndex + 1 && secondLineHasParenthese) {
        inputs[startIndex + 1] = inputs[startIndex + 1].replace(/\(([\w\(\) ]+)/, '(\r\n$1');
        let newInputs = inputs[startIndex + 1].split("\r\n");
        if (newInputs.length == 2) {
            inputs[startIndex + 1] = newInputs[0];
            inputs.splice(startIndex + 2, 0, newInputs[1]);
            endIndex++;
            parentEndIndex++;
        }
    }
    if (firstLineHasParenthese && inputs[startIndex].indexOf("MAP") > 0) {
        inputs[startIndex] = inputs[startIndex].replace(/([^\w])(MAP)\s+\(/g, '$1$2(');
    }
    result.push(new FormattedLine(inputs[startIndex], indent));
    if (secondLineHasParenthese) {
        let secondLineIndent = indent;
        if (endIndex == startIndex + 1) {
            secondLineIndent++;
        }
        result.push(new FormattedLine(inputs[startIndex + 1], secondLineIndent));
    }
    let blockBodyEndIndex = endIndex;
    let i = beautify3(inputs, result, settings, blockBodyStartIndex + 1, indent + 1, endIndex);
    if (inputs[i].startsWith(")")) {
        result[i].Indent--;
        blockBodyEndIndex--;
    }
    var alignSettings = settings.SignAlignSettings;
    if (alignSettings != null) {
        if (alignSettings.isRegional && !alignSettings.isAll
            && alignSettings.keyWords != null
            && alignSettings.keyWords.indexOf(mode) >= 0) {
            blockBodyStartIndex++;
            AlignSigns(result, blockBodyStartIndex, blockBodyEndIndex, alignSettings.mode, settings.AlignComments);
        }
    }
    return [i, parentEndIndex];
}
exports.beautifyPortGenericBlock = beautifyPortGenericBlock;
function AlignSigns(result, startIndex, endIndex, mode, alignComments) {
    AlignSign_(result, startIndex, endIndex, ":", mode);
    AlignSign_(result, startIndex, endIndex, ":=", mode);
    AlignSign_(result, startIndex, endIndex, "<=", mode);
    AlignSign_(result, startIndex, endIndex, "=>", mode);
    if (alignComments) {
        AlignSign_(result, startIndex, endIndex, "@@comments", mode);
    }
}
exports.AlignSigns = AlignSigns;
function AlignSign_(result, startIndex, endIndex, symbol, mode) {
    let maxSymbolIndex = -1;
    let symbolIndices = {};
    let startLine = startIndex;
    let labelAndKeywords = [
        "([\\w\\s]*:(\\s)*PROCESS)",
        "([\\w\\s]*:(\\s)*POSTPONED PROCESS)",
        "([\\w\\s]*:\\s*$)",
        "([\\w\\s]*:.*\\s+GENERATE)"
    ];
    let labelAndKeywordsStr = labelAndKeywords.join("|");
    let labelAndKeywordsRegex = new RegExp("(" + labelAndKeywordsStr + ")([^\\w]|$)");
    for (let i = startIndex; i <= endIndex; i++) {
        let line = result[i].Line;
        if (symbol == ":" && line.regexStartsWith(labelAndKeywordsRegex)) {
            continue;
        }
        let regex = new RegExp("([\\s\\w\\\\]|^)" + symbol + "([\\s\\w\\\\]|$)");
        if (line.regexCount(regex) > 1) {
            continue;
        }
        let colonIndex = line.regexIndexOf(regex);
        if (colonIndex > 0) {
            maxSymbolIndex = Math.max(maxSymbolIndex, colonIndex);
            symbolIndices[i] = colonIndex;
        }
        else if ((mode != "local" && !line.startsWith(ILCommentPrefix) && line.length != 0)
            || (mode == "local")) {
            if (startLine < i - 1) // if cannot find the symbol, a block of symbols ends
            {
                AlignSign(result, startLine, i - 1, symbol, maxSymbolIndex, symbolIndices);
            }
            maxSymbolIndex = -1;
            symbolIndices = {};
            startLine = i;
        }
    }
    if (startLine < endIndex) // if cannot find the symbol, a block of symbols ends
    {
        AlignSign(result, startLine, endIndex, symbol, maxSymbolIndex, symbolIndices);
    }
}
function AlignSign(result, startIndex, endIndex, symbol, maxSymbolIndex = -1, symbolIndices = {}) {
    if (maxSymbolIndex < 0) {
        return;
    }
    for (let lineIndex in symbolIndices) {
        let symbolIndex = symbolIndices[lineIndex];
        if (symbolIndex == maxSymbolIndex) {
            continue;
        }
        let line = result[lineIndex].Line;
        result[lineIndex].Line = line.substring(0, symbolIndex)
            + (Array(maxSymbolIndex - symbolIndex + 1).join(" "))
            + line.substring(symbolIndex);
    }
}
exports.AlignSign = AlignSign;
function beautifyCaseBlock(inputs, result, settings, startIndex, indent) {
    if (!inputs[startIndex].regexStartsWith(/(.+:\s*)?(CASE)([\s]|$)/)) {
        return startIndex;
    }
    result.push(new FormattedLine(inputs[startIndex], indent));
    let i = beautify3(inputs, result, settings, startIndex + 1, indent + 2);
    result[i].Indent = indent;
    return i;
}
exports.beautifyCaseBlock = beautifyCaseBlock;
function getSemicolonBlockEndIndex(inputs, settings, startIndex, parentEndIndex) {
    let endIndex = 0;
    let openBracketsCount = 0;
    let closeBracketsCount = 0;
    for (let i = startIndex; i < inputs.length; i++) {
        let input = inputs[i];
        let indexOfSemicolon = input.indexOf(";");
        let splitIndex = indexOfSemicolon < 0 ? input.length : indexOfSemicolon + 1;
        let stringBeforeSemicolon = input.substring(0, splitIndex);
        let stringAfterSemicolon = input.substring(splitIndex);
        stringAfterSemicolon = stringAfterSemicolon.replace(new RegExp(ILCommentPrefix + "[0-9]+"), "");
        openBracketsCount += stringBeforeSemicolon.count("(");
        closeBracketsCount += stringBeforeSemicolon.count(")");
        if (indexOfSemicolon < 0) {
            continue;
        }
        if (openBracketsCount == closeBracketsCount) {
            endIndex = i;
            if (stringAfterSemicolon.trim().length > 0 && settings.NewLineSettings.newLineAfter.indexOf(";") >= 0) {
                inputs[i] = stringBeforeSemicolon;
                inputs.splice(i, 0, stringAfterSemicolon);
                parentEndIndex++;
            }
            break;
        }
    }
    return [endIndex, parentEndIndex];
}
function beautifyComponentBlock(inputs, result, settings, startIndex, parentEndIndex, indent) {
    let endIndex = startIndex;
    for (let i = startIndex; i < inputs.length; i++) {
        if (inputs[i].regexStartsWith(/END(\s|$)/)) {
            endIndex = i;
            break;
        }
    }
    result.push(new FormattedLine(inputs[startIndex], indent));
    if (endIndex != startIndex) {
        let actualEndIndex = beautify3(inputs, result, settings, startIndex + 1, indent + 1, endIndex);
        let incremental = actualEndIndex - endIndex;
        endIndex += incremental;
        parentEndIndex += incremental;
    }
    return [endIndex, parentEndIndex];
}
exports.beautifyComponentBlock = beautifyComponentBlock;
function beautifyPackageIsNewBlock(inputs, result, settings, startIndex, parentEndIndex, indent) {
    let endIndex = startIndex;
    for (let i = startIndex; i < inputs.length; i++) {
        if (inputs[i].regexIndexOf(/;(\s|$)/) >= 0) {
            endIndex = i;
            break;
        }
    }
    result.push(new FormattedLine(inputs[startIndex], indent));
    if (endIndex != startIndex) {
        let actualEndIndex = beautify3(inputs, result, settings, startIndex + 1, indent + 1, endIndex);
        let incremental = actualEndIndex - endIndex;
        endIndex += incremental;
        parentEndIndex += incremental;
    }
    return [endIndex, parentEndIndex];
}
exports.beautifyPackageIsNewBlock = beautifyPackageIsNewBlock;
function beautifySemicolonBlock(inputs, result, settings, startIndex, parentEndIndex, indent) {
    let endIndex = startIndex;
    [endIndex, parentEndIndex] = getSemicolonBlockEndIndex(inputs, settings, startIndex, parentEndIndex);
    result.push(new FormattedLine(inputs[startIndex], indent));
    if (endIndex != startIndex) {
        let i = beautify3(inputs, result, settings, startIndex + 1, indent + 1, endIndex);
    }
    return [endIndex, parentEndIndex];
}
exports.beautifySemicolonBlock = beautifySemicolonBlock;
function beautify3(inputs, result, settings, startIndex, indent, endIndex) {
    let i;
    let regexOneLineBlockKeyWords = new RegExp(/(PROCEDURE)[^\w](?!.+[^\w]IS([^\w]|$))/); //match PROCEDURE..; but not PROCEDURE .. IS;
    let regexFunctionMultiLineBlockKeyWords = new RegExp(/(FUNCTION|IMPURE FUNCTION)[^\w](?=.+[^\w]IS([^\w]|$))/); //match FUNCTION .. IS; but not FUNCTION
    let blockMidKeyWords = ["BEGIN"];
    let blockStartsKeyWords = [
        "IF",
        "CASE",
        "ARCHITECTURE",
        "PROCEDURE",
        "PACKAGE",
        "(([\\w\\s]*:)?(\\s)*PROCESS)",
        "(([\\w\\s]*:)?(\\s)*POSTPONED PROCESS)",
        "(.*\\s*PROTECTED)",
        "(COMPONENT)",
        "(ENTITY(?!.+;))",
        "FOR",
        "WHILE",
        "LOOP",
        "(.*\\s*GENERATE)",
        "(CONTEXT[\\w\\s\\\\]+IS)",
        "(CONFIGURATION(?!.+;))",
        "BLOCK",
        "UNITS",
        "\\w+\\s+\\w+\\s+IS\\s+RECORD"
    ];
    let blockEndsKeyWords = ["END", ".*\\)\\s*RETURN\\s+[\\w]+;"];
    let indentedEndsKeyWords = [ILIndentedReturnPrefix + "RETURN\\s+\\w+;"];
    let blockEndsWithSemicolon = [
        "(WITH\\s+[\\w\\s\\\\]+SELECT)",
        "([\\w\\\\]+[\\s]*<=)",
        "([\\w\\\\]+[\\s]*:=)",
        "FOR\\s+[\\w\\s,]+:\\s*\\w+\\s+USE",
        "REPORT"
    ];
    let newLineAfterKeyWordsStr = blockStartsKeyWords.join("|");
    let regexBlockMidKeyWords = blockMidKeyWords.convertToRegexBlockWords();
    let regexBlockStartsKeywords = new RegExp("([\\w]+\\s*:\\s*)?(" + newLineAfterKeyWordsStr + ")([^\\w]|$)");
    let regexBlockEndsKeyWords = blockEndsKeyWords.convertToRegexBlockWords();
    let regexBlockIndentedEndsKeyWords = indentedEndsKeyWords.convertToRegexBlockWords();
    let regexblockEndsWithSemicolon = blockEndsWithSemicolon.convertToRegexBlockWords();
    let regexMidKeyWhen = "WHEN".convertToRegexBlockWords();
    let regexMidKeyElse = "ELSE|ELSIF".convertToRegexBlockWords();
    if (endIndex == null) {
        endIndex = inputs.length - 1;
    }
    for (i = startIndex; i <= endIndex; i++) {
        if (indent < 0) {
            indent = 0;
        }
        let input = inputs[i].trim();
        if (input.regexStartsWith(regexBlockIndentedEndsKeyWords)) {
            result.push(new FormattedLine(input, indent));
            return i;
        }
        if (input.regexStartsWith(/COMPONENT\s/)) {
            let modeCache = Mode;
            Mode = FormatMode.EndsWithSemicolon;
            [i, endIndex] = beautifyComponentBlock(inputs, result, settings, i, endIndex, indent);
            Mode = modeCache;
            continue;
        }
        if (input.regexStartsWith(/PACKAGE[\s\w]+IS\s+NEW/)) {
            let modeCache = Mode;
            Mode = FormatMode.EndsWithSemicolon;
            [i, endIndex] = beautifyPackageIsNewBlock(inputs, result, settings, i, endIndex, indent);
            Mode = modeCache;
            continue;
        }
        if (input.regexStartsWith(/\w+\s*:\s*ENTITY/)) {
            let modeCache = Mode;
            Mode = FormatMode.EndsWithSemicolon;
            [i, endIndex] = beautifySemicolonBlock(inputs, result, settings, i, endIndex, indent);
            Mode = modeCache;
            continue;
        }
        if (Mode != FormatMode.EndsWithSemicolon && input.regexStartsWith(regexblockEndsWithSemicolon)) {
            let modeCache = Mode;
            Mode = FormatMode.EndsWithSemicolon;
            [i, endIndex] = beautifySemicolonBlock(inputs, result, settings, i, endIndex, indent);
            Mode = modeCache;
            continue;
        }
        if (input.regexStartsWith(/(.+:\s*)?(CASE)([\s]|$)/)) {
            let modeCache = Mode;
            Mode = FormatMode.CaseWhen;
            i = beautifyCaseBlock(inputs, result, settings, i, indent);
            Mode = modeCache;
            continue;
        }
        if (input.regexStartsWith(/.*?\:\=\s*\($/)) {
            [i, endIndex] = beautifyPortGenericBlock(inputs, result, settings, i, endIndex, indent, ":=");
            continue;
        }
        if (input.regexStartsWith(/[\w\s:]*\bPORT\b([\s]|$)/)) {
            [i, endIndex] = beautifyPortGenericBlock(inputs, result, settings, i, endIndex, indent, "PORT");
            continue;
        }
        if (input.regexStartsWith(/TYPE\s+\w+\s+IS\s+\(/)) {
            [i, endIndex] = beautifyPortGenericBlock(inputs, result, settings, i, endIndex, indent, "IS");
            continue;
        }
        if (input.regexStartsWith(/[\w\s:]*GENERIC([\s]|$)/)) {
            [i, endIndex] = beautifyPortGenericBlock(inputs, result, settings, i, endIndex, indent, "GENERIC");
            continue;
        }
        if (input.regexStartsWith(/[\w\s:]*PROCEDURE[\s\w]+\($/)) {
            [i, endIndex] = beautifyPortGenericBlock(inputs, result, settings, i, endIndex, indent, "PROCEDURE");
            if (inputs[i].regexStartsWith(/.*\)[\s]*IS/)) {
                i = beautify3(inputs, result, settings, i + 1, indent + 1);
            }
            continue;
        }
        if (input.regexStartsWith(/FUNCTION[^\w]/)
            && input.regexIndexOf(/[^\w]RETURN[^\w]/) < 0) {
            [i, endIndex] = beautifyPortGenericBlock(inputs, result, settings, i, endIndex, indent, "FUNCTION");
            if (!inputs[i].regexStartsWith(regexBlockEndsKeyWords)) {
                i = beautify3(inputs, result, settings, i + 1, indent + 1);
            }
            else {
                result[i].Indent++;
            }
            continue;
        }
        if (input.regexStartsWith(/IMPURE FUNCTION[^\w]/)
            && input.regexIndexOf(/[^\w]RETURN[^\w]/) < 0) {
            [i, endIndex] = beautifyPortGenericBlock(inputs, result, settings, i, endIndex, indent, "IMPURE FUNCTION");
            if (!inputs[i].regexStartsWith(regexBlockEndsKeyWords)) {
                if (inputs[i].regexStartsWith(regexBlockIndentedEndsKeyWords)) {
                    result[i].Indent++;
                }
                else {
                    i = beautify3(inputs, result, settings, i + 1, indent + 1);
                }
            }
            else {
                result[i].Indent++;
            }
            continue;
        }
        result.push(new FormattedLine(input, indent));
        if (startIndex != 0
            && (input.regexStartsWith(regexBlockMidKeyWords)
                || (Mode != FormatMode.EndsWithSemicolon && input.regexStartsWith(regexMidKeyElse))
                || (Mode == FormatMode.CaseWhen && input.regexStartsWith(regexMidKeyWhen)))) {
            result[i].Indent--;
        }
        else if (startIndex != 0
            && (input.regexStartsWith(regexBlockEndsKeyWords))) {
            result[i].Indent--;
            return i;
        }
        if (input.regexStartsWith(regexOneLineBlockKeyWords)) {
            continue;
        }
        if (input.regexStartsWith(regexFunctionMultiLineBlockKeyWords)
            || input.regexStartsWith(regexBlockStartsKeywords)) {
            i = beautify3(inputs, result, settings, i + 1, indent + 1);
        }
    }
    i--;
    return i;
}
exports.beautify3 = beautify3;
function ReserveSemicolonInKeywords(arr) {
    for (let i = 0; i < arr.length; i++) {
        if (arr[i].match(/FUNCTION|PROCEDURE/) != null) {
            arr[i] = arr[i].replace(/;/g, ILSemicolon);
        }
    }
}
function ApplyNoNewLineAfter(arr, noNewLineAfter) {
    if (noNewLineAfter == null) {
        return;
    }
    for (let i = 0; i < arr.length; i++) {
        noNewLineAfter.forEach(n => {
            let regex = new RegExp("(" + n.toUpperCase + ")[ a-z0-9]+[a-z0-9]+");
            if (arr[i].regexIndexOf(regex) >= 0) {
                arr[i] += "@@singleline";
            }
        });
    }
}
exports.ApplyNoNewLineAfter = ApplyNoNewLineAfter;
function RemoveAsserts(arr) {
    let need_semi = false;
    let inAssert = false;
    let n = 0;
    for (let i = 0; i < arr.length; i++) {
        let has_semi = arr[i].indexOf(";") >= 0;
        if (need_semi) {
            arr[i] = '';
        }
        n = arr[i].indexOf("ASSERT ");
        if (n >= 0) {
            inAssert = true;
            arr[i] = '';
        }
        if (!has_semi) {
            if (inAssert) {
                need_semi = true;
            }
        }
        else {
            need_semi = false;
        }
    }
}
exports.RemoveAsserts = RemoveAsserts;
function escapeText(arr, regex, escapedChar) {
    let quotes = [];
    let regexEpr = new RegExp(regex, "g");
    for (let i = 0; i < arr.length; i++) {
        let matches = arr[i].match(regexEpr);
        if (matches != null) {
            for (var j = 0; j < matches.length; j++) {
                var match = matches[j];
                arr[i] = arr[i].replace(match, escapedChar.repeat(match.length));
                quotes.push(match);
            }
        }
    }
    return quotes;
}
function RemoveExtraNewLines(input) {
    input = input.replace(/(?:\r\n|\r|\n)/g, '\r\n');
    input = input.replace(/ \r\n/g, '\r\n');
    input = input.replace(/\r\n\r\n\r\n/g, '\r\n');
    return input;
}