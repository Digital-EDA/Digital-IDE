module ADF_driver
(
	input       clk,        //系统时钟
	input       wrsig,      //发送命令，上升沿有效
	input [8:0] datain,     //需要发送的数据

	output reg tx_idle,         //线路状态指示，高为线路忙，低为线路空闲
	output reg tx,              //发送数据信号
	output reg clkout,
	output reg LE
);

reg tx_send=0;
reg tx_wrsigbuf=0, tx_wrsigrise=0;
reg[7:0] tx_cnt=0; //计数器
//检测发送命令是否有效
reg [15:0] clk_cnt=0;
reg [31:0]dataint=0;
reg [10:0]cnt_init=0;
reg init=0;
reg [4:0] cnt_wei=0;
reg [15:0]int_v=0;
reg [11:0]frac_v=0;


parameter [31:0]R5=32'b00000000_00011_0000000000000000_101;
parameter [31:0]R4=32'b00000000_1101_01100100_000000_111100;
parameter [31:0]R3=32'b00000000_100000010_111111111111_011;
parameter [31:0]R2=32'b00000000_0000000001_00000_001000010;
parameter [31:0]R1=32'b00000_000000000000_000001100100_001;
reg [31:0]R0=32'b0_00000000_10100000_000000000000_000;

always @(posedge clk) begin//分频进程   CLK/(1000000)
  if(clk_cnt == 16'd24) begin
    clkout <= 1'b1;
    clk_cnt <= clk_cnt + 16'd1;
  end
  else if(clk_cnt == 16'd49) begin
    clkout <= 1'b0;
    clk_cnt <= 16'd0;
  end
  else begin
    clk_cnt <= clk_cnt + 16'd1;
  end
end


always @(negedge clkout) begin
	int_v<=datain/7'd100;
	frac_v<=datain%7'd100;
	if(!init) begin
		cnt_init<=cnt_init+1'b1;
		case(cnt_init)
		11'd5: begin R0<=32'b0_00000000_10100000_000000000000_000; end
		11'd1010: begin tx_send <= 1'b1; dataint<=R5; end
		11'd1046: begin tx_send <= 1'b0; end
		11'd1110: begin tx_send <= 1'b1; dataint<=R4; end
		11'd1146: begin tx_send <= 1'b0; end
		11'd1210: begin tx_send <= 1'b1; dataint<=R3; end
		11'd1246: begin tx_send <= 1'b0; end
		11'd1310: begin tx_send <= 1'b1; dataint<=R2; end
		11'd1346: begin tx_send <= 1'b0; end
		11'd1410: begin tx_send <= 1'b1; dataint<=R1; end
		11'd1446: begin tx_send <= 1'b0; end
		11'd1510: begin tx_send <= 1'b1; dataint<=R0; end
		11'd1546: begin tx_send <= 1'b0; end
		11'd1610: begin tx_send <= 1'b1; dataint<=R3; end
		11'd1646: begin tx_send <= 1'b0; end
		11'd1650: begin init<=1'b1; end
		endcase
	end
	else begin
		tx_wrsigbuf <= wrsig;
		tx_wrsigrise <= (~tx_wrsigbuf) & wrsig;
		if (tx_wrsigrise && (~tx_idle)) begin
			tx_send <= 1'b1;
			R0[30:15]<=int_v;
			R0[14:3]<=frac_v;
		end
		else if(tx_cnt == 8'd36) begin
			tx_send <= 1'b0;
		end
	end
end

always @(negedge clkout) begin
	if(tx_send == 1'b1) begin
		case(tx_cnt) //产生起始位
		8'd1: begin
			LE<=1'b0;
			tx <= dataint[31];
			cnt_wei<=5'd31;
			tx_idle <= 1'b1;
			tx_cnt <= tx_cnt + 8'd1;
		end
		8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8,8'd9,8'd10,8'd11,8'd12,8'd13,8'd14,8'd15
		,8'd16,8'd17,8'd18,8'd19,8'd20,8'd21,8'd22,8'd23,8'd24,8'd25,8'd26,8'd27,
		8'd28,8'd29,8'd30,8'd31,8'd32,8'd33: begin
			tx <= dataint[cnt_wei]; //发送数据0 位
			cnt_wei<=cnt_wei-1'b1;
			tx_idle <= 1'b1;
			tx_cnt <= tx_cnt + 8'd1;
		end
		8'd34: begin
			tx <= 1'b1; 
			LE<=1'b1;
			tx_idle <= 1'b0;
			tx_cnt <= tx_cnt + 8'd1;
		end
		default: begin
			tx_cnt <= tx_cnt + 8'd1;
		end
		endcase
	end
	else begin
		tx <= 1'b1;
		LE<=1'b1;
		cnt_wei<=5'd31;
		tx_cnt <= 8'd0;
		tx_idle <= 1'b0;
	end
end

endmodule