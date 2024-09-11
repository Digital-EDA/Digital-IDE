`timescale 1ns/1ns
module Video_Image_Processor #(
	parameter RAW2RG888_YUV444	= "ON",
	parameter GRAY_MEDIUM		= "ON",
	parameter GRAY_SOBEL 		= "ON",
	parameter GRAY_EROSION		= "ON",
	parameter GRAY_DILATION		= "ON",
	parameter IMG_HDISP 		= 11'd640,	//640*480
	parameter IMG_VDISP 		= 11'd480
) (
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset
	//Image data prepred to be processd
	input				per_frame_vsync,	//Prepared Image data vsync valid signal
	input				per_frame_href,		//Prepared Image data href vaild  signal
	input		[7:0]	per_img_RAW,		//Prepared Image data of YCbCr 4:2:2 {CbY} {CrY}
	//Image data has been processd
	output				post_frame_vsync,	//Processed Image data vsync valid signal
	output				post_frame_href,	//Processed Image data href vaild  signal
	output		[7:0]	post_img_Gray,		//Processed Image Gray output
	//user interface
	input		[7:0]	Sobel_Threshold		//Sobel Threshold for image edge detect	
);

//-------------------------------------
//Convert the RAW format to RGB888 format.
wire				post1_frame_vsync;	//Processed Image data vsync valid signal
wire				post1_frame_href;	//Processed Image data href vaild  signal
wire		[7:0]	post1_img_red;		//Processed Image Red output
wire		[7:0]	post1_img_green;	//Processed Image Green output
wire		[7:0]	post1_img_blue;		//Processed Image Blueoutput
wire				post2_frame_vsync;	//Processed Image data vsync valid signal
wire				post2_frame_href;	//Processed Image data href vaild  signal
wire		[7:0]	post2_img_Gray;		//Processed Image Gray output

generate if(RAW2RG888_YUV444 == "ON") begin : RAW2RG888_YUV444_ON
	RAW8_RGB888	# (
		.IMG_HDISP	(IMG_HDISP),	//640*480
		.IMG_VDISP	(IMG_VDISP)
	) RAW8_RGB888_u (
		//global clock
		.clk					(clk),					//cmos video pixel clock
		.rst_n					(rst_n),				//system reset

		//Image data prepred to be processd
		.per_frame_vsync		(per_frame_vsync),		//Prepared Image data vsync valid signal
		.per_frame_href			(per_frame_href),		//Prepared Image data href vaild  signal
		.per_img_RAW			(per_img_RAW),			//Prepared Image data 8 Bit RAW Data
		
		//Image data has been processd
		.post_frame_vsync		(post1_frame_vsync),	//Processed Image data vsync valid signal
		.post_frame_href		(post1_frame_href),		//Processed Image data href vaild  signal
		.post_img_red			(post1_img_red),		//Prepared Image green data to be processed	
		.post_img_green			(post1_img_green),		//Prepared Image green data to be processed
		.post_img_blue			(post1_img_blue)		//Prepared Image blue data to be processed
	);
	//-------------------------------------
	//Convert the RGB888 format to YCbCr444 format.
	RGB888_YCbCr444	RGB888_YCbCr444_u(
		//global clock
		.clk				(clk),					//cmos video pixel clock
		.rst_n				(rst_n),				//system reset

		//Image data prepred to be processd
		.per_frame_vsync	(post1_frame_vsync),	//Prepared Image data vsync valid signal
		.per_frame_href		(post1_frame_href),		//Prepared Image data href vaild  signal
		.per_img_red		(post1_img_red),		//Prepared Image red data input
		.per_img_green		(post1_img_green),		//Prepared Image green data input
		.per_img_blue		(post1_img_blue),		//Prepared Image blue data input
		
		//Image data has been processd
		.post_frame_vsync	(post2_frame_vsync),	//Processed Image frame data valid signal
		.post_frame_href	(post2_frame_href),		//Processed Image hsync data valid signal
		.post_img_Y			(post2_img_Gray),		//Processed Image brightness output
		.post_img_Cb		(),						//Processed Image blue shading output
		.post_img_Cr		()						//Processed Image red shading output
	);
end
else if(RAW2RG888_YUV444 == "OFF") begin : RAW2RG888_YUV444_OFF
	assign	post2_frame_vsync = per_frame_vsync;
	assign	post2_frame_href = per_frame_href;
	assign	post2_img_Gray = per_img_RAW;
end
endgenerate

//--------------------------------------
//Gray Image median filter for better picture quality.
wire				post3_frame_vsync;	//Processed Image data vsync valid signal
wire				post3_frame_href;	//Processed Image data href vaild  signal
wire		[7:0]	post3_img_Gray;		//Processed Image Gray output
generate if(GRAY_MEDIUM == "ON") begin : GRAY_MEDIUM_ON
	Gray_Median_Filter # (
		.IMG_HDISP	(IMG_HDISP),	//640*480
		.IMG_VDISP	(IMG_VDISP)
	) Gray_Median_Filter_u (
		//global clock
		.clk					(clk),  				//cmos video pixel clock
		.rst_n					(rst_n),				//global reset

		//Image data prepred to be processd
		.per_frame_vsync		(post2_frame_vsync),		//Prepared Image data vsync valid signal
		.per_frame_href			(post2_frame_href),		//Prepared Image data href vaild  signal
		.per_img_Gray			(post2_img_Gray),			//Prepared Image brightness input

		//Image data has been processd
		.post_frame_vsync		(post3_frame_vsync),	//Processed Image data vsync valid signal
		.post_frame_href		(post3_frame_href),		//Processed Image data href vaild  signal
		.post_img_Gray			(post3_img_Gray)		//Processed Image brightness output
	);
end
else if(GRAY_MEDIUM == "OFF") begin : GRAY_MEDIUM_OFF
	assign	post3_frame_vsync = post2_frame_vsync;
	assign	post3_frame_href = post2_frame_href;
	assign	post3_img_Gray = post2_img_Gray;
end
endgenerate

//--------------------------------------
//Image edge detector with Sobel.
wire			post4_frame_vsync;	//Processed Image data vsync valid signal
wire			post4_frame_href;	//Processed Image data href vaild  signal
wire			post4_img_Bit;		//Processed Image Bit flag outout(1: Value, 0:inValid)
wire	[7:0]	post4_img_Gray;		
generate if(GRAY_SOBEL == "ON") begin : GRAY_SOBEL_ON
	Sobel_Edge_Detector # (
		.IMG_HDISP	(IMG_HDISP),	//640*480
		.IMG_VDISP	(IMG_VDISP)
	) Sobel_Edge_Detector_u (
		//global clock
		.clk					(clk),  				//cmos video pixel clock
		.rst_n					(rst_n),				//global reset

		//Image data prepred to be processd
		.per_frame_vsync		(post3_frame_vsync),	//Prepared Image data vsync valid signal
		.per_frame_href			(post3_frame_href),		//Prepared Image data href vaild  signal
		.per_img_Gray			(post3_img_Gray),		//Prepared Image brightness input

		//Image data has been processd
		.post_frame_vsync		(post4_frame_vsync),	//Processed Image data vsync valid signal
		.post_frame_href		(post4_frame_href),		//Processed Image data href vaild  signal
		.post_img_Bit			(post4_img_Bit),		//Processed Image Bit flag outout(1: Value, 0:inValid)
		
		//User interface
		.Sobel_Threshold		(Sobel_Threshold)		//Sobel Threshold for image edge detect
	);
	assign	post4_img_Gray = {8{~post4_img_Bit}};
end
else if(GRAY_SOBEL == "OFF") begin : GRAY_SOBEL_OFF
	assign	post4_frame_vsync = post3_frame_vsync;
	assign	post4_frame_href  = post3_frame_href;
	assign	post4_img_Gray    = post3_img_Gray;
end
endgenerate

//--------------------------------------
//Bit Image Process with Erosion before Dilation Detector.
wire			post5_frame_vsync;	//Processed Image data vsync valid signal
wire			post5_frame_href;	//Processed Image data href vaild  signal
wire			post5_img_Bit;		//Processed Image Bit flag outout(1: Value, 0:inValid)
wire	[7:0]	post5_img_Gray;	
generate if(GRAY_EROSION == "ON") begin : GRAY_EROSION_ON
	Bit_Erosion_Detector # (
		.IMG_HDISP	(IMG_HDISP),	//640*480
		.IMG_VDISP	(IMG_VDISP)
	) Bit_Erosion_Detector_u (
		//global clock
		.clk					(clk),  				//cmos video pixel clock
		.rst_n					(rst_n),				//global reset

		//Image data prepred to be processd
		.per_frame_vsync		(post4_frame_vsync),	//Prepared Image data vsync valid signal
		.per_frame_href			(post4_frame_href),		//Prepared Image data href vaild  signal
		.per_img_Bit			(post4_img_Gray[0]),	//Processed Image Bit flag outout(1: Value, 0:inValid)

		//Image data has been processd
		.post_frame_vsync		(post5_frame_vsync),	//Processed Image data vsync valid signal
		.post_frame_href		(post5_frame_href),		//Processed Image data href vaild  signal
		.post_img_Bit			(post5_img_Bit)			//Processed Image Bit flag outout(1: Value, 0:inValid)
	);
	assign	post5_img_Gray = {8{post5_img_Bit}};
end
else if(GRAY_EROSION == "OFF") begin : GRAY_EROSION_OFF
	assign	post5_frame_vsync = post4_frame_vsync;
	assign	post5_frame_href = post4_frame_href;
	assign	post5_img_Gray = post4_img_Gray;
end
endgenerate

//--------------------------------------
//Bit Image Process with Dilation after Erosion Detector.
wire			post6_frame_vsync;	//Processed Image data vsync valid signal
wire			post6_frame_href;	//Processed Image data href vaild  signal
wire			post6_img_Bit;		//Processed Image Bit flag outout(1: Value, 0:inValid)
wire	[7:0]	post6_img_Gray;	
generate if(GRAY_DILATION == "ON") begin : GRAY_DILATION_ON
	Bit_Dilation_Detector # (
		.IMG_HDISP	(IMG_HDISP),	//640*480
		.IMG_VDISP	(IMG_VDISP)
	) Bit_Dilation_Detector_u (
		//global clock
		.clk					(clk),  				//cmos video pixel clock
		.rst_n					(rst_n),				//global reset

		//Image data prepred to be processd
		.per_frame_vsync		(post5_frame_vsync),	//Prepared Image data vsync valid signal
		.per_frame_href			(post5_frame_href),		//Prepared Image data href vaild  signal
		.per_img_Bit			(post5_img_Gray[0]),	//Processed Image Bit flag outout(1: Value, 0:inValid)

		//Image data has been processd
		.post_frame_vsync		(post6_frame_vsync),	//Processed Image data vsync valid signal
		.post_frame_href		(post6_frame_href),		//Processed Image data href vaild  signal
		.post_img_Bit			(post6_img_Bit)			//Processed Image Bit flag outout(1: Value, 0:inValid)
	);
	assign	post6_img_Gray = {8{post6_img_Bit}};
end
else if(GRAY_DILATION == "OFF") begin : GRAY_DILATION_OFF
	assign	post6_frame_vsync = post5_frame_vsync;
	assign	post6_frame_href = post5_frame_href;
	assign	post6_img_Gray = post5_img_Gray;
end
endgenerate

assign	post_frame_vsync = post6_frame_vsync;	//Processed Image data vsync valid signal
assign	post_frame_href  = post6_frame_href;	//Processed Image data href vaild  signal
assign	post_img_Gray    = post6_img_Gray;		//Processed Image Gray output	

endmodule
