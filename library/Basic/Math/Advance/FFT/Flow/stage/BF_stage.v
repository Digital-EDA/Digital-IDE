`timescale 1ns/100ps

module BF_stage #(
        parameter   SCALE_KCOE = 1,
        parameter   BUFLY_MODE = 1,
        parameter 	BUFL_STAGE = 10, // stage of current bf
        parameter 	TOTAL_STEP = 12, 
        parameter 	DATA_WIDTH = 18
    ) (
        input  iclk,
        input  rstn,
 
        input  ien,
        input  [TOTAL_STEP-1:0]   iaddr,
        input  [2*DATA_WIDTH-1:0] idata,

        output oen,
        output [TOTAL_STEP-1:0]   oaddr,
        output [2*DATA_WIDTH-1:0] odata
    );

    localparam BUFY_DELAY = (1<<(BUFL_STAGE-1));
    localparam CPLX_WIDTH = 2*DATA_WIDTH;
    localparam ADDR_WIDTH = (BUFL_STAGE == 1) ? 0 : (BUFL_STAGE - 2);
    localparam TOTAL_ADDR_MAX = { TOTAL_STEP { 1'b1 } };

	localparam REAL_MSB = 2*DATA_WIDTH-1;		// 35
	localparam REAL_LSB = DATA_WIDTH;			// 18
	localparam IMAG_MSB = DATA_WIDTH - 1;		// 17
	localparam IMAG_LSB = 0;					// 0

    reg  [TOTAL_STEP-1:0]   roaddr;

    wire 	                mvalid;
    wire [CPLX_WIDTH-1 : 0]	mdata;

    wire [CPLX_WIDTH-1 : 0] bf_oa;
    wire [CPLX_WIDTH-1 : 0] bf_ob;

    generate 
    if(BUFLY_MODE) begin : FLOW_MODE
        wire 	                oavalid;
        wire 	                obvalid;
        wire 	                bvalid;
        wire [CPLX_WIDTH-1 : 0]	bdata;

        shiftTaps #(
            .WIDTH 		( CPLX_WIDTH ),
            .SHIFT 		( BUFY_DELAY ))
        u0_shiftTaps(
            //ports
            .clock    		( iclk    ),
            .reset    		( ~rstn   ),

            .ivalid   		( ien     ),
            .shiftin  		( idata   ),

            .ovalid   		( mvalid  ),
            .shiftout 		( mdata   )
        );

        cmplAdsu #(
            .SCALE_FACTOR 		( SCALE_KCOE ),
            .REAL_WIDTH_A 		( DATA_WIDTH ),
            .IMAG_WIDTH_A 		( DATA_WIDTH ),
            .REAL_WIDTH_B 		( DATA_WIDTH ),
            .IMAG_WIDTH_B 		( DATA_WIDTH ),
            .REAL_WIDTH_O 		( DATA_WIDTH ),
            .IMAG_WIDTH_O 		( DATA_WIDTH ))
        u0_cmplAdsu(
            //ports
            .clock    		( iclk    		),
            .reset    		( ~rstn    		),
            .add_sub  		( 1'b0  		),  // + 
            .ivalid   		( mvalid   	    ),
            .dataa_r  		( mdata[REAL_MSB:REAL_LSB] ),
            .dataa_i  		( mdata[IMAG_MSB:IMAG_LSB] ),
            .datab_r  		( idata[REAL_MSB:REAL_LSB] ),
            .datab_i  		( idata[IMAG_MSB:IMAG_LSB] ),
            .ovalid   		( oavalid   		       ),
            .result_r 		( bf_oa[REAL_MSB:REAL_LSB] ),
            .result_i 		( bf_oa[IMAG_MSB:IMAG_LSB] )
        );

        cmplAdsu #(
            .SCALE_FACTOR 		( SCALE_KCOE ),
            .REAL_WIDTH_A 		( DATA_WIDTH ),
            .IMAG_WIDTH_A 		( DATA_WIDTH ),
            .REAL_WIDTH_B 		( DATA_WIDTH ),
            .IMAG_WIDTH_B 		( DATA_WIDTH ),
            .REAL_WIDTH_O 		( DATA_WIDTH ),
            .IMAG_WIDTH_O 		( DATA_WIDTH ))
        u1_cmplAdsu(
            //ports
            .clock    		( iclk    		),
            .reset    		( ~rstn    		),
            .add_sub  		( 1'b1  		),  // - 
            .ivalid   		( mvalid   	    ),
            .dataa_r  		( mdata[REAL_MSB:REAL_LSB] ),
            .dataa_i  		( mdata[IMAG_MSB:IMAG_LSB] ),
            .datab_r  		( idata[REAL_MSB:REAL_LSB] ),
            .datab_i  		( idata[IMAG_MSB:IMAG_LSB] ),
            .ovalid   		( obvalid   		       ),
            .result_r 		( bf_ob[REAL_MSB:REAL_LSB] ),
            .result_i 		( bf_ob[IMAG_MSB:IMAG_LSB] )
        );

        shiftTaps #(
            .WIDTH 		( CPLX_WIDTH ),
            .SHIFT 		( BUFY_DELAY ))
        u1_shiftTaps(
            //ports
            .clock    		( iclk              ),
            .reset    		( ~rstn             ),

            .ivalid   		( oavalid & obvalid ),
            .shiftin  		( bf_ob             ),

            .ovalid   		( bvalid            ),
            .shiftout 		( bdata             )
        );

        assign odata = oaddr[BUFL_STAGE-1] ? bdata : bf_oa;
        assign oaddr = roaddr;
        assign oen = oavalid & obvalid;
    end
    else begin : OPT_MODE
        localparam VALID = (BUFY_DELAY > 1) ? (BUFY_DELAY - 2) : 0;

        reg [BUFY_DELAY-1:0] roen;

        wire is_load = ~iaddr[BUFL_STAGE-1];

        wire signed [DATA_WIDTH-1:0] bf_ar = mdata[REAL_MSB:REAL_LSB];
        wire signed [DATA_WIDTH-1:0] bf_ai = mdata[IMAG_MSB:IMAG_LSB];
        wire signed [DATA_WIDTH-1:0] bf_br = idata[REAL_MSB:REAL_LSB];
        wire signed [DATA_WIDTH-1:0] bf_bi = idata[IMAG_MSB:IMAG_LSB];

        wire signed [DATA_WIDTH : 0] qa_r = bf_ar + bf_br;
        wire signed [DATA_WIDTH : 0] qa_i = bf_ai + bf_bi;
        wire signed [DATA_WIDTH : 0] qb_r = bf_ar - bf_br;
        wire signed [DATA_WIDTH : 0] qb_i = bf_ai - bf_bi;

        assign bf_oa = {qa_r[DATA_WIDTH-SCALE_KCOE:1-SCALE_KCOE], qa_i[DATA_WIDTH-SCALE_KCOE:1-SCALE_KCOE]};
        assign bf_ob = {qb_r[DATA_WIDTH-SCALE_KCOE:1-SCALE_KCOE], qb_i[DATA_WIDTH-SCALE_KCOE:1-SCALE_KCOE]};

        wire [CPLX_WIDTH-1 : 0]	sdata = is_load ? idata : bf_ob;

        shiftTaps #(
            .WIDTH 		( CPLX_WIDTH ),
            .SHIFT 		( BUFY_DELAY ))
        u_shiftTaps(
            //ports
            .clock      ( iclk        ),
            .reset      ( ~rstn       ),

            .ivalid     ( (ien | oen) ),
            .shiftin    ( sdata       ),

            .ovalid     ( mvalid     ),
            .shiftout   ( mdata      )
        );

        assign odata = is_load ? mdata : bf_oa;

        always @(posedge iclk or negedge rstn) begin
            if (!rstn) begin
                roen <= 0;
            end 
            else begin    
                roen <= (BUFY_DELAY > 1) ? {roen[VALID:0], ien} : ien;
            end
        end

        assign oen = roen[BUFY_DELAY-1];
    end
    endgenerate

    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            roaddr <= 0;
        end
        else begin
            if (oen) begin
                roaddr <= roaddr + 1;
            end
            else begin
                roaddr <= 0;
            end
        end
    end

    assign oaddr = roaddr;

endmodule
