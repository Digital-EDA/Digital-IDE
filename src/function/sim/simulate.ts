import * as vscode from 'vscode';
import * as fs from 'fs';
import * as child_process from 'child_process';

import { hdlParam } from '../../hdlParser';
import { AbsPath, MainOutput, opeParam, ReportType } from '../../global';
import { hdlDir, hdlFile, hdlPath } from '../../hdlFs';
import { getSelectItem } from './instance';
import { ToolChainType } from '../../global/enum';
import { HdlModule } from '../../hdlParser/core';

interface SimulateConfig {
    mod : string,   // 设置的顶层模块              
    clk : string,   // 设置的主频信号
    rst : string,   // 设置的复位信号
    end : string,   // 
    wave : string,  // wave存放的路径     
    simulationHome : string, // sim运行的路径
    gtkwavePath : string, // gtkwave安装路径
    installPath : string  // 第三方仿真工具的安装路径
    iverilogPath: string
    vvpPath: string
}

class Simulate {
    regExp = {
        mod  : /\/\/ @ sim.module : (?<mod>\w+)/,
        clk  : /\/\/ @ sim.clk : (?<clk>\w+)/,
        rst  : /\/\/ @ sim.rst : (?<rst>\w+)/,
        end  : /#(?<end>[0-9+])\s+\$(finish|stop)/,
        wave : /\$dumpfile\s*\(\s*\"(?<wave>.+)\"\s*\);/,
    };
    xilinxLib = [
        "xeclib", "unisims" ,"unimacro" ,"unifast" ,"retarget"
    ];

    /**
     * @description 获取仿真的配置
     * @param path 代码路径
     * @param tool 仿真工具名
     */
    getConfig(path: AbsPath, tool: string): SimulateConfig | undefined {
        let simConfig: SimulateConfig = {
            mod : '',            
            clk : '',                   // 设置的主频信号
            rst : '',                   // 设置的复位信号
            end : '',                   // 
            wave : '',                  // wave存放的路径     
            simulationHome : '',               // sim运行的路径
            gtkwavePath : '',           // gtkwave安装路径
            installPath : '',           // 第三方仿真工具的安装路径
            iverilogPath: 'iverilog',   // iverilog仿真器所在路径
            vvpPath: 'vvp'              // vvp解释器所在路径
        };
        let code = hdlFile.readFile(path);
        if (!code) {
            MainOutput.report('error when read ' + path, ReportType.Error, true);
            return;
        }

        for (const element in this.regExp) {    
            const regGroup = code.match(this.regExp[element as keyof typeof this.regExp])?.groups;
            if (regGroup) {
                simConfig[element as keyof SimulateConfig] = regGroup[element];
            }
        }

        const setting = vscode.workspace.getConfiguration();

        // make simulation dir
        const defaultSimulationDir = hdlPath.join(opeParam.prjInfo.arch.prjPath, 'simulation', 'icarus');
        simConfig.simulationHome = setting.get('function.simulate.simulationHome', '');
        if (!fs.existsSync(simConfig.simulationHome)) {
            simConfig.simulationHome = defaultSimulationDir;
        }
        
        
        
        if (!hdlFile.isDir(simConfig.simulationHome)) {
            MainOutput.report('create dir ' + simConfig.simulationHome, ReportType.Info);
            hdlDir.mkdir(simConfig.simulationHome);
        }

        simConfig.gtkwavePath = setting.get('function.simulate.gtkwavePath', 'gtkwave');
        
        if (simConfig.gtkwavePath !== '' && !hdlFile.isDir(simConfig.gtkwavePath)) {
            simConfig.gtkwavePath = 'gtkwave'; // 如果不存在则认为是加入了环境变量
        } else {
            if (opeParam.os === 'win32') {
                simConfig.gtkwavePath = hdlPath.join(simConfig.gtkwavePath, 'gtkwave.exe');
            } else {
                simConfig.gtkwavePath = hdlPath.join(simConfig.gtkwavePath, 'gtkwave');
            }
        }

        simConfig.installPath = setting.get('function.simulate.icarus.installPath', '');
        if (simConfig.installPath !== '' && !hdlFile.isDir(simConfig.installPath)) {
            MainOutput.report(`install path ${simConfig.installPath} is illegal`, ReportType.Error, true);
            return;
        }

        return simConfig;
    }

    /**
     * @description 获取自带仿真库的路径
     * @param toolChain 
     */
    public getSimLibArr(toolChain: ToolChainType): AbsPath[] {
        let libPath: AbsPath[] = [];
        const setting = vscode.workspace.getConfiguration();

        // 获取xilinx的自带仿真库的路径
        if (toolChain === ToolChainType.Xilinx) {
            const simLibPath = setting.get('function.simulate.xilinxLibPath', '');

            if (!hdlFile.isDir(simLibPath)) {
                return [];
            }
            const glblPath = hdlPath.join(simLibPath, 'glbl.v');
            libPath.push(glblPath);
            for (const element of this.xilinxLib) {
                const xilinxPath = hdlPath.join(simLibPath, element);
                libPath.push(xilinxPath);
            }
        }
        return libPath;
    }
}

/**
 * @description icarus 仿真类
 * 
 */
class IcarusSimulate extends Simulate {
    os: string;
    prjPath: AbsPath;
    toolChain: ToolChainType;

