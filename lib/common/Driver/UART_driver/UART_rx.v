`timescale 1ns / 1ps

module uart_rx(
	input clk_50m,
	input uart_rx,
	output [7:0] uart_rx_data,
	output uart_rx_done
    );
    
parameter [12:0] BAUD_DIV     = 13'd87;//bps115200  每位数据传输时间为t=1/115200 s,周期T=1/100000000，计数值为t/T=868
parameter [12:0] BAUD_DIV_CAP = 13'd43;   

reg [12:0] baud_div=0;				      
reg baud_bps=0;					            
reg bps_start=0;					          
always@(posedge clk_50m)
begin
	if(baud_div==BAUD_DIV_CAP)	    	     
		begin
			baud_bps<=1'b1;
			baud_div<=baud_div+1'b1;
		end
	else if(baud_div<BAUD_DIV && bps_start) 
		begin
			baud_div<=baud_div+1'b1;
			baud_bps<=0;
		end
	else
		begin
			baud_bps<=0;
			baud_div<=0;
		end
end

reg [4:0] uart_rx_r=5'b11111;			 
always@(posedge clk_50m)
begin
	uart_rx_r<={uart_rx_r[3:0],uart_rx};
end
wire uart_rxnt=uart_rx_r[4]|uart_rx_r[3]|uart_rx_r[2]|uart_rx_r[1]|uart_rx_r[0];

reg [3:0] bit_num=0;	    
reg state=1'b0;

reg [7:0] uart_rx_data_r0=0;
reg [7:0] uart_rx_data_r1=0;
reg       uart_rx_dong_r=0;
always@(posedge clk_50m)
begin
    uart_rx_dong_r <= 0;
	case(state)
		1'b0 : 
			if(!uart_rxnt)
				begin
					bps_start<=1'b1;
					state<=1'b1;
				end
		1'b1 :			
			if(baud_bps)	
				begin
					bit_num<=bit_num+1'b1;
					if(bit_num<4'd9)	
						uart_rx_data_r0[bit_num-1]<=uart_rx;
				end
			else if(bit_num==4'd10)
				begin
					bit_num<=0;
					uart_rx_dong_r <= 1;
					uart_rx_data_r1<=uart_rx_data_r0;
					state<=1'b0;
					bps_start<=0;
				end
		default:;
	endcase
end
assign uart_rx_data=uart_rx_data_r1;		
assign uart_rx_done= uart_rx_dong_r;
endmodule