`timescale 1ns/1ns
module Gray_Median_Filter #(
	parameter	[10:0]	IMG_HDISP = 11'd640,	//640*480
	parameter	[10:0]	IMG_VDISP = 11'd480
) (
	//global clock
	input				clock,  				//100MHz
	input				reset,				//global reset
	//Image data prepred to be processd
	input				per_img_vsync,	//Prepared Image data vsync valid signal
	input				per_img_href,		//Prepared Image data href vaild  signal
	input		[7:0]	per_img_Gray,		//Prepared Image brightness input
	//Image data has been processd
	output				post_img_vsync,	//Processed Image data vsync valid signal
	output				post_img_href,	//Processed Image data href vaild  signal
	output		[7:0]	post_img_Gray		//Processed Image brightness input
);

//----------------------------------------------------
//Generate 8Bit 3X3 Matrix for Video Image Processor.
	//Image data has been processd
wire				matrix_img_vsync;	//Prepared Image data vsync valid signal
wire				matrix_img_href;	//Prepared Image data href vaild  signal
wire				matrix_img_clocken;	//Prepared Image data output/capture enable clock	
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
//Median Filter of 3X3 datas, need 3 clock
wire	[7:0]	mid_value;
Median_Filter_3X3	u_Median_Filter_3X3(
	.clock			(clock),
	.reset			(reset),
	//ROW1
	.data11			(matrix_pixel_11), 
	.data12			(matrix_pixel_12), 
	.data13			(matrix_pixel_13),
	//ROW2	
	.data21			(matrix_pixel_21), 
	.data22			(matrix_pixel_22), 
	.data23			(matrix_pixel_23),
	//ROW3	
	.data31			(matrix_pixel_31), 
	.data32			(matrix_pixel_32), 
	.data33			(matrix_pixel_33),
	
	.target_data	(mid_value)
);

//------------------------------------------
//lag 3 clocks signal sync  
reg	[2:0]	per_img_vsync_d;
reg	[2:0]	per_img_href_d;	
always@(posedge clock or posedge reset) begin
	if(reset) begin
		per_img_vsync_d <= 0;
		per_img_href_d <= 0;
	end
	else begin
		per_img_vsync_d 	<= 	{per_img_vsync_d[1:0], 	matrix_img_vsync};
		per_img_href_d 	<= 	{per_img_href_d[1:0], 	matrix_img_href};
	end
end
assign	post_img_vsync 	= 	per_img_vsync_d[2];
assign	post_img_href 	= 	per_img_href_d[2];
assign	post_img_Gray		=	post_img_href ? mid_value : 8'd0;

endmodule
