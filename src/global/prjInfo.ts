/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as fspath from 'path';


import { ToolChainType, LibraryState, XilinxIP,
         validToolChainType, validXilinxIP, validLibraryState } from './enum';
import { PrjInfoSchema } from './propertySchema';
import assert = require('assert');
import * as hdlPath from '../hdlFs/path';


type AbsPath = string;
type RelPath = string;
type Path = AbsPath | RelPath;

type SimPath = {sim: Path};
type SrcPath = {src: Path};
type DataPath = {data: Path};

type OptionalPickType<T> = {[P in keyof T]?: T[P]};
type PrjInfoMeta = Record<keyof PrjInfoSchema, any>;
type RawPrjInfoMeta = OptionalPickType<PrjInfoMeta>;

const PrjInfoDefaults: PrjInfoMeta = {
    get toolChain() {
        return ToolChainType.Xilinx;
    },

    get prjName() {
        return {
            PL: 'template',
            PS: 'template'
        };
    },

    get IP_REPO() {
        return [];
    },

    get soc() {
        return {
            core: '',
            bd: '',
            os: '',
            app: ''
        };
    }, 

    get enableShowLog() {
        return false;
    },

    get device() {
        return 'none';
    },
    
    get arch() {
        return {
            prjPath: '.',
            hardware: {
                src: '.',
                sim: '.',
                data: '.'
            },
            software: {
                src: '.',
                data: '.'
            }
        };
    },

    get library() {
        return {
            state: LibraryState.Remote,
            hardware: {
                common: [],
                custom: []
            }  
        };
    },

    get iverilogCompileOptions() {
        return {
            standard: "2012",
            includes: []
        };
    }
};

interface PrjName {
    PL: RelPath
    PS: RelPath
};

interface Arch {
    prjPath: AbsPath
    hardware: SrcPath & SimPath & DataPath
    software: SrcPath & DataPath
};

interface Soc {
    core: string
    bd: string
    os: string
    app: string
};

interface Library {
    state: LibraryState,
    hardware: {
        common: RelPath[], 
        custom: (RelPath | AbsPath)[]
    }
}

interface IverilogCompileOptions {
    standard: string,
    includes: Path[]
}

interface RawPrjInfo extends RawPrjInfoMeta {
    toolChain?: ToolChainType
    prjName?: PrjName
    IP_REPO?: XilinxIP[]
    soc?: Soc
    enableShowLog?: boolean
    device?: string
    arch?: Arch
    library?: Library
};


function toSlash(path: Path): Path {
    return path.replace(/\\/g,"\/");
}

function resolve(...paths: Path[]): AbsPath {
    const absPath = fspath.resolve(...paths);
    return toSlash(absPath);
}

function join(...paths: string[]): AbsPath {
    const joinedPath = fspath.join(...paths);
    return toSlash(joinedPath);
}


class PrjInfo implements PrjInfoMeta {
    private _extensionPath: AbsPath = '';
    private _workspacePath: AbsPath = '';

    // toolChain is the tool chain used in the project
    // which is supposed to support xilinx, intel, custom
    private _toolChain: ToolChainType = PrjInfoDefaults.toolChain;

    // project name, include pl and ps
    private readonly _prjName: PrjName = PrjInfoDefaults.prjName;

    private _IP_REPO: XilinxIP[] = PrjInfoDefaults.IP_REPO;
    
    private readonly _soc: Soc = PrjInfoDefaults.soc;

    private _enableShowLog: boolean = PrjInfoDefaults.enableShowLog;
    
    private _device: string = PrjInfoDefaults.device;

    // structure of the project, including path of source of hardware design, testBench
    private readonly _arch: Arch = PrjInfoDefaults.arch;

    // library to manage
    private readonly _library: Library = PrjInfoDefaults.library;

    // compile for iverilog
    private readonly _iverilogCompileOptions: IverilogCompileOptions = PrjInfoDefaults.iverilogCompileOptions; 

    public get toolChain(): ToolChainType {
        return this._toolChain;
    }

    public get prjName(): PrjName {
        return this._prjName;
    }

    public get arch(): Arch {
        return this._arch;
    }

    public get library(): Library {
        return this._library;
    }

    public get IP_REPO() : XilinxIP[] {
        return this._IP_REPO;
    }

    public get soc(): Soc {
        return this._soc;
    }

    public get enableShowLog(): boolean {
        return this._enableShowLog;
    }

