module circuit(
   input         clk,
   input         reset,
   input  [7:0]  fmin,
   output [11:0] dmout
);

wire [11:0]   d1;
wire [11:0]   d2;
wire [7:0]    dout;
wire [7:0]    output_xhdl0;
   
multiplier I1(
	.clk(clk), 
	.reset(reset), 
	.input1(fmin), 
	.input2(dout), 
	.output_xhdl0(output_xhdl0)
);

fir I4(
	.clock(clk), 
	.reset(reset), 
	.data_in(d1), 
	.data_out(dmout)
);

loop_filter I3(
	.clk(clk), 
	.reset(reset), 
	.c(output_xhdl0), 
	.d1(d1), 
	.d2(d2)
);

nco I2(
	.clk(clk), 
	.reset(reset), 
	.din(d2), 
	.dout(dout)
);
   
endmodule
