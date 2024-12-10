import { opeParam, OpeParamDefaults } from './opeParam';
import { PrjInfo, PrjInfoDefaults } from './prjInfo';
import { MainOutput, LinterOutput, YosysOutput, WaveViewOutput, ReportType } from './outputChannel';

import * as Enum from './enum';
import * as Lang from './lang';
import { LspClient } from './lsp';

type AbsPath = string;
type RelPath = string;

type AllowNull<T> = T | null;


interface IProgress {
    message?: string,
    increment?: number
}

export {
    opeParam,
    OpeParamDefaults,
    PrjInfo,
    PrjInfoDefaults,
    Enum,
    Lang,
    AbsPath,
    RelPath,
    MainOutput,
    LinterOutput,
    YosysOutput,
    WaveViewOutput,
    ReportType,
    AllowNull,
    LspClient,
    IProgress
};