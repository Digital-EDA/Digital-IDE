`timescale 1ns / 1ps
module measure
(
    input           clk_sys,
    input           clk_samp,
    input           rst_n,
    input           mearsure_start,
    input [11:0]    AD_data,
    output          measure_done_q,
    output [21:0]   data_out
);
parameter           cnt_clear = 22'd255;
reg                 clk_samp_buf0;
reg                 clk_samp_buf1;
wire                clk_samp_impluse = clk_samp_buf0 & ~clk_samp_buf1;//采样脉冲信号
wire [21:0]         mult_data;
reg [16:0]          cnt;
reg [39:0]          sig_energy;
reg [21:0]          data_out_buf;
reg                 measure_en;
wire                measure_done  = (cnt == cnt_clear) ? 1'b1:1'b0;
assign              measure_done_q = measure_done;
always@(posedge clk_sys)
begin
    clk_samp_buf0 <= clk_samp;
    clk_samp_buf1 <= clk_samp_buf0;
end
always@(posedge clk_sys)
begin
    if(!rst_n)
    begin
        measure_en <= 1'b0;
    end
    else if(mearsure_start)
        measure_en <= 1'b1;
    else if(measure_done)
        measure_en <= 1'b0;
    else
        measure_en <= measure_en;
end
always@(posedge clk_sys)
begin
    if(!rst_n)
    begin
        sig_energy <= 40'd0;
        cnt <= 17'd0;
        data_out_buf <= 22'd0;
    end
    else if(cnt == cnt_clear)
    begin
        sig_energy <= 40'd0;
        data_out_buf <= sig_energy[39:8];
        cnt <= 17'd0;
    end
    else if(clk_samp_impluse && measure_en)
    begin
        cnt <= cnt + 17'd1;
        sig_energy <= sig_energy + mult_data;
    end
    else
    begin
        sig_energy <= sig_energy;
        data_out_buf <= data_out_buf;
        cnt <= cnt;
    end
end
mult1 mult1_inst
(
.A(AD_data),
.B(AD_data),
.P(mult_data),
.CLK(clk_sys),
.CE(clk_samp_impluse)
);
assign data_out  = data_out_buf;
endmodule
