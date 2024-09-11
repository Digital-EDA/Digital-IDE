module CLK_Sample # (
	parameter PHASE_WIDTH = 32
) (
    input                    clk_in,
    input                    RST,
    input  [PHASE_WIDTH-1:0] sample_fre,
    output		             clk_sample
);

reg  [PHASE_WIDTH-1:0] addr_r = 0;
always @(posedge clk_in) begin
	if (RST) 
		addr_r <= 32'd0;
	else 
		addr_r <= addr_r + sample_fre;
end
assign clk_sample = addr_r[PHASE_WIDTH-1];

endmodule