    simConfig: SimulateConfig | undefined;

    constructor() {
        super();
        this.os = opeParam.os;
        this.prjPath = opeParam.prjInfo.arch.prjPath;
        this.toolChain = opeParam.prjInfo.toolChain;
    }

    private makeMacroIncludeArguments(includes: string[]): string {
        const args = [];
        for (const includePath of includes) {
            if(!hdlFile.isDir(includePath)) {
                args.push(includePath);
            } else {
                args.push('-I ' + includePath);
            }
        }
        return args.join(' ').trim();
    }

    private makeDependenceArguments(dependences: string[]): string {
        const args = [];
        for (const dep of dependences) {
            args.push('"' + dep + '"');
        }
        return args.join(' ').trim();
    }

    private makeThirdLibraryArguments(simLibPaths: string[]): string {
        const args = [];
        for (const libPath of simLibPaths) {
            if(!hdlFile.isDir(libPath)) {
                args.push(libPath);
            } else {
                args.push('-y ' + libPath);
            }
        }
        return args.join(' ').trim();
    }

    /**
     * generate acutal iverlog simulation command
     * @param name name of top module
     * @param path path of the simulated file
     * @param dependences dependence that not specified in `include macro
     * @returns 
     */
    private getCommand(name: string, path: AbsPath, dependences: string[]): string | undefined {
        const simConfig = this.getConfig(path, 'iverilog');
        if (!simConfig) {
            return;
        }
        this.simConfig = simConfig;
        const installPath = simConfig.installPath;
        const iverilogCompileOptions = opeParam.prjInfo.iverilogCompileOptions;

        if (this.os === 'win32') {
            simConfig.iverilogPath += '.exe';
            simConfig.vvpPath += '.exe';
        }
        
        if (hdlFile.isDir(installPath)) {
            simConfig.iverilogPath = hdlPath.join(installPath, simConfig.iverilogPath);
            simConfig.vvpPath = hdlPath.join(installPath, simConfig.vvpPath);
        }

        const simLibPaths = this.getSimLibArr(this.toolChain);

        const macroIncludeArgs = this.makeMacroIncludeArguments(iverilogCompileOptions.includes);
        const dependenceArgs = this.makeDependenceArguments(dependences);
        const thirdLibraryArgs = this.makeThirdLibraryArguments(simLibPaths);

        const iverilogPath = simConfig.iverilogPath;
        // default is -g2012
        const argu = '-g' + iverilogCompileOptions.standard;
        const outVvpPath = '"' + hdlPath.join(simConfig.simulationHome, 'out.vvp') + '"';      
        const mainPath = '"' + path + '"';

        const cmd = `${iverilogPath} ${argu} -o ${outVvpPath} -s ${name} ${macroIncludeArgs} ${thirdLibraryArgs} ${mainPath} ${dependenceArgs}`;
        MainOutput.report(cmd, ReportType.Run);
        return cmd;
    }

    private execInTerminal(command: string, cwd: AbsPath) {
        // let vvp: vscode.Terminal;
        // const targetTerminals = vscode.window.terminals.filter(t => t.name === 'vvp');
        // if (targetTerminals.length > 0) {
        //     vvp = targetTerminals[0];
        // } else {
        //     vvp = vscode.window.createTerminal('vvp');
        // }

        // let cmd = `${vvpPath} ${outVvpPath}`;
        // if (simConfig.wave !== '') {
        //     let waveExtname = simConfig.wave.split('.');
        //     cmd += '-' + waveExtname[simConfig.wave.length - 1];
        // }

        // vvp.show(true);
        // vvp.sendText(cmd);
        // if (simConfig.wave !== '') {
        //     vvp.sendText(`${simConfig.gtkwavePath} ${simConfig.wave}`);
        // } else {
        //     MainOutput.report('There is no wave image path in this testbench', ReportType.Error);
        // }
    }

