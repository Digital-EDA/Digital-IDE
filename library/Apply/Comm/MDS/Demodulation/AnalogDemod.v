module DigitalDemod #(
        parameter PWIDTH = 32,
        parameter OSCALE = 0,
        parameter FWIDTH = 4,
        parameter IWIDTH = 8,
        parameter OWIDTH = 12
    ) (
        input               clock,
        input               reset,

        input  [15:0]       factor,
        input  [PWIDTH-1:0] fre_word,

        input  [IWIDTH-1:0] wave_in,

        output [OWIDTH-1:0] FM_Demodule,
        output [OWIDTH-1:0] PM_Demodule,
        output [OWIDTH-1:0] AM_Demodule
    );

    // IQ_MIXED Outputs
    wire  clk_div;
    wire  [OWIDTH - 1 : 0]  i_wave;
    wire  [OWIDTH - 1 : 0]  q_wave;

    DDC #(
        .LWIDTH     ( 12      ),
        .PWIDTH     ( PWIDTH  ),
        .OSCALE     ( OSCALE  ),
        .FWIDTH     ( FWIDTH  ),
        .IWIDTH     ( IWIDTH  ),
        .OWIDTH     ( OWIDTH  )) 
    u_DDC (
        .clock                  ( clock      ),
        .reset                  ( reset      ),
        
        .factor                 ( factor     ),
        .fre_word               ( fre_word   ),
        .wave_in                ( wave_in    ),

        .clk_div                ( clk_div    ),
        .i_wave                 ( i_wave     ),
        .q_wave                 ( q_wave     )
    );

    wire                     iqvalid;
    wire signed [OWIDTH-1:0] x_vec;
    wire signed [OWIDTH-1:0] y_vec;
    wire signed [OWIDTH-1:0] z_vec;
    cordic #(
        .XY_BITS      		( OWIDTH        ),
        .PH_BITS      		( OWIDTH        ),
        .ITERATIONS   		( 16            ),
        .STYLE       		( "VECTOR"      ),
        .CALMODE    		( "FAST"        ))
    u_cordic_vec(
        //ports
        .clock     		( clk_div     	 ),
        .reset     		( reset     	 ),

        .ivalid    		( input_strobe   ),
        .x_i       		( i_wave       	 ),
        .y_i       		( q_wave       	 ),
        .z_i    		( 0           	 ),
        
        .ovalid    		( iqvalid    	 ),
        .x_o       		( x_vec       	 ),
        .y_o       		( y_vec       	 ),
        .z_o     		( z_vec 	     )
    );

    reg signed [OWIDTH-1:0] pha_buf;
    reg signed [OWIDTH : 0] pha_dif;
    always @(posedge clk_div) begin
        if(iqvalid) begin
            pha_buf <= z_vec;
            pha_dif <= z_vec - pha_buf;
        end
        else begin
            pha_buf <= 0;
            pha_dif <= 0;
        end
    end

    
    assign FM_Demodule = pha_dif >>> 1;
    assign AM_Demodule = x_vec;
    assign PM_Demodule = z_vec;

endmodule
