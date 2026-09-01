`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   shiftSets.v - shiftSets
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : 
*                 1. In Vivado, EDA can directly use BRAM for synthesis.
*   Dependencies: none(FPGA) auto for BRAM in vivado | RAM_IP with IC 
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '101010101010101010101'},
  {name: 'case1:ivalid', wave: '01...................'},
  {name: 'case2:ivalid', wave: '101010101010101010101'},
  {name: 'idata', wave: 'x4.4.4.4.4.x.........', data: ['data0','data1','data2','data3','data4']},
  {name: 'ivalid', wave: '0........1...........'},
  {name: 'odata', wave: 'x........5.5.5.5.5.x.', data: ['data0','data1','data2','data3','data4']},
]}
*/
module shiftSets #(
        // Data width.
        parameter WIDTH = 16,
        // Delay or shift length width.
        parameter DEEPW = 8
    ) (
        // Clock input
        input                   clock,
        // Asynchronous reset with active high
        input                   reset,

        // @Flow input valid
        input                   ivalid, 
        // @Flow input shift data
        input  [WIDTH - 1 : 0]  shiftin,
        input  [DEEPW - 1 : 0]  delay,
 
        // @Flow output data 
        output [WIDTH - 1 : 0]  shiftout
    );

    reg [DEEPW:0]  count;

    SDPRAM #(
        .WIDTH 		( WIDTH 		),
        .DEPTH 		( 1<<DEEPW  	))
    u_SDPRAM(
        //ports
        .clock  	( clock  		),
        .reset   	( reset   		),

        .wen   		( ivalid   		),
        .ren        ( 1'b1          ),

        .waddr 		( count 		),
        .raddr 		( count 		),

        .din  		( shiftin  		),
        .dout 		( shiftout 		)
    );

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            count <= 0;
        end 
        else begin            
            if (ivalid) begin
                count <= count + 1;
                if (count == (delay-2)) begin
                    count <= 0;
                end
            end
        end
    end
    
endmodule

