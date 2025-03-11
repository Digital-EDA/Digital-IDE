import * as vscode from 'vscode';
import { ChildProcessWithoutNullStreams, exec, spawn } from 'child_process';
import * as fspath from 'path';
import * as fs from 'fs';
import * as os from 'os';

import { AbsPath, opeParam, PrjInfo } from '../../global';
import { hdlParam } from '../../hdlParser/core';
import { hdlFile, hdlDir, hdlPath } from '../../hdlFs';
import { PropertySchema } from '../../global/propertySchema';

import { XilinxIP } from '../../global/enum';
import { HardwareOutput, MainOutput, ReportType } from '../../global/outputChannel';
import { debounce, getPIDsWithName, killProcess } from '../../global/util';
import { t } from '../../i18n';
import { HdlFileProjectType } from '../../hdlParser/common';
import { integer } from 'vscode-languageclient';
import { AnyARecord } from 'dns';

type ChainInfo = [number, number, number, number];

export class EfinityOperation {
    prjScript: string;
    efxPath: string;
    constructor() {
        this.prjScript = '';
        this.efxPath = hdlPath.join(opeParam.workspacePath, `${opeParam.prjInfo.prjName.PL}.xml`);
    }

    public launch() {
        this.prjScript = `<efx:project xmlns:efx="http://www.efinixinc.com/enf_proj" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="${opeParam.prjInfo.prjName.PL}" description="" last_change="1724639062" sw_version="2023.2.307" last_run_state="pass" last_run_flow="bitstream" config_result_in_sync="sync" design_ood="sync" place_ood="sync" route_ood="sync" xsi:schemaLocation="http://www.efinixinc.com/enf_proj enf_proj.xsd">\n${this.getDeviceInfo(opeParam.prjInfo.device)}\n${this.getDesignInfo()}\n${this.getConstraintInfo()}\n  <efx:sim_info />\n  <efx:misc_info />\n  <efx:ip_info />\n${this.getSynthInfo()}\n${this.getPnRInfo()}\n${this.getBitstreamInfo()}\n${this.getDebugInfo()}\n${this.getSecurityInfo()}\n</efx:project>`;

        fs.writeFileSync(this.efxPath, this.prjScript);

        hdlParam.getHdlModule(opeParam.firstSrcTopModule.path || '', opeParam.firstSrcTopModule.name);

    }

    public simulate() {

    }

    public simulateCli() {

    }

    public simulateGui() {

    }

    public refresh() {
        this.launch();
    }

    public build() {
        exec(`${this.updateEfinixPath()} ${this.efxPath} --flow compile --work_dir=${opeParam.workspacePath}/prj/efinix --output_dir ${opeParam.workspacePath}/prj/efinix/outflow --cleanup_work_dir work_pt`, (error, stdout, stderr) => {
            console.log(error);

        })
    }

    public synth() {

    }

    public impl() {

    }

    public bitstream() {

    }

    public program() {
        const bitPath = hdlPath.join(opeParam.workspacePath, 'outflow/efinix.bit');
        const svfPath = hdlPath.join(opeParam.workspacePath, 'efinix.svf');
        this.convert_to_SVF_TrionX(bitPath, svfPath, "10660A79", "6E6", 2000, true, [0, 0, 0, 0]);

        // exec()
    }

    public gui() {

    }

    public exit() {

    }

    public setSrcTop() {

    }

    public setSimTop() {

    }

    private getDeviceInfo(device: string): string {
        const deviceInfo = device.split('-');
        let family = 'Trion';
        if (device.slice(0, 2).toLowerCase() === 'ti') {
            family = 'Titanium';
        }

        return `  <efx:device_info>
    <efx:family name="${family}"/>
    <efx:device name="${deviceInfo[0]}"/>
    <efx:timing_model name="${deviceInfo[1]}"/>
  </efx:device_info>`;
    }

