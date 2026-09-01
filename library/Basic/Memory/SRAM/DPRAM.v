`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   DPRAM.v - DPRAM
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : The synchronous dual-port SRAM has A, B ports to access the same memory location. 
*                 Both ports can be independently read or written from the memory array.
*                 1. In Vivado, EDA can directly use BRAM for synthesis.
*                 2. The module continuously outputs data when enabled, and when disabled, 
*                    it outputs the last data.
*                 3. When writing data to the same address on ports A and B simultaneously, 
*                    the write operation from port B will take precedence.
*                 4. In write mode, the current data input takes precedence for writing, 
*                    and the data from the address input at the previous clock cycle is read out. 
*                    In read mode, the data from the address input at the current clock cycle 
*                    is directly read out. In write mode, when writing to different addresses, 
*                    the data corresponding to the current address input at the current clock cycle 
*                    is directly read out.
*   Dependencies: none(FPGA) auto for BRAM in vivado | RAM_IP with IC 
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clka/b', wave: '101010101'},
  {name: 'ena/b', wave: '01...0...'},
  {name: 'wea/b', wave: '01...0...'},
  {name: 'addra/b', wave: 'x3...3.x.', data: ['addr0','addr2']},
  {name: 'dina/b', wave: 'x4.4.x...', data: ['data0','data1']},
  {name: 'douta/b', wave: 'x..5.5.x.', data: ['data0','data2']},
]}
*/
module DPRAM #(
        // The width parameter for reading and writing data.
        parameter WIDTH = 16,
        // The depth parameter of RAM.
        parameter DEPTH = 1024
    ) (
        // A Port Clock Input
        input                       clka,
        // A Port Enable active high
        input                       ena,
        // A Port Write Enable active high
        input                       wea,
        // A Port Address Inputs
        input [$clog2(DEPTH)-1:0]   addra,
        // A Port Data Inputs
        input [WIDTH-1:0]           dina,
        // A Port Data Outputs
        output reg [WIDTH-1:0]      douta,

        // B Port Clock Input
        input                       clkb,
        // B Port Enable active high
        input                       enb,
        // B Port Write Enable active high
        input                       web,
        // B Port Address Inputs
        input [$clog2(DEPTH)-1:0]   addrb,
        // B Port Data Inputs
        input [WIDTH-1:0]           dinb,
        // B Port Data Outputs
        output reg [WIDTH-1:0]      doutb
    );

    reg [WIDTH - 1 : 0] ram [DEPTH - 1 : 0];
    integer i;
    initial begin
        for(i=0;i<DEPTH;i=i+1) begin
            ram[i] <= 0;
        end
        douta <= 0;
        doutb <= 0;
    end

    always @(posedge clka) begin
        if (ena) begin
            if (wea) begin
                ram[addra] <= dina;
            end
            douta <= ram[addra];
        end
    end

    always @(posedge clkb) begin
        if (enb) begin
            if (web) begin
                ram[addrb] <= dinb;
            end
            doutb <= ram[addrb];
        end
    end
    
endmodule
