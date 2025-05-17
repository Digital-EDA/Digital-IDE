import * as assert from 'assert';
import * as fs from 'fs';

import { Arch, PrjInfo, RawPrjInfo, resolve } from './prjInfo';
import { hdlPath } from '../hdlFs';
import { getUserHomeDir } from './util';

type AbsPath = string;
type RelPath = string;

// eslint-disable-next-line @typescript-eslint/naming-convention
const OpeParamDefaults = {
    os: '',
    extensionPath: '',
    workspacePath: '',
    prjInfo: new PrjInfo(),
    propertyJsonPath: '',               // path of property.json
    propertySchemaPath: '',             // path of property-schema.json
    propertyInitPath: '',               // path of property-init.json
    topModule: { name: '', path: '' }
};

interface FirstTopModuleDesc {
    name: string
    path: AbsPath | undefined
};

function readJSON(path: AbsPath): object {
    try {
        const context = fs.readFileSync(path, 'utf-8');
        return JSON.parse(context);
    } catch (err) {
        console.log('fail to read JSON: ', err);
    }
    return {};
}


class OpeParam {
    private _os: string = OpeParamDefaults.os;
    private _extensionPath: AbsPath = OpeParamDefaults.extensionPath;
    private _workspacePath: AbsPath = OpeParamDefaults.workspacePath;

    // information of the whole project
    private _prjInfo: PrjInfo = OpeParamDefaults.prjInfo;

    // path of property.json
    private _propertyJsonPath: AbsPath = OpeParamDefaults.propertyJsonPath;

    // path of property-schema.json
    private _propertySchemaPath: AbsPath = OpeParamDefaults.propertySchemaPath;

    // path of property-init.json
    private _propertyInitPath: AbsPath = OpeParamDefaults.propertyInitPath;

    private _firstSrcTopModule: FirstTopModuleDesc = OpeParamDefaults.topModule;
    private _firstSimTopModule: FirstTopModuleDesc = OpeParamDefaults.topModule;
    private _openMode: 'folder' | 'file' = 'folder';

    public get os() : string {
        return this._os;
    }

    public get extensionPath(): AbsPath {
        return this._extensionPath;
    }

    public get workspacePath(): AbsPath {
        return this._workspacePath;
    }

    public get prjInfo(): PrjInfo {
        return this._prjInfo;
    }
    
    /**
     * path of property.json
     */
    public get propertyJsonPath(): AbsPath {
        return this._propertyJsonPath;
    }

    /**
     * .dideignore 的路径
     */
    public get dideignorePath(): AbsPath {
        const workspace = this._workspacePath;
        return hdlPath.join(workspace, '.dideignore');
    }

    /**
     * path of property-schema.json
     */
    public get propertySchemaPath() : AbsPath {
        return this._propertySchemaPath;
    }

    public get dideHome() : AbsPath {
        return hdlPath.join(getUserHomeDir(), '.digital-ide');
    }

    /**
     * path of property-init.json
     */
    public get propertyInitPath() : AbsPath {
        return this._propertyInitPath;
    }
    
    public get firstSrcTopModule(): FirstTopModuleDesc {
        return this._firstSrcTopModule;
    }

    public get firstSimTopModule(): FirstTopModuleDesc {
        return this._firstSimTopModule;
    }

    public get prjStructure(): Arch {
        return this._prjInfo.arch;
    }

    public get openMode(): 'file' | 'folder' {
        return this._openMode;
    }

    public setBasicInfo(os: string, 
                        extensionPath: AbsPath, 
                        workspacePath: AbsPath, 
                        propertyJsonPath: AbsPath,
                        propertySchemaPath: AbsPath,
                        propertyInitPath: AbsPath) {
        this._os = os;

        assert(fs.existsSync(extensionPath), 'extensionPath ' + extensionPath + ' not exist!');
        assert(fs.existsSync(propertySchemaPath), 'propertySchemaPath ' + propertySchemaPath + ' not exist!');
        assert(fs.existsSync(propertyInitPath), 'propertyInitPath ' + propertyInitPath + ' not exist!');

        this._extensionPath = extensionPath;
        this._workspacePath = workspacePath;
        this._propertyJsonPath = propertyJsonPath;
        this._propertySchemaPath = propertySchemaPath;
        this._propertyInitPath = propertyInitPath;

        // 如果 workspacePath 为空，说明当前是以单文件形式打开的
        if (fs.existsSync(workspacePath)) {
            this._openMode = 'folder';
        } else {
            this._openMode = 'file';
        }
    }

    public setFirstSrcTopModule(name: string | null, path: AbsPath | null) {
        if (name) {
            this._firstSrcTopModule.name = name;
        }
        if (path) {
            this._firstSrcTopModule.path = path;
        }
    }

    public setFirstSimTopModule(name: string | null, path: AbsPath | null) {
        if (name) {
            this._firstSimTopModule.name = name;
        }
        if (path) {
            this._firstSimTopModule.path = path;
        }
    }

    public mergePrjInfo(rawPrjInfo: RawPrjInfo) {
        this.prjInfo.merge(rawPrjInfo);
    }

    /**
     * return the absolute path based on workspacePath
     * @param relPath 
     */
    public resolvePathWorkspace(relPath: RelPath): AbsPath {
        return resolve(this._workspacePath, relPath);
    }

    /**
     * return the absolute path based on extensionPath
     * @param relPath 
     */
    public resolvePathExtension(relPath: RelPath): AbsPath {
        return resolve(this._extensionPath, relPath);
    }

    /**
     * get User's property.json
     */
    public getUserPrjInfo(): PrjInfo {
        const userPrjInfo = new PrjInfo();
        userPrjInfo.initContextPath(this.extensionPath, this.workspacePath);
        const rawPrjInfo = this.getRawUserPrjInfo();
        userPrjInfo.merge(rawPrjInfo);
        return userPrjInfo;
    }

    /**
     * get content from property.json (disk IO)
     * @returns 
     */
    public getRawUserPrjInfo(): RawPrjInfo {
        const propertyJsonPath = this.propertyJsonPath;
        if (fs.existsSync(propertyJsonPath)) {
            const rawPrjInfo = readJSON(propertyJsonPath);
            return rawPrjInfo;
        } else {
            // use default config instead
            const rawPrjInfo = readJSON(this.propertyInitPath);
            return rawPrjInfo;
        }
    }

};

const opeParam: OpeParam = new OpeParam();

export {
    opeParam,
    OpeParamDefaults
};