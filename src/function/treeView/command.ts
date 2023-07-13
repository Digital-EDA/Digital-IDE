/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import { MainOutput, opeParam } from '../../global';
import { hdlDir, hdlFile, hdlPath } from '../../hdlFs';
import { getIconConfig } from '../../hdlFs/icons';
import { hdlIgnore } from '../../manager/ignore';

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

    private getElementChildrenNum(element: CommandDataItem): number {
        if (element.children) {
            return Object.keys(element.children).length;
        }
        return 0;
    }

    // 根据输入的CommandDataItem转化为vscode.TreeItem
    getTreeItem(element: CommandDataItem): vscode.TreeItem | Thenable<vscode.TreeItem> {
        const childNum = this.getElementChildrenNum(element);
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
                cmd: 'digital-ide.hard.launch',
                icon: 'cmd',
                tip: 'Launch FPGA development assist function'
            },
            Simulate: {
                cmd: 'digital-ide.hard.simulate',
                icon: 'toolBox',
                tip: 'Launch the manufacturer Simulation',
                children: {
                    CLI: {
                        cmd: 'digital-ide.hard.simulate.cli',
                        icon: 'branch',
                        tip: 'Launch the manufacturer Simulation in CLI'
                    },
                    GUI: {
                        cmd: 'digital-ide.hard.simulate.gui',
                        icon: 'branch',
                        tip: 'Launch the manufacturer Simulation in GUI'
                    },
                }
            },
            Refresh: {
                cmd: 'digital-ide.hard.refresh',
                icon: 'cmd',
                tip: 'Refresh the current project file'
            },
            Build: {
                cmd: 'digital-ide.hard.build',
                icon: 'toolBox',
                tip: 'Build the current fpga project',
                children: {
                    Synth: {
                        cmd: 'digital-ide.hard.build.synth',
                        icon: 'branch',
                        tip: 'Synth the current project'
                    },
                    Impl: {
                        cmd: 'digital-ide.hard.build.impl',
                        icon: 'branch',
                        tip: 'Impl the current project'
                    },
                    BitStream: {
                        cmd: 'digital-ide.hard.build.bitstream',
                        icon: 'branch',
                        tip: 'Generate the BIT File'
                    },
                }
            },
            Program: {
                cmd: 'digital-ide.hard.program',
                icon: 'cmd',
                tip: 'Download the bit file into the device'
            },
            GUI: {
                cmd: 'digital-ide.hard.gui',
                icon: 'cmd',
                tip: 'Open the GUI'
            },
            Exit: {
                cmd: 'digital-ide.hard.exit',
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
                cmd: 'digital-ide.soft.launch',
                icon: 'cmd',
                tip: 'Launch SDK development assist function'
            },
            Build: {
                cmd: 'digital-ide.soft.build',
                icon: 'cmd',
                tip: 'Build the current SDK project'
            },
            Download: {
                cmd: 'digital-ide.soft.download',
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
                cmd: 'digital-ide.tool.clean',
                icon: 'clean',
                tip: 'Clean the current project'
            }
        };
        super(config, 'TOOL');

        vscode.commands.registerCommand('digital-ide.tool.clean', this.clean);
    }

    public async clean() {
        const prjPath = opeParam.prjInfo.arch.prjPath;
        const xilFolder = hdlPath.join(opeParam.workspacePath, '.Xil');

        hdlDir.rmdir(prjPath);
        hdlDir.rmdir(xilFolder);

        const ignores = hdlIgnore.getIgnoreFiles();

        const strFiles = hdlFile.pickFileRecursive(opeParam.workspacePath, ignores, p => p.endsWith('.str'));
        for (const path of strFiles) {
            hdlFile.removeFile(path);
        }

        const logFiles = hdlFile.pickFileRecursive(opeParam.workspacePath, ignores, p => p.endsWith('.log'));
        for (const path of logFiles) {
            hdlFile.readFile(path);
        }

        MainOutput.report('finish digital-ide.tool.clean');
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