`timescale 1ns / 1ps
module Image_XYCrop(
	input			clk,				
	input			rst_n,				
	
	//CMOS 
	input			image_in_vsync,		
	input			image_in_href,		
	input		   	image_in_data,

	output			image_out_vsync,	
	output			image_out_href_left,	
	output		   	image_out_data_left,
    output			image_out_href_right,                                    	
    output		   	image_out_data_right                                       	
);

//-----------------------------------
reg		image_in_href_r  = 0;
reg		image_in_vsync_r = 0;
reg	   	image_in_data_r  = 0;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		image_in_vsync_r <= 0;
		image_in_href_r <= 0;
		image_in_data_r <= 0;
	end
	else begin
		image_in_vsync_r <= image_in_vsync;
		image_in_href_r <= image_in_href;
		image_in_data_r <= image_in_data;
	end
end
//-----------------------------------
//Image Ysize Crop
reg	 [11:0] image_ypos = 0;
wire image_in_href_negedge = (image_in_href_r & ~image_in_href) ? 1'b1 : 1'b0;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		image_ypos <= 0;
	else if(image_in_vsync == 1'b1) begin
		if(image_in_href_negedge == 1'b1)   //行同步信号的下降沿，一行信号赋值完成后，image_ypos累加1
			image_ypos <= image_ypos + 1'b1;
		else
			image_ypos <= image_ypos;
	end
	else
		image_ypos <= 0;
end
assign	image_out_vsync = image_in_vsync_r; // image_out_vsync是打一拍后的 image_in_vsync的信号，延时了一个时钟周期
			   
//-----------------------------------
//Image Hsize Crop
reg	[11:0] image_xpos = 0;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		image_xpos <= 0;
	else if(image_in_href == 1'b1)
		image_xpos <= image_xpos + 1'b1;
	else
		image_xpos <= 0;
end

assign	image_out_href_right = ((image_in_href_r == 1'b1) && (image_xpos > 10'd640) && (image_xpos < 12'd1280)) ? 1'b1 : 1'b0;
assign	image_out_data_right = (image_out_vsync & image_out_href_right) ? image_in_data_r : 1'd0;				   
assign	image_out_href_left  = ((image_in_href_r == 1'b1) && (image_xpos <= 10'd640)) ? 1'b1 : 1'b0;	 
assign	image_out_data_left  = (image_out_vsync & image_out_href_left)  ? image_in_data_r : 1'd0;

endmodule
