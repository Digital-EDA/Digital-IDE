# Syntheis command format
#"-from" objects must be of type clock (c:), port (p:), inst (i:), or pin (t:)
#
#166MHz - Application CLOCK
#set APP_CLK_PER             6.0 
#set APP_CLK_HALF_PER         [expr APP_CLK_PER]


#100MHz - SDRAM Clock
#set SDR_CLK_PER             10.0 
#set SDI_CLK_HALF_PER         [expr $SDR_CLK_PERR/2]


####################################
# Clear Application Clock : 200Mhz
####################################

create_clock -name wb_clk_i -period 6 -waveform {0 3} p:wb_clk_i
#set_clock_uncertainty -max 0.2 [get_clocks wb_clk_i]
#set_clock_uncertainty -min  0.1 [get_clocks wb_clk_i]
#set_clock_latency 2.0 [get_clocks wb_clk_i]

########################################
# Create SDRAM Clock to 100Mhz
########################################
create_clock -name sdram_clk -period 10 -waveform {0 5} p:sdram_clk
#set_clock_uncertainty -max 0.2 [get_clocks sdram_clk]
#set_clock_uncertainty -min  0.1 [get_clocks sdram_clk]
#set_clock_latency 2.0 [get_clocks sdram_clk]


###########################################
# Set false path between application and SDRAM Clock
##########################################
set_false_path -from c:wb_clk_i  -to   c:sdram_clk
set_false_path -to   c:wb_clk_i  -from c:sdram_clk


########################################
# Set false path through reset
########################################
set_false_path -from p:wb_rst_i
set_false_path -from p:sdram_resetn


########################################
# Set False path to all the configuration input
########################################

#set_false_path -from p:{cfg_colbits[*] cfg_req_depth[*] cfg_sdr_cas[*]}
#set_false_path -from p:{cfg_sdr_en cfg_sdr_mode_reg[*] cfg_sdr_rfmax[*]] 
#set_false_path -from p:{cfg_sdr_rfsh[*] cfg_sdr_tras_d[*] cfg_sdr_trcar_d[*]}
#set_false_path -from p:{cfg_sdr_trcd_d[*] cfg_sdr_trp_d[*] cfg_sdr_twr_d[*]}
#set_false_path -from p:cfg_sdr_width[*]


########################################
# Application Port Input Contraints
# Since Application Signal will be internally terminated and
# there is will not be any additional FPGA pad delay of 3ns.
#  So input delay constraint changed form 3ns to 0ns
# 
#######################################
#set_input_delay 3 -max [ wb_stb_i wb_addr_i wb_we_i wb_dat_i wb_sel_i wb_cyc_i wb_cti_i] -clock wb_clk_i
set_input_delay 0 -max { wb_stb_i wb_addr_i[*] wb_we_i wb_dat_i[*] wb_sel_i[*] wb_cyc_i wb_cti_i[*]} -clock wb_clk_i
set_input_delay 0.5  -min { wb_stb_i wb_addr_i[*] wb_we_i wb_dat_i[*] wb_sel_i[*] wb_cyc_i wb_cti_i[*]} -clock wb_clk_i


########################################
# Application Port Output Contraints
# Since Application Signal will be internally terminstated and
# there will not be addiitional FPGA pad delay of 3ns.
#  So output delat contraints are changed from 3ns to 0ns
#######################################

#set_output_delay 3   -max [ wb_ack_o wb_dat_o ]  -clock wb_clk_i
set_output_delay 0    -max wb_ack_o   -clock wb_clk_i
set_output_delay 3    -max {wb_dat_o[*]}   -clock wb_clk_i
set_output_delay 0.5  -min wb_ack_o  -clock  wb_clk_i
set_output_delay 0.5  -min {wb_dat_o[*]}  -clock  wb_clk_i



#######################################
# SDRAM Input Contraints
# 10 - 2 = 8ns
#######################################

set_input_delay 5    -max  {sdr_dq[*]} -clock sdram_clk
set_input_delay 0.5  -min  {sdr_dq[*]} -clock sdram_clk


#######################################
# Set the SDRAM Output delay constraints
#######################################

set_output_delay 5 -max { sdr_cs_n sdr_cke sdr_ras_n sdr_cas_n sdr_we_n sdr_dqm[*] sdr_ba[*] sdr_addr[*] sdr_dq[*] }  -clock sdram_clk
set_output_delay -2  -min { sdr_cs_n sdr_cke sdr_ras_n sdr_cas_n sdr_we_n sdr_dqm[*] sdr_ba[*] sdr_addr[*] sdr_dq[*] }  -clock sdram_clk



########################################
# Misc
#########################################

set_output_delay 5   -max { sdr_init_done } -clock sdram_clk
set_output_delay -2  -min { sdr_init_done } -clock sdram_clk