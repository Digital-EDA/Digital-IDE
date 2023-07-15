/**
 * PL: program logic
 * Hardware Programming
 */
import * as vscode from 'vscode';

import { PLConfig, XilinxOperation } from './xilinx';
import { BaseManage } from '../common';
import { opeParam } from '../../global';
import { ToolChainType } from '../../global/enum';
import { hdlFile, hdlPath } from '../../hdlFs';
import { moduleTreeProvider, ModuleDataItem } from '../../function/treeView/tree';
import { HdlFileType } from '../../hdlParser/common';
import { PropertySchema } from '../../global/propertySchema';

class PlManage extends BaseManage {
    config: PLConfig;

    constructor() {
        super();
        this.config = { 
            tool: 'default', 
            path: '',
            ope: new XilinxOperation(),
            terminal: null
        };

        if (opeParam.prjInfo.toolChain) {
            this.config.tool = opeParam.prjInfo.toolChain;
        }

        const curToolChain = this.config.tool;
        if (curToolChain === ToolChainType.Xilinx) {
            const vivadoPath = vscode.workspace.getConfiguration('prj.vivado.install').get('path', '');
            if (hdlFile.isDir(vivadoPath)) {
                this.config.path = hdlPath.join(hdlPath.toSlash(vivadoPath), 'vivado');
                if (opeParam.os === 'win32') {
                    this.config.path += '.bat';
                }
            } else {
                this.config.path = 'vivado';
            }
        }       
    }

    public launch() {
        this.config.terminal = this.createTerminal('Hardware');
        this.config.terminal.show(true);
        this.config.ope.launch(this.config);
    }

    public simulate() {
        if (!this.config.terminal) {
            return;
        }
        this.config.ope.simulate(this.config);
    }

    public simulateCli() {
        this.config.ope.simulateCli(this.config);
    }

    public simulateGui() {
        this.config.ope.simulateGui(this.config);
    }

    public refresh() {
        if (!this.config.terminal) {
            return;
        }
        this.config.ope.refresh(this.config.terminal);
    }

    public build() {
        this.config.ope.build(this.config);
    }


    public synth() {
        this.config.ope.synth(this.config);
    }

    public impl() {
        if (!this.config.terminal) {
            return null;
        }

        this.config.ope.impl(this.config);
    }

    public bitstream() {
        this.config.ope.generateBit(this.config);
    }

    public program() {
        this.config.ope.program(this.config);
    }

    public gui() {
        this.config.ope.gui(this.config);
    }

    public exit() {
        if (!this.config.terminal) {
            return null;
        }

        this.config.terminal.show(true);
        this.config.terminal.sendText(`exit`);
        this.config.terminal.sendText(`exit`);
        this.config.terminal = null;
    }


    public setSrcTop(item: ModuleDataItem) {        
        this.config.ope.setSrcTop(item.name, this.config);
        const type = moduleTreeProvider.getItemType(item);
        if (type === HdlFileType.Src) {
            moduleTreeProvider.setFirstTop(HdlFileType.Src, item.name, item.path);
            moduleTreeProvider.refreshSrc();
        }
    }

    public setSimTop(item: ModuleDataItem) {
        this.config.ope.setSimTop(item.name, this.config);
        const type = moduleTreeProvider.getItemType(item);
        if (type === HdlFileType.Sim) {
            moduleTreeProvider.setFirstTop(HdlFileType.Sim, item.name, item.path);
            moduleTreeProvider.refreshSim();
        }
    }


    async addFiles(files: string[]) {
        this.config.ope.addFiles(files, this.config);
    }

    async delFiles(files: string[]) {
        this.config.ope.delFiles(files, this.config);
    }

    async addDevice() {
        const propertySchema = opeParam.propertySchemaPath;
        let propertyParam = hdlFile.readJSON(propertySchema) as PropertySchema;
        const device = await vscode.window.showInputBox({
            password: false,
            ignoreFocusOut: true,
            placeHolder: 'Please input the name of device'
        });

        if (!device) {
            return;    
        }

        if (!propertyParam.properties.device.enum.includes(device)) {
            propertyParam.properties.device.enum.push(device);
            hdlFile.writeJSON(propertySchema, propertyParam);
            vscode.window.showInformationMessage(`Add the ${device} successfully!!!`);
        } else {
            vscode.window.showWarningMessage("The device already exists.");
        }
    }

    async delDevice() {
        const propertySchema = opeParam.propertySchemaPath;
        let propertyParam = hdlFile.readJSON(propertySchema) as PropertySchema;
        const device = await vscode.window.showQuickPick(propertyParam.properties.device.enum);
        if (!device) {
            return;
        }

        const index = propertyParam.properties.device.enum.indexOf(device);
        propertyParam.properties.device.enum.splice(index, 1);
        hdlFile.writeJSON(propertySchema, propertyParam);
        vscode.window.showInformationMessage(`Delete the ${device} successfully!!!`);
    }
}


export {
    PlManage,
};