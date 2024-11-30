import * as vscode from 'vscode';
import * as os from 'os';

import { AbsPath, IProgress, opeParam } from '../global';
import { HdlLangID } from '../global/enum';
import { MainOutput, ReportType } from '../global/outputChannel';

import * as common from './common';
import { hdlFile, hdlPath } from '../hdlFs';
import { defaultMacro, defaultRange, doPrimitivesJudgeApi, HdlSymbol } from './util';
import { DoFastFileType } from '../global/lsp';
import { t } from '../i18n';


class HdlParam {
    private readonly topModules : Set<HdlModule> = new Set<HdlModule>();
    private readonly srcTopModules : Set<HdlModule> = new Set<HdlModule>();
    private readonly simTopModules : Set<HdlModule> = new Set<HdlModule>();
    private readonly pathToHdlFiles : Map<AbsPath, HdlFile> = new Map<AbsPath, HdlFile>();
    public  readonly modules : Set<HdlModule> = new Set<HdlModule>();
    private readonly unhandleInstances : Set<HdlInstance> = new Set<HdlInstance>();

    public hasHdlFile(path: AbsPath): boolean {
        const moduleFile = this.getHdlFile(path);
        if (!moduleFile) {
            return false;
        }
        return true;
    }
    
    public getHdlFile(path: AbsPath): HdlFile | undefined {
        return this.pathToHdlFiles.get(path);
    }

    public getAllHdlFiles(): HdlFile[] {
        const hdlFiles = [];
        for (const [_, hdlFile] of this.pathToHdlFiles) {
            hdlFiles.push(hdlFile);
        }
        return hdlFiles;
    }

    /**
     * used only in initialization stage
     * @param hdlFile
     */
    public setHdlFile(hdlFile: HdlFile) {
        const path = hdlFile.path;
        this.pathToHdlFiles.set(path, hdlFile);
    }

    /**
     * add a file by path and create context
     * @param path absolute path of the file to be added
     */
    public async addHdlPath(path: AbsPath) {
        path = hdlPath.toSlash(path);
        await this.doHdlFast(path, 'common');
        const hdlFile = this.getHdlFile(path);
        if (!hdlFile) {
            MainOutput.report('error happen when we attempt to add file by path: ' + path, {
                level: ReportType.Error
            });
        } else {
            hdlFile.makeInstance();
            // when a new file is added, retry the solution of dependency
            for (const hdlModule of hdlFile.getAllHdlModules()) {
                hdlModule.solveUnhandleInstance();
            }
        }
    }

    public hasHdlModule(path: AbsPath | undefined, name: string): boolean {
        if (!path) {
            return false;
        }
        const hdlFile = this.getHdlFile(path);
        if (!hdlFile) {
            return false;
        }
        const hdlModule = hdlFile.getHdlModule(name);
        if (!hdlModule) {
            return false;
        }
        return true;
    }

    public getHdlModule(path: AbsPath, name: string): HdlModule | undefined {
        const hdlFile = this.getHdlFile(path);
        if (!hdlFile) {
            return undefined;
        }
        return hdlFile.getHdlModule(name);
    }

    public getAllHdlModules(): HdlModule[] {
        const hdlModules: HdlModule[] = [];
        this.modules.forEach(m => hdlModules.push(m));
        return hdlModules;
    }

    public addHdlModule(hdlModule: HdlModule) {
        this.modules.add(hdlModule);
    }

    public addTopModule(hdlModule: HdlModule) {
        this.topModules.add(hdlModule);
    }

    public deleteTopModule(hdlModule: HdlModule) {
        this.topModules.delete(hdlModule);
    }

    public getAllTopModules(global :boolean = false): HdlModule[] {
        const topModules: HdlModule[] = [];
        if (global) {
            this.topModules.forEach(m => topModules.push(m));
        } else {
            this.srcTopModules.forEach(m => topModules.push(m));
            this.simTopModules.forEach(m => topModules.push(m));
        }
        return topModules;
    }

    public isTopModule(path: AbsPath, name: string, global = false): boolean {
        const module = this.getHdlModule(path, name);
        if (!module) {
            return false;
        }
        if (global) {
            return this.topModules.has(module);
        } else {
            const sourceTopModule = this.selectTopModuleSourceByFileType(module);
            return sourceTopModule.has(module);
        }
    }

    public selectTopModuleSourceByFileType(hdlModule: HdlModule): Set<HdlModule> {
        switch (hdlModule.file.projectType) {
            case common.HdlFileProjectType.Src: return this.srcTopModules;
            case common.HdlFileProjectType.Sim: return this.simTopModules;
            case common.HdlFileProjectType.LocalLib: return this.srcTopModules;
            case common.HdlFileProjectType.RemoteLib: return this.srcTopModules;
            default: return this.srcTopModules;        
        }
    }

