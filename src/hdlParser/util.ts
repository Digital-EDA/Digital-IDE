import { Fast, vlogAll, vlogFast, vhdlAll, svFast, svAll, vhdlFast, All } from '../../resources/hdlParser';
import { hdlFile } from '../hdlFs';
import { HdlLangID } from '../global/enum';
import { AbsPath } from '../global';

namespace HdlSymbol {
    export async function fast(path: AbsPath): Promise<Fast | undefined> {
        const langID = hdlFile.getLanguageId(path);
        switch (langID) {
            case HdlLangID.Verilog: return vlogFast(path);
            case HdlLangID.Vhdl: return vhdlFast(path);
            case HdlLangID.SystemVerilog: return svFast(path);
            default: return undefined;
        }
    }

    export async function all(path: AbsPath): Promise<All | undefined> {
        const langID = hdlFile.getLanguageId(path);
        switch (langID) {
            case HdlLangID.Verilog: return vlogAll(path);
            case HdlLangID.Vhdl: return vhdlAll(path);
            case HdlLangID.SystemVerilog: return svAll(path);
            default: return undefined;
        }
    }
}



export {
    HdlSymbol,
};