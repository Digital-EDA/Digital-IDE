/**
 * PL: program logic
 * Hardware Programming
 */
import * as vscode from 'vscode';

import { PLContext, XilinxOperation } from './xilinx';
import { BaseManage } from '../common';
import { opeParam } from '../../global';
import { ToolChainType } from '../../global/enum';
import { hdlFile, hdlPath } from '../../hdlFs';
import { moduleTreeProvider, ModuleDataItem } from '../../function/treeView/tree';
import { HdlFileType } from '../../hdlParser/common';
import { PropertySchema } from '../../global/propertySchema';
import { HardwareOutput, ReportType } from '../../global/outputChannel';

class PlManage extends BaseManage {
    context: PLContext;

    constructor() {
        super();

        this.context = { 
            tool: opeParam.prjInfo.toolChain || 'xilinx', 
            path: '',
            ope: new XilinxOperation(),
            terminal: undefined,
            process: undefined
        };

        const curToolChain = this.context.tool;
        if (curToolChain === ToolChainType.Xilinx) {
            const vivadoPath = vscode.workspace.getConfiguration('digital-ide.prj.vivado.install').get('path', '');
            if (hdlFile.isDir(vivadoPath)) {
                this.context.path = hdlPath.join(hdlPath.toSlash(vivadoPath), 'vivado');
                if (opeParam.os === 'win32') {
                    this.context.path += '.bat';
                }
            } else {
                this.context.path = 'vivado';
            }
        }       
    }

    public launch() {
        this.context.ope.launch(this.context);
    }

    public simulate() {
        if (this.context.process === undefined) {
            return;
        }
        this.context.ope.simulate(this.context);
    }

    public simulateCli() {
        this.context.ope.simulateCli(this.context);
    }

    public simulateGui() {
        this.context.ope.simulateGui(this.context);
    }

    public refresh() {
        if (this.context.process === undefined) {
            return;
        }
        this.context.ope.refresh(this.context);
    }

    public build() {
        this.context.ope.build(this.context);
    }

    public synth() {
        this.context.ope.synth(this.context);
    }

    public impl() {
        if (this.context.process === undefined) {
            return null;
        }
        this.context.ope.impl(this.context);
    }

    public bitstream() {
        this.context.ope.generateBit(this.context);
    }

    public program() {
        this.context.ope.program(this.context);
    }

    public gui() {
        this.context.ope.gui(this.context);
    }

    public exit() {
        const { t } = vscode.l10n;

        if (this.context.process === undefined) {
            return;
        }

        HardwareOutput.show();
        this.context.process.stdin.write('exit\n');
        HardwareOutput.report(t('info.pl.exit.title'), ReportType.Info);
        this.context.process = undefined;
    }


    public setSrcTop(item: ModuleDataItem) {        
        this.context.ope.setSrcTop(item.name, this.context);
        const type = moduleTreeProvider.getItemType(item);
        if (type === HdlFileType.Src) {
            moduleTreeProvider.setFirstTop(HdlFileType.Src, item.name, item.path);
            moduleTreeProvider.refreshSrc();
        }
    }

    public setSimTop(item: ModuleDataItem) {
        this.context.ope.setSimTop(item.name, this.context);
        const type = moduleTreeProvider.getItemType(item);
        if (type === HdlFileType.Sim) {
            moduleTreeProvider.setFirstTop(HdlFileType.Sim, item.name, item.path);
            moduleTreeProvider.refreshSim();
        }
    }


    async addFiles(files: string[]) {
        this.context.ope.addFiles(files, this.context);
    }

    async delFiles(files: string[]) {
        this.context.ope.delFiles(files, this.context);
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