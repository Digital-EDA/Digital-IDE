`timescale 1ns / 1ps
module msequence #(  
        parameter W = 4'd4,
        parameter POLY = 5'b10011
    ) (   
        input  clock,
        input  reset,
        output omseq
    );

    reg [W-1:0] sreg = 8'b11111111;
    assign omseq = sreg[0];

    always@(posedge clock or posedge reset) begin
        if(reset) begin
            sreg <= 1'b1;
        end
        else begin
            if(omseq) begin
                sreg <= (sreg >> 1) ^ (POLY >> 1);
            end
            else begin
                sreg <= sreg >> 1;
            end
        end
    end

endmodule
