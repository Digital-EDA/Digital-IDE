/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import { ChildProcessWithoutNullStreams, exec, spawn } from 'child_process';
import * as fspath from 'path';
import * as fs from 'fs';

import { AbsPath, opeParam, PrjInfo } from '../../global';
import { hdlParam } from '../../hdlParser/core';
import { hdlFile, hdlDir, hdlPath } from '../../hdlFs';
import { PropertySchema } from '../../global/propertySchema';

import { XilinxIP } from '../../global/enum';
import { HardwareOutput, MainOutput, ReportType } from '../../global/outputChannel';
import { debounce, getPIDsWithName, killProcess } from '../../global/util';
import { t } from '../../i18n';
import { HdlFileProjectType } from '../../hdlParser/common';

interface XilinxCustom {
    ipRepo: AbsPath, 
    bdRepo: AbsPath
};

interface TopMod {
    src: string, 
    sim: string
};

// Programmable Logic Context for short
interface PLContext {
    // 保留启动上下文
    terminal? : vscode.Terminal,
    // 目前使用的启动上下文
    process?: ChildProcessWithoutNullStreams,
    // 工具类型
    tool? : string,
    // 第三方工具运行路径
    path? : string,
    // 操作类
    ope : Record<string, any>
};

interface PLPrjInfo {
    path : AbsPath,
    name : string,
    device : string
};

interface BootInfo {
    outsidePath : AbsPath,
    insidePath : AbsPath,
    outputPath : AbsPath,
    elfPath : AbsPath,
    bitPath : AbsPath,
    fsblPath : AbsPath
};

/**
 * xilinx operation under PL
 */
class XilinxOperation {
    guiLaunched: boolean;
    guiPid: number;
    constructor() {
        this.guiLaunched = false;
        this.guiPid = -1;
    }

    public get xipRepo(): XilinxIP[] {
        return opeParam.prjInfo.IP_REPO; 
    }

    public get xipPath(): AbsPath {
        return hdlPath.join(opeParam.extensionPath, 'IP_repo');
    }

    public get xbdPath(): AbsPath {
        return hdlPath.join(opeParam.extensionPath, 'library', 'Factory', 'xilinx', 'bd');
    }

    public get xilinxPath(): AbsPath {
        return hdlPath.join(opeParam.extensionPath, 'resources', 'script', 'xilinx');
    }

    public get prjPath(): AbsPath {
        return opeParam.prjInfo.arch.prjPath;
    }

    public get srcPath(): AbsPath {
        return opeParam.prjInfo.arch.hardware.src;
    }

    public get simPath(): AbsPath {
        return opeParam.prjInfo.arch.hardware.sim;
    }

    public get datPath(): AbsPath {
        return opeParam.prjInfo.arch.hardware.data;
    }

    public get softSrc(): AbsPath {
        return opeParam.prjInfo.arch.software.src;
    }

    public get HWPath(): AbsPath {
        return fspath.dirname(this.srcPath);
    }

    public get extensionPath(): AbsPath {
        return opeParam.extensionPath;
    }

    public get prjConfig(): PrjInfo {
        return opeParam.prjInfo;
    }

    public get custom(): XilinxCustom {
        return {
            ipRepo: vscode.workspace.getConfiguration().get('digital-ide.prj.xilinx.IP.repo.path', ''),
            bdRepo: vscode.workspace.getConfiguration().get('digital-ide.prj.xilinx.BD.repo.path', '')
        };
    }
    
    public get topMod(): TopMod {
        return {
            src : opeParam.firstSrcTopModule.name,
            sim : opeParam.firstSimTopModule.name,
        };
    }

    public get prjInfo(): PLPrjInfo {
        return {
            path : hdlPath.join(this.prjPath, 'xilinx'),
            name : opeParam.prjInfo.prjName.PL,
            device : opeParam.prjInfo.device
        };
    }

