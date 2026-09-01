`timescale 1ns / 1ps
module manchester (
        input  clock,
        input  reset,
        input  sig_in,
        output sig_out
    );

    reg ck;
    reg ck_r;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ck <= 0;
            ck <= 0;
        end
        else begin            
            ck <= ck_r;
            ck <= ~ ck;
        end
    end

    assign sig_out = ck ^ sig_in;

endmodule