    /**
     * add module to top modules of a certain source (sim or src)
     * @param hdlModule 
     */
    public addTopModuleToSource(hdlModule: HdlModule) {
        const topModuleSource = this.selectTopModuleSourceByFileType(hdlModule);
        topModuleSource.add(hdlModule);
    }

    /**
     * @description 根据输入的 module 把它从所属的 src 或者 sim 的 topmodules 中去除
     * @param hdlModule 
     */
    public deleteTopModuleToSource(hdlModule: HdlModule) {
        const topModuleSource = this.selectTopModuleSourceByFileType(hdlModule);
        topModuleSource.delete(hdlModule);
    }

    public getAllDependences(path: AbsPath, name: string): common.HdlDependence | undefined {        
        const module = this.getHdlModule(path, name);
        if (!module) {
            return undefined;
        }

        if (this.isTopModule(path, name)) {
            console.log(module);
        }

        const dependencies : common.HdlDependence = {
            current: [],
            include: [],
            others: []
        };

        for (const inst of module.getAllInstances()) {
            if (!inst.module) {
                continue;
            }
            const status = inst.instModPathStatus;
            if (status === common.InstModPathStatus.Current && inst.instModPath) {
                dependencies.current.push(inst.instModPath);
            } else if (status === common.InstModPathStatus.Include && inst.instModPath) {
                dependencies.include.push(inst.instModPath);
            } else if (status === common.InstModPathStatus.Others && inst.instModPath) {
                dependencies.others.push(inst.instModPath);
            }
            const instDependencies = this.getAllDependences(inst.module.path, inst.module.name);            
            if (instDependencies) {
                dependencies.current.push(...instDependencies.current);
                dependencies.include.push(...instDependencies.include);
                dependencies.others.push(...instDependencies.others);
            }
        }

        return dependencies;
    }

    public getUnhandleInstanceNumber(): number {
        return this.unhandleInstances.size;
    }

    /**
     * @description 获取所有 scope 内存在 unhandle instance 的 module
     */
    public getAllUnhandleInstanceBelongedModule(): HdlModule[] {
        const modules = new Set<HdlModule>();
        for (const instance of this.unhandleInstances) {
            modules.add(instance.parentMod);
        }
        return [...modules];
    }

    /**
     * @description 输入 moduleName，找到这个 module 的所有置于 unhandleInstances 中的例化，并去 solve 它们
     * 因为一个 module 对应的 unsolved instance 可能不止一个。比如现在项目中，有两个地方存在 AGC 模块的例化，
     * 但是当前项目并没有引入 AGC 的 module 申明，那么当引入 AGC 后，外部就应该调用 getUnhandleInstancesByModuleName("AGC")
     * 并返回两个 AGC 的例化模块，然后去 solve 它们
     * @param moduleName 
     * @returns 
     */
    public getUnhandleInstancesByModuleName(moduleName: string): HdlInstance[] {
        const unsolvedInstances = [];
        for (const inst of this.unhandleInstances) {
            if (inst.type === moduleName) {
                unsolvedInstances.push(inst);
            }
        }
        return unsolvedInstances;
    }

    public addUnhandleInstance(inst: HdlInstance) {
        this.unhandleInstances.add(inst);
    }

    public deleteUnhandleInstance(inst: HdlInstance) {
        this.unhandleInstances.delete(inst);
    }

    private async doHdlFast(path: AbsPath, fileType: DoFastFileType) {
        try {
            const fast = await HdlSymbol.fast(path, fileType);
            if (fast) {
                const languageId = this.getRealLanguageId(path, fast.fileType);
                const fileProjectType = this.getHdlFileProjectType(path, fast.fileType);
                new HdlFile(path,
                            languageId,
                            fast.macro,
                            fast.content,
                            fileProjectType,
                            fast.fileType);
            }
        } catch (error) {
            MainOutput.report('Error happen when parse ' + path, {
                level: ReportType.Error
            });
            MainOutput.report('Reason: ' + error, {
                level: ReportType.Error
            });
        }
    }

    private getRealLanguageId(path: string, fileType: DoFastFileType): HdlLangID {
        if (fileType === 'ip' && opeParam.prjInfo.toolChain === 'xilinx') {
            return HdlLangID.Vhdl;
        }
        return hdlFile.getLanguageId(path);
    }

