/* eslint-disable @typescript-eslint/naming-convention */
"use strict";
const os = require('os');
const fs = require('fs');
const path = require('path');
const vscode = require('vscode');
const temp = require("temp");

const vlogFormatter = require("./vlogFormatter.js");
const vhdlFormatter = require("./vhdlFormatter.js");

class Formatter {
    constructor() {
        this.vlogFormatter = new VlogFormatter();
        this.vhdlFormatter = new VhdlFormatter();
    }

    async provideDocumentFormattingEdits(document, options, token) {
        const edits = [];
        //Get document code
        let code_document = document.getText();
        let selection_document = this.getDocumentRange(document);
        //Get selected text
        let editor = vscode.window.activeTextEditor;
        let selection_selected_text = '';
        let code_selected_text = '';
        if (editor !== undefined) {
            selection_selected_text = editor.selection;
            code_selected_text = editor.document.getText(editor.selection);
        }
        //Code to format
        let code_to_format = '';
        let selection_to_format = '';
        if (code_selected_text !== '') {
            code_to_format = code_selected_text;
            selection_to_format = selection_selected_text;
        } else {
            code_to_format = code_document;
            selection_to_format = selection_document;
        }

        let code_format = await this.format(document.languageId, code_to_format);
        if (code_format === null) {
            console.log("Error format code.");
            return edits;
        } else {
            const replacement = vscode.TextEdit.replace(selection_to_format, code_format);
            edits.push(replacement);
            return edits;
        }
    }

    async format(language, code) {
        let options = null;
        let formatted_code = '';
        try {
            if (language === "vhdl") {
                options = this.get_vhdl_config();
                formatted_code = await this.vhdlFormatter.format_from_code(code, options);
            }
            else {
                options = this.get_vlog_config();
                formatted_code = await this.vlogFormatter.format_from_code(code, options);
            }
            return formatted_code;
        } catch (error) {
            return code;
        }
    }

    get_vlog_config() {
        let style = vscode.workspace.getConfiguration("function.lsp.formatter.vlog.default").get("style");
        let args = vscode.workspace.getConfiguration("function.lsp.formatter.vlog.default").get("args");
        return `--style=${style} ${args}`;
    }

    get_vhdl_config() {
        let configuration = vscode.workspace.getConfiguration('function.lsp.formatter.vhdl.default');
        let settings = {
            "RemoveComments": false,
            "RemoveAsserts": false,
            "CheckAlias": false,
            "AlignComments": configuration.get('align-comments'),
            "SignAlignSettings": {
                "isRegional": true,
                "isAll": true,
                "mode": 'local',
                "keyWords": [
                    "FUNCTION",
                    "IMPURE FUNCTION",
                    "GENERIC",
                    "PORT",
                    "PROCEDURE"
                ]
            },
            "KeywordCase": configuration.get('keyword-case'),
            "TypeNameCase": configuration.get('type-name-case'),
            "Indentation": ' '.repeat(configuration.get('indentation')),
            "NewLineSettings": {
                "newLineAfter": [
                    ";",
                    "then"
                ],
                "noNewLineAfter": []
            },
            "EndOfLine": "\n"
        };
        return settings;
    }

    getDocumentRange(document) {
        const lastLineId = document.lineCount - 1;
        return new vscode.Range(0, 0, lastLineId, document.lineAt(lastLineId).text.length);
    }
}

class VlogFormatter {
    async format_from_code(code, options) {
        let verilogFormatter = await vlogFormatter();
        verilogFormatter.FS.writeFile("/share/FILE_IN.v", code, { encoding: 'utf8' });
        verilogFormatter.ccall('run', '', ['string'], [`${options} finish`]);
        let formatted_code = verilogFormatter.FS.readFile("/share/FILE_OUT.v", { encoding: 'utf8' });
        return formatted_code;
    }
}

class VhdlFormatter {
    async format_from_code(code, options) {
        let beautifuler = new vhdlFormatter.Beautifuler();
        let formatted_code = beautifuler.beauty(code, options);
        return formatted_code;
    }
}


const hdlFormatterProvider = new Formatter();
module.exports = { hdlFormatterProvider };