    public get device(): string {
        return this._device;
    }

    public get INSIDE_BOOT_TYPE(): string {
        return 'microphase';
    }

    public get iverilogCompileOptions(): IverilogCompileOptions {
        return this._iverilogCompileOptions;
    }

    /**
     * replace token like ${workspace} in path
     * @param path 
     */
    private replacePathToken(path: AbsPath): AbsPath {
        const workspacePath = this._workspacePath;
        assert(workspacePath);
        this.setDefaultValue(this.prjName, 'PL', 'template');
        this.setDefaultValue(this.prjName, 'PS', 'template');
        const plname = this.prjName.PL;
        const psname = this.prjName.PS;

        // TODO : packaging the replacer
        return path.replace(/\$\{workspace\}/g, workspacePath)
                   .replace(/\$\{plname\}/g, plname)
                   .replace(/\$\{psname\}/g, psname);
    }

    /**
     * uniform a absolute path
     * @param path 
     */
    public uniformisePath(path: AbsPath): AbsPath {
        const slashPath = toSlash(path);
        const replacedPath = this.replacePathToken(slashPath);
        return replacedPath;
    }

    /**
     * resolve path with workspacePath as root
     * @param path 
     * @param check if true, check the existence of path
     * @param root root of path, root and path will be joined
     * @returns 
     */
    private resolvePath(path: Path, check: boolean = false, root?: AbsPath): AbsPath | undefined {
        let uniformPath = '';
        if (fspath.isAbsolute(path)) {
            uniformPath = path;
        } else {
            const rootPath = root ? root : this._workspacePath;
            uniformPath = fspath.resolve(rootPath, path);
        }
        
        uniformPath = this.uniformisePath(uniformPath);

        if (check) {
            if (fs.existsSync(uniformPath)) {
                return uniformPath;
            } else {
                vscode.window.showErrorMessage('path ' + uniformPath + ' not exist!');
                return undefined;
            }
        } else {
            return uniformPath;
        }
    }

    public updateToolChain(toolChain?: ToolChainType) {
        if (toolChain) {
            if (!validToolChainType(toolChain)) {
                vscode.window.showErrorMessage('expect toolChain to be "xilinx", "intel", "custom"');
                return;
            }
            this._toolChain = toolChain;
        }
    }

    public updatePathWisely<T extends string>(obj: Record<T, AbsPath | AbsPath[]>, 
                                              attr: T, 
                                              path?: Path | Path[],
                                              root?: AbsPath,
                                              defaultPath: Path | Path[] = '') {                
        if (path) {
            if (path instanceof Array) {
                const actualPaths = [];
                for (const p of path) {
                    const actualPath = this.resolvePath(p, true, root);
                    if (actualPath) {
                        actualPaths.push(actualPath);
                    }
                }
                obj[attr] = actualPaths;
            } else {
                const actualPath = this.resolvePath(path, true, root);
                if (actualPath) {
                    obj[attr] = actualPath;                    
                }   
            }
        } else {
            obj[attr] = defaultPath;
        }
    }
    
    public updatePrjName(prjName?: PrjName) {
        if (prjName) {
            if (prjName.PL) {
                this._prjName.PL = prjName.PL;
            }
            if (prjName.PS) {
                this._prjName.PS = prjName.PS;
            }
        }
    }

    public updateIP_REPO(IP_REPO?: XilinxIP[]) {
        if (IP_REPO) {
            if (IP_REPO instanceof Array) {
                const invalidIPs = IP_REPO.filter(ip => !validXilinxIP(ip));
                if (invalidIPs.length > 0) {
                    vscode.window.showErrorMessage('detect invalid IPs:' + invalidIPs);
                } else {
                    this._IP_REPO = IP_REPO;
                }
            } else {
                vscode.window.showErrorMessage('expect IP_REPO to be list');
            }
        }
    }

    public updateSoc(soc?: Soc) {
        if (soc) {
            if (soc.core) {
                this._soc.core = soc.core;
            }
            if (soc.bd) {
                this._soc.bd = soc.bd;
            }
            if (soc.os) {
                this._soc.os = soc.os;
            }
            if (soc.app) {
                this._soc.app = soc.app;
            }
        }
    }

    public updateEnableShowLog(enableShowLog?: boolean) {
        if (enableShowLog) {
            this._enableShowLog = enableShowLog;
        }
    }

    public updateDevice(device?: string) {
        if (device) {
            this._device = device;
        }
    }


