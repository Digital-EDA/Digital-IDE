import * as vscode from 'vscode';
import { ChildProcessWithoutNullStreams, exec, spawn } from 'child_process';
import * as fspath from 'path';
import * as fs from 'fs';

import { AbsPath, opeParam, PrjInfo } from '../../global';
import { hdlParam } from '../../hdlParser/core';
import { hdlFile, hdlDir, hdlPath } from '../../hdlFs';
import { PropertySchema } from '../../global/propertySchema';

import { XilinxIP } from '../../global/enum';
import { HardwareOutput, MainOutput, ReportType } from '../../global/outputChannel';
import { debounce, getPIDsWithName, killProcess } from '../../global/util';
import { t } from '../../i18n';
import { HdlFileProjectType } from '../../hdlParser/common';

import { parseString, Builder, processors } from 'xml2js';

const syn = `  <efx:synthesis tool_name="efx_map">
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

const pnr = `  <efx:place_and_route tool_name="efx_pnr">
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

const bit = `  <efx:bitstream_generation tool_name="efx_pgm">
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

const debug = `  <efx:debugger>
    <efx:param name="work_dir" value="work_dbg" value_type="e_string"/>
    <efx:param name="auto_instantiation" value="off" value_type="e_bool"/>
    <efx:param name="profile" value="NONE" value_type="e_string"/>
  </efx:debugger>`;

const security = `  <efx:security>
    <efx:param name="randomize_iv_value" value="on" value_type="e_bool"/>
    <efx:param name="iv_value" value="" value_type="e_string"/>
    <efx:param name="enable_bitstream_encrypt" value="off" value_type="e_bool"/>
    <efx:param name="enable_bitstream_auth" value="off" value_type="e_bool"/>
    <efx:param name="encryption_key_file" value="NONE" value_type="e_string"/>
    <efx:param name="auth_key_file" value="NONE" value_type="e_string"/>
  </efx:security>`;


export class EfinityOperation {
    // config: Record<string, any>;
    constructor() {

    }

    
}