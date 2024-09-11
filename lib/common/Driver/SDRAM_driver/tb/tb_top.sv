//////////////////////////////////////////////////////////////////////
////                                                              ////
////                                                              ////
////  This file is part of the SDRAM Controller project           ////
////  http://www.opencores.org/cores/sdr_ctrl/                    ////
////                                                              ////
////  Description                                                 ////
////  SDRAM CTRL definitions.                                     ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
//   Version  :0.1 - Test Bench automation is improvised with     ////
//             seperate data,address,burst length fifo.           ////
//             Now user can create different write and            ////
//             read sequence                                      ////
//                                                                ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

// This testbench verify with SDRAM TOP

module tb_top;

parameter P_SYS  = 10;     //    200MHz
parameter P_SDR  = 20;     //    100MHz

// General
reg            RESETN;
reg            sdram_clk;
reg            sys_clk;

initial sys_clk = 0;
initial sdram_clk = 0;

always #(P_SYS/2) sys_clk = !sys_clk;
always #(P_SDR/2) sdram_clk = !sdram_clk;

parameter      dw              = 32;  // data width
parameter      tw              = 8;   // tag id width
parameter      bl              = 5;   // burst_lenght_width 

//-------------------------------------------
// WISH BONE Interface
//-------------------------------------------
//--------------------------------------
// Wish Bone Interface
// -------------------------------------      
reg             wb_stb_i           ;
wire            wb_ack_o           ;
reg  [25:0]     wb_addr_i          ;
reg             wb_we_i            ; // 1 - Write, 0 - Read
reg  [dw-1:0]   wb_dat_i           ;
reg  [dw/8-1:0] wb_sel_i           ; // Byte enable
wire  [dw-1:0]  wb_dat_o           ;
reg             wb_cyc_i           ;
reg   [2:0]     wb_cti_i           ;



//--------------------------------------------
// SDRAM I/F 
//--------------------------------------------

`ifdef SDR_32BIT
   wire [31:0]           Dq                 ; // SDRAM Read/Write Data Bus
   wire [3:0]            sdr_dqm            ; // SDRAM DATA Mask
`elsif SDR_16BIT 
   wire [15:0]           Dq                 ; // SDRAM Read/Write Data Bus
   wire [1:0]            sdr_dqm            ; // SDRAM DATA Mask
`else 
   wire [7:0]           Dq                 ; // SDRAM Read/Write Data Bus
   wire [0:0]           sdr_dqm            ; // SDRAM DATA Mask
`endif

wire [1:0]            sdr_ba             ; // SDRAM Bank Select
wire [12:0]           sdr_addr           ; // SDRAM ADRESS
wire                  sdr_init_done      ; // SDRAM Init Done 

// to fix the sdram interface timing issue
wire #(2.0) sdram_clk_d   = sdram_clk;

`ifdef SDR_32BIT

   sdrc_top #(.SDR_DW(32),.SDR_BW(4)) u_dut(
`elsif SDR_16BIT 
   sdrc_top #(.SDR_DW(16),.SDR_BW(2)) u_dut(
`else  // 8 BIT SDRAM
   sdrc_top #(.SDR_DW(8),.SDR_BW(1)) u_dut(
`endif
      // System 
