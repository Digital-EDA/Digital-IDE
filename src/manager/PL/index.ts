/**
 * PL: program logic
 * Hardware Programming
 */
import * as vscode from 'vscode';
import * as fs from 'fs';

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
import { EfinityOperation } from './efinity';
import { AnlogicOperation } from './anlogic';

class PlManage extends BaseManage {
    context: PLContext;

    constructor() {
        super();

        // 按工具链分发操作类（当前支持 Xilinx / Efinity / Anlogic）
        const toolChain = opeParam.prjInfo.toolChain;
        const ope = this.makeOperation(toolChain);

        this.context = {
            tool: toolChain,
            path: '',
            ope,
            terminal: undefined,
            process: undefined
        };

        const curToolChain = this.context.tool;
        if (curToolChain === ToolChainType.Xilinx) {
            this.context.path = this.context.ope.updateVivadoPath();
        } else if (curToolChain === ToolChainType.Efinity) {
            this.context.ope = new EfinityOperation();
            this.context.path = this.context.ope.updateEfinixPath();
        } else if (curToolChain === ToolChainType.Anlogic) {
            this.context.ope = new AnlogicOperation();
            this.context.path = (this.context.ope as AnlogicOperation).updateAnlogicPath();
        }
    }

    public launch() {
        this.ensureToolchain();
        this.context.ope.launch(this.context);
    }

    public simulate() {
        this.ensureToolchain();
        if (this.context.process === undefined) {
            return;
        }
        this.context.ope.simulate(this.context);
    }

    public simulateCli() {
        this.ensureToolchain();
        this.context.ope.simulateCli(this.context);
    }

    public simulateGui() {
        this.ensureToolchain();
        this.context.ope.simulateGui(this.context);
    }

    public refresh() {
        this.ensureToolchain();
        if (this.context.process === undefined) {
            return;
        }
        this.context.ope.refresh(this.context);
    }

    public build() {
        this.ensureToolchain();
        this.context.ope.build(this.context);
    }

    public synth() {
        this.ensureToolchain();
        this.context.ope.synth(this.context);
    }

    public impl() {
        this.ensureToolchain();
        if (this.context.process === undefined) {
            return null;
        }
        this.context.ope.impl(this.context);
    }

    public bitstream() {
        this.ensureToolchain();
        this.context.ope.generateBit(this.context);
    }

    public program() {
        this.ensureToolchain();
        this.context.ope.program(this.context);
    }

    public gui() {
        this.ensureToolchain();
        this.context.ope.gui(this.context);
    }

    public async exit() {
        if (this.context.process === undefined) {
            return;
        }
        HardwareOutput.show();        
        this.context.ope.exit(this.context);
    }

    /**
     * @description 检测 toolChain 是否变化（如从 Xilinx 工程切到安路工程）。
     * PlManage 是单例（插件激活时创建一次），ope 按首次 toolChain 创建；
     * 切换工程后 toolChain 变了但 ope 仍是旧的，会启动错误工具链。
     * 此方法检测到变化时重建 ope 并清理旧工具链进程。
     */
    private ensureToolchain() {
        const current = opeParam.prjInfo.toolChain;
        if (this.context.tool === current) {
            return;
        }
        // 清理旧工具链进程，避免残留
        if (this.context.process !== undefined) {
            try {
                this.context.ope.exit?.(this.context);
            } catch { /* ignore */ }
            this.context.process = undefined;
        }
        // 按新 toolChain 重建操作类
        this.context.ope = this.makeOperation(current);
        this.context.tool = current;
        if (current === ToolChainType.Xilinx) {
            this.context.path = (this.context.ope as XilinxOperation).updateVivadoPath();
        } else if (current === ToolChainType.Efinity) {
            this.context.ope = new EfinityOperation();
            this.context.path = (this.context.ope as EfinityOperation).updateEfinixPath();
        } else if (current === ToolChainType.Anlogic) {
            this.context.ope = new AnlogicOperation();
            this.context.path = (this.context.ope as AnlogicOperation).updateAnlogicPath();
        }
        HardwareOutput.report(`工具链切换为 ${current}`, { level: ReportType.Info });
    }

    private makeOperation(toolChain: ToolChainType): XilinxOperation | EfinityOperation | AnlogicOperation {
        if (toolChain === ToolChainType.Efinity) {
            return new EfinityOperation();
        }
        if (toolChain === ToolChainType.Anlogic) {
            return new AnlogicOperation();
        }
        return new XilinxOperation();
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

    /**
     * @description 添加自定义 device 字符串
     * @returns 
     */
    async addDevice() {
        const propertySchema = opeParam.propertySchemaPath;
        let propertyParam = hdlFile.readJSON(propertySchema) as PropertySchema;
        const device = await vscode.window.showInputBox({
            password: false,
            ignoreFocusOut: true,
            placeHolder: t('info.addDevice.placeholder')
        });

        if (!device) {
            return;    
        }

        // 同步到缓存中
        const dideHome = opeParam.dideHome;
        const cachePPy = hdlPath.join(dideHome, 'property-schema.json');

        if (!propertyParam.properties.device.enum.includes(device)) {
            propertyParam.properties.device.enum.push(device);
            hdlFile.writeJSON(propertySchema, propertyParam);
            hdlFile.writeJSON(cachePPy, propertyParam);
            vscode.window.showInformationMessage(t('info.addDevice.add-success', device));
        } else {
            vscode.window.showWarningMessage(t('warning.addDevice.name-taken', device));
        }
    }

    /**
     * @description 删除用户创建的 device
     * @returns 
     */
    async delDevice() {
        const propertySchema = opeParam.propertySchemaPath;
        const propertyParam = hdlFile.readJSON(propertySchema) as PropertySchema;
        const cachePPy = hdlPath.join(opeParam.dideHome, 'property-schema.json');

        const device = await vscode.window.showQuickPick(
            propertyParam.properties.device.enum.filter(device => device !== 'none'),
            {
                placeHolder: t('info.delDevice.placeholder'),
                ignoreFocusOut: true
            }
        );
        if (!device) {
            return;
        }

        const index = propertyParam.properties.device.enum.indexOf(device);
        propertyParam.properties.device.enum.splice(index, 1);
        hdlFile.writeJSON(propertySchema, propertyParam);
        hdlFile.writeJSON(cachePPy, propertyParam);
        vscode.window.showInformationMessage(t('info.delDevice.del-success', device));
    }
}

export {
    PlManage,
};
