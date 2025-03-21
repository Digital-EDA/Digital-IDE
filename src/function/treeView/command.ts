/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fspath from 'path';

import { MainOutput, opeParam } from '../../global';
import { hdlDir, hdlFile, hdlPath } from '../../hdlFs';
import { getIconConfig } from '../../hdlFs/icons';
import { hdlIgnore } from '../../manager/ignore';
import { t } from '../../i18n';

interface CommandDataItem {
    name: string,
    cmd: string,
    icon: string,
    tip: string,
    children: CommandDataItem[]
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
    }

    public async clean() {
        const workspacePath = opeParam.workspacePath;
        const prjPath = opeParam.prjStructure.prjPath;

        // move bd * ip
        const plName = opeParam.prjInfo.prjName.PL;
        const targetPath = fspath.dirname(opeParam.prjInfo.arch.hardware.src);

        const sourceIpPath = `${workspacePath}/prj/xilinx/${plName}.srcs/sources_1/ip`;
        const sourceBdPath = `${workspacePath}/prj/xilinx/${plName}.srcs/sources_1/bd`;

        hdlDir.mvdir(sourceIpPath, targetPath, true);
        MainOutput.report("move dir from " + sourceIpPath + " to " + targetPath);

        hdlDir.mvdir(sourceBdPath, targetPath, true);
        MainOutput.report("move dir from " + sourceBdPath + " to " + targetPath);
                
        if (prjPath !== opeParam.workspacePath) {
            hdlDir.rmdir(prjPath);
            const xilFolder = hdlPath.join(opeParam.workspacePath, '.Xil');
            hdlDir.rmdir(xilFolder);
            MainOutput.report("remove dir : " + prjPath);
            MainOutput.report("remove dir : " + xilFolder);
        } else {
            vscode.window.showWarningMessage(t('warn.command.clean.prjPath-is-workspace'));
        }

        const strFiles = hdlFile.pickFileRecursive(workspacePath, p => p.endsWith('.str'));
        for (const path of strFiles) {
            hdlFile.removeFile(path);
            MainOutput.report("remove file " + path);
        }

        const logFiles = hdlFile.pickFileRecursive(workspacePath, p => p.endsWith('.log'));
        for (const path of logFiles) {
            hdlFile.readFile(path);
        }

        MainOutput.report('finish digital-ide.tool.clean');
    }

}

export async function clean() {
    const workspacePath = opeParam.workspacePath;
    const prjPath = opeParam.prjStructure.prjPath;

    // move bd * ip
    const plName = opeParam.prjInfo.prjName.PL;
    const targetPath = fspath.dirname(opeParam.prjInfo.arch.hardware.src);

    if (hdlDir.isDir(`${workspacePath}/prj/xilinx/${plName}.gen`)) {
        const sourceIpPath = `${workspacePath}/prj/xilinx/${plName}.gen/sources_1/ip`;
        const sourceBdPath = `${workspacePath}/prj/xilinx/${plName}.gen/sources_1/bd`;

        hdlDir.mvdir(sourceIpPath, targetPath, true);
        MainOutput.report("move dir from " + sourceIpPath + " to " + targetPath);

        hdlDir.mvdir(sourceBdPath, targetPath, true);
        MainOutput.report("move dir from " + sourceBdPath + " to " + targetPath);
    }

    if (hdlDir.isDir(`${workspacePath}/prj/xilinx/${plName}.srcs`)) {
        const sourceIpPath = `${workspacePath}/prj/xilinx/${plName}.srcs/sources_1/ip`;
        const sourceBdPath = `${workspacePath}/prj/xilinx/${plName}.srcs/sources_1/bd`;

        hdlDir.mvdir(sourceIpPath, targetPath, true);
        MainOutput.report("move dir from " + sourceIpPath + " to " + targetPath);

        hdlDir.mvdir(sourceBdPath, targetPath, true);
        MainOutput.report("move dir from " + sourceBdPath + " to " + targetPath);
    }
            
    if (prjPath !== opeParam.workspacePath) {
        hdlDir.rmdir(prjPath);
        const xilFolder = hdlPath.join(opeParam.workspacePath, '.Xil');
        hdlDir.rmdir(xilFolder);
        MainOutput.report("remove dir : " + prjPath);
        MainOutput.report("remove dir : " + xilFolder);
    } else {
        vscode.window.showWarningMessage(t('warn.command.clean.prjPath-is-workspace'));
    }

    const strFiles = hdlFile.pickFileRecursive(workspacePath, p => p.endsWith('.str'));
    for (const path of strFiles) {
        hdlFile.removeFile(path);
        MainOutput.report("remove file " + path);
    }

    const logFiles = hdlFile.pickFileRecursive(workspacePath, p => p.endsWith('.log'));
    for (const path of logFiles) {
        hdlFile.readFile(path);
    }

    MainOutput.report('finish digital-ide.tool.clean');
}


const hardwareTreeProvider = new HardwareTreeProvider();
const softwareTreeProvider = new SoftwareTreeProvider();
const toolTreeProvider = new ToolTreeProvider();

export {
    hardwareTreeProvider,
    softwareTreeProvider,
    toolTreeProvider,
};