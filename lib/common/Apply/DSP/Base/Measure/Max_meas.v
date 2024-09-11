module Max_meas #
(
	parameter         data_width      = 4'd12,
	parameter         range_width     = 4'd10
)
(
	input				  clk_in,
	input 				  rst_n,
	input          [range_width-1:0]  range,
	input  signed  [data_width - 1:0] data_in,
	output signed  [data_width - 1:0] data_out
);

localparam 		  state_output    = 3'b010;
localparam 		  state_initial   = 3'b000;
localparam 		  state_detection = 3'b001;

reg signed [data_width - 1:0] data_out_buf  = 0;
reg signed [data_width - 1:0] data_out_buf1 = 0;
reg [2:0]  state = 3'b000;
reg 	   test_sig = 1'b0;
reg 	   test_sig_buf = 1'b0;
wire 	   test_done_sig = ~test_sig & test_sig_buf;
wire 	   test_start_sig = test_sig & ~test_sig_buf;

/***************************************************/
//define the time counter
reg [range_width-1:0] cnt0 = 1;

always@(posedge clk_in)
begin
	if (range == 0)
    begin
    	test_sig <= 1'b1;
    end
    else if (cnt0 == range)      
    begin
        cnt0 <= 10'd0;                    //count done,clearing the time counter
        test_sig <= 1'd0;
    end
    else
        test_sig <= 1'd1;                   //cnt0 counter = cnt0 counter + 1
        cnt0 <= cnt0 + 1'b1; 
end
/***************************************************/



always@(posedge clk_in)
begin
	if (range == 0)
	begin
		test_sig_buf <= 1'b0;
	end
	else
	begin
		test_sig_buf <= test_sig;
	end
end

always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
	begin
		data_out_buf <= 0;
		data_out_buf1 <= 0;
	end
	else
	begin
		case(state)
		state_initial:begin 
			if(test_start_sig) 
			begin 
				state <= state_detection; 
				data_out_buf <= 0;
			end 
			end
		state_detection:begin 
			if(test_done_sig)
				state <= state_output;
			else
				if(data_in > data_out_buf)
				begin
					data_out_buf <= data_in;
					if (range == 0)
					begin
						data_out_buf1 <= data_out_buf;
					end
				end
			end
		state_output:begin 
			data_out_buf1 <= data_out_buf;
			state <= state_initial; 
			end
		endcase
	end
end

assign data_out=data_out_buf1;

endmodule 