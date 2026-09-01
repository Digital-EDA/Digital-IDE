`timescale 1ns / 1ps
module RmsMeas #(
        parameter WINDOW = 50,
        parameter IWIDTH = 12,
        parameter OWIDTH = $clog2(WINDOW)+IWIDTH*2
    ) (
        input               clock,
        input               reset,

        input               ivalid,
        input  [IWIDTH-1:0] idata,

        output              ovalid,
        output [OWIDTH-1:0] rmsvalue
    );

    localparam  EWIDTH = $clog2(WINDOW)+IWIDTH*2;

    wire [IWIDTH*2-1:0]       power;

    reg  [EWIDTH-1:0]         psum;
    reg  [EWIDTH-1:0]         energy;
    reg  [$clog2(WINDOW)-1:0] count;

    always@(posedge clock) begin
        if(reset) begin
            psum  <= 0;
            count <= 0;
        end
        else begin            
            if (ivalid) begin
                if (count == WINDOW) begin
                    psum <= 0;
                    count <= 0;
                    energy <= psum;
                end
                else begin
                    psum  <= psum  + power;
                    count <= count + 1'b1;
                end
            end
        end
    end

endmodule
