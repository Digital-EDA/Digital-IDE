import * as vscode from 'vscode';

import { AbsPath, opeParam } from '../../global';
import { Soc } from '../../global/prjInfo';

import { hdlFile, hdlPath } from '../../hdlFs';

interface XilinxOperationConfig {
    path : AbsPath,
    hw : string,
    bsp: string,
    dat: AbsPath,
    src: AbsPath,
    soc: Soc
}

interface PSConfig {
    terminal? : vscode.Terminal | null,
    tool? : string,                  // 工具类型
    path? : string,                  // 第三方工具运行路径
    ope? : XilinxOperation,
}

/**
 * @state finish-untest
 * @descriptionCn xilinx工具链下PS端的操作类
 */
class XilinxOperation {
    public get config(): XilinxOperationConfig {
        return {
            path : hdlPath.join(opeParam.extensionPath, 'resources', 'script', 'xilinx', 'soft'),
            hw : "SDK_Platform",
            bsp: "BSP_package",
            dat: opeParam.prjInfo.arch.software.data,
            src: opeParam.prjInfo.arch.software.src,
            soc: {
                core: "ps7_cortexa9_0",
                bd: "template",
                app: "Hello World",
                os: "standalone"
            }
        };
    }

    launch(config: PSConfig) {
        const hdfs = hdlFile.pickFileRecursive(this.config.dat, [], 
            p => p.endsWith('.hdf'));

        if (hdfs.length) {
            vscode.window.showErrorMessage(`There is no hdf file in ${this.config.dat}.`);
            return null;
        }

        const scriptPath = `${this.config.path}/launch.tcl`;
        const script = `
setws ${this.config.src}
if { [getprojects -type hw] == "" } {
    createhw -name ${this.config.hw} -hwspec ${this.config.dat}/
} else {
    openhw ${this.config.src}/[getprojects -type hw]/system.hdf 
}

if { [getprojects -type bsp] == "" } {
    createbsp -name ${this.config.bsp} \\
                -hwproject ${this.config.hw} \\
                -proc ${this.config.soc.core} \\
                -os ${this.config.soc.os}
}

if { [getprojects -type app] == "" } {
    createapp -name ${this.config.soc.bd} \\
                -hwproject ${this.config.hw} \\
                -bsp ${this.config.bsp} \\
                -proc ${this.config.soc.core} \\
                -os ${this.config.soc.os} \\
                -lang C \\
                -app {${this.config.soc.app}}
}
file delete ${scriptPath} -force\n`;
        
        hdlFile.writeFile(scriptPath, script);
        config.terminal?.show(true);
        config.terminal?.sendText(`${config.path} ${scriptPath}`);
    }

    build(config: PSConfig) {        
        const scriptPath = `${this.config.path}/build.tcl`;
        const script = `
setws ${this.config.src}
openhw ${this.config.src}/[getprojects -type hw]/system.hdf
projects -build
file delete ${scriptPath} -force\n`;
        hdlFile.writeFile(scriptPath, script);
        config.terminal?.show(true);
        config.terminal?.sendText(`${config.path} ${scriptPath}`);
    }

    program(config: PSConfig) {        
        const len = this.config.soc.core.length;
        const index = this.config.soc.core.slice(len-1, len);
        const scriptPath = `${this.config.path}/program.tcl`;
        const script = `
setws ${this.config.src}
openhw ${this.config.src}/[getprojects -type hw]/system.hdf
connect
targets -set -filter {name =~ "ARM*#${index}"}
rst -system
namespace eval xsdb { 
    source ${this.config.src}/${this.config.hw}/ps7_init.tcl
    ps7_init
}
fpga ./${this.config.soc.bd}.bit
dow  ${this.config.src}/${this.config.soc.bd}/Debug/${this.config.soc.bd}.elf
con
file delete ${scriptPath} -force\n`;
        hdlFile.writeFile(scriptPath, script);
        config.terminal?.show(true);
        config.terminal?.sendText(`${config.path} ${scriptPath}`);
    }
}

export {
    XilinxOperation
};