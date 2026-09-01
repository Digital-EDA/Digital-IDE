`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   cmplAdsu.v - cmplAdsu
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Both inputs and outputs are signed numbers.
*                 (ar + ai) + (br + bi)
*                 (ar + ai) - (br + bi)
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '101010101'},
  {name: 'reset', wave: '10.......'},
  {name: 'ivalid', wave: '01.....0.'},
  {name: 'dataa_r', wave: 'x3.3.3.x.', data: ['3','7','-3']},
  {name: 'dataa_i', wave: 'x4.4.4.x.', data: ['4','8','2']},
  {name: 'datab_r', wave: 'x3.3.3.x.', data: ['1','5','4']},
  {name: 'datab_i', wave: 'x4.4.4.x.', data: ['2','6','-1']},
  {name: 'ovalid', wave: '01.....0.'},
  {name: 'result_r', wave: 'x5.5.5.x.', data: ['4','12','1']},
  {name: 'result_i', wave: 'x5.5.5.x.', data: ['6','14','1']}, 
]}
*/
module cmplAdsu #(
        // Scaling factor: first, truncate the high bits according to the required output width, 
        // then perform a right shift based on the scaling factor.
        parameter    SCALE_FACTOR = 1,

        // The real bit width of the A input port
        parameter    REAL_WIDTH_A = 12,
        // The Imaginary bit width of the A input port
        parameter    IMAG_WIDTH_A = 12,

        // The real bit width of the B input port
        parameter    REAL_WIDTH_B = 12,
        // The Imaginary bit width of the B input port
        parameter    IMAG_WIDTH_B = 12,

        // The real bit width of the O output port
        parameter    REAL_WIDTH_O = 12,
        // The Imaginary bit width of the O output port
        parameter    IMAG_WIDTH_O = 12
    ) (
        // Clock input
        input  clock,
        // Asynchronous reset with active high
        input  reset,

        // Sign signal for addition and subtraction
        // 0 : (ar + ai) + (br + bi)
        // 1 : (ar + ai) - (br + bi)
        input  add_sub,

        // @Flow Input valid
        // Synchronized input with the dataa_r & dataa_i & datab_r & datab_i port
        input                            ivalid,
        // @Flow The real of the signed A input port
        input signed [REAL_WIDTH_A-1:0]  dataa_r,
        // @Flow The Imaginary of the signed A input port
        input signed [IMAG_WIDTH_A-1:0]  dataa_i,

        // @Flow The real of the signed B input port
        input signed [REAL_WIDTH_B-1:0]  datab_r,
        // @Flow The Imaginary of the signed B input port
        input signed [IMAG_WIDTH_B-1:0]  datab_i,
        
        // @Flow Output valid
        // Synchronized output with the result_r & result_i port
        output                           ovalid,   
        // @Flow The real of the signed O output port
        output signed [REAL_WIDTH_O-1:0] result_r,
        // @Flow The Imaginary of the signed O output port
        output signed [IMAG_WIDTH_O-1:0] result_i
    );

    localparam AB_RR_WIDTH = REAL_WIDTH_A > REAL_WIDTH_B ? 
                             REAL_WIDTH_A : REAL_WIDTH_B;
    localparam AB_II_WIDTH = IMAG_WIDTH_A > IMAG_WIDTH_B ? 
                             IMAG_WIDTH_A : IMAG_WIDTH_B;      

    localparam END_INDEX_R = AB_RR_WIDTH - REAL_WIDTH_O + 1;
    localparam END_INDEX_I = AB_II_WIDTH - IMAG_WIDTH_O + 1;


    reg signed [AB_RR_WIDTH:0] ab_rr;
    reg signed [AB_II_WIDTH:0] ab_ii;

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            ab_rr <= 0;
            ab_ii <= 0;
        end
        else begin
            if (add_sub) begin                
                ab_rr <= dataa_r - datab_r;
                ab_ii <= dataa_i - datab_i;
            end
            else begin
                ab_rr <= dataa_r + datab_r;
                ab_ii <= dataa_i + datab_i;
            end
        end
    end

    reg ovalid_buf;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ovalid_buf <= 0;
        end 
        else begin    
            ovalid_buf <= ivalid;
        end
    end
    assign ovalid = ovalid_buf;

    assign result_r = ab_rr[AB_RR_WIDTH - SCALE_FACTOR : END_INDEX_R - SCALE_FACTOR];
    assign result_i = ab_ii[AB_II_WIDTH - SCALE_FACTOR : END_INDEX_I - SCALE_FACTOR];

endmodule
