`timescale 1ns/100ps
module testbench();

parameter TOTAL_STAGE = 8;

reg                    clk_100m  = 0;
reg                    sys_rst_n = 0;
reg [TOTAL_STAGE-1:0]  addr = 0;

wire         valid_out;
always begin
    #10 clk_100m = ~clk_100m;
end
always begin
    #50 sys_rst_n = 1;
end
always begin
    if (valid_out) begin
        #10 addr = addr + 1;#10;
    end
    else begin     
        #10 addr = 0;#10;
    end
end

parameter  REAL_WIDTH  = 18;
parameter  IMGN_WIDTH  = 18;

wire  [REAL_WIDTH-1:0] cos_wave;
wire  [IMGN_WIDTH-1:0] sin_wave;
wire  [15:0] pha_diff;
Cordic #
(
   .XY_BITS(REAL_WIDTH),
   .PH_BITS(16),                 //1~32
   .ITERATIONS(16),              //1~32
   .CORDIC_STYLE("ROTATE"),    //ROTATE  //VECTOR
   .PHASE_ACC("ON")            //ON      //OFF
)
IQ_Gen_u
(
   .clk_in(clk_100m),
   .RST(1'd0),
   .x_i(0),
   .y_i(0),
   .phase_in(16'd2356),//Fre_word = （(2^PH_BITS)/fc）* f   fc：时钟频率   f输出频率

   .x_o(cos_wave),
   .y_o(sin_wave),
   .phase_out(pha_diff),

   .valid_in(1),
   .valid_out(valid_out)
);

wire                   oen;
wire [REAL_WIDTH-1:0]  oReal;
wire [IMGN_WIDTH-1:0]  oImag;
wire [TOTAL_STAGE-1:0] oaddr;
fft #(
    .REAL_WIDTH(REAL_WIDTH),
    .IMGN_WIDTH(REAL_WIDTH),
    .TOTAL_STAGE(TOTAL_STAGE)
)
fft_ins 
(
	.iclk(clk_100m),
	.rst_n(sys_rst_n),

	.iaddr(addr),
	.iReal(cos_wave),
	.iImag(0),
	.ien(valid_out),

	.oReal(oReal),
	.oImag(oImag),
	.oaddr(oaddr),
	.oen(oen)
);

endmodule
