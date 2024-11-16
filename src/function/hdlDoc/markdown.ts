import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';

import { AbsPath, opeParam, MainOutput, ReportType } from '../../global';
import { hdlParam, HdlModule, HdlFile } from '../../hdlParser/core';
import { HdlModulePort, HdlModuleParam } from '../../hdlParser/common';

import { MarkdownString, RenderString, RenderType,
         mergeSortByLine, getWavedromsFromFile, Count, WavedromString } from './common';
import { hdlPath, hdlFile } from '../../hdlFs';

import { getSymbolComments } from '../lsp/util/feature';
import { HdlLangID, ThemeType } from '../../global/enum';
import { makeDiagram } from './diagram';
import { defaultMacro, doFastApi } from '../../hdlParser/util';


function makeSVGElementByLink(link: AbsPath, caption?: string) {
    let mainHtml;
    if (caption) {
        mainHtml = `<div align=center><img src="${link}"></img><p class="ImgCaption">${caption}</p></div>`;
    } else {
        mainHtml = `<div align=center><img src="${link}"></img></div>`;
    }
    return '<br>' + mainHtml + '<br><br>\n';
}

function selectFieldValue(obj: any, subName: string, ws: string, name: string): string {
    if (subName === 'empty') {
        return '——';
    }
    let value = obj[subName];

    // 对于 source ，支持跳转
    if (subName === 'instModPath' && value) {
            const relativePath = value.replace(ws, '');
        if (fs.existsSync(value)) {
            // 判断 类型
            const hdlFile = hdlParam.getHdlFile(value);
            if (hdlFile && hdlFile.type === 'remote_lib') {
                // 如果是 库 文件，做出更加自定义的字面量
                const libRelPath = value.replace(`${opeParam.extensionPath}/library/`, '');                
                value = `[library] [${libRelPath}](file://${value})`;
            } else {
                value = `[project] [${relativePath}](file://${value})`;
            }            
        } else {
            value = relativePath;
        }
    }

    if (value && value.trim().length === 0) {
        return '——';
    }

    // TODO : 1 not known                
    if (name === 'ports' && value === '1') {
        return '——';
    }
    return value;
}


function makeTableFromObjArray(md: MarkdownString, array: any[], name: string, fieldNames: string[], displayNames: string[]) {
    const ws = hdlPath.toSlash(opeParam.workspacePath) + '/';
    
    if (array.length === 0) {
        md.addText(`no ${name} info`);
    } else {
        const rows = [];
        for (const obj of array) {
            const data = [];
            for (const subName of fieldNames) {         
                const value = selectFieldValue(obj, subName, ws, name);
                data.push(value);
            }
            rows.push(data);
        }
        if (displayNames) {
            md.addTable(displayNames, rows);
        } else {
            md.addTable(fieldNames, rows);
        }
    }
}


/**
 * @description add attribute description to each port/param
 * @param {string} path
 * @param {Array<ModPort|ModParam>} ports
 */
async function patchComment(path: AbsPath, ports: (HdlModulePort | HdlModuleParam)[]) {    
    if (!ports || !ports.length) {
        return;
    } 
    const ranges = ports.map(port => port.range);
    const comments = await getSymbolComments(path, ranges);
    
    for (let i = 0; i < ports.length; ++ i) {
        let inlineComment = comments[i]
                    .replace(/\n\n/g, '<br>')
                    .replace(/\n/g, '<br>')
                    
        if (inlineComment.startsWith('//') || inlineComment.startsWith('--')) {
            inlineComment = inlineComment.substring(2);
        }
        ports[i].desc = inlineComment;
    }
}


/**
 * @description get basedoc obj from a module
 * @param module 
 */
async function getDocsFromModule(module: HdlModule): Promise<MarkdownString> {
    const moduleName = module.name;
    const portNum = module.ports.length;
    const paramNum = module.params.length;
        
    // add desc can optimizer in the future version
    const paramPP = patchComment(module.path, module.params);
    const portPP = patchComment(module.path, module.ports);

    let topModuleDesc = '';
    if (hdlParam.isTopModule(module.path, module.name)) {
        topModuleDesc = '√';
    } else {
        topModuleDesc = '×';
    }

    const md = new MarkdownString(module.range.start.line);
    
    if (module.languageId === HdlLangID.Vhdl) {
        md.addTitle('Entity: `' + moduleName + '`', 1);
    } else if (module.languageId === HdlLangID.Verilog) {
        md.addTitle('Module: `' + moduleName + '`', 1);
    } else if (module.languageId === HdlLangID.SystemVerilog) {
        md.addTitle('Module: `' + moduleName + '`', 1);
    }
    
    // add module name
    md.addTitle('Basic Info', 2);
    
    const infos = [
        `**File:** ${fspath.basename(module.file.path)}`,
        `${paramNum} params, ${portNum} ports`,
        'top module ' + topModuleDesc
    ];
    md.addUnorderedList(infos);
    md.addEnter();

    const diagram = makeDiagram(module.params, module.ports);
    md.addText(diagram);
    
    // wait param and port patch
    await paramPP;
    await portPP;

    // param section
    md.addTitle('Params', 2);
    makeTableFromObjArray(md, module.params, 'params', 
                          ['name', 'init', 'empty', 'desc'],
                          ['Param Name', 'Init', 'Range', 'Description']);
    md.addEnter();
    

    // port section
    md.addTitle('Ports', 2);
    makeTableFromObjArray(md, module.ports, 'ports', 
                          ['name', 'type', 'width', 'desc'],
                          ['Port Name', 'Direction', 'Range', 'Description']);
    md.addEnter();
    
    // dependency section
    md.addTitle('Dependency', 2);
    const insts = [];
    for (const inst of module.getAllInstances()) {
        insts.push(inst);
    }
    
    makeTableFromObjArray(md, insts, 'Dependencies',
                         ['name', 'type', 'instModPath'],
                         ['name', 'module', 'source']);

    md.addEnter();
    return md;
}


