module HDMI_out #(
    parameter    INPUT_WIDTH  = 12,
    parameter    OUTPUT_WIDTH = 12
) (
    input                           clk_in,
    input                           rst_n,
    input  [INPUT_WIDTH - 1 : 0]    data_in,
    output [OUTPUT_WIDTH - 1 : 0]   data_out
);

endmodule  //HDMI_out