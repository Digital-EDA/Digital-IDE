import * as vscode from 'vscode';

import { AbsPath, MainOutput, opeParam, ReportType } from '../../global';
import { SimPath, SrcPath } from '../../global/prjInfo';
import { HdlInstance, hdlParam } from '../../hdlParser/core';
import { HdlFileType, Range } from '../../hdlParser/common';
import { hdlFile, hdlPath } from '../../hdlFs';
import { xilinx, itemModes, otherModes } from './common';
import { getIconConfig } from '../../hdlFs/icons';

let needExpand = true;

interface ModuleDataItem {
    icon: string,           // 图标
    name: string,           // module name
    type: string,
    range: Range | null,   
    path: AbsPath | undefined,      // path of the file
    parent: ModuleDataItem | null   // parent file
}

interface FirstTopItem {
    name: string,
    path: AbsPath | undefined
}

interface FirstTop {
    src: FirstTopItem | null,
    sim: FirstTopItem | null
}

function canExpandable(element: ModuleDataItem) {
    if (element.icon === 'src' || element.icon === 'sim') {     // src and sim can expand anytime
        return true;
    } else {
        const modulePath = element.path;
        if (!modulePath) {                              // unsolved module cannot expand
            return false;
        }
        const moduleName = element.name;
        if (!hdlParam.hasHdlModule(modulePath, moduleName)) {      // test or bug
            return false;
        }
        const module = hdlParam.getHdlModule(modulePath, moduleName);
        if (module) {
            return module.getInstanceNum() > 0;
        } else {
            return false;
        }
    }
}


class ModuleTreeProvider implements vscode.TreeDataProvider<ModuleDataItem> {
    treeEventEmitter: vscode.EventEmitter<ModuleDataItem>;
    treeEvent: vscode.Event<ModuleDataItem>;
    firstTop: FirstTop;
    srcRootItem: ModuleDataItem;
    simRootItem: ModuleDataItem;

    constructor() {
        this.treeEventEmitter = new vscode.EventEmitter<ModuleDataItem>();
        this.treeEvent = this.treeEventEmitter.event;
        this.firstTop = { 
            src: null,
            sim: null,
        };
        this.srcRootItem = {icon: 'src', type: HdlFileType.Src, name: 'src', range: null, path: '', parent: null};
        this.simRootItem = {icon: 'sim', type: HdlFileType.Sim, name: 'sim', range: null, path: '', parent: null};

    }

    public refresh(element?: ModuleDataItem) {
        if (element) {
            this.treeEventEmitter.fire(element);
        } else {
            // refresh all the root in default
            this.refreshSim();
            this.refreshSrc();
        }
    }

    public refreshSrc() {
        this.treeEventEmitter.fire(this.srcRootItem);
    }

    public refreshSim() {
        this.treeEventEmitter.fire(this.simRootItem);
    }


    public getTreeItem(element: ModuleDataItem): vscode.TreeItem | Thenable<vscode.TreeItem> {
        let itemName = element.name;
        if (itemModes.has(element.icon)) {
            itemName = `${element.type}(${itemName})`;
        }

        const expandable = canExpandable(element);
        let collapsibleState;
        if (!expandable) {
            collapsibleState = vscode.TreeItemCollapsibleState.None;
        } else if (needExpand) {
            collapsibleState = vscode.TreeItemCollapsibleState.Expanded;
        } else {
            collapsibleState = vscode.TreeItemCollapsibleState.Collapsed;
        }

        const treeItem = new vscode.TreeItem(itemName, collapsibleState);
        // set contextValue file -> simulate / netlist
        if (otherModes.has(element.icon)) {
            treeItem.contextValue = 'other';
        } else {
            treeItem.contextValue = 'file';
        }

        // set tooltip
        treeItem.tooltip = element.path;
        if (!treeItem.tooltip) {
            treeItem.tooltip = "can't find the module of this instance";
        }

        // set iconPath
        treeItem.iconPath = getIconConfig(element.icon);
        
        // set command
        treeItem.command = {
            title: "Open this HDL File",
            command: 'digital-ide.treeView.arch.openFile',
            arguments: [element.path, element.range],
        };

        return treeItem;
    }

