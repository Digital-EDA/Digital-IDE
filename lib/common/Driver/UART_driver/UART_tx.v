module uart_tx(
	input clk_50m,
	input [7:0] uart_tx_data,	      
	input uart_tx_en,			        
	output uart_tx,
	output uart_tx_done
);

parameter BAUD_DIV     = 13'd87;  
parameter BAUD_DIV_CAP = 13'd43;     
reg [12:0] baud_div=0;			         
reg baud_bps=0;				            
reg [9:0] send_data=10'b1111111111;    
reg [3:0] bit_num=0;	                
reg uart_send_flag=0;	                
reg uart_tx_r=1;		              
always@(posedge clk_50m)
begin
	if(baud_div==BAUD_DIV_CAP)	        
		begin
			baud_bps<=1'b1;
			baud_div<=baud_div+1'b1;
		end
	else if(baud_div<BAUD_DIV && uart_send_flag)
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

always@(posedge clk_50m)
begin
    if(uart_tx_en)	
		begin
			uart_send_flag<=1'b1;
			send_data<={1'b1,uart_tx_data,1'b0};
		end
	else if(bit_num==4'd10)	
		begin
			uart_send_flag<=1'b0;
			send_data<=10'b1111_1111_11;
		end
end

always@(posedge clk_50m)
begin
	if(uart_send_flag)	
		begin
			if(baud_bps)
				begin
					if(bit_num<=4'd9)
						begin
							uart_tx_r<=send_data[bit_num];	
							bit_num<=bit_num+1'b1;
						end
				end
			else if(bit_num==4'd10)
				bit_num<=4'd0;
		end
	else
		begin
			uart_tx_r<=1'b1;	
			bit_num<=0;
		end
end

assign uart_tx=uart_tx_r;
assign uart_tx_done = (bit_num == 10) ? 1:0;
endmodule