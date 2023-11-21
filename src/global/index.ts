import { opeParam, OpeParamDefaults } from './opeParam';
import { PrjInfo, PrjInfoDefaults } from './prjInfo';
import { MainOutput, LspOutput, YosysOutput, ReportType } from './outputChannel';

import * as Enum from './enum';
import * as Lang from './lang';

type AbsPath = string;
type RelPath = string;

type AllowNull<T> = T | null;

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
    LspOutput,
    YosysOutput,
    ReportType,
    AllowNull
};