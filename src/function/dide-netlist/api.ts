import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

import pako from 'pako';
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
        const vcdFilters: Record<string, string[]> = {};
        vcdFilters[""] = ['svg'];
        vcdFilters[t('info.vcd-viewer.all-file')] = ['*'];

        const saveUri = await vscode.window.showSaveDialog({
            title: t('info.vcd-viewer.save-as-view'),
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

export async function saveAsPdf(req: Request, res: Response) {
    try {
        const { svgBuffer, moduleName, width, height } = req.body;
        const svgString = pako.ungzip(svgBuffer, { to: 'string' });
        // 询问新的路径        
        const defaultFilename = moduleName + '.pdf';
        const savePath = await showSaveViewDialog({
            title: 'Save As pdf',
            defaultPath: path.resolve(__dirname, '../test', defaultFilename),
            buttonLabel: 'Save',
            filters: [
                { name: 'pdf', extensions: ['pdf'] },
                { name: 'All Files', extensions: ['*'] },
            ],
        });

        if (savePath) {
            // 先保存 html
            const htmlPath = savePath.slice(0, -4) + '.html';
            fs.writeFileSync(htmlPath, svgString);

            await html2pdf(htmlPath, savePath, moduleName, width, height);
            // removeBlankPages(savePath);

            res.send({
                savePath,
                success: true
            });
        } else {
            res.send({
                success: false
            });
        }
    } catch (error) {
        console.log('error happen in /save-as-pdf, ' + error);
        res.send({
            success: false
        });
    }   
}

async function html2pdf(htmlPath: string, pdfPath: string, moduleName: string, width: number, height: number) {    
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