`timescale 1ns/100ps
module ifft #( 
        parameter   SCALE_KCOE = 1,
        parameter   BUFLY_MODE = 1,
        parameter   TWIDD_MODE = 0,
        parameter 	TOTAL_STEP = 11,
        parameter 	DATA_WIDTH = 18 
    ) (
        input  iclk, 
        input  rstn,

        input  ien,
        input  [TOTAL_STEP-1:0]  iaddr,
        input  [DATA_WIDTH-1:0]  iReal,
        input  [DATA_WIDTH-1:0]  iImag,
        
        output oen,
        output [TOTAL_STEP-1:0]  oaddr,
        output [DATA_WIDTH-1:0]  oReal,
        output [DATA_WIDTH-1:0]  oImag
    );
	
	localparam CPLX_WIDTH = 2*DATA_WIDTH;
	localparam INTER_MODU_WIRE_NUM = ((TOTAL_STEP-1)/2);
	
	wire [DATA_WIDTH-1:0] Real_e;	
	wire [DATA_WIDTH-1:0] Imag_e;	
	wire [DATA_WIDTH-1:0] Real_w =  iReal;	
	wire [DATA_WIDTH-1:0] Imag_w = -iImag;
	assign oReal =  Real_e;
	assign oImag = -Imag_e;
	
	fft #( 
        .SCALE_KCOE(SCALE_KCOE),
        .BUFLY_MODE(BUFLY_MODE),
        .TWIDD_MODE(TWIDD_MODE),
		.TOTAL_STEP(TOTAL_STEP),
		.DATA_WIDTH(DATA_WIDTH)) 
    fft_ins (
		.iclk(iclk),
		.rstn(rstn),
		.ien(ien),
		.iaddr(iaddr),
		.iReal(Real_w),
		.iImag(Imag_w),
		.oen(oen),
		.oaddr(oaddr),
		.oReal(Real_e),
		.oImag(Imag_e)
	);

endmodule
