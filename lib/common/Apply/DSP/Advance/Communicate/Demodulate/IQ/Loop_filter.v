`timescale 1ns / 1ps
module Loop_filter (
    input                clk_sys,
    input                rst_n,
    input  signed [27:0] Xdin,
    output signed [27:0] Ydout
);

parameter k1 = 12498;
parameter k2 = 4430400;

reg [2:0] cnt;
reg signed [27:0]   Ydin_1;
reg signed [27:0]   Ydout_buf;
always@(posedge clk_sys) begin
    if(!rst_n) 
        cnt <= 3'd0;
    else
        cnt <= cnt + 3'd1;
end
always@(posedge clk_sys) begin
    if(!rst_n) begin
        Ydin_1 <= 28'd0;
        Ydout_buf <= 28'd0;
    end
    else if(cnt == 3'd3)
        Ydin_1 = Ydin_1 + Xdin/k1;
    else if(cnt == 3'd4)
        Ydout_buf <= Ydin_1 + Xdin/k2;
end
assign Ydout = Ydout_buf;
endmodule
