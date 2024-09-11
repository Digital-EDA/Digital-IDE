`timescale 1 ns / 1 ns
module CIC_DOWN_S4 #(
    parameter FACTOR       = 10,
    parameter INPUT_WIDTH  = 12,
    parameter OUTPUT_WIDTH = 15
) (
    input   						  clk,
    input   						  clk_enable,
    input   						  reset,
    input   signed [INPUT_WIDTH-1:0]  filter_in,
    output  signed [OUTPUT_WIDTH-1:0] filter_out,
    output  						  ce_out
);

localparam FILTER_WIDTH = OUTPUT_WIDTH;

////////////////////////////////////////////////////////////////
//Module Architecture: CIC_DOWN_S4
////////////////////////////////////////////////////////////////
// Local Functions
// Type Definitions
// Constants
// Signals
reg  [15:0] cur_count = 0; // ufix2
wire phase_1; // boolean
reg  ce_out_reg = 0; // boolean
//
reg  signed [INPUT_WIDTH-1:0] input_register = 0; // sfix16_En15
//   -- Section 1 Signals
wire signed [INPUT_WIDTH-1:0] section_in1; // sfix16_En15
wire signed [FILTER_WIDTH-1:0] section_cast1; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] sum1; // sfix20_En15
reg  signed [FILTER_WIDTH-1:0] section_out1 = 0; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] add_cast; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] add_cast_1; // sfix20_En15
wire signed [FILTER_WIDTH:0] add_temp; // sfix21_En15
//   -- Section 2 Signals
wire signed [FILTER_WIDTH-1:0] section_in2; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] sum2; // sfix20_En15
reg  signed [FILTER_WIDTH-1:0] section_out2 = 0; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] add_cast_2; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] add_cast_3; // sfix20_En15
wire signed [FILTER_WIDTH:0] add_temp_1; // sfix21_En15
//   -- Section 3 Signals
wire signed [FILTER_WIDTH-1:0] section_in3; // sfix20_En15
reg  signed [FILTER_WIDTH-1:0] diff1 = 0; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] section_out3; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] sub_cast; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] sub_cast_1; // sfix20_En15
wire signed [FILTER_WIDTH:0] sub_temp; // sfix21_En15
//   -- Section 4 Signals
wire signed [FILTER_WIDTH-1:0] section_in4; // sfix20_En15
reg  signed [FILTER_WIDTH-1:0] diff2 = 0; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] section_out4; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] sub_cast_2; // sfix20_En15
wire signed [FILTER_WIDTH-1:0] sub_cast_3; // sfix20_En15
wire signed [FILTER_WIDTH:0] sub_temp_1; // sfix21_En15
//
reg  signed [FILTER_WIDTH-1:0] output_register = 0; // sfix20_En15

// Block Statements
//   ------------------ CE Output Generation ------------------

always @ (posedge clk or posedge reset) begin: ce_output
    if (reset == 1'b1) begin
        cur_count <= 16'd0;
    end
    else begin
        if (clk_enable == 1'b1) begin
            if (cur_count == FACTOR-1) begin
                cur_count <= 16'd0;
            end
            else begin
                cur_count <= cur_count + 1;
            end
        end
    end
end // ce_output

assign  phase_1 = (cur_count == 16'd1 && clk_enable == 1'b1)? 1 : 0;

//   ------------------ CE Output Register ------------------

always @ (posedge clk or posedge reset) begin: ce_output_register
    if (reset == 1'b1) begin
        ce_out_reg <= 1'b0;
    end
    else begin
        ce_out_reg <= phase_1;
    end
end // ce_output_register

//   ------------------ Input Register ------------------

always @ (posedge clk or posedge reset) begin: input_reg_process
    if (reset == 1'b1) begin
        input_register <= 0;
    end
    else begin
        if (clk_enable == 1'b1) begin
            input_register <= filter_in;
        end
    end
end // input_reg_process

//   ------------------ Section # 1 : Integrator ------------------

assign section_in1 = input_register;

assign section_cast1 = $signed({{(FILTER_WIDTH-INPUT_WIDTH){section_in1[INPUT_WIDTH-1]}}, section_in1});

assign add_cast = section_cast1;
assign add_cast_1 = section_out1;
assign add_temp = add_cast + add_cast_1;
assign sum1 = add_temp[FILTER_WIDTH-1:0];

always @ (posedge clk or posedge reset) begin: integrator_delay_section1
    if (reset == 1'b1) begin
        section_out1 <= 0;
    end
    else begin
        if (clk_enable == 1'b1) begin
            section_out1 <= sum1;
        end
    end
end // integrator_delay_section1

//   ------------------ Section # 2 : Integrator ------------------

assign section_in2 = section_out1;

assign add_cast_2 = section_in2;
assign add_cast_3 = section_out2;
assign add_temp_1 = add_cast_2 + add_cast_3;
assign sum2 = add_temp_1[FILTER_WIDTH-1:0];

always @ (posedge clk or posedge reset) begin: integrator_delay_section2
    if (reset == 1'b1) begin
        section_out2 <= 0;
    end
    else begin
        if (clk_enable == 1'b1) begin
            section_out2 <= sum2;
        end
    end
end // integrator_delay_section2

//   ------------------ Section # 3 : Comb ------------------

assign section_in3 = section_out2;

assign sub_cast = section_in3;
assign sub_cast_1 = diff1;
assign sub_temp = sub_cast - sub_cast_1;
assign section_out3 = sub_temp[FILTER_WIDTH-1:0];

always @ (posedge clk or posedge reset) begin: comb_delay_section3
    if (reset == 1'b1) begin
        diff1 <= 0;
    end
    else begin
        if (phase_1 == 1'b1) begin
            diff1 <= section_in3;
        end
    end
end // comb_delay_section3

//   ------------------ Section # 4 : Comb ------------------

assign section_in4 = section_out3;

assign sub_cast_2 = section_in4;
assign sub_cast_3 = diff2;
assign sub_temp_1 = sub_cast_2 - sub_cast_3;
assign section_out4 = sub_temp_1[FILTER_WIDTH-1:0];

always @ (posedge clk or posedge reset) begin: comb_delay_section4
    if (reset == 1'b1) begin
        diff2 <= 0;
    end
    else begin
        if (phase_1 == 1'b1) begin
            diff2 <= section_in4;
        end
    end
end // comb_delay_section4

//   ------------------ Output Register ------------------

always @ (posedge clk or posedge reset) begin: output_reg_process
    if (reset == 1'b1) begin
        output_register <= 0;
    end
    else begin
        if (phase_1 == 1'b1) begin
            output_register <= section_out4;
        end
    end
end // output_reg_process

// Assignment Statements
assign ce_out = ce_out_reg;
assign filter_out = output_register;
endmodule  // CIC_DOWN_S4
