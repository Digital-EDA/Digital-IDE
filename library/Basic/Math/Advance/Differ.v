`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   Differ.v - Differ
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Simple fixed-point differentiation calculation, 
*                 computing the difference between two valid time points. 
*                 Both input and output values are signed numbers.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '1010101010101'},
  {name: 'reset', wave: '10...........'},
  {name: 'ivalid', wave: '01.......0...'},
  {name: 'idata', wave: 'x3.3.3.3.x...', data: ['5','10','7','0']},
  {name: 'ovalid', wave: '0..1.......0.'},
  {name: 'odata', wave: 'x..5.5.5.5.x.', data: ['x','5','-3','-7']}, 
]}
*/
module Differ #(
        // The width parameter for input data.
        parameter WIDTH = 12,
        // Output mode setting: 
        // 0 : it truncates the higher WIDTH bits for output
        // 1 : it truncates the lower WIDTH bits for output.
        parameter OMODE = 1
    ) (
        // Clock input
        input  clock,
        // Asynchronous reset with active high
        input  reset,
        
        // @Flow Input valid
        input                     ivalid,
        // @Flow The real of the signed input port
        input  signed [WIDTH-1:0] idata,
        
        // @Flow Output valid
        // Synchronized output with the odata port
        output                    ovalid,
        // @Flow modulus data signed output
        output signed [WIDTH-1:0] odata
    );

    reg                    ovalid_reg;
    reg signed [WIDTH-1:0] odata_reg;
    reg signed [WIDTH:0]   odata_buf;
    always @(posedge clock) begin
        if(reset) begin
            odata_reg <= 0;
            odata_buf <= 0;
            ovalid_reg <= 0;
        end
        else begin
            if (ivalid) begin
                odata_reg <= idata;
                odata_buf <= idata - odata_reg;
            end
            ovalid_reg <= ivalid;
        end
    end

    assign odata = OMODE ? odata_buf[WIDTH-1:0] : odata_buf[WIDTH:1];
    assign ovalid = ovalid_reg;
    
endmodule  //Differ
