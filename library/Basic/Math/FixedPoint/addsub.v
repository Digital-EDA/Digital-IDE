`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   addsub.v - addsub
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : 4-stage pipelined addsub.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '10101010101010101'},
  {name: 'reset', wave: '10...............'},
  {name: 'clr', wave: '01.0.............'},
  {name: 'idata', wave: 'x3...............', data: ['5']},
  {name: 'odata', wave: 'x........5.5.5.5.', data: ['5','10','25','30']}, 
]}
*/
module addsub #(
        // Data width.
        parameter WIDTH = 16
    ) (
        // Clock input
        input  clock,
        // Asynchronous reset with active high
        input  reset,

        // Addition/subtraction type selection signal.
        // 0 : add
        // 1 : sub
        input  add_sub,

        // Initial input of the addsub.
        input  [WIDTH-1:0] A,
        input  [WIDTH-1:0] B,

        // output of the addsub.
        output [WIDTH-1:0] S
    );

    
endmodule