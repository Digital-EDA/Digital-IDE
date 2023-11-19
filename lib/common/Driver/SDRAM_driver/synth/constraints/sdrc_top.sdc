# Top Level Design Parameters

# Clocks

create_clock -period 6.000000 -waveform {0.000000 3.000000} wb_clk_i
create_clock -period 10.000000 -waveform {0.000000 5.000000} sdram_clk

# False Paths Between Clocks


# False Path Constraints

set_false_path -from {wb_rst_i} -to {*}
set_false_path -from {sdram_resetn} -to {*}

# Maximum Delay Constraints


# Multicycle Constraints


# Virtual Clocks
# Output Load Constraints
# Driving Cell Constraints
# Wire Loads
# set_wire_load_mode top

# Other Constraints
set_input_delay 0.000 -clock {wb_clk_i} {wb_stb_i}
set_output_delay 0.000 -clock {wb_clk_i} {wb_ack_o}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[0]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[1]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[2]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[3]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[4]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[5]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[6]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[7]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[8]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[9]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[10]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[11]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[12]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[13]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[14]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[15]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[16]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[17]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[18]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[19]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[20]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[21]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[22]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[23]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[24]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[25]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[26]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[27]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[28]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_addr_i[29]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_we_i}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[0]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[1]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[2]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[3]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[4]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[5]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[6]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[7]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[8]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[9]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[10]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[11]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[12]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[13]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[14]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[15]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[16]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[17]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[18]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[19]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[20]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[21]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[22]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[23]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[24]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[25]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[26]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[27]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[28]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[29]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[30]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_dat_i[31]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_sel_i[0]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_sel_i[1]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_sel_i[2]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_sel_i[3]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[0]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[1]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[2]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[3]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[4]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[5]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[6]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[7]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[8]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[9]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[10]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[11]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[12]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[13]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[14]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[15]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[16]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[17]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[18]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[19]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[20]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[21]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[22]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[23]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[24]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[25]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[26]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[27]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[28]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[29]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[30]}
set_output_delay 3.000 -clock {wb_clk_i} {wb_dat_o[31]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_cyc_i}
set_input_delay 0.000 -clock {wb_clk_i} {wb_cti_i[0]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_cti_i[1]}
set_input_delay 0.000 -clock {wb_clk_i} {wb_cti_i[2]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_cs_n}
set_output_delay 5.000 -clock {sdram_clk} {sdr_cke}
set_output_delay 5.000 -clock {sdram_clk} {sdr_ras_n}
set_output_delay 5.000 -clock {sdram_clk} {sdr_cas_n}
set_output_delay 5.000 -clock {sdram_clk} {sdr_we_n}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dqm[0]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dqm[1]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_ba[0]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_ba[1]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[0]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[1]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[2]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[3]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[4]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[5]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[6]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[7]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[8]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[9]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[10]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_addr[11]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[0]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[0]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[1]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[1]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[2]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[2]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[3]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[3]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[4]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[4]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[5]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[5]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[6]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[6]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[7]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[7]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[8]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[8]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[9]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[9]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[10]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[10]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[11]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[11]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[12]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[12]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[13]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[13]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[14]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[14]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_dq[15]}
set_input_delay 5.000 -clock {sdram_clk} {sdr_dq[15]}
set_output_delay 5.000 -clock {sdram_clk} {sdr_init_done}
