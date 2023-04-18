import * as vscode from 'vscode';
import * as fspath from 'path';
import * as fs from 'fs';

import { AbsPath, opeParam } from '../global';
import { PrjInfo, RawPrjInfo } from '../global/prjInfo';
import { HdlLangID } from '../global/enum';
import { hdlFile, hdlPath } from '../hdlFs';
import { getIconConfig } from '../hdlFs/icons';

type MissPathType = { path?: string };
type LibPickItem = vscode.QuickPickItem & MissPathType;

class LibPick {
    commonPath: AbsPath;
    customPath: AbsPath;
    commonQuickPickItem: LibPickItem;
    customQuickPickItem: LibPickItem;
    rootItems: LibPickItem[];
    backQuickPickItem: LibPickItem;
    curPath: AbsPath;
    selectedQuickPickItem: LibPickItem | undefined;

    constructor () {
        this.commonPath = opeParam.prjInfo.libCommonPath;
        this.customPath = opeParam.prjInfo.libCustomPath;
        
        this.commonQuickPickItem = {
            label: "$(libpick-common) common", 
            description: 'common library provided by us',
            detail: 'current path: ' + this.commonPath,
            path: this.commonPath,
            buttons: [{iconPath: getIconConfig('import'), tooltip: 'import everything in common'}]
        };

        this.customQuickPickItem = {
            label: "$(libpick-custom) custom", 
            description: 'custom library by yourself',
            detail: 'current path: ' + this.customPath,
            path: this.customPath,
            buttons: [{iconPath: getIconConfig('import'), tooltip: 'import everything in custom'}]
        };

        this.rootItems = [
            this.commonQuickPickItem,
            this.customQuickPickItem
        ];

        this.backQuickPickItem = {
            label: '...', 
            description: 'return'
        };

        this.curPath = '';
    }

    getPathIcon(path: AbsPath): string {
        let prompt;
        if (hdlFile.isFile(path)) {
            const langID = hdlFile.getLanguageId(path);
            if (langID === HdlLangID.Vhdl) {
                prompt = 'vhdl';
            } else if (langID === HdlLangID.Verilog ||
                       langID === HdlLangID.SystemVerilog) {
                prompt = 'verilog';
            } else {
                prompt = 'unknown';
            }
        } else {
            prompt = 'folder';
        }
        return `$(libpick-${prompt})`;
    }

    private getReadmeText(path: AbsPath, fileName: string): string | undefined {
        const mdPath1 = hdlPath.join(path, fileName, 'readme.md');
        if (fs.existsSync(mdPath1)) {
            return hdlFile.readFile(mdPath1);
        }
        const mdPath2 = hdlPath.join(path, fileName, 'README.md');
        if (fs.existsSync(mdPath2)) {
            return hdlFile.readFile(mdPath2);
        }
        return undefined;
    }

    private makeQuickPickItemsByPath(path: AbsPath, back: boolean=true): LibPickItem[] {
        const items: LibPickItem[] = [];
        if (!hdlPath.exist(path)) {
            return items;
        }
        if (back) {
            items.push(this.backQuickPickItem);
        }

        for (const fileName of fs.readdirSync(path)) {
            const filePath = hdlPath.join(path, fileName);
            const themeIcon = this.getPathIcon(filePath);
            const label = themeIcon + " " + fileName;
            const mdText = this.getReadmeText(path, fileName);
            const description = mdText ? mdText : '';
            const buttons = [{iconPath: getIconConfig('import'), tooltip: 'import everything in ' + fileName}];
            items.push({label, description, path: filePath, buttons});
        }
        return items;
    }

    private provideQuickPickItem(item?: LibPickItem) {
        if (!item) {
            return this.rootItems;
        } else if (item === this.backQuickPickItem) {
            if ((this.curPath === this.commonPath) || 
                (this.curPath === this.customPath)) {
                return this.rootItems;
            } else {
                // rollback the current path
                this.curPath = fspath.dirname(this.curPath);
            }
        } else if (item === this.commonQuickPickItem) {
            this.curPath = this.commonPath;
        } else if (item === this.customQuickPickItem) {
            this.curPath = this.customPath;
        } else {
            const label = item.label;
            const fileName = label.replace(/\$\([\s\S]*\)/, '').trim();
            this.curPath = hdlPath.join(this.curPath, fileName);
        }

        return this.makeQuickPickItemsByPath(this.curPath);
    }

    async pickItems() {
        const pickWidget = vscode.window.createQuickPick<LibPickItem>();
        
        pickWidget.placeholder = 'pick the library';
        pickWidget.items = this.provideQuickPickItem();
        
        pickWidget.onDidChangeSelection(items => {
            if (items[0]) {
                this.selectedQuickPickItem = items[0];
            }
        });

        pickWidget.onDidAccept(() => {
            if (this.selectedQuickPickItem) {
                const childernItems = this.provideQuickPickItem(this.selectedQuickPickItem);
                if (childernItems && childernItems.length > 0) {
                    pickWidget.items = childernItems;
                }
            }
        });

        pickWidget.onDidTriggerItemButton(event => {
            const selectedPath = event.item.path;

            if (selectedPath && hdlPath.exist(selectedPath)) {
                const userPrjInfo = opeParam.getUserPrjInfo();
                console.log(userPrjInfo);
                
                if (selectedPath.includes(this.commonQuickPickItem.path!)) {
                    // this is a module import from common, use relative path
                    const relPath = selectedPath.replace(this.commonQuickPickItem.path + '/', '');
                    userPrjInfo.appendLibraryCommonPath(relPath);
                } else {
                    // this is a module import from custom, use absolute path
                    const relPath = selectedPath.replace(this.customQuickPickItem.path + '/', '');
                    userPrjInfo.appendLibraryCustomPath(relPath);
                }

                // acquire raw and replace it
                const rawUserPrjInfo = opeParam.getRawUserPrjInfo();
                rawUserPrjInfo.library = userPrjInfo.library;
                hdlFile.writeJSON(opeParam.propertyJsonPath, rawUserPrjInfo);
            }
        });

        pickWidget.show();
    }
}

function pickLibrary() {
    const picker = new LibPick();
    picker.pickItems();
}

export {
    LibPick,
    LibPickItem,
    pickLibrary
};