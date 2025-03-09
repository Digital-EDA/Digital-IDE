/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';

import { AbsPath, IProgress, MainOutput, opeParam, ReportType } from '../global';
import { PathSet } from '../global/util';
import { RawPrjInfo } from '../global/prjInfo';
import { hdlDir, hdlFile, hdlPath } from '../hdlFs';
import { hdlParam } from '../hdlParser';
import { PlManage } from './PL';
import { PsManage } from './PS';
import { hdlIgnore } from './ignore';
import { hdlMonitor } from '../monitor';
import { t } from '../i18n';
import { PpyAction } from '../monitor/propery';
import { checkJson, readJSON } from '../hdlFs/file';


interface RefreshPrjConfig {
    mkdir: boolean
}

class PrjManage {
    pl?: PlManage;
    ps?: PsManage;

    /**
     * @description 生成 .vscode/property.json 
     * @returns 
     */
    public async generatePropertyJson(context: vscode.ExtensionContext) {
        if (fs.existsSync(opeParam.propertyJsonPath)) {
            vscode.window.showWarningMessage('property file already exists !!!');
            return;
        }

        const cachePPy = hdlPath.join(opeParam.dideHome, 'property-init.json');
        const propertyInitPath = fs.existsSync(cachePPy) ? cachePPy: opeParam.propertyInitPath;

        const template = hdlFile.readJSON(propertyInitPath) as RawPrjInfo;
        hdlFile.writeJSON(opeParam.propertyJsonPath, template);

        // 当创建 property.json 时，monitor 似乎无法获取到 ppy 的 add 事件
        // 所以此处需要手动调用
        const ppyAction = new PpyAction();
        await ppyAction.add(opeParam.propertyJsonPath, hdlMonitor);
    }

    /**
     * @description 用户自定义 property-init.json
     */
    public async overwritePropertyJson() {
        const dideHome = opeParam.dideHome;
        hdlDir.mkdir(dideHome);
        const cachePPy = hdlPath.join(dideHome, 'property-init.json');
        if (!fs.existsSync(cachePPy)) {
            hdlFile.copyFile(opeParam.propertyInitPath, cachePPy);
        }

        const options = {
            preview: false,
            viewColumn: vscode.ViewColumn.Active
        };
        const uri = vscode.Uri.file(cachePPy);
        await vscode.window.showTextDocument(uri, options);
    }

    private getWorkspacePath(): AbsPath {
        if (vscode.workspace.workspaceFolders !== undefined &&
            vscode.workspace.workspaceFolders.length !== 0) {
            const wsPath = vscode.workspace.workspaceFolders[0].uri.fsPath;
            return hdlPath.toSlash(wsPath);
        }
        return '';
    }

    /**
     * init opeParam
     * @param context 
     */
    public async initOpeParam(context: vscode.ExtensionContext): Promise<RefreshPrjConfig> {
        const os = process.platform;
        const extensionPath = hdlPath.toSlash(context.extensionPath);
        const workspacePath = this.getWorkspacePath();
        const propertyJsonPath = hdlPath.join(workspacePath, '.vscode', 'property.json');
        const propertySchemaPath = hdlPath.join(extensionPath, 'project', 'property-schema.json');
        const propertyInitPath = hdlPath.join(extensionPath, 'project', 'property-init.json');

        opeParam.setBasicInfo(os, 
                              extensionPath, 
                              workspacePath, 
                              propertyJsonPath, 
                              propertySchemaPath, 
                              propertyInitPath);
        
        opeParam.prjInfo.initContextPath(extensionPath, workspacePath);
        const refreshPrjConfig: RefreshPrjConfig = {mkdir: true};
        if (fs.existsSync(propertyJsonPath)) {
            const rawPrjInfo = hdlFile.readJSON(propertyJsonPath) as RawPrjInfo;
            opeParam.mergePrjInfo(rawPrjInfo);
        } else {
            refreshPrjConfig.mkdir = false;
        }

        // 创建用户目录
        hdlDir.mkdir(opeParam.dideHome);
        // 同步部分文件
        const cachePPySchema = hdlPath.join(opeParam.dideHome, 'property-schema.json');
        const propertySchema = opeParam.propertySchemaPath;
        if (fs.existsSync(cachePPySchema) && checkJson(cachePPySchema)) {
            hdlFile.copyFile(cachePPySchema, propertySchema);
        }

        return refreshPrjConfig;
    }