    /**
     * xilinx下的launch运行，打开存在的工程或者再没有工程时进行新建
     * @param context
     */
    public async launch(context: PLContext): Promise<string | undefined> {
        this.guiLaunched = false;
        this.guiPid = -1;

        let scripts: string[] = [];
        let prjFilePath = this.prjPath as AbsPath;
        // 找到所有的 xilinx 工程文件
        const prjFiles = hdlFile.pickFileRecursive(prjFilePath, 
            filePath => filePath.endsWith('.xpr')
        );

        if (prjFiles.length) {
            if (prjFiles.length > 1) {
                const selection = await vscode.window.showQuickPick(prjFiles, {
                    placeHolder : t('info.pl.xilinx.launch.pick-project-placeholder'),
                    canPickMany: false
                });
                if (selection) {
                    this.open(selection, scripts);
                }
            } else {
                prjFilePath = prjFiles[0];
                this.open(prjFilePath, scripts);
            }
        } else {
            if (!hdlDir.mkdir(this.prjInfo.path)) {
                vscode.window.showErrorMessage(`mkdir ${this.prjInfo.path} failed`);
                return undefined;
            }

            this.create(scripts);
        }

        const tclPath = hdlPath.join(this.xilinxPath, 'launch.tcl');
        scripts.push(this.getRefreshXprDesignSourceCommand());
        scripts.push(`file delete ${tclPath} -force`);
        const tclCommands = scripts.join('\n') + '\n';
        hdlFile.writeFile(tclPath, tclCommands);

        const argu = `-notrace -nolog -nojournal`;
        context.path = this.updateVivadoPath();
        const cmd = `${context.path} -mode tcl -s ${tclPath} ${argu}`;
        
        const _this = this;
        
        const onVivadoClose = debounce(() => {
            _this.onVivadoClose();
        }, 100);

        function launchScript(pids: number[]): Promise<ChildProcessWithoutNullStreams | undefined> {
            if (!opeParam.workspacePath) {
                return Promise.resolve(undefined);
            }

            const vivadoPids = new Set<number>(pids);
            const vivadoProcess = spawn(cmd, [], { shell: true, stdio: 'pipe', cwd: opeParam.workspacePath });
            let status: 'pending' | 'fulfilled' = 'pending';

            vivadoProcess.on('close', () => {
                onVivadoClose();            
            });
            vivadoProcess.on('exit', () => {
                onVivadoClose();
            });
            vivadoProcess.on('disconnect', () => {
                onVivadoClose();
            });

            return new Promise(resolve => {
                vivadoProcess.stdout.on('data', async data => {
                    const message: string = _this.handleMessage(data.toString(), status);                                        
                    if (status === 'pending') {
                        HardwareOutput.clear();
                        HardwareOutput.show();
                        const pids = await getPIDsWithName('vivado');
                        const newPid = pids.find(p => !vivadoPids.has(p));
                        if (newPid) {
                            _this.guiPid = newPid;
                        }
                        resolve(vivadoProcess);
                    }
                    HardwareOutput.report(message, {
                        level: ReportType.Info
                    });
                    status = 'fulfilled';
                });

                vivadoProcess.stderr.on('data', async data => {
                    HardwareOutput.report(data.toString(), {
                        level: ReportType.Error
                    });
                    HardwareOutput.show();
                    if (status === 'pending') {
                        // pending 阶段就出现 stderr 说明启动失败
                        resolve(undefined);

                        const vivadoInstallPath = vscode.workspace.getConfiguration('digital-ide').get<string>('prj.vivado.install.path') || '';
                        
                        const res = await vscode.window.showErrorMessage(
                            t('error.pl.launch.not-valid-vivado-path', data.toString(), vivadoInstallPath.toString()),
                            {
                                title: t('info.pl.launch.set-vivado-path'),
                                value: true
                            }
                        );
                        if (res?.value) {
                            await vscode.commands.executeCommand('workbench.action.openSettings', 'digital-ide.prj.vivado.install.path');
                        }
                    }
                });
            });
        }

        const process = await vscode.window.withProgress({
            title: t('info.pl.launch.progress.launch-tcl.title'),
            location: vscode.ProgressLocation.Notification,
            cancellable: true
        }, async () => {
            const originVivadoPids = await getPIDsWithName('vivado');
            return await launchScript(originVivadoPids);
        });

        context.process = process;
    }

    private handleMessage(message: string, status: 'pending' | 'fulfilled'): string {        
        if (status === 'fulfilled') {
            return message.trim();
        } else {
            const messageBuffer: string[] = [];
            for (const line of message.trim().split('\n')) {
                if (line.startsWith('source') && line.includes('.tcl')) {
                    continue;
                }
                messageBuffer.push(line);
            }
            const launchInfo = t('info.pl.launch.launch-info');
            messageBuffer.unshift(launchInfo);
            return messageBuffer.join("\n");
        }
    }

