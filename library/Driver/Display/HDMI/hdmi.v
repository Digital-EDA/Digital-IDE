`timescale 1ns / 1ps

// (c) fpga4fun.com & KNJN LLC 2013
// edited/updated for vivado 2020.1 by Dominic Meads 10/2020

////////////////////////////////////////////////////////////////////////
module HDMI_out(
        input  clk_pixel,     // 25MHz
        input  clk_pixel_x5,  // 250MHz
        input  reset,

        input [7:0] RED,
        input [7:0] GREEN,
        input [7:0] BLUE,
        input       HSYNC,
        input       VSYNC,

        // HMDI Pin I/O
        output [2:0] TMDS_DATA_P,
        output [2:0] TMDS_DATA_N,

        output TMDS_CLK_P,
        output TMDS_CLK_N,

        output TMDS_OUT_EN
    );
    assign TMDS_OUT_EN = 1;
    
    /******************************** HDMI OUT ********************************/
    // 8b/10b encoding for transmission
    wire [9:0]	r_tmds;
    tmds_encoder r_tmds_encoder(
        //ports
        .clock   	( clk_pixel   	),
        .reset      ( reset   		),
        .den   		( 1'b1   		),
        .ctrl  		( {0,0}  		),
        .idata 		( RED    		),
        .tmds  		( r_tmds  		)
    );

    wire [9:0]	g_tmds;
    tmds_encoder g_tmds_encoder(
        //ports
        .clock   	( clk_pixel   	),
        .reset   	( reset   		),
        .den   		( 1'b1   		),
        .ctrl  		( {0,0}  		),
        .idata 		( GREEN 		),
        .tmds  		( g_tmds  		)
    );

    wire [9:0]	b_tmds;
    tmds_encoder b_tmds_encoder(
        //ports
        .clock   	( clk_pixel   	 ),
        .reset   	( reset   		 ),
        .den   		( 1'b1   		 ),
        .ctrl  		( {VSYNC, HSYNC} ),
        .idata 		( BLUE  		 ),
        .tmds  		( b_tmds  		 )
    );

    wire [2:0] tmds;
    wire tmds_clock;
    oserializer #(
        .VIDEO_RATE(25)) 
    u_oserializer(
        .clk_pixel(clk_pixel), 
        .clk_pixel_x5(clk_pixel_x5), 
        .reset(reset), 
        .red(r_tmds),
        .green(g_tmds),
        .blue(b_tmds),
        .tmds(tmds), 
        .tmds_clock(tmds_clock)
    );

    OBUFDS #(
        .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
        .SLEW("SLOW"))          // Specify the output slew rate
    OBUFDS_red (
        .O(TMDS_DATA_P[2]),     // Diff_p output (connect directly to top-level port)
        .OB(TMDS_DATA_N[2]),    // Diff_n output (connect directly to top-level port)
        .I(tmds[2])   // Buffer input
    );

    OBUFDS #(
        .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
        .SLEW("SLOW"))          // Specify the output slew rate
    OBUFDS_green (
        .O(TMDS_DATA_P[1]),     // Diff_p output (connect directly to top-level port)
        .OB(TMDS_DATA_N[1]),    // Diff_n output (connect directly to top-level port)
        .I(tmds[1]) // Buffer input
    );

    OBUFDS #(
        .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
        .SLEW("SLOW"))          // Specify the output slew rate
    OBUFDS_blue (
        .O(TMDS_DATA_P[0]),     // Diff_p output (connect directly to top-level port)
        .OB(TMDS_DATA_N[0]),    // Diff_n output (connect directly to top-level port)
        .I(tmds[0])  // Buffer input
    );

    OBUFDS #(
        .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
        .SLEW("SLOW"))          // Specify the output slew rate
    OBUFDS_clock (
        .O(TMDS_CLK_P),     // Diff_p output (connect directly to top-level port)
        .OB(TMDS_CLK_N),    // Diff_n output (connect directly to top-level port)
        .I(tmds_clock)          // Buffer input
    );

endmodule  // HDMI_out