`ifdef SDR_32BIT
          .cfg_sdr_width      (2'b00              ), // 32 BIT SDRAM
`elsif SDR_16BIT
          .cfg_sdr_width      (2'b01              ), // 16 BIT SDRAM
`else 
          .cfg_sdr_width      (2'b10              ), // 8 BIT SDRAM
`endif
          .cfg_colbits        (2'b00              ), // 8 Bit Column Address

/* WISH BONE */
          .wb_rst_i           (!RESETN            ),
          .wb_clk_i           (sys_clk            ),

          .wb_stb_i           (wb_stb_i           ),
          .wb_ack_o           (wb_ack_o           ),
          .wb_addr_i          (wb_addr_i          ),
          .wb_we_i            (wb_we_i            ),
          .wb_dat_i           (wb_dat_i           ),
          .wb_sel_i           (wb_sel_i           ),
          .wb_dat_o           (wb_dat_o           ),
          .wb_cyc_i           (wb_cyc_i           ),
          .wb_cti_i           (wb_cti_i           ), 

/* Interface to SDRAMs */
          .sdram_clk          (sdram_clk          ),
          .sdram_resetn       (RESETN             ),
          .sdr_cs_n           (sdr_cs_n           ),
          .sdr_cke            (sdr_cke            ),
          .sdr_ras_n          (sdr_ras_n          ),
          .sdr_cas_n          (sdr_cas_n          ),
          .sdr_we_n           (sdr_we_n           ),
          .sdr_dqm            (sdr_dqm            ),
          .sdr_ba             (sdr_ba             ),
          .sdr_addr           (sdr_addr           ), 
          .sdr_dq             (Dq                 ),

    /* Parameters */
          .sdr_init_done      (sdr_init_done      ),
          .cfg_req_depth      (2'h3               ),	        //how many req. buffer should hold
          .cfg_sdr_en         (1'b1               ),
          .cfg_sdr_mode_reg   (13'h033            ),
          .cfg_sdr_tras_d     (4'h4               ),
          .cfg_sdr_trp_d      (4'h2               ),
          .cfg_sdr_trcd_d     (4'h2               ),
          .cfg_sdr_cas        (3'h3               ),
          .cfg_sdr_trcar_d    (4'h7               ),
          .cfg_sdr_twr_d      (4'h1               ),
          .cfg_sdr_rfsh       (12'h100            ), // reduced from 12'hC35
          .cfg_sdr_rfmax      (3'h6               )

);


`ifdef SDR_32BIT
mt48lc2m32b2 #(.data_bits(32)) u_sdram32 (
          .Dq                 (Dq                 ) , 
          .Addr               (sdr_addr[10:0]     ), 
          .Ba                 (sdr_ba             ), 
          .Clk                (sdram_clk_d        ), 
          .Cke                (sdr_cke            ), 
          .Cs_n               (sdr_cs_n           ), 
          .Ras_n              (sdr_ras_n          ), 
          .Cas_n              (sdr_cas_n          ), 
          .We_n               (sdr_we_n           ), 
          .Dqm                (sdr_dqm            )
     );

`elsif SDR_16BIT

   IS42VM16400K u_sdram16 (
          .dq                 (Dq                 ), 
          .addr               (sdr_addr[11:0]     ), 
          .ba                 (sdr_ba             ), 
          .clk                (sdram_clk_d        ), 
          .cke                (sdr_cke            ), 
          .csb                (sdr_cs_n           ), 
          .rasb               (sdr_ras_n          ), 
          .casb               (sdr_cas_n          ), 
          .web                (sdr_we_n           ), 
          .dqm                (sdr_dqm            )
    );
`else 


mt48lc8m8a2 #(.data_bits(8)) u_sdram8 (
          .Dq                 (Dq                 ) , 
          .Addr               (sdr_addr[11:0]     ), 
          .Ba                 (sdr_ba             ), 
          .Clk                (sdram_clk_d        ), 
          .Cke                (sdr_cke            ), 
          .Cs_n               (sdr_cs_n           ), 
          .Ras_n              (sdr_ras_n          ), 
          .Cas_n              (sdr_cas_n          ), 
          .We_n               (sdr_we_n           ), 
          .Dqm                (sdr_dqm            )
     );
`endif

//--------------------
// data/address/burst length FIFO
//--------------------
int dfifo[$]; // data fifo
int afifo[$]; // address  fifo
int bfifo[$]; // Burst Length fifo

reg [31:0] read_data;
reg [31:0] ErrCnt;
int k;
reg [31:0] StartAddr;
/////////////////////////////////////////////////////////////////////////
// Test Case
/////////////////////////////////////////////////////////////////////////

initial begin //{
  ErrCnt          = 0;
   wb_addr_i      = 0;
   wb_dat_i      = 0;
   wb_sel_i       = 4'h0;
   wb_we_i        = 0;
   wb_stb_i       = 0;
   wb_cyc_i       = 0;

  RESETN    = 1'h1;

 #100
  // Applying reset
  RESETN    = 1'h0;
  #10000;
  // Releasing reset
  RESETN    = 1'h1;
  #1000;
  wait(u_dut.sdr_init_done == 1);

  #1000;
  $display("-------------------------------------- ");
  $display(" Case-1: Single Write/Read Case        ");
  $display("-------------------------------------- ");

  burst_write(32'h4_0000,8'h4);  
 #1000;
  burst_read();  

  // Repeat one more time to analysis the 
  // SDRAM state change for same col/row address
  $display("-------------------------------------- ");
  $display(" Case-2: Repeat same transfer once again ");
  $display("----------------------------------------");
  burst_write(32'h4_0000,8'h4);  
  burst_read();  
  burst_write(32'h0040_0000,8'h5);  
  burst_read();  
  $display("----------------------------------------");
  $display(" Case-3 Create a Page Cross Over        ");
  $display("----------------------------------------");
  burst_write(32'h0000_0FF0,8'h8);  
  burst_write(32'h0001_0FF4,8'hF);  
  burst_write(32'h0002_0FF8,8'hF);  
  burst_write(32'h0003_0FFC,8'hF);  
  burst_write(32'h0004_0FE0,8'hF);  
  burst_write(32'h0005_0FE4,8'hF);  
  burst_write(32'h0006_0FE8,8'hF);  
  burst_write(32'h0007_0FEC,8'hF);  
  burst_write(32'h0008_0FD0,8'hF);  
  burst_write(32'h0009_0FD4,8'hF);  
  burst_write(32'h000A_0FD8,8'hF);  
  burst_write(32'h000B_0FDC,8'hF);  
  burst_write(32'h000C_0FC0,8'hF);  
  burst_write(32'h000D_0FC4,8'hF);  
  burst_write(32'h000E_0FC8,8'hF);  
  burst_write(32'h000F_0FCC,8'hF);  
  burst_write(32'h0010_0FB0,8'hF);  
  burst_write(32'h0011_0FB4,8'hF);  
  burst_write(32'h0012_0FB8,8'hF);  
  burst_write(32'h0013_0FBC,8'hF);  
  burst_write(32'h0014_0FA0,8'hF);  
  burst_write(32'h0015_0FA4,8'hF);  
  burst_write(32'h0016_0FA8,8'hF);  
  burst_write(32'h0017_0FAC,8'hF);  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  

  $display("----------------------------------------");
  $display(" Case:4 4 Write & 4 Read                ");
  $display("----------------------------------------");
  burst_write(32'h4_0000,8'h4);  
  burst_write(32'h5_0000,8'h5);  
  burst_write(32'h6_0000,8'h6);  
  burst_write(32'h7_0000,8'h7);  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  

  $display("---------------------------------------");
  $display(" Case:5 24 Write & 24 Read With Different Bank and Row ");
  $display("---------------------------------------");
  //----------------------------------------
  // Address Decodeing:
  //  with cfg_col bit configured as: 00
  //    <12 Bit Row> <2 Bit Bank> <8 Bit Column> <2'b00>
  //
  burst_write({12'h000,2'b00,8'h00,2'b00},8'h4);   // Row: 0 Bank : 0
  burst_write({12'h000,2'b01,8'h00,2'b00},8'h5);   // Row: 0 Bank : 1
  burst_write({12'h000,2'b10,8'h00,2'b00},8'h6);   // Row: 0 Bank : 2
  burst_write({12'h000,2'b11,8'h00,2'b00},8'h7);   // Row: 0 Bank : 3
  burst_write({12'h001,2'b00,8'h00,2'b00},8'h4);   // Row: 1 Bank : 0
  burst_write({12'h001,2'b01,8'h00,2'b00},8'h5);   // Row: 1 Bank : 1
  burst_write({12'h001,2'b10,8'h00,2'b00},8'h6);   // Row: 1 Bank : 2
  burst_write({12'h001,2'b11,8'h00,2'b00},8'h7);   // Row: 1 Bank : 3
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  

  burst_write({12'h002,2'b00,8'h00,2'b00},8'h4);   // Row: 2 Bank : 0
  burst_write({12'h002,2'b01,8'h00,2'b00},8'h5);   // Row: 2 Bank : 1
  burst_write({12'h002,2'b10,8'h00,2'b00},8'h6);   // Row: 2 Bank : 2
  burst_write({12'h002,2'b11,8'h00,2'b00},8'h7);   // Row: 2 Bank : 3
  burst_write({12'h003,2'b00,8'h00,2'b00},8'h4);   // Row: 3 Bank : 0
  burst_write({12'h003,2'b01,8'h00,2'b00},8'h5);   // Row: 3 Bank : 1
  burst_write({12'h003,2'b10,8'h00,2'b00},8'h6);   // Row: 3 Bank : 2
  burst_write({12'h003,2'b11,8'h00,2'b00},8'h7);   // Row: 3 Bank : 3

  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  

  burst_write({12'h002,2'b00,8'h00,2'b00},8'h4);   // Row: 2 Bank : 0
  burst_write({12'h002,2'b01,8'h01,2'b00},8'h5);   // Row: 2 Bank : 1
  burst_write({12'h002,2'b10,8'h02,2'b00},8'h6);   // Row: 2 Bank : 2
  burst_write({12'h002,2'b11,8'h03,2'b00},8'h7);   // Row: 2 Bank : 3
  burst_write({12'h003,2'b00,8'h04,2'b00},8'h4);   // Row: 3 Bank : 0
  burst_write({12'h003,2'b01,8'h05,2'b00},8'h5);   // Row: 3 Bank : 1
  burst_write({12'h003,2'b10,8'h06,2'b00},8'h6);   // Row: 3 Bank : 2
  burst_write({12'h003,2'b11,8'h07,2'b00},8'h7);   // Row: 3 Bank : 3

  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  burst_read();  
  $display("---------------------------------------------------");
  $display(" Case: 6 Random 2 write and 2 read random");
  $display("---------------------------------------------------");
  for(k=0; k < 20; k++) begin
     StartAddr = $random & 32'h003FFFFF;
     burst_write(StartAddr,($random & 8'h0f)+1);  
 #100;

     StartAddr = $random & 32'h003FFFFF;
     burst_write(StartAddr,($random & 8'h0f)+1);  
 #100;
     burst_read();  
 #100;
     burst_read();  
 #100;
  end

  #10000;

        $display("###############################");
    if(ErrCnt == 0)
        $display("STATUS: SDRAM Write/Read TEST PASSED");
    else
        $display("ERROR:  SDRAM Write/Read TEST FAILED");
        $display("###############################");

    $finish;
end

task burst_write;
input [31:0] Address;
input [7:0]  bl;
int i;
begin
  afifo.push_back(Address);
  bfifo.push_back(bl);

   @ (negedge sys_clk);
   $display("Write Address: %x, Burst Size: %d",Address,bl);

   for(i=0; i < bl; i++) begin
      wb_stb_i        = 1;
      wb_cyc_i        = 1;
      wb_we_i         = 1;
      wb_sel_i        = 4'b1111;
      wb_addr_i       = Address[31:2]+i;
      wb_dat_i        = $random & 32'hFFFFFFFF;
      dfifo.push_back(wb_dat_i);

      do begin
          @ (posedge sys_clk);
      end while(wb_ack_o == 1'b0);
          @ (negedge sys_clk);
   
       $display("Status: Burst-No: %d  Write Address: %x  WriteData: %x ",i,wb_addr_i,wb_dat_i);
   end
   wb_stb_i        = 0;
   wb_cyc_i        = 0;
   wb_we_i         = 'hx;
   wb_sel_i        = 'hx;
   wb_addr_i       = 'hx;
   wb_dat_i        = 'hx;
end
endtask

task burst_read;
reg [31:0] Address;
reg [7:0]  bl;

int i,j;
reg [31:0]   exp_data;
begin
  
   Address = afifo.pop_front(); 
   bl      = bfifo.pop_front(); 
   @ (negedge sys_clk);

      for(j=0; j < bl; j++) begin
         wb_stb_i        = 1;
         wb_cyc_i        = 1;
         wb_we_i         = 0;
         wb_addr_i       = Address[31:2]+j;

         exp_data        = dfifo.pop_front(); // Exptected Read Data
         do begin
             @ (posedge sys_clk);
         end while(wb_ack_o == 1'b0);
         if(wb_dat_o !== exp_data) begin
             $display("READ ERROR: Burst-No: %d Addr: %x Rxp: %x Exd: %x",j,wb_addr_i,wb_dat_o,exp_data);
             ErrCnt = ErrCnt+1;
         end else begin
             $display("READ STATUS: Burst-No: %d Addr: %x Rxd: %x",j,wb_addr_i,wb_dat_o);
         end 
         @ (negedge sdram_clk);
      end
   wb_stb_i        = 0;
   wb_cyc_i        = 0;
   wb_we_i         = 'hx;
   wb_addr_i       = 'hx;
end
endtask


endmodule
