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
import { HdlFileProjectType } from '../../hdlParser/common';
import { PropertySchema } from '../../global/propertySchema';
import { HardwareOutput, MainOutput, ReportType } from '../../global/outputChannel';
import { AbsPath } from '../../global';
import { t } from '../../i18n';

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
            this.context.path = this.context.ope.updateVivadoPath();
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

        if (this.context.process === undefined) {
            return;
        }

        HardwareOutput.show();
        this.context.process.stdin.write('exit\n');
        HardwareOutput.report(t('info.pl.exit.title'));
        this.context.process = undefined;
    }


    public setSrcTop(item: ModuleDataItem) {        
        this.context.ope.setSrcTop(item.name, this.context);
        const type = moduleTreeProvider.getItemType(item);
        if (type === HdlFileProjectType.Src) {
            moduleTreeProvider.setFirstTop(HdlFileProjectType.Src, item.name, item.path);
            moduleTreeProvider.refreshSrc();
        }
    }

    public setSimTop(item: ModuleDataItem) {
        this.context.ope.setSimTop(item.name, this.context);
        const type = moduleTreeProvider.getItemType(item);
        if (type === HdlFileProjectType.Sim) {
            moduleTreeProvider.setFirstTop(HdlFileProjectType.Sim, item.name, item.path);
            moduleTreeProvider.refreshSim();
        }
    }
    
    /**
     * @description 因发生文件布局变动而进行更新
     * @param addFiles 
     * @param delFiles 
     */
    public async updateByMonitor(addFiles: AbsPath[], delFiles: AbsPath[]) {
        // 目前只支持 Xilinx
        const addfileActionTag = '(add files) ';
        const delfileActionTag = '(del files) ';
        if (addFiles.length > 0) {
            const reportMsg = ['', ...addFiles].join('\n\t');
            MainOutput.report(addfileActionTag + t('info.pl.xilinx.update-addfiles') + reportMsg, {
                level: ReportType.Run
            });
            await this.addFiles(addFiles);
        } else {
            MainOutput.report(addfileActionTag + t('info.pl.xilinx.no-need-add-files'));
        }

        if (delFiles.length > 0) {
            const reportMsg = ['', ...delFiles].join('\n\t');
            MainOutput.report(delfileActionTag + t('info.pl.xilinx.update-delfiles') + reportMsg, {
                level: ReportType.Run
            });
            await this.delFiles(delFiles);
        } else {
            MainOutput.report(delfileActionTag + t('info.pl.xilinx.no-need-del-files'));
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