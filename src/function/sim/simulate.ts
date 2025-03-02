import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';
import * as child_process from 'child_process';

import { hdlParam } from '../../hdlParser';
import { AbsPath, MainOutput, opeParam, ReportType } from '../../global';
import { hdlDir, hdlFile, hdlPath } from '../../hdlFs';
import { getSelectItem } from './instance';
import { HdlLangID, ToolChainType } from '../../global/enum';
import { HdlFile, HdlModule } from '../../hdlParser/core';
import { ModuleDataItem } from '../treeView/tree';
import { defaultMacro, doFastApi } from '../../hdlParser/util';
import { t } from '../../i18n';
import { openWaveViewer } from '../dide-viewer';

type Path = string;

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

function makeSafeArgPath(path: Path): string {
    const haveHeadQuote = path.startsWith('"');
    const haveTailQuote = path.startsWith('"');

    if (haveHeadQuote && haveHeadQuote) {
        return path;
    } else if (!haveHeadQuote && !haveTailQuote) {
        return '"' + path + '"';
    } else if (!haveHeadQuote && haveTailQuote) {
        return '"' + path;
    } else {
        return path + '"';
    }
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
            MainOutput.report('error when read ' + path, {
                level: ReportType.Error,
                notify: true
            });
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
        const defaultSimulationDir = hdlPath.join(opeParam.prjInfo.prjPath, 'icarus');
        
        simConfig.simulationHome = setting.get('digital-ide.function.simulate.simulationHome', '');
        if (!fs.existsSync(simConfig.simulationHome)) {
            simConfig.simulationHome = defaultSimulationDir;
        }
        
        
        if (!hdlFile.isDir(simConfig.simulationHome)) {
            MainOutput.report('create dir ' + simConfig.simulationHome, {
                level: ReportType.Info
            });
            hdlDir.mkdir(simConfig.simulationHome);
        }

        simConfig.gtkwavePath = setting.get('digital-ide.function.simulate.gtkwavePath', 'gtkwave');
        
        if (simConfig.gtkwavePath !== '' && !hdlFile.isDir(simConfig.gtkwavePath)) {
            simConfig.gtkwavePath = 'gtkwave'; // 如果不存在则认为是加入了环境变量
        } else {
            if (opeParam.os === 'win32') {
                simConfig.gtkwavePath = hdlPath.join(simConfig.gtkwavePath, 'gtkwave.exe');
            } else {
                simConfig.gtkwavePath = hdlPath.join(simConfig.gtkwavePath, 'gtkwave');
            }
        }

        simConfig.installPath = setting.get('digital-ide.prj.iverilog.install.path', '');
        if (simConfig.installPath !== '' && !hdlFile.isDir(simConfig.installPath)) {
            MainOutput.report(`install path ${simConfig.installPath} is illegal`, {
                level: ReportType.Error,
                notify: true
            });
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
            const simLibPath = setting.get('digital-ide.function.simulate.xilinxLibPath', '');

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
export class IcarusSimulate extends Simulate {
    os: string;
    prjPath: AbsPath;
    toolChain: ToolChainType;
    context: vscode.ExtensionContext;
    simConfig: SimulateConfig | undefined;

    constructor(context: vscode.ExtensionContext) {
        super();
        this.os = opeParam.os;
        this.context = context;
        this.prjPath = opeParam.prjInfo.arch.prjPath;
        this.toolChain = opeParam.prjInfo.toolChain;
    }

    private makeMacroIncludeArguments(includes: string[]): string {
        const args = [];
        for (const includePath of includes) {
            if(!hdlFile.isDir(includePath)) {
                args.push(makeSafeArgPath(includePath));
            } else {
                args.push('-I ' + makeSafeArgPath(includePath));
            }
        }
        return args.join(' ').trim();
    }

    /**
     * @description 生成用于进行仿真的依赖项相关的参数
     * @returns 
     */
    private makeDependenceArguments(dependences: string[]): string {
        // 去重
        const visitedPath = new Set<Path>;
        const args = [];
        for (const dep of dependences) {
            // 去重
            if (visitedPath.has(dep)) {
                continue;
            }
            // icarus 不支持 原语
            if (dep === 'xilinx-primitives') {
                MainOutput.report(t('error.simluate.icarus.use-primitives', dep), { level: ReportType.Error });
                continue;
            }
            // icarus 不支持 IP
            if (opeParam.prjInfo.ipPath.length > 0 && dep.startsWith(opeParam.prjInfo.ipPath)) {
                MainOutput.report(t('error.simluate.icarus.use-ip', dep), { level: ReportType.Error });
                continue;     
            }

            args.push(makeSafeArgPath(dep));
            visitedPath.add(dep);
        }
        
        return args.join(' ').trim();
    }

    private makeThirdLibraryArguments(simLibPaths: string[]): { fileArgsString: string, dirArgsString: string } {
        const fileArgs = [];
        const dirArgs = [];
        for (const libPath of simLibPaths) {
            if(!hdlFile.isDir(libPath)) {
                fileArgs.push(makeSafeArgPath(libPath));
            } else {
                dirArgs.push('-y ' + makeSafeArgPath(libPath));
            }
        }
        const fileArgsString = fileArgs.join(' ');
        const dirArgsString = dirArgs.join(' ');
        return { fileArgsString, dirArgsString };
    }

    /**
     * @description 获取 iverilog 仿真的命令
     * @returns 
     */
    private getCommand(name: string, path: AbsPath, dependences: string[]): string | undefined {
        MainOutput.clear();

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

        const thirdLibraryFileArgs = thirdLibraryArgs.fileArgsString;
        const thirdLibraryDirArgs = thirdLibraryArgs.dirArgsString;

        const iverilogPath = simConfig.iverilogPath;
        // default is -g2012
        const argu = '-g' + iverilogCompileOptions.standard;
        const outVvpPath = makeSafeArgPath(hdlPath.join(simConfig.simulationHome, name + '.vvp'));      
        const mainPath = makeSafeArgPath(path);

        const args = [];
        if (macroIncludeArgs) {
            args.push(macroIncludeArgs);
        }

        if (thirdLibraryDirArgs) {
            args.push(thirdLibraryDirArgs);
        }

        if (mainPath) {
            args.push(mainPath);
        }

        if (dependenceArgs) {
            args.push(dependenceArgs);
        }

        if (thirdLibraryFileArgs) {
            args.push(thirdLibraryFileArgs);
        }

        const extaArgs = args.join(' ');
        let command = `${iverilogPath} ${argu} -o ${outVvpPath} -s ${name}`;
        if (extaArgs) {
            command += ' ' + extaArgs;
        }

        // const parent = fspath.dirname(path);
        // command += ' ' + '-I "' + parent + '"';

        return command;
    }

    private execInTerminal(command: string, cwd: AbsPath, hdlModule: HdlModule) {
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

    /**
     * @description 在 Digital IDE 窗口中运行 iverilog 的快速仿真
     * @param command 
     * @param cwd 
     * @param hdlModule 
     * @returns 
     */
    private execInOutput(command: string, cwd: AbsPath, hdlModule: HdlModule) {
        const simConfig = this.simConfig;
        if (!simConfig) {
            return;
        }

        this.runIverilog(simConfig, command, cwd, hdlModule);
    }

    private reportCommandError(command: string, stderr: string) {
        MainOutput.report(t('error.simulation.error-happen-run-command') + command, {
            level: ReportType.Error
        });
        MainOutput.report(t('error.simulation.reason', stderr), {
            level: ReportType.Error
        });
    }

    /**
     * @description 运行 iverilog xxx 的命令
     */
    private runIverilog(simConfig: SimulateConfig, command: string, cwd: string, hdlModule: HdlModule) {
        child_process.exec(command, (error, stdout, stderr) => {
            if (error) {
                this.reportCommandError(command, stderr);
                return;
            }

            // 准备执行 vvp
            MainOutput.report(stdout);
            const generateVvpName = hdlModule.name + '.vvp';

            const outVvpPath = hdlPath.join(simConfig.simulationHome, generateVvpName);
            // MainOutput.report(t('info.simulation.create-vvp', outVvpPath), {
            //     level: ReportType.Run
            // });
            
            const vvpPath = simConfig.vvpPath;

            // 运行 vvp 文件，执行目录在生成的 vcd 的同级目录
            // 对于 vvp 执行的 cwd，为了方便用户可以调用 $readmemb $fopen $dumpfile
            // 这些系统调用进行 IO，所以选择 {workspace} 作为执行 vvp 的 cwd
            const vvpCwd = opeParam.openMode === 'file' ? cwd: opeParam.workspacePath;

            const vvpCommand = `${vvpPath} ${outVvpPath}`;
            // MainOutput.report(vvpCommand, { level: ReportType.Run });
            
            this.runVvp(vvpCommand, vvpCwd);
        });
    }

    /**
     * @description 陨星 vvp xxx 的命令
     */
    private runVvp(command: string, cwd: string) {
        child_process.exec(command, { cwd }, (error, stdout, stderr) => {
            if (error) {
                this.reportCommandError(command, stderr);
                return;
            }

            // 对于 vvp 的输出结果，特殊处理
            this.handleVvpStdOutput(stdout, command, cwd);
        });
    }

    /**
     * @description 处理 vvp xxx.vvp 执行后输出的标准输出
     * vvp 的标准输出似乎总是一行一个的
     * @param stdoutMessage vvp 执行后的标准输出窗口
     * @param command 用于重新执行
     * @param cwd 用于重新执行
     */
    private handleVvpStdOutput(stdoutMessage: string, command: string, cwd: string) {
        for (const line of stdoutMessage.split('\n').map(line => line.trim())) {
            if (line.startsWith('WARNING:')) {
                // 运行时警告
                MainOutput.report(line.slice(8).trim(), { level: ReportType.Warn });
                
            } else if (line.startsWith('ERROR:')) {
                // 运行时错误，比如用户 $readmemb 读取的文件并不存在
                MainOutput.report(line.slice(6).trim(), { level: ReportType.Error });

            } else if (line.startsWith('VCD info:')) {
                // 导出 VCD 的信息，用于输出
                // 此处尝试提取 vcd 导出的信息，然后转换内部信息导出到屏幕上
                const match = line.match(/dumpfile (.+) opened for output/);
                if (match) {
                    const vcdPath = match[1];
                    const absVcdPath = hdlPath.resolve(cwd, vcdPath);
                    MainOutput.report(t('info.simulate.vvp.vcd-generate', absVcdPath), { level: ReportType.Finish });
                    if (fs.existsSync(absVcdPath)) {
                        openWaveViewer(this.context, vscode.Uri.file(absVcdPath));
                    }
                } else {
                    MainOutput.report(line.slice(9).trim());
                }

            } else if (line.startsWith('VCD Error:')) {
                // 出现 VCD Error 可能是因为生成地点的目录不存在，创建目录，然后再运行                
                const match = line.match(/Unable to open (.+) for output\./);
                if (match) {
                    const vcdPath = match[1];
                    const absVcdPath = hdlPath.resolve(cwd, vcdPath);
                    const parentFolderPath = fspath.dirname(absVcdPath);
                    hdlDir.mkdir(parentFolderPath);
                    // 清除输出，准备第二次运行
                    MainOutput.clear();
                    this.runVvp(command, cwd);
                } else {
                    // 没有匹配到，说明是其他错误，直接按照错误输出
                    MainOutput.report(line.slice(10).trim(), { level: ReportType.Error });
                }
            } else {
                const displayMessage = line.trim();
                if (displayMessage) {
                    MainOutput.report(displayMessage, { level: ReportType.PrintOuput});
                }
            }
        }
    }

    private exec(command: string, cwd: AbsPath, hdlModule: HdlModule) {
        const simConfig = this.simConfig;
        if (!simConfig) {
            MainOutput.report('this.simConfig is empty when exec');
            return;
        }

        const runInTerminal = vscode.workspace.getConfiguration().get('digital-ide.function.simulate.runInTerminal');
        
        if (runInTerminal) {
            this.execInTerminal(command, cwd, hdlModule);
        } else {
            MainOutput.show();
            this.execInOutput(command, cwd, hdlModule);
        }
    }

    private getAllOtherDependences(path: AbsPath, name: string): AbsPath[] {
        const deps = hdlParam.getAllDependences(path, name);
        if (deps) {
            return deps.others;
        } else {
            // MainOutput.report('Fail to get dependences of path: ' + path + ' name: ' + name, ReportType.Warn);
            return [];
        }
    }

    private simulateByHdlModule(hdlModule: HdlModule) {
        const name = hdlModule.name;
        const path = hdlModule.path;
        // if (!hdlParam.isTopModule(path, name, false)) {
        //     const warningMsg = name + ' in ' + path + ' is not top module';
        //     MainOutput.report(warningMsg, ReportType.Warn, true);
        //     return;
        // }
        
        const dependences = this.getAllOtherDependences(path, name);        
        const simulationCommand = this.getCommand(name, path, dependences);
        if (simulationCommand) {
            const cwd = hdlPath.resolve(path, '..');            
            this.exec(simulationCommand, cwd, hdlModule);
        } else {
            const errorMsg = 'Fail to generate command';
            MainOutput.report(errorMsg, {
                level: ReportType.Error,
                notify: true
            });
            return;
        }
    }

    public async tryGetModuleFromView(view: ModuleDataItem): Promise<HdlModule | undefined> {         
        if (view.path) {
            const path = hdlPath.toEscapePath(view.path);
            const currentFile = hdlParam.getHdlFile(path);
            if (currentFile) {
                const modules = currentFile.getAllHdlModules();
                const targetModule = view.name === undefined ?
                    modules[0] :
                    modules.filter(mod => mod.name === view.name)[0];

                if (targetModule) {
                    return targetModule;
                }
            }
            // 没有获取有效的 module 则重新解析
            const langID = hdlFile.getLanguageId(path);            
            if (langID === HdlLangID.Unknown) {
                return undefined;
            }
            const standardPath = hdlPath.toSlash(path);

            const response = await doFastApi(standardPath, 'common');
            const projectType = hdlParam.getHdlFileProjectType(standardPath, 'common');               
            const moduleFile = new HdlFile(
                standardPath, langID,
                response?.macro || defaultMacro,
                response?.content || [],
                projectType,
                'common'
            );
            // 从 hdlParam 中去除，避免干扰全局
            hdlParam.removeFromHdlFile(moduleFile);
            const modules = moduleFile.getAllHdlModules();
            const targetModule = view.name === undefined ?
                modules[0] :
                modules.filter(mod => mod.name === view.name)[0];

            if (targetModule) {
                return targetModule;
            }
        } else {
            return undefined;
        }
    }

    public async simulateFile(view: ModuleDataItem) {
        const targetModule = await this.tryGetModuleFromView(view);

        if (targetModule !== undefined) {
            this.simulateByHdlModule(targetModule);
        } else {
            MainOutput.report('There is no module named ' + view.name + ' in ' + view.path, {
                level: ReportType.Error,
                notify: true
            });
            return;
        }
    }
}