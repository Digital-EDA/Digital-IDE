module IQ_MIXED #(
	//LO_OUTPUR_parameter
    parameter LO_WIDTH     = 12,
	parameter PHASE_WIDTH  = 32,
	//CIC_Filter_parameter
	parameter Fiter_WIDTH  = 38,
	//IQ_MIXED_parameter
    parameter INPUT_WIDTH  = 12,
    parameter OUTPUT_WIDTH = 12
) (
    input                         clk,
    output                        clk_out,  
    input                         RST,

	input  [15:0]                 FACTOR,
    input  [PHASE_WIDTH - 1 : 0]  Fre_word,

    input  [INPUT_WIDTH - 1 : 0]  wave_in,
    output [OUTPUT_WIDTH - 1 : 0] I_OUT,
    output [OUTPUT_WIDTH - 1 : 0] Q_OUT
);

wire  [LO_WIDTH-1:0]    cos_wave;
wire  [LO_WIDTH-1:0]    sin_wave;
wire  [PHASE_WIDTH-1:0] pha_diff;
Cordic # (
    .XY_BITS(LO_WIDTH),               
    .PH_BITS(PHASE_WIDTH),      //1~32     
    .ITERATIONS(16),     //1~32
    .CORDIC_STYLE("ROTATE"),    //ROTATE  //VECTOR
    .PHASE_ACC("ON")            //ON      //OFF
) IQ_Gen_u (
    .clk(clk),
    .RST(RST),
    .x_i(0), 
    .y_i(0),
    .phase_in(Fre_word),       
	.valid_in(~RST),   
        
    .x_o(cos_wave),
    .y_o(sin_wave),
    .phase_out(pha_diff)
);

wire signed [Fiter_WIDTH - 1 : 0] I_SIG;
wire signed [Fiter_WIDTH - 1 : 0] Q_SIG;
reg  signed [INPUT_WIDTH + LO_WIDTH - 1 : 0] I_SIG_r = 0;
reg  signed [INPUT_WIDTH + LO_WIDTH - 1 : 0] Q_SIG_r = 0;
always @(posedge clk) begin
	if (RST) begin
		I_SIG_r <= 24'd0;
		Q_SIG_r <= 24'd0;
	end
	else begin
		I_SIG_r <= $signed(wave_in) * $signed(cos_wave);
		Q_SIG_r <= $signed(wave_in) * $signed(sin_wave);
	end
end
assign I_SIG = I_SIG_r[INPUT_WIDTH + LO_WIDTH - 1 : INPUT_WIDTH + LO_WIDTH - 12];
assign Q_SIG = Q_SIG_r[INPUT_WIDTH + LO_WIDTH - 1 : INPUT_WIDTH + LO_WIDTH - 12];


wire        [Fiter_WIDTH-1:0] Fiter_wave_I;
CIC_DOWN_S3#(
	.INPUT_WIDTH(12),
	.OUTPUT_WIDTH(Fiter_WIDTH)) 
Fiter_I (
    .clk(clk),
    .clk_enable(1'd1),
    .reset(RST),
	.FACTOR(FACTOR),
    .filter_in(I_SIG),
    .filter_out(Fiter_wave_I)
);
assign I_OUT = Fiter_wave_I[Fiter_WIDTH - 1 : Fiter_WIDTH - OUTPUT_WIDTH];

wire        [Fiter_WIDTH-1:0] Fiter_wave_Q;
CIC_DOWN_S3#(
	.INPUT_WIDTH(12),
	.OUTPUT_WIDTH(Fiter_WIDTH)
) Fiter_Q(
    .clk(clk),
    .clk_enable(1'd1),
    .reset(RST),
	.FACTOR(FACTOR),
    .filter_in(Q_SIG),
    .filter_out(Fiter_wave_Q),
	.ce_out(clk_out)
);
assign Q_OUT = Fiter_wave_Q[Fiter_WIDTH - 1 : Fiter_WIDTH - OUTPUT_WIDTH];

endmodule