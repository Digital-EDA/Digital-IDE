module AD9226_driver #
(
	parameter signed CH_offset = 27
)
(
	input 			clk_in,
	input 			rst_n,
	input   [11:0] 	AD_data,
	output 			AD_clk,
	output  [11:0] 	wave_CH
);

reg signed [11:0] wave_CH_buf;
always@(posedge clk_in or negedge rst_n) begin
	if(!rst_n)
		wave_CH_buf <= 12'd0;
	else begin
		wave_CH_buf[11] <= AD_data[0];
		wave_CH_buf[10] <= AD_data[1];
		wave_CH_buf[9]  <= AD_data[2];
		wave_CH_buf[8]  <= AD_data[3];
		wave_CH_buf[7]  <= AD_data[4];
		wave_CH_buf[6]  <= AD_data[5];
		wave_CH_buf[5]  <= AD_data[6];
		wave_CH_buf[4]  <= AD_data[7];
		wave_CH_buf[3]  <= AD_data[8];
		wave_CH_buf[2]  <= AD_data[9];
		wave_CH_buf[1]  <= AD_data[10];
		wave_CH_buf[0]  <= AD_data[11];
	end
end

assign wave_CH = $signed(wave_CH_buf) + $signed(CH_offset);
assign AD_clk  = clk_in;

endmodule

