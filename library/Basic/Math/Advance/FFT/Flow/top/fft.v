`timescale 1ns/100ps

module fft #( 
        parameter   SCALE_KCOE = 1,
        parameter   BUFLY_MODE = 1,
        parameter   TWIDD_MODE = 0,
        parameter 	TOTAL_STEP = 11,
        parameter 	DATA_WIDTH = 18 
    ) (
        input iclk, 
        input rstn,

        input ien,
        input [TOTAL_STEP-1:0]  iaddr,
        input [DATA_WIDTH-1:0]  iReal,
        input [DATA_WIDTH-1:0]  iImag,
        
        output oen,
        output [TOTAL_STEP-1:0]  oaddr,
        output [DATA_WIDTH-1:0]  oReal,
        output [DATA_WIDTH-1:0]  oImag
    );
	
	localparam CPLX_WIDTH = 2*DATA_WIDTH;
	localparam INTER_MODU_WIRE_NUM = ((TOTAL_STEP-1)/2) + 1;
	
	wire en_w [INTER_MODU_WIRE_NUM:0];
	wire [TOTAL_STEP-1:0] addr_w [INTER_MODU_WIRE_NUM:0];
	wire [CPLX_WIDTH-1:0] data_w [INTER_MODU_WIRE_NUM:0];

	assign en_w[INTER_MODU_WIRE_NUM] = ien;
	assign addr_w[INTER_MODU_WIRE_NUM] = iaddr;
	assign data_w[INTER_MODU_WIRE_NUM] = {iReal, iImag};
	
	generate
	genvar gv_stg;
		for(gv_stg = TOTAL_STEP; gv_stg >= 1; gv_stg = gv_stg-2) begin : stagX
            localparam gv_index = ((gv_stg-1)/2) + 1;
            
            fft_stage #(
                .FFT_STAGE    ( gv_stg 		 ),
                .TOTAL_STG    ( TOTAL_STEP   ),
                .TWIDD_MODE   ( TWIDD_MODE   ),
                .BUFLY_MODE   ( BUFLY_MODE   ),
                .SCALE_KCOE   ( SCALE_KCOE   ),
                .DATA_WIDTH   ( DATA_WIDTH   ))
            u_fft_stage(
                //ports
                .iclk  		( iclk  		     ),
                .rstn 		( rstn 		         ),

                .ien   		( en_w[gv_index]	 ),
                .iaddr 		( addr_w[gv_index]	 ),
                .idata 		( data_w[gv_index]	 ),

                .oen   		( en_w[gv_index-1]   ),
                .oaddr 		( addr_w[gv_index-1] ),
                .odata 		( data_w[gv_index-1] )
            );
		end
	endgenerate

	wire [TOTAL_STEP-1:0] addr_end;
    assign oen = en_w[0];
    assign addr_end = addr_w[0];
    assign {oReal, oImag} = data_w[0];

    generate	// bit_reverse
	genvar index;
		for(index=0; index < TOTAL_STEP; index=index+1) begin: bit_reverse
			assign oaddr[TOTAL_STEP-index-1] = addr_end[index];
		end
	endgenerate

endmodule