    public getHdlFileProjectType(path: string, fileType: DoFastFileType): common.HdlFileProjectType {
        switch (fileType) {
            case 'common':
                // 根据前缀来判断对应的类型
                path = hdlPath.toSlash(path);
                const prjInfo = opeParam.prjInfo;
                
                if (path.startsWith(prjInfo.hardwareSrcPath)) {
                    return common.HdlFileProjectType.Src;
                } else if (path.startsWith(prjInfo.hardwareSimPath)) {
                    return common.HdlFileProjectType.Sim;
                } else if (path.startsWith(prjInfo.ipPath)) {
                    return common.HdlFileProjectType.IP;
                } else if (path.startsWith(prjInfo.localLibPath)) {
                    return common.HdlFileProjectType.LocalLib;
                } else if (path.startsWith(prjInfo.remoteLibPath)) {
                    return common.HdlFileProjectType.RemoteLib;
                } else {
                    return common.HdlFileProjectType.Unknown;
                }
            case 'ip':
                return common.HdlFileProjectType.IP;
            case 'primitives':
                return common.HdlFileProjectType.Primitive;            
        }
    }

    public async initializeHdlFiles(hdlFiles: AbsPath[], progress: vscode.Progress<IProgress>) {        
        let count: number = 0;
        let fileNum = hdlFiles.length;
        const parallelChunk = Math.min(os.cpus().length, 32);
        console.log("use cpu: " + parallelChunk);

        const pools: { id: number, promise: Promise<void>, path: string }[] = [];
        const reportTitle = t('info.progress.build-module-tree');
        progress.report({ message: reportTitle + ` ${1}/${fileNum}`, increment: 0 });

        async function consumePools() {
            for (const p of pools) {
                const increment = Math.floor(p.id / fileNum * 100);
                await p.promise;
                console.log("handle id " + p.id + ' increment: ' + increment);                
                progress?.report({ message: reportTitle + ` ${p.id}/${fileNum}`, increment });
            }
            pools.length = 0;
        }

        for (const path of hdlFiles) {
            count ++;            
            const p = this.doHdlFast(path, 'common');
            pools.push({ id: count, promise: p, path });
            if (pools.length % parallelChunk === 0) {
                // 消费并发池
                await consumePools();
            }
        }

        if (pools.length > 0) {
            await consumePools();
        }
    }

    public async initializeIPsPath(IPsPath: string[], progress: vscode.Progress<IProgress>) {
        let count: number = 0;
        let fileNum = IPsPath.length;

        const parallelChunk = Math.min(os.cpus().length, 32);
        console.log("use cpu: " + parallelChunk);

        const pools: { id: number, promise: Promise<void>, path: string }[] = [];
        
        const reportTitle = t('info.progress.build-ip-module-tree');
        progress.report({ message: reportTitle + ` ${1}/${fileNum}`, increment: 0 });

        async function consumePools() {
            for (const p of pools) {
                const increment = Math.floor(p.id / fileNum * 100);
                await p.promise;
                console.log("handle id " + p.id + ' increment: ' + increment);                
                progress?.report({ message: reportTitle + ` ${p.id}/${fileNum}`, increment });
            }
            pools.length = 0;
        }

        for (const path of IPsPath) {
            count ++;            
            const p = this.doHdlFast(path, 'ip');
            pools.push({ id: count, promise: p, path });
            if (pools.length % parallelChunk === 0) {
                // 消费并发池
                await consumePools();
            }
        }

        if (pools.length > 0) {
            await consumePools();
        }
    }

    public async makeAllInstance() {
        for (const hdlFile of this.getAllHdlFiles()) {
            hdlFile.makeInstance();
        }
    }

    public getTopModulesByType(type: string): HdlModule[] {
        const hardware = opeParam.prjInfo.arch.hardware;
        if (hardware.sim === hardware.src) {
            return this.getAllTopModules();
        }

        switch (type) {
            case common.HdlFileProjectType.Src: return this.getSrcTopModules();
            case common.HdlFileProjectType.Sim: return this.getSimTopModules();
            default: return [];
        }
    }

    public getSrcTopModules(): HdlModule[] {
        const srcTopModules = this.srcTopModules;
        if (!srcTopModules) {
            return [];
        }
        const moduleFiles = [];
        for (const module of srcTopModules) {
            moduleFiles.push(module);
        }
        return moduleFiles;
    }

    public getSimTopModules(): HdlModule[] {
        const simTopModules = this.simTopModules;
        if (!simTopModules) {
            return [];
        }
        const moduleFiles = [];
        for (const module of simTopModules) {
            moduleFiles.push(module);
        }
        return moduleFiles;
    }

    public removeFromHdlFile(hdlFile: HdlFile) {
        this.pathToHdlFiles.delete(hdlFile.path);
    }

    public deleteHdlFile(path: AbsPath) {
        path = hdlPath.toSlash(path);
        const moduleFile = this.getHdlFile(path);
        if (moduleFile) {
            for (const name of moduleFile.getAllModuleNames()) {
                moduleFile.deleteHdlModule(name);
            }
            this.pathToHdlFiles.delete(path);
        }
    }

