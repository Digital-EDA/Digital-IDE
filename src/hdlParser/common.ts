/* eslint-disable @typescript-eslint/naming-convention */
import * as vscode from 'vscode';

import { AbsPath, RelPath } from '../global';
import { HdlLangID } from '../global/enum';
import { DoFastFileType } from '../global/lsp';

interface Position {
    // row/line of the cursor, index from 0
    line: number

    // col of the cursor, index from 0
    character: number
};

function makeVscodePosition(position: Position): vscode.Position {
    return new vscode.Position(position.line, position.character);
} 

interface Range {
    start: Position
    end: Position
};


enum HdlModulePortType {
    Inout = 'inout', 
    Output = 'output', 
    Input = 'input',
    VhdlInput = 'in',
    VhdlOutput = 'out',
    Unknown = 'unknown'
};

enum HdlModuleParamType {LocalParam, Parameter, Unknown};

/**
 * @description 用于描述当前的这个 HDL 文件是会被系统视为哪一种进行处理
 * - Src: src 目录文件
 * - Sim: sim 目录文件
 * - LocalLib: 局部库文件
 * - RemoteLib: 全局库文件
 * - IP: IP 核
 * - Primitive: 原语
 */
enum HdlFileProjectType {
    Src = 'src', 
    Sim = 'sim',
    LocalLib = 'local_lib',
    RemoteLib = 'remote_lib',
    IP = 'ip',
    Primitive = 'primitive',
    Unknown = 'unknown'
};

enum InstModPathStatus {Current, Include, Others, Unknown};
// enum SymbolType {
//     Module = 'module',
//     Input = 'input',
//     Output = 'output',
//     Inout = 'inout',
//     Program = 'program',
//     Package = 'package',
//     Import = 'import',
//     Always = 'always',
//     Processe = 'processe',
//     Task = 'task',
//     Function = 'function',
//     Assert = 'assert',
//     Event = 'event',
//     Instance = 'instance',
//     Time = 'time',
//     Define = 'define',
//     Typedef = 'typedef',
//     Generate = 'generate',
//     Enum = 'enum',
//     Modport = 'modport',
//     Property = 'property',
//     Interface = 'interface',
//     Buffer = 'buffer',
//     Localparam = 'localparam',
//     Parameter = 'parameter',
//     Integer = 'integer',
//     Char = 'char',
//     Float = 'float',
//     Int = 'int',
//     String = 'string',
//     Struct = 'struct',
//     Class = 'class',
//     Logic = 'logic',
//     Wire = 'wire',
//     Reg = 'reg',
//     Net = 'net',
//     Bit = 'bit'
// };

interface Error {
    severity: vscode.DiagnosticSeverity
    message: string
    source: string
    range: Position
    running_mode?: string
    running_phase?: string
};

interface DefineParam {
    name: string,
    value: string
};

/**
 * `define A out
 * name is "A", replacement is "out"
 * `define max(a, b=1) a*b
 * name is "max", replacement is "a*b", params is 
 * {
    "name": "a",
    "value": "Unknown"
    },
    {
    "name": "b",
    "value": "1"
    }
*/
interface Define {
    name: string
    replacement: string
    range: Range
    params: DefineParam[],
};

interface Include {
    // path is the value in the `include
    path: AbsPath
    range: Range
};


interface Macro {
    errors: Error[]                        // error
    defines: Define[]                      // define macro
    includes: Include[]                    // include
    invalid: Range[]                       // invalid set of range
};

interface HdlModulePort {
    name: string
    type: HdlModulePortType
    width: string
    range: Range
    desc?: string   // for patch in hdlDoc
    signed: string
    netType: string
};

interface HdlModuleParam {
    name: string
    // TODO : make out type of "type"
    type: string
    init: string
    range: Range
    desc?: string
};

type InstRange = Range | null;

interface RawHdlInstance {
    name: string
    type: string
    instparams: InstRange
    instports: InstRange
    range: Range
};

interface RawHdlModule {
    name: string
    archName: string
    params: HdlModuleParam[]
    ports: HdlModulePort[]
    instances: RawHdlInstance[]
    range: Range
};


interface RawSymbol {
    name: string
    type: string
    range: Range
    width?: string
    init?: string
    parent?: string
    signed: number
    netType: string
};

interface InstModPathSearchResult {
    path: AbsPath
    status: InstModPathStatus
};

interface HdlDependence {
    current: AbsPath[]
    include: AbsPath[]
    others: AbsPath[]
};

interface CommentResult {
    start: { line : number }
    length: number
}

interface Fast {
    content: RawHdlModule[]
    languageId: string
    macro: Macro,
    fileType: DoFastFileType
}

interface All {
    content: RawSymbol[]
    languageId: HdlLangID
    macro: Macro
    error: Error[]
}

export {
    Position,
    Range,
    InstRange,
    HdlModulePortType,
    HdlModuleParamType,
    HdlFileProjectType,
    InstModPathStatus,
    Error,
    Define,
    Include,
    Macro,
    HdlModulePort,
    HdlModuleParam,
    RawHdlInstance,
    RawHdlModule,
    InstModPathSearchResult,
    HdlDependence,
    RawSymbol,
    CommentResult,
    makeVscodePosition,
    Fast,
    All
};