    private async onVivadoClose() {
        const workspacePath = opeParam.workspacePath;
        const plName = opeParam.prjInfo.prjName.PL;
        const targetPath = fspath.dirname(opeParam.prjInfo.arch.hardware.src);

        if (hdlDir.isDir(`${workspacePath}/prj/xilinx/${plName}.gen`)) {            
            const sourceIpPath = `${workspacePath}/prj/xilinx/${plName}.gen/sources_1/ip`;
            const sourceBdPath = `${workspacePath}/prj/xilinx/${plName}.gen/sources_1/bd`;
    
            hdlDir.mvdir(sourceIpPath, targetPath, true);
            HardwareOutput.report("move dir from " + sourceIpPath + " to " + targetPath);
    
            hdlDir.mvdir(sourceBdPath, targetPath, true);
            HardwareOutput.report("move dir from " + sourceBdPath + " to " + targetPath);
        }

        if (hdlDir.isDir(`${workspacePath}/prj/xilinx/${plName}.srcs`)) {            
            const sourceIpPath = `${workspacePath}/prj/xilinx/${plName}.srcs/sources_1/ip`;
            const sourceBdPath = `${workspacePath}/prj/xilinx/${plName}.srcs/sources_1/bd`;
    
            hdlDir.mvdir(sourceIpPath, targetPath, true);
            HardwareOutput.report("move dir from " + sourceIpPath + " to " + targetPath);
    
            hdlDir.mvdir(sourceBdPath, targetPath, true);
            HardwareOutput.report("move dir from " + sourceBdPath + " to " + targetPath);
        }

        await this.closeAllWindows();
    }

    public create(scripts: string[]) {
        scripts.push(`set_param general.maxThreads 8`);
        scripts.push(`create_project ${this.prjInfo.name} ${this.prjInfo.path} -part ${this.prjInfo.device} -force`);
        scripts.push(`set_property SOURCE_SET sources_1   [get_filesets sim_1]`);
        scripts.push(`set_property top_lib xil_defaultlib [get_filesets sim_1]`);
        scripts.push(`update_compile_order -fileset sim_1 -quiet`);
    }

    public open(path: AbsPath, scripts: string[]) {
        scripts.push(`set_param general.maxThreads 8`);
        scripts.push(`open_project ${path} -quiet`);
    }

    /**
     * @description 更新 xpr 设计源的命令
     * @returns 
     */
    private getRefreshXprDesignSourceCommand(): string {
        const scripts: string[] = [];
        // 清除所有源文件
        scripts.push(`remove_files -quiet [get_files]`);

        // 导入 IP_repo_paths
        scripts.push(`set xip_repo_paths {}`);

        if (fs.existsSync(this.custom.ipRepo)) {
            scripts.push(`lappend xip_repo_paths ${this.custom.ipRepo}`);
        }

        this.xipRepo.forEach(
            ip => scripts.push(`lappend xip_repo_paths ${this.xipPath}/${ip}`));
        
        scripts.push(`set_property ip_repo_paths $xip_repo_paths [current_project] -quiet`);
        scripts.push(`update_ip_catalog -quiet`);

        // 导入bd设计源文件
        if (hdlFile.isHasAttr(this.prjConfig, "SOC.bd")) {            
            const bd = this.prjConfig.soc.bd;
            const bdFile = bd + '.bd';
            let bdSrcPath = hdlPath.join(this.xbdPath, bdFile);
            if (!hdlFile.isFile(bdSrcPath)) {
                bdSrcPath = hdlPath.join(this.custom.bdRepo, bdFile);
            }
    
            if (!hdlFile.isFile(bdSrcPath)) {
                vscode.window.showErrorMessage(`can not find ${bd}.bd in ${this.xbdPath} and ${this.custom.bdRepo}`);
            } else {
                if (hdlFile.copyFile(
                    bdSrcPath, 
                    hdlPath.join(this.HWPath, 'bd', bd, bdFile)
                )) {
                    vscode.window.showErrorMessage(`cp ${bd} failed, can not find ${bdSrcPath}`);
                }
            }

            if (bd) {
                const loadBdPath = hdlPath.join(this.HWPath, 'bd', bd, bdFile);
                scripts.push(`generate_target all [get_files ${loadBdPath}] -quiet`);
                scripts.push(`make_wrapper -files [get_files ${loadBdPath}] -top -quiet`);
                scripts.push(`open_bd_design ${loadBdPath} -quiet`);
            }
        }
        
        const bdPaths = [
            hdlPath.join(this.HWPath, 'bd'),
            hdlPath.join(this.prjInfo.path, this.prjInfo.name + '.src', 'sources_1', 'bd')
        ];

        hdlFile.pickFileRecursive(bdPaths, filePath => {
            if (filePath.endsWith('.bd')) {
                scripts.push(`add_files ${filePath} -quiet`);
                scripts.push(`add_files ${fspath.dirname(filePath)}/hdl -quiet`);
            }
        });

        const mrefPath = hdlPath.join(this.HWPath, 'bd', 'mref');
        hdlFile.pickFileRecursive(mrefPath, filePath => {
            if (filePath.endsWith('.tcl')) {
                scripts.push(`source ${filePath}`);
            }
        });

        // 导入ip设计源文件
        const ipPaths = [
            hdlPath.join(this.HWPath, 'ip'),
            hdlPath.join(this.prjInfo.path, this.prjInfo.name + '.src', 'sources_1', 'ip')
        ];

        hdlFile.pickFileRecursive(ipPaths, filePath => {
            if (filePath.endsWith('.xci')) {
                scripts.push(`add_files ${filePath} -quiet`);
            }
        });

        // 导入非本地的设计源文件
        for (const hdlFile of hdlParam.getAllHdlFiles()) {
            switch (hdlFile.projectType) {
                case HdlFileProjectType.Src:
                case HdlFileProjectType.LocalLib:
                case HdlFileProjectType.RemoteLib:
                    // src 和 library 加入 source_1 设计源
                    scripts.push(`add_file ${hdlFile.path} -quiet`);
                    break;
                case HdlFileProjectType.Sim:
                    // sim 加入 sim_1 设计源
                    scripts.push(`add_file -fileset sim_1 ${hdlFile.path} -quiet`);
                    break;
                case HdlFileProjectType.IP:
                case HdlFileProjectType.Primitive:
                    // IP 和 原语不用管
                    break;
                default:
                    break;
            }
        }

        scripts.push(`add_files -fileset constrs_1 ${this.datPath} -quiet`);

        if (this.topMod.src !== '') {
            scripts.push(`set_property top ${this.topMod.src} [current_fileset]`);
        }
        if (this.topMod.sim !== '') {
            scripts.push(`set_property top ${this.topMod.sim} [get_filesets sim_1]`);
        }

        let script = '';
        for (let i = 0; i < scripts.length; i++) {
            const content = scripts[i];
            script += content + '\n';
        }

        const scriptPath = `${this.xilinxPath}/refresh.tcl`;
        script += `file delete ${scriptPath} -force\n`;
        hdlFile.writeFile(scriptPath, script);
        const cmd = `source ${scriptPath} -quiet`;
        return cmd;
    }