    public getChildren(element?: ModuleDataItem | undefined): vscode.ProviderResult<ModuleDataItem[]> {
        if (element) {
            const name = element.name;
            if (name === 'sim' || name === 'src') {
                element.parent = null;
                return this.getTopModuleItemList(element);
            } else {
                return this.getInstanceItemList(element);
            }
        } else {
            // use roots in default
            return [
                this.srcRootItem,
                this.simRootItem,
            ];
        }
    }

    public getParent(element: ModuleDataItem): vscode.ProviderResult<ModuleDataItem> {
        return element.parent;
    }

    public getTopModuleItemList(element: ModuleDataItem): ModuleDataItem[] {
        // src or sim
        const hardwarePath = opeParam.prjInfo.arch.hardware;
        const moduleType = element.name as keyof (SrcPath & SimPath);

        const topModules = hdlParam.getTopModulesByType(moduleType);
        const topModuleItemList = topModules.map<ModuleDataItem>(module => ({
            icon: 'top',
            type: moduleType,
            name: module.name,
            range: module.range,
            path: module.path,
            parent: element,
        }));

        if (topModuleItemList.length > 0) {
            const type = moduleType as keyof FirstTop;

            const firstTop = topModuleItemList[0];
            if (!this.firstTop[type]) {
                this.setFirstTop(type, firstTop.name, firstTop.path);
            }
            const name = this.firstTop[type]!.name;
            const path = this.firstTop[type]!.path;
            const icon = this.makeFirstTopIconName(type);
            const range = firstTop.range;
            const parent = element;

            const tops = topModuleItemList.filter(item => item.path === path && item.name === name);
            const adjustItemList = [];
            if (tops.length > 0 || !hdlParam.hasHdlModule(path, name)) {
                // mean that the seleted top is an original top module
                // push it to the top of the *topModuleItemList*
                const headItem = tops[0] ? tops[0] : topModuleItemList[0];

                headItem.icon = icon;
                adjustItemList.push(headItem);
                for (const item of topModuleItemList) {
                    if (item !== headItem) {
                        adjustItemList.push(item);
                    }
                }
            } else {
                // mean the selected top is not an original top module
                // create it and add it to the head of *topModuleItemList*
                const selectedTopItem: ModuleDataItem = {icon, type, name, range, path, parent};
                adjustItemList.push(selectedTopItem);
                adjustItemList.push(...topModuleItemList);
            }
            return adjustItemList;
        }

        return topModuleItemList;
    }

    // 获取当前模块下的子模块
    public getInstanceItemList(element: ModuleDataItem): ModuleDataItem[] {
        if (!element.path) {
            return [];
        }

        const moduleDataItemList: ModuleDataItem[] = [];
        const targetModule = hdlParam.getHdlModule(element.path, element.name);

        if (targetModule) {
            for (const instance of targetModule.getAllInstances()) {
                const item: ModuleDataItem = {
                    icon: 'file',
                    type: instance.name,
                    name: instance.type,
                    range: instance.module ? instance.module.range : null,
                    path: instance.instModPath,
                    parent: element
                };

                if (item.type === element.type &&            // 防止递归
                    item.name === element.name &&
                    item.path === element.path) {
                    continue;
                }
                item.icon = this.judgeIcon(item, instance);
                
                moduleDataItemList.push(item);
            }
        } else {
            MainOutput.report(`cannot find ${element} in hdlParam when constructing treeView`, ReportType.Error);
        }

        return moduleDataItemList;
    }

    public setFirstTop(type: keyof FirstTop, name: string, path: AbsPath | undefined) {
        this.firstTop[type] = {name, path};
    }


    private makeFirstTopIconName(type: string): string {
        return 'current-' + type + '-top';
    }

    private judgeIcon(item: ModuleDataItem, instance: HdlInstance): string {
        const workspacePath = opeParam.workspacePath;
        if (hdlPath.exist(item.path)) {
            if (!item.path?.includes(workspacePath)) {
                return 'remote';
            } else {
                const langID = hdlFile.getLanguageId(item.path);
                return langID;
            }
        } else {
            if (xilinx.has(instance.type)) {
                return 'cells';
            } else {
                return 'File Error';
            }
        }
    }
}

const moduleTreeProvider = new ModuleTreeProvider();

export {
    moduleTreeProvider,
    ModuleDataItem
};