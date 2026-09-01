`timescale 1ns/1ns
module Sobel_Edge_Detector #(
	parameter	[10:0]	IMG_HDISP = 11'd640,	//640*480
	parameter	[10:0]	IMG_VDISP = 11'd480
) (
	//global clock
	input				clock,  				//cmos video pixel clock
	input				reset,				//global reset
	//Image data prepred to be processd
	input				per_img_vsync,	//Prepared Image data vsync valid signal
	input				per_img_href,		//Prepared Image data href vaild  signal
	input		[7:0]	per_img_Gray,		//Prepared Image brightness input
	//Image data has been processd
	output				post_img_vsync,	//Processed Image data vsync valid signal
	output				post_img_href,	//Processed Image data href vaild  signal
	output				post_img_Bit,		//Processed Image Bit flag outout(1: Value, 0:inValid)
	//user interface
	input		[7:0]	Sobel_Threshold		//Sobel Threshold for image edge detect
);

//----------------------------------------------------
//Generate 8Bit 3X3 Matrix for Video Image Processor.
//Image data has been processd
wire				matrix_img_vsync;	//Prepared Image data vsync valid signal
wire				matrix_img_href;	//Prepared Image data href vaild  signal
wire		[7:0]	matrix_pixel_11, matrix_pixel_12, matrix_pixel_13;	//3X3 Matrix output
wire		[7:0]	matrix_pixel_21, matrix_pixel_22, matrix_pixel_23;
wire		[7:0]	matrix_pixel_31, matrix_pixel_32, matrix_pixel_33;
Matrix_Generate_3X3 # (
	.DATA_WIDTH (    8    ),
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
) Matrix_Generate_3X3_Buf_u (
	//global clock
	.clock					(clock),  				//cmos video pixel clock
	.reset					(reset),				//global reset
	//Image data prepred to be processd
	.per_img_vsync		    (per_img_vsync),		//Prepared Image data vsync valid signal
	.per_img_href			(per_img_href),		//Prepared Image data href vaild  signal
	.per_img_Data			(per_img_Gray),			//Prepared Image brightness input
	//Image data has been processd
	.post_img_vsync		    (matrix_img_vsync),	//Processed Image data vsync valid signal
	.post_img_href	    	(matrix_img_href),	//Processed Image data href vaild  signal
	.matrix_pixel_11(matrix_pixel_11),	.matrix_pixel_12(matrix_pixel_12), 	.matrix_pixel_13(matrix_pixel_13),	//3X3 Matrix output
	.matrix_pixel_21(matrix_pixel_21), 	.matrix_pixel_22(matrix_pixel_22), 	.matrix_pixel_23(matrix_pixel_23),
	.matrix_pixel_31(matrix_pixel_31), 	.matrix_pixel_32(matrix_pixel_32), 	.matrix_pixel_33(matrix_pixel_33)
);

//Add you arithmetic here
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//-------------------------------------------
//Sobel Parameter
//         Gx                  Gy				  Pixel
// [   -1  0   +1  ]   [   +1  +2   +1 ]     [   P11  P12   P13 ]
// [   -2  0   +2  ]   [   0   0    0  ]     [   P21  P22   P23 ]
// [   -1  0   +1  ]   [   -1  -2   -1 ]     [   P31  P32   P33 ]

// localparam	P11 = 8'd15,	P12 = 8'd94,	P13 = 8'd136;
// localparam	P21 = 8'd31,	P22 = 8'd127,	P23 = 8'd231;
// localparam	P31 = 8'd44,	P32 = 8'd181,	P33 = 8'd249;
//Caculate horizontal Grade with |abs|
//Step 1-2
reg	[9:0]	Gx_temp1;	//postive result
reg	[9:0]	Gx_temp2;	//negetive result
reg	[9:0]	Gx_data;	//Horizontal grade data
always@(posedge clock or posedge reset) begin
	if(reset) begin
		Gx_temp1 <= 0;
		Gx_temp2 <= 0;
		Gx_data <= 0;
	end
	else begin
		Gx_temp1 <= matrix_pixel_13 + (matrix_pixel_23 << 1) + matrix_pixel_33;	//postive result
		Gx_temp2 <= matrix_pixel_11 + (matrix_pixel_21 << 1) + matrix_pixel_31;	//negetive result
		Gx_data <= (Gx_temp1 >= Gx_temp2) ? Gx_temp1 - Gx_temp2 : Gx_temp2 - Gx_temp1;
	end
end

//---------------------------------------
//Caculate vertical Grade with |abs|
//Step 1-2
reg	[9:0]	Gy_temp1;	//postive result
reg	[9:0]	Gy_temp2;	//negetive result
reg	[9:0]	Gy_data;	//Vertical grade data
always@(posedge clock or posedge reset) begin
	if(reset) begin
		Gy_temp1 <= 0;
		Gy_temp2 <= 0;
		Gy_data <= 0;
	end
	else begin
		Gy_temp1 <= matrix_pixel_11 + (matrix_pixel_12 << 1) + matrix_pixel_13;	//postive result
		Gy_temp2 <= matrix_pixel_31 + (matrix_pixel_32 << 1) + matrix_pixel_33;	//negetive result
		Gy_data <= (Gy_temp1 >= Gy_temp2) ? Gy_temp1 - Gy_temp2 : Gy_temp2 - Gy_temp1;
	end
end

//---------------------------------------
//Caculate the square of distance = (Gx^2 + Gy^2)
//Step 3
reg	[20:0]	Gxy_square;
always@(posedge clock or posedge reset) begin
	if(reset)
		Gxy_square <= 0;
	else
		Gxy_square <= Gx_data * Gx_data + Gy_data * Gy_data;
end

//---------------------------------------
//Caculate the distance of P5 = (Gx^2 + Gy^2)^0.5
//Step 4
wire [10:0] Dim; 
Sqrt #(
	.q_port_width (11),
	.r_port_width (12),
	.width        (21)
) SQRT_u (
	.radical	(Gxy_square),
	.q			(Dim),
	.remainder	()
);

//---------------------------------------
//Compare and get the Sobel_data
//Step 5
reg	post_img_Bit_d;
always@(posedge clock or posedge reset) begin
	if(reset)
		post_img_Bit_d <= 1'b0;	//Default None
	else if(Dim >= Sobel_Threshold)
		post_img_Bit_d <= 1'b1;	//Edge Flag
	else
		post_img_Bit_d <= 1'b0;	//Not Edge
end

//------------------------------------------
//lag 5 clocks signal sync  
reg	[4:0]	per_img_vsync_d;
reg	[4:0]	per_img_href_d;	
always@(posedge clock or posedge reset) begin
	if(reset) begin
		per_img_vsync_d <= 5'b0;
		per_img_href_d <= 5'b0;
	end
	else begin
		per_img_vsync_d 	<= 	{per_img_vsync_d[3:0], 	matrix_img_vsync};
		per_img_href_d 	<= 	{per_img_href_d[3:0], 	matrix_img_href};
	end
end
assign	post_img_vsync 	= 	per_img_vsync_d[4];
assign	post_img_href 	= 	per_img_href_d[4];
assign	post_img_Bit	=   post_img_Bit_d;	//post_img_href ? post_img_Bit_d : 1'b0;

endmodule
