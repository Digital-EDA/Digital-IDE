`timescale 1ns/100ps

module fft #(
	parameter REAL_WIDTH = 18,
	parameter IMGN_WIDTH = 18,
	parameter TOTAL_STAGE = 11
) (
	input                    iclk,
	input                    rst_n,

	input                    ien,
	input  [TOTAL_STAGE-1:0] iaddr,
	input  [REAL_WIDTH-1:0]  iReal,
	input  [IMGN_WIDTH-1:0]  iImag,

	output                   oen,
	output [TOTAL_STAGE-1:0] oaddr,
	output [REAL_WIDTH-1:0]  oReal,
	output [IMGN_WIDTH-1:0]  oImag
);
	
localparam INTER_MODU_WIRE_NUM = ((TOTAL_STAGE-1)/2);
localparam CPLX_WIDTH = REAL_WIDTH + IMGN_WIDTH;

wire [CPLX_WIDTH -1:0] data_end;
wire [TOTAL_STAGE-1:0] addr_end;

wire                   en_w   [INTER_MODU_WIRE_NUM:0];
wire [CPLX_WIDTH -1:0] data_w [INTER_MODU_WIRE_NUM:0];
wire [TOTAL_STAGE-1:0] addr_w [INTER_MODU_WIRE_NUM:0];

assign en_w  [INTER_MODU_WIRE_NUM] = ien;
assign addr_w[INTER_MODU_WIRE_NUM] = iaddr;
assign data_w[INTER_MODU_WIRE_NUM] = {iReal, iImag};

generate
genvar gv_stg;
for(gv_stg=TOTAL_STAGE; gv_stg>=2; gv_stg=gv_stg-2) begin : stagX
fft_stage #( 
	.REAL_WIDTH(REAL_WIDTH),
	.IMGN_WIDTH(IMGN_WIDTH),
	.TOTAL_STAGE(TOTAL_STAGE),
	.FFT_STG(gv_stg) 
)stgX_inst (
	.iclk(iclk),
	.rst_n(rst_n),
	.iaddr(addr_w[((gv_stg-1)/2)]),
	.idata(data_w[((gv_stg-1)/2)]),
	.ien(en_w[((gv_stg-1)/2)]),
	.oaddr(addr_w[((gv_stg-1)/2)-1]),
	.odata(data_w[((gv_stg-1)/2)-1]),
	.oen(en_w[((gv_stg-1)/2)-1])
);
end
if(TOTAL_STAGE[0]) begin : BF_stg1
	BF_stg1 #( 
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TOTAL_STAGE(TOTAL_STAGE),
		.FFT_STG(1) 
	)stg1_inst (
		.iclk(iclk),
		.rst_n(rst_n),
		.ien(en_w[0]),
		.iaddr(addr_w[0]),
		.idata(data_w[0]),
		.oen(oen),
		.oaddr(addr_end),
		.odata(data_end)
	);
	end
endgenerate

generate	// bit_reverse
genvar index;
	for(index=0; index<TOTAL_STAGE; index=index+1) begin: bit_reverse
		assign oaddr[TOTAL_STAGE-index-1] = addr_end[index];
	end
endgenerate
assign oReal = data_end[CPLX_WIDTH:REAL_WIDTH];
assign oImag = data_end[IMGN_WIDTH:0];

endmodule
