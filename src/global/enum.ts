/* eslint-disable @typescript-eslint/naming-convention */

enum HdlLangID {
    Verilog = 'verilog',
    SystemVerilog = 'systemverilog', 
    Vhdl = 'vhdl', 
    Unknown = 'Unknown'
};

enum ToolChainType {
    Xilinx = 'xilinx',
    Intel = 'intel', 
    Custom = 'custom'
};

enum LibraryState {
    Local = 'local', 
    Remote = 'remote', 
    Unknown = 'Unknown'
};

enum XilinxIP {
    Arm = 'arm', 
    Aid = 'aid'
};

enum ThemeType {
    Dark = 'dark',
    Light = 'light'
};

function validToolChainType(name: ToolChainType) {
    const allTypes = [
        'xilinx',
        'intel',
        'custom'
    ];
    return allTypes.includes(name);
}

function validXilinxIP(name: XilinxIP) {
    const ips = [
        'arm',
        'aid'
    ];
    return ips.includes(name);
}

function validLibraryState(state: LibraryState) {
    const states = [
        'local', 
        'remote', 
        'Unknown'
    ];
    return states.includes(state);
}

export {
    HdlLangID,
    ToolChainType,
    LibraryState,
    XilinxIP,
    ThemeType,
    validToolChainType,
    validXilinxIP,
    validLibraryState
};