    private getDesignInfo(): string {
        let designFile = `    <efx:top_module name="${opeParam.firstSrcTopModule.name}"/>\n`;
        for (const hdlFile of hdlParam.getAllHdlFiles()) {
            switch (hdlFile.projectType) {
                case HdlFileProjectType.Src:
                case HdlFileProjectType.LocalLib:
                case HdlFileProjectType.RemoteLib:
                case HdlFileProjectType.Sim:
                    designFile += `    <efx:design_file name="${hdlFile.path}" version="default" library="default"/>\n`;
                    break;
                case HdlFileProjectType.IP:
                case HdlFileProjectType.Primitive:
                    // IP 和 原语不用管
                    break;
                default:
                    break;
            }
        }
        designFile += `    <efx:top_vhdl_arch name=""/>`
        return `  <efx:design_info def_veri_version="verilog_2k" def_vhdl_version="vhdl_2008">\n${designFile}
  </efx:design_info>`
    };

    private getConstraintInfo(): string {
        let constraintFile = '';
        hdlFile.pickFileRecursive(opeParam.prjInfo.arch.hardware.data, filePath => {
            if (filePath.endsWith('.sdc')) {
                constraintFile += `  <efx:sdc_file name="${filePath}" />\n`;
            }
        });

        constraintFile += `    <efx:inter_file name="" />\n`;

        return `  <efx:constraint_info>\n${constraintFile}    </efx:constraint_info>`;
    }

    private getSynthInfo(): string {
        return `  <efx:synthesis tool_name="efx_map">
    <efx:param name="work_dir" value="work_syn" value_type="e_string"/>
    <efx:param name="write_efx_verilog" value="on" value_type="e_bool"/>
    <efx:param name="mode" value="speed" value_type="e_option"/>
    <efx:param name="max_ram" value="-1" value_type="e_integer"/>
    <efx:param name="max_mult" value="-1" value_type="e_integer"/>
    <efx:param name="infer-clk-enable" value="3" value_type="e_option"/>
    <efx:param name="infer-sync-set-reset" value="1" value_type="e_option"/>
    <efx:param name="min-sr-fanout" value="0" value_type="e_integer"/>
    <efx:param name="min-ce-fanout" value="0" value_type="e_integer"/>
    <efx:param name="fanout-limit" value="0" value_type="e_integer"/>
    <efx:param name="bram_output_regs_packing" value="1" value_type="e_option"/>
    <efx:param name="retiming" value="1" value_type="e_option"/>
    <efx:param name="seq_opt" value="1" value_type="e_option"/>
    <efx:param name="blast_const_operand_adders" value="1" value_type="e_option"/>
    <efx:param name="operator-sharing" value="0" value_type="e_option"/>
    <efx:param name="optimize-adder-tree" value="0" value_type="e_option"/>
    <efx:param name="seq-opt-sync-only" value="0" value_type="e_option"/>
    <efx:param name="blackbox-error" value="1" value_type="e_option"/>
    <efx:param name="allow-const-ram-index" value="0" value_type="e_option"/>
    <efx:param name="hdl-compile-unit" value="1" value_type="e_option"/>
    <efx:param name="create-onehot-fsms" value="0" value_type="e_option"/>
    <efx:param name="dsp-mac-packing" value="1" value_type="e_option"/>
    <efx:param name="dsp-output-regs-packing" value="1" value_type="e_option"/>
    <efx:param name="dsp-input-regs-packing" value="1" value_type="e_option"/>
    <efx:param name="pack-luts-to-comb4" value="0" value_type="e_option"/>
    <efx:param name="mult-auto-pipeline" value="0" value_type="e_option"/>
    <efx:param name="mult-decomp-retime" value="0" value_type="e_option"/>
    <efx:param name="optimize-zero-init-rom" value="1" value_type="e_option"/>
    <efx:param name="use-logic-for-small-mem" value="64" value_type="e_integer"/>
    <efx:param name="use-logic-for-small-rom" value="64" value_type="e_integer"/>
    <efx:param name="insert-carry-skip" value="0" value_type="e_option"/>
  </efx:synthesis>`;
    }

    private getPnRInfo(): string {
        return `  <efx:place_and_route tool_name="efx_pnr">
    <efx:param name="work_dir" value="work_pnr" value_type="e_string"/>
    <efx:param name="verbose" value="off" value_type="e_bool"/>
    <efx:param name="load_delaym" value="on" value_type="e_bool"/>
    <efx:param name="optimization_level" value="NULL" value_type="e_option"/>
    <efx:param name="seed" value="1" value_type="e_integer"/>
    <efx:param name="placer_effort_level" value="2" value_type="e_option"/>
    <efx:param name="max_threads" value="-1" value_type="e_integer"/>
    <efx:param name="print_critical_path" value="10" value_type="e_integer"/>
    <efx:param name="beneficial_skew" value="on" value_type="e_option"/>
  </efx:place_and_route>`;
    }

