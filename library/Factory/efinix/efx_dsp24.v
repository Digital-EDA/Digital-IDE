/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Efinix Inc. All rights reserved.
//
// Efinix DSP24:
//
// This is a powerful DSP block that can perform multiplication
// plus addition/subtraction/accumulation. The final output can 
// be dynamically shifted 0-15 bits right.
//
// There are 6 optional pipe-line registers at key points. 
//
// The DSP can be signed or unsinged.
// The DSP implements an 8x8 multiplier followed by an AddSub block
//
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////

module EFX_DSP24 (
   A, B, C, CASCIN, OP, SHIFT_ENA, CLK, CE, RST, O, CASCOUT
);
   
   parameter [0:0] A_REG     = 0;
   parameter [0:0] B_REG     = 0;
   parameter [0:0] C_REG     = 0;
   parameter [0:0] P_REG     = 0;
   parameter [0:0] OP_REG    = 0;
   parameter [0:0] W_REG     = 0;
   parameter [0:0] O_REG     = 0;
   parameter [0:0] SHIFTER   = 0;
   parameter [0:0] RST_SYNC  = 0;
   parameter [0:0] SIGNED    = 1;
   parameter P_EXT           = "ALIGN_RIGHT";
   parameter C_EXT           = "ALIGN_RIGHT";
   parameter M_SEL           = "P";
   parameter N_SEL           = "C";
   parameter W_SEL           = "X";
   parameter CASCOUT_SEL     = "W";
   parameter [0:0] CLK_POLARITY       = 1;
   parameter [0:0] CE_POLARITY        = 1;
   parameter [0:0] RST_POLARITY       = 1;
   parameter [0:0] SHIFT_ENA_POLARITY = 1;
   parameter [0:0] A_REG_USE_CE   = 1;
   parameter [0:0] B_REG_USE_CE   = 1;
   parameter [0:0] C_REG_USE_CE   = 1;
   parameter [0:0] OP_REG_USE_CE  = 1;
   parameter [0:0] P_REG_USE_CE   = 1;
   parameter [0:0] W_REG_USE_CE   = 1;
   parameter [0:0] O_REG_USE_CE   = 1;
   parameter [0:0] A_REG_USE_RST  = 1;
   parameter [0:0] B_REG_USE_RST  = 1;
   parameter [0:0] C_REG_USE_RST  = 1;
   parameter [0:0] OP_REG_USE_RST = 1;
   parameter [0:0] P_REG_USE_RST  = 1;
   parameter [0:0] W_REG_USE_RST  = 1;
   parameter [0:0] O_REG_USE_RST  = 1;
   
   input [7:0]  A;
   input [7:0]  B;
   input [7:0]  C;
   input [23:0]  CASCIN;
   input [1:0] 	 OP;
   input 		 SHIFT_ENA, CLK, CE, RST;
   output [23:0] O;
   output [23:0] CASCOUT;
   
   reg 		finish_error = 0;
   initial begin
	  // Check for illegal extension
	  case(P_EXT)
		"ALIGN_LEFT","ALIGN_RIGHT","TEST" : ;
		default: begin
		 $display("ERROR: Illegal P_EXT %s", P_EXT);
		 finish_error = 1;
		end
	  endcase
	  case(C_EXT)
		"ALIGN_LEFT","ALIGN_RIGHT","TEST" : ;
		default: begin
		 $display("ERROR: Illegal C_EXT %s", C_EXT);
		 finish_error = 1;
		end
	  endcase
	  // Check for illegal mux selection
	  case(M_SEL)
		"P","C" : ;
		default: begin
		 $display("ERROR: Illegal M_SEL %s", M_SEL);
		 finish_error = 1;
		end
	  endcase
	  case(N_SEL)
		"CONST0", "CONST1", "C", "P", "CASCIN", "W","O" : ;
		default: begin
		 $display("ERROR: Illegal N_SEL %s", N_SEL);
		 finish_error = 1;
		end
	  endcase
	  case(W_SEL)
		"P","X" : ;
		default: begin
		 $display("ERROR: Illegal W_SEL %s", W_SEL);
		 finish_error = 1;
		end
	  endcase
	  case(CASCOUT_SEL)
		"C", "P","W", "ABC" : ;
		default: begin
		 $display("ERROR: Illegal CASCOUT_SEL %s", CASCOUT_SEL);
		 finish_error = 1;
		end
	  endcase

	  if (finish_error == 1)
		#1 $finish();
   end

   wire [7:0] 	 A_p, B_p, C_p;
   wire [1:0] 	 OP_p;
   wire [15:0] 	 P, P_p;
   wire [23:0] 	 C_a, P_a, M, N, X, W, W_p, S, O_p;
   wire [3:0] 	 shift;

   // Create nets for optional control inputs
   // allows us to assign to them without getting warning
   // for coercing input to inout
   wire 		 CE_net;
   wire 		 RST_net;
   wire 		 SHIFT_ENA_net;
   
   // Default values for optional control signals
   assign (weak0, weak1) CE_net = CE_POLARITY;
   assign (weak0, weak1) RST_net = ~RST_POLARITY;
   assign (weak0, weak1) SHIFT_ENA_net = ~SHIFT_ENA_POLARITY;

   // Now assign the input
   assign CE_net = CE;
   assign RST_net = RST;
   assign SHIFT_ENA_net = SHIFT_ENA;

   // Wires for polarity control
   wire 		 CLK_i, CE_i, RST_i, SHIFT_ENA_i;
   
   assign CLK_i       = CLK_POLARITY       ~^ CLK;
   assign CE_i        = CE_POLARITY        ~^ CE_net;
   assign RST_i       = RST_POLARITY       ~^ RST_net;
   assign SHIFT_ENA_i = SHIFT_ENA_POLARITY ~^ SHIFT_ENA_net;

   // Individual pipeline stages can ignore the CE & RST pins
   wire 		 CE_a, CE_b, CE_c, CE_op, CE_p, CE_w, CE_o;
   wire 		 RST_a, RST_b, RST_c, RST_op, RST_p, RST_w, RST_o;

   assign CE_a   = CE_i | ~A_REG_USE_CE;
   assign CE_b   = CE_i | ~B_REG_USE_CE;
   assign CE_c   = CE_i | ~C_REG_USE_CE;
   assign CE_op  = CE_i | ~OP_REG_USE_CE;
   assign CE_p   = CE_i | ~P_REG_USE_CE;
   assign CE_w   = CE_i | ~W_REG_USE_CE;
   assign CE_o   = CE_i | ~O_REG_USE_CE;
   assign RST_a  = RST_i & A_REG_USE_RST;
   assign RST_b  = RST_i & B_REG_USE_RST;
   assign RST_c  = RST_i & C_REG_USE_RST;
   assign RST_op = RST_i & OP_REG_USE_RST;
   assign RST_p  = RST_i & P_REG_USE_RST;
   assign RST_w  = RST_i & W_REG_USE_RST;
   assign RST_o  = RST_i & O_REG_USE_RST;

   // Mult Operator
   EFX_DSP24_pipe #(.W(8), .REG(A_REG), .SYNC(RST_SYNC)) A_pipe(.I(A), .CLK(CLK_i), .CE(CE_a), .RST(RST_a), .O(A_p));
   EFX_DSP24_pipe #(.W(8), .REG(B_REG), .SYNC(RST_SYNC)) B_pipe(.I(B), .CLK(CLK_i), .CE(CE_b), .RST(RST_b), .O(B_p));
   EFX_DSP24_mult #(.A_W(8), .B_W(8), .O_W(16), .SIGNED(SIGNED)) mult(.A(A_p), .B(B_p), .O(P));
   EFX_DSP24_pipe #(.W(16), .REG(P_REG), .SYNC(RST_SYNC)) P_pipe(.I(P), .CLK(CLK_i), .CE(CE_p), .RST(RST_p), .O(P_p));

   // Mult Extender
   EFX_DSP24_extender #(.W_I(16),.W_O(24),.SIGNED(SIGNED),.EXT(P_EXT)) ext_P(.I(P_p),  .O(P_a));

   // C input and extender
   EFX_DSP24_pipe #(.W(8), .REG(C_REG), .SYNC(RST_SYNC)) C_pipe(.I(C), .CLK(CLK_i), .CE(CE_c), .RST(RST_c), .O(C_p));
   EFX_DSP24_extender #(.W_I(8), .W_O(24),.SIGNED(SIGNED),.EXT(C_EXT)) ext_C(.I(C_p), .O(C_a));

   // Choose Add/Sub Operator Inputs
   assign M = (M_SEL == "P") ? P_a : 
			  (M_SEL == "C") ? C_a : -1;
   

   assign N = (N_SEL == "CONST0") ? 24'd0 :
			  (N_SEL == "CONST1") ? 24'd1 :
			  (N_SEL == "C") ? C_a :
			  (N_SEL == "P") ? P_a :
			  (N_SEL == "CASCIN") ? CASCIN :
			  (N_SEL == "W") ? W_p :
			  (N_SEL == "O") ? O_p : -1;

   // Add/Sub Operator
   EFX_DSP24_pipe #(.W(2), .REG(OP_REG), .SYNC(RST_SYNC)) OP_pipe(.I(OP), .CLK(CLK_i), .CE(CE_op), .RST(RST_op), .O(OP_p));
   EFX_DSP24_add_sub #(.W(24), .SIGNED(SIGNED)) add_sub(.A(M), .B(N), .OP(OP_p), .O(X), .OVFL());
   EFX_DSP24_pipe #(.W(24), .REG(W_REG), .SYNC(RST_SYNC)) W_pipe(.I(X), .CLK(CLK_i), .CE(CE_w), .RST(RST_w), .O(W_p));

   // Choose the shifter input W register or aligned multiplier
   assign W = (W_SEL == "P") ? P_a : W_p;
   EFX_DSP24_pipe #(.W(4), .REG(1)) shift_val(.I(C[3:0]), .CLK(CLK_i), .CE(SHIFT_ENA_i), .RST(RST_i), .O(shift));
   EFX_DSP24_shifter #(.W(24), .SIGNED(SIGNED)) shifter(.I(W),  .S(shift), .O(S));

   // Output pipeline
   EFX_DSP24_pipe #(.W(24), .REG(O_REG|(W_REG && W_SEL=="P")), .SYNC(RST_SYNC)) O_pipe(.I(S), .CLK(CLK_i), .CE(CE_o), .RST(RST_o), .O(O_p));
   assign O = O_p;

   // Choose Cascade Output
   assign CASCOUT = (CASCOUT_SEL == "C") ? C_a :
					(CASCOUT_SEL == "P") ? P_a :
					(CASCOUT_SEL == "W") ? W_p : 
					(CASCOUT_SEL == "ABC") ? {A_p,B_p,C_p} : -1;