    /**
     * @description 【Xilinx Vivado 操作】更新 xpr 文件
     * @param context 
     */
    public refresh(context: PLContext) {
        vscode.window.showInformationMessage(
            "Xilinx: Refresh",
            { title: 'ok', value: true }
        );
        const cmd = this.getRefreshXprDesignSourceCommand();
        context.process?.stdin.write(cmd + '\n');
    }

    public async closeAllWindows() {
        if (this.guiPid > 0) {
            await killProcess(this.guiPid);
        }

        const srcscannerPids = await getPIDsWithName('srcscanner');
        for (const pid of srcscannerPids) {
            await killProcess(pid);
        }

        // 删除所有 vivado_pid21812.str
        for (const file of fs.readdirSync(opeParam.workspacePath)) {
            if (file.startsWith('vivado_pid') && file.endsWith('.str')) {
                const file_path = hdlPath.join(opeParam.workspacePath, file);
                hdlFile.rmSync(file_path);
            }
        }
    }

    public async exit(context: PLContext) {
        context.process?.stdin.write('exit' + '\n');
        await this.closeAllWindows();
    }

    public simulate(context: PLContext) {
        this.simulateCli(context);
    }

    public simulateGui(context: PLContext) {
        vscode.window.showInformationMessage(
            "Xilinx: Simulate GUI",
            { title: 'ok', value: true }
        );

        const scriptPath = `${this.xilinxPath}/simulate.tcl`;

        const script = `
if {[current_sim] != ""} {
    relaunch_sim -quiet
} else {
    launch_simulation -quiet
}

set curr_wave [current_wave_config]
if { [string length $curr_wave] == 0 } {
    if { [llength [get_objects]] > 0} {
        add_wave /
        set_property needs_save false [current_wave_config]
    } else {
        send_msg_id Add_Wave-1 WARNING "No top level signals found. Simulator will start without a wave window. If you want to open a wave window go to 'File->New Waveform Configuration' or type 'create_wave_config' in the TCL console."
    }
}
run 1us

start_gui -quiet
file delete ${scriptPath} -force\n`;

        hdlFile.writeFile(scriptPath, script);
        const cmd = `source ${scriptPath} -quiet`;
        
        HardwareOutput.report('simulateGui');
        context.process?.stdin.write(cmd + '\n');
    }

    public simulateCli(context: PLContext) {
        vscode.window.showInformationMessage(
            "Xilinx: Simulate CLI",
            { title: 'ok', value: true }
        );

        const scriptPath = hdlPath.join(this.xilinxPath, 'simulate.tcl');
        const script = `
if {[current_sim] != ""} {
    relaunch_sim -quiet
} else {
    launch_simulation -quiet
}

set curr_wave [current_wave_config]
if { [string length $curr_wave] == 0 } {
    if { [llength [get_objects]] > 0} {
        add_wave /
        set_property needs_save false [current_wave_config]
    } else {
        send_msg_id Add_Wave-1 WARNING "No top level signals found. Simulator will start without a wave window. If you want to open a wave window go to 'File->New Waveform Configuration' or type 'create_wave_config' in the TCL console."
    }
}
run 1us
file delete ${scriptPath} -force\n`;

        hdlFile.writeFile(scriptPath, script);
        const cmd = `source ${scriptPath} -quiet`;

        HardwareOutput.report('simulateCli');
        context.process?.stdin.write(cmd + '\n');
    }

