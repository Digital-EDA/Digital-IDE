/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2016 Efinix Inc. All rights reserved.
//
// Efinix Dual-Port Block RAM (BRAM):
//
// This is a 5K true dual-port RAM
//
// The A & B ports can
// Be in any of the following WIDTHs:
//   8  --> 512x8
//   4  --> 1024x4
//   2  --> 2048x2
//   1  --> 4096x1
//   10 --> 512x10
//   5  --> 1024x5
// Reading and Writing can be in different WIDTHs
//
// Writing can be done in one of three WRITE MODEs
//   READ_FIRST
//   WRITE_FIRST
//   NO_CHANGE
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

module EFX_DPRAM_5K
(
   CLKA, WEA, CLKEA, WDATAA, ADDRA, RDATAA,
   CLKB, WEB, CLKEB, WDATAB, ADDRB, RDATAB
);
   

   parameter CLKA_POLARITY  = 1'b1;
   parameter CLKEA_POLARITY = 1'b1;
   parameter WEA_POLARITY   = 1'b1;
   parameter CLKB_POLARITY  = 1'b1;
   parameter CLKEB_POLARITY = 1'b1;
   parameter WEB_POLARITY   = 1'b1;
   // Need to add all the data & address input  polarity inversion parameters
   parameter READ_WIDTH_A = 8;
   parameter WRITE_WIDTH_A = 8;
   parameter READ_WIDTH_B = 8;
   parameter WRITE_WIDTH_B = 8;
   parameter OUTPUT_REG_A = 1'b0;
   parameter OUTPUT_REG_B = 1'b0;
   parameter WRITE_MODE_A = "READ_FIRST";
   parameter WRITE_MODE_B = "READ_FIRST";
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

   localparam READ_AWIDTH_A = 
			    (READ_WIDTH_A == 1) ? 12 :
			    (READ_WIDTH_A == 2) ? 11 :
			    (READ_WIDTH_A == 4) ? 10 :
			    (READ_WIDTH_A == 5) ? 10 :
			    (READ_WIDTH_A == 8) ? 9 :
			    (READ_WIDTH_A == 10) ? 9 :-1;
   
   localparam WRITE_AWIDTH_A = 
			    (WRITE_WIDTH_A == 1) ? 12 :
			    (WRITE_WIDTH_A == 2) ? 11 :
			    (WRITE_WIDTH_A == 4) ? 10 :
			    (WRITE_WIDTH_A == 5) ? 10 :
			    (WRITE_WIDTH_A == 8) ? 9 :
			    (WRITE_WIDTH_A == 10) ? 9 :-1;

   // Greater of Read and Write widths defines input size
   localparam AWIDTH_A = (READ_AWIDTH_A > WRITE_AWIDTH_A) ? READ_AWIDTH_A : WRITE_AWIDTH_A;
   localparam DWIDTH_A = (READ_WIDTH_A > WRITE_WIDTH_A) ? WRITE_WIDTH_A : READ_WIDTH_A;
   
   localparam READ_AWIDTH_B = 
			    (READ_WIDTH_B == 1) ? 12 :
			    (READ_WIDTH_B == 2) ? 11 :
			    (READ_WIDTH_B == 4) ? 10 :
			    (READ_WIDTH_B == 5) ? 10 :
			    (READ_WIDTH_B == 8) ? 9 :
			    (READ_WIDTH_B == 10) ? 9 :-1;
   
   localparam WRITE_AWIDTH_B = 
			    (WRITE_WIDTH_B == 1) ? 12 :
			    (WRITE_WIDTH_B == 2) ? 11 :
			    (WRITE_WIDTH_B == 4) ? 10 :
			    (WRITE_WIDTH_B == 5) ? 10 :
			    (WRITE_WIDTH_B == 8) ? 9 :
			    (WRITE_WIDTH_B == 10) ? 9 :-1;
   
   // Greater of Read and Write widths defines input size
   localparam AWIDTH_B = (READ_AWIDTH_B > WRITE_AWIDTH_B) ? READ_AWIDTH_B : WRITE_AWIDTH_B;
   localparam DWIDTH_B = (READ_WIDTH_B > WRITE_WIDTH_B) ? WRITE_WIDTH_B : READ_WIDTH_B;

   
   localparam MEMORY_SIZE = 256*20;

   localparam READ_FIRST = 0;
   localparam WRITE_FIRST = 1;
   localparam WRITE_NOT_READ = 2;
   
   input 			CLKA, WEA, CLKEA;
   input 			CLKB, WEB, CLKEB;
   input [WRITE_WIDTH_A-1:0] WDATAA;
   input [AWIDTH_A-1:0] 	 ADDRA;
   reg [READ_WIDTH_A-1:0] 	 RDATAA_early, RDATAA_late;
   reg [READ_WIDTH_A-1:0] 	 RDATAA_out = 0;
   reg [READ_WIDTH_A-1:0] 	 RDATAA_reg = 0;
   output [READ_WIDTH_A-1:0] RDATAA;
   input [WRITE_WIDTH_B-1:0] WDATAB;
   input [AWIDTH_B-1:0] 	 ADDRB;
   reg [READ_WIDTH_B-1:0] 	 RDATAB_early, RDATAB_late;
   reg [READ_WIDTH_B-1:0] 	 RDATAB_out = 0;
   reg [READ_WIDTH_B-1:0] 	 RDATAB_reg = 0;
   output [READ_WIDTH_B-1:0] RDATAB;

   // Local variables
   reg mem [MEMORY_SIZE-1:0];
   integer i;
   
   // Create nets for optional control inputs
   // allows us to assign to them without getting warning
   // for coercing input to inout
   wire     WEA_net;
   wire     CLKEA_net;
   wire     WEB_net;
   wire     CLKEB_net;

   // Pull unused address lines low, to mirror EFX synthesis behavior.
   wire [AWIDTH_A-1:0] ADDRA_net;
   wire [AWIDTH_B-1:0] ADDRB_net;

   // Default values for optional control signals
   assign (weak0, weak1) WEA_net = WEA_POLARITY ? 1'b0 : 1'b1;
   assign (weak0, weak1) CLKEA_net = CLKEA_POLARITY ? 1'b1 : 1'b0;
   assign (weak0, weak1) WEB_net = WEB_POLARITY ? 1'b0 : 1'b1;
   assign (weak0, weak1) CLKEB_net = CLKEB_POLARITY ? 1'b1 : 1'b0;

   assign (weak0, weak1) ADDRA_net = {AWIDTH_A{1'b0}};
   assign (weak0, weak1) ADDRB_net = {AWIDTH_B{1'b0}};

   // Now assign the input
   assign WEA_net = WEA;
   assign CLKEA_net = CLKEA;
   assign WEB_net = WEB;
   assign CLKEB_net = CLKEB;

   assign ADDRA_net = ADDRA;
   assign ADDRB_net = ADDRB;

   function COMPATIBLE_WIDTH;
	  input integer 	w1, w2;
	  COMPATIBLE_WIDTH = ((((w1==1)||(w1==2)||(w1==4)||(w1==8))&&((w2==1)||(w2==2)||(w2==4)||(w2==8))) ||
					(((w1==5)||(w1==10))&&((w2==5)||(w2==10))));
   endfunction

   
   initial begin
	  // Check for illegal modes, address width will be -1
	  if (READ_AWIDTH_A == -1) begin
		 $display("ERROR:Illegal READ WIDTH Port A %d", READ_WIDTH_A);
		 $finish();
	  end
	  if (WRITE_AWIDTH_A == -1) begin
		 $display("ERROR:Illegal WRITE WIDTH Port A %d", WRITE_WIDTH_A);
		 $finish();
	  end
	  if (READ_AWIDTH_B == -1) begin
		 $display("ERROR:Illegal READ WIDTH Port B %d", READ_WIDTH_B);
		 $finish();
	  end
	  if (WRITE_AWIDTH_B == -1) begin
		 $display("ERROR:Illegal WRITE WIDTH Port B %d", WRITE_WIDTH_B);
		 $finish();
	  end
	  if (~COMPATIBLE_WIDTH(READ_WIDTH_A,WRITE_WIDTH_A)) begin
		 $display("ERROR: Port A READ WIDTH %d cannot be used with WRITE WIDTH %d", READ_WIDTH_A, WRITE_WIDTH_A);
		 $finish();
	  end
	  if (~COMPATIBLE_WIDTH(READ_WIDTH_B,WRITE_WIDTH_B)) begin
		 $display("ERROR: Port B READ WIDTH %d cannot be used with WRITE WIDTH %d", READ_WIDTH_B, WRITE_WIDTH_B);
		 $finish();
	  end
	  if (~COMPATIBLE_WIDTH(READ_WIDTH_A,READ_WIDTH_B)||~COMPATIBLE_WIDTH(WRITE_WIDTH_A,WRITE_WIDTH_B)) begin
		 $display("ERROR: Port A READ/WRITE WIDTHS %d/%d cannot be used with Port B READ/WRITE WIDTHs %d/%d", 
				  READ_WIDTH_A, WRITE_WIDTH_A, READ_WIDTH_B, WRITE_WIDTH_B);
		 $finish();
	  end
	  // Check for illegal write modes
	  if (WRITE_MODE_A != "READ_FIRST" && WRITE_MODE_A != "WRITE_FIRST" && WRITE_MODE_A != "NO_CHANGE") begin
		 $display("ERROR:Illegal WRITE_MODE A %s", WRITE_MODE_A);
		 $finish();
	  end
	  if (WRITE_MODE_B != "READ_FIRST" && WRITE_MODE_B != "WRITE_FIRST" && WRITE_MODE_B != "NO_CHANGE") begin
		 $display("ERROR:Illegal WRITE_MODE B %s", WRITE_MODE_B);
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
   wire 			CLKA_i, WEA_i, CLKEA_i;
   wire 			CLKB_i, WEB_i, CLKEB_i;

   assign CLKA_i  = CLKA_POLARITY  ? CLKA : ~CLKA;
   assign CLKEA_i = CLKEA_POLARITY ? CLKEA_net : ~CLKEA_net;
   assign WEA_i   = WEA_POLARITY   ? WEA_net : ~WEA_net;
   assign CLKB_i  = CLKB_POLARITY  ? CLKB : ~CLKB;
   assign CLKEB_i = CLKEB_POLARITY ? CLKEB_net : ~CLKEB_net;
   assign WEB_i   = WEB_POLARITY   ? WEB_net : ~WEB_net;

   //////////////////////////////////////////////////////////////
   // Port A
   //////////////////////////////////////////////////////////////
   task read_rama;
	  input [READ_AWIDTH_A-1:0] addr;
	  output [READ_WIDTH_A-1:0] rdata;

	  
	  begin
		
		for (i=0; i < READ_WIDTH_A; i=i+1)
		    rdata[i] = mem[addr*READ_WIDTH_A+i];
	  end
   endtask

   task write_rama;
	  input [WRITE_AWIDTH_A-1:0] addr;
	  input [WRITE_WIDTH_A-1:0] wdata;
	  input we;
	  
	  begin
		if (we)
		   for (i=0; i < WRITE_WIDTH_A; i=i+1)
			 mem[addr*WRITE_WIDTH_A+i] = wdata[i];
	  end
   endtask

   always@(posedge CLKA_i)
     if (CLKEA_i) begin
		// Do an early read, write and late read
		// Then decide what do do with the read data
		read_rama(ADDRA_net[AWIDTH_A-1:AWIDTH_A - READ_AWIDTH_A], RDATAA_early);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		write_rama(ADDRA_net[AWIDTH_A-1:AWIDTH_A - WRITE_AWIDTH_A], WDATAA, WEA_i);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		read_rama(ADDRA_net[AWIDTH_A-1:AWIDTH_A - READ_AWIDTH_A], RDATAA_late);
		   
		// Based on the write mode decide which read data to use
		if (WRITE_MODE_A == "READ_FIRST") begin
		   RDATAA_out = RDATAA_early;
		end
		else if (WRITE_MODE_A == "WRITE_FIRST") begin
		   RDATAA_out = RDATAA_late;
		end
		else /* (WRITE_MODE_A == "NO_CHANGE") */ begin
		   RDATAA_out = WEA_i ? RDATAA_out : RDATAA_early;
		end
	 end
   
   // Optional output register
   generate if (OUTPUT_REG_A) 
	 begin
		always@(posedge CLKA_i)
			RDATAA_reg <= RDATAA_out;

		assign RDATAA = RDATAA_reg;
	 end
   else
	 begin
		assign RDATAA = RDATAA_out;
	 end
   endgenerate

   //////////////////////////////////////////////////////////////
   // Port B
   //////////////////////////////////////////////////////////////
   task read_ramb;
	  input [READ_AWIDTH_B-1:0] addr;
	  output [READ_WIDTH_B-1:0] rdata;

	  begin
		 for (i=0; i < READ_WIDTH_B; i=i+1)
		   rdata[i] = mem[addr*READ_WIDTH_B+i];
	  end
   endtask

   task write_ramb;
	  input [WRITE_AWIDTH_B-1:0] addr;
	  input [WRITE_WIDTH_B-1:0] wdata;
	  input  we;

	  begin
		 if (we)
		   for (i=0; i < WRITE_WIDTH_B; i=i+1)
			 mem[addr*WRITE_WIDTH_B+i] = wdata[i];
	  end
   endtask

   always@(posedge CLKB_i)
     if (CLKEB_i) begin
		// Do an early read, write and late read
		// Then decide what do do with the read data
		read_ramb(ADDRB_net[AWIDTH_B-1:AWIDTH_B - READ_AWIDTH_B], RDATAB_early);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		write_ramb(ADDRB_net[AWIDTH_B-1:AWIDTH_B - WRITE_AWIDTH_B], WDATAB, WEB_i);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		read_ramb(ADDRB_net[AWIDTH_B-1:AWIDTH_B - READ_AWIDTH_B], RDATAB_late);
		   
		// Based on the write mode decide which read data to use
		if (WRITE_MODE_B == "READ_FIRST") begin
		   RDATAB_out = RDATAB_early;
		end
		else if (WRITE_MODE_B == "WRITE_FIRST") begin
		   RDATAB_out = RDATAB_late;
		end
		else /* (WRITE_MODE_B == "NO_CHANGE") */ begin
		   RDATAB_out = WEB_i ? RDATAB_out : RDATAB_early;
		end
	 end
   
   // Optional output register
   generate if (OUTPUT_REG_B) 
	 begin
		always@(posedge CLKB_i)
			RDATAB_reg <= RDATAB_out;

		assign RDATAB = RDATAB_reg;
	 end
   else
	 begin
		assign RDATAB = RDATAB_out;
	 end
   endgenerate

endmodule // EFX_DPRAM_5K

//////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2013-2016 Efinix Inc. All rights reserved.
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
