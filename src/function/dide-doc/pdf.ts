import * as vscode from 'vscode';
import * as fs from 'fs';
import * as puppeteer from 'puppeteer-core';

import { makeShowHTML } from './html';
import { hdlFile, hdlPath } from '../../hdlFs';
import { AbsPath, MainOutput, opeParam, ReportType } from '../../global';
import { t } from '../../i18n';

// TODO : finish it in each platform
function getDefaultBrowerPath(): AbsPath {
    const browserPath = vscode.workspace.getConfiguration().get<string>('digital-ide.function.doc.pdf.browserPath.title');
    if (browserPath && fs.existsSync(browserPath)) {
        return browserPath;
    }
    switch (opeParam.os) {
        case 'win32': return 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
        case 'linux': return '';
        default: return '';
    }
}

/**
 * @description transform a html file to pdf file
 * @param htmlPath absolute path of input html
 * @param pdfPath output path of pdf
*/
async function htmlFile2PdfFile(htmlPath: AbsPath, pdfPath: AbsPath) {    
    const pdfConfig = vscode.workspace.getConfiguration("digital-ide.function.doc.pdf");
    const platformDefaultBrowerPath = getDefaultBrowerPath();
    
    const browserPath = pdfConfig.get<string>('browserPath') || platformDefaultBrowerPath;
    
    if (!fs.existsSync(browserPath)) {
        const res = await vscode.window.showErrorMessage(
            t('error.not-valid-browser', browserPath),
            { title: t('info.config-browser-path'), value: true }
        );

        if (res?.value) {
            await vscode.commands.executeCommand('workbench.action.openSettings', 'digital-ide.function.doc.pdf.browserPath');
        }
        return;
    }
    const browser = await puppeteer.launch({
        executablePath: browserPath,
        args: ['--lang=' + vscode.env.language, '--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    const uriFilePath = vscode.Uri.file(htmlPath).toString();

    await page.goto(uriFilePath, { waitUntil: 'networkidle0' });

    const options = {
        path: pdfPath,
        scale: pdfConfig.scale,
        displayHeaderFooter: pdfConfig.displayHeaderFooter,
        headerTemplate: pdfConfig.headerTemplate,
        footerTemplate: `<div style="font-size: 15px; margin: 0 auto;">CodeDoc - Powered By Digital IDE</div>`,
        printBackground: pdfConfig.printBackground,
        landscape: pdfConfig.landscape,
        format: pdfConfig.format,
        margin: {
            top: pdfConfig.margin.top + 'cm',
            right: pdfConfig.margin.right + 'cm',
            bottom: pdfConfig.margin.bottom + 'cm',
            left: pdfConfig.margin.left + 'cm'
        }
    };
    await page.pdf(options);
    await browser.close();
}

async function exportCurrentFileDocAsPDF(uri: vscode.Uri) {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        return;
    }
    const currentFilePath = hdlPath.toSlash(editor.document.fileName);
    const hdlFileName = hdlPath.basename(currentFilePath);
    const wsPath = opeParam.workspacePath;

    return vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: t('info.pdf.exporting', currentFilePath),
        cancellable: true
    }, async progress => {
        try {
            const html = await makeShowHTML(uri, "pdf");

            if (!html) {
                return;
            }
            
            const pdfFolderPath = hdlPath.join(wsPath, 'doc');
            if (!fs.existsSync(pdfFolderPath)) {
                fs.mkdirSync(pdfFolderPath);
            }
        
            const pdfName = hdlFileName + '.pdf';
            const pdfPath = hdlPath.join(pdfFolderPath, pdfName);
            if (fs.existsSync(pdfPath)) {
                hdlFile.rmSync(pdfPath);
            }
        
            const tempHtmlName = hdlFileName + '.tmp.html';
            const tempHtmlPath = hdlPath.join(pdfFolderPath, tempHtmlName);
            if (fs.existsSync(tempHtmlPath)) {
                hdlFile.rmSync(tempHtmlPath);
            }
        
            fs.writeFileSync(tempHtmlPath, html);
            await htmlFile2PdfFile(tempHtmlPath, pdfPath);
            // hdlFile.rmSync(tempHtmlPath);

            // 在当前编辑器中打开生成的 pdf
            if (fs.existsSync(pdfPath)) {
                vscode.window.showInformationMessage(t('info.generate-pdf-to', pdfFolderPath));
            }
            
        } catch (error) {
            MainOutput.report("error happen in export pdf: " + error, {
                level: ReportType.Error
            });
            return;
        }
    });
}

function exportProjectDocAsPDF() {
    vscode.window.showInformationMessage('this is exportProjectDocAsPDF');   
}

export {
    exportCurrentFileDocAsPDF,
    exportProjectDocAsPDF
};