    /**
     * @description 往 hdlparam 中添加路径中的若干模块
     * @param path 
     */
    public async addHdlFile(path: AbsPath) {
        path = hdlPath.toSlash(path);
        // 解析并构建
        await this.doHdlFast(path, 'common');
        // 初始化
        const moduleFile = this.getHdlFile(path);
        if (!moduleFile) {
            MainOutput.report('error happen when create moduleFile ' + path, {
                level: ReportType.Warn
            });
        } else {
            moduleFile.makeInstance();
            for (const module of moduleFile.getAllHdlModules()) {                
                module.solveUnhandleInstance();
            }
        }
    }

    public updateFast(path: string, fast: common.Fast) {
        const moduleFile = this.getHdlFile(path);
        if (moduleFile === undefined) {
            return;
        }

        // 1. update marco directly
        moduleFile.updateMacro(fast.macro);
        
        // 2. update modules one by one
        const uncheckedModuleNames = new Set<string>();
        for (const name of moduleFile.getAllModuleNames()) {
            uncheckedModuleNames.add(name);
        }
    
        for (const rawHdlModule of fast.content) {
            const moduleName = rawHdlModule.name;            
            if (uncheckedModuleNames.has(moduleName)) {     
                // match the same module, check then
                const originalModule = moduleFile.getHdlModule(moduleName);
                uncheckedModuleNames.delete(moduleName);
                originalModule?.update(rawHdlModule);                
            } else {             
                // no matched, create it
                const newModule = moduleFile.createHdlModule(rawHdlModule);
                newModule.makeNameToInstances();
                newModule.solveUnhandleInstance();
            }
        }

        // 3. delete module not visited yet
        for (const moduleName of uncheckedModuleNames) {
            moduleFile.deleteHdlModule(moduleName);
        }
    }

    public async updateByMonitor(addFiles: AbsPath[], delFiles: AbsPath[]) {
        for (const path of addFiles) {
            await this.addHdlFile(path);
        }
        for (const path of delFiles) {
            this.deleteHdlFile(path);
        }
    }
};

const hdlParam = new HdlParam();

class HdlInstance {
    /**
     * @description 例化的名字
     * 
     * 对于下面的例子，唯一例化 的 name 就是 `u_tool`
     * @example
     * module hello()
     *   tool u_tool();
     * endmodule
     *
     */
    name: string;

    /**
     * @description 例化的模块名
     * 
     * 对于下面的例子，唯一例化 的 type 就是 `tool`
     * @example
     * module hello()
     *   tool u_tool();
     * endmodule
     *
     */
    type: string;

    /**
     * @description 例化的 range
     */
    range: common.Range;                            // range of instance
    
    /**
     * @description 例化的模块的定义路径
     * 
     * 对于下面的例子，唯一例化 的 instModPath 就是 `tool` 这个模块 `module tool` 申明所在的文件的路径
     * @example
     * module hello()
     *   tool u_tool();
     * endmodule
     *
     */
    instModPath: AbsPath | undefined;

    /**
     * @description 用于描述当前例化是如何被引入的，以下是三类枚举
     * - current: 例化对应的模块就在当前文件中
     * - include: 通过 `include
     * - others: 其他
     */
    instModPathStatus: common.InstModPathStatus;

    /**
     * @description 例化 params 部分的 range.
     * 如果是 vhdl，则是 generic map 部分的 range
     */
    instparams: common.InstRange;
    
    /**
     * @description 例化 ports 部分的 range.
     * 如果是 vhdl，则是 port map 部分的 range
     */
    instports: common.InstRange;
    
    /**
     * @description 例化模块例化地点的外层 module
     * 
     * 对于下面的例子， 例化 `u_tool` 的 parentMod 就是 `hello`
     * @example
     * module hello()
     *   tool u_tool();
     * endmodule
     *
     */
    parentMod: HdlModule;

    /**
     * @description 例化模块的定义模块
     * 
     * 对于下面的例子， 例化 `u_tool` 的 `module` 就是 tool
     * @example
     * module hello();
     *   tool u_tool();
     * endmodule
     * 
     * module tool();
     *  ...
     * endmodule
     */
    module: HdlModule | undefined;

    constructor(name: string, 
                type: string,
                instModPath: string | undefined,
                instModPathStatus: common.InstModPathStatus,
                instparams: common.InstRange,
                instports: common.InstRange,
                range: common.Range,
                parentMod: HdlModule
                ) {
        this.name = name;
        this.type = type;
        this.parentMod = parentMod;
        this.instparams = instparams;
        this.instports = instports;
        this.instModPath = instModPath;
        this.instModPathStatus = instModPathStatus;
        this.range = range;
        this.module = undefined;
        
        // solve dependency
        this.locateHdlModule();
    }

