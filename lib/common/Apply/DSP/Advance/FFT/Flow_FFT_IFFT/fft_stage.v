`timescale 1ns/100ps

module fft_stage #( 
	parameter  FFT_STG = 7,
	parameter  REAL_WIDTH  = 18,
	parameter  IMGN_WIDTH  = 18,
	parameter  TOTAL_STAGE = 11,
	localparam CPLX_WIDTH  = REAL_WIDTH + IMGN_WIDTH
) (
	input  iclk,
	input  rst_n,

	input                      ien,
	input  [CPLX_WIDTH-1 : 0]  idata,
	input  [TOTAL_STAGE-1 : 0] iaddr,

	output                     oen,
	output [CPLX_WIDTH-1 : 0]  odata,
	output [TOTAL_STAGE-1 : 0] oaddr
);

wire	                  bfX_oen;
wire	[CPLX_WIDTH-1:0]  bfX_odata;
wire	[TOTAL_STAGE-1:0] bfX_oaddr;

wire	                  Trans_I_oen;
wire	[CPLX_WIDTH-1:0]  Trans_I_odata;
wire	[TOTAL_STAGE-1:0] Trans_I_oaddr;

wire	                  bfX_1_oen;
wire	[CPLX_WIDTH-1:0]  bfX_1_data;
wire	[TOTAL_STAGE-1:0] bfX_1_oaddr;

generate 
if(FFT_STG == 2) begin : BF_stg_I2
	BF_stg1 #( 
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TOTAL_STAGE(TOTAL_STAGE),
		.FFT_STG(2) 
	)BF_instI (
		.iclk(iclk),
		.rst_n(rst_n),
		.ien(ien),
		.iaddr(iaddr),
		.idata(idata),
		.oen(bfX_oen),
		.oaddr(bfX_oaddr),
		.odata(bfX_odata)
	);
end
else begin : BF_stgX_I
	BF_stgX #( 
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TOTAL_STAGE(TOTAL_STAGE),
		.FFT_STG(FFT_STG) 
	)BF_instI (
		.iclk(iclk),
		.rst_n(rst_n),
		.ien(ien),
		.iaddr(iaddr),
		.idata(idata),
		.oen(bfX_oen),
		.oaddr(bfX_oaddr),
		.odata(bfX_odata)
	);
end
endgenerate

generate if(FFT_STG > 1) begin : ftrans_conjugate
	ftrans #( 
		.FTRANS_STYLE("conjugate"),    //conjugate
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TOTAL_STAGE(TOTAL_STAGE),
		.FFT_STG(FFT_STG) 
	) ftrans_conjugate_inst (
		.iclk(iclk),
		.ien(bfX_oen),
		.iaddr(bfX_oaddr),
		.idata(bfX_odata),
		.oen(Trans_I_oen),
		.oaddr(Trans_I_oaddr),
		.odata(Trans_I_odata)
	);
end
else begin
	assign oen   = bfX_oen;
	assign oaddr = bfX_oaddr;
	assign odata = bfX_odata;
end
endgenerate

generate 
if(FFT_STG == 3) begin : BF_stg_II2
	BF_stg1 #( 
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TOTAL_STAGE(TOTAL_STAGE),
		.FFT_STG(2) 
	) BF_instII (
		.iclk(iclk),
		.rst_n(rst_n),
		.ien(Trans_I_oen),
		.iaddr(Trans_I_oaddr),
		.idata(Trans_I_odata),
		.oen(bfX_1_oen),
		.oaddr(bfX_1_oaddr),
		.odata(bfX_1_data)
	);
end
else if(FFT_STG == 2) begin : BF_stg_II1
	BF_stg1 #( 
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TOTAL_STAGE(TOTAL_STAGE),
		.FFT_STG(1) 
	) BF_instII (
		.iclk(iclk),
		.rst_n(rst_n),
		.ien(Trans_I_oen),
		.iaddr(Trans_I_oaddr),
		.idata(Trans_I_odata),
		.oen(bfX_1_oen),
		.oaddr(bfX_1_oaddr),
		.odata(bfX_1_data)
	);
end
else begin : BF_stgX_II
	BF_stgX #( 
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TOTAL_STAGE(TOTAL_STAGE),
		.FFT_STG(FFT_STG-1) 
	) BF_instII (
		.iclk(iclk),
		.rst_n(rst_n),
		.ien(Trans_I_oen),
		.iaddr(Trans_I_oaddr),
		.idata(Trans_I_odata),
		.oen(bfX_1_oen),
		.oaddr(bfX_1_oaddr),
		.odata(bfX_1_data)
	);
end
endgenerate

generate 
if(FFT_STG > 2) begin : ftrans_twiddle
	ftrans #( 
		.FTRANS_STYLE("twiddle"),    //conjugate
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TOTAL_STAGE(TOTAL_STAGE),
		.FFT_STG(FFT_STG) 
	) ftrans_twiddle_inst (
		.iclk(iclk),
		.ien(bfX_1_oen),
		.iaddr(bfX_1_oaddr),
		.idata(bfX_1_data),
		.oen(oen),
		.oaddr(oaddr),
		.odata(odata)
	);
end
else begin
	assign oen   = bfX_1_oen;
	assign oaddr = bfX_1_oaddr;
	assign odata = bfX_1_data;
end
endgenerate


endmodule
