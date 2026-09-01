module DDC #(
        //LO_OUTPUR_parameter
        parameter LWIDTH = 12,
        parameter PWIDTH = 32,
        //CIC_Filter_parameter
        parameter OSCALE = 0,
        parameter FWIDTH = 8,
        //IQ_MIXED_parameter
        parameter IWIDTH = 12,
        parameter OWIDTH = 12
    ) (
        input               clock,
        input               reset,

        input  [FWIDTH-1:0] factor,
        input  [PWIDTH-1:0] fre_word,
        input  [IWIDTH-1:0] wave_in,

        output              clk_div,  
        output [OWIDTH-1:0] i_wave,
        output [OWIDTH-1:0] q_wave
    );

    wire [PWIDTH-1:0] Q;
    accuml #(
        .WIDTH 		( PWIDTH    ))
    u_accuml(
        //ports
        .clock      ( clock     ),
        .reset      ( reset     ),
        .clr        ( reset     ),
        .add_sub    ( 1'b0      ),
        .D          ( fre_word  ),
        .Q          ( Q         )
    );

    wire                     iq_ovalid;
    wire signed [LWIDTH-1:0] cos_wave;
    wire signed [LWIDTH-1:0] sin_wave;
    wire signed [PWIDTH-1:0] pha_diff;

    cordic #(
        .XY_BITS      		( LWIDTH        ),
        .PH_BITS      		( PWIDTH        ),
        .ITERATIONS   		( 16            ),
        .STYLE       		( "ROTATE"      ),
        .CALMODE    		( "FAST"        ))
    u_cordic_iq(
        //ports
        .clock     		( clock          ),
        .reset     		( reset          ),
        .ivalid    		( ~reset         ),
        .x_i       		( {PWIDTH{1'b1}} ),
        .y_i       		( 0              ),
        .z_i    		( Q              ),
        .ovalid    		( iq_ovalid      ),
        .x_o       		( cos_wave       ),
        .y_o       		( sin_wave       ),
        .z_o     		( pha_diff       )
    );

    reg  signed [IWIDTH+LWIDTH-1:0] i_sig;
    reg  signed [IWIDTH+LWIDTH-1:0] q_sig;
    always @(posedge clock) begin
        if (reset) begin
            i_sig <= 0;
            q_sig <= 0;
        end
        else begin
            i_sig <= $signed(wave_in) * $signed(cos_wave);
            q_sig <= $signed(wave_in) * $signed(sin_wave);
        end
    end

    wire [11:0] i;
    wire [11:0] q;

    assign i = i_sig[IWIDTH+LWIDTH-1:IWIDTH+LWIDTH-12];
    assign q = q_sig[IWIDTH+LWIDTH-1:IWIDTH+LWIDTH-12];

    wire 	ivalid;
    wire 	qvalid;
    CIC #(
        .CSTAGE 		( 3  		),
        .FWIDTH 		( FWIDTH 	),
        .IWIDTH 		( 12 		),
        .OSCALE 		( OSCALE  	),
        .OWIDTH 		( OWIDTH 	))
    u_CIC_i(
        //ports
        .clock      		( clock      ),
        .reset      		( reset      ),
        .factor     		( factor     ),
        .ivalid     		( 1'b1       ),
        .filter_in  		( i  		 ),
        .ovalid     		( ivalid     ),
        .filter_out 		( i_wave 	 )
    );

    CIC #(
        .CSTAGE 		( 3  		),
        .FWIDTH 		( FWIDTH 	),
        .IWIDTH 		( 12 		),
        .OSCALE 		( OSCALE  	),
        .OWIDTH 		( OWIDTH 	))
    u_CIC_q(
        //ports
        .clock      		( clock      ),
        .reset      		( reset      ),
        .factor     		( factor     ),
        .ivalid     		( 1'b1       ),
        .filter_in  		( q  		 ),
        .ovalid     		( qvalid     ),
        .filter_out 		( q_wave 	 )
    );

    assign clk_div = ivalid & qvalid;

endmodule