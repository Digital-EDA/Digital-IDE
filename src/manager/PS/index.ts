/**
 * PS: processing system
 * software of cpu
 */
import * as vscode from 'vscode';
import { opeParam } from '../../global';
import { ToolChainType } from '../../global/enum';
import { hdlFile, hdlPath } from '../../hdlFs';
import { BaseManage } from '../common';

import { PSConfig, XilinxOperation } from './xilinx';


class PsManage extends BaseManage {
    config: PSConfig;

    constructor() {
        super();
        this.config = {
            tool : 'default',
            path : '',
            ope  : new XilinxOperation(),
            terminal : this.createTerminal('PS')
        };


        // get tool chain
        if (opeParam.prjInfo.toolChain) {
            this.config.tool = opeParam.prjInfo.toolChain;
        }

        // get install path & operation object
        if (this.config.tool === ToolChainType.Xilinx) {
            const xsdkPath = vscode.workspace.getConfiguration('digital-ide.prj.xsdk.install').get('path', '');
            if (hdlFile.isDir(xsdkPath)) {
                this.config.path = hdlPath.join(hdlPath.toSlash(xsdkPath), 'xsct');
                if (opeParam.os === "win32") {
                    this.config.path += '.bat';
                }
            } else {
                this.config.path = 'xsct';
            }
        }
    }

    launch() {
        this.config.terminal = this.createTerminal('Software');
        this.config.ope.launch(this.config);
    }

    build() {
        this.config.terminal = this.createTerminal('Software');
        this.config.ope.build(this.config);
    }

    program() {
        this.config.terminal = this.createTerminal('Software');
        this.config.ope.program(this.config);
    }
}


export {
    PsManage,
};