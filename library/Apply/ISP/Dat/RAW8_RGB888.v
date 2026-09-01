`timescale 1ns/1ns
module RAW8_RGB888 #(
	parameter	[10:0]	IMG_HDISP = 11'd640,	//640*480
	parameter	[10:0]	IMG_VDISP = 11'd480
) (
	//global clock
	input				clock,  			//cmos video pixel clock
	input				reset,				//global reset

	//CMOS YCbCr444 data output
	input				per_img_vsync,	    //Prepared Image data vsync valid signal
	input				per_img_href,		//Prepared Image data href vaild  signal

	input		[7:0]	per_img_RAW,		//Prepared Image data 8 Bit RAW Data

	
	//CMOS RGB888 data output
	output				post_img_vsync,	     //Processed Image data vsync valid signal
	output				post_img_href,	     //Processed Image data href vaild  signal
	output		[7:0]	post_img_red,		 //Prepared  Image green data to be processed	
	output		[7:0]	post_img_green,		 //Prepared  Image green data to be processed
	output		[7:0]	post_img_blue		 //Prepared  Image blue data to be processed
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
	.per_img_vsync		(per_img_vsync),		//Prepared Image data vsync valid signal
	.per_img_href			(per_img_href),		//Prepared Image data href vaild  signal
	.per_img_Data			(per_img_RAW),			//Prepared Image brightness input

	//Image data has been processd
	.post_img_vsync		(matrix_img_vsync),	//Processed Image data vsync valid signal
	.post_img_href		(matrix_img_href),	//Processed Image data href vaild  signal
	.matrix_pixel_11(matrix_pixel_11),	.matrix_pixel_12(matrix_pixel_12), 	.matrix_pixel_13(matrix_pixel_13),	//3X3 Matrix output
	.matrix_pixel_21(matrix_pixel_21), 	.matrix_pixel_22(matrix_pixel_22), 	.matrix_pixel_23(matrix_pixel_23),
	.matrix_pixel_31(matrix_pixel_31), 	.matrix_pixel_32(matrix_pixel_32), 	.matrix_pixel_33(matrix_pixel_33)
);

//-------------------------------------------------------------
//sync the frame vsync and href signal and generate frame begin & end signal
reg		matrix_img_href_d;
always@(posedge clock or posedge reset) begin
	if(reset)
		matrix_img_href_d <= 0;
	else
		matrix_img_href_d <= matrix_img_href;
end
wire	matrix_img_href_end	=	(matrix_img_href_d & ~matrix_img_href) ? 1'b1 : 1'b0;	//Line over signal

//----------------------------------------
//Count the frame lines
reg	[10:0]	line_cnt;
always@(posedge clock or posedge reset) begin
	if(reset)
		line_cnt <= 0;
	else if(matrix_img_vsync == 1'b1) begin
		if(matrix_img_href_end)
			line_cnt <= (line_cnt < IMG_VDISP - 1'b1) ? line_cnt + 1'b1 : 10'd0;
		else
			line_cnt <= line_cnt;
	end
	else
		line_cnt <= 0;
end

//----------------------------------------
//Count the pixels
reg	[10:0]	point_cnt;
always@(posedge clock or posedge reset) begin
	if(reset)
		point_cnt <= 0;
	else if(matrix_img_href == 1'b1)	//Line valid
		point_cnt <= (line_cnt < IMG_HDISP - 1'b1) ? point_cnt + 1'b1 : 10'd0;
	else
		point_cnt <= 0;
end

//--------------------------------------
//Convet RAW 2 RGB888 Format
//
localparam	OddLINE_OddPOINT	=	2'b10;	//odd lines + odd point
localparam	OddLINE_Even_POINT	=	2'b11;	//odd lines + even point
localparam	EvenLINE_OddPOINT	=	2'b00;	//even lines + odd point
localparam	EvenLINE_EvenPOINT	=	2'b01;	//even lines + even point
reg	[9:0]	post_img_red_d;
reg	[9:0]	post_img_green_d;
reg	[9:0]	post_img_blue_d;
always@(posedge clock or posedge reset) begin
	if(reset) begin
		post_img_red_d	<=	0;
		post_img_green_d<=	0;
		post_img_blue_d	<=	0;
	end
	else begin
		case({line_cnt[0], point_cnt[0]})
		//-------------------------BGBG...BGBG--------------------//
		OddLINE_OddPOINT:begin	//odd lines + odd point
			//Center Blue
			post_img_red_d	<=	(matrix_pixel_11 + matrix_pixel_13 + matrix_pixel_31 + matrix_pixel_33)>>2;
			post_img_green_d<=	(matrix_pixel_12 + matrix_pixel_21 + matrix_pixel_23 + matrix_pixel_32)>>2;
			post_img_blue_d	<=	matrix_pixel_22;		
		end
		OddLINE_Even_POINT:begin	//odd lines + even point
			//Center Green
			post_img_red_d	<=	(matrix_pixel_12 + matrix_pixel_32)>>1;
			post_img_green_d<=	matrix_pixel_22;
			post_img_blue_d	<=	(matrix_pixel_21 + matrix_pixel_23)>>1;
		end
		//-------------------------GRGR...GRGR--------------------//
		EvenLINE_OddPOINT:begin	//even lines + odd point
			//Center Green	
			post_img_red_d	<=	(matrix_pixel_21 + matrix_pixel_23)>>1;
			post_img_green_d<=	matrix_pixel_22;
			post_img_blue_d	<=	(matrix_pixel_12 + matrix_pixel_32)>>1;
		end
		EvenLINE_EvenPOINT:begin //even lines + even point
			//Center Red
			post_img_red_d	<=	matrix_pixel_22;
			post_img_green_d<=	(matrix_pixel_12 + matrix_pixel_21 + matrix_pixel_23 + matrix_pixel_32)>>2;
			post_img_blue_d	<=	(matrix_pixel_11 + matrix_pixel_13 + matrix_pixel_31 + matrix_pixel_33)>>2;
		end
		endcase
	end
end
assign	post_img_red	=	post_img_red_d[7:0];
assign	post_img_green	=	post_img_green_d[7:0];
assign	post_img_blue	=	post_img_blue_d[7:0];

//------------------------------------------
//lag n clocks signal sync  	
reg	[1:0]	post_img_vsync_d;
reg	[1:0]	post_img_href_d;
always@(posedge clock or posedge reset) begin
	if(reset) begin
		post_img_vsync_d 	<= 	0;
		post_img_href_d 	<= 	0;
	end
	else begin
		post_img_vsync_d 	<= 	{post_img_vsync_d[0],   matrix_img_vsync};
		post_img_href_d 	<= 	{post_img_href_d[0], 	matrix_img_href};
	end
end
assign	post_img_vsync 	= 	post_img_vsync_d[0];
assign	post_img_href 	= 	post_img_href_d[0];

endmodule
