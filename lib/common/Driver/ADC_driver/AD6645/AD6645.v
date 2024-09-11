module AD6645
(
	input 		clk_in,
	input 		rst_n,
	input  [13:0] 	AD_data,
	output [13:0] 	wave_CH
);
reg [13:0] 	wave_CH_buf;
always@(posedge clk_in or negedge rst_n)
begin
	if(!rst_n)
		wave_CH_buf <= 14'd0;
	else
		wave_CH_buf <= AD_data;
end
assign wave_CH = wave_CH_buf - 14'd1700;
endmodule 