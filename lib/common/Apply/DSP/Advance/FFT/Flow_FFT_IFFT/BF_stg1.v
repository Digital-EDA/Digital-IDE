`timescale 1ns/100ps
module BF_stg1 #( 
	parameter  FFT_STG = 7,
	parameter  REAL_WIDTH  = 18,
	parameter  IMGN_WIDTH  = 18,
	parameter  TOTAL_STAGE = 11,
	localparam CPLX_WIDTH  = REAL_WIDTH + IMGN_WIDTH
) (
	input iclk,
	input rst_n,

	input                      ien,
	input  [TOTAL_STAGE-1 : 0] iaddr,
	input  [CPLX_WIDTH -1 : 0] idata,

	output                     oen,
	output [TOTAL_STAGE-1 : 0] oaddr,
	output [CPLX_WIDTH -1 : 0] odata
);
	
localparam TOTAL_ADDR_MAX   = { TOTAL_STAGE { 1'b1 } };
localparam STG_MAX          = { FFT_STG { 1'b1 } };
localparam STG_HALFMAX      = ( STG_MAX >> 1 );

reg [CPLX_WIDTH - 1 : 0] r [STG_HALFMAX:0];
integer i;
initial begin
   for (i = 0; i<=STG_HALFMAX; i=i+1) begin
		r[i] = 0;
	end
end



reg                   dump = 0;
reg [FFT_STG - 1 : 0] dump_cnt = 0;
always @(posedge iclk) begin
	if(iaddr[FFT_STG-1:0] == STG_MAX && ien) begin
		dump <= 1'b1;
		dump_cnt <= 0;
	end
	else if(dump) begin
		if(dump_cnt == STG_HALFMAX) dump <= 1'b0;
		dump_cnt <= dump_cnt + 1'b1;
	end
end

wire   with_dump;
assign with_dump = dump;

wire [CPLX_WIDTH - 1 : 0] bf_ia;
wire [CPLX_WIDTH - 1 : 0] bf_ib;
wire [CPLX_WIDTH - 1 : 0] bf_oa;
wire [CPLX_WIDTH - 1 : 0] bf_ob;
assign bf_ia = r[STG_HALFMAX];
assign bf_ib = idata;
BF_op #(
	.REAL_WIDTH(REAL_WIDTH),
	.IMGN_WIDTH(IMGN_WIDTH)
) bf0 (
	.ia(bf_ia),
	.ib(bf_ib),
	.oa(bf_oa),
	.ob(bf_ob)
);

wire [CPLX_WIDTH - 1 : 0] wdata_in;
integer index;
always @(posedge iclk) begin
	if(ien) r[0] <= wdata_in;
	for(index = STG_HALFMAX; index > 0; index=index-1) 
		r[index] <= r[index-1];
end

reg                     oen_r   = 0;
reg [TOTAL_STAGE-1 : 0] oaddr_r = 0;
reg [CPLX_WIDTH -1 : 0] odata_r = 0;
wire   is_load;
wire   is_calc;
assign is_load  = ~iaddr[FFT_STG-1];
assign is_calc  =  iaddr[FFT_STG-1];
assign wdata_in =  is_load ? idata : bf_ob;
always @(posedge iclk) begin
	if(is_calc & ien) begin
		odata_r <= bf_oa;
		oaddr_r <= oaddr_r + 1'b1;
		oen_r <= 1'b1;
	end
	else if((is_load | ~ien) & with_dump) begin
		odata_r <= r[STG_HALFMAX];
		oaddr_r <= oaddr_r + 1'b1;
		oen_r <= 1'b1;
	end
	else begin
		odata_r <= 0;
		oaddr_r <= TOTAL_ADDR_MAX;
		oen_r <= 1'b0;
	end
end
assign odata = odata_r;
assign oaddr = oaddr_r;
assign oen = oen_r;

endmodule
