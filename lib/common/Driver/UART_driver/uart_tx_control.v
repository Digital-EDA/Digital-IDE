module uart_tx_control
(
	input 			clk_50m,
	input 			rst_n,
	input 			uart_tx_done,
   input 			start_sig,
	input  [31:0]	uart_data_a,
	input  [31:0]	uart_data_b,
	input  [1:0]	mod,
	output [7:0] 	uart_tx_data,
	output 			tx_sig_q,
	output 			uart_tx_en
);
parameter 			clk_pw_div_1 = 16'd44999;
parameter 			clk_pw_div_2 = 16'd249999;
reg [4:0] 			state;
reg [7:0] 			uart_tx_data_r;
reg 					tx_en_r;
reg  					tx_sig;
reg [31:0] 			uart_data_a_buf;
reg [31:0] 			uart_data_b_buf;
reg 					start_sig_buf;
reg [2:0] 			state_sweep;
reg [2:0] 			state_piont;
reg [22:0] 			clk_cnt;
always@(posedge clk_50m or negedge rst_n)
begin
	if(!rst_n)
	begin
		start_sig_buf <= 1'd0;
		state_sweep <= 3'd0;
		state_piont <= 3'd0;
		clk_cnt <= 23'd0;
	end
	else if(mod == 2'b01)//扫频
	begin
		state_piont <= 3'd0;
		case(state_sweep)
			3'd0:begin start_sig_buf<=1'd0; clk_cnt<=15'd0; state_sweep<=3'd1;end
			3'd1:begin if(start_sig) state_sweep<=2'd2;end
			3'd2:begin if(clk_cnt==clk_pw_div_1) state_sweep<=3'd3; else clk_cnt<=clk_cnt+23'd1;end
			3'd3:begin start_sig_buf<=1'd1; state_sweep<=3'd0; end
		endcase
	end
	else if(mod == 2'b10)//点频
	begin
		state_sweep <= 3'd0;
		case(state_piont)
			3'd0:begin start_sig_buf<=1'd0; clk_cnt<=15'd0; state_piont<=3'd1;end
			3'd1:begin if(start_sig) state_piont<=2'd2;end
			3'd2:begin start_sig_buf<=1'd0; if(clk_cnt==clk_pw_div_2) state_piont<=3'd3; else clk_cnt<=clk_cnt+23'd1;end
			3'd3:begin start_sig_buf<=1'd1; clk_cnt<=15'd0; state_piont<=3'd2; end
		endcase
	end
	else
	begin
		start_sig_buf <= 1'd0;
		state_sweep <= 3'd0;
		state_piont <= 3'd0;
		clk_cnt <= 15'd0;
	end
end

always@(posedge clk_50m or negedge rst_n)
begin
	if(!rst_n)
	begin
		uart_data_a_buf <= 28'd0;
		uart_data_b_buf <= 28'd0;
	end
	else if(start_sig_buf)
	begin
		uart_data_a_buf <= uart_data_a;
		uart_data_b_buf <= uart_data_b;
	end
end
always@(posedge clk_50m or negedge rst_n)
begin
	if(!rst_n)
	begin
		state <= 5'd0;
		tx_sig <= 1'd0;
		uart_tx_data_r <= 8'd0;
		tx_en_r <= 1'd0;
	end
	else
	begin
		case(state)
			5'd0:begin if(start_sig_buf)begin state<=state+1; tx_sig<=0; tx_en_r<=1; end end
			5'd1:begin uart_tx_data_r<=8'h99; tx_en_r<=1; state<=state+1; end
			5'd2:begin if(uart_tx_done) begin uart_tx_data_r<=8'h24; tx_en_r<=1; state<=state+1; end end
			5'd3:begin if(uart_tx_done) begin uart_tx_data_r<=uart_data_a_buf[7:0];  tx_en_r<=1; state<=state+1; end end
			5'd4:begin if(uart_tx_done) begin uart_tx_data_r<=uart_data_a_buf[15:8]; tx_en_r<=1; state<=state+1; end end
			5'd5:begin if(uart_tx_done) begin uart_tx_data_r<=uart_data_a_buf[23:16]; tx_en_r<=1; state<=state+1; end end
			5'd6:begin if(uart_tx_done) begin uart_tx_data_r<=uart_data_a_buf[31:24]; tx_en_r<=1; state<=state+1; end end
			5'd7:begin if(uart_tx_done) begin uart_tx_data_r<=uart_data_b_buf[7:0];  tx_en_r<=1; state<=state+1; end end
			5'd8:begin if(uart_tx_done) begin uart_tx_data_r<=uart_data_b_buf[15:8]; tx_en_r<=1; state<=state+1; end end
			5'd9:begin if(uart_tx_done) begin uart_tx_data_r<=uart_data_b_buf[23:16]; tx_en_r<=1; state<=state+1; end end
			5'd10:begin if(uart_tx_done) begin uart_tx_data_r<=uart_data_b_buf[31:24]; tx_en_r<=1; state<=state+1; end end
			5'd11:begin tx_en_r<=0; state<=state+1; end
			5'd12:begin if(uart_tx_done) begin tx_sig<=1; state<=5'd0;end end
			default:begin state <= 0; end
		endcase
	end
end
assign uart_tx_data = uart_tx_data_r;
assign uart_tx_en = tx_en_r;
assign tx_sig_q = tx_sig;
endmodule 

