`timescale 1ns/1ns
module Matrix_Generate_3X3_Buf #(
	parameter DATA_WIDTH = 8,
	parameter IMG_HDISP  = 640,	//640*480
	parameter IMG_VDISP  = 480
) (
	//global clock
	input				 	clk,  				//cmos video pixel clock
	input				 	rst_n,				//global reset

	//Image data prepred to be processd
	input				 	per_frame_vsync,	//Prepared Image data vsync valid signal
	input				 	per_frame_href,		//Prepared Image data href vaild  signal
	input [DATA_WIDTH-1:0]  per_img_Data,		//Prepared Image brightness input

	//Image data has been processd
	output				 	matrix_frame_vsync,	//Prepared Image data vsync valid signal
	output				 	matrix_frame_href,	//Prepared Image data href vaild  signal

	output	reg	[DATA_WIDTH-1:0]	matrix_p11, matrix_p12, matrix_p13,	//3X3 Matrix output
	output	reg	[DATA_WIDTH-1:0]	matrix_p21, matrix_p22, matrix_p23,
	output	reg	[DATA_WIDTH-1:0]	matrix_p31, matrix_p32, matrix_p33
);


//Generate 3*3 matrix 
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
//--------------------------------------------------------------------------
//sync row3_data with per_frame_clken & row1_data & raw2_data
wire [DATA_WIDTH-1:0] row1_data;	//frame data of the 1th row
wire [DATA_WIDTH-1:0] row2_data;	//frame data of the 2th row
reg	 [DATA_WIDTH-1:0] row3_data;	//frame data of the 3th row
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		row3_data <= 0;
	else begin
		if(per_frame_href)
			row3_data <= per_img_Data;
		else
			row3_data <= row3_data;
	end	
end

//---------------------------------------
//module of shift ram for raw data
wire	shift_clk_en = per_frame_href;
Line_Shift_RAM #(
    .RAM_Length (  IMG_HDISP  ),
    .DATA_WIDTH (  DATA_WIDTH )
) u_Line_Shift_RAM (
    .clock                   ( clk          ),
    .clken                   ( shift_clk_en ),
    .shiftin                 ( row3_data    ),

    .taps0x                  ( row2_data    ),
    .taps1x                  ( row1_data    )
);
//------------------------------------------
//lag 2 clocks signal sync  
reg	[2:0]	per_frame_vsync_r;
reg	[2:0]	per_frame_href_r;	
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		per_frame_vsync_r <= 0;
		per_frame_href_r <= 0;
		end
	else begin
		per_frame_vsync_r 	<= 	{per_frame_vsync_r[1:0], 	per_frame_vsync};
		per_frame_href_r 	<= 	{per_frame_href_r[1:0], 	per_frame_href};
	end
end
//Give up the 1th and 2th row edge data caculate for simple process
//Give up the 1th and 2th point of 1 line for simple process
wire	read_frame_href		=	per_frame_href_r[0]|per_frame_href_r[1];	//RAM read href sync signal
assign	matrix_frame_vsync 	= 	per_frame_vsync_r[2];
assign	matrix_frame_href 	= 	per_frame_href_r[2];

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
//wire	[23:0]	matrix_row1 = {matrix_p11, matrix_p12, matrix_p13};	//Just for test
//wire	[23:0]	matrix_row2 = {matrix_p21, matrix_p22, matrix_p23};
//wire	[23:0]	matrix_row3 = {matrix_p31, matrix_p32, matrix_p33};
reg		[31:0]	            pixel_cnt;
reg		[DATA_WIDTH-1:0]	row1_data0; 
reg		[DATA_WIDTH-1:0]	row2_data0; 
reg		[DATA_WIDTH-1:0]	row3_data0; 
reg		[DATA_WIDTH-1:0]	row1_data1; 
reg		[DATA_WIDTH-1:0]	row2_data1; 
reg		[DATA_WIDTH-1:0]	row3_data1;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		pixel_cnt <= 0;
		row1_data0 <= 0; row1_data1 <= 0;
		row2_data0 <= 0; row2_data1 <= 0;
		row3_data0 <= 0; row3_data1 <= 0;
		{matrix_p11, matrix_p12, matrix_p13} <= 0;
		{matrix_p21, matrix_p22, matrix_p23} <= 0;
		{matrix_p31, matrix_p32, matrix_p33} <= 0;
	end
	else if(read_frame_href) begin
		pixel_cnt <=  (pixel_cnt < IMG_HDISP) ? pixel_cnt + 1'b1 : 32'd0;	//Point Counter
		{row1_data1, row1_data0} <= {row1_data0, row1_data};
		{row2_data1, row2_data0} <= {row2_data0, row2_data};
		{row3_data1, row3_data0} <= {row3_data0, row3_data};
		if(pixel_cnt == 0) begin
			{matrix_p11, matrix_p12, matrix_p13} <= 0;
			{matrix_p21, matrix_p22, matrix_p23} <= 0;
			{matrix_p31, matrix_p32, matrix_p33} <= 0;
		end
		else if(pixel_cnt == 1) begin	
			{matrix_p11, matrix_p12, matrix_p13} <= {row1_data, row1_data0, row1_data};			
			{matrix_p21, matrix_p22, matrix_p23} <= {row2_data, row2_data0, row2_data};	
			{matrix_p31, matrix_p32, matrix_p33} <= {row3_data, row3_data0, row3_data};	
		end
		else if(pixel_cnt == IMG_HDISP) begin		
			{matrix_p11, matrix_p12, matrix_p13} <= {row1_data1, row1_data,	row1_data1};
			{matrix_p21, matrix_p22, matrix_p23} <= {row2_data1, row2_data,	row2_data1};
			{matrix_p31, matrix_p32, matrix_p33} <= {row3_data1, row3_data,	row3_data1};
		end
		else begin
			{matrix_p11, matrix_p12, matrix_p13} <= {row1_data1, row1_data0, row1_data};
			{matrix_p21, matrix_p22, matrix_p23} <= {row2_data1, row2_data0, row2_data};
			{matrix_p31, matrix_p32, matrix_p33} <= {row3_data1, row3_data0, row3_data};
		end
	end
	else begin
		pixel_cnt <= 0;
		{matrix_p11, matrix_p12, matrix_p13} <= 0;
		{matrix_p21, matrix_p22, matrix_p23} <= 0;
		{matrix_p31, matrix_p32, matrix_p33} <= 0;
	end
end

endmodule
