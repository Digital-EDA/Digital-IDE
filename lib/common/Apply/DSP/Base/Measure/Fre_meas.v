module Fre_meas(
	input			  clk_in,	
	input			  square,
	input      [31:0] GATE_TIME,	
	output     [31:0] CNTCLK,		//闸门内系统时钟周期计数
	output     [31:0] CNTSQU		//闸门内待测方波时钟周期计数
);
//parameter   GATE_TIME = 28'd49_999_999;//实际闸门计数是99_999_999，仿真时设为10ms

reg		square_r0 = 1'b0;
reg		square_r1 = 1'b0;
reg		square_r2 = 1'b0;
reg		square_r3 = 1'b0;

reg		gate = 1'b0;	//闸门信号
reg		gatebuf = 1'b0; //与方波同步之后的闸门信号
reg		gatebuf1 = 1'b0;//同步闸门信号延时一拍

reg [31:0]	cnt1 = 28'd0;   //产生 1s 的闸门信号的计数器
reg	[31:0]	cnt2 = 28'd0;
reg	[31:0]	cnt2_r = 28'd0;
reg	[31:0]	cnt3 = 28'd0;
reg	[31:0]	cnt3_r = 28'd0;

wire		square_pose,square_nege;
wire		gate_start,gate_end;

//使方波和100MHz时钟同步并捕捉待测方波的边沿
always @ (posedge clk_in)
begin
	square_r0 <= square;
	square_r1 <= square_r0;//将外部输入的方波打两拍
	square_r2 <= square_r1;
	square_r3 <= square_r2;
end

assign square_pose = square_r2 & ~square_r3;
assign square_nege = ~square_r2 & square_r3;	

always @ (posedge clk_in)
begin
	if(cnt1 == GATE_TIME)begin
		cnt1 <= 28'd0;
		gate <= ~gate;//产生 1s 的闸门信号
		end
	else begin
		cnt1 <= cnt1 + 1'b1; 
		end
end

always @ (posedge clk_in )
begin
	if(square_pose == 1'b1)
	begin 
		gatebuf <= gate;//使闸门信号与待测方波同步，保证一个闸门包含整数个方波周期
	end
	gatebuf1 <= gatebuf;//将同步之后的闸门信号打一拍，用于捕捉闸门信号的边沿
end

assign	gate_start = gatebuf & ~gatebuf1;//表示闸门开始时刻
assign	gate_end = ~gatebuf & gatebuf1;//闸门结束时刻

//计数系统时钟周期
always @ (posedge clk_in)
begin
	if(gate_start == 1'b1) begin
		cnt2 <= 28'd1;
		end
	else if(gate_end == 1'b1) begin
		cnt2_r <= cnt2;//将所得结果保存在cnt2_r中，并将计数器清零
		cnt2 <= 28'd0;
		end
	else if(gatebuf1 == 1'b1) begin//在闸门内计数系统时钟周期
		cnt2 <= cnt2 + 1'b1;end
end

//计数待测方波周期数
always @ (posedge clk_in )
begin
	if(gate_start == 1'b1) begin 
		cnt3 <= 28'd0;
		end
	else if(gate_end == 1'b1) begin 
		cnt3_r <= cnt3;//将所得结果保存在cnt3_r中，并将计数器清零
		cnt3 <= 28'd0;
		end
	else if(gatebuf1 == 1'b1 && square_nege == 1'b1) begin//在闸门内计数待测方波周期数(数闸门内方波的下降沿）
		cnt3 <= cnt3 + 1'b1;
		end
end


assign CNTCLK = cnt2_r;
assign CNTSQU = cnt3_r;

endmodule