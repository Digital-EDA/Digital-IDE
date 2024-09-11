`timescale 1ns / 1ps
module mseq #(  
    parameter W = 4'd4,
    parameter POLY = 5'b10011
) (   
    input  clk,
    input  rst_n,
    output mseq_out
);

reg [W-1:0] sreg = 8'b11111111;
assign mseq_out = sreg[0];

always@(posedge clk or posedge rst_n) begin
    if(~rst_n) 
        sreg <= 1'b1;
    else begin
        if(mseq_out) 
            sreg <= (sreg >> 1) ^ (POLY >> 1);
        else 
            sreg <= sreg >> 1;
    end
end

endmodule
