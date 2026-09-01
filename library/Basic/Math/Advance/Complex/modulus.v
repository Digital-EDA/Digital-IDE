`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   modulus.v - modulus
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Approximate modulus operation.
*                 http://dspguru.com/dsp/tricks/magnitude-estimator
*                 alpha = 1, beta = 1/4 Fixed-point round half up.
*                 avg err 0.006
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '1010101010101'},
  {name: 'reset', wave: '10...........'},
  {name: 'ivalid', wave: '01.....0.....'},
  {name: 'idata_r', wave: 'x3.3.3.x.....', data: ['4','-8','2']},
  {name: 'idata_i', wave: 'x4.4.4.x.....', data: ['3','7','-3']},
  {name: 'ovalid', wave: '0....1.....0.'},
  {name: 'modulus', wave: 'x....5.5.5.x.', data: ['5','10','4']}, 
]}
*/
module modulus #(
        // Data width.
        parameter WIDTH = 16
    ) (
        // Clock input
        input clock,
        // Asynchronous reset with active high
        input reset,

        // @Flow Input valid
        input ivalid,
        // @Flow The real of the signed input port
        input signed [WIDTH-1:0] idata_r,
        // @Flow The Imaginary of the signed input port
        input signed [WIDTH-1:0] idata_i,

        // @Flow Output valid
        // Synchronized output with the modulus port
        output                   ovalid,
        // @Flow modulus data unsigned output
        output reg [WIDTH-1:0]   modulus
    );

    reg  [WIDTH-1:0] abs_r;
    reg  [WIDTH-1:0] abs_i;

    reg  [WIDTH-1:0] max;
    reg  [WIDTH-1:0] min;
    wire [WIDTH-1:0] rmin = min[1] ? (min[WIDTH-1:2] + 1) : (min>>2);

    reg  [2:0] ovalid_buf;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ovalid_buf <= 0;
        end 
        else begin    
            ovalid_buf <= {ovalid_buf[1:0], ivalid};
        end
    end
    assign ovalid = ovalid_buf[2];

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            modulus <= 0;
            abs_r <= 0;
            abs_i <= 0;
            max <= 0;
            min <= 0;
        end 
        else if (ivalid) begin
            abs_r <= idata_r[WIDTH-1] ? (~idata_r+1) : idata_r;
            abs_i <= idata_i[WIDTH-1] ? (~idata_i+1) : idata_i;

        end
        max <= (abs_i > abs_r) ? abs_i : abs_r;
        min <= (abs_i > abs_r) ? abs_r : abs_i;

        modulus <= max + rmin;
    end

endmodule
