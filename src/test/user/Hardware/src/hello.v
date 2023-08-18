// VHDL code for a 2-to-1 multiplexer

module mux2to1(
        input wire a,
        input wire b,
        input wire sel,
        output wire outp
    );

    // outports wire
wire [XY_BITS-1:0] 	x_o;
wire [XY_BITS-1:0] 	y_o;
wire [PH_BITS-1:0] 	phase_out;
wire               	valid_out;

Cordic u_Cordic(
	.clk       	( clk        ),
	.RST       	( RST        ),
	.x_i       	( x_i        ),
	.y_i       	( y_i        ),
	.phase_in  	( phase_in   ),
	.x_o       	( x_o        ),
	.y_o       	( y_o        ),
	.phase_out 	( phase_out  ),
	.valid_in  	( valid_in   ),
	.valid_out 	( valid_out  )
);



    assign outp = sel == 1'b0 ? a : b;

endmodule
