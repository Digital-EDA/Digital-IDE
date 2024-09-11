`timescale 1ns/1ns
module RAW8_RGB888 #(
	parameter	[10:0]	IMG_HDISP = 11'd640,	//640*480
	parameter	[10:0]	IMG_VDISP = 11'd480
) (
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset

	//CMOS YCbCr444 data output
	input				per_frame_vsync,	//Prepared Image data vsync valid signal
	input				per_frame_href,		//Prepared Image data href vaild  signal

	input		[7:0]	per_img_RAW,		//Prepared Image data 8 Bit RAW Data

	
	//CMOS RGB888 data output
	output				post_frame_vsync,	//Processed Image data vsync valid signal
	output				post_frame_href,	//Processed Image data href vaild  signal
	output		[7:0]	post_img_red,		//Prepared Image green data to be processed	
	output		[7:0]	post_img_green,		//Prepared Image green data to be processed
	output		[7:0]	post_img_blue		//Prepared Image blue data to be processed
);

//----------------------------------------------------
//Generate 8Bit 3X3 Matrix for Video Image Processor.
	//Image data has been processd
wire				matrix_frame_vsync;	//Prepared Image data vsync valid signal
wire				matrix_frame_href;	//Prepared Image data href vaild  signal
wire		[7:0]	matrix_p11, matrix_p12, matrix_p13;	//3X3 Matrix output
wire		[7:0]	matrix_p21, matrix_p22, matrix_p23;
wire		[7:0]	matrix_p31, matrix_p32, matrix_p33;
Matrix_Generate_3X3_Buf # (
	.DATA_WIDTH (    8    ),
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
) Matrix_Generate_3X3_Buf_u (
	//global clock
	.clk					(clk),  				//cmos video pixel clock
	.rst_n					(rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(per_frame_vsync),		//Prepared Image data vsync valid signal
	.per_frame_href			(per_frame_href),		//Prepared Image data href vaild  signal
	.per_img_Data			(per_img_RAW),			//Prepared Image brightness input

	//Image data has been processd
	.matrix_frame_vsync		(matrix_frame_vsync),	//Processed Image data vsync valid signal
	.matrix_frame_href		(matrix_frame_href),	//Processed Image data href vaild  signal
	.matrix_p11(matrix_p11),	.matrix_p12(matrix_p12), 	.matrix_p13(matrix_p13),	//3X3 Matrix output
	.matrix_p21(matrix_p21), 	.matrix_p22(matrix_p22), 	.matrix_p23(matrix_p23),
	.matrix_p31(matrix_p31), 	.matrix_p32(matrix_p32), 	.matrix_p33(matrix_p33)
);

//-------------------------------------------------------------
//sync the frame vsync and href signal and generate frame begin & end signal
reg		matrix_frame_href_r;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		matrix_frame_href_r <= 0;
	else
		matrix_frame_href_r <= matrix_frame_href;
end
wire	matrix_frame_href_end	=	(matrix_frame_href_r & ~matrix_frame_href) ? 1'b1 : 1'b0;	//Line over signal

//----------------------------------------
//Count the frame lines
reg	[10:0]	line_cnt;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		line_cnt <= 0;
	else if(matrix_frame_vsync == 1'b1) begin
		if(matrix_frame_href_end)
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
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		point_cnt <= 0;
	else if(matrix_frame_href == 1'b1)	//Line valid
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
reg	[9:0]	post_img_red_r;
reg	[9:0]	post_img_green_r;
reg	[9:0]	post_img_blue_r;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		post_img_red_r	<=	0;
		post_img_green_r<=	0;
		post_img_blue_r	<=	0;
	end
	else begin
		case({line_cnt[0], point_cnt[0]})
		//-------------------------BGBG...BGBG--------------------//
		OddLINE_OddPOINT:begin	//odd lines + odd point
			//Center Blue
			post_img_red_r	<=	(matrix_p11 + matrix_p13 + matrix_p31 + matrix_p33)>>2;
			post_img_green_r<=	(matrix_p12 + matrix_p21 + matrix_p23 + matrix_p32)>>2;
			post_img_blue_r	<=	matrix_p22;		
		end
		OddLINE_Even_POINT:begin	//odd lines + even point
			//Center Green
			post_img_red_r	<=	(matrix_p12 + matrix_p32)>>1;
			post_img_green_r<=	matrix_p22;
			post_img_blue_r	<=	(matrix_p21 + matrix_p23)>>1;
		end
		//-------------------------GRGR...GRGR--------------------//
		EvenLINE_OddPOINT:begin	//even lines + odd point
			//Center Green	
			post_img_red_r	<=	(matrix_p21 + matrix_p23)>>1;
			post_img_green_r<=	matrix_p22;
			post_img_blue_r	<=	(matrix_p12 + matrix_p32)>>1;
		end
		EvenLINE_EvenPOINT:begin //even lines + even point
			//Center Red
			post_img_red_r	<=	matrix_p22;
			post_img_green_r<=	(matrix_p12 + matrix_p21 + matrix_p23 + matrix_p32)>>2;
			post_img_blue_r	<=	(matrix_p11 + matrix_p13 + matrix_p31 + matrix_p33)>>2;
		end
		endcase
	end
end
assign	post_img_red	=	post_img_red_r[7:0];
assign	post_img_green	=	post_img_green_r[7:0];
assign	post_img_blue	=	post_img_blue_r[7:0];

//------------------------------------------
//lag n clocks signal sync  	
reg	[1:0]	post_frame_vsync_r;
reg	[1:0]	post_frame_href_r;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		post_frame_vsync_r 	<= 	0;
		post_frame_href_r 	<= 	0;
	end
	else begin
		post_frame_vsync_r 	<= 	{post_frame_vsync_r[0], matrix_frame_vsync};
		post_frame_href_r 	<= 	{post_frame_href_r[0], 	matrix_frame_href};
	end
end
assign	post_frame_vsync 	= 	post_frame_vsync_r[0];
assign	post_frame_href 	= 	post_frame_href_r[0];

endmodule
