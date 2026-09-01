module Line_ShiftRAM #(
	parameter  RAM_Length = 640,	//640*480
    parameter  DATA_WIDTH = 8
) (
	input	                   clken,
	input	                   clock,
	input 					   reset,
	input	[DATA_WIDTH-1:0]   shiftin,
	output	[DATA_WIDTH-1:0]   taps0x,
	output	[DATA_WIDTH-1:0]   taps1x
);

wire pvalid_d;
shiftTaps #(
    .THRES ( 'd512 ),
    .WIDTH ( DATA_WIDTH ),
    .SHIFT ( RAM_Length ))
 u0_shiftTaps (
    .clock                   ( clock                     ),
    .reset                   ( reset                     ),
    .ivalid                  ( clken                    ),
    .shiftin                 ( shiftin    ),

    .ovalid                  ( pvalid_d                    ),
    .shiftout                ( taps0x  [DATA_WIDTH - 1 : 0] )
);


shiftTaps #(
    .THRES ( 'd512 ),
    .WIDTH ( DATA_WIDTH ),
    .SHIFT ( RAM_Length ))
 u1_shiftTaps (
    .clock                   ( clock                     ),
    .reset                   ( reset                     ),
    .ivalid                  ( clken                    ),
    .shiftin                 ( taps0x   [DATA_WIDTH - 1 : 0] ),

    .ovalid                  ( ovalid                    ),
    .shiftout                ( taps1x  [DATA_WIDTH - 1 : 0] )
);

endmodule