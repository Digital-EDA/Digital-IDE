/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2018 Efinix Inc. All rights reserved.
//
// Efinix Block RAM (BRAM):
//
// This is a 10K simple dual-port RAM
// (one read & one write port)
//
// The read and write ports can
// Be in any of the following WIDTHS
//   16 --> 512x16
//   8  --> 1024x8
//   4  --> 2048x4
//   2  --> 4096x2
//   1  --> 8192x1
//   20 --> 512x20
//   10 --> 1024x10
//   5  --> 2048x5
//
// Writing can be done in one of three WRITE MODEs
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

module EFX_RAM10
(
   WCLK, WE, WCLKE, WADDREN, WDATA, WADDR,
   RCLK, RE, RST, RADDREN, RDATA, RADDR
);
   

   parameter [0:0] WCLK_POLARITY  = 1'b1;
   parameter [0:0] WCLKE_POLARITY = 1'b1;
   parameter [0:0] WADDREN_POLARITY = 1'b1;
   parameter [1:0] WE_POLARITY    = 2'b11;
   parameter [0:0] RCLK_POLARITY  = 1'b1;
   parameter [0:0] RE_POLARITY    = 1'b1;
   parameter [0:0] RST_POLARITY    = 1'b1;
   parameter [0:0] RADDREN_POLARITY = 1'b1;
   // Need to add all the data & address input  polarity inversion parameters
   parameter READ_WIDTH = 16;
   parameter WRITE_WIDTH = 16;
   parameter [0:0] OUTPUT_REG = 1'b0;
   parameter WRITE_MODE = "READ_FIRST";
   parameter RESET_RAM = "ASYNC";
   parameter RESET_OUTREG = "ASYNC";
   
   parameter [255:0] INIT_0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_1 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_2 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_3 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_4 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_5 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_6 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_7 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_8 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_9 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_F = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_10 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_11 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_12 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_13 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_14 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_15 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_16 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_17 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_18 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_19 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_1A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_1B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_1C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_1D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_1E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_1F = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_20 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_21 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_22 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_23 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_24 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_25 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_26 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
   parameter [255:0] INIT_27 = 256'h0000000000000000000000000000000000000000000000000000000000000000;

   localparam READ_AWIDTH = 
			    (READ_WIDTH == 1) ? 13 :
			    (READ_WIDTH == 2) ? 12 :
			    (READ_WIDTH == 4) ? 11 :
			    (READ_WIDTH == 5) ? 11 :
			    (READ_WIDTH == 8) ? 10 :
			    (READ_WIDTH == 10) ? 10 :
			    (READ_WIDTH == 16) ? 9 :
			    (READ_WIDTH == 20) ? 9 :-1;
   
   localparam WRITE_AWIDTH = 
			    (WRITE_WIDTH == 1) ? 13 :
			    (WRITE_WIDTH == 2) ? 12 :
			    (WRITE_WIDTH == 4) ? 11 :
			    (WRITE_WIDTH == 5) ? 11 :
			    (WRITE_WIDTH == 8) ? 10 :
			    (WRITE_WIDTH == 10) ? 10 :
			    (WRITE_WIDTH == 16) ? 9 :
			    (WRITE_WIDTH == 20) ? 9 :-1;

   localparam WRITE_BYTES = (WRITE_WIDTH == 16) || (WRITE_WIDTH == 20);
   
   localparam MEMORY_SIZE = 512*20;
      
   input 			WCLK, WCLKE, WADDREN;
   input 			RCLK, RE, RST, RADDREN;
   input [1:0] 		WE;
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
   wire [1:0] WE_net;
   wire     WCLKE_net;
   wire 	WADDREN_net;
   wire     RE_net;
   wire     RST_net;
   wire 	RADDREN_net;

   // Pull unused address lines low, to mirror EFX synthesis behavior.
   wire [WRITE_AWIDTH-1:0] WADDR_net;
   wire [READ_AWIDTH-1:0] RADDR_net;
   reg [WRITE_AWIDTH-1:0] WADDR_r = 0;
   reg [READ_AWIDTH-1:0] RADDR_r = 0;

   // Default values for optional control signals
   assign (weak0, weak1) WE_net      = ~WE_POLARITY;
   assign (weak0, weak1) WCLKE_net   = WCLKE_POLARITY;
   assign (weak0, weak1) WADDREN_net = WADDREN_POLARITY;
   assign (weak0, weak1) RE_net      = RE_POLARITY;
   assign (weak0, weak1) RST_net     = ~RST_POLARITY;
   assign (weak0, weak1) RADDREN_net = RADDREN_POLARITY;

   assign (weak0, weak1) WADDR_net = {WRITE_AWIDTH{1'b0}};
   assign (weak0, weak1) RADDR_net = {READ_AWIDTH{1'b0}};

   // Now assign the input
   assign WE_net      = WE;
   assign WCLKE_net   = WCLKE;
   assign WADDREN_net = WADDREN;
   assign RE_net      = RE;
   assign RST_net     = RST;
   assign RADDREN_net = RADDREN;
   
   assign WADDR_net = WADDR;
   assign RADDR_net = RADDR;

   function COMPATIBLE_WIDTH;
	  input integer 	w1, w2;
	  COMPATIBLE_WIDTH = ((((w1==1)||(w1==2)||(w1==4)||(w1==8)||(w1==16))&&((w2==1)||(w2==2)||(w2==4)||(w2==8)||(w2==16))) ||
					(((w1==5)||(w1==10)||(w1==20))&&((w2==5)||(w2==10)||(w2==20))));
   endfunction

   reg 		finish_error = 0;
   initial begin
	  // Check for illegal modes, address width will be -1
	  if (READ_AWIDTH == -1) begin
		 $display("ERROR: Illegal READ WIDTH %d", READ_WIDTH);
		 finish_error = 1;
	  end
	  if (WRITE_AWIDTH == -1) begin
		 $display("ERROR: Illegal WRITE WIDTH %d", WRITE_WIDTH);
		 finish_error = 1;
	  end
	  if (~COMPATIBLE_WIDTH(READ_WIDTH,WRITE_WIDTH)) begin
		 $display("ERROR: READ WIDTH %d cannot be used with WRITE WIDTH %d", READ_WIDTH, WRITE_WIDTH);
		 finish_error = 1;
	  end
	  // Check for illegal write modes
	  if (WRITE_MODE != "READ_FIRST" && WRITE_MODE != "WRITE_FIRST" && WRITE_MODE != "READ_UNKNOWN") begin
		 $display("ERROR: Illegal WRITE_MODE %s", WRITE_MODE);
		 finish_error = 1;
	  end
	  if (RESET_RAM != "ASYNC" && RESET_RAM != "SYNC" && RESET_RAM != "NONE") begin
		 $display("ERROR: Illegal RESET_RAM setting %s", RESET_RAM);
		 finish_error = 1;
	  end
	  if (RESET_OUTREG != "ASYNC" && RESET_OUTREG != "NONE") begin
		 $display("ERROR: Illegal RESET_OUTREG setting %s", RESET_OUTREG);
		 finish_error = 1;
	  end
	  if ((WRITE_MODE === "WRITE_FIRST") && (WRITE_WIDTH != READ_WIDTH)) begin
		 $display("ERROR: WRITE_WIDTH %d must match READ_WIDTH %d in WRITE_FIRST WRITE_MODE", WRITE_WIDTH, READ_WIDTH);
		 finish_error = 1;
	  end

	  if (finish_error == 1)
		#1 $finish();

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
		 mem[256*20+i] = INIT_14[i];
		 mem[256*21+i] = INIT_15[i];
		 mem[256*22+i] = INIT_16[i];
		 mem[256*23+i] = INIT_17[i];
		 mem[256*24+i] = INIT_18[i];
		 mem[256*25+i] = INIT_19[i];
		 mem[256*26+i] = INIT_1A[i];
		 mem[256*27+i] = INIT_1B[i];
		 mem[256*28+i] = INIT_1C[i];
		 mem[256*29+i] = INIT_1D[i];
		 mem[256*30+i] = INIT_1E[i];
		 mem[256*31+i] = INIT_1F[i];
		 mem[256*32+i] = INIT_20[i];
		 mem[256*33+i] = INIT_21[i];
		 mem[256*34+i] = INIT_22[i];
		 mem[256*35+i] = INIT_23[i];
		 mem[256*36+i] = INIT_24[i];
		 mem[256*37+i] = INIT_25[i];
		 mem[256*38+i] = INIT_26[i];
		 mem[256*39+i] = INIT_27[i];

      end
   end

   // Wires for the polarity control.
   // Only supporting clocks and enable for now
   wire 			WCLK_i, WCLKE_i, WADDREN_i;
   wire 			RCLK_i, RE_i, RCLKE_i, RST_i, RADDREN_i;
   wire [1:0] 		WE_i;

   assign WCLK_i    = WCLK_POLARITY    ~^ WCLK;
   assign WCLKE_i   = WCLKE_POLARITY   ~^ WCLKE_net;
   assign WE_i      = WE_POLARITY      ~^ WE_net;
   assign WADDREN_i = WADDREN_POLARITY ~^ WADDREN_net;
   assign RCLK_i    = RCLK_POLARITY    ~^ RCLK;
   assign RE_i      = RE_POLARITY      ~^ RE_net;
   assign RST_i     = RST_POLARITY     ~^ RST_net;
   assign RADDREN_i = RADDREN_POLARITY ~^ RADDREN_net;

   // Wires for the configurable reset controls
   wire 			ram_async_rst, ram_sync_rst, outreg_async_rst;
   assign ram_async_rst    = (RESET_RAM == "ASYNC")    ? RST_i : 1'b0;
   assign ram_sync_rst     = (RESET_RAM == "SYNC")     ? RST_i : 1'b0;
   assign outreg_async_rst = (RESET_OUTREG == "ASYNC") ? RST_i : 1'b0;
   
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

   task write_ram_lo;
	  input [WRITE_AWIDTH-1:0] addr;
	  input [WRITE_WIDTH-1:0] wdata;
	  
	  begin
		 for (i=0; i < (WRITE_WIDTH/2); i=i+1)
		   mem[addr*WRITE_WIDTH+i] = wdata[i];
	  end
   endtask   

   task write_ram_hi;
	  input [WRITE_AWIDTH-1:0] addr;
	  input [WRITE_WIDTH-1:0] wdata;
	  
	  begin
		 for (i=(WRITE_WIDTH/2); i < WRITE_WIDTH; i=i+1)
		   mem[addr*WRITE_WIDTH+i] = wdata[i];
	  end
   endtask
   

   always@(posedge WCLK_i) begin
	  if (WCLKE_i) begin
		 // Only update the address latch if not stalled
		 WADDR_r = WADDREN_i ? WADDR_net : WADDR_r;
		 // #0 delay blocking assignments for coordinating cross port read/write
		 #0; // Early read
		 // Write
		 // Decide if we are writing bytes or the whole data width
		 if (WRITE_BYTES) begin
			if (WE_i[0]) begin
			   // Write low byte
			   write_ram_lo(WADDR_r, WDATA);
			end
			if (WE_i[1]) begin
			   // Write high byte
			   write_ram_hi(WADDR_r, WDATA);
			end
		 end
		 else begin
			if (WE_i[0]) begin
			   // Write full width
			   write_ram(WADDR_r, WDATA);
			end
		 end
		 #0; // Late read
	  end
   end

   always@(posedge RCLK_i) begin
	  if (RE_i) begin
		 // Update the address latch if reading & not stalled
		 RADDR_r = RADDREN_i ? RADDR_net : RADDR_r;
		 
		 // early read, write and late read
		 read_ram(RADDR_r, RDATA_early);
		 #0; // Use #0 delay blocking assignments to allow cross port read/write
		 #0; // Use #0 delay blocking assignments to allow cross port read/write
		 read_ram(RADDR_r, RDATA_late);
		 #0;
	  end
   end

   // Decide which data to output
   always@(posedge RCLK_i or posedge ram_async_rst) begin
	  // Check for async reset
	  if (ram_async_rst) begin
		 RDATA_out <= {READ_WIDTH{1'b0}};
	  end
	  else begin
		 // Delay for the read/write/read to happen
		 #0; #0; #0;
		 if (RE_i) begin
			// Check for sync reset
			if (ram_sync_rst) begin
			   RDATA_out <= {READ_WIDTH{1'b0}};
		    end 
			else begin
			   // Based on the write mode decide which read data to use
			   if (WRITE_MODE == "READ_FIRST") begin
				  RDATA_out <= RDATA_early;
			   end
			   else if (WRITE_MODE == "WRITE_FIRST") begin
				  RDATA_out <= RDATA_late;
			   end
			   else /* (WRITE_MODE == "READ_UNKNOWN") */ begin
				  RDATA_out <= (RDATA_early === RDATA_late) ? RDATA_early : {READ_WIDTH{1'bx}};
		       end
			end
		 end
	  end
   end
   
   // Optional output register
   generate if (OUTPUT_REG) 
	 begin
		always@(posedge RCLK_i or posedge outreg_async_rst) begin
		   if (outreg_async_rst) RDATA_reg <= {READ_WIDTH{1'b0}};
		   else if (RE_i) RDATA_reg <= RDATA_out;
		end

		assign RDATA = RDATA_reg;
	 end
   else
	 begin
		assign RDATA = RDATA_out;
	 end // else: !if(OUTPUT_REG)
   endgenerate
	       
endmodule 

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
