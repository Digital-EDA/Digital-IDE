`timescale 1ns/100ps
module fft_stage #(
        parameter 	FFT_STAGE  = 3,
        parameter 	TOTAL_STG  = 10,
        parameter   TWIDD_MODE = 0,
        parameter   BUFLY_MODE = 1,
        parameter   SCALE_KCOE = 1,
        parameter 	DATA_WIDTH = 18
    ) (
        input  iclk,
        input  rstn,

        input  ien,
        input  [TOTAL_STG-1:0] iaddr,
        input  [2*DATA_WIDTH-1:0] idata,

        output oen,
        output [TOTAL_STG-1:0] oaddr,
        output [2*DATA_WIDTH-1:0] odata
    );

    localparam CPLX_WIDTH = 2*DATA_WIDTH;

    wire bfX_I_oen;
    wire [TOTAL_STG-1:0]  bfX_I_oaddr;
    wire [CPLX_WIDTH-1:0] bfX_I_odata;

    // stage one : always exist
    BF_stage #(
        .BUFLY_MODE ( BUFLY_MODE ),
        .BUFL_STAGE ( FFT_STAGE  ),
        .TOTAL_STEP ( TOTAL_STG  ),
        .DATA_WIDTH ( DATA_WIDTH ))
    BF_inst_I (
        .iclk(iclk),
        .rstn(rstn),

        .ien(ien),
        .iaddr(iaddr),
        .idata(idata),
        
        .oen(bfX_I_oen),
        .oaddr(bfX_I_oaddr),
        .odata(bfX_I_odata)
    );

    generate if(FFT_STAGE >= 2) begin : LARGER_THAN_2
        wire bfX_II_oen;
        wire [TOTAL_STG-1:0]  bfX_II_oaddr;
        wire [CPLX_WIDTH-1:0] bfX_II_odata;

        wire Trans_I_oen;
        wire [TOTAL_STG-1:0]  Trans_I_oaddr;
        wire [CPLX_WIDTH-1:0] Trans_I_odata;

        ftrans #(
            .FFT_STAGE   ( FFT_STAGE    ),
            .TRANS_MODE  ( 0            ),
            .TWIDD_MODE  ( TWIDD_MODE   ),
            .TOTAL_STEP  ( TOTAL_STG    ),
            .SCALE_KCOE  ( SCALE_KCOE   ),
            .DATA_WIDTH  ( DATA_WIDTH   ))
        ftrans_I (
            //ports
            .iclk  		( iclk  	),
            .rstn 		( rstn 		),

            .ien   		( bfX_I_oen   	),
            .iaddr 		( bfX_I_oaddr 	),
            .idata 		( bfX_I_odata 	),

            .oen   		( Trans_I_oen   ),
            .oaddr 		( Trans_I_oaddr ),
            .odata 		( Trans_I_odata )
        );

        // stage two : always exist
        BF_stage #(
            .BUFLY_MODE ( BUFLY_MODE   ),
            .BUFL_STAGE ( FFT_STAGE-1  ),
            .TOTAL_STEP ( TOTAL_STG    ),
            .DATA_WIDTH ( DATA_WIDTH   ))
        BF_inst_II (
            //ports
            .iclk  		( iclk  	),
            .rstn 		( rstn 		),

            .ien   		( Trans_I_oen   ),
            .iaddr 		( Trans_I_oaddr ),
            .idata 		( Trans_I_odata ),

            .oen   		( bfX_II_oen   	),
            .oaddr 		( bfX_II_oaddr 	),
            .odata 		( bfX_II_odata	)
        );

        if(FFT_STAGE == 2) begin : LESS_THAN_3
            assign oen   = bfX_II_oen;
            assign oaddr = bfX_II_oaddr;
            assign odata = bfX_II_odata;
        end
        else begin : LARGER_THAN_3
            ftrans #(
                .FFT_STAGE   ( FFT_STAGE    ),
                .TRANS_MODE  ( 1            ),
                .TWIDD_MODE  ( TWIDD_MODE   ),
                .TOTAL_STEP  ( TOTAL_STG    ),
                .SCALE_KCOE  ( SCALE_KCOE   ),
                .DATA_WIDTH  ( DATA_WIDTH   ))
            ftrans_II (
                //ports
                .iclk  		( iclk  		),
                .rstn 		( rstn 		    ),

                .ien   		( bfX_II_oen   	),
                .iaddr 		( bfX_II_oaddr 	),
                .idata 		( bfX_II_odata 	),

                .oen   		( oen   		),
                .oaddr 		( oaddr 		),
                .odata 		( odata 		)
            );
        end
    end
    else begin : LESS_THAN_2
        assign oen   = bfX_I_oen;
        assign oaddr = bfX_I_oaddr;
        assign odata = bfX_I_odata;
    end
    endgenerate

endmodule
