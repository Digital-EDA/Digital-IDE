module uart_rx_control
(
	input		    clk_50m,
	input 			rst_n,
	input			uart_rx_done,
	input  [7:0]    uart_rx_data,
	output [31:0]   data_out_0,
	output [15:0]   data_out_1,
	output [15:0]   data_out_2,
	output 			uart_done
);
reg [31:0] 			uart_data_buf_0;
reg [31:0] 			data_out_r_0;

reg [15:0] 			uart_data_buf_1;
reg [15:0] 			data_out_r_1;

reg [15:0] 			uart_data_buf_2;
reg [15:0] 			data_out_r_2;

reg [4:0] 			state;
reg 				   uart_done_buf;

always@(posedge clk_50m or negedge rst_n)
begin
	if(!rst_n)
	begin
		state <= 4'd0;
		uart_data_buf_0 <= 32'd0;
		uart_data_buf_1 <= 15'd0;
		uart_data_buf_2 <= 15'd0;
		uart_done_buf <= 1'd0;
	end
	else
	begin
		case(state)
			5'd0:begin uart_done_buf<=1'd0; state<=state+1; end
			5'd1:if((uart_rx_data == 8'h99)&&uart_rx_done)begin state<=state+1; end
			5'd2:if((uart_rx_data == 8'h50)&&uart_rx_done)begin state<=state+1; end				
			5'd3:if(uart_rx_done)begin uart_data_buf_0[7:0]<=uart_rx_data;  state<=state+1; end
			5'd4:if(uart_rx_done)begin uart_data_buf_0[15:8]<=uart_rx_data; state<=state+1; end
			5'd5:if(uart_rx_done)begin uart_data_buf_0[23:16]<=uart_rx_data; state<=state+1; end
			5'd6:if(uart_rx_done)begin uart_data_buf_0[31:24]<=uart_rx_data; state<=state+1; end
			5'd7:if(uart_rx_done)begin uart_data_buf_1[7:0]<=uart_rx_data;  state<=state+1; end
			5'd8:if(uart_rx_done)begin uart_data_buf_1[15:8]<=uart_rx_data; state<=state+1; end
			5'd9:if(uart_rx_done)begin uart_data_buf_2[7:0]<=uart_rx_data;  state<=state+1; end
			5'd10:if(uart_rx_done)begin uart_data_buf_2[15:8]<=uart_rx_data; state<=state+1; end
			5'd11:begin data_out_r_0<=uart_data_buf_0; 
							data_out_r_1<=uart_data_buf_1;
							data_out_r_2<=uart_data_buf_2;
							uart_done_buf<=1'd1; state<=4'd0; 
					end
		endcase	
	end
end
assign data_out_0 = data_out_r_0;
assign data_out_1 = data_out_r_1;
assign data_out_2 = data_out_r_2;

assign uart_done = uart_done_buf;
endmodule 