    /**
     * @description 定位出当前 instance 的模块是什么，并将模块对应的 HdlModule （普通 HDL、IP、原语） 赋值到 this.module 上
     * 对于存在于结构树中的 HdlModule （普通 HDL & IP），改变这些 HdlModule 的 ref 并修改顶层模块相关的属性
     */
    public locateHdlModule() {
        const instModPath = this.instModPath;
        const instModName = this.type;

        if (instModPath) {
            const module = hdlParam.getHdlModule(instModPath, instModName);
            if (module) {
                this.module = module;
                // 增加当前模块的 global ref
                this.module.addGlobalReferedInstance(this);
                // 如果当前 instance 对应的例化是同源例化，则
                // 增加当前 instance 的 local ref，并从对应类型的顶层模块中剔除
                if (this.isSameSourceInstantiation()) {
                    this.module?.addLocalReferedInstance(this);
                }
            }
        } else {
            doPrimitivesJudgeApi(instModName).then(isPrimitive => {                
                if (isPrimitive) {
                    // 构造 fake hdlfile
                    if (opeParam.prjInfo.toolChain === 'xilinx') {
                        const fakeModule = new HdlModule(
                            XilinxPrimitivesHdlFile, instModName, defaultRange, [], [], []);
                        this.module = fakeModule;
                        // 原语在任何情况下都不是顶层模块
                        hdlParam.deleteTopModule(fakeModule);
                        hdlParam.deleteTopModuleToSource(fakeModule);
                    }
                }
            });
        }
    }


    /**
     * @description 判断当前的 `instance` 对应的例化行为是否为一个同源例化 (SSI, same source instantiation)
     * 
     * - 对于标准项目结构，也就是 src + sim ，如果在 moduleA 中完成了 moduleB 的例化，且 moduleA 和 moduleB 都是 src 文件夹下的，
     * 那么这个例化就是一个同源例化；如果 moduleB 在 sim 下， moduleA 在 src 下，那么当前的例化就是一个非同源例化。
     * - 对于 library 和 IP 这两种类型的 module，对于它们的例化一律视为同源引用。
     * - 同源例化造成的引用为 local ref，非同源例化 + 同源例化造成的引用为 global ref。在模块树下， src 文件夹下的只有 local ref 为空的 module 才是顶层模块
     * 换句话说，非同源例化一定不会造成顶层模块的变化，但是同源例化有可能会。
     * @returns 
     */
    public isSameSourceInstantiation(): boolean {
        const parentModule = this.parentMod;
        const belongModule = this.module;

        // 当前 instance 仍然是 unsolved 状态，返回 false 不参与后续的 ref 计算
        if (!belongModule) {
            return false;
        }
        
        // instance 模块本身是 library / IP / 原语，一律视为 SSI
        if (belongModule.file.projectType === common.HdlFileProjectType.IP ||
            belongModule.file.projectType === common.HdlFileProjectType.Primitive ||
            belongModule.file.projectType === common.HdlFileProjectType.LocalLib ||
            belongModule.file.projectType === common.HdlFileProjectType.RemoteLib
        ) {
            return true;
        }

        // 剩余情况下，一律根据 type 判断
        return parentModule.file.projectType === belongModule.file.projectType;
    }

    /**
     * @description 更新当前的 instance
     * @param newInstance 
     */
    public update(newInstance: common.RawHdlInstance) {        
        this.type = newInstance.type;
        this.range = newInstance.range;
        this.instparams = newInstance.instparams;
        this.instports = newInstance.instports;

        this.instModPath = this.module?.path || '';
        this.updateInstModPathStatus();
    }

    /**
     * @description 用于解决例化的路径引入状态，对于 A 模块，它的两个例化 u_A1 和 u_A2
     * 使用 u_A1 和 u_A2 的模块需要知道 u_A1 是如何被引入的，此时需要调用 u_A1.updateInstModPathStatus() 来更新
     * u_A1 的 instModPathStatus
     */
    public updateInstModPathStatus() {
        const module = this.module;
        if (module) {
            const userModule = this.parentMod;
            if (userModule.path === module.path) {
                this.instModPathStatus = common.InstModPathStatus.Current;
            } else {
                const userIncludePaths = userModule.file.macro.includes.map(
                    include => hdlPath.rel2abs(userModule.path, include.path)
                );
    
                if (userIncludePaths.includes(module.path)) {
                    this.instModPathStatus = common.InstModPathStatus.Include;
                } else {
                    this.instModPathStatus = common.InstModPathStatus.Others;
                }
            }
        } else {
            this.instModPathStatus = common.InstModPathStatus.Unknown;
        }
    }