    public synth(context: PLContext) {
        vscode.window.showInformationMessage(
            "Xilinx: Synth",
            { title: 'ok', value: true }
        );

        let quietArg = '';
        if (opeParam.prjInfo.enableShowLog) {
            quietArg = '-quiet';
        }

        let script = '';
        script += `reset_run synth_1 ${quietArg};`;
        script += `launch_runs synth_1 ${quietArg} -jobs 4;`;
        script += `wait_on_run synth_1 ${quietArg}`;

        context.process?.stdin.write(script + '\n');
    }

    impl(context: PLContext) {
        vscode.window.showInformationMessage(
            "Xilinx: Impl",
            { title: 'ok', value: true }
        );

        let quietArg = '';
        if (opeParam.prjInfo.enableShowLog) {
            quietArg = '-quiet';
        }

        let script = '';
        script += `reset_run impl_1 ${quietArg};`;
        script += `launch_runs impl_1 ${quietArg} -jobs 4;`;
        script += `wait_on_run impl_1 ${quietArg};`;
        script += `open_run impl_1 ${quietArg};`;
        script += `report_timing_summary ${quietArg}`;

        context.process?.stdin.write(script + '\n');
    }

    build(context: PLContext) {
        vscode.window.showInformationMessage(
            "Xilinx: Build",
            { title: 'ok', value: true }
        );
        let quietArg = '';
        if (this.prjConfig.enableShowLog) {
            quietArg = '-quiet';
        }
        
        let script = '';
        script += `reset_run synth_1 ${quietArg}\n`;
        script += `launch_runs synth_1 ${quietArg} -jobs 4\n`;
        script += `wait_on_run synth_1 ${quietArg}\n`;
        script += `reset_run impl_1 ${quietArg}\n`;
        script += `launch_runs impl_1 ${quietArg} -jobs 4\n`;
        script += `wait_on_run impl_1 ${quietArg}\n`;
        script += `open_run impl_1 ${quietArg}\n`;
        script += `report_timing_summary ${quietArg}\n`;

        this.generateBit(context);

        const scriptPath = `${this.xilinxPath}/build.tcl`;
        script += `source ${scriptPath} -notrace\n`;

        script += `file delete ${scriptPath} -force\n`;
        hdlFile.writeFile(scriptPath, script);
        const cmd = `source ${scriptPath} -quiet`;

        context.process?.stdin.write(cmd + '\n');
    }

    generateBit(context: PLContext) {
        vscode.window.showInformationMessage(
            "Xilinx: BitStream",
            { title: 'ok', value: true }
        );

        let scripts: string[] = [];
        let core = this.prjConfig.soc.core;
        let sysdefPath = `${this.prjInfo.path}/${this.prjInfo.name}.runs` + 
                         `/impl_1/${this.prjInfo.name}.sysdef`;

        if (core && (core !== "none")) {
            if (fs.existsSync(sysdefPath)) {
                scripts.push(`file copy -force ${sysdefPath} ${this.softSrc}/[current_project].hdf`);
            } else {
                scripts.push(`write_hwdef -force -file ${this.softSrc}/[current_project].hdf`);
            }
            // TODO: 是否专门设置输出文件路径的参数
            scripts.push(`write_bitstream ./[current_project].bit -force -quiet`);
        } else {
            scripts.push(`write_bitstream ./[current_project].bit -force -quiet -bin_file`);
        }

        let script = '';
        for (let i = 0; i < scripts.length; i++) {
            const content = scripts[i];
            script += content + '\n';
        }
        let scriptPath = `${this.xilinxPath}/bit.tcl`;
        script += `file delete ${scriptPath} -force\n`;
        hdlFile.writeFile(scriptPath, script);
        const cmd = `source ${scriptPath} -quiet`;

        context.process?.stdin.write(cmd + '\n');
    }

