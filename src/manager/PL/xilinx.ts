/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import { exec } from 'child_process';
import * as fspath from 'path';
import * as fs from 'fs';

import { AbsPath, opeParam, PrjInfo } from '../../global';
import { hdlParam } from '../../hdlParser/core';
import { hdlFile, hdlDir, hdlPath } from '../../hdlFs';
import { PropertySchema } from '../../global/propertySchema';

import { XilinxIP } from '../../global/enum';
import { MainOutput } from '../../global/outputChannel';

interface XilinxCustom {
    ipRepo: AbsPath, 
    bdRepo: AbsPath
};

interface TopMod {
    src: string, 
    sim: string
};

interface PLConfig {
    terminal : vscode.Terminal | null,
    tool? : string,                  // 工具类型
    path? : string,                  // 第三方工具运行路径
    ope : XilinxOperation,
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
    constructor() {
        this.guiLaunched = false;
    }

    public get xipRepo(): XilinxIP[] {
        return opeParam.prjInfo.IP_REPO; 
    }

    public get xipPath(): AbsPath {
        return hdlPath.join(opeParam.extensionPath, 'IP_repo');
    }

    public get xbdPath(): AbsPath {
        return hdlPath.join(opeParam.extensionPath, 'lib', 'xilinx', 'bd');
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
     * @param config
     */
    async launch(config: PLConfig): Promise<string | undefined> {
        this.guiLaunched = false;
        const vivadoTerminal = config.terminal;
        if (!vivadoTerminal) {
            return undefined;
        }

        let scripts: string[] = [];

        let prjFilePath = this.prjPath as AbsPath;
        const prjFiles = hdlFile.pickFileRecursive(prjFilePath, [], 
            filePath => filePath.endsWith('.xpr'));

        if (prjFiles.length) {
            if (prjFiles.length > 1) {
                const selection = await vscode.window.showQuickPick(prjFiles, { placeHolder : "Which project you want to open?" });
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
        scripts.push(this.getRefreshCmd());
        scripts.push(`file delete ${tclPath} -force`);
        const tclCommands = scripts.join('\n') + '\n';

        hdlFile.writeFile(tclPath, tclCommands);

        const argu = `-notrace -nolog -nojournal`;
        const cmd = `${config.path} -mode tcl -s ${tclPath} ${argu}`;

        vivadoTerminal.show(true);
        vivadoTerminal.sendText(cmd);
    }

    create(scripts: string[]) {
        scripts.push(`set_param general.maxThreads 8`);
        scripts.push(`create_project ${this.prjInfo.name} ${this.prjInfo.path} -part ${this.prjInfo.device} -force`);
        scripts.push(`set_property SOURCE_SET source_1   [get_filesets sim_1]`);
        scripts.push(`set_property top_lib xil_defaultlib [get_filesets sim_1]`);
        scripts.push(`update_compile_order -fileset sim_1 -quiet`);
    }

    open(path: AbsPath, scripts: string[]) {
        scripts.push(`set_param general.maxThreads 8`);
        scripts.push(`open_project ${path} -quiet`);
    }

    private getRefreshCmd(): string {
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
    
            const bdPaths = [
                hdlPath.join(this.HWPath, 'bd'),
                hdlPath.join(this.prjInfo.path, this.prjInfo.name + '.src', 'source_1', 'bd')
            ];

            hdlFile.pickFileRecursive(bdPaths, [], (filePath) => {
                if (filePath.endsWith('.bd')) {
                    scripts.push(`add_files ${filePath} -quiet`);
                    scripts.push(`add_files ${fspath.dirname(filePath)}/hdl -quiet`);
                }
            });
    
            if (bd) {
                const loadBdPath = hdlPath.join(this.HWPath, 'bd', bd, bdFile);
                scripts.push(`generate_target all [get_files ${loadBdPath}] -quiet`);
                scripts.push(`make_wrapper -files [get_files ${loadBdPath}] -top -quiet`);
                scripts.push(`open_bd_design ${loadBdPath} -quiet`);
            }
        }

        const mrefPath = hdlPath.join(this.HWPath, 'bd', 'mref');
        hdlFile.pickFileRecursive(mrefPath, [], filePath => {
            if (filePath.endsWith('.tcl')) {
                scripts.push(`source ${filePath}`);
            }
        });

        // 导入ip设计源文件
        const ipPaths = [
            hdlPath.join(this.HWPath, 'ip'),
            hdlPath.join(this.prjInfo.path, this.prjInfo.name + '.src', 'source_1', 'ip')
        ];

        hdlFile.pickFileRecursive(ipPaths, [], filePath => {
            if (filePath.endsWith('.xci')) {
                scripts.push(`add_files ${filePath} -quiet`);
            }
        });

        // 导入非本地的设计源文件
        const HDLFiles = hdlParam.getAllHdlFiles();
        for (const file of HDLFiles) {
            if (file.type === "src") {
                scripts.push(`add_files ${file.path} -quiet`);
            }
            scripts.push(`add_files -fileset sim_1 ${file.path} -quiet`);
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

    refresh(terminal: vscode.Terminal) {
        const cmd = this.getRefreshCmd();
        terminal.sendText(cmd);
    }

    simulate(config: PLConfig) {
        this.simulateCli(config);
    }

    simulateGui(config: PLConfig) {
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
        config.terminal?.sendText(cmd);
    }

    simulateCli(config: PLConfig) {
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
        config.terminal?.sendText(cmd);
    }

    synth(config: PLConfig) {
        let quietArg = '';
        if (opeParam.prjInfo.enableShowLog) {
            quietArg = '-quiet';
        }

        let script = '';
        script += `reset_run synth_1 ${quietArg};`;
        script += `launch_runs synth_1 ${quietArg} -jobs 4;`;
        script += `wait_on_run synth_1 ${quietArg}`;

        config.terminal?.sendText(script);
    }

    impl(config: PLConfig) {
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

        config.terminal?.sendText(script);
    }

    build(config: PLConfig) {
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

        this.generateBit(config);

        const scriptPath = `${this.xilinxPath}/build.tcl`;
        script += `source ${scriptPath} -notrace\n`;

        script += `file delete ${scriptPath} -force\n`;
        hdlFile.writeFile(scriptPath, script);
        const cmd = `source ${scriptPath} -quiet`;
        config.terminal?.sendText(cmd);
    }


    generateBit(config: PLConfig) {
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
        config.terminal?.sendText(cmd);
    }

    program(config: PLConfig) {
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
        config.terminal?.sendText(cmd);
    }

    public gui(config: PLConfig) {
        if (config.terminal) {
            config.terminal.sendText("start_gui -quiet");
            this.guiLaunched = true;
        } else {
            const prjFiles = hdlFile.pickFileRecursive(this.prjPath, [], 
                filePath => filePath.endsWith('.xpr'));

            const arg = '-notrace -nolog -nojournal';
            const cmd = `${config.path} -mode gui -s ${prjFiles[0]} ${arg}`;
            exec(cmd, (error, stdout, stderr) => {
                if (error !== null) {
                    vscode.window.showErrorMessage(stderr);
                } else {
                    vscode.window.showInformationMessage("GUI open successfully");
                    this.guiLaunched = true;
                }
            });
        }
    }

    public addFiles(files: string[], config: PLConfig) {
        if (!this.guiLaunched) {
            this.processFileInPrj(files, config, "add_file");
        }
    }

    public delFiles(files: string[], config: PLConfig) {
        if (!this.guiLaunched) {
            this.processFileInPrj(files, config, "remove_files");
        }
    }

    setSrcTop(name: string, config: PLConfig) {
        const cmd = `set_property top ${name} [current_fileset]`;
        config.terminal?.sendText(cmd);
    }

    setSimTop(name: string, config: PLConfig) {
        const cmd = `set_property top ${name} [get_filesets sim_1]`;
        config.terminal?.sendText(cmd);
    }

    processFileInPrj(files: string[], config: PLConfig, command: string) {
        const terminal = config.terminal;
        if (terminal) {
            for (const file of files) {
                terminal.sendText(command + ' ' + file);
            }
        }
    }

    xExecShowLog(logPath: AbsPath) {
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
    
    getConfig() {
        this.extensionPath = opeParam.extensionPath;
        this.xbdPath = hdlPath.join(this.extensionPath, 'lib', 'bd', 'xilinx');
        this.schemaPath = opeParam.propertySchemaPath;
        this.schemaCont = hdlFile.readJSON(this.schemaPath) as PropertySchema;
        this.bdEnum = this.schemaCont.properties?.soc.properties.bd.enum;
        this.bdRepo = this.setting.get('digital-ide.prj.xilinx.BD.repo.path', '');
    }

    async overwrite(uri: vscode.Uri): Promise<void> {
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

    add(uri: vscode.Uri) {
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

    
    delete() {
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

    load() {
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
        const paths: AbsPath[] = hdlFile.pickFileRecursive(outsidePath, [], 
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
        let bitList = hdlFile.pickFileRecursive(bitPath, [], 
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
        return hdlFile.pickFileRecursive(path, [], 
            filePath => filePath.endsWith('.elf') && !filePath.endsWith('fsbl.elf'));
    }
};


export {
    XilinxOperation,
    tools,
    XilinxBd,
    PLConfig
};