    public get getDoFastFileType(): DoFastFileType | undefined {
        return this.module?.file.doFastType;
    }
};

class HdlModule {
    file: HdlFile;
    name: string;
    range: common.Range;
    params: common.HdlModuleParam[];
    ports: common.HdlModulePort[];
    public rawInstances: common.RawHdlInstance[] | undefined;
    // TODO: 此处无法采用 instance name 作为主键，是因为 verilog 允许 instance name 同名出现
    private nameToInstances: Map<string, HdlInstance>;
    private unhandleInstances: Set<HdlInstance>;
    private globalRefers: Set<HdlInstance>;
    private localRefers: Set<HdlInstance>;

    constructor(file: HdlFile, 
                name: string, 
                range: common.Range, 
                params: common.HdlModuleParam[], 
                ports: common.HdlModulePort[], 
                instances: common.RawHdlInstance[]) {
        
        this.file = file;
        this.name = name;
        this.range = range;
        this.params = params ? params : [];
        this.ports = ports ? ports : [];
                
        this.rawInstances = instances;
        this.nameToInstances = new Map<string, HdlInstance>();

        // add in hdlParam data structure
        // default both top module in top module and local top module (sim/src)
        hdlParam.addTopModule(this);
        hdlParam.addTopModuleToSource(this);
        hdlParam.addHdlModule(this);

        // log reference (its instance)
        // represents all the instance from this
        this.globalRefers = new Set<HdlInstance>();

        // represents all the instance from this created in the same scope
        // scope: src or sim (lib belongs to src)
        // localRefers subset to refers
        this.localRefers = new Set<HdlInstance>();

        // make unhandleInstances
        this.unhandleInstances = new Set<HdlInstance>();
    }

    public get path() : string {
        return this.file.path;
    }

    public get languageId(): HdlLangID {
        return this.file.languageId;
    }

    public makeInstanceKey(instanceName: string, moduleName: string): string {
        return instanceName + '-' + moduleName;
    }

    public getInstance(name: string, moduleName: string): HdlInstance | undefined {
        return this.nameToInstances.get(this.makeInstanceKey(name, moduleName));
    }

    public getAllInstances(): HdlInstance[] {
        const hdlInstances: HdlInstance[] = [];
        for (const inst of this.nameToInstances.values()) {
            hdlInstances.push(inst);
        }
        return hdlInstances;
    }

    public getInstanceNum(): number {
        return this.nameToInstances.size;
    }

    public createHdlInstance(rawHdlInstance: common.RawHdlInstance): HdlInstance {
        const instModName = rawHdlInstance.type;

        if (this.languageId === HdlLangID.Verilog || this.languageId === HdlLangID.SystemVerilog) {
            const searchResult = this.searchInstModPath(instModName);       
            const hdlInstance = new HdlInstance(rawHdlInstance.name,
                                                rawHdlInstance.type,
                                                searchResult.path,
                                                searchResult.status,
                                                rawHdlInstance.instparams,
                                                rawHdlInstance.instports,
                                                rawHdlInstance.range,
                                                this);
            if (!searchResult.path) {
                hdlParam.addUnhandleInstance(hdlInstance);
                this.addUnhandleInstance(hdlInstance);
            }
            if (this.nameToInstances) {
                const key = this.makeInstanceKey(rawHdlInstance.name, rawHdlInstance.type);
                this.nameToInstances.set(key, hdlInstance);
            }
            return hdlInstance; 
        } else if (this.languageId === HdlLangID.Vhdl) {
            const hdlInstance = new HdlInstance(rawHdlInstance.name,
                                                rawHdlInstance.type,
                                                this.path,
                                                common.InstModPathStatus.Current,
                                                rawHdlInstance.instparams,
                                                rawHdlInstance.instports,
                                                rawHdlInstance.range,
                                                this);
            hdlInstance.module = this;
            if (this.nameToInstances) {
                const key = this.makeInstanceKey(rawHdlInstance.name, rawHdlInstance.type);
                this.nameToInstances.set(key, hdlInstance);
            }           
            return hdlInstance;
        } else {
            vscode.window.showErrorMessage(`Unknown Language :${this.languageId} exist in our core program`);
            const hdlInstance = new HdlInstance(rawHdlInstance.name,
                                                rawHdlInstance.type,
                                                this.path,
                                                common.InstModPathStatus.Unknown,
                                                rawHdlInstance.instparams,
                                                this.ports[0].range,
                                                rawHdlInstance.range,
                                                this);
            
            return hdlInstance;
        }
    }

