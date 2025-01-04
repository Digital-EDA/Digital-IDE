import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

import * as pako from 'pako';
import puppeteer, { LowerCasePaperFormat, PDFOptions } from 'puppeteer-core';
import { AbsPath, opeParam } from '../../global';
import { hdlPath } from '../../hdlFs';
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

export async function saveAsSvg(data: any, panel: vscode.WebviewPanel) {
    try {
        const { svgBuffer, moduleName } = data;
        const svgString = pako.ungzip(svgBuffer, { to: 'string' });
        // 询问新的路径        
        const defaultFilename = moduleName + '.svg';
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
            
            panel.webview.postMessage({
                command: 'save-as-svg',
                arguments: [{ success: true }] 
            });

        } else {
            panel.webview.postMessage({
                command: 'save-as-svg',
                arguments: [{ success: false }] 
            });
        }
    } catch (error) {
        console.log('error happen in /save-as-svg, ' + error);
        panel.webview.postMessage({
            command: 'save-as-svg',
            arguments: [{ success: false }] 
        });
    }   
}

export async function saveAsPdf(data: any, panel: vscode.WebviewPanel) {
    try {
        const { svgBuffer, moduleName, width, height } = data;
        const svgString = pako.ungzip(svgBuffer, { to: 'string' });
        // 询问新的路径        
        const defaultFilename = moduleName + '.pdf';
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
            // 先保存 html
            const htmlPath = savePath.slice(0, -4) + '.html';
            fs.writeFileSync(htmlPath, svgString);

            await vscode.window.withProgress({
                title: t('export-pdf'),
                location: vscode.ProgressLocation.Notification
            }, async () => {
                await html2pdf(htmlPath, savePath, moduleName, width, height);
            });
            fs.rmSync(htmlPath);

            panel.webview.postMessage({
                command: 'save-as-pdf',
                arguments: [{ success: true }] 
            });
        } else {
            panel.webview.postMessage({
                command: 'save-as-pdf',
                arguments: [{ success: false }] 
            });
        }
    } catch (error) {
        console.log('error happen in /save-as-pdf, ' + error);
        panel.webview.postMessage({
            command: 'save-as-pdf',
            arguments: [{ success: false }] 
        });
    }   
}

async function html2pdf(htmlPath: string, pdfPath: string, moduleName: string, width: number, height: number) {    
    const browserPath = getDefaultBrowerPath();
    const browser = await puppeteer.launch({
        executablePath: browserPath,
        args: ['--lang=en-US', '--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    const uriFilePath = 'file:///' + path.resolve(htmlPath).replace(/\\/g, "/");
    await page.goto(uriFilePath, { waitUntil: 'networkidle0' });

    const options: PDFOptions = {
        path: pdfPath,
        scale: 1,
        displayHeaderFooter: true,
        // headerTemplate: `<div style="font-size: 12px; margin-left: 1cm;">module ${moduleName}</div>`,
        footerTemplate: `<div style="font-size: 15px; margin: 0 auto;">Netlist for <code>${moduleName}</code> - 由 Digital IDE 生成 </div>`,
        printBackground: true,
        landscape: true,
        width: width
    };
    await page.pdf(options);
    await browser.close();
}