`timescale 1ns/1ns
module Matrix_Generate_3X3 #(
	parameter DATA_WIDTH = 8,
	parameter IMG_HDISP  = 640,	//640*480
	parameter IMG_VDISP  = 480
) (
	//global clock
	input				 	clock,  				//cmos video pixel clock
	input				 	reset,				    //global reset

	//Image data prepred to be processd
	input				 	per_img_vsync,	    //Prepared Image data vsync valid signal
	input				 	per_img_href,		//Prepared Image data href vaild  signal
	input [DATA_WIDTH-1:0]  per_img_Data,		//Prepared Image brightness input

	//Image data has been processd
	output				 	post_img_vsync,	//Prepared Image data vsync valid signal
	output				 	post_img_href,	//Prepared Image data href vaild  signal

	output	reg	[DATA_WIDTH-1:0]	matrix_pixel_11, matrix_pixel_12, matrix_pixel_13,	//3X3 Matrix output
	output	reg	[DATA_WIDTH-1:0]	matrix_pixel_21, matrix_pixel_22, matrix_pixel_23,
	output	reg	[DATA_WIDTH-1:0]	matrix_pixel_31, matrix_pixel_32, matrix_pixel_33
);


//Generate 3*3 matrix 
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
//sync row3_data with per_img_clken & row1_data & raw2_data
wire [DATA_WIDTH-1:0] row1_data;	//frame data of the 1th row
wire [DATA_WIDTH-1:0] row2_data;	//frame data of the 2th row
reg	 [DATA_WIDTH-1:0] row3_data;	//frame data of the 3th row
always@(posedge clock or posedge reset) begin
	if(reset)begin
		row3_data <= 0;
	end
	else begin
		if(per_img_href)begin
			row3_data <= per_img_Data;
		end
		else begin
			row3_data <= row3_data;
		end
	end	
end

//---------------------------------------
//module of shift ram for raw data
wire	shift_clk_en = per_img_href;
Line_ShiftRAM #(
    .RAM_Length (  IMG_HDISP  ),
    .DATA_WIDTH (  DATA_WIDTH )
) u_Line_Shift_RAM (
    .clock                   ( clock          ),
	.reset 					 (reset),
    .clken                   ( shift_clk_en ),
    .shiftin                 ( row3_data    ),

    .taps0x                  ( row2_data    ),
    .taps1x                  ( row1_data    )
);
//------------------------------------------
//lag 2 clocks signal sync  
reg	[1:0]	per_img_vsync_d;
reg	[1:0]	per_img_href_d;
always@(posedge clock or posedge reset) begin
	if(reset) begin
		per_img_vsync_d <= 0;
		per_img_href_d <= 0;
	end
	else begin
		per_img_vsync_d 	<= 	{per_img_vsync_d[0], 	per_img_vsync};
		per_img_href_d 	<= 	{per_img_href_d[0], 	per_img_href};
	end
end
//Give up the 1th and 2th row edge data caculate for simple process
//Give up the 1th and 2th point of 1 line for simple process
wire	read_img_href		=	per_img_href_d[0];	//RAM read href sync signal
assign	post_img_vsync 	= 	per_img_vsync_d[1];
assign	post_img_href 	= 	per_img_href_d[1];

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
/******************************************************************************
					----------	Convert Matrix	----------
				[ P31 -> P32 -> P33 -> ]	--->	[ P11 P12 P13 ]	
				[ P21 -> P22 -> P23 -> ]	--->	[ P21 P22 P23 ]
				[ P11 -> P12 -> P11 -> ]	--->	[ P31 P32 P33 ]
******************************************************************************/
//---------------------------------------------------------------------------
//---------------------------------------------------
/***********************************************
	(1)	Read data from Shift_RAM
	(2) Caculate the Sobel
	(3) Steady data after Sobel generate
************************************************/
//wire	[2:0]	matrix_row1 = {matrix_pixel_11, matrix_pixel_12, matrix_pixel_13};	//Just for test
//wire	[2:0]	matrix_row2 = {matrix_pixel_21, matrix_pixel_22, matrix_pixel_23};
//wire	[2:0]	matrix_row3 = {matrix_pixel_31, matrix_pixel_32, matrix_pixel_33};
always@(posedge clock or posedge reset) begin
	if(reset) begin
		{matrix_pixel_11, matrix_pixel_12, matrix_pixel_13} <= 0;
		{matrix_pixel_21, matrix_pixel_22, matrix_pixel_23} <= 0;
		{matrix_pixel_31, matrix_pixel_32, matrix_pixel_33} <= 0;
	end
	else if(read_img_href) begin
		{matrix_pixel_11, matrix_pixel_12, matrix_pixel_13} <= {matrix_pixel_12, matrix_pixel_13, row1_data};	//1th shift input
		{matrix_pixel_21, matrix_pixel_22, matrix_pixel_23} <= {matrix_pixel_22, matrix_pixel_23, row2_data};	//2th shift input
		{matrix_pixel_31, matrix_pixel_32, matrix_pixel_33} <= {matrix_pixel_32, matrix_pixel_33, row3_data};	//3th shift input
	end
	else begin
		{matrix_pixel_11, matrix_pixel_12, matrix_pixel_13} <= 0;
		{matrix_pixel_21, matrix_pixel_22, matrix_pixel_23} <= 0;
		{matrix_pixel_31, matrix_pixel_32, matrix_pixel_33} <= 0;
	end
end

endmodule
