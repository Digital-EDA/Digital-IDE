import * as vscode from 'vscode';
import { AbsPath } from '../../global';

interface ModuleDataItem {
    icon: string,           // 图标
    name: string,           // module name
    type: string,           
    path: AbsPath,                // path of the file
    parent: ModuleDataItem | null   // parent file
}

interface SelectTop {
    src: any,
    sim: any
}


class ModuleTreeProvider implements vscode.TreeDataProvider<ModuleDataItem> {
    treeEventEmitter: vscode.EventEmitter<ModuleDataItem>;
    treeEvent: vscode.Event<ModuleDataItem>;

    constructor() {
        this.treeEventEmitter = new vscode.EventEmitter<ModuleDataItem>();
        this.treeEvent = this.treeEventEmitter.event;

        
    }


    getTreeItem(element: ModuleDataItem): vscode.TreeItem | Thenable<vscode.TreeItem> {
        
    }

    getChildren(element?: ModuleDataItem | undefined): vscode.ProviderResult<ModuleDataItem[]> {
        if (element) {
            const name = element.name;
            if (name === 'sim' || name === 'src') {
                element.parent = null;

            }
        } else {

        }
    }

    getParent(element: ModuleDataItem): vscode.ProviderResult<ModuleDataItem> {
        
    }

    getTopModuleItemList(element: ModuleDataItem): ModuleDataItem[] {
        
    }
}