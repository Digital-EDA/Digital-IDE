`timescale 1ns/1ns
module Bit_Dilation_Detector #(
	parameter	[10:0]	IMG_HDISP = 11'd640,	//640*480
	parameter	[10:0]	IMG_VDISP = 11'd480
) (
	//global clock
	input				clock,  				//cmos video pixel clock
	input				reset,				//global reset
	//Image data prepred to be processd
	input				per_img_vsync,	//Prepared Image data vsync valid signal
	input				per_img_href,		//Prepared Image data href vaild  signal
	input				per_img_Bit,		//Prepared Image Bit flag outout(1: Value, 0:inValid)
	//Image data has been processd
	output				post_img_vsync,	//Processed Image data vsync valid signal
	output				post_img_href,	//Processed Image data href vaild  signal
	output				post_img_Bit		//Processed Image Bit flag outout(1: Value, 0:inValid)
);

//----------------------------------------------------
//Generate 1Bit 3X3 Matrix for Video Image Processor.
//Image data has been processd
wire			matrix_img_vsync;	//Prepared Image data vsync valid signal
wire			matrix_img_href;	//Prepared Image data href vaild  signal
wire			matrix_pixel_11, matrix_pixel_12, matrix_pixel_13;	//3X3 Matrix output
wire			matrix_pixel_21, matrix_pixel_22, matrix_pixel_23;
wire			matrix_pixel_31, matrix_pixel_32, matrix_pixel_33;
Matrix_Generate_3X3 #(
	.DATA_WIDTH  (    1    ),
	.IMG_HDISP	 (IMG_HDISP),	//640*480
	.IMG_VDISP	 (IMG_VDISP)
) Matrix_Generate_3X3_u (
	//global clock
	.clock					(clock),  				//cmos video pixel clock
	.reset					(reset),				//global reset
	//Image data prepred to be processd
	.per_img_vsync		    (per_img_vsync),		//Prepared Image data vsync valid signal
	.per_img_href			(per_img_href),		//Prepared Image data href vaild  signal
	.per_img_Data			(per_img_Bit),			//Prepared Image brightness input
	//Image data has been processd
	.post_img_vsync		(matrix_img_vsync),	//Processed Image data vsync valid signal
	.post_img_href		(matrix_img_href),	//Processed Image data href vaild  signal
	.matrix_pixel_11(matrix_pixel_11),	.matrix_pixel_12(matrix_pixel_12), 	.matrix_pixel_13(matrix_pixel_13),	//3X3 Matrix output
	.matrix_pixel_21(matrix_pixel_21), 	.matrix_pixel_22(matrix_pixel_22), 	.matrix_pixel_23(matrix_pixel_23),
	.matrix_pixel_31(matrix_pixel_31), 	.matrix_pixel_32(matrix_pixel_32), 	.matrix_pixel_33(matrix_pixel_33)
);

//Add you arithmetic here
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//-------------------------------------------
//-------------------------------------------
//Dilation Parameter
//      Original         Dilation			  Pixel
// [   0  0   0  ]   [   1	1   1 ]     [   P1  P2   P3 ]
// [   0  1   0  ]   [   1  1   1 ]     [   P4  P5   P6 ]
// [   0  0   0  ]   [   1  1	1 ]     [   P7  P8   P9 ]
//P = P1 | P2 | P3 | P4 | P5 | P6 | P7 | 8 | 9;
//---------------------------------------
//Dilation with or operation,1 : White,  0 : Black
//Step1
reg	post_img_Bit1,	post_img_Bit2,	post_img_Bit3;
always@(posedge clock or posedge reset) begin
	if(reset) begin
		post_img_Bit1 <= 1'b0;
		post_img_Bit2 <= 1'b0;
		post_img_Bit3 <= 1'b0;
	end
	else begin
		post_img_Bit1 <= matrix_pixel_11 | matrix_pixel_12 | matrix_pixel_13;
		post_img_Bit2 <= matrix_pixel_21 | matrix_pixel_22 | matrix_pixel_23;
		post_img_Bit3 <= matrix_pixel_21 | matrix_pixel_32 | matrix_pixel_33;
	end
end

//Step 2
reg	post_img_Bit4;
always@(posedge clock or posedge reset) begin
	if(reset)
		post_img_Bit4 <= 1'b0;
	else
		post_img_Bit4 <= post_img_Bit1 | post_img_Bit2 | post_img_Bit3;
end

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
		per_img_vsync_d 	<= 	{per_img_vsync_d[0], 	matrix_img_vsync};
		per_img_href_d 	<= 	{per_img_href_d[0], 	matrix_img_href};
	end
end
assign	post_img_vsync 	= 	per_img_vsync_d[1];
assign	post_img_href 	= 	per_img_href_d[1];
assign	post_img_Bit		=	post_img_href ? post_img_Bit4 : 1'b0;

endmodule