    program(context: PLContext) {
        vscode.window.showInformationMessage(
            "Xilinx: Program",
            { title: 'ok', value: true }
        );

        let scriptPath = `${this.xilinxPath}/program.tcl`;
        let script = `
open_hw -quiet
connect_hw_server -quiet
set found 0
foreach hw_target [get_hw_targets] {
    current_hw_target $hw_target
    open_hw_target -quiet
    foreach hw_device [get_hw_devices] {
        if { [string equal -length 6 [get_property PART $hw_device] ${this.prjInfo.device}] == 1 } {
            puts "------Successfully Found Hardware Target with a ${this.prjInfo.device} device------ "
            current_hw_device $hw_device
            set found 1
        }
    }
    if {$found == 1} {break}
    close_hw_target
}   

#download the hw_targets
if {$found == 0 } {
    puts "******ERROR : Did not find any Hardware Target with a ${this.prjInfo.device} device****** "
} else {
    set_property PROGRAM.FILE ./[current_project].bit [current_hw_device]
    program_hw_devices [current_hw_device] -quiet
    disconnect_hw_server -quiet
}
file delete ${scriptPath} -force\n`;

        hdlFile.writeFile(scriptPath, script);
        const cmd = `source ${scriptPath} -quiet`;

        context.process?.stdin.write(cmd + '\n');
    }

    public async gui(context: PLContext) {
        if (context.process === undefined) {
            await this.launch(context);
        }

        const tclProcess = context.process;
        if (tclProcess === undefined) {
            return;
        }

        tclProcess.stdin.write('start_gui -quiet\n');
        vscode.window.showInformationMessage(
            t('info.vivado-gui.started'),
            { title: t('ok'), value: true }
        );
        HardwareOutput.report(t('info.pl.gui.report-title'), {
            level: ReportType.Info
        });

        HardwareOutput.show();
        this.guiLaunched = true;
    }

    public addFiles(files: string[], context: PLContext) {
        if (!this.guiLaunched && files.length > 0) {
            const filesString = files.join("\n");
            HardwareOutput.report(t('info.pl.add-files.title') + '\n' + filesString);
            this.execCommandToFilesInTclInterpreter(files, context, "add_file");
        }
    }

    public delFiles(files: string[], context: PLContext) {
        if (!this.guiLaunched && files.length > 0) {
            const filesString = files.join("\n");
            HardwareOutput.report(t('info.pl.del-files.title') + '\n' + filesString);
            this.execCommandToFilesInTclInterpreter(files, context, "remove_files");
        }
    }

    /**
     * @description 设置为 src 顶层文件
     * @param name 
     * @param context 
     */
    public setSrcTop(name: string, context: PLContext) {
        const cmd = `set_property top ${name} [current_fileset]`;
        context.process?.stdin.write(cmd + '\n');
    }

    /**
     * @description 设置为 sim 顶层文件
     * @param name 
     * @param context 
     */
    public setSimTop(name: string, context: PLContext) {
        const cmd = `set_property top ${name} [get_filesets sim_1]`;
        context.process?.stdin.write(cmd + '\n');
    }

    /**
     * @description 为输入的每一个文件在 TCL 解释器中执行 command
     * @param files 
     * @param context 
     * @param command 
     */
    public execCommandToFilesInTclInterpreter(files: string[], context: PLContext, command: string) {
        if (context.process === undefined) {
            return;
        }
        for (const file of files) {
            context.process.stdin.write(command + ' ' + file + '\n');
        }
    }

    public xExecShowLog(logPath: AbsPath) {
        let logPathList = ["runme", "xvlog", "elaborate"];
        let fileName = fspath.basename(logPath, ".log");

        if (!logPathList.includes(fileName)) {
            return null;
        }

        let content = hdlFile.readFile(logPath);
        if (!content) {
            return null;
        }

        if (content.indexOf("INFO: [Common 17-206] Exiting Vivado") === -1) {
            return null;
        }

        let log = '';
        var regExp = /(?<head>CRITICAL WARNING:|ERROR:)(?<content>[\w\W]*?)(INFO:|WARNING:)/g;

        while (true) {
            let match = regExp.exec(content);
            if (match === null) {
                break;      
            }

            if (match.groups) {
                log += match.groups.head.replace("ERROR:", "[error] :");
                log += match.groups.content;
            }
        }

        MainOutput.report(log);
    }

    public updateVivadoPath(): string {
        const vivadoBinFolder = vscode.workspace.getConfiguration('digital-ide.prj.vivado.install').get<string>('path') || '';
        if (hdlFile.isDir(vivadoBinFolder)) {
            let vivadoPath = hdlPath.join(hdlPath.toSlash(vivadoBinFolder), 'vivado');
            if (opeParam.os === 'win32') {
                vivadoPath += '.bat';
            }
            return vivadoPath;
        } else {
            // 没有设置 vivado bin 文件夹，就认为用户已经把对应的路径加入环境变量了
            return 'vivado';
        }
    }
}