    /**
     * @description 获取所有的用户 hdl 文件，包括：
     * - sim
     * - src
     * - common lib
     * - custom lib
     * @returns 
     */
    public async getPrjHardwareFiles(): Promise<AbsPath[]> {
        const searchPathSet = new PathSet();
        const prjInfo = opeParam.prjInfo;
        const hardwareInfo = prjInfo.arch.hardware;

        // 根据当前的打开模式来判断
        if (opeParam.openMode === 'file') {
            // 如果是单文件模式，需要的操作
        } else {
            // 先处理 lib 文件
            // const fileChange = await libManage.processLibFiles(prjInfo.library);
            // MainOutput.report(`libManage finish process, add ${fileChange.add.length} files, del ${fileChange.del.length} files`;
    
            // 默认搜索路径包括：
            // src, sim, lib
            searchPathSet.checkAdd(prjInfo.hardwareSrcPath);
            searchPathSet.checkAdd(prjInfo.hardwareSimPath);
            searchPathSet.checkAdd(hardwareInfo.sim);
            searchPathSet.checkAdd(prjInfo.getLibraryCommonPaths());
            searchPathSet.checkAdd(prjInfo.getLibraryCustomPaths());
        }

        const reportMsg = ['', ... searchPathSet.files].join('\n\t');
        MainOutput.report(t('info.launch.search-and-parse') + reportMsg, {
            level: ReportType.Run
        });

        // 根据搜索路径获取所有 HDL 文件（出现在 .dideignore 中的文件不会被搜索到）
        const hdlFiles = hdlFile.getHDLFiles(searchPathSet.files);

        return hdlFiles;
    }

    /**
     * @description 获取当前项目中所有的 IP 文件夹
     */
    public async getPrjIPs() {
        const toolchain = opeParam.prjInfo.toolChain;
        
        switch (toolchain) {
            case 'xilinx':
                return this.getXilinxIPs();
                break;
        
            default:
                break;
        }
        return [];
    }

    public getXilinxIPs() {
        const srcFolder = opeParam.prjInfo.arch.hardware.src;
        const ipFolder = hdlPath.resolve(srcFolder, '../ip');
        const validIPs: string[] = [];
        if (fs.existsSync(ipFolder) && hdlFile.isDir(ipFolder)) {
            for (const folder of fs.readdirSync(ipFolder)) {
                const folderPath = hdlPath.join(ipFolder, folder);
                if (this.isValidXilinxIP(folderPath)) {
                    validIPs.push(folderPath);
                }
            }
        }
        return validIPs;
    }

    public isValidXilinxIP(folderPath: string): boolean {
        const folderName = fspath.basename(folderPath);
        const descriptionFile = folderName + '.xci';
        const descriptionFilePath = hdlPath.join(folderPath, descriptionFile);
        return fs.existsSync(descriptionFilePath);
    }

    public async initialise(context: vscode.ExtensionContext, progress: vscode.Progress<IProgress>, countTimeCost: boolean = true) {
        if (countTimeCost) {
            console.time('launch');
        }

        // 初始化 ignore
        hdlIgnore.updatePatterns();
        
        // 解析 hdl 文件，构建 hdlParam
        const hdlFiles = await this.getPrjHardwareFiles();                  
        await hdlParam.initializeHdlFiles(hdlFiles, progress);

        // 根据 toolchain 解析合法的 IP，构建 hdlParam
        const IPsPath = await this.getPrjIPs();
        await hdlParam.initializeIPsPath(IPsPath, progress);        

        // 构建 instance 解析
        await hdlParam.makeAllInstance();

        // 分析依赖关系错位情况
        const unhandleNum = hdlParam.getUnhandleInstanceNumber();
        const reportMsg = t('info.initialise.report.title', hdlFiles.length.toString(), unhandleNum.toString());
        MainOutput.report(reportMsg, {
            level: ReportType.Launch
        });

        this.pl = new PlManage();
        // TODO : finish it later
        // this.ps = new PsManage();

        if (countTimeCost) {
            console.timeLog('launch');
        }

        return hdlFiles;
    }

    public async refreshPrjFolder(config?: RefreshPrjConfig) {
        if (config && config.mkdir === false) {
            return;
        }
        // read new prj from ppy
        const rawPrjInfo = opeParam.getRawUserPrjInfo();

        if (rawPrjInfo.arch) {
            // configure user's info
            await this.createFolderByRawPrjInfo(rawPrjInfo);
        } else {
            // configure by default            
            await this.createFolderByDefault(rawPrjInfo);
        }

        opeParam.prjInfo.checkArchDirExist();
    }

