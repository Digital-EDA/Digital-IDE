/*
*   Date : 2024-08-30
*   Author : cjh
*   Module Name:   DPRAM.v - DPRAM
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
        Revision 0.02 - File upload
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

module ecc_decode #(
    parameter DW = 64,
    parameter PW = $clog2(1+DW+$clog2(1+DW))
) (
    input  [DW + PW : 0] data_i,

    output [DW  - 1 : 0] data_o,

    output               sbiterr,

    output               dbiterr
);

logic  parity;

// Check parity bit. 0 = parity equal, 1 = different parity
assign parity = data_i[DW+PW] ^ (^data_i[DW+PW-1:0]);

///!    | 0  1  2  3  4  5  6  7  8  9 10 11 12  13  14
///!    |p1 p2 d1 p4 d2 d3 d4 p8 d5 d6 d7 d8 d9 d10 d11
///! ---|----------------------------------------------
///! p1 | x     x     x     x     x     x     x       x
///! p2 |    x  x        x  x        x  x         x   x
///! p4 |          x  x  x  x              x  x   x   x
///! p8 |                      x  x  x  x  x  x   x   x

///! 1. Parity bit 1 covers all bit positions which have the least significant bit
///!    set: bit 1 (the parity bit itself), 3, 5, 7, 9, etc.
///! 2. Parity bit 2 covers all bit positions which have the second least
///!    significant bit set: bit 2 (the parity bit itself), 3, 6, 7, 10, 11, etc.
///! 3. Parity bit 4 covers all bit positions which have the third least
///!    significant bit set: bits 4–7, 12–15, 20–23, etc.
///! 4. Parity bit 8 covers all bit positions which have the fourth least
///!    significant bit set: bits 8–15, 24–31, 40–47, etc.
///! 5. In general each parity bit covers all bits where the bitwise AND of the
///!    parity position and the bit position is non-zero.


logic [PW      - 1 : 0] syndrome;
logic                   syndrome_not_zero;

logic [DW + PW - 1 : 0] correct_data;
logic [DW      - 1 : 0] data_wo_parity;

assign                  syndrome_not_zero = |syndrome;

always_comb begin : calculate_syndrome
  syndrome = 0;
  for (int unsigned i = 0; i < PW; i++) begin
    for (int unsigned j = 0; j < DW + PW; j++) begin
      if (|(unsigned'(2**i) & (j + 1))) 
        syndrome[i] = syndrome[i] ^ data_i[j];
    end
  end
end

// correct the data word if the syndrome is non-zero
always_comb begin
  correct_data = data_i[DW + PW - 1 : 0];
  if (syndrome_not_zero) begin
    correct_data[syndrome - 1] = ~data_i[syndrome - 1];
  end
end

///! Syndrome | Overall Parity (MSB) | Error Type   | Notes
  ///! --------------------------------------------------------
  ///! 0        | 0                    | No Error     |
  ///! /=0      | 1                    | Single Error | Correctable. Syndrome holds incorrect bit position.
  ///! 0        | 1                    | Parity Error | Overall parity, MSB is in error and can be corrected.
  ///! /=0      | 0                    | Double Error | Not correctable.

assign sbiterr = parity  & syndrome_not_zero;
assign dbiterr = ~parity & syndrome_not_zero;

// Extract data vector
always_comb begin
  automatic int unsigned idx; // bit index
  data_wo_parity = '0;
  idx = 0;

  for (int unsigned i = 1; i < DW + PW + 1; i++) begin
  // if i is a power of two we are indexing a parity bit
    if (unsigned'(2**$clog2(i)) != i) begin
      data_wo_parity[idx] = correct_data[i - 1];
      idx++;
    end
  end
end

assign data_o = data_wo_parity;

endmodule  //ecc_decode