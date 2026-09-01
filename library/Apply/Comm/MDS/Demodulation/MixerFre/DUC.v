module DUC #(
        //LO_OUTPUR_parameter
        parameter DWIDTH = 12,
        parameter PWIDTH = 32,
        //CIC_Filter_parameter
        parameter FWIDTH = 38,
        //IQ_MIXED_parameter
        parameter IWIDTH = 12,
        parameter OWIDTH = 12
    ) (
        input               clock,
        input               reset,

        input  [PWIDTH-1:0] fre_word,
        input  [OWIDTH-1:0] i_wave,
        input  [OWIDTH-1:0] q_wave,

        input  [IWIDTH-1:0] wave_out
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
    wire signed [DWIDTH-1:0] cos_wave;
    wire signed [DWIDTH-1:0] sin_wave;
    wire signed [PWIDTH-1:0] pha_diff;

    cordic #(
        .XY_BITS      		( DWIDTH        ),
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

    reg  signed [IWIDTH+DWIDTH-1:0] i_sig;
    reg  signed [IWIDTH+DWIDTH-1:0] q_sig;
    always @(posedge clock) begin
        if (reset) begin
            i_sig <= 0;
            q_sig <= 0;
        end
        else begin
            i_sig <= $signed(i_wave) * $signed(cos_wave);
            q_sig <= $signed(q_wave) * $signed(sin_wave);
        end
    end

    reg  signed [IWIDTH+DWIDTH : 0] wave;
    always @(posedge clock) begin
        if (reset) begin
            wave <= 0;
        end
        else begin
            wave <= i_sig + q_sig;
        end
    end

    assign wave_out = wave[IWIDTH+DWIDTH:IWIDTH+DWIDTH-11];

endmodule