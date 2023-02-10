const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

const HDLPath = require('../../../HDLfilesys/operation/path');
const { HDLParam, Module, SymbolResult, Instance } = require('../../../HDLparser');
const { positionAfterEqual } = require('./index');

/**
 * @param {string} folderPath 
 * @param {string} currentPath 
 * @returns {Array<vscode.CompletionItem>}
 */
function filterIncludeFiles(folderPath, currentPath) {
    if (fs.existsSync(folderPath)) {
        const suggestFiles = [];
        for (const fileName of fs.readdirSync(folderPath)) {
            const filePath = HDLPath.join(folderPath, fileName);
            if (filePath == currentPath) {
                continue;
            }

            const stat = fs.statSync(filePath);
            const clItem = new vscode.CompletionItem(fileName);
            if (stat.isDirectory()) {
                clItem.kind = vscode.CompletionItemKind.Folder;
            } else if (stat.isFile()) {
                clItem.kind = vscode.CompletionItemKind.File;
            }
            suggestFiles.push(clItem);
        }
        return suggestFiles;
    }
    return [];
}

/**
 * @param {vscode.TextDocument} document
 * @param {vscode.Position} position
 * @returns {Array<vscode.CompletionItem>}
 */
function provideIncludeFiles(document, position) {
    if (position.character == 0) {
        return [];
    }
    const filePath = HDLPath.toSlash(document.fileName);
    const lineText = document.lineAt(position).text;

    let firstQIndex = lineText.lastIndexOf('"', position.character - 1);
    let lastQIndex = lineText.indexOf('"', position.character);

    if (firstQIndex != -1 && lastQIndex != -1) {
        const currentPath = lineText.substring(firstQIndex + 1, lastQIndex);
        const folderName = currentPath.length == 0 ? '.' : currentPath;
        const folderAbsPath = HDLPath.rel2abs(filePath, folderName);
        return filterIncludeFiles(folderAbsPath, filePath);
    }

    return [];
}


/**
 * @param {string} singleWord 
 * @param {object} defines 
 * @returns {Promise<Array<vscode.CompletionItem>>}
 */
function provideMacros(singleWord, defines) {
    const suggestMacros = [];
    if (!defines) {
        return suggestMacros;
    }
    for (const macro of Object.keys(defines)) {
        const value = defines[macro].value;
        const name = '`' + macro;
        const clItem = new vscode.CompletionItem('`' + macro, vscode.CompletionItemKind.Constant)
        clItem.detail = 'macro ' + value;
        if (singleWord[0] == '`') {
            clItem.insertText = macro;
        } else {
            clItem.insertText = name;
        }

        suggestMacros.push(clItem);
    }
    return suggestMacros;
}

/**
 * @param {vscode.Position} position cursor position
 * @param {Instance} currentInst 
 * @returns {Promise<Array<vscode.CompletionItem>>} 
 */
function providePositionPorts(position, currentInst) {
    const params = currentInst.instparams;
    const ports = currentInst.instports;
    console.log(position);
    console.log(params);
    console.log(ports);

    if (params &&
        positionAfterEqual(position, params.start) &&
        positionAfterEqual(params.end, position)) {
        
        return currentInst.module.params.map(param => {
            const clItem = new vscode.CompletionItem(param.name, vscode.CompletionItemKind.Constant);
            clItem.detail = 'param';
            return clItem;
        })
    }
    if (ports && 
        positionAfterEqual(position, ports.start) &&
        positionAfterEqual(ports.end, position)) {
        
        return currentInst.module.ports.map(port => {
            const clItem = new vscode.CompletionItem(port.name, vscode.CompletionItemKind.Interface);
            clItem.detail = 'port';
            return clItem;
        })
    }

    return [];
}


/**
 * @description provide module of the current module and include module
 * @param {string} filePath 
 * @param {object} includes {path: range}
 * @returns {Promise<Array<vscode.CompletionItem>>} 
 */
async function provideModules(filePath, includes) {
    // support include of all the module
    // use command property to auto add include path
    const suggestModules = [];

    if (!includes) {
        return suggestModules;
    }

    for (const module of HDLParam.getAllModules()) {
        const clItem = new vscode.CompletionItem(module.name, vscode.CompletionItemKind.Class);
        clItem.detail = 'module';
        suggestModules.push(clItem);
    }

    return suggestModules;
}


/**
 * @param {Module} module
 * @returns {Promise<Array<vscode.CompletionItem>>}
 */
async function provideParamsPorts(module) {
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


/**
 * @param {Array<SymbolResult>} symbols 
 * @returns {Promise<Array<vscode.CompletionItem>>}  
 */
async function provideNets(symbols) {
    if (!symbols) {
        return [];
    }
    const suggestNets = [];
    for (const symbol of symbols) {
        if (symbol.type == 'net') {
            const clItem = new vscode.CompletionItem(symbol.name, vscode.CompletionItemKind.Variable);
            clItem.detail = 'net';
            suggestNets.push(clItem);
        }
    }
    return suggestNets;
}

module.exports = {
    provideIncludeFiles,
    provideMacros,
    providePositionPorts,
    provideModules,
    provideParamsPorts,
    provideNets
};