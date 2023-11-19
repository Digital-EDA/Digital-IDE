module DAC_PWM #
(
	parameter MAIN_FRE = 500,
	parameter PWM_FRE  = 1000,
	parameter PHASE_WIDTH = 32
)
(
    input                    clk_in,
    input                    RST,
    output                   DAC_PWM,
    input  [PHASE_WIDTH-1:0] data_in
);

localparam [PHASE_WIDTH-1:0] DC_ADD   = (2**(PHASE_WIDTH-1)) - 1;
localparam [PHASE_WIDTH-1:0] FRE_WORD = (2**PHASE_WIDTH)*PWM_FRE/(MAIN_FRE*1000);

reg [PHASE_WIDTH-1:0] addr_r = 0;
always @(posedge clk_in) begin
	if (RST) 
		addr_r <= 0;
	else 
		addr_r <= addr_r + FRE_WORD;
end

reg [PHASE_WIDTH-1:0] duty_r = 0;
always @(posedge clk_in) begin
	if (RST) 
		duty_r <= 32'd0;
	else 
		duty_r <= $signed(data_in) + DC_ADD;
end

assign DAC_PWM = (addr_r <= duty_r) ? 1'b1 : 1'b0;

endmodule