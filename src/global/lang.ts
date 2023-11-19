const verilogExts: string[] = ['v', 'vh', 'vl'];
const vhdlExts: string[] = ['vhd', 'vhdl', 'vho', 'vht'];
const systemVerilogExts: string[] = ['sv'];

const hdlExts: string[] = verilogExts.concat(vhdlExts).concat(systemVerilogExts);

export {
    verilogExts,
    vhdlExts,
    systemVerilogExts,
    hdlExts
};