/**
 * @description get basedoc obj according to a file
 * @param path absolute path of the file
 */
async function getDocsFromFile(path: AbsPath): Promise<MarkdownString[] | undefined> {
    const { t } = vscode.l10n;

    let moduleFile = hdlParam.getHdlFile(path);
    // 没有说明是单文件模式，直接打开解析
    if (!moduleFile) {
        const standardPath = hdlPath.toSlash(path);
        const response = await doFastApi(standardPath, 'common');
        const langID = hdlFile.getLanguageId(standardPath);
        moduleFile = new HdlFile(
            standardPath, langID,
            response?.macro || defaultMacro,
            response?.content || [],
            'common'
        );
        // 从 hdlParam 中去除，避免干扰全局
        hdlParam.removeFromHdlFile(moduleFile);

        // const message = t('error.common.not-valid-hdl-file');
        // const errorMsg = path + ' ' + message + ' ' + opeParam.prjInfo.hardwareSrcPath + '\n' + opeParam.prjInfo.hardwareSimPath;
        // vscode.window.showErrorMessage(errorMsg);
        // return undefined;
    }
    const markdownStringPromises = [];
    for (const module of moduleFile.getAllHdlModules()) {
        const markdownStringPromise = getDocsFromModule(module);
        markdownStringPromises.push(markdownStringPromise);
    }
    const fileDocs = [];
    for (const p of markdownStringPromises) {
        const markdownString = await p;
        fileDocs.push(markdownString);
    }
    return fileDocs;
}

/**
 * @description get render list of path
 * @param path
 */
async function getRenderList(path: AbsPath): Promise<RenderString[] | undefined> {
    if (!hdlFile.isHDLFile(path)) {
        vscode.window.showErrorMessage('Please use the command in a HDL file!');
        return [];
    }
    const docs = await getDocsFromFile(path);
    const svgs = await getWavedromsFromFile(path);
    if (docs && svgs) {
        const renderList = mergeSortByLine(docs, svgs);
        return renderList;
    }
    return undefined;
}


/**
 * @description return render list of current file 
 */
async function getCurrentRenderList(): Promise<RenderString[] | undefined> {
    const editor = vscode.window.activeTextEditor;
    if (editor) {
        const currentFilePath = hdlPath.toSlash(editor.document.fileName);        
        return await getRenderList(currentFilePath);
    }
    return;
}

async function exportCurrentFileDocAsMarkdown() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        return;
    }
    const currentFilePath = hdlPath.toSlash(editor.document.fileName);
    const hdlFileName = hdlPath.basename(currentFilePath);

    const renderList = await getRenderList(currentFilePath);
    if (!renderList || renderList.length === 0) {
        return;
    }

    const wsPath = opeParam.workspacePath;
    const markdownFolderPath = hdlPath.join(wsPath, 'markdown');
    if (!fs.existsSync(markdownFolderPath)) {
        fs.mkdirSync(markdownFolderPath);
    }
    const currentRoot = hdlPath.join(markdownFolderPath, hdlFileName);
    if (fs.existsSync(currentRoot)) {
        hdlFile.rmSync(currentRoot);
    }
    fs.mkdirSync(currentRoot);
    const figureFolder = hdlPath.join(currentRoot, 'figure');
    fs.mkdirSync(figureFolder);

    let markdown = '';
    for (const r of renderList) {
        if (r instanceof MarkdownString) {
            markdown += r.renderMarkdown() + '\n';
        } else if (r instanceof WavedromString) {
            const svgString = r.render();
            const svgName = 'wavedrom-' + Count.svgMakeTimes + '.svg';
            const svgPath = hdlPath.join(figureFolder, svgName);
            fs.writeFileSync(svgPath, svgString);
            const relatePath = hdlPath.join('./figure', svgName);
            const svgHtml = makeSVGElementByLink(relatePath);
            markdown += '\n\n' + svgHtml + '\n\n';
        }
    }
    
    const markdownName = 'index.md';
    const markdownPath = hdlPath.join(currentRoot, markdownName);
    Count.svgMakeTimes = 0;
    fs.writeFileSync(markdownPath, markdown);
}

async function exportProjectDocAsMarkdown() {
    vscode.window.showInformationMessage('this is exportProjectDocAsMarkdown');
}

export {
    getDocsFromFile,
    getRenderList,
    getCurrentRenderList,
    exportCurrentFileDocAsMarkdown,
    exportProjectDocAsMarkdown
};