    private getBitstreamInfo(): string {
        return `  <efx:bitstream_generation tool_name="efx_pgm">
    <efx:param name="mode" value="active" value_type="e_option"/>
    <efx:param name="width" value="1" value_type="e_option"/>
    <efx:param name="enable_roms" value="smart" value_type="e_option"/>
    <efx:param name="spi_low_power_mode" value="on" value_type="e_bool"/>
    <efx:param name="io_weak_pullup" value="on" value_type="e_bool"/>
    <efx:param name="oscillator_clock_divider" value="DIV8" value_type="e_option"/>
    <efx:param name="bitstream_compression" value="on" value_type="e_bool"/>
    <efx:param name="enable_external_master_clock" value="off" value_type="e_bool"/>
    <efx:param name="active_capture_clk_edge" value="negedge" value_type="e_option"/>
    <efx:param name="jtag_usercode" value="0xFFFFFFFF" value_type="e_string"/>
    <efx:param name="release_tri_then_reset" value="on" value_type="e_bool"/>
    <efx:param name="four_byte_addressing" value="off" value_type="e_bool"/>
    <efx:param name="generate_bit" value="on" value_type="e_bool"/>
    <efx:param name="generate_bitbin" value="off" value_type="e_bool"/>
    <efx:param name="generate_hex" value="on" value_type="e_bool"/>
    <efx:param name="generate_hexbin" value="off" value_type="e_bool"/>
    <efx:param name="cold_boot" value="off" value_type="e_bool"/>
    <efx:param name="cascade" value="off" value_type="e_option"/>
  </efx:bitstream_generation>`;
    }

    private getDebugInfo(): string {
        return `  <efx:debugger>
    <efx:param name="work_dir" value="work_dbg" value_type="e_string"/>
    <efx:param name="auto_instantiation" value="off" value_type="e_bool"/>
    <efx:param name="profile" value="NONE" value_type="e_string"/>
  </efx:debugger>`;
    }

    private getSecurityInfo(): string {
        return `  <efx:security>
    <efx:param name="randomize_iv_value" value="on" value_type="e_bool"/>
    <efx:param name="iv_value" value="" value_type="e_string"/>
    <efx:param name="enable_bitstream_encrypt" value="off" value_type="e_bool"/>
    <efx:param name="enable_bitstream_auth" value="off" value_type="e_bool"/>
    <efx:param name="encryption_key_file" value="NONE" value_type="e_string"/>
    <efx:param name="auth_key_file" value="NONE" value_type="e_string"/>
  </efx:security>`;
    }