    private execInOutput(command: string, cwd: AbsPath) {
        const simConfig = this.simConfig;
        if (!simConfig) {
            return;
        }
        child_process.exec(command, { cwd }, (error, stdout, stderr) => {
            if (error) {
                MainOutput.report('Error took place when run ' + command, ReportType.Error);
                MainOutput.report('Reason: ' + stderr, ReportType.Error);
            } else {
                MainOutput.report(stdout, ReportType.Info);
                const vvpOutFile = hdlPath.join(simConfig.simulationHome, 'out.vvp');
                MainOutput.report("Create vvp to " + vvpOutFile, ReportType.Run);
                
                const outVvpPath = hdlPath.join(simConfig.simulationHome, 'out.vvp');
                const vvpPath = simConfig.vvpPath;

                // run vvp to interrupt script
                const vvpCommand = `${vvpPath} ${outVvpPath}`;
                MainOutput.report(vvpCommand, ReportType.Run);
                
                child_process.exec(vvpCommand, { cwd }, (error, stdout, stderr) => {
                    if (error) {
                        MainOutput.report('Error took place when run ' + vvpCommand, ReportType.Error);
                        MainOutput.report('Reason: ' + stderr, ReportType.Error);
                    } else {
                        MainOutput.report(stdout, ReportType.Info);
                    }
                });
            }
        });
    }

    private exec(command: string, cwd: AbsPath) {
        const simConfig = this.simConfig;
        if (!simConfig) {
            MainOutput.report('this.simConfig is empty when exec');
            return;
        }

        const runInTerminal = vscode.workspace.getConfiguration().get('function.simulate.runInTerminal');
        
        if (runInTerminal) {
            this.execInTerminal(command, cwd);
        } else {
            MainOutput.show();
            this.execInOutput(command, cwd);
        }
    }

    private getAllOtherDependences(path: AbsPath, name: string): AbsPath[] {
        const deps = hdlParam.getAllDependences(path, name);
        if (deps) {
            return deps.others;
        } else {
            MainOutput.report('Fail to get dependences of path: ' + path + ' name: ' + name, ReportType.Warn);
            return [];
        }
    }

    private simulateByHdlModule(hdlModule: HdlModule) {
        const name = hdlModule.name;
        const path = hdlModule.path;
        if (!hdlParam.isTopModule(path, name, false)) {
            const warningMsg = name + ' in ' + path + ' is not top module';
            MainOutput.report(warningMsg, ReportType.Warn, true);
            return;
        }
        const dependences = this.getAllOtherDependences(path, name);
        const simulationCommand = this.getCommand(name, path, dependences);
        if (simulationCommand) {
            const cwd = hdlPath.resolve(path, '..');            
            this.exec(simulationCommand, cwd);
        } else {
            const errorMsg = 'Fail to generate command';
            MainOutput.report(errorMsg, ReportType.Error, true);
            return;
        }
    }
    

    public async simulateModule(hdlModule: HdlModule) {
        this.simulateByHdlModule(hdlModule);
    }

    public async simulateFile() {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            return;
        }
        const uri = editor.document.uri;
        const path = hdlPath.toSlash(uri.fsPath);

        const currentFile = hdlParam.getHdlFile(path);
        if (!currentFile) {
            MainOutput.report('path ' + path + ' is not a hdlFile', ReportType.Error, true);
            return;
        }
        const items = getSelectItem(currentFile.getAllHdlModules());
        if (items.length) {
            let selectModule: HdlModule;
            if (items.length === 1) {
                selectModule = items[0].module;
            } else {
                const select = await vscode.window.showQuickPick(items, {placeHolder: 'choose a top module'});
                if (select) {
                    selectModule = select.module;
                } else {
                    return;
                }
            }
            this.simulateByHdlModule(selectModule);
        }
    }
}

const icarus = new IcarusSimulate();

namespace Icarus {
    export async function simulateModule(hdlModule: HdlModule) {
        await icarus.simulateModule(hdlModule);
    }
    
    export async function simulateFile() {
        await icarus.simulateFile();
    }
};

export {
    Icarus
};