    public async createFolderByRawPrjInfo(rawPrjInfo: RawPrjInfo) {
        if (rawPrjInfo.arch) {
            hdlDir.mkdir(rawPrjInfo.arch.prjPath);
            
            const hardware = rawPrjInfo.arch.hardware;
            const software = rawPrjInfo.arch.software;

            if (hardware) {
                hdlDir.mkdir(hardware.src);
                hdlDir.mkdir(hardware.sim);
                hdlDir.mkdir(hardware.data);
            }

            if (software) {
                hdlDir.mkdir(software.src);
                hdlDir.mkdir(software.data);
            }
        }
    }

    public async createFolderByDefault(rawPrjInfo: RawPrjInfo) {
        // create prj first
        const defaultPrjPath = hdlPath.join(opeParam.workspacePath, 'prj');
        hdlDir.mkdir(defaultPrjPath);

        // 如果 soc.core 有效，那么就是 LS，否则是 PL
        const nextmode = this.getNextMode(rawPrjInfo);
        
        const hardware = opeParam.prjInfo.arch.hardware;
        const software = opeParam.prjInfo.arch.software;
        
        hdlDir.mkdir(hardware.src);
        hdlDir.mkdir(hardware.sim);
        hdlDir.mkdir(hardware.data);
        if (nextmode === 'LS') {
            hdlDir.mkdir(software.src);
            hdlDir.mkdir(software.data);
        }
    }

    public getNextMode(rawPrjInfo: RawPrjInfo): 'PL' | 'LS' {
        if (rawPrjInfo.soc && rawPrjInfo.soc.core !== 'none') {
            return 'LS';
        }
        return 'PL';
    }

    public getCurrentMode(softwarePath: AbsPath, hardwarePath: AbsPath): 'PL' | 'LS' {
        if (fs.existsSync(softwarePath) || fs.existsSync(hardwarePath)) {
            return 'LS';
        }
        return 'PL';
    }

