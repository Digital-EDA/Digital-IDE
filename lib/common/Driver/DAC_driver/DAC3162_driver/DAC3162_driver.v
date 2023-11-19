`timescale 1ns / 1ps

module DAC3162_driver (
    input               clk_in,
    input               clk_div,

    input    [11:0]     DA3162_CH1,
    input    [11:0]     DA3162_CH2,
    /*DAC*/
    output   [11:0]     dac_data_p,
    output   [11:0]     dac_data_n,
    output              dac_clk_p,
    output              dac_clk_n,
    output              dac_sleep
);

assign dac_sleep = 1'd1;

reg  [11:0] dac_a_int  = 0;
reg  [11:0] dac_b_int  = 0;
reg  [11:0] dac_a_intt = 0;
reg  [11:0] dac_b_intt = 0;

reg  [1:0]  cnt_clk = 0;
reg  [3:0]  power_on_rst_cnt = 4'h0;
reg         power_on_rst = 1;

always @ (posedge clk_in) begin
    dac_a_int<=DA3162_CH1 + 12'b100000000000;
    dac_b_int<=DA3162_CH2 + 12'b100000000000;
    dac_a_intt<=dac_a_int;
    dac_b_intt<=dac_b_int;
end

always @ (posedge clk_div) begin
    if (power_on_rst_cnt == 4'hf) begin
        power_on_rst_cnt <= power_on_rst_cnt;
        power_on_rst <= 0;
    end
    else begin
        power_on_rst_cnt <= power_on_rst_cnt + 1;
        power_on_rst <= 1;
    end
end

LVDS_DDR_clk  DAC3162_clk_u (
    .data_out_from_device ( 4'b0101      ), // input [3:0] data_out_from_device
    .data_out_to_pins_p   ( dac_clk_p    ), // output [0:0] data_out_to_pins_p
    .data_out_to_pins_n   ( dac_clk_n    ), // output [0:0] data_out_to_pins_n
    .clk_in               ( clk_in       ), // input clk_in                            
    .clk_div_in           ( clk_div      ), // input clk_div_in                        
    .io_reset             ( power_on_rst )  // input io_reset
); 

// input  [47:0] data_out_from_device
LVDS_DDR_data  DAC3162_data_u (                                            
    .clk_in               ( clk_in        ), // input clk_in
    .clk_div_in           ( clk_div       ), // input clk_div_in
    .data_out_from_device ({dac_a_int,dac_b_int,dac_a_intt,dac_b_intt}  ), 
    .data_out_to_pins_p   ( dac_data_p    ), // output [11:0] data_out_to_pins_p
    .data_out_to_pins_n   ( dac_data_n    ), // output [11:0] data_out_to_pins_n
    .io_reset             ( power_on_rst  )  // input io_reset
); 

endmodule