    public makeNameToInstances() {
        if (this.rawInstances !== undefined) {            
            this.nameToInstances.clear();

            for (const inst of this.rawInstances) {
                const instance = this.createHdlInstance(inst);
            }
            // this.rawInstances = undefined;
        } else {
            MainOutput.report('call makeNameToInstances but this.rawInstances is undefined', {
                level: ReportType.Warn
            });
        }
    }

    public deleteInstanceByName(instanceName: string, moduleName: string) {
        const inst = this.getInstance(instanceName, moduleName);
        this.deleteInstance(inst);
    }

    public deleteInstance(inst?: HdlInstance) {
        if (inst) {
            this.deleteUnhandleInstance(inst);
            hdlParam.deleteUnhandleInstance(inst);
            if (this.nameToInstances) {
                const key = this.makeInstanceKey(inst.name, inst.type);
                this.nameToInstances.delete(key);
            }
            // delete reference from instance's instMod
            const instMod = inst.module;
            if (instMod) {
                instMod.deleteGlobalReferedInstance(inst);
                if (inst.isSameSourceInstantiation()) {
                    instMod.deleteLocalReferedInstance(inst);
                }
            }
        }
    }

    /**
     * @description 计算出当前 instance 和父组件的 包含关系
     * @param instModName instance 的名字
     * @returns InstModPathSearchResult
     */
    private searchInstModPath(instModName: string): common.InstModPathSearchResult {        
        // search path of instance
        // priority:  "current file" -> "included files" -> "other hdls in the project"

        // prepare for "other hdls in the project"
        const excludeFile = new Set([this.file]);

        // search all the modules in the current file
        for (const name of this.file.getAllModuleNames()) {
            if (instModName === name) {
                return {path : this.path, status: common.InstModPathStatus.Current};      
            }
        }


        // search included file
        for (const include of this.file.macro.includes) {
            const absIncludePath = hdlPath.rel2abs(this.path, include.path);
            const includeFile = hdlParam.getHdlFile(absIncludePath);
            
            if (includeFile) {
                excludeFile.add(includeFile);
                if (includeFile.hasHdlModule(instModName)) {
                    return {path: includeFile.path, status: common.InstModPathStatus.Include};
                }
            }
        }

        // search other files in the project
        for (const hdlFile of hdlParam.getAllHdlFiles()) {
            if (!excludeFile.has(hdlFile) && hdlFile.hasHdlModule(instModName)) {
                return {
                    path: hdlFile.path,
                    status: common.InstModPathStatus.Others
                };
            }
        }

        return {path: '', status: common.InstModPathStatus.Unknown};
    }

    public addUnhandleInstance(inst: HdlInstance) {
        this.unhandleInstances.add(inst);
    }

    public deleteUnhandleInstance(inst: HdlInstance) {
        this.unhandleInstances.delete(inst);
    }

    public getAllGlobalRefers(): Set<HdlInstance> {
        return this.globalRefers;
    }

    public getAllLocalRefers(): Set<HdlInstance> {
        return this.localRefers;
    }

    public addGlobalReferedInstance(inst: HdlInstance) {
        const globalRefers = this.globalRefers;
        globalRefers.add(inst);
        // it is refered in global scope, so delete this from top module
        if (globalRefers.size > 0) {
            hdlParam.deleteTopModule(this);
        }
    }

    public deleteGlobalReferedInstance(inst: HdlInstance) {
        const globalRefers = this.globalRefers;
        globalRefers.delete(inst);
        if (globalRefers.size === 0) {
            hdlParam.addTopModule(this);
        }
    }

    public addLocalReferedInstance(inst: HdlInstance) {
        const localRefers = this.localRefers;
        localRefers.add(inst);
        // it is refered in local scope, so delete this from top module
        if (localRefers.size > 0) {
            hdlParam.deleteTopModuleToSource(this);
        }
    }

    public deleteLocalReferedInstance(inst: HdlInstance) {
        const localRefers = this.localRefers;
        localRefers.delete(inst);
        if (localRefers.size === 0) {
            hdlParam.addTopModuleToSource(this);
        }
    }

    /**
     * @description 从全局寻找这个 module 的例化，并尝试修改它的状态
     */
    public solveUnhandleInstance() {
        const instances = hdlParam.getUnhandleInstancesByModuleName(this.name);

        for (const instance of instances) {
            const belongScopeModule = instance.parentMod;
            // 先从 unsolved 堆中删除当前的 instance
            hdlParam.deleteUnhandleInstance(instance);
            belongScopeModule.deleteUnhandleInstance(instance);

            // 解决
            instance.instModPath = this.path;
            instance.updateInstModPathStatus();

            // 找寻这个 instance 对应的真正的 module（也有可能是原语）
            // 并将这个 instance 加入这个 module 的计数器中
            instance.locateHdlModule();
        }
    }

