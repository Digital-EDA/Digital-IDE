`timescale 1ns/100ps

module BF_op #( 
	parameter  REAL_WIDTH = 18,
	parameter  IMGN_WIDTH = 18,
	localparam CPLX_WIDTH = REAL_WIDTH + IMGN_WIDTH
) (
	input  [CPLX_WIDTH - 1 : 0] ia,
	input  [CPLX_WIDTH - 1 : 0] ib,
	output [CPLX_WIDTH - 1 : 0] oa,
	output [CPLX_WIDTH - 1 : 0] ob
);

assign oa[CPLX_WIDTH-1:REAL_WIDTH] = $signed(ia[CPLX_WIDTH-1:REAL_WIDTH]) + $signed(ib[CPLX_WIDTH-1:REAL_WIDTH]);
assign oa[IMGN_WIDTH-1:0]          = $signed(ia[IMGN_WIDTH-1:0])          + $signed(ib[IMGN_WIDTH-1:0]);

assign ob[CPLX_WIDTH-1:REAL_WIDTH] = $signed(ia[CPLX_WIDTH-1:REAL_WIDTH]) - $signed(ib[CPLX_WIDTH-1:REAL_WIDTH]);
assign ob[IMGN_WIDTH-1:0]          = $signed(ia[IMGN_WIDTH-1:0])          - $signed(ib[IMGN_WIDTH-1:0]);

endmodule
