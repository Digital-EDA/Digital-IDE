import * as vscode from 'vscode';
import * as os from 'os';

import { AbsPath, IProgress, opeParam } from '../global';
import { HdlLangID } from '../global/enum';
import { MainOutput, ReportType } from '../global/outputChannel';

import * as common from './common';
import { hdlFile, hdlPath } from '../hdlFs';
import { HdlSymbol } from './util';
import { Fast, vhdlFast } from '../../resources/hdlParser';

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
        await this.initHdlFiles([path]);
        const hdlFile = this.getHdlFile(path);
        if (!hdlFile) {
            MainOutput.report('error happen when we attempt to add file by path: ' + path, ReportType.Error);
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
        switch (hdlModule.file.type) {
            case common.HdlFileType.Src: return this.srcTopModules;
            case common.HdlFileType.Sim: return this.simTopModules;
            case common.HdlFileType.LocalLib: return this.srcTopModules;
            case common.HdlFileType.RemoteLib: return this.srcTopModules;
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

    public deleteTopModuleToSource(hdlModule: HdlModule) {
        const topModuleSource = this.selectTopModuleSourceByFileType(hdlModule);
        topModuleSource.delete(hdlModule);
    }

    public getAllDependences(path: AbsPath, name: string): common.HdlDependence | undefined {        
        const module = this.getHdlModule(path, name);
        if (!module) {
            return undefined;
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

    public getUnhandleInstanceByType(typeName: string): HdlInstance | undefined {
        for (const inst of this.unhandleInstances) {
            if (inst.type === typeName) {
                return inst;
            }
        }
        return undefined;
    }

    public addUnhandleInstance(inst: HdlInstance) {
        this.unhandleInstances.add(inst);
    }

    public deleteUnhandleInstance(inst: HdlInstance) {
        this.unhandleInstances.delete(inst);
    }

    /**
     * vlog -> HdlLangID.Verilog
     * svlog -> HdlLangID.SystemVerilog
     * vhdl -> HdlLangID.Vhdl
     * @param langID 
     */
    private alignLanguageId(langID: string) : HdlLangID {
        switch (langID) {
            case 'vhdl': return HdlLangID.Vhdl;
            case 'vlog': return HdlLangID.Verilog;
            case 'svlog': return HdlLangID.SystemVerilog;
            default: return HdlLangID.Unknown;
        }
    }

    private async doHdlFast(path: AbsPath) {
        try {
            const fast = await HdlSymbol.fast(path);
            if (fast) {
                const languageId = hdlFile.getLanguageId(path);
                new HdlFile(path,
                            languageId,
                            fast.macro,
                            fast.content);
            }
        } catch (error) {
            MainOutput.report('Error happen when parse ' + path, ReportType.Error);
            MainOutput.report('Reason: ' + error, ReportType.Error);
        }
    }

    public async initHdlFiles(hdlFiles: AbsPath[], progress?: vscode.Progress<IProgress>) {
        const { t } = vscode.l10n;        
        let count: number = 0;
        let fileNum = hdlFiles.length;

        // TODO: 找出最合理的核心数
        const parallelChunk = Math.min(os.cpus().length, 32);
        console.log("use cpu: " + parallelChunk);
        

        const pools: { id: number, promise: Promise<void>, path: string }[] = [];
        const reportTitle = t('progress.build-module-tree');

        progress?.report({ message: reportTitle + ` ${1}/${fileNum}`, increment: 0 });

        // for (const path of hdlFiles) {
        //     count ++;
        //     console.log('send request: ' + path);
            
        //     await this.doHdlFast(path);
        //     const increment = Math.floor(count / fileNum * 100);
        //     progress?.report({ message: reportTitle + ` ${count}/${fileNum}`, increment });
        // }

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
            console.log('send request: ' + path);
            
            const p = this.doHdlFast(path);
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

    public async initialize(hdlFiles: AbsPath[], progress: vscode.Progress<IProgress>) {        
        await this.initHdlFiles(hdlFiles, progress);
        
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
            case common.HdlFileType.Src: return this.getSrcTopModules();
            case common.HdlFileType.Sim: return this.getSimTopModules();
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

    public async addHdlFile(path: AbsPath) {
        path = hdlPath.toSlash(path);
        await this.initHdlFiles([path]);
        const moduleFile = this.getHdlFile(path);
        if (!moduleFile) {
            MainOutput.report('error happen when create moduleFile ' + path, ReportType.Warn);
        } else {
            moduleFile.makeInstance();
            for (const module of moduleFile.getAllHdlModules()) {
                module.solveUnhandleInstance();
            }
        }
    }

    public updateFast(path: string, fast: Fast) {
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
};

const hdlParam = new HdlParam();

class HdlInstance {
    name: string;                                   // name of the instance
    type: string;                                   // type
    range: common.Range;                            // range of instance
    instModPath: AbsPath | undefined;               // path of the definition
    instModPathStatus: common.InstModPathStatus;    // status of the instance (current, include, others)
    instparams: common.InstRange;                   // range of params
    instports: common.InstRange;                    // range of ports
    parentMod: HdlModule;                           // HdlModule that the instance serves
    module: HdlModule | undefined;                  // module

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

    public locateHdlModule() {
        const instModPath = this.instModPath;
        const instModName = this.type;

        if (instModPath) {
            this.module = hdlParam.getHdlModule(instModPath, instModName);
            
            // add refer for module 
            this.module?.addGlobalReferedInstance(this);
            // if module and parent module share the same source (e.g both in src folder)
            if (this.isSameSource()) {
                this.module?.addLocalReferedInstance(this);
            }
        }
    }

    /**
     * judge if the instance is a cross source reference
     * e.g. this.module is from src, this.parentMod is from sim, then
     * isSameSource will return false, meaning that the instance is a cross source reference
     * 
     * a cross source reference won't affect the top module reference of this.module,
     * meaning that a top module in one source can have its instance in other source
     */
    public isSameSource(): boolean {
        const parentMod = this.parentMod;
        const instMod = this.module;
        if (instMod) {
            return parentMod.file.type === instMod.file.type;
        }
        return false;
    }

    /**
     * @description update Instance of each time
     * @param newInstance 
     */
    public update(newInstance: common.RawHdlInstance) {        
        this.type = newInstance.type;
        this.range = newInstance.range;
        this.instparams = newInstance.instparams;
        this.instports = newInstance.instports;

        this.instModPath = this.parentMod.path;
        this.instModPathStatus = this.parentMod.solveInstModPathStatus();
    }
};

class HdlModule {
    file: HdlFile;
    name: string;
    range: common.Range;
    params: common.HdlModuleParam[];
    ports: common.HdlModulePort[];
    private rawInstances: common.RawHdlInstance[] | undefined;
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

    public getInstance(name: string): HdlInstance | undefined {
        return this.nameToInstances.get(name);
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
                this.nameToInstances.set(rawHdlInstance.name, hdlInstance);
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
                this.nameToInstances.set(rawHdlInstance.name, hdlInstance);
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
                this.createHdlInstance(inst);
            }
            // this.rawInstances = undefined;
        } else {
            MainOutput.report('call makeNameToInstances but this.rawInstances is undefined', 
                              ReportType.Warn);
        }
    }

    public deleteInstanceByName(name: string) {
        const inst = this.getInstance(name);
        this.deleteInstance(inst);
    }

    public deleteInstance(inst?: HdlInstance) {
        if (inst) {
            this.deleteUnhandleInstance(inst);
            hdlParam.deleteUnhandleInstance(inst);
            if (this.nameToInstances) {
                this.nameToInstances.delete(inst.name);
            }
            // delete reference from instance's instMod
            const instMod = inst.module;
            if (instMod) {
                instMod.deleteGlobalReferedInstance(inst);
                if (inst.isSameSource()) {
                    instMod.deleteLocalReferedInstance(inst);
                }
            }
        }
    }

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
                return {path: hdlFile.path, status: common.InstModPathStatus.Others};
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

    public solveInstModPathStatus(): common.InstModPathStatus {
        const inst = hdlParam.getUnhandleInstanceByType(this.name);
        if (!inst) {
            return common.InstModPathStatus.Unknown;
        }
        const userModule = inst.parentMod;
        if (userModule.path === this.path) {
            return common.InstModPathStatus.Current;
        } else {
            const userIncludePaths = userModule.file.macro.includes.map(
                include => hdlPath.rel2abs(userModule.path, include.path));

            if (userIncludePaths.includes(this.path)) {
                return common.InstModPathStatus.Include;
            } else {
                return common.InstModPathStatus.Others;
            }
        }
    }

    public solveUnhandleInstance() {
        const inst = hdlParam.getUnhandleInstanceByType(this.name);

        if (inst) {
            const userModule = inst.parentMod;
            // match a inst with the same type name of the module
            // remove from unhandle list
            hdlParam.deleteUnhandleInstance(inst);
            userModule.deleteUnhandleInstance(inst);

            // assign instModPath
            inst.instModPath = this.path;

            // judge the type of instModPathStatus
            inst.instModPathStatus = this.solveInstModPathStatus();
            
            // assign module in the instance
            inst.locateHdlModule();            
        }
    }

    public update(newModule: common.RawHdlModule) {
        this.ports = newModule.ports;
        this.params = newModule.params;
        this.range = newModule.range;        
        // compare and make change to instance
        const uncheckedInstanceNames = new Set<string>();
        for (const inst of this.getAllInstances()) {
            uncheckedInstanceNames.add(inst.name);
        }

        for (const newInst of newModule.instances) {
            if (uncheckedInstanceNames.has(newInst.name)) {     
                // match exist instance, compare and update
                const originalInstance = this.getInstance(newInst.name);
                originalInstance?.update(newInst);
                uncheckedInstanceNames.delete(newInst.name);
            } else {        
                // unknown instance, create it
                this.createHdlInstance(newInst);
            }
        }
        // delete Instance that not visited
        for (const instName of uncheckedInstanceNames) {
            this.deleteInstanceByName(instName);
        }
    }
};

class HdlFile {
    public path: string;
    public languageId: HdlLangID;
    public type: common.HdlFileType;
    public macro: common.Macro;
    private readonly nameToModule: Map<string, HdlModule>;

    constructor(path: string, 
                languageId: HdlLangID, 
                macro: common.Macro, 
                modules: common.RawHdlModule[]) {

        this.path = path;
        this.languageId = languageId;
        this.macro = macro;
        this.type = hdlFile.getHdlFileType(path);

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


export {
    hdlParam,
    HdlModule,
    HdlInstance,
    hdlFile
};