/*
*   Date : 2024-08-30
*   Author : cjh
*   Module Name:   DPRAM.v - DPRAM
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*       Revision 0.02 - File upload
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

module ecc_encode #(
  parameter DW = 64,
  parameter PW = $clog2(1+DW+$clog2(1+DW))
) (

  input  [DW - 1  : 0] data_i,

  output [DW + PW : 0] data_o
);

logic [PW - 1 : 0]      parity;
logic [DW + PW - 1 : 0] data;
logic [DW + PW - 1 : 0] codeword;

// Expand incoming data to codeword width
always_comb begin : expand_data
  automatic int unsigned idx;
  data = 0;
  idx  = 0;
  for (int unsigned i = 1; i < DW + PW + 1; i++) begin
    // if it is not a power of two word it is a normal data index
    if (unsigned'(2**$clog2(i)) != i) begin
      data[i - 1] = data_i[idx];
      idx++;
    end
  end
end

// calculate code word
always_comb begin : calculate_syndrome
  parity = 0;
  for (int unsigned i = 0; i < PW; i++) begin
    for (int unsigned j = 1; j < DW + PW + 1; j++) begin
      if (|(unsigned'(2**i) & j))
        parity[i] = parity[i] ^ data[j - 1];
    end
  end
end

// fuse the final codeword
always_comb begin : generate_codeword
  codeword = data;
  for (int unsigned i = 0; i < PW; i++) begin
    codeword[2**i-1] = parity[i];
  end
end

assign data_o[DW+PW-1:0] = codeword;
assign data_o[DW+PW]   = ^codeword;

endmodule