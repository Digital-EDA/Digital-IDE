/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Efinix Inc. All rights reserved.
//
// Efinix SRL8:
//
// This is an 8-bit shift-register with clock-enable
// The bit output can be controlled by the address input
// The clock and clock-enable inputs are invertable
//
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////

module EFX_SRL8(D, A, CLK, CE, Q, Q7);
   parameter CLK_POLARITY = 1'b1; // 0 falling edge, 1 rising edge
   parameter CE_POLARITY  = 1'b1; // 0 negative, 1 positive
   parameter INIT = 8'h00;

   input [2:0] A;
   input 	   D, CLK, CE;
   output 	   Q;
   output 	   Q7;

   // Create nets for unused inputs
   wire [2:0] A_net;
   wire 	  CE_net;

   // Default values for unused inptus
   assign (weak0, weak1) A_net = 3'b1;
   assign (weak0, weak1) CE_net = CE_POLARITY ? 1'b1 : 1'b0;

   // Now assign the input
   assign A_net = A;
   assign CE_net = CE;
   
   // Internal signals
   wire ce_int;
   wire clk_int;
     
   // Check parameters and set internal signals appropriately
   assign clk_int = CLK_POLARITY ? CLK : ~CLK;
   assign ce_int = CE_POLARITY ? CE_net : ~CE_net;

   // Shift register data
   reg [7:0] data;

   initial begin
	  data = INIT;
   end
   
   always @(posedge clk_int) begin
	  if (ce_int) begin
		 data <= {data[6:0], D};
	  end
	  else begin
		data <= data;
	  end
   end

   // Q points the the selected data bit
   assign Q  = ~data[~A_net];
   // Q7 points to the last data bit
   assign Q7 = data[7];

endmodule

//////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2020 Efinix Inc. All rights reserved.
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
