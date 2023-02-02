`timescale 1 ps / 1 ps
module cmpl_mult #( 
	parameter REAL_WIDTH  = 18,
	parameter IMGN_WIDTH  = 18,
	localparam CPLX_WIDTH = REAL_WIDTH + IMGN_WIDTH
) (
	input	                  clock,
	input	[REAL_WIDTH-1:0]  dataa_real,
	input	[IMGN_WIDTH-1:0]  dataa_imag,
	input	[REAL_WIDTH-1:0]  datab_real,
	input	[IMGN_WIDTH-1:0]  datab_imag,
	output	[CPLX_WIDTH-1:0]  result_real,
	output	[CPLX_WIDTH-1:0]  result_imag
);


reg signed [CPLX_WIDTH-1:0] outr = 0;
reg signed [CPLX_WIDTH-1:0] outi = 0;
always@(posedge clock) begin
	outr <= $signed(dataa_real) * $signed(datab_real) - $signed(dataa_imag) * $signed(datab_imag); 
	outi <= $signed(dataa_real) * $signed(datab_imag) + $signed(dataa_imag) * $signed(datab_real); 
end

assign result_imag = outi;
assign result_real = outr;

endmodule