    private getIODeviceConfig(): string {

        function getIOBankInfo(params:Record<string, string>): string {
            let iobankInfo = '';
            for (const [key, value] of Object.entries(params)) {
                iobankInfo += `            <efxpt:iobank name="${key}" iostd="${value}" is_dyn_voltage="false" mode_sel_name="${key}_MODE_SEL"/>\n`;
            }
            return `        <efxpt:iobank_info>\n${iobankInfo}        </efxpt:iobank_info>`;
        }

        function getReconfigInfo(params:Record<string, string>): string {
            let ctrlInfo = '';
            for (const [key, value] of Object.entries(params)) {
                ctrlInfo += `            <efxpt:ctrl name="${key}" ctrl_def="${value}" clock_name="" is_clk_invert="false" cbsel_bus_name="${key}_CBSEL" config_ctrl_name="${key}_CONFIG" ena_capture_name="${key}_ENA" error_status_name="${key}_ERROR" um_signal_status_name="${key}_USR_STATUS" is_remote_update_enable="false" is_user_mode_enable="false"/>\n`;
            }
            return `        <efxpt:ctrl_info>\n${ctrlInfo}        </efxpt:ctrl_info>`;
        }

        function getSeuInfo(params:Record<string, string>): string {
            let seuInfo = '';
            for (const [key, value] of Object.entries(params)) {
                seuInfo += `            <efxpt:seu name="${key}" block_def="${value}" mode="auto" ena_detect="false" wait_interval="16500000">\n                <efxpt:gen_pin>\n                    <efxpt:pin name="${key}_START" type_name="START" is_bus="false"/>\n                    <efxpt:pin name="${key}_INJECT_ERROR" type_name="INJECT_ERROR" is_bus="false"/>\n                    <efxpt:pin name="${key}_RST" type_name="RST" is_bus="false"/>\n                    <efxpt:pin name="${key}_CONFIG" type_name="CONFIG" is_bus="false"/>\n                    <efxpt:pin name="${key}_ERROR" type_name="ERROR" is_bus="false"/>\n                    <efxpt:pin name="${key}_DONE" type_name="DONE" is_bus="false"/>\n                </efxpt:gen_pin>\n            </efxpt:seu>\n`;
            }
            return `        <efxpt:seu_info>\n${seuInfo}        </efxpt:seu_info>`;
        }

        function getCLKMUXInfo(params:Record<string, string>): string {
            let clkmuxInfo = '';
            for (const [key, value] of Object.entries(params)) {
                clkmuxInfo += `            <efxpt:clkmux name="${key}" block_def="${value}" is_mux_bot0_dyn="false" is_mux_bot7_dyn="false">\n                <efxpt:gen_pin>\n                    <efxpt:pin name="" type_name="ROUTE0" is_bus="false" is_clk="true" is_clk_invert="false"/>\n                    <efxpt:pin name="" type_name="ROUTE1" is_bus="false" is_clk="true" is_clk_invert="false"/>\n                    <efxpt:pin name="" type_name="ROUTE2" is_bus="false" is_clk="true" is_clk_invert="false"/>\n                    <efxpt:pin name="" type_name="ROUTE3" is_bus="false" is_clk="true" is_clk_invert="false"/>\n                    <efxpt:pin name="" type_name="DYN_MUX_OUT_0" is_bus="false"/>\n                    <efxpt:pin name="" type_name="DYN_MUX_OUT_7" is_bus="false"/>\n                    <efxpt:pin name="" type_name="DYN_MUX_SEL_0" is_bus="true"/>\n                    <efxpt:pin name="" type_name="DYN_MUX_SEL_7" is_bus="true"/>\n                </efxpt:gen_pin>\n            </efxpt:clkmux>\n`;
            }
            return `        <efxpt:clkmux_info>\n${clkmuxInfo}        </efxpt:clkmux_info>`;
        }

        return `    <efxpt:device_info>\n${getIOBankInfo({
            "1A_4B" : "1.8 V LVCMOS",
            "1B" : "1.8 V LVCMOS",
            "2A_2B" : "1.8 V LVCMOS",
            "3A" : "1.8 V LVCMOS",
            "3B_4A" : "1.8 V LVCMOS",
            "BL" : "1.8 V LVCMOS"
        })}\n${getReconfigInfo({
            "cfg" : "CONFIG_CTRL0"
        })}\n${getSeuInfo({
            "seu" : "CONFIG_SEU0"
        })}\n${getCLKMUXInfo({
            "CLKMUX_B" : "CLKMUX_B",
            "CLKMUX_L" : "CLKMUX_L",
            "CLKMUX_R" : "CLKMUX_R",
            "CLKMUX_T" : "CLKMUX_T"
        })}
        <efxpt:ext_flash_ctrl_info>
            <efxpt:ext_flash_ctrl ena_ext_flash_ctrl="false"/>
        </efxpt:ext_flash_ctrl_info>
    </efxpt:device_info>`
    }

    private setCompInputGPIO(param:Record<string, string>): string {
        return `    <efxpt:comp_gpio_info>
        <efxpt:comp_gpio name="comp_gpio_inst1" block_def="COMP_GPIO0">
            <efxpt:gen_pin>
                <efxpt:pin name="comp_gpio_in" type_name="IN" is_bus="true"/>
                <efxpt:pin name="comp_gpio_out" type_name="OUT" is_bus="true"/>
                <efxpt:pin name="comp_gpio_oe" type_name="OE" is_bus="true"/>
            </efxpt:gen_pin>
        </efxpt:comp_gpio>`
    }

