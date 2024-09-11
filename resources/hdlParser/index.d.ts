import type { RawHdlModule, Macro, RawSymbol, Error } from '../../src/hdlParser/common';
import type { HdlLangID } from '../../src/global/enum';

type AbsPath = string;
type RelPath = string;
type Path = AbsPath | RelPath;


export const extensionUrl: string;

interface Fast {
    content: RawHdlModule[]
    languageId: string
    macro: Macro
}

interface All {
    content: RawSymbol[]
    languageId: HdlLangID
    macro: Macro
    error: Error[]
}

export function callParser(path: AbsPath, func: number): Promise<any | undefined>;
export function vlogFast(path: AbsPath): Promise<Fast | undefined>;
export function vlogAll(path: AbsPath): Promise<All | undefined>;
export function vhdlFast(path: AbsPath): Promise<Fast | undefined>;
export function vhdlAll(path: AbsPath): Promise<All | undefined>;
export function svFast(path: AbsPath): Promise<Fast | undefined>;
export function svAll(path: AbsPath): Promise<All | undefined>;