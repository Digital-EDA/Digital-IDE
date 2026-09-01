/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2016 Efinix Inc. All rights reserved.
//
// Efinix full-adder
//
// This is a simple full-adder
// Both data inputs have programmable invert
//
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////

module EFX_ADD #
(
 parameter I0_POLARITY   = 1'b1,  // 0 invert
 parameter I1_POLARITY   = 1'b1  // 0 invert
)
(
 input 	I0,  // data input
 input 	I1,  // data input
 input 	CI,  // carry input
 output	O,  // data output
 output CO  // carry output
);
   // Create nets for optional data inputs
   // allows us to assign to them without getting warning
   // for coercing input to inout
   wire     I0_net;
   wire     I1_net;
   wire     CI_net;

   // Default values for optional data signals
   // Can be inverted by polarity parameter
   assign (weak0, weak1) I0_net = I0_POLARITY ? 1'b0 : 1'b1;
   assign (weak0, weak1) I1_net = I1_POLARITY ? 1'b0 : 1'b1;
   assign (weak0, weak1) CI_net = 1'b0;

   // Now assign the input
   assign I0_net = I0;
   assign I1_net = I1;
   assign CI_net = CI;

   // Internal signals
   wire i0_int;
   wire i1_int;

   // Check datas polarity
   assign i0_int = I0_POLARITY ? I0_net : ~I0_net;
   assign i1_int = I1_POLARITY ? I1_net : ~I1_net;
   
   assign {CO, O} = i0_int + i1_int + CI_net;
   
endmodule // EFX_ADD

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