    private getHBRAMConfig(): string {
        return `    <efxpt:hyper_ram_info>
        <efxpt:hyper_ram name="hyper_ram_inst1" block_def="HYPER_RAM0">
            <efxpt:gen_pin>
                <efxpt:pin name="" type_name="CLK" is_bus="false" is_clk="true" is_clk_invert="false"/>
                <efxpt:pin name="" type_name="CLK90" is_bus="false" is_clk="true" is_clk_invert="false"/>
                <efxpt:pin name="" type_name="CLKCAL" is_bus="false" is_clk="true" is_clk_invert="false"/>
                <efxpt:pin name="hbc_rst_n" type_name="RST_N" is_bus="false"/>
                <efxpt:pin name="hbc_cs_n" type_name="CS_N" is_bus="false"/>
                <efxpt:pin name="hbc_ck_p_HI" type_name="CK_P_HI" is_bus="false"/>
                <efxpt:pin name="hbc_ck_p_LO" type_name="CK_P_LO" is_bus="false"/>
                <efxpt:pin name="hbc_ck_N_HI" type_name="CK_N_HI" is_bus="false"/>
                <efxpt:pin name="hbc_ck_N_LO" type_name="CK_N_LO" is_bus="false"/>
                <efxpt:pin name="hbc_rwds_OUT_HI" type_name="RWDS_OUT_HI" is_bus="true"/>
                <efxpt:pin name="hbc_rwds_OUT_LO" type_name="RWDS_OUT_LO" is_bus="true"/>
                <efxpt:pin name="hbc_rwds_IN_HI" type_name="RWDS_IN_HI" is_bus="true"/>
                <efxpt:pin name="hbc_rwds_IN_LO" type_name="RWDS_IN_LO" is_bus="true"/>
                <efxpt:pin name="hbc_rwds_OE" type_name="RWDS_OE" is_bus="true"/>
                <efxpt:pin name="hbc_dq_OUT_HI" type_name="DQ_OUT_HI" is_bus="true"/>
                <efxpt:pin name="hbc_dq_OUT_LO" type_name="DQ_OUT_LO" is_bus="true"/>
                <efxpt:pin name="hbc_dq_IN_HI" type_name="DQ_IN_HI" is_bus="true"/>
                <efxpt:pin name="hbc_dq_IN_LO" type_name="DQ_IN_LO" is_bus="true"/>
                <efxpt:pin name="hbc_dq_OE" type_name="DQ_OE" is_bus="true"/>
            </efxpt:gen_pin>
        </efxpt:hyper_ram>
    </efxpt:hyper_ram_info>`
    }

