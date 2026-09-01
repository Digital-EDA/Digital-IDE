/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2016 Efinix Inc. All rights reserved.
//
// Efinix Multipler:
//
// This is a simple signed multiplier
// with optional registers on all data ports.
//
// The multiplier can be in the widths:
//   16 --> 16x16
//   18 --> 18x18
//
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////

// Set the next line to 1 to enable checks that
// the multiplier widths are legal for our architectures
`define STRICT_MULT_CHECK 1

module EFX_MULT
(
   A, B, O, CLK, CEA, RSTA, CEB, RSTB, CEO, RSTO
);
   
   parameter WIDTH        = 18;
   parameter A_REG        = 1'b0;
   parameter B_REG        = 1'b0;
   parameter O_REG        = 1'b0;
   parameter CLK_POLARITY = 1'b1; // 0 falling edge, 1 rising edge
   parameter CEA_POLARITY = 1'b1; // 0 negative, 1 positive
   parameter RSTA_POLARITY = 1'b1; // 0 negative, 1 positive
   parameter RSTA_SYNC     = 1'b0; // 0 async, 1 sync
   parameter RSTA_VALUE    = 1'b0; // 0 reset, 1 set
   parameter CEB_POLARITY = 1'b1; // 0 negative, 1 positive
   parameter RSTB_POLARITY = 1'b1; // 0 negative, 1 positive
   parameter RSTB_SYNC     = 1'b0; // 0 async, 1 sync
   parameter RSTB_VALUE    = 1'b0; // 0 reset, 1 set
   parameter CEO_POLARITY = 1'b1; // 0 negative, 1 positive
   parameter RSTO_POLARITY = 1'b1; // 0 negative, 1 positive
   parameter RSTO_SYNC     = 1'b0; // 0 async, 1 sync
   parameter RSTO_VALUE    = 1'b0; // 0 reset, 1 set
   parameter SR_SYNC_PRIORITY = 1'b1; // 0 CE, 1 SR
   
   initial begin
	  // Check for illegal width
	  if (`STRICT_MULT_CHECK) begin
		 if (WIDTH != 16 && WIDTH != 18 ) begin
			$display("ERROR:Illegal WIDTH %d", WIDTH);
			$finish();
		 end
	  end
   end

   localparam IN_DATA_WIDTH = WIDTH;
   localparam OUT_DATA_WIDTH = WIDTH*2;

   input  signed [IN_DATA_WIDTH-1:0] A, B;
   output signed [OUT_DATA_WIDTH-1:0] O;
   input CLK, CEA, RSTA, CEB, RSTB, CEO, RSTO;

   wire  signed [IN_DATA_WIDTH-1:0] A_ff, B_ff, A_int, B_int;
   wire  signed [OUT_DATA_WIDTH-1:0] O_ff, O_int;

   // Optional input registers
   genvar i;
   generate for(i=0;i<IN_DATA_WIDTH;i=i+1) begin : inreg
	  INIT_MULT_FF #(.CLK_POLARITY(CLK_POLARITY), .CE_POLARITY(CEA_POLARITY), .SR_POLARITY(RSTA_POLARITY), .SR_VALUE(RSTA_VALUE), .SR_SYNC(RSTA_SYNC), .SR_SYNC_PRIORITY(SR_SYNC_PRIORITY)) 
	      ffa (.D(A[i]), .CLK(CLK), .CE(CEA), .SR(RSTA), .Q(A_ff[i]));
	  
	  INIT_MULT_FF #(.CLK_POLARITY(CLK_POLARITY), .CE_POLARITY(CEB_POLARITY), .SR_POLARITY(RSTB_POLARITY), .SR_VALUE(RSTB_VALUE), .SR_SYNC(RSTB_SYNC), .SR_SYNC_PRIORITY(SR_SYNC_PRIORITY)) 
	      ffb(.D(B[i]), .CLK(CLK), .CE(CEB), .SR(RSTB), .Q(B_ff[i]));
   end
   endgenerate

   assign A_int = (A_REG == 1) ? A_ff : A;
   assign B_int = (B_REG == 1) ? B_ff : B;
   
   assign O_int = A_int * B_int;

   // Optional output registers
   genvar j;
   generate for(j=0;j<OUT_DATA_WIDTH;j=j+1) begin : outreg
	  INIT_MULT_FF #(.CLK_POLARITY(CLK_POLARITY), .CE_POLARITY(CEO_POLARITY), .SR_POLARITY(RSTO_POLARITY), .SR_VALUE(RSTO_VALUE), .SR_SYNC(RSTO_SYNC), .SR_SYNC_PRIORITY(SR_SYNC_PRIORITY)) 
	      ffo(.D(O_int[j]), .CLK(CLK), .CE(CEO), .SR(RSTO), .Q(O_ff[j]));
   end
   endgenerate

   assign O = (O_REG == 1) ? O_ff : O_int;

endmodule // EFX_MULT

module INIT_MULT_FF # 
(
 parameter CLK_POLARITY = 1'b1, // 0 falling edge, 1 rising edge
 parameter CE_POLARITY  = 1'b1, // 0 negative, 1 positive
 parameter SR_POLARITY  = 1'b1, // 0 negative, 1 positive
 parameter SR_SYNC      = 1'b0, // 0 async, 1 sync
 parameter SR_VALUE     = 1'b0, // 0 reset, 1 set
 parameter SR_SYNC_PRIORITY = 1'b1, // 0 CE, 1 SR
 parameter D_POLARITY   = 1'b1  // 0 invert
)
(
 input 	    D, // data input
 input 	    CE, // clock-enable
 input 	    CLK, // clock
 input 	    SR, // asyc/sync set/reset
 output reg Q = 1'b0    // data output
);
   // Create nets for optional control inputs
   // allows us to assign to them without getting warning
   // for coercing input to inout
   wire     CE_net;
   wire     SR_net;

   // Default values for optional control signals
   assign (weak0, weak1) CE_net = CE_POLARITY ? 1'b1 : 1'b0;
   assign (weak0, weak1) SR_net = SR_POLARITY ? 1'b0 : 1'b1;

   // Now assign the input
   assign CE_net = CE;
   assign SR_net = SR;
   
   // Internal signals
   wire d_int;
   wire ce_int;
   wire clk_int;
   wire sr_int;
   wire sync_sr_int;
   wire async_sr_int;
   wire priority_ce_int;
     
   // Check parameters and set internal signals appropriately
   
   // Check clock polarity
   assign clk_int = CLK_POLARITY ? CLK : ~CLK;
   
   // Check clock-enable polarity
   assign ce_int = CE_POLARITY ? CE_net : ~CE_net;

   // Check set/reset polarity
   assign sr_int = SR_POLARITY ? SR_net : ~SR_net;

   // Check datas polarity
   assign d_int = D_POLARITY ? D : ~D;

   // Decide if set/reset is sync or async
   assign sync_sr_int = SR_SYNC ? sr_int : 1'b0;
   assign async_sr_int = SR_SYNC ? 1'b0 : sr_int;

   // Decide if CE or sync SR is a priority
   assign priority_ce_int = SR_SYNC_PRIORITY ? 1'b1 : ce_int;

   // Actual FF guts, everything is positive logic
   always @(posedge async_sr_int or posedge clk_int)
     // Only one of async/sync sr will be valid
     if (async_sr_int)
       Q <= SR_VALUE;
     else if (priority_ce_int)
       if (sync_sr_int)
		 Q <= SR_VALUE;
	   else if (ce_int)
		 Q <= d_int;

endmodule // INIT_MULT_FF

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
