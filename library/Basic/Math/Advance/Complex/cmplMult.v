`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   cmplMult.v - cmplMult
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : (ar + ai) x (br + bi) -- Both inputs and outputs are signed numbers.
*                 The complex multiplier always outputs, 
*                 but the output valid signal only synchronizes with valid outputs.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '10101010101'},
  {name: 'reset', wave: '10.........'},
  {name: 'ivalid', wave: '01.....0...'},
  {name: 'dataa_r', wave: 'x3.3.3.x...', data: ['3','7','-3']},
  {name: 'dataa_i', wave: 'x4.4.4.x...', data: ['4','8','2']},
  {name: 'datab_r', wave: 'x3.3.3.x...', data: ['1','5','4']},
  {name: 'datab_i', wave: 'x4.4.4.x...', data: ['2','6','-1']},
  {name: 'ovalid', wave: '0..1.....0.'},
  {name: 'result_r', wave: 'x..5.5.5.x.', data: ['-3','-7','-5']},
  {name: 'result_i', wave: 'x..5.5.5.x.', data: ['5','41','5']}, 
]}
*/
module cmplMult #(
        // Scaling factor: first, truncate the high bits according to the required output width, 
        // then perform a right shift based on the scaling factor.
        parameter    SCALE_FACTOR = 1,
        // Real part input width of port A.
        parameter    REAL_WIDTH_A = 12,
        // Imaginary part input width of port A.
        parameter    IMAG_WIDTH_A = 12,

        // Real part input width of port B.    
        parameter    REAL_WIDTH_B = 12,
        // Imaginary part input width of port B.
        parameter    IMAG_WIDTH_B = 12,

        // Real part output width of port O.    
        parameter    REAL_WIDTH_O = 12,
        // Imaginary part output width of port O.
        parameter    IMAG_WIDTH_O = 12
    ) (
        // Clock input
        input  clock,
        // Asynchronous reset with active high
        input  reset,

        // @Flow Input valid
        input                            ivalid,
        // @Flow A port real part signed data input.
        input signed [REAL_WIDTH_A-1:0]  dataa_r,
        // @Flow A port Imaginary part signed data input.
        input signed [IMAG_WIDTH_A-1:0]  dataa_i,
    
        // @Flow B port real part signed data input.
        input signed [REAL_WIDTH_B-1:0]  datab_r,
        // @Flow B port Imaginary part signed data input.
        input signed [IMAG_WIDTH_B-1:0]  datab_i,
        
        // @Flow Output valid
        // Synchronized output with the result_r & result_i port
        output                           ovalid,   
        // @Flow O port real part signed data output.
        output signed [REAL_WIDTH_O-1:0] result_r,
        // @Flow O port Imaginary part signed data output.
        output signed [IMAG_WIDTH_O-1:0] result_i
    );

    localparam AB_RR_WIDTH = REAL_WIDTH_A + REAL_WIDTH_B;
    localparam AB_II_WIDTH = IMAG_WIDTH_A + IMAG_WIDTH_B;
    localparam AB_RI_WIDTH = REAL_WIDTH_A + IMAG_WIDTH_B;
    localparam AB_IR_WIDTH = IMAG_WIDTH_A + REAL_WIDTH_B;

    localparam REAL_WIDTH = AB_RR_WIDTH > AB_II_WIDTH ? 
                            AB_RR_WIDTH : AB_II_WIDTH;
    localparam IMAG_WIDTH = AB_RI_WIDTH > AB_IR_WIDTH ? 
                            AB_RI_WIDTH : AB_IR_WIDTH;      

    localparam END_INDEX_R = REAL_WIDTH - REAL_WIDTH_O + 1;
    localparam END_INDEX_I = IMAG_WIDTH - IMAG_WIDTH_O + 1;

    reg signed [REAL_WIDTH:0]    outr;
    reg signed [IMAG_WIDTH:0]    outi;
    reg signed [AB_RR_WIDTH-1:0] ab_rr;
    reg signed [AB_II_WIDTH-1:0] ab_ii;
    reg signed [AB_RI_WIDTH-1:0] ab_ri;
    reg signed [AB_IR_WIDTH-1:0] ab_ir;

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            ab_rr <= 0;
            ab_ii <= 0;
            ab_ri <= 0;
            ab_ir <= 0;

            outr <= 0;
            outi <= 0;
        end
        else begin
            ab_rr <= dataa_r * datab_r;
            ab_ii <= dataa_i * datab_i;
            ab_ri <= dataa_r * datab_i;
            ab_ir <= dataa_i * datab_r;
            outr <= ab_rr - ab_ii;
            outi <= ab_ri + ab_ir;
        end
    end

    reg [1:0] ovalid_buf;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ovalid_buf <= 0;
        end 
        else begin    
            ovalid_buf <= {ovalid_buf[0], ivalid};
        end
    end
    assign ovalid = ovalid_buf[1];

    if(END_INDEX_R - SCALE_FACTOR > 0) begin
        assign result_r = (&outr[REAL_WIDTH - SCALE_FACTOR: END_INDEX_R - SCALE_FACTOR - 1])? 0 : outr[REAL_WIDTH - SCALE_FACTOR : END_INDEX_R - SCALE_FACTOR];
        assign result_i = (&outi[REAL_WIDTH - SCALE_FACTOR: END_INDEX_R - SCALE_FACTOR - 1])? 0 : outi[IMAG_WIDTH - SCALE_FACTOR : END_INDEX_I - SCALE_FACTOR];
    end else begin
        assign result_r = outr[REAL_WIDTH - SCALE_FACTOR : END_INDEX_R - SCALE_FACTOR];
        assign result_i = outi[IMAG_WIDTH - SCALE_FACTOR : END_INDEX_I - SCALE_FACTOR];

    end
endmodule
