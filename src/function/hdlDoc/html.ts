import * as assert from 'assert';
import * as vscode from 'vscode';
import * as fs from 'fs';

import { opeParam, MainOutput, AbsPath } from '../../global';

import { Count, MarkdownString, ThemeColorConfig, WavedromString } from './common';
import { getRenderList, getCurrentRenderList } from './markdown';
import { hdlPath, hdlIcon, hdlFile } from '../../hdlFs'; 
import { ThemeType } from '../../global/enum';

const _cache = {
    css : ''
};

function makeFinalHTML(body: string, style: string): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="wrapper">
        <div id="write">
            ${body}
        </div>
    </div>
</body>
<script>
const vscode = acquireVsCodeApi();

document.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', (event) => {
        event.preventDefault();
        const href = link.getAttribute('href');
        if (href.startsWith('file://')) {
            vscode.postMessage({
                command: 'openFile',
                filePath: href
            });
        }
    });
});
</script>
<style>
    ${style}
</style>
</html>`;
}


function makeExportHTML(cssHref: string, body: string): string {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <link rel="stylesheet" type="text/css" href="${cssHref}"></link>
</head>
<body>
    <div id="wrapper">
        <div id="write">
            ${body}
        </div>
    </div>
</body>
</html>`;
}

function makeCommonElement(renderResult: string): string {
    return renderResult + '<br>\n';
}

function makeSVGElement(renderResult: string, caption: string): string {
    let mainHtml;
    if (caption) {
        mainHtml = '<div align=center>' + renderResult + `<p class="ImgCaption">${caption}</p>` + '</div>';
    } else {
        mainHtml = '<div align=center>' + renderResult + '</div>';
    }
    return '<br>' + mainHtml + '<br><br>\n';
}

function makeSVGElementByLink(link: AbsPath, caption: string): string {
    let mainHtml;
    if (caption) {
        mainHtml = `<div align=center><img src="${link}"></img><p class="ImgCaption">${caption}</p></div>`;
    } else {
        mainHtml = `<div align=center><img src="${link}"></img></div>`;
    }
    return '<br>' + mainHtml + '<br><br>\n';
}

function getDocCssString() {
    if (_cache.css) {
        return _cache.css;
    } else {
        const cssPath = hdlPath.join(opeParam.extensionPath, 'css/documentation.css');
        const cssString = fs.readFileSync(cssPath, 'utf-8');
        _cache.css = cssString;
        return cssString;
    }
}


function makeWavedromRenderErrorHTML() {
    return `<div class="error-out">
    <p class="error">Error Render</p>
</div><br>`;
}


/**
 * @description make the html string of a finial display style
 * @param usage in whick module is used
 */
async function makeShowHTML(usage: 'webview' | 'pdf' | 'html' | 'markdown'): Promise<string> {

    // start to render the real html
    let body = '';
    const userStyle = (usage === 'webview' || usage === 'markdown') ? undefined : ThemeType.Light;
    ThemeColorConfig.specify = userStyle;

    const renderList = await getCurrentRenderList();
    if (!renderList || renderList.length === 0) {
        return '';
    }
    
    for (const r of renderList) {
        const renderResult = r.render();
        if (renderResult) {
            if (r instanceof MarkdownString) {
                body += makeCommonElement(renderResult);
            } else if (r instanceof WavedromString) {
                body += makeSVGElement(renderResult, r.desc);
            }
        } else {
            body += makeWavedromRenderErrorHTML();
        }
    }

    // add css
    let cssString = getDocCssString();
    if (usage === 'webview') {          // if invoked by webview, change background image
        const webviewConfig = vscode.workspace.getConfiguration("digital-ide.function.doc.webview");
        const imageUrl = webviewConfig.get('backgroundImage', '');
        cssString = cssString.replace("--backgroundImage", imageUrl);
    } else if (usage === 'pdf') {      // if invoked by pdf, transform .vscode-light to #write
        cssString = cssString.replace(/\.vscode-light/g, '#write');
    }
    const html = makeFinalHTML(body, cssString);
    ThemeColorConfig.specify = undefined;
    
    return html;
}

async function showDocWebview() {
    const htmlPromise = makeShowHTML("webview");
    const webview = vscode.window.createWebviewPanel(
        'TOOL.doc.webview.show', 
        'document',
        vscode.ViewColumn.Two,
        {
            enableScripts: true,            // enable JS
            retainContextWhenHidden: true,  // unchange webview when hidden, prevent extra refresh
        }
    );

    webview.iconPath = hdlIcon.getIconConfig('documentation');
    webview.webview.html = await htmlPromise;
    webview.webview.onDidReceiveMessage(message => {
        switch (message.command) {
            case 'openFile':
                let filePath: string = message.filePath;
                if (filePath.startsWith('file://')) {
                    filePath = filePath.slice(7);
                }
                console.log('debug, ', filePath);
                
                const uri = vscode.Uri.file(filePath);
                vscode.commands.executeCommand('vscode.open', uri);
                return;
        }
    });
}


async function exportCurrentFileDocAsHTML() {
    if (vscode.window.activeColorTheme.kind !== vscode.ColorThemeKind.Light) {
        vscode.window.showErrorMessage('Please export html in a light theme!');
        return;
    }

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
    const markdownFolderPath = hdlPath.join(wsPath, 'html');
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

    const cssFolder = hdlPath.join(currentRoot, 'css');
    fs.mkdirSync(cssFolder);
    const relateCssPath = './css/index.css';
    const cssPath = hdlPath.join(cssFolder, 'index.css');
    let cssString = getDocCssString();

    // only support export in the ligth theme
    cssString = cssString.replace(/\.vscode-light/g, '#write');
    fs.writeFileSync(cssPath, cssString);

    let body = '';
    for (const r of renderList) {
        const renderResult = r.render();
        if (r instanceof MarkdownString) {
            body += makeCommonElement(renderResult);
        } else if (r instanceof WavedromString) {
            const svgName = 'wavedrom-' + Count.svgMakeTimes + '.svg';
            const svgPath = hdlPath.join(figureFolder, svgName);
            fs.writeFileSync(svgPath, renderResult);
            const relatePath = hdlPath.join('./figure', svgName);
            body += makeSVGElementByLink(relatePath, r.desc);
        }
    }

    const html = makeExportHTML(relateCssPath, body);    
    const htmlName = 'index.html';
    const htmlPath = hdlPath.join(currentRoot, htmlName);
    Count.svgMakeTimes = 0;
    fs.writeFileSync(htmlPath, html);
}

async function exportProjectDocAsHTML() {
    vscode.window.showInformationMessage('this is exportProjectDocAsHTML');
}

export {
    showDocWebview,
    exportCurrentFileDocAsHTML,
    exportProjectDocAsHTML,
    makeShowHTML,
    makeSVGElementByLink
};