module Demodulate #(
    parameter PHASE_WIDTH  = 32,
	parameter Fiter_WIDTH  = 38,
    parameter INPUT_WIDTH  = 8,
    parameter OUTPUT_WIDTH = 12
) (
    input                     clk,
    input                     RST,

	input  [15:0]             FACTOR,
    input  [PHASE_WIDTH-1:0]  Fre_word,

    input  [INPUT_WIDTH-1:0]  wave_in,

    output [OUTPUT_WIDTH-1:0] FM_Demodule_OUT,
    output [OUTPUT_WIDTH-1:0] PM_Demodule_OUT,
    output [OUTPUT_WIDTH-1:0] AM_Demodule_OUT
);

// IQ_MIXED Outputs
wire  clk_out;
wire  [OUTPUT_WIDTH - 1 : 0]  I_OUT;
wire  [OUTPUT_WIDTH - 1 : 0]  Q_OUT;

/*
数字下变频处理模块
*/
IQ_MIXED #(
    .LO_WIDTH     ( 12 ),
    .PHASE_WIDTH  ( PHASE_WIDTH  ),
    .Fiter_WIDTH  ( Fiter_WIDTH  ),
    .INPUT_WIDTH  ( INPUT_WIDTH  ),
    .OUTPUT_WIDTH ( OUTPUT_WIDTH )) 
u_IQ_MIXED (
    .clk                  ( clk     ),
    .clk_out                 ( clk_out    ),
    .RST                     ( RST        ),
	
	.FACTOR                  ( FACTOR     ),
    .Fre_word                ( Fre_word   ),

    .wave_in                 ( wave_in    ),
    .I_OUT                   ( I_OUT      ),
    .Q_OUT                   ( Q_OUT      )
);

wire  [OUTPUT_WIDTH-1:0] Y_diff;
Cordic # (
    .XY_BITS(OUTPUT_WIDTH),               
    .PH_BITS(OUTPUT_WIDTH),      //1~32
    .ITERATIONS(16),             //1~32
    .CORDIC_STYLE("VECTOR"))     //ROTATE  //VECTOR
Demodulate_Gen_u (
    .clk(clk_out),
    .RST(RST),
    .x_i(I_OUT), 
    .y_i(Q_OUT),
    .phase_in(0),          
	.valid_in(~RST),   
     
    .x_o(AM_Demodule_OUT),
    .y_o(Y_diff),
    .phase_out(PM_Demodule_OUT)
);

reg [OUTPUT_WIDTH-1:0] PM_Demodule_OUT_r = 0;
always @(posedge clk_out) begin
    PM_Demodule_OUT_r <= PM_Demodule_OUT;
end
assign FM_Demodule_OUT = $signed(PM_Demodule_OUT) - $signed(PM_Demodule_OUT_r);

endmodule