endmodule

module EFX_DSP24_pipe (I, CLK, CE, RST, O);
   parameter W    = 48;
   parameter REG  = 0;
   parameter SYNC = 0;

   input [W-1:0] I;
   input 		 CLK, CE, RST;
   output [W-1:0] O;

   wire 		  s_RST, a_RST;
   assign s_RST = SYNC ? RST : 0;
   assign a_RST = SYNC ? 0 : RST;
   
   reg [W-1:0] O_r = 0;

   always @(posedge CLK or posedge a_RST) begin
	  if (a_RST || s_RST) begin
		 O_r <= 0;
	  end
	  else begin
		if (CE) O_r <= I;
	  end
   end

   assign O = REG ? O_r : I;
   
endmodule

module EFX_DSP24_mult (A, B, O);
   parameter A_W = 8;
   parameter B_W = 8;
   parameter O_W = 16;
   parameter SIGNED = 1;

   input [A_W-1:0] A;
   input [B_W-1:0] B;
   output [O_W-1:0] O;

   reg [O_W-1:0] O_r;
   
   always @(*) begin
	  if (SIGNED) O_r = $signed(A) * $signed(B);
	  else O_r = A * B;
   end

   assign O = O_r;
   
endmodule

module EFX_DSP24_extender (I, O);
   parameter W_I = 48;
   parameter W_O = 48;
   parameter SIGNED = 1;
   parameter EXT = "ALIGN_RIGHT";

   input [W_I-1:0] I;
   output [W_O-1:0] O;

   reg [W_O-1:0] O_r;
	  
   always @(*) begin
	  if (EXT == "ALIGN_RIGHT")
		if (SIGNED) O_r = $signed(I);
	  	else O_r = {{W_O-W_I{1'b0}}, I};
	  else O_r = {I, {W_O-W_I{1'b0}}};
   end

   assign O = O_r;
   
endmodule

module EFX_DSP24_shifter (I, S, O);
   parameter W = 48;
   parameter WS = 4;
   parameter SIGNED = 1;

   input [W-1:0] I;
   input [WS-1:0] 	 S;
   output [W-1:0] O;

   reg [W-1:0] O_r;
	  
   always @(*) begin
	  if (SIGNED) O_r = $signed(I) >>> S;
	  else O_r = I >>> S;
   end

   assign O = O_r;
   
endmodule

module EFX_DSP24_add_sub (A, B, OP, O, OVFL);
   parameter W = 24;
   parameter SIGNED = 1;

   input [W-1:0] A;
   input [W-1:0] B;
   input [1:0] 	 OP;
   output [W-1:0] O;
   output 		  OVFL;

   localparam signed [W+1:0] MAX = (1<<(W-1))-1;
   localparam signed [W+1:0] MIN = -(1<<(W-1));
   reg signed [W+1:0] 	  O_r;
   reg signed [W:0] 	  A_r, B_r;
   
   always @(*) begin
	  // Add/sub is done in signed arith and converted back to unsigned
	  if (SIGNED) begin
		 A_r = $signed(A);
		 B_r = $signed(B);
	  end
	  else begin
		 A_r = $unsigned(A);
		 B_r = $unsigned(B);
	  end
	  
	  case(OP)
		2'b00: O_r = A_r+B_r;
		2'b01: O_r = A_r-B_r;
		2'b10: O_r = -A_r+B_r;
		2'b11: O_r = -A_r-B_r-1;
	  endcase
   end

   assign O = O_r[W-1:0];
   // Only overflow if data is lost. 
   assign OVFL = (SIGNED || OP != 2'b00) ? ((O_r > MAX) || (O_r < MIN)) : O_r[W];
      
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
