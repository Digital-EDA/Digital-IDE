`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   ser2par.v - ser2par
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Single-bit serial data converted to parallel data.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: 'n..................'},
  {name: 'case1:ivalid', wave: '01.................'},
  {name: 'case2:ivalid', wave: 'n..................'},
  {name: 'idata', wave: '01010101..01..01.0.'},
  {name: 'ovalid', wave: '0.......10......10.'},
  {name: 'odata', wave: 'x.......5.......5..', data: ['11010101','10111011']}, // direct = 0
  {name: 'odata', wave: 'x.......5.......5..', data: ['10101011','11011101']}, // direct = 1
]}
*/
module ser2par #(
        // Specify the length for conversion to parallel data.
        parameter LENGTH = 8
    ) (
        // Clock input
        input clock,
        // Asynchronous reset with active high
        input reset,

        // Specify the direction of conversion.
        // 0 : The first input is the least significant bit (LSB) of the parallel data.
        // 1 : The first input is the most significant bit (MSB) of the parallel data.
        input direct,

        // @Flow Input valid
        input ivalid,
        // @Flow Single-bit serial data input
        input idata,

        // @Flow Output valid
        output reg              ovalid,
        // @Flow Parallel data output
        output reg [LENGTH-1:0] odata
    );

    reg [LENGTH-1:0]            data_buf;
    reg [$clog2(LENGTH)-1:0]    cnt;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            cnt <= 0;
            data_buf <= 0;
            odata <= 0;
            ovalid <= 0;
        end 
        else if (ivalid) begin
            data_buf[LENGTH-1] <= idata;
            data_buf[LENGTH-2:0] <= data_buf[LENGTH-1:1];
            cnt <= cnt + 1;
            if (cnt == LENGTH-1) begin
                if (direct == 0) begin
                    odata <= {idata, data_buf[LENGTH-1:1]};
                end
                else begin
                    odata <= {data_buf[LENGTH-1:1], idata};
                end
                ovalid <= 1;
            end 
            else begin
                ovalid <= 0;
            end
        end 
        else begin
            ovalid <= 0;
        end
    end
endmodule
