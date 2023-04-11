/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import { getIconConfig } from '../../hdlFs/icons';

interface CommandDataItem {
    name: string,
    cmd: string,
    icon: string,
    tip: string,
    children: any[]
}

type CommandConfig = Record<string, {
    cmd: string,
    icon: string,
    tip: string,
    children?: CommandConfig,
}>;

class BaseCommandTreeProvider implements vscode.TreeDataProvider<CommandDataItem> {
    config: CommandConfig;
    contextValue: 'HARD' | 'SOFT' | 'TOOL';

    constructor(config: CommandConfig, contextValue: 'HARD' | 'SOFT' | 'TOOL') {
        this.config = config;
        this.contextValue = contextValue;
    }

    // 根据对象遍历属性，返回CommandDataItem数组
    public makeCommandDataItem(object: any): CommandDataItem[] {
        const childDataItemList = [];
        for (const key of Object.keys(object)) {
            const el = object[key];
            const dataItem: CommandDataItem = { name: key, cmd: el.cmd, icon: el.icon, tip: el.tip, children: el.children };
            childDataItemList.push(dataItem);
        }
        return childDataItemList;
    }

    public getChildren(element: CommandDataItem): CommandDataItem[] {
        if (element) {
            if (element.children) {
                return this.makeCommandDataItem(element.children);
            } else {
                return [];
            }
        } else {            // 第一层
            return this.makeCommandDataItem(this.config);
        }
    }


    // 根据输入的CommandDataItem转化为vscode.TreeItem
    getTreeItem(element: CommandDataItem): vscode.TreeItem | Thenable<vscode.TreeItem> {
        const childNum = Object.keys(element.children).length;
        const treeItem = new vscode.TreeItem(
            element.name,
            childNum === 0 ?
            vscode.TreeItemCollapsibleState.None :
            vscode.TreeItemCollapsibleState.Collapsed
        );
        treeItem.contextValue = this.contextValue;
        treeItem.command = {
            title: element.cmd,
            command: element.cmd,
        };

        treeItem.tooltip = element.tip;

        treeItem.iconPath = getIconConfig(element.icon);

        return treeItem;   
    }
};

class HardwareTreeProvider extends BaseCommandTreeProvider {
    constructor() {
        const config: CommandConfig = {
            Launch: {
                cmd: 'HARD.Launch',
                icon: 'cmd',
                tip: 'Launch FPGA development assist function'
            },
            Simulate: {
                cmd: 'HARD.Simulate',
                icon: 'toolBox',
                tip: 'Launch the manufacturer Simulation',
                children: {
                    CLI: {
                        cmd: 'HARD.simCLI',
                        icon: 'branch',
                        tip: 'Launch the manufacturer Simulation in CLI'
                    },
                    GUI: {
                        cmd: 'HARD.simGUI',
                        icon: 'branch',
                        tip: 'Launch the manufacturer Simulation in GUI'
                    },
                }
            },
            Refresh: {
                cmd: 'HARD.Refresh',
                icon: 'cmd',
                tip: 'Refresh the current project file'
            },
            Build: {
                cmd: 'HARD.Build',
                icon: 'toolBox',
                tip: 'Build the current fpga project',
                children: {
                    Synth: {
                        cmd: 'HARD.Synth',
                        icon: 'branch',
                        tip: 'Synth the current project'
                    },
                    Impl: {
                        cmd: 'HARD.Impl',
                        icon: 'branch',
                        tip: 'Impl  the current project'
                    },
                    BitStream: {
                        cmd: 'HARD.Bit',
                        icon: 'branch',
                        tip: 'Generate the BIT File'
                    },
                }
            },
            Program: {
                cmd: 'HARD.Program',
                icon: 'cmd',
                tip: 'Download the bit file into the device'
            },
            GUI: {
                cmd: 'HARD.GUI',
                icon: 'cmd',
                tip: 'Open the GUI'
            },
            Exit: {
                cmd: 'HARD.Exit',
                icon: 'cmd',
                tip: 'Exit the current project'
            }
        };

        super(config, 'HARD');
    }
};

class SoftwareTreeProvider extends BaseCommandTreeProvider {
    constructor() {
        const config: CommandConfig = {
            Launch: {
                cmd: 'SOFT.Launch',
                icon: 'cmd',
                tip: 'Launch SDK development assist function'
            },
            Build: {
                cmd: 'SOFT.Launch',
                icon: 'cmd',
                tip: 'Build the current SDK project'
            },
            Download: {
                cmd: 'SOFT.Launch',
                icon: 'cmd',
                tip: 'Download the boot file into the device'
            },
        };

        super(config, 'SOFT');
    }
}

class ToolTreeProvider extends BaseCommandTreeProvider {
    constructor() {
        const config: CommandConfig = {
            Clean: {
                cmd: 'TOOL.Clean',
                icon: 'clean',
                tip: 'Clean the current project'
            }
        };
        super(config, 'TOOL');
    }
}


const hardwareTreeProvider = new HardwareTreeProvider();
const softwareTreeProvider = new SoftwareTreeProvider();
const toolTreeProvider = new ToolTreeProvider();

export {
    hardwareTreeProvider,
    softwareTreeProvider,
    toolTreeProvider,
};