/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Efinix Inc. All rights reserved.
//
// Efinix 4-input combinational logic cell:
//
// This is a WYSIWYG cell representing the full functionality
// of the Titanium logic cell.
//
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////

module EFX_COMB4 #
(
 parameter LUTMASK  = 16'h0000, // Content of Lookup table RAM
 parameter MODE = "LOGIC"       // LOGIC or ARITH
)
(
 input 	I0, // data input
 input 	I1, // data input
 input 	I2, // data input
 input 	I3, // data input
 input 	CI, // carry input
 output O,  // data output
 output CO, // carry out
 output FCO, // flexibl carry out
 output P   // Propagate output
);

   reg 		finish_error = 0;
   initial begin
	  if (MODE != "LOGIC" && MODE != "ARITH") begin
		 $display("ERROR: Illegal MODE setting %s", MODE);
		 finish_error = 1;
	  end

	  if (finish_error == 1)
		#1 $finish();
   end
   
   // Create nets for optional control inputs
   // allows us to assign to them without getting warning
   // for coercing input to inout
   wire     I0_net;
   wire     I1_net;
   wire     I2_net;
   wire     I3_net;
   wire 	CI_net;
   
   // Default values for unused inputs
   assign (weak0, weak1) I0_net = 1'b0;
   assign (weak0, weak1) I1_net = 1'b0;
   assign (weak0, weak1) I2_net = 1'b0;
   assign (weak0, weak1) I3_net = 1'b0;
   assign (weak0, weak1) CI_net = 1'b0;

   // Now assign the input
   assign I0_net = I0;
   assign I1_net = I1;
   assign I2_net = (MODE === "LOGIC") ? I2 : CI;
   assign I3_net = (MODE === "LOGIC") ? I3 : 1'b0;
   assign CI_net = CI;

   // internal variables
   wire [15:0] lutrom;
   reg 	       lut = 1'b0;
   reg 		   prop = 1'b0;
   reg 		   gen = 1'b0;
   
   // assign LUT ROM
   assign lutrom = LUTMASK;
   
   always @(I0_net or I1_net or I2_net or I3_net) begin
      lut = get_lut_value(3, {I3_net, I2_net, I1_net, I0_net});
      prop = get_lut_value(1, {1'b1, 1'b0, I1_net, I0_net});
      gen = get_lut_value(1, {1'b1, 1'b1, I1_net, I0_net});
   end

   assign O = lut;
   assign P = prop;
   wire carry;
   assign carry = (MODE === "ARITH") ? (prop ? CI_net : gen) : 1'bx;
   
   assign CO = ~carry;
   assign FCO = carry;

   function automatic [0:0] get_lut_value;
	  input integer index;
	  input [3:0] I;
	  reg 		  hi_value, lo_value;
	  
	  // Check for an X value
	  if (I[index] === 1'bx) begin
		 // Need to test if both sub-trees return the same value
		 case (index)
		   3: begin
			  hi_value = get_lut_value(2, {1'b1, I[2:0]});
			  lo_value = get_lut_value(2, {1'b0, I[2:0]});
		   end
		   2: begin
			  hi_value = get_lut_value(1, {I[3], 1'b1, I[1:0]});
			  lo_value = get_lut_value(1, {I[3], 1'b0, I[1:0]});
		   end
		   1: begin
			  hi_value = get_lut_value(0, {I[3:2], 1'b1, I[0]});
			  lo_value = get_lut_value(0, {I[3:2], 1'b0, I[0]});
		   end
		   0: begin
			  hi_value = lutrom[{I[3:1], 1'b1}];
			  lo_value = lutrom[{I[3:1], 1'b0}];
		   end
		 endcase // case (index)

		 //  If the same value return it, otherwise X
		 get_lut_value = (hi_value === lo_value) ? hi_value : 1'bx;
		 
	  end
	  else
		// If last index return the value
		if (index == 0)
		  get_lut_value = lutrom[I];
		else
		  get_lut_value = get_lut_value(index-1, I);
		  
   endfunction //
   
   
endmodule // EFX_LUT4

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
