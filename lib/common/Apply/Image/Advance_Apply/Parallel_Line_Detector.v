module Parallel_Line_Detector #(
	parameter	IMG_VDISP      = 1240,
	parameter	X_THRESHOLD    = 100,
	parameter	Y_THRESHOLD    = 100,
	parameter	X_Center_Value = 540,
	parameter	Y_Center_Value = 540
) (
	input         clk,
	input         rst_n,
	//
	input		  per_img_Bit,
	input		  per_frame_href,
	input		  per_frame_vsync,
	//
	output        X_up_down,
	output		  Y_up_down,
	output [15:0] X_distance,
	output [15:0] Y_distance
);


//检测行同步信号边沿，一行数据的开始和结束
wire 		href_pos,href_neg,vsync_neg;
reg  [1:0]  per_frame_href_r,per_frame_vsync_r;
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		per_frame_href_r  <= 2'b0;
		per_frame_vsync_r <= 2'b0;
	end
	else begin
		per_frame_href_r  <= {per_frame_href_r[0],per_frame_href};
		per_frame_vsync_r <= {per_frame_vsync_r[0],per_frame_vsync};
	end
end
assign href_pos  =(~per_frame_href_r[1]  & per_frame_href_r[0])  ? 1'b1 : 1'b0; //一行信号的开始
assign href_neg  =(~per_frame_href_r[0]  & per_frame_href_r[1])  ? 1'b1 : 1'b0; //一行信号的结束
assign vsync_neg =(~per_frame_vsync_r[0] & per_frame_vsync_r[1]) ? 1'b1 : 1'b0; //一帧信号的结束

/**************************************直线检测部分**************************************/
wire IMG_BIT_INPUT = ~per_img_Bit; //输入的边缘数据

reg [15:0] x_coordinate_cnt; //列计数器，横坐标 X
reg [15:0] y_coordinate_cnt; //行计数器，纵坐标 Y

reg [15:0] X_edge_center;   //纵向纤芯坐标
reg [15:0] Y_edge_center;   //横向纤芯坐标

//竖线线检测的相关变量
reg  [15:0] X_edge_acc = 0;  			//列边沿坐标的累加
reg  [15:0] X_edge_cnt = 0;   			//列边沿的计数器
reg  [15:0] per_row_acc [IMG_VDISP:1];  //每列的累加值
reg  [IMG_VDISP:1] per_row_flag;        //每列的累加值

//横线检测的相关变量
reg  [15:0] Y_edge_acc = 0;   			//行边沿坐标的累加
reg  [15:0] Y_edge_cnt = 0;   			//行边沿的计数器
reg  [15:0] per_href_acc = 0; 			//每行的累加值

//直线检测处理语句块
integer i;
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		Y_edge_acc <= 16'd0;
		Y_edge_cnt <= 16'd0;
		X_edge_acc <= 16'd0;
		X_edge_cnt <= 16'd0;
		per_href_acc <= 16'd0;
		x_coordinate_cnt <= 16'd0;
		y_coordinate_cnt <= 16'd0;
		for (i = 1; i<=IMG_VDISP; i=i+1) begin
			per_row_acc[i] <= 16'd0;
			per_row_flag[i] <= 1'd0; 
		end
	end
	else if (per_frame_href) begin
		if (href_pos) y_coordinate_cnt <= y_coordinate_cnt + 1'd1;
		else y_coordinate_cnt <= y_coordinate_cnt;
		if ((per_row_acc[x_coordinate_cnt] >= X_THRESHOLD) && (~per_row_flag[x_coordinate_cnt])) begin
			X_edge_cnt <= X_edge_cnt + 1'd1;
			per_row_flag[x_coordinate_cnt] <= 1'b1;
			X_edge_acc <= X_edge_acc + x_coordinate_cnt;
		end
		per_href_acc <= per_href_acc + IMG_BIT_INPUT;
		x_coordinate_cnt <= x_coordinate_cnt + 1'd1;
		per_row_acc[x_coordinate_cnt] <= per_row_acc[x_coordinate_cnt] + IMG_BIT_INPUT;
	end
	else if(href_neg) begin             //一行数据结束
		if(per_href_acc >= Y_THRESHOLD) begin
			Y_edge_cnt <= Y_edge_cnt + 1'd1;
			Y_edge_acc <= Y_edge_acc + y_coordinate_cnt;
		end
		per_href_acc <= 16'd0;
		x_coordinate_cnt <= 16'd0;
	end	
	else if (vsync_neg) begin
		X_edge_center = X_edge_acc / X_edge_cnt;
		Y_edge_center = Y_edge_acc / Y_edge_cnt;
		X_edge_acc <= 16'd0; X_edge_cnt <= 16'd0;
		Y_edge_acc <= 16'd0; Y_edge_cnt <= 16'd0;
		for (i = 1; i<=IMG_VDISP; i=i+1) begin
			per_row_acc[i] <= 16'd0;
			per_row_flag[i] <= 1'd0; 
		end
		y_coordinate_cnt <= 16'd0;
	end
end

assign X_distance = $signed(X_edge_center) - $signed(X_Center_Value);
assign Y_distance = $signed(Y_edge_center) - $signed(Y_Center_Value);
assign X_up_down  = X_distance[16];
assign Y_up_down  = Y_distance[16];

endmodule
