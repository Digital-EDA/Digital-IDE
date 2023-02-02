`timescale 1ns/100ps

module ftrans #( 
	parameter  FTRANS_STYLE = "twiddle",    //conjugate
	parameter  REAL_WIDTH   = 18,
	parameter  IMGN_WIDTH   = 18,
	parameter  TOTAL_STAGE  = 11,
	parameter  FFT_STG      = 7,
	localparam CPLX_WIDTH   = REAL_WIDTH + IMGN_WIDTH	
) (
	input  iclk,

	input                    ien,
	input  [CPLX_WIDTH-1:0]  idata,
	input  [TOTAL_STAGE-1:0] iaddr,

	output                   oen,
	output [CPLX_WIDTH-1:0]  odata,
	output [TOTAL_STAGE-1:0] oaddr
);

wire k1 = iaddr[FFT_STG-1];
wire k2 = iaddr[FFT_STG-2];

wire signed [REAL_WIDTH-1:0]  data_real = idata[CPLX_WIDTH-1:REAL_WIDTH];
wire signed [IMGN_WIDTH-1:0]  data_imag = idata[IMGN_WIDTH-1:0];

reg [CPLX_WIDTH-1:0]  idata_r = 0;
reg [CPLX_WIDTH-1:0]  odata_r = 0;
generate if(FTRANS_STYLE == "conjugate") begin : conjugate
	always @(posedge iclk) begin
		if({k1, k2} == 2'b11)begin
			idata_r <= {data_real,-data_imag};
			odata_r <= idata_r;
		end
		else begin
			idata_r <= idata;
			odata_r <= idata_r;
		end
	end
end
else if(FTRANS_STYLE == "twiddle") begin : twiddle
	wire [FFT_STG-3:0] n3 = iaddr[FFT_STG-3:0];
	wire [FFT_STG-2:0] addr1 = k1 ? {1'b0, n3} : { (FFT_STG-1) {1'b0} };
	wire [FFT_STG-2:0] addr2 = k2 ? {n3, 1'b0} : { (FFT_STG-1) {1'b0} };
	wire [FFT_STG-1:0] ROM_addr = addr1 + addr2;	// ROM_addr = (k1 + 2*k2) * n3

	wire [REAL_WIDTH-1:0] twiddle_ore;
	wire [IMGN_WIDTH-1:0] twiddle_oim;
	ftwiddle #(
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH),
		.TW_STAGE(FFT_STG)
	) ftwiddle_inst (
		.idx(ROM_addr),
		.ore(twiddle_ore),
		.oim(twiddle_oim)
	);

	wire [CPLX_WIDTH-1:0] mul_ore;
	wire [CPLX_WIDTH-1:0] mul_oim;
	cmpl_mult #(
		.REAL_WIDTH(REAL_WIDTH),
		.IMGN_WIDTH(IMGN_WIDTH)
	) cmpl_mult_inst (
		.clock(iclk),
		.dataa_real(data_real),
		.dataa_imag(data_imag),
		.datab_real(twiddle_ore),
		.datab_imag(twiddle_oim),
		.result_real(mul_ore),
		.result_imag(mul_oim)
	);
	always @(posedge iclk) begin
		odata_r <= {mul_ore[CPLX_WIDTH-1:REAL_WIDTH],mul_oim[CPLX_WIDTH-1:IMGN_WIDTH]}; 	
	end
end
endgenerate	
assign odata = odata_r;

localparam LATENCY = 2;
reg  [TOTAL_STAGE-1:0] oaddr_d [LATENCY-1:0];
integer i;
initial begin
	for (i = 0; i<LATENCY; i=i+1) begin
		oaddr_d[i] = 0;
	end
end
integer index;
always @(posedge iclk) begin
	oaddr_d[0] <= iaddr;
	for(index=0; index<LATENCY-1; index=index+1) begin
		oaddr_d[index+1] <= oaddr_d[index];
	end
end
assign oaddr = oaddr_d[LATENCY-1];
	
reg  [LATENCY-1:0] oen_d = 0;
always @(posedge iclk) begin
	oen_d <= {oen_d[LATENCY-2:0], ien};
end
assign oen = oen_d[LATENCY-1];

// generate if(FTRANS_STYLE == "conjugate") begin
// 	localparam LATENCY = 2;
// 	reg  [TOTAL_STAGE-1:0] oaddr_d [LATENCY-1:0];
// 	integer i;
// 	initial begin
// 	   for (i = 0; i<LATENCY; i=i+1) begin
// 			oaddr_d[i] = 0;
// 		end
// 	end
// 	integer index;
// 	always @(posedge iclk) begin
// 		oaddr_d[0] <= iaddr;
// 		for(index=0; index<LATENCY-1; index=index+1) begin
// 			oaddr_d[index+1] <= oaddr_d[index];
// 		end
// 	end
// 	assign oaddr = oaddr_d[LATENCY-1];
		
// 	reg  [LATENCY-1:0] oen_d = 0;
// 	always @(posedge iclk) begin
// 		oen_d <= {oen_d[LATENCY-2:0], ien};
// 	end
// 	assign oen = oen_d[LATENCY-1];
// end
// else if(FTRANS_STYLE == "twiddle") begin
// 	localparam LATENCY = 3;
// 	reg  [TOTAL_STAGE-1:0] oaddr_d [LATENCY-1:0];
// 	integer i;
// 	initial begin
// 	   for (i = 0; i<LATENCY; i=i+1) begin
// 			oaddr_d[i] = 0;
// 		end
// 	end
// 	integer index;
// 	always @(posedge iclk) begin
// 		oaddr_d[0] <= iaddr;
// 		for(index=0; index<LATENCY-1; index=index+1) begin
// 			oaddr_d[index+1] <= oaddr_d[index];
// 		end
// 	end
// 	assign oaddr = oaddr_d[LATENCY-1];
		
// 	reg  [LATENCY-1:0] oen_d = 0;
// 	always @(posedge iclk) begin
// 		oen_d <= {oen_d[LATENCY-2:0], ien};
// 	end
// 	assign oen = oen_d[LATENCY-1];
// end
// endgenerate

endmodule
