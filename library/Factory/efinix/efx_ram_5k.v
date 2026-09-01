/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2016 Efinix Inc. All rights reserved.
//
// Efinix Block RAM (BRAM):
//
// This is a 5K simple dual-port RAM
// (one read & one write port)
//
// The read and write ports can
// Be in any of the following WIDTHS
//   16 --> 256x16
//   8  --> 512x8
//   4  --> 1024x4
//   2  --> 2048x2
//   1  --> 4096x1
//   20 --> 256x20
//   10 --> 512x10
//   5  --> 1024x5
//
// Writing can be done in one of two READ DURING WRITE MODEs
//   READ_FIRST
//   WRITE_FIRST
//   READ_UNKNOWN
//
// Behavior is undefined when
// reading / writing the same address
// TODO: Need to add address collision checking!
//
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////
module EFX_RAM_5K
(
   WCLK, WE, WCLKE, WDATA, WADDR,
   RCLK, RE, RDATA, RADDR
);
   

   parameter WCLK_POLARITY  = 1'b1;
   parameter WCLKE_POLARITY = 1'b1;
   parameter WE_POLARITY    = 1'b1;
   parameter RCLK_POLARITY  = 1'b1;
   parameter RE_POLARITY    = 1'b1;
   // Need to add all the data & address input  polarity inversion parameters
   parameter READ_WIDTH = 16;
   parameter WRITE_WIDTH = 16;
   parameter OUTPUT_REG = 1'b0;
   parameter WRITE_MODE = "READ_FIRST";
   parameter INIT_0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_1 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_2 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_3 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_4 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_5 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_6 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_7 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_8 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_9 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_F = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_10 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_11 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_12 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter INIT_13 = 256'h0000000000000000000000000000000000000000000000000000000000000000;

   localparam READ_AWIDTH = 
			    (READ_WIDTH == 1) ? 12 :
			    (READ_WIDTH == 2) ? 11 :
			    (READ_WIDTH == 4) ? 10 :
			    (READ_WIDTH == 5) ? 10 :
			    (READ_WIDTH == 8) ? 9 :
			    (READ_WIDTH == 10) ? 9 :
			    (READ_WIDTH == 16) ? 8 :
			    (READ_WIDTH == 20) ? 8 :-1;
   
   localparam WRITE_AWIDTH = 
			    (WRITE_WIDTH == 1) ? 12 :
			    (WRITE_WIDTH == 2) ? 11 :
			    (WRITE_WIDTH == 4) ? 10 :
			    (WRITE_WIDTH == 5) ? 10 :
			    (WRITE_WIDTH == 8) ? 9 :
			    (WRITE_WIDTH == 10) ? 9 :
			    (WRITE_WIDTH == 16) ? 8 :
			    (WRITE_WIDTH == 20) ? 8 :-1;

   localparam MEMORY_SIZE = 256*20;
      
   input 			WCLK, WE, WCLKE;
   input 			RCLK, RE;
   input [WRITE_WIDTH-1:0]  WDATA;
   input [WRITE_AWIDTH-1:0] WADDR;
   input [READ_AWIDTH-1:0] 	RADDR;
   reg [READ_WIDTH-1:0] 	RDATA_early, RDATA_late;
   reg [READ_WIDTH-1:0] 	RDATA_out = 0;
   reg [READ_WIDTH-1:0] 	RDATA_reg = 0;
   output [READ_WIDTH-1:0] 	RDATA;

   // Local variables
   reg mem [MEMORY_SIZE-1:0];
   integer i;
   
   // Create nets for optional control inputs
   // allows us to assign to them without getting warning
   // for coercing input to inout
   wire     WE_net;
   wire     WCLKE_net;
   wire     RE_net;

   // Pull unused address lines low, to mirror EFX synthesis behavior.
   wire [WRITE_AWIDTH-1:0] WADDR_net;
   wire [READ_AWIDTH-1:0] RADDR_net;

   // Default values for optional control signals
   assign (weak0, weak1) WE_net = WE_POLARITY ? 1'b0 : 1'b1;
   assign (weak0, weak1) WCLKE_net = WCLKE_POLARITY ? 1'b1 : 1'b0;
   assign (weak0, weak1) RE_net = RE_POLARITY ? 1'b1 : 1'b0;

   assign (weak0, weak1) WADDR_net = {WRITE_AWIDTH{1'b0}};
   assign (weak0, weak1) RADDR_net = {READ_AWIDTH{1'b0}};

   // Now assign the input
   assign WE_net = WE;
   assign WCLKE_net = WCLKE;
   assign RE_net = RE;
   
   assign WADDR_net = WADDR;
   assign RADDR_net = RADDR;

   function COMPATIBLE_WIDTH;
	  input integer 	w1, w2;
	  COMPATIBLE_WIDTH = ((((w1==1)||(w1==2)||(w1==4)||(w1==8)||(w1==16))&&((w2==1)||(w2==2)||(w2==4)||(w2==8)||(w2==16))) ||
					(((w1==5)||(w1==10)||(w1==20))&&((w2==5)||(w2==10)||(w2==20))));
   endfunction

   initial begin
	  // Check for illegal modes, address width will be -1
	  if (READ_AWIDTH == -1) begin
		 $display("ERROR:Illegal READ WIDTH %d", READ_WIDTH);
		 $finish();
	  end
	  if (WRITE_AWIDTH == -1) begin
		 $display("ERROR:Illegal WRITE WIDTH %d", WRITE_WIDTH);
		 $finish();
	  end
	  if (~COMPATIBLE_WIDTH(READ_WIDTH,WRITE_WIDTH)) begin
		 $display("ERROR: READ WIDTH %d cannot be used with WRITE WIDTH %d", READ_WIDTH, WRITE_WIDTH);
		 $finish();
	  end
	  // Check for illegal write modes
	  if (WRITE_MODE != "READ_FIRST" && WRITE_MODE != "WRITE_FIRST" && WRITE_MODE != "READ_UNKNOWN") begin
		 $display("ERROR:Illegal WRITE_MODE %s", WRITE_MODE);
		 $finish();
	  end
	  // Initialize memory
      for (i=0; i < 256; i=i+1) begin
		 mem[256*0+i] = INIT_0[i];
		 mem[256*1+i] = INIT_1[i];
		 mem[256*2+i] = INIT_2[i];
		 mem[256*3+i] = INIT_3[i];
		 mem[256*4+i] = INIT_4[i];
		 mem[256*5+i] = INIT_5[i];
		 mem[256*6+i] = INIT_6[i];
		 mem[256*7+i] = INIT_7[i];
		 mem[256*8+i] = INIT_8[i];
		 mem[256*9+i] = INIT_9[i];
		 mem[256*10+i] = INIT_A[i];
		 mem[256*11+i] = INIT_B[i];
		 mem[256*12+i] = INIT_C[i];
		 mem[256*13+i] = INIT_D[i];
		 mem[256*14+i] = INIT_E[i];
		 mem[256*15+i] = INIT_F[i];
		 mem[256*16+i] = INIT_10[i];
		 mem[256*17+i] = INIT_11[i];
		 mem[256*18+i] = INIT_12[i];
		 mem[256*19+i] = INIT_13[i];
      end
   end

   // Wires for the polarity control.
   // Only supporting clocks and enable for now
   wire 			WCLK_i, WE_i, WCLKE_i;
   wire 			RCLK_i, RE_i, RCLKE_i;

   assign WCLK_i  = WCLK_POLARITY ? WCLK : ~WCLK;
   assign WCLKE_i = WCLKE_POLARITY ? WCLKE_net : ~WCLKE_net;
   assign WE_i    = WE_POLARITY ? WE_net : ~WE_net;
   assign RCLK_i  = RCLK_POLARITY ? RCLK : ~RCLK;
   assign RE_i    = RE_POLARITY ? RE_net : ~RE_net;

   //////////////////////////////////////////////////////////////
   // Tasks for actual RAM reading & writing
   //////////////////////////////////////////////////////////////
   task read_ram;
	  input [READ_AWIDTH-1:0] addr;
	  output [READ_WIDTH-1:0] rdata;
 
	  begin
		 for (i=0; i < READ_WIDTH; i=i+1)
		   rdata[i] = mem[addr*READ_WIDTH+i];
	  end
   endtask

   task write_ram;
	  input [WRITE_AWIDTH-1:0] addr;
	  input [WRITE_WIDTH-1:0] wdata;
	  
	  begin
		 for (i=0; i < WRITE_WIDTH; i=i+1)
		   mem[addr*WRITE_WIDTH+i] = wdata[i];
	  end
   endtask   

   always@(posedge WCLK_i)
     if (WE_i & WCLKE_i) begin
		// Do an early read, write and late read
		// Then decide what do do with the read data
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		write_ram(WADDR_net, WDATA);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
	 end
   
   always@(posedge RCLK_i)
     if (RE_i) begin
		// Do an early read, write and late read
		// Then decide what do do with the read data
	   read_ram(RADDR_net, RDATA_early);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		#0; // Use #0 delay blocking assignments to allow cross port read/write
	   read_ram(RADDR_net, RDATA_late);

		// Based on the write mode decide which read data to use
		if (WRITE_MODE == "READ_FIRST") begin
		   RDATA_out = RDATA_early;
		end
		else if (WRITE_MODE == "WRITE_FIRST") begin
		   RDATA_out = RDATA_late;
		end
		else /* (WRITE_MODE == "READ_UNKNOWN") */ begin
		   RDATA_out = (RDATA_early === RDATA_late) ? RDATA_early : {READ_WIDTH{1'bx}};
		end
	 end

   // Optional output register
   generate if (OUTPUT_REG) 
	 begin
		always@(posedge RCLK_i)
			RDATA_reg <= RDATA_out;

		assign RDATA = RDATA_reg;
	 end
   else
	 begin
		assign RDATA = RDATA_out;
	 end // else: !if(OUTPUT_REG)
   endgenerate
	       
endmodule // EFX_RAM_5K

//////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2013-2017 Efinix Inc. All rights reserved.
//
// This   document  contains  proprietary information  which   is
// protected by  copyright. All rights  are reserved.  This notice
// refers to original work by Efinix, Inc. which may be derivitive
// of other work distributed under license of the authors.  In the
// case of derivative work, nothing in this notice overrides the
// original author's license agreement.  Where applicable, the 
// original license agreement is included in it's original 
// unmodified form immediately below this header.
//
// WARRANTY DISCLAIMER.  
//     THE  DESIGN, CODE, OR INFORMATION ARE PROVIDED “AS IS” AND 
//     EFINIX MAKES NO WARRANTIES, EXPRESS OR IMPLIED WITH 
//     RESPECT THERETO, AND EXPRESSLY DISCLAIMS ANY IMPLIED WARRANTIES, 
//     INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
//     MERCHANTABILITY, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR 
//     PURPOSE.  SOME STATES DO NOT ALLOW EXCLUSIONS OF AN IMPLIED 
//     WARRANTY, SO THIS DISCLAIMER MAY NOT APPLY TO LICENSEE.
//
// LIMITATION OF LIABILITY.  
//     NOTWITHSTANDING ANYTHING TO THE CONTRARY, EXCEPT FOR BODILY 
//     INJURY, EFINIX SHALL NOT BE LIABLE WITH RESPECT TO ANY SUBJECT 
//     MATTER OF THIS AGREEMENT UNDER TORT, CONTRACT, STRICT LIABILITY 
//     OR ANY OTHER LEGAL OR EQUITABLE THEORY (I) FOR ANY INDIRECT, 
//     SPECIAL, INCIDENTAL, EXEMPLARY OR CONSEQUENTIAL DAMAGES OF ANY 
//     CHARACTER INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF 
//     GOODWILL, DATA OR PROFIT, WORK STOPPAGE, OR COMPUTER FAILURE OR 
//     MALFUNCTION, OR IN ANY EVENT (II) FOR ANY AMOUNT IN EXCESS, IN 
//     THE AGGREGATE, OF THE FEE PAID BY LICENSEE TO EFINIX HEREUNDER 
//     (OR, IF THE FEE HAS BEEN WAIVED, $100), EVEN IF EFINIX SHALL HAVE 
//     BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGES.  SOME STATES DO 
//     NOT ALLOW THE EXCLUSION OR LIMITATION OF INCIDENTAL OR 
//     CONSEQUENTIAL DAMAGES, SO THIS LIMITATION AND EXCLUSION MAY NOT 
//     APPLY TO LICENSEE.
//
/////////////////////////////////////////////////////////////////////////////
