import * as vscode from 'vscode';
import * as fspath from 'path';
import * as fs from 'fs';

import { AbsPath, opeParam } from '../global';
import { HdlLangID } from '../global/enum';
import { hdlDir, hdlFile, hdlPath } from '../hdlFs';
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
        this.commonPath = hdlPath.join(opeParam.extensionPath, 'lib', 'common');
        this.customPath = hdlPath.toSlash(vscode.workspace.getConfiguration('PRJ.custom.Lib.repo').get('path', '')); 
        
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
            const mdPath = hdlPath.join(path, fileName, 'readme.md');
            const mdText = hdlFile.readFile(mdPath);
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
            console.log('enter onDidChangeSelection');
            if (items[0]) {
                this.selectedQuickPickItem = items[0];
            }
        });

        pickWidget.onDidAccept(() => {
            console.log('enter onDidAccept');
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
                const ppyPath = hdlPath.join(opeParam.workspacePath, '.vscode', 'property.json');

                // 抽象这块
                let prjInfo = null;
                // 如果存在，则读取用户的配置文件，否则使用默认的
                if (!hdlPath.exist(ppyPath)) {
                    prjInfo = hdlFile.readJSON(opeParam.propertyInitPath);
                } else {
                    prjInfo = hdlFile.readJSON(ppyPath);
                }

                if (selectedPath.includes(this.commonQuickPickItem.path!)) {
                    // this is a module import from common, use relative path
                    const relPath = selectedPath.replace(this.commonQuickPickItem.path + '/', '');                    
                    appendLibraryCommonPath(relPath, prjInfo);
                } else {
                    // this is a module import from custom, use absolute path
                    const relPath = selectedPath.replace(this.customQuickPickItem.path + '/', '');
                    appendLibraryCustomPath(relPath, prjInfo);
                }
                hdlFile.writeJSON(ppyPath, prjInfo);
            }
        });

        pickWidget.show();
    }
}