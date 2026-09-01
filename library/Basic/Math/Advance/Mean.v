`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   Mean.v - Mean
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Calculate the average of inputs A and B.
*                 Both inputs and outputs are signed numbers.
*                 C = (A+B)/2
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '1010101010101'},
  {name: 'reset', wave: '10...........'},
  {name: 'ivalid', wave: '01...0.......'},
  {name: 'A', wave: 'x3.3.x.......', data: ['-31','11']},
  {name: 'B', wave: 'x3.3.x.......', data: ['11','21']},
  {name: 'ovalid', wave: '0....1.....0.'},
  {name: 'C', wave: 'x....5.5.x...', data: ['-10','16']}, 
]}
*/
module Mean #(
        parameter WIDTH = 16
    )(
        // Clock input
        input  clock,
        // Asynchronous reset with active high
        input  reset,
        // Output sign selection.
        // 0 : Normal output.
        // 1 : Inverted output.
        input  sign,
 
        // @Flow Input valid
        input                ivalid,
        // @Flow The signed A input port
        input  signed [WIDTH-1:0] A,
        // @Flow The signed B input port
        input  signed [WIDTH-1:0] B,

        // @Flow Output valid
        // Synchronized output with the C port
        output               ovalid,
        // @Flow The signed mean C output port
        output signed [WIDTH-1:0] C
    );

    reg signed [WIDTH:0]   sum;
    reg signed [WIDTH-1:0] res;
    reg signed [WIDTH-1:0] cc;

    reg [1:0] sign_buf;
    reg [2:0] ovalid_buf;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            sign_buf <= 0;
            ovalid_buf <= 0;
        end 
        else begin    
            sign_buf <= {sign_buf[0], sign};
            ovalid_buf <= {ovalid_buf[1:0], ivalid};
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            sum <= 0;
            res <= 0;
            cc <= 0;
        end 
        else if (ivalid) begin
            sum <= A + B;
        end
        res <= sum >>> 1;
        cc <= sign_buf[1] ? ~res+1 : res;
    end

    assign ovalid = ovalid_buf[2];
    assign C = cc;

endmodule