    private convert_to_SVF_TrionX(
        inputFile: string,
        destSVFFile: string,
        idcode: string,
        freq: string,
        sdrSize: number,
        enterUserMode: boolean,
        chainInfo: ChainInfo
    ): void {
        const N = sdrSize;

        // 读取 HEX 文件并转换为位数组（模拟 bitarray）
        const hexContent = fs.readFileSync(inputFile, 'utf-8').split(/\r?\n/);
        const numBits = this.get_bitstream_num_bits(inputFile);

        const arr: boolean[] = [];
        hexContent.forEach(line => {
            const byte = parseInt(line, 16);
            const bits = byte.toString(2).padStart(8, '0');
            bits.split('').forEach(b => arr.push(b === '1'));
        });

        // 处理 JTAG chain 信息
        const [len_hir, len_tir, len_hdr, len_tdr] = chainInfo;

        const generateTDI = (length: number, bit: '0' | '1'): string => {
            if (length === 0) return '';
            const binary = Array(length).fill(bit).join('');
            const decimal = parseInt(binary, 2);
            return ` TDI (${decimal.toString(16).toUpperCase()})`;
        };

        const hir_tdi = generateTDI(len_hir, '1');
        const tir_tdi = generateTDI(len_tir, '1');
        const hdr_tdi = generateTDI(len_hdr, '0');
        const tdr_tdi = generateTDI(len_tdr, '0');

        // 构建 SVF 内容
        const svfLines: string[] = [
            'TRST OFF;',
            'ENDIR IDLE;',
            'ENDDR IDLE;',
            'STATE RESET;',
            'STATE IDLE;',
            `FREQUENCY ${freq} HZ;`,
            `TIR ${len_tir}${tir_tdi};`,
            `HIR ${len_hir}${hir_tdi};`,
            `TDR ${len_tdr}${tdr_tdi};`,
            `HDR ${len_hdr}${hdr_tdi};`,
            '// ',
            '// Check idcode',
            'SIR 5 TDI (3);',
            `SDR 32 TDI (00000000) TDO (${idcode}) MASK (ffffffff);`,
            '// ',
            '// Enter programming mode',
            'SIR 5 TDI (4);'
        ];

        if (idcode.toUpperCase() === '10660A79' || idcode.toUpperCase() === '10661A79') {
            svfLines.push('RUNTEST RESET 100 TCK;', 'SIR 5 TDI (4);');
        }

        svfLines.push(
            '// ',
            '// Begin bitstream',
            '// ',
            'ENDDR DRPAUSE;',
            'HDR 0;',
            `TDR ${len_tdr}${tdr_tdi};`
        );

        // 生成 SDR 命令
        let currBit = 0;
        while (currBit < numBits) {
            const demarcIndex = Math.min(currBit + N, numBits);
            const lineLength = demarcIndex - currBit;

            let currLine = '';
            let nibbleBuffer = '';
            for (let i = currBit; i < demarcIndex; i++) {
                nibbleBuffer = (arr[i] ? '1' : '0') + nibbleBuffer;
                if (nibbleBuffer.length === 4) {
                    currLine += parseInt(nibbleBuffer, 2).toString(16).toUpperCase();
                    nibbleBuffer = '';
                }
            }

            if (nibbleBuffer.length > 0) {
                currLine += parseInt(nibbleBuffer.padEnd(4, '0'), 2).toString(16).toUpperCase();
            }

            svfLines.push(`SDR ${lineLength} TDI (${currLine.split('').reverse().join('')});`);
            currBit = demarcIndex;
        }

        // 添加额外 TCK
        const NUM_EXTRA_TCK = 2000;
        const NUM_EXTRA_TCK_LOOPS = (NUM_EXTRA_TCK / N) + 1;
        svfLines.push('// Extra clock ticks in SDR state');
        const tdiPattern = '0'.repeat(Math.ceil(N / 4));
        for (let i = 0; i < NUM_EXTRA_TCK_LOOPS; i++) {
            svfLines.push(`SDR ${N} TDI (${tdiPattern});`);
        }

        // 用户模式处理
        svfLines.push('// ');
        if (enterUserMode) {
            svfLines.push(
                '// Enter user mode',
                'SIR 5 TDI (7);',
                'RUNTEST 100 TCK;'
            );
        } else {
            svfLines.push(
                '// Enter user mode -- DISABLED PER REQUEST',
                '// SIR 5 TDI (7);',
                '// RUNTEST 100 TCK;'
            );
        }

        // 写入文件
        fs.writeFileSync(destSVFFile, svfLines.join('\n'));
    }

    private get_bitstream_num_bits(input_file: string): integer {
        let ext = hdlPath.extname(input_file);
        let num_bytes = 0;
        if (ext === '.hex' || ext == '.bit') {
            const lines = fs.readFileSync(input_file, 'utf-8').split(/\r?\n/);
            num_bytes = lines.filter(line => {
                const trimmed = line.trim();

                // 有效性检查条件（根据你的 HEX 格式调整）
                return trimmed.length > 0 &&                // 非空行
                    trimmed.length >= 2 &&              // 每行 2 个字符（例如 "1A"）
                    /^[0-9A-Fa-f]{2}$/.test(trimmed);    // 合法 HEX 字符
            }).length;
        } else if (ext === '.bin') {
            num_bytes = fs.statSync(input_file).size;
        }

        return num_bytes * 8;
    }

    public updateEfinixPath(): string {
        const efinixBinFolder = vscode.workspace.getConfiguration('digital-ide.prj.efinix.install').get<string>('path') || '';
        if (hdlFile.isDir(efinixBinFolder)) {
            let efinixPath = hdlPath.join(hdlPath.toSlash(efinixBinFolder), 'efx_run');
            if (opeParam.os === 'win32') {
                efinixPath += '.bat';
            }
            return efinixPath;
        } else {
            // 没有设置 Efinix bin 文件夹，就认为用户已经把对应的路径加入环境变量了
            return 'efx_run';
        }
    }
}