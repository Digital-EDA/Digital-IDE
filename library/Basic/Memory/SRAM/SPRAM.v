`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   SPRAM.v - SPRAM
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
*                 3. In write mode, when MODE=0, the output equals the input. 
*                    When MODE=1, write priority is enabled, and the output equals 
*                    the stored value corresponding to the address input from the previous clock cycle.
*   Dependencies: none(FPGA) auto for BRAM in vivado | RAM_IP with IC 
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '1010101010101'},
  {name: 'ena', wave: '01.........0.'},
  {name: 'wea', wave: '01.....0.....'},
  {name: 'addra', wave: 'x3...3.3.3.x.', data: ['addr0','addr1','addr0','addr1']},
  {name: 'dina', wave: 'x4.4.4.x.....', data: ['data00','data01','data2','data3','data4']},
  {name: 'douta', wave: 'x5.5.5.5.5...', data: ['data00','data01','data1','data01','data1']}, // MODE = 0
  {name: 'douta', wave: 'x..5.5.5.5...', data: ['data00','data2','data01','data1']}, // MODE = 1
]}
*/
module SPRAM #(
        // SPRAM output mode
        // 0 : Read first
        // 1 : Write first
        parameter MODE  = 0,
        // The width parameter for reading and writing data.
        parameter WIDTH = 16,
        // The depth parameter of RAM.
        parameter DEPTH = 1024
    )(
        // Clock input 
        input wire  clka,          
        // Enable input active high
        input wire  ena,      
        // Write Enable active high 
        input wire  wea,     

        // Address Inputs
        input wire  [$clog2(DEPTH)-1:0]  addra, 
        // Data Inputs
        input wire  [WIDTH-1:0]          dina,   
        // Data Outputs
        output wire [WIDTH-1:0]          douta  
    );

    reg [WIDTH-1:0] mem [DEPTH-1:0];
    reg [WIDTH-1:0] douta_buf;

    integer i;
    initial begin    
        for (i = 0; i < DEPTH; i=i+1) begin
            mem[i] <= 0;
        end
    end

    always @(posedge clka) begin
        if (ena) begin
            if (wea) begin
                mem[addra] <= dina;
                douta_buf <= MODE ? mem[addra] : dina;
            end 
            else begin
                douta_buf <= mem[addra];
            end
        end
    end

    assign douta = douta_buf;

endmodule
