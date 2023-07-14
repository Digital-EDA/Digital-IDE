// VHDL code for a 2-to-1 multiplexer

module mux2to1(
        input wire a,
        input wire b,
        input wire sel,
        output wire outp
    );





    assign outp = sel == 1'b0 ? a : b;

endmodule
