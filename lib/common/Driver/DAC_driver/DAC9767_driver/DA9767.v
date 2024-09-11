//============================================================================================
/*
 * #Author       : sterben(Duan)
 * #LastAuthor   : sterben(Duan)
 * #Date         : 2019-09-27 00:00:34
 * #lastTime     : 2020-01-22 23:54:59
 * #FilePath     : src\Driver\DAC_driver\DAC9767_driver\DA9767.v
 * #Description  : port:
 */
//============================================================================================

module DA9767 #
(
	parameter INPUT_WIDTH = 14,
	parameter INPUT_STYLE = "signed",
	parameter ALIGNED_STYLE = "LSB"
)
(
	input 			               clk_in,
    input   [INPUT_WIDTH - 1 : 0]  DA_data,
	output						   DA_clk,
	output			               DA_wrt,
	output  [13:0] 	               DA_out
);

generate if(INPUT_STYLE == "signed") begin : OUTPUT
	if (INPUT_WIDTH < 14) begin
		localparam DATA_WIDTH = 14 - INPUT_WIDTH;
		if (ALIGNED_STYLE == "LSB") begin
			assign 	DA_out = $signed({{DATA_WIDTH{DA_data[INPUT_WIDTH-1]}},DA_data}) 
											+ $signed(14'd8192);
		end
		else if(ALIGNED_STYLE == "MSB") begin
			reg [DATA_WIDTH - 1 : 0 ] data_buf = 0;
			assign 	DA_out = $signed({DA_data,data_buf}) + $signed(14'd8192);
		end
	end
	else begin
		assign 	DA_out = $signed(DA_data[INPUT_WIDTH - 1 : INPUT_WIDTH - 14]) + $signed(14'd8192);
	end
end
else if(INPUT_STYLE == "unsigned") begin
	if (INPUT_WIDTH < 14) begin
		localparam DATA_WIDTH = 14 - INPUT_WIDTH;
		if (ALIGNED_STYLE == "LSB") begin
			assign 	DA_out = {{DATA_WIDTH{DA_data[INPUT_WIDTH-1]}},DA_data};
		end
		else if(ALIGNED_STYLE == "MSB") begin
			reg [DATA_WIDTH - 1 : 0 ] data_buf = 0;
			assign 	DA_out = {DA_data,data_buf};
		end
	end
	else begin
		assign 	DA_out = DA_data[INPUT_WIDTH - 1 : INPUT_WIDTH - 14];
	end
end
endgenerate	

assign 				DA_clk = clk_in;
assign 				DA_wrt = clk_in;

endmodule