class XilinxBd {
    setting : vscode.WorkspaceConfiguration;
    extensionPath: AbsPath;
    xbdPath: AbsPath;
    schemaPath: AbsPath;
    schemaCont: PropertySchema;
    bdEnum: string[];
    bdRepo: AbsPath;

    constructor() {
        this.setting = vscode.workspace.getConfiguration();
        this.extensionPath = opeParam.extensionPath;
        this.xbdPath = hdlPath.join(this.extensionPath, 'lib', 'bd', 'xilinx');
        this.schemaPath = opeParam.propertySchemaPath;


        this.schemaCont = hdlFile.readJSON(this.schemaPath) as PropertySchema;
        
        this.bdEnum = this.schemaCont.properties.soc.properties.bd.enum;
        this.bdRepo = this.setting.get('digital-ide.prj.xilinx.BD.repo.path', '');
    }
    
    public getConfig() {
        this.extensionPath = opeParam.extensionPath;
        this.xbdPath = hdlPath.join(this.extensionPath, 'lib', 'bd', 'xilinx');
        this.schemaPath = opeParam.propertySchemaPath;
        this.schemaCont = hdlFile.readJSON(this.schemaPath) as PropertySchema;
        this.bdEnum = this.schemaCont.properties?.soc.properties.bd.enum;
        this.bdRepo = this.setting.get('digital-ide.prj.xilinx.BD.repo.path', '');
    }

    public async overwrite(uri: vscode.Uri): Promise<void> {
        this.getConfig();
        // 获取当前bd file的路径
        const select = await vscode.window.showQuickPick(this.bdEnum);
        // the user canceled the select
        if (!select) {
            return;
        }
        
        let bdSrcPath = `${this.xbdPath}/${select}.bd`;
        if (!hdlFile.isFile(bdSrcPath)) {
            bdSrcPath = `${this.bdRepo}/${select}.bd`;
        }

        if (!hdlFile.isFile(bdSrcPath)) {
            vscode.window.showErrorMessage(`can not find ${select}.bd in ${this.xbdPath} and ${this.bdRepo}, please load again.`);
        } else {
            const docPath = hdlPath.toSlash(uri.fsPath);
            const doc = hdlFile.readFile(docPath);
            if (doc) {
                hdlFile.writeFile(bdSrcPath, doc);
            }
        }
    }

    public add(uri: vscode.Uri) {
        this.getConfig();
        // 获取当前bd file的路径
        let docPath = hdlPath.toSlash(uri.fsPath);
        let bd_name = hdlPath.basename(docPath); 

        // 检查是否重复
        if (this.bdEnum.includes(bd_name)) {
            vscode.window.showWarningMessage(`The file already exists.`);
            return null;
        }

        // 获取存放路径
        let storePath = this.setting.get('digital-ide.prj.xilinx.BD.repo.path', '');
        if (!fs.existsSync(storePath)) {
            vscode.window.showWarningMessage(`This bd file will be added into extension folder.We don't recommend doing this because it will be cleared in the next update.`);
            storePath = this.xbdPath;
        }

        // 写入
        const bd_path = `${storePath}/${bd_name}.bd`;
        const doc = hdlFile.readFile(docPath);
        if (doc) {
            hdlFile.writeFile(bd_path, doc);
        }

        this.schemaCont.properties.soc.properties.bd.enum.push(bd_name);
        hdlFile.writeJSON(this.schemaPath, this.schemaCont);
    }

    
    public delete() {
        this.getConfig();
        vscode.window.showQuickPick(this.bdEnum).then(select => {
            // the user canceled the select
            if (!select) {
                return;
            }
            
            let bdSrcPath = `${this.xbdPath}/${select}.bd`;
            if (!hdlFile.isFile(bdSrcPath)) {
                bdSrcPath = `${this.bdRepo}/${select}.bd`;
            }

            if (!hdlFile.isFile(bdSrcPath)) {
                vscode.window.showErrorMessage(`can not find ${select}.bd in ${this.xbdPath} and ${this.bdRepo}, please load again.`);
            } else {
                hdlFile.removeFile(bdSrcPath);
            }
        });
    }

    public load() {
        this.getConfig();
        if (hdlFile.isDir(this.bdRepo)) {
            for (const file of fs.readdirSync(this.bdRepo)) {
                if (file.endsWith('.bd')) {
                    let basename = hdlPath.basename(file);
                    if (this.bdEnum.includes(basename)) {
                        return;
                    }
                    this.schemaCont.properties.soc.properties.bd.enum.push(basename);
                }
            }
        }

        hdlFile.writeJSON(this.schemaPath, this.schemaCont);
    }
};