    /**
     * assign defaultValue to obj[attr] if boolean of obj[attr] is false or 'none'
     * @param obj 
     * @param attr 
     * @param defaultValue 
     */
    private setDefaultValue<T extends string, K>(obj: Record<T, K>, 
                                                 attr: T, 
                                                 defaultValue: K) {
        const value: K = obj[attr];        
        let isNull = !Boolean(value);
        if (typeof value === 'string') {
            isNull ||= value === 'none';
        }
        if (isNull) {
            obj[attr] = defaultValue;
        }
    }

    private checkDirExist(dir: AbsPath) {
        if (dir === '') {
            return;
        }
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
    }

    public updateArch(arch?: Arch) {
        const workspacePath = this._workspacePath;
        if (arch) {
            this.updatePathWisely(this.arch, 'prjPath', arch.prjPath);            
            if (arch.hardware) {
                this.updatePathWisely(this.arch.hardware, 'src', arch.hardware.src);
                this.updatePathWisely(this.arch.hardware, 'sim', arch.hardware.sim);
                this.updatePathWisely(this.arch.hardware, 'data', arch.hardware.data);
            }

            if (arch.software) {
                this.updatePathWisely(this.arch.software, 'src', arch.software.src);
                this.updatePathWisely(this.arch.software, 'data', arch.software.data);
            }
        } else {
            let hardwarePath: AbsPath = join(workspacePath, 'user');
            let softwarePath: AbsPath = join(workspacePath, 'user', 'Software');
            const socCore = this._soc.core;
            if (socCore && socCore !== 'none') {
                hardwarePath = join(hardwarePath, 'Hardware');
                this.arch.software.src = join(softwarePath, 'src');
                this.arch.software.data = join(softwarePath, 'data');
            }

            this.arch.prjPath = join(workspacePath, 'prj');
            this.arch.hardware.src = join(hardwarePath, 'src');
            this.arch.hardware.sim = join(hardwarePath, 'sim');
            this.arch.hardware.data = join(hardwarePath, 'data');
        }
        
        // if path is '', set as workspace
        this.setDefaultValue(this.arch.hardware, 'src', workspacePath);
        this.setDefaultValue(this.arch.hardware, 'sim', this.arch.hardware.src);
        this.setDefaultValue(this.arch.hardware, 'data', workspacePath);
        this.setDefaultValue(this.arch.software, 'src', workspacePath);
        this.setDefaultValue(this.arch.software, 'data', workspacePath);
        this.setDefaultValue(this.arch, 'prjPath', workspacePath);
    }

    public checkArchDirExist() {
        this.checkDirExist(this.arch.hardware.sim);
        this.checkDirExist(this.arch.hardware.src);
        this.checkDirExist(this.arch.hardware.data);
        if (this.soc.core !== 'none') {
            this.checkDirExist(this.arch.software.src);
            this.checkDirExist(this.arch.software.data);
        }
        this.checkDirExist(this.arch.prjPath);
    }

    public updateLibrary(library?: Library) {        
        if (library) {
            if (library.state) {
                if (!validLibraryState(library.state)) {
                    vscode.window.showErrorMessage('expect library.state to be "local", "remote"');
                    this._library.state = LibraryState.Unknown;
                } else {
                    this._library.state = library.state;
                }
            } else {
                this._library.state = library.state;
            }
            if (library.hardware) {
                const commonPath = this.libCommonPath;
                const customPath = this.libCustomPath;
                this.library.hardware.common = library.hardware.common ? library.hardware.common : [];
                // this.updatePathWisely(this.library.hardware, 'common', library.hardware.common, commonPath, []);
                this.updatePathWisely(this.library.hardware, 'custom', library.hardware.custom, customPath, []);
                
            } else {
                this._library.hardware = library.hardware;
            }
        } else {
            this._library.hardware = PrjInfoDefaults.library.hardware;
            this._library.state = PrjInfoDefaults.library.state;
        }
    }

    public updateIverilogCompileOptions(iverilogCompileOptions?: IverilogCompileOptions) {        
        if (iverilogCompileOptions) {
            if (iverilogCompileOptions.standard) {
                this._iverilogCompileOptions.standard = iverilogCompileOptions.standard;
            }
            if (iverilogCompileOptions.includes && iverilogCompileOptions.includes instanceof Array<Path>) {
                this._iverilogCompileOptions.includes = [];
                for (const includePath of iverilogCompileOptions.includes) {
                    const realIncludePath = includePath.replace(/\$\{workspace\}/g, this._workspacePath);
                    this._iverilogCompileOptions.includes.push(realIncludePath);
                }
            }
        }
    }

