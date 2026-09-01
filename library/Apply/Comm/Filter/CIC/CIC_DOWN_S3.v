`timescale 1 ns / 1 ns
module CIC_DOWN_S3 #(
        parameter FWIDTH = 12,
        parameter IWIDTH = 12,
        parameter OWIDTH = 15
    ) (
        input   					 clock,
        input   					 reset,

        input		   [FWIDTH-1:0]  factor,

        input   					 ivalid,
        input   signed [IWIDTH-1:0]  filter_in,

        output  				     ovalid,
        output  signed [OWIDTH-1:0]  filter_out
    );

    localparam FILTER_WIDTH = OWIDTH;

    ////////////////////////////////////////////////////////////////
    //Module Architecture: CIC_DOWN_S3
    ////////////////////////////////////////////////////////////////
    // Local Functions
    // Type Definitions
    // Constants
    // Signals
    reg  [FWIDTH-1:0] cur_count; // ufix2
    wire phase_1; // boolean
    reg  ce_out_reg; // boolean
    //
    reg  signed [IWIDTH-1:0] input_register; // sfix12_En11
    //   -- Section 1 Signals
    wire signed [IWIDTH-1:0] section_in1; // sfix12_En11
    wire signed [FILTER_WIDTH-1:0] section_cast1; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sum1; // sfix15_En11
    reg  signed [FILTER_WIDTH-1:0] section_out1; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] add_cast; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] add_cast_1; // sfix15_En11
    wire signed [FILTER_WIDTH:0] add_temp; // sfix16_En11
    //   -- Section 2 Signals
    wire signed [FILTER_WIDTH-1:0] section_in2; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sum2; // sfix15_En11
    reg  signed [FILTER_WIDTH-1:0] section_out2; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] add_cast_2; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] add_cast_3; // sfix15_En11
    wire signed [FILTER_WIDTH:0] add_temp_1; // sfix16_En11
    //   -- Section 3 Signals
    wire signed [FILTER_WIDTH-1:0] section_in3; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sum3; // sfix15_En11
    reg  signed [FILTER_WIDTH-1:0] section_out3; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] add_cast_4; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] add_cast_5; // sfix15_En11
    wire signed [FILTER_WIDTH:0] add_temp_2; // sfix16_En11
    //   -- Section 4 Signals
    wire signed [FILTER_WIDTH-1:0] section_in4; // sfix15_En11
    reg  signed [FILTER_WIDTH-1:0] diff1; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] section_out4; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sub_cast; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sub_cast_1; // sfix15_En11
    wire signed [FILTER_WIDTH:0] sub_temp; // sfix16_En11
    //   -- Section 5 Signals
    wire signed [FILTER_WIDTH-1:0] section_in5; // sfix15_En11
    reg  signed [FILTER_WIDTH-1:0] diff2; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] section_out5; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sub_cast_2; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sub_cast_3; // sfix15_En11
    wire signed [FILTER_WIDTH:0] sub_temp_1; // sfix16_En11
    //   -- Section 6 Signals
    wire signed [FILTER_WIDTH-1:0] section_in6; // sfix15_En11
    reg  signed [FILTER_WIDTH-1:0] diff3; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] section_out6; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sub_cast_4; // sfix15_En11
    wire signed [FILTER_WIDTH-1:0] sub_cast_5; // sfix15_En11
    wire signed [FILTER_WIDTH:0] sub_temp_2; // sfix16_En11
    //
    reg  signed [FILTER_WIDTH-1:0] output_register; // sfix15_En11

    // Block Statements
    //   ------------------ CE Output Generation ------------------

    always @ (posedge clock or posedge reset) begin: ce_output
        if (reset) begin
            cur_count <= 0;
        end
        else begin
            if (ivalid) begin
                if (cur_count == factor-1) begin
                    cur_count <= 0;
                end
                else begin
                    cur_count <= cur_count + 1;
                end
            end
        end
    end // ce_output

    assign  phase_1 = (cur_count == 1 && ivalid)? 1 : 0;

    //   ------------------ CE Output Register ------------------

    always @ (posedge clock or posedge reset) begin: ce_output_register
        if (reset) begin
            ce_out_reg <= 1'b0;
        end
        else begin
            ce_out_reg <= phase_1;
        end
    end // ce_output_register

    //   ------------------ Input Register ------------------

    always @ (posedge clock or posedge reset) begin: input_reg_process
        if (reset) begin
            input_register <= 0;
        end
        else begin
            if (ivalid) begin
                input_register <= filter_in;
            end
        end
    end

    //   ------------------ Section # 1 : Integrator ------------------

    assign section_in1 = input_register;

    assign section_cast1 = $signed({{(FILTER_WIDTH-IWIDTH){section_in1[IWIDTH-1]}}, section_in1});

    assign add_cast = section_cast1;
    assign add_cast_1 = section_out1;
    assign add_temp = add_cast + add_cast_1;
    assign sum1 = add_temp[FILTER_WIDTH-1:0];

    always @ (posedge clock or posedge reset) begin: integrator_delay_section1
        if (reset) begin
            section_out1 <= 0;
        end
        else begin
            if (ivalid) begin
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

    always @ (posedge clock or posedge reset) begin: integrator_delay_section2
        if (reset) begin
            section_out2 <= 0;
        end
        else begin
            if (ivalid) begin
                section_out2 <= sum2;
            end
        end
    end // integrator_delay_section2

    //   ------------------ Section # 3 : Integrator ------------------

    assign section_in3 = section_out2;

    assign add_cast_4 = section_in3;
    assign add_cast_5 = section_out3;
    assign add_temp_2 = add_cast_4 + add_cast_5;
    assign sum3 = add_temp_2[FILTER_WIDTH-1:0];

    always @ (posedge clock or posedge reset) begin: integrator_delay_section3
        if (reset) begin
            section_out3 <= 0;
        end
        else begin
            if (ivalid) begin
                section_out3 <= sum3;
            end
        end
    end // integrator_delay_section3

    //   ------------------ Section # 4 : Comb ------------------

    assign section_in4 = section_out3;

    assign sub_cast = section_in4;
    assign sub_cast_1 = diff1;
    assign sub_temp = sub_cast - sub_cast_1;
    assign section_out4 = sub_temp[FILTER_WIDTH:0];

    always @ (posedge clock or posedge reset) begin: comb_delay_section4
        if (reset) begin
            diff1 <= 0;
        end
        else begin
            if (phase_1 == 1'b1) begin
                diff1 <= section_in4;
            end
        end
    end // comb_delay_section4

    //   ------------------ Section # 5 : Comb ------------------

    assign section_in5 = section_out4;

    assign sub_cast_2 = section_in5;
    assign sub_cast_3 = diff2;
    assign sub_temp_1 = sub_cast_2 - sub_cast_3;
    assign section_out5 = sub_temp_1[FILTER_WIDTH-1:0];

    always @ (posedge clock or posedge reset) begin: comb_delay_section5
        if (reset) begin
            diff2 <= 0;
        end
        else begin
            if (phase_1 == 1'b1) begin
                diff2 <= section_in5;
            end
        end
    end // comb_delay_section5

    //   ------------------ Section # 6 : Comb ------------------

    assign section_in6 = section_out5;

    assign sub_cast_4 = section_in6;
    assign sub_cast_5 = diff3;
    assign sub_temp_2 = sub_cast_4 - sub_cast_5;
    assign section_out6 = sub_temp_2[FILTER_WIDTH-1:0];

    always @ (posedge clock or posedge reset) begin: comb_delay_section6
        if (reset) begin
            diff3 <= 0;
        end
        else begin
            if (phase_1 == 1'b1) begin
                diff3 <= section_in6;
            end
        end
    end // comb_delay_section6

    //   ------------------ Output Register ------------------

    always @ (posedge clock or posedge reset) begin: output_reg_process
        if (reset) begin
            output_register <= 0;
        end
        else begin
            if (phase_1 == 1'b1) begin
                output_register <= section_out6;
            end
        end
    end // output_reg_process

    // Assignment Statements
    assign ovalid = ce_out_reg;
    assign filter_out = output_register;
    
endmodule  // CIC_DOWN_S3
