module Line_Shift_RAM #(
	parameter  RAM_Length = 640,	//640*480
    parameter  DATA_WIDTH = 8
) (
	input	                   clken,
	input	                   clock,
	input	[DATA_WIDTH-1:0]   shiftin,
	output	[DATA_WIDTH-1:0]   taps0x,
	output	[DATA_WIDTH-1:0]   taps1x
);

RAMshift_taps #(
	.TOTAL_RAM_Length (RAM_Length),
	.DATA_WIDTH (DATA_WIDTH)
) RAMshfit_taps_u1 (
	.clken(clken), 
	.clock(clock),
	.Delay_Length(RAM_Length),
	.shiftin(shiftin),
	.shiftout(taps0x)
);

RAMshift_taps #(
	.TOTAL_RAM_Length (RAM_Length),
	.DATA_WIDTH (DATA_WIDTH)
) RAMshfit_taps_u2 (
	.clken(clken), 
	.clock(clock),
	.Delay_Length(RAM_Length),
	.shiftin(taps0x),
	.shiftout(taps1x)
);
endmodule