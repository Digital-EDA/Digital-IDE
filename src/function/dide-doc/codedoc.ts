import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';

import * as puppeteer from 'puppeteer-core';
import { PDFOptions, PaperFormat } from 'puppeteer-core';
import * as pako from 'pako';
import { t } from '../../i18n';
import { hdlPath } from '../../hdlFs';
import { opeParam } from '../../global';

export interface IPdfSetting {
    scale: number
    printBackground: boolean
    landscape: boolean
    format: string
}


async function htmlFile2PdfFile(htmlPath: string, pdfPath: string, option?: IPdfSetting) {
    const browserPath = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';

    option = option || { scale: 1, printBackground: true, landscape: false, format: 'a4' };

    const browser = await puppeteer.launch({
        headless: 'new',
        executablePath: browserPath,
        args: ['--lang=en', '--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();

    const absoluteHtmlPath = path.resolve(htmlPath);
    const uriFilePath = `file://${absoluteHtmlPath.replace(/\\/g, '/')}`;
    await page.goto(uriFilePath, { waitUntil: 'networkidle0' });

    const options: PDFOptions = {
        path: pdfPath,
        displayHeaderFooter: true,
        // headerTemplate: '',
        // footerTemplate: `<div style="font-size: 15px; margin: 0 auto; color: #CB81DA">CodeDoc - Powered By Digital IDE</div>`,
        scale: option.scale,
        printBackground: option.printBackground,
        landscape: option.landscape,
        format: option.format as PaperFormat,
        margin: {
            top: 0,
            right: 0,
            bottom: 0,
            left: 0
        }
    };
    await page.pdf(options);
    await browser.close();
}


export async function getDocIR(data: any, panel: vscode.WebviewPanel, codeDocIr: any) {
    const docIrPath = './static/codedoc.test.json';
    const raw = fs.readFileSync(docIrPath, { encoding: 'utf-8' });
    panel.webview.postMessage({
        command: 'get-doc-ir',
        codeDocIr
    });
}

function makeHtmlFromTemplate(content: string, backgroundColor: string): string {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Digital IDE</title>
</head>
<body>
<div class="dide-svg">
    ${content}
</div>
</body>
<style>
.dide-svg {
    background-color: ${backgroundColor};
    width: 100vw;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
}
</style>
</html>
    `.trim();
}

export async function downloadSvg(data: any, panel: vscode.WebviewPanel) {
    try {
        const { svgString, format, backgroundColor } = data;
        switch (format) {
            case 'pdf':
                await downloadAsPdf(svgString, backgroundColor);
                break;
            case 'svg':
                await downloadAsSvg(svgString);
                break;
            case 'markdown':
                await downloadAsMarkdown(svgString);
                break;
        
            default:
                break;
        }

    } catch (error) {
        console.log('发生错误 downloadSvg');
        console.error(error);
    }
}

async function downloadAsPdf(svgString: string, backgroundColor: string) {
    const defaultFilename = '.pdf';
    const defaultPath = hdlPath.join(opeParam.workspacePath, defaultFilename);
    const saveUri = await vscode.window.showSaveDialog({
        title: t('toolbar.save-as-pdf'),
        defaultUri: vscode.Uri.file(defaultPath),
        saveLabel: t('info.vcd-viewer.save'),
        filters: {
            [t('pdf-file')]: ['pdf'],
            [t("info.vcd-viewer.all-file")]: ['*']
        }
    });

    if (saveUri) {
        const savePath = saveUri.fsPath;
        const html = makeHtmlFromTemplate(svgString, backgroundColor);
        fs.writeFileSync(savePath + '.html', html);
        await htmlFile2PdfFile(savePath + '.html', savePath);
    }
}

async function downloadAsSvg(svgString: string) {
    const defaultFilename = '.svg';
    const defaultPath = hdlPath.join(opeParam.workspacePath, defaultFilename);

    const saveUri = await vscode.window.showSaveDialog({
        title: t('netlist.save-as-svg'),
        defaultUri: vscode.Uri.file(defaultPath),
        saveLabel: t('info.vcd-viewer.save'),
        filters: {
            [t('svg-file')]: ['svg'],
            [t("info.vcd-viewer.all-file")]: ['*']
        }
    });

    if (saveUri) {
        const savePath = saveUri.fsPath;
        fs.writeFileSync(savePath, svgString);
    }
}

async function downloadAsMarkdown(svgString: string) {
    const defaultFilename = '.md';
    const defaultPath = hdlPath.join(opeParam.workspacePath, defaultFilename);

    const saveUri = await vscode.window.showSaveDialog({
        title: t('netlist.save-as-markdown'),
        defaultUri: vscode.Uri.file(defaultPath),
        saveLabel: t('info.vcd-viewer.save'),
        filters: {
            [t('markdown-file')]: ['md'],
            [t("info.vcd-viewer.all-file")]: ['*']
        }
    });

    if (saveUri) {
        const savePath = saveUri.fsPath;
        fs.writeFileSync(savePath, svgString);
    }
}


function makeDocHtmlFromTemplate(content: string, cssString: string): string {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Digital IDE</title>
</head>
<body>
<div class="vscode-dark dide-doc">
${content}
</div>
</body>
<style>
.dide-doc {
    width: 100vw;
    height: 100vh;
} 
${cssString}
</style>
</html>
    `.trim();
}

function getNameFromFileName(filename: string) {
    if (filename) {
        if (filename.includes('/')) {
            return filename.split('/').at(-1) || '';
        }
        return filename;
    }

    return '';
}

export async function exportDocHtml(data: any, panel: vscode.WebviewPanel) {
    try {
        const { renderStringArray, cssStringArray, filename, option } = data;
        const renderString = pako.ungzip(renderStringArray, { to: 'string' });
        const cssString = pako.ungzip(cssStringArray, { to: 'string' });
        const html = makeDocHtmlFromTemplate(renderString, cssString);

        const defaultFilename = getNameFromFileName(filename) + '.html';
        const defaultPath = hdlPath.join(opeParam.workspacePath, defaultFilename);
        const saveUri = await vscode.window.showSaveDialog({
            title: t('toolbar.save-as-html'),
            defaultUri: vscode.Uri.file(defaultPath),
            saveLabel: t('info.vcd-viewer.save'),
            filters: {
                [t('html-file')]: ['html'],
                [t("info.vcd-viewer.all-file")]: ['*']
            }
        });
    
        if (saveUri) {
            const savePath = saveUri.fsPath;
            fs.writeFileSync(savePath, html);
        }
    } catch (error) {
        console.error(error);
    }
}

export async function exportDocPdf(data: any, panel: vscode.WebviewPanel) {
    try {
        const { renderStringArray, cssStringArray, filename, option } = data;
        const renderString = pako.ungzip(renderStringArray, { to: 'string' });
        const cssString = pako.ungzip(cssStringArray, { to: 'string' });
        const html = makeDocHtmlFromTemplate(renderString, cssString);

        const defaultFilename = getNameFromFileName(filename) + '.pdf';
        const defaultPath = hdlPath.join(opeParam.workspacePath, defaultFilename);
        const saveUri = await vscode.window.showSaveDialog({
            title: t('toolbar.save-as-pdf'),
            defaultUri: vscode.Uri.file(defaultPath),
            saveLabel: t('info.vcd-viewer.save'),
            filters: {
                [t('pdf-file')]: ['pdf'],
                [t("info.vcd-viewer.all-file")]: ['*']
            }
        });
    
        if (saveUri) {
            const savePath = saveUri.fsPath;
            const tempPath = savePath + '.html';
            fs.writeFileSync(tempPath, html);
            console.log(option);
            htmlFile2PdfFile(tempPath, savePath, option);
        }
    } catch (error) {
        console.error(error);
    }
}

export async function exportDocMarkdown(data: any, panel: vscode.WebviewPanel) {
    try {
        const { renderStringArray, cssStringArray, filename, option } = data;
        const renderString = pako.ungzip(renderStringArray, { to: 'string' });
        const cssString = pako.ungzip(cssStringArray, { to: 'string' });

        console.log('receive renderString size: ' + renderString.length);

        const html = makeDocHtmlFromTemplate(renderString, cssString);

        const defaultFilename = getNameFromFileName(filename) + '.md';
        const defaultPath = hdlPath.join(opeParam.workspacePath, defaultFilename);
        const saveUri = await vscode.window.showSaveDialog({
            title: t('netlist.save-as-markdown'),
            defaultUri: vscode.Uri.file(defaultPath),
            saveLabel: t('info.vcd-viewer.save'),
            filters: {
                [t('markdown-file')]: ['md'],
                [t("info.vcd-viewer.all-file")]: ['*']
            }
        });
    
        if (saveUri) {
            const savePath = saveUri.fsPath;
            const tempPath = savePath + '.html';
            fs.writeFileSync(tempPath, html);
            console.log(option);
            htmlFile2PdfFile(tempPath, savePath, option);
        }
    } catch (error) {
        console.error(error);
    }
}