    public appendLibraryCommonPath(relPath: RelPath) {
        this._library.hardware.common.push(relPath);
    }

    public appendLibraryCustomPath(relPath: RelPath) {
        this._library.hardware.custom.push(relPath);
    }

    public getLibraryCommonPaths(absolute: boolean = true, state?: LibraryState): Path[] {
        const targetState = state ? state : this._library.state;
        const localLibPath = hdlPath.join(this.hardwareSrcPath, 'lib');
        const remoteLibPath = this.libCommonPath;
        const targetLibPath = (targetState === LibraryState.Local) ? localLibPath : remoteLibPath;
        const commonFolder = hdlPath.join(targetLibPath, 'Empty');
        
        if (absolute) {            
            const absPaths = this._library.hardware.common.map<Path>(relPath => hdlPath.rel2abs(commonFolder, relPath));            
            return absPaths;
        }
        return this._library.hardware.common;
    }

    public getLibraryCustomPaths(absolute: boolean = true): Path[] {
        const libCustomPath = this.libCustomPath;
        if (libCustomPath === '') {
            return [];
        }

        if (absolute) {
            const configFolder = hdlPath.join(libCustomPath, 'Empty');
            return this._library.hardware.custom.map<Path>(relPath => hdlPath.rel2abs(configFolder, relPath));
        }
        return this._library.hardware.custom;
    }

    /**
     * merge the input uncomplete prjInfo into this
     * cover the value that exist in rawPrjInfo recursively
     * reserve the value that not covered in rawPrjInfo
     * @param rawPrjInfo 
     */
    public merge(rawPrjInfo: RawPrjInfo) {        
        this.updateToolChain(rawPrjInfo.toolChain);
        this.updatePrjName(rawPrjInfo.prjName);
        this.updateIP_REPO(rawPrjInfo.IP_REPO);
        this.updateSoc(rawPrjInfo.soc);
        this.updateEnableShowLog(rawPrjInfo.enableShowLog);
        this.updateDevice(rawPrjInfo.device);
        this.updateArch(rawPrjInfo.arch);
        this.updateLibrary(rawPrjInfo.library);
        this.updateIverilogCompileOptions(rawPrjInfo.iverilogCompileOptions);
    }

    /**
     * config init path in prjInfo
     * @param extensionPath 
     * @param workspacePath 
     */
    public initContextPath(extensionPath: AbsPath, workspacePath: AbsPath) {
        this._extensionPath = toSlash(extensionPath);
        this._workspacePath = toSlash(workspacePath);
    }

    public get libCommonPath(): AbsPath {
        const libPath = join(this._extensionPath, 'lib', 'common');
        if (!fs.existsSync(libPath)) {
            vscode.window.showErrorMessage('common lib path: "' + libPath + '"  in extension is invalid, maybe extension has been corrupted, reinstall the extension');
        }
        return libPath;
    }

    public get libCustomPath(): AbsPath {
        const libPath = vscode.workspace.getConfiguration().get('prj.lib.custom.path', this._workspacePath);
        if (!fs.existsSync(libPath)) {                      
            return '';
        }
        return libPath;
    }

    public get hardwareSimPath(): AbsPath {
        const simPath = this._arch.hardware.sim;  
        if (fspath.isAbsolute(simPath)) {
            return simPath;
        }
        const workspace = this._workspacePath;
        return hdlPath.join(workspace, simPath);
    }

    public get hardwareSrcPath(): AbsPath {
        const srcPath = this._arch.hardware.src;
        if (fspath.isAbsolute(srcPath)) {
            return srcPath;
        }
        const workspace = this._workspacePath;
        return hdlPath.join(workspace, srcPath);
    }

    public json(): RawPrjInfo {
        return {
            toolChain: this._toolChain,
            prjName: this._prjName,
            IP_REPO: this._IP_REPO,
            soc: this._soc,
            enableShowLog: this._enableShowLog,
            device: this._device,
            arch: this._arch,
            library: this._library,
        };
    }
};

export {
    PrjInfo,
    PrjInfoDefaults,
    PrjName,
    Arch,
    Soc,
    Library,
    RawPrjInfo,
    toSlash,
    resolve,
    SimPath,
    SrcPath,
    DataPath
};