const tools = {
    async boot() {
        // 声明变量
        const bootInfo: BootInfo = {
            outsidePath : hdlPath.join(fspath.dirname(opeParam.prjStructure.prjPath), 'boot'),
            insidePath  : hdlPath.join(opeParam.extensionPath, 'resources', 'boot', 'xilinx'),
            outputPath  : hdlPath.join(opeParam.extensionPath, 'resources', 'boot', 'xilinx', 'output.bif'),
            elfPath    : '',
            bitPath    : '',
            fsblPath   : ''
        };

        if (opeParam.prjInfo.INSIDE_BOOT_TYPE) {
            bootInfo.insidePath = hdlPath.join(bootInfo.insidePath, opeParam.prjInfo.INSIDE_BOOT_TYPE);
        } else {
            bootInfo.insidePath = hdlPath.join(bootInfo.insidePath, 'microphase');
        }
    
        let output_context =  "//arch = zynq; split = false; format = BIN\n";
            output_context += "the_ROM_image:\n";
            output_context += "{\n";
    
        bootInfo.fsblPath = await this.getfsblPath(bootInfo.outsidePath, bootInfo.insidePath);
        if (!bootInfo.fsblPath) {
            return null;
        }
        output_context += bootInfo.fsblPath;

        bootInfo.bitPath  = await this.getBitPath(opeParam.workspacePath);
        if (bootInfo.bitPath) {
            output_context += bootInfo.bitPath;
        }

        bootInfo.elfPath  = await this.getElfPath(bootInfo);
        if (!bootInfo.elfPath) {
            return null;
        }
        output_context += bootInfo.elfPath;

        output_context += "}";
        let result = hdlFile.writeFile(bootInfo.outputPath, output_context);
        if (!result) {
            return null;
        }

        let command = `bootgen -arch zynq -image ${bootInfo.outputPath} -o ${opeParam.workspacePath}/BOOT.bin -w on`;
        exec(command, function (error, stdout, stderr) {
            if (error) {
                vscode.window.showErrorMessage(`${error}`);
                vscode.window.showErrorMessage(`stderr: ${stderr}`);
                return;
            } else {
                vscode.window.showInformationMessage("write boot file successfully!!");
            }
        });
    },

    async getfsblPath(outsidePath: AbsPath, insidePath: AbsPath): Promise<string> {
        const paths: AbsPath[] = hdlFile.pickFileRecursive(outsidePath,
            filePath => filePath.endsWith('fsbl.elf'));

        if (paths.length) {
            if (paths.length === 1) {
                return `\t[bootloader]${outsidePath}/${paths[0]}\n`;
            }

            let selection = await vscode.window.showQuickPick(paths);
            if (!selection) {
                return '';
            }
            return `\t[bootloader]${outsidePath}/${selection}\n`;
        }
        
        return `\t[bootloader]${insidePath}/fsbl.elf\n`;
    },

    async getBitPath(bitPath: AbsPath): Promise<string> {
        let bitList = hdlFile.pickFileRecursive(bitPath,
            filePath => filePath.endsWith('.bit'));

        if (bitList.length === 0) {
            vscode.window.showInformationMessage("Generated only from elf file");
        } 
        else if (bitList.length === 1) {
            return"\t" + bitPath + bitList[0] + "\n";
        }
        else {
            let selection = await vscode.window.showQuickPick(bitList);
            if (!selection) {
                return '';
            }
            return "\t" + bitPath + selection + "\n";
        }
        return '';
    },

    async getElfPath(bootInfo: BootInfo): Promise<string> {
        // 优先在外层寻找elf文件
        let elfs = this.pickElfFile(bootInfo.outsidePath);

        if (elfs.length) {
            if (elfs.length === 1) {
                return `\t${bootInfo.outsidePath}/${elfs[0]}\n`;
            }

            let selection = await vscode.window.showQuickPick(elfs);
            if (!selection) {
                return '';
            }
            return `\t${bootInfo.outsidePath}/${selection}\n`;
        }

        // 如果外层找不到文件则从内部调用
        elfs = this.pickElfFile(bootInfo.insidePath);
        if (elfs.length) {
            if (elfs.length === 1) {
                return `\t${bootInfo.insidePath}/${elfs[0]}\n`;
            }

            let selection = await vscode.window.showQuickPick(elfs);
            if (!selection) {
                return '';
            }
            return `\t${bootInfo.insidePath}/${selection}\n`;
        }

        // 如果内层也没有则直接退出
        vscode.window.showErrorMessage("The elf file was not found\n");
        return '';
    },
    
    pickElfFile(path: AbsPath): AbsPath[] {
        return hdlFile.pickFileRecursive(path,
            filePath => filePath.endsWith('.elf') && !filePath.endsWith('fsbl.elf'));
    }
};

export {
    XilinxOperation,
    tools,
    XilinxBd,
    PLContext
};