    public update(newModule: common.RawHdlModule) {
        this.ports = newModule.ports;
        this.params = newModule.params;
        this.range = newModule.range;        
        // compare and make change to instance
        const uncheckedInstanceNames = new Map<string, HdlInstance>();
        for (const inst of this.getAllInstances()) {
            const key = this.makeInstanceKey(inst.name, inst.type);
            uncheckedInstanceNames.set(key, inst);
        }

        for (const newInst of newModule.instances) {
            const newInstKey = this.makeInstanceKey(newInst.name, newInst.type);
            if (uncheckedInstanceNames.has(newInstKey)) {     
                // match exist instance, compare and update
                const originalInstance = this.getInstance(newInst.name, newInst.type);
                originalInstance?.update(newInst);
                uncheckedInstanceNames.delete(newInstKey);
            } else {        
                // unknown instance, create it
                this.createHdlInstance(newInst);
            }
        }
        // delete Instance that not visited
        for (const inst of uncheckedInstanceNames.values()) {
            this.deleteInstanceByName(inst.name, inst.type);
        }
    }
};

export class HdlFile {
    // 标准化的文件绝对路径
    public path: string;
    // 对应的 HDL 语言 ID
    public languageId: HdlLangID;
    // 文件的项目类型
    public projectType: common.HdlFileProjectType;
    // 文件的解析模式
    public doFastType: DoFastFileType;
    // 当前文件的宏
    public macro: common.Macro;
    // 维护当前文件内部 module 的 map
    private readonly nameToModule: Map<string, HdlModule>;

    constructor(path: string, 
                languageId: HdlLangID, 
                macro: common.Macro, 
                modules: common.RawHdlModule[],
                projectType: common.HdlFileProjectType,
                doFastType: DoFastFileType) {

        this.path = path;
        this.languageId = languageId;
        this.macro = macro;
        this.projectType = projectType;
        this.doFastType = doFastType;

        // add to global hdlParam
        hdlParam.setHdlFile(this);

        // make nameToModule
        this.nameToModule = new Map<string, HdlModule>();   
        for (const rawHdlModule of modules) {
            this.createHdlModule(rawHdlModule);
        }
    }

    public createHdlModule(rawHdlModule: common.RawHdlModule): HdlModule {
        const module: HdlModule = new HdlModule(this,
                                                rawHdlModule.name,
                                                rawHdlModule.range,
                                                rawHdlModule.params,
                                                rawHdlModule.ports,
                                                rawHdlModule.instances);
        this.nameToModule.set(rawHdlModule.name, module);
        return module;
    }

    public hasHdlModule(name: string): boolean {
        return this.nameToModule.has(name);
    }

    public getHdlModule(name: string): HdlModule | undefined {
        return this.nameToModule.get(name);
    }

    public getAllModuleNames(): string[] {
        const names: string[] = [];
        for (const [name, _] of this.nameToModule) {
            names.push(name);
        }
        return names;
    }

    public getAllHdlModules(): HdlModule[] {
        const hdlModules: HdlModule[] = [];
        for (const hdlModule of this.nameToModule.values()) {
            hdlModules.push(hdlModule);
        }
        return hdlModules;
    }

    public deleteHdlModule(name: string) {
        const hdlModule = this.getHdlModule(name);
        if (hdlModule) {
            // delete child reference in the module which use this
            for (const childInst of hdlModule.getAllGlobalRefers()) {
                const userModule = childInst.parentMod;
                childInst.module = undefined;
                childInst.instModPath = undefined;
                childInst.instModPathStatus = common.InstModPathStatus.Unknown;

                hdlParam.addUnhandleInstance(childInst);
                userModule.addUnhandleInstance(childInst);
            }

            // delete all the instance in the module
            for (const inst of hdlModule.getAllInstances()) {
                hdlModule.deleteInstance(inst);
            }

            // delete any variables containing module
            hdlParam.deleteTopModule(hdlModule);
            hdlParam.deleteTopModuleToSource(hdlModule);
            hdlParam.modules.delete(hdlModule);
            this.nameToModule.delete(hdlModule.name);
        }
    }
    
    public makeInstance() {
        for (const module of this.getAllHdlModules()) {            
            module.makeNameToInstances();
        }
    }
    
    public updateMacro(macro: common.Macro) {
        this.macro = macro;
    }
}

export const XilinxPrimitivesHdlFile = new HdlFile(
    'xilinx-primitives',
    HdlLangID.Verilog,
    defaultMacro,
    [],
    common.HdlFileProjectType.Primitive,
    'primitives');


export {
    hdlParam,
    HdlModule,
    HdlInstance,
    hdlFile
};