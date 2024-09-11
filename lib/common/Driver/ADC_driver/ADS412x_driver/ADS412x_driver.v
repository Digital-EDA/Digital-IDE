`timescale 1ns / 1ps

module ADS412x_driver(
    // input         sys_rst_n,
    input         user_clk,
    output [11:0] user_rd_data,
    
    output        adc_sclk,  // sclk 
    output        adc_sdata, // sda
    output        adc_reset,
    output        adc_sen,
    input  [11:0] adc_data,
    input         adc_clk,
    output        adc_samp_clk
);

wire sys_rst_n;
assign sys_rst_n = 1;

wire        adc_config_done;
wire        rst_n;
reg  [11:0] adc_data_r;
reg  [11:0] adc_data_rr;

assign adc_samp_clk=user_clk;
assign rst_n = ((adc_config_done == 1'b1) && (sys_rst_n == 1'b1)) ? 1'b1 : 1'b0;

assign user_rd_data=adc_data_rr;////

ADC_CFG u_ADS4128_CFG(
        .clk      ( user_clk        ),
        .rstn     ( sys_rst_n       ),
        .sclk     ( adc_sclk        ),
        .sdata    ( adc_sdata       ),
        .sen      ( adc_sen         ),
        .adc_rst  ( adc_reset       ),
        .cfg_done ( adc_config_done )
);

always @ (posedge adc_clk) begin
    if (rst_n == 1'b0) begin
        adc_data_r  <= 12'h000;
        adc_data_rr <= 12'h000;
    end
    else begin
        adc_data_r  <= adc_data;
        adc_data_rr <= adc_data_r + 12'b1000_0000_0000;
    end
end

endmodule