    /**
     * @description 指令 `digital-ide.structure.from-xilinx-to-standard` 的实现
     * 
     * 将 Xilinx 结构转变为标准项目结构
     */
    public async transformXilinxToStandard(context: vscode.ExtensionContext) {
        function xprFile(): string | undefined {
            if (opeParam.openMode === 'file' || opeParam.workspacePath.length === 0) {
                return undefined;
            }
            for (const filename of fs.readdirSync(opeParam.workspacePath)) {
                if (filename.endsWith('.xpr')) {
                    return filename;
                }
            }
            return undefined;
        }

        /**
         * @description 转移非 PL PS 文件夹
         * @param workspace 
         * @param plname 
         */
        function transformXilinxNonP(
            workspace: string,
            plname: string
        ) {
            const xilinxPL = plname + '.srcs';
            const xilinxPS = plname + '.sdk';
            const ignores = ['user', 'prj', '.vscode', xilinxPL, xilinxPS];
            hdlDir.rmdir(hdlPath.join(workspace, '.Xil'));
            for (const file of fs.readdirSync(workspace)) {
                // 排除标准文件夹
                if (ignores.includes(file)) {
                    continue;
                }

                const sourcePath = hdlPath.join(workspace, file);

                if (file.startsWith(plname)) {
                    const targetFolder = hdlPath.join(workspace, 'prj', 'xilinx');
                    hdlFile.move(sourcePath, targetFolder);
                } else {
                    // 排除非 hdl 文件
                    if (hdlFile.isFile(sourcePath) && !hdlFile.isHDLFile(sourcePath)) {
                        continue;
                    }
                    const targetFolder = hdlPath.join(workspace, 'user', 'src');
                    hdlFile.move(sourcePath, targetFolder);
                }
            }
        }

        /**
         * @description 搬移 Xilinx 项目中的 BD
         * 
         * bd 一般在 ${workspace}/${plname}.srcs/sources_xxx/bd 里面
         */
        function transformBD(
            matchPrefix: string,
            workspace: string,
            plname: string
        ) {
            const xilinxSrcsPath = hdlPath.join(workspace, plname + '.srcs');
            const standardBdPath = hdlPath.join(workspace, 'user', 'bd');
            if (!fs.existsSync(xilinxSrcsPath)) {
                return;
            }
            const sourceNames = fs.readdirSync(xilinxSrcsPath).filter(filename => filename.startsWith(matchPrefix));
            for (const sn of sourceNames) {
                const bdPath = hdlPath.join(xilinxSrcsPath, sn, 'bd');
                if (!hdlFile.isDir(bdPath)) {
                    continue;
                }

                for (const bdname of fs.readdirSync(bdPath)) {
                    const sourcePath = hdlPath.join(bdPath, bdname);
                    hdlDir.mvdir(sourcePath, standardBdPath, true);
                }
                hdlDir.rmdir(bdPath);
            }
        }
        

        /**
         * @description 搬移 Xilinx 项目中的 IP
         * 
         * IP 一般在 ${workspace}/${plname}.srcs/sources_xxx/ip 里面
         */
        function transformIP(
            matchPrefix: string,
            workspace: string,
            plname: string
        ) {
            const xilinxSrcsPath = hdlPath.join(workspace, plname + '.srcs');
            const standardIpPath = hdlPath.join(workspace, 'user', 'ip');
            if (!fs.existsSync(xilinxSrcsPath)) {
                return;
            }
            const sourceNames = fs.readdirSync(xilinxSrcsPath).filter(filename => filename.startsWith(matchPrefix));
            for (const sn of sourceNames) {
                const ipPath = hdlPath.join(xilinxSrcsPath, sn, 'ip');

                if (!hdlFile.isDir(ipPath)) {
                    continue;
                }

                for (const ipname of fs.readdirSync(ipPath)) {
                    const sourcePath = hdlPath.join(ipPath, ipname);
                    hdlDir.mvdir(sourcePath, standardIpPath, true);
                }
                hdlDir.rmdir(ipPath);
            }
        }

        /**
         * @description 将文件从 Xilinx 中迁移到标准结构去
         * 根据 ${workspace}/${plname}.srcs 下以 source_ 开头的前缀分两种情况：
         * - 如果只有一个 source_1，则将 ${workspace}/${plname}.srcs/sources_1 迁移
         * - 如果有多个 source_*，则将 ${workspace}/${plname}.srcs 迁移
         * @returns 
         */
        function transformXilinxPL(
            sourceType: 'src' | 'sim' | 'data',
            matchPrefix: string,
            workspace: string,
            plname: string
        ) {
            const xilinxSrcsPath = hdlPath.join(workspace, plname + '.srcs');
            if (!fs.existsSync(xilinxSrcsPath)) {
                return;
            }
            const sourceNames = fs.readdirSync(xilinxSrcsPath).filter(filename => filename.startsWith(matchPrefix));
            if (sourceNames.length === 0) {
                return;
            } else if (sourceNames.length === 1) {
                // 如果只有一个 source_1，则将 ${workspace}/${plname}.srcs/sources_1 迁移
                const sourceFolderPath = hdlPath.join(workspace, plname + '.srcs', sourceNames[0]);
                const targetPath = hdlPath.join(workspace, 'user', sourceType);
                for (const filename of fs.readdirSync(sourceFolderPath)) {
                    const sourcePath = hdlPath.join(sourceFolderPath, filename);
                    hdlFile.move(sourcePath, targetPath);
                }
                hdlDir.rmdir(sourceFolderPath);
            } else {
                // 如果有多个 source_*，则将 ${workspace}/${plname}.srcs 迁移
                for (const sn of sourceNames) {
                    const sourcePath = hdlPath.join(workspace, plname + '.srcs', sn);
                    const targetPath = hdlPath.join(workspace, 'user', sourceType);
                    hdlDir.mvdir(sourcePath, targetPath, true);
                }
            }
        }

        /**
         * @description 迁移 ${workspace}/${plname}.sdk 到 user/sdk 下
         * @returns 
         */
        function transformXilinxPS(
            workspace: string,
            plname: string
        ) {
            const xilinxSdkPath = hdlPath.join(workspace, plname + '.sdk');
            if (!fs.existsSync(xilinxSdkPath)) {
                return;
            }
            const standardSdkPath = hdlPath.join(workspace, 'user', 'sdk');
            hdlDir.mvdir(xilinxSdkPath, standardSdkPath, true);
            
            const hwNames = fs.readdirSync(standardSdkPath).filter(filename => filename.includes("_hw_platform_"));
            if (hwNames.length === 0) {
                return;
            } else if (hwNames.length === 1) {
                const hwFolderPath = hdlPath.join(standardSdkPath, hwNames[0]);
                const targetPath = hdlPath.join(standardSdkPath, 'data');
                for (const filename of fs.readdirSync(hwFolderPath)) {
                    hdlFile.move(hdlPath.join(hwFolderPath, filename), targetPath);
                }
                hdlDir.rmdir(hwFolderPath);
            } else {
                for (const hw of hwNames) {
                    const hwPath = hdlPath.join(standardSdkPath, hw);
                    const targetPath = hdlPath.join(standardSdkPath, 'data');
                    hdlDir.mvdir(hwPath, targetPath, true);
                }
            }
        }

        // 下方操作会产生大量的文件移动，为了进行性能优化，先关闭 monitor
        hdlMonitor.close();

        await vscode.window.withProgress({
            title: t('info.command.structure.transform-xilinx-to-standard'),
            location: vscode.ProgressLocation.Notification
        }, async () => {
            // 先获取 project name
            const xprfile = xprFile();            
            if (xprfile === undefined) {
                MainOutput.report(t('error.command.structure.not-valid-xilinx-project'), {
                    level: ReportType.Error,
                    notify: true
                });
                return;
            }

            const plname = xprfile.slice(0, -4);
            const workspacePath = opeParam.workspacePath;
            
            // 创建标准项目结构基本文件夹
            // xilinx prj
            hdlDir.mkdir(hdlPath.join(workspacePath, 'prj', 'xilinx'));

            // hardware
            hdlDir.mkdir(hdlPath.join(workspacePath, 'user', 'src'));
            hdlDir.mkdir(hdlPath.join(workspacePath, 'user', 'sim'));
            hdlDir.mkdir(hdlPath.join(workspacePath, 'user', 'data'));
            hdlDir.mkdir(hdlPath.join(workspacePath, 'user', 'ip'));

            hdlDir.mkdir(hdlPath.join(workspacePath, 'user', 'bd'));

            // software
            hdlDir.mkdir(hdlPath.join(workspacePath, 'user', 'sdk'));
            hdlDir.mkdir(hdlPath.join(workspacePath, 'user', 'sdk', 'data'));

            // 非 ${workspace}/${plname}.srcs ${workspace}/${plname}.sdk 的 ${workspace}/${plname}.* 文件夹迁移到 prj/xilinx 下
            // 其他文件夹迁移到 user/src 下面
            transformXilinxNonP(workspacePath, plname);

            // 迁移 IP
            transformIP('sources_', workspacePath, plname);
            transformIP('sim_', workspacePath, plname);

            // 迁移 BD
            transformBD('sources_', workspacePath, plname);
            transformBD('sim_', workspacePath, plname);

            // 迁移文件夹 ${workspace}/${plname}.srcs
            transformXilinxPL('src', 'sources_', workspacePath, plname);
            transformXilinxPL('sim', 'sim_', workspacePath, plname);
            transformXilinxPL('data', 'constrs_', workspacePath, plname);
            // 迁移文件夹 ${workspace}/${plname}.sdk
            transformXilinxPS(workspacePath, plname);
            
            // 删除原本的项目文件夹 ${workspace}/${plname}.srcs 和 ${workspace}/${plname}.sdk
            hdlDir.rmdir(hdlPath.join(workspacePath, plname + '.srcs'));
            hdlDir.rmdir(hdlPath.join(workspacePath, plname + '.sdk'));

            // 创建 property.json
            const ppyTemplate = hdlFile.readJSON(opeParam.propertyInitPath);
            ppyTemplate.prjName = {
                PL: plname
            };

            hdlFile.writeJSON(opeParam.propertyJsonPath, ppyTemplate);
        });

        const res = await vscode.window.showInformationMessage(
            t('info.command.structure.reload-vscode'),
            { title: t('info.common.confirm'), value: true }
        );

        if (res?.value) {
            await vscode.commands.executeCommand('workbench.action.reloadWindow');
        }

        // await vscode.window.withProgress({
        //     location: vscode.ProgressLocation.Window,
        //     title: t('info.progress.initialization')
        // }, async (progress: vscode.Progress<IProgress>, token: vscode.CancellationToken) => {
        //     hdlParam.clear();

        //     // 初始化解析
        //     await this.initialise(context, progress, false);
    
        //     // 刷新结构树
        //     refreshArchTree();
    
        //     // 启动监视器
        //     hdlMonitor.start();
        // });
    }

}

const prjManage = new PrjManage();

export {
    prjManage,
    PrjManage
};