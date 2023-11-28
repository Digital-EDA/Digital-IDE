import * as vscode from 'vscode';

class Keywords {
    private keywords: Set<string>;
    private compilerKeywords: string[];    // start with `
    private systemKeywords: string[];   // start with $
    constructor(keywords: string[], compilerKeywords: string[], systemKeywords: string[]) {
        this.keywords = new Set(keywords);
        const keywordItems = [];
        this.compilerKeywords = compilerKeywords;
        this.systemKeywords = systemKeywords;
    }

    public keys(): Set<string> {
        return this.keywords;
    }

    public compilerKeys(): string[] {
        return this.compilerKeywords;
    }

    public systemKeys(): string[] {
        return this.systemKeywords;
    }

    public isKeyword(word: string): boolean {
        return this.keywords.has(word);
    }
}

const vlogKeyword = new Keywords([
    "above", "disable", "idt", "notif1", "supply0", "abs", "discipline", "idtmod",
    "or", "supply1", "absdelay", "driver_update", "if", "output", "table", "ac_stim",
    "edge", "ifnone", "parameter", "tan", "acos", "else", "inf", "pmos", "tanh",
    "acosh", "end", "initial", "posedge", "task", "always", "endcase", "initial_step",
    "potential", "time", "analog", "endconnectrules", "inout", "pow", "timer", "analysis",
    "enddiscipline", "input", "primitive", "tran", "and", "endfunction", "integer",
    "pull0", "tranif0", "asin", "endmodule", "join", "pull1", "tranif1", "asinh",
    "endnature", "laplace_nd", "pulldown", "transition", "assign", "endprimitive",
    "laplace_np", "pullup", "tri", "atan", "endspecify", "laplace_zd", "rcmos", "tri0",
    "atan2", "endtable", "laplace_zp", "real", "tri1", "atanh", "endtask", "large",
    "realtime", "triand", "begin", "event", "last_crossing", "reg", "trior", "branch",
    "exclude", "limexp", "release", "trireg", "buf", "exp", "ln", "repeat", "vectored",
    "bufif0", "final_step", "log", "rnmos", "wait", "bufif1", "flicker_noise", "macromodule",
    "rpmos", "wand", "case", "flow", "max", "rtran", "weak0", "casex", "for", "medium",
    "rtranif0", "weak1", "casez", "force", "min", "rtranif1", "while", "ceil", "forever",
    "module", "scalared", "white_noise", "cmos", "fork", "nand", "sin", "wire",
    "connectrules", "from", "nature", "sinh", "wor", "cos", "function", "negedge",
    "slew", "wreal", "cosh", "generate", "net_resolution", "small", "xnor", "cross",
    "genvar", "nmos", "specify", "xor", "ddt", "ground", "noise_table", "specparam",
    "zi_nd", "deassign", "highz0", "nor", "sqrt", "zi_np", "default", "highz1",
    "not", "strong0", "zi_zd", "defparam", "hypot", "notif0", "strong1", "zi_zp",
],
[
    "begin_keywords", "celldefine", "default_nettype", "define", "else", "elsif",
    "end_keywords", "endcelldefine", "endif", "ifdef", "ifndef", "include", "line",
    "nounconnected_drive", "pragma", "resetall", "timescale", "unconnected_drive", "undef"
],
[
    'acos', 'sqrt', 'ftell', 'fdisplay', 'fclose', 'timeformat', 'fseek', 'asinh', 'fdisplayh', 
    'fmonitorb', 'dist_erlang', 'writeb', 'fwrite', 'swriteb', 'printtimescale', 'displayb', 'atan', 
    'sscanf', 'exp', 'nand', 'fdisplayo', 'sdf_annotate', 'stime', 'sin', 'dist_chi_square', 'strobeh', 
    'array', 'swriteo', 'and', 'dist_normal', 'readmemb', 'strobeb', 'realtobits', 'or', 'dist_exponential', 
    'plusargs', 'hypot', 'swrite', 'writeh', 'plane', 'fstrobeb', 'time', 'fread', 'fstrobe', 'rewind', 'async', 
    'sync', 'bitstoreal', 'readmemh', 'fwriteo', 'value', 'tanh', 'rtoi', 'fgetc', 'realtime', 'atan2', 'acosh', 
    'displayh', 'log10', 'clog2', 'fstrobeo', 'pow', 'fwriteb', 'fwriteh', 'nor', 'fdisplayb', 'monitoroff', 'fgets', 
    'q_add', 'atanh', 'monitor', 'monitorh', 'cos', 'ln', 'q_initialize', 'unsigned', 'swriteh', 'asin', 'monitoron', 
    'monitoro', 'display', 'tan', 'fscanf', 'dist_uniform', 'test', 'q_exam', 'itor', 'random', 'fstrobeh', 'strobe', 
    'displayo', 'monitorb', 'ungetc', 'feof', 'stop', 'ferror', 'finish', 'fmonitor', 'fmonitorh', 'cosh', 'writeo', 'sinh', 
    'dist_poisson', 'write', 'fopen', 'fmonitoro', 'fflush', 'ceil', 'strobeo', 'dist_t', 'q_full', 'signed', 'sformat', 
    'q_remove', 'floor',
    'dumpfile', 'dumpvars', 'dumpoff', 'dumpon', 'dumpall', 'dumplimit', 'dumpflush', 
    'dumpports', 'dumpportsoff', 'dumpportson', 'dumpportsall', 'dumpportslimit', 'dumpportsflush'
]
);

