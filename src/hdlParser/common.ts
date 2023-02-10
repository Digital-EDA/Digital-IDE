/* eslint-disable @typescript-eslint/naming-convention */

import { AbsPath, RelPath } from '../global';

interface Position {
    // row/line of the cursor, index from 0
    line: number

    // col of the cursor, index from 0
    character: number
};

interface Range {
    start: Position
    end: Position
};


enum HdlModulePortType {
    Inout = 'inout', 
    Output = 'output', 
    Input = 'input', 
    Unknown = 'Unknown'
};

enum HdlModuleParamType {LocalParam, Parameter, Unknown};

enum HdlFileType {
    Src = 'src', 
    Sim = 'sim',
    LocalLib = 'local_lib',
    RemoteLib = 'remote_lib' 
};
enum InstModPathStatus {Current, Include, Others, Unknown};
enum SymbolType {
    Module = 'module',
    Input = 'input',
    Output = 'output'
};

interface Error {
    severity: number
    message: string
    source: string
    range: Range
};

interface Define {
    // `define A out
    // name is "A", value is "out"
    name: string
    value: string
    range: Position
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
    desc?: string
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
    params: HdlModuleParam[]
    ports: HdlModulePort[]
    instances: RawHdlInstance[]
    range: Range
};


interface RawSymbol {
    name: string
    type: SymbolType
    range: Range
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

export {
    Position,
    Range,
    InstRange,
    HdlModulePortType,
    HdlModuleParamType,
    HdlFileType,
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
    RawSymbol
};