// TODO : do vhdl and sv version
const vhdlKeyword = new Keywords(["abs", "configuration", "impure", "null", "rem", "type", 
    "access", "constant", "in", "of", "report", "unaffected", "after", "disconnect", 
    "inertial", "on", "return", "units", "alias", "downto", "inout", "open", "rol", 
    "until", "all", "else", "is", "or", "ror", "use", "and", "elsif", "label", "others", 
    "select", "variable", "architecture", "end", "library", "out", "severity", "wait", "array", 
    "entity", "linkage", "package", "signal", "when", "assert", "exit", "literal", "port", "shared", 
    "while", "attribute", "file", "loop", "postponed", "sla", "with", "begin", "for", "map", "procedure", 
    "sll", "xnor", "block", "function", "mod", "process", "sra", "xor", "body", "generate", "nand", "pure", 
    "srl", "buffer", "generic", "new", "range", "subtype", "bus", "group", "next", "record", "then", "case", 
    "guarded", "nor", "register", "to",
], 
[
    "std_logic", "std_ulogic", "std_logic_vector", "std_ulogic_vector", "signed", "unsigned", "complex", "complex_polar", 
    "boolean", "bit", "character", "severity_level", "integer", "real", "time", "delay_length", "now", "natural", "positive",
    "string", "bit_vector", "file_open_kind", "file_open_status", "fs", "ps", "ns", "us", "ms", "sec", "min", "hr", 
    "severity_level", "note", "warning", "error", "failure", "line", "text", "side", "width", "input", "output"
], 
[]);

const systemverilogKeyword = new Keywords([
    "above", "disable", "idt", "notif1", "supply0", "abs", "discipline", "idtmod",
    "or", "supply1", "absdelay", "driver_update", "if", "output", "table", "ac_stim",
    "edge", "ifnone", "parameter", "tan", "acos", "else", "inf", "pmos", "tanh",
    "acosh", "end", "initial", "posedge", "task", "always", "endcase", "initial_step",
    "potential", "time", "analog", "endconnectrules", "inout", "pow", "timer", "analysis",
    "enddiscipline", "input", "primitive", "tran", "and", "endfunction", "integer",
    "pull0", "tranif0", "asin", "endmodule", "join", "pull1", "tranif1", "asinh",
    "endnature", "laplace_nd", "pulldown", "transition", "assign", "endprimitive",
    "laplace_np", "pullup", "tri", "atan", "endspecify", "laplace_zd", "rcmos", "tri0",
    "atan2", "endtable", "laplace_zp", "real", "tri1", "atanh", "endtask", "large",
    "realtime", "triand", "begin", "event", "last_crossing", "reg", "trior", "branch",
    "exclude", "limexp", "release", "trireg", "buf", "exp", "ln", "repeat", "vectored",
    "bufif0", "final_step", "log", "rnmos", "wait", "bufif1", "flicker_noise", "macromodule",
    "rpmos", "wand", "case", "flow", "max", "rtran", "weak0", "casex", "for", "medium",
    "rtranif0", "weak1", "casez", "force", "min", "rtranif1", "while", "ceil", "forever",
    "module", "scalared", "white_noise", "cmos", "fork", "nand", "sin", "wire",
    "connectrules", "from", "nature", "sinh", "wor", "cos", "function", "negedge",
    "slew", "wreal", "cosh", "generate", "net_resolution", "small", "xnor", "cross",
    "genvar", "nmos", "specify", "xor", "ddt", "ground", "noise_table", "specparam",
    "zi_nd", "deassign", "highz0", "nor", "sqrt", "zi_np", "default", "highz1",
    "not", "strong0", "zi_zd", "defparam", "hypot", "notif0", "strong1", "zi_zp"
],
[
    "begin_keywords", "celldefine", "default_nettype", "define", "else", "elsif",
    "end_keywords", "endcelldefine", "endif", "ifdef", "ifndef", "include", "line",
    "nounconnected_drive", "pragma", "resetall", "timescale", "unconnected_drive", "undef"
],
[
    'acos', 'sqrt', 'ftell', 'fdisplay', 'fclose', 'timeformat', 'fseek', 'asinh', 'fdisplayh', 
    'fmonitorb', 'dist_erlang', 'writeb', 'fwrite', 'swriteb', 'printtimescale', 'displayb', 'atan', 
    'sscanf', 'exp', 'nand', 'fdisplayo', 'sdf_annotate', 'stime', 'sin', 'dist_chi_square', 'strobeh', 
    'array', 'swriteo', 'and', 'dist_normal', 'readmemb', 'strobeb', 'realtobits', 'or', 'dist_exponential', 
    'plusargs', 'hypot', 'swrite', 'writeh', 'plane', 'fstrobeb', 'time', 'fread', 'fstrobe', 'rewind', 'async', 
    'sync', 'bitstoreal', 'readmemh', 'fwriteo', 'value', 'tanh', 'rtoi', 'fgetc', 'realtime', 'atan2', 'acosh', 
    'displayh', 'log10', 'clog2', 'fstrobeo', 'pow', 'fwriteb', 'fwriteh', 'nor', 'fdisplayb', 'monitoroff', 'fgets', 
    'q_add', 'atanh', 'monitor', 'monitorh', 'cos', 'ln', 'q_initialize', 'unsigned', 'swriteh', 'asin', 'monitoron', 
    'monitoro', 'display', 'tan', 'fscanf', 'dist_uniform', 'test', 'q_exam', 'itor', 'random', 'fstrobeh', 'strobe', 
    'displayo', 'monitorb', 'ungetc', 'feof', 'stop', 'ferror', 'finish', 'fmonitor', 'fmonitorh', 'cosh', 'writeo', 'sinh', 
    'dist_poisson', 'write', 'fopen', 'fmonitoro', 'fflush', 'ceil', 'strobeo', 'dist_t', 'q_full', 'signed', 'sformat', 
    'q_remove', 'floor'
]
);


const tclKeyword = new Keywords([
    'create_clock',  
    'set_clock_uncertainty',  
    'create_reset',  
    'set_initial_state',  
    'create_sync',  
    'create_source_sync',  
    'create_launch_bar',  
    'connect_port',  
    'set_signal_type',  
    'set_edge_detect',  
    'set_delay',  
    'create_generated_clock',  
    'create_programmable_logic',  
    'create_lookup_table',  
    'create_shift_register',  
    'create_counter',  
    'create_multiplier',  
    'create_divider',  
    'create_comparator',  
    'create_register',  
    'create_flop',  
    'connect_power_pin',  
    'connect_ground_pin',
    'set_property'
],
[],
[]
);


export {
    vlogKeyword,
    vhdlKeyword,
    systemverilogKeyword,
    tclKeyword
};