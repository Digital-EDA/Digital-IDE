/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Efinix Inc. All rights reserved.
//
// Efinix DSP48:
//
// This is a powerful DSP block that can perform multiplication
// plus addition/subtraction/accumulation. The final output can 
// be dynamically shifted 0-15 bits right.
//
// There are 6 optional pipe-line registers at key points. 
//
// The DSP can be signed or unsinged. 
// The DSP can be in the following MODES:
//   NORMAL   --> 19x18
//   DUAL     --> 11x10 & 8x8
//   QUAD     --> 7x6 & (3) 4x4
//   BFLOAT    --> A,B,C BFLOAT16, CASCIN, CASCOUT, O FP32
//
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////

module EFX_DSP48 (
   A, B, C, CASCIN, OP, SHIFT_ENA, CLK, CE, RST, O, CASCOUT, OVFL
);
   
   parameter MODE            = "NORMAL";
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
   parameter ROUNDING        = "RNE";
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
   
   input [18:0]  A;
   input [17:0]  B;
   input [17:0]  C;
   input [47:0]  CASCIN;
   input [1:0] 	 OP;
   input 		 SHIFT_ENA, CLK, CE, RST;
   output [47:0] O;
   output [47:0] CASCOUT;
   output 		 OVFL;
   
   reg 		finish_error = 0;
   initial begin
	  // Check for illegal modes
	  case(MODE)
		"NORMAL","DUAL","QUAD","BFLOAT" : ;
		default: begin
		 $display("ERROR: Illegal MODE %s", MODE);
		 finish_error = 1;
		end
	  endcase
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
		"P","C","ABC" : ;
		default: begin
		 $display("ERROR: Illegal M_SEL %s", M_SEL);
		 finish_error = 1;
		end
	  endcase
	  case(N_SEL)
		"CONST0", "CONST1", "C", "P", "CASCIN", "CASCIN_ASR18", "CASCIN_LSR18", "W","O" : ;
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
	  case(ROUNDING)
		"RTZ", "RDOWN","RUP", "RTI", "RTO", "RNE" : ;
		default: begin
		 $display("ERROR: Illegal ROUNDING %s", ROUNDING);
		 finish_error = 1;
		end
	  endcase

	  if (finish_error == 1)
		#1 $finish();
   end
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
   wire 		 CLK_w, CE_w, RST_w, SHIFT_ENA_w;
   
   assign CLK_w       = CLK_POLARITY       ~^ CLK;
   assign CE_w        = CE_POLARITY        ~^ CE_net;
   assign RST_w       = RST_POLARITY       ~^ RST_net;
   assign SHIFT_ENA_w = SHIFT_ENA_POLARITY ~^ SHIFT_ENA_net;

   // Choose integer or floating point
   generate
	  if (MODE == "BFLOAT") begin
		 EFX_DSP48_float bf_DSP48 (.A(A),.B(B),.C(C),.CASCIN(CASCIN),.OP(OP),.SHIFT_ENA(SHIFT_ENA_w),.CLK(CLK_w),.CE(CE_w),.RST(RST_w),.O(O),.CASCOUT(CASCOUT),.OVFL(OVFL));
		 defparam bf_DSP48.MODE        = MODE;
		 defparam bf_DSP48.A_REG       = A_REG;
		 defparam bf_DSP48.B_REG       = B_REG;
		 defparam bf_DSP48.C_REG       = C_REG;
		 defparam bf_DSP48.P_REG       = P_REG;
		 defparam bf_DSP48.OP_REG      = OP_REG;
		 defparam bf_DSP48.W_REG       = W_REG;
		 defparam bf_DSP48.O_REG       = O_REG;
		 defparam bf_DSP48.RST_SYNC    = RST_SYNC;
		 defparam bf_DSP48.SIGNED      = SIGNED;
		 defparam bf_DSP48.P_EXT       = P_EXT;
		 defparam bf_DSP48.C_EXT       = C_EXT;
		 defparam bf_DSP48.M_SEL       = M_SEL;
		 defparam bf_DSP48.N_SEL       = N_SEL;
		 defparam bf_DSP48.W_SEL       = W_SEL;
		 defparam bf_DSP48.CASCOUT_SEL = CASCOUT_SEL;
		 defparam bf_DSP48.ROUNDING    = ROUNDING;
		 defparam bf_DSP48.A_REG_USE_CE   = A_REG_USE_CE;
		 defparam bf_DSP48.B_REG_USE_CE   = B_REG_USE_CE;
		 defparam bf_DSP48.C_REG_USE_CE   = C_REG_USE_CE;
		 defparam bf_DSP48.OP_REG_USE_CE  = OP_REG_USE_CE;
		 defparam bf_DSP48.P_REG_USE_CE   = P_REG_USE_CE;
		 defparam bf_DSP48.W_REG_USE_CE   = W_REG_USE_CE;
		 defparam bf_DSP48.O_REG_USE_CE   = O_REG_USE_CE;
		 defparam bf_DSP48.A_REG_USE_RST  = A_REG_USE_RST;
		 defparam bf_DSP48.B_REG_USE_RST  = B_REG_USE_RST;
		 defparam bf_DSP48.C_REG_USE_RST  = C_REG_USE_RST;
		 defparam bf_DSP48.OP_REG_USE_RST = OP_REG_USE_RST;
		 defparam bf_DSP48.P_REG_USE_RST  = P_REG_USE_RST;
		 defparam bf_DSP48.W_REG_USE_RST  = W_REG_USE_RST;
		 defparam bf_DSP48.O_REG_USE_RST  = O_REG_USE_RST;
	  end
	  else begin
		 EFX_DSP48_int i_DSP48 (.A(A),.B(B),.C(C),.CASCIN(CASCIN),.OP(OP),.SHIFT_ENA(SHIFT_ENA_w),.CLK(CLK_w),.CE(CE_w),.RST(RST_w),.O(O),.CASCOUT(CASCOUT),.OVFL(OVFL));
		 defparam i_DSP48.MODE        = MODE;
		 defparam i_DSP48.A_REG       = A_REG;
		 defparam i_DSP48.B_REG       = B_REG;
		 defparam i_DSP48.C_REG       = C_REG;
		 defparam i_DSP48.P_REG       = P_REG;
		 defparam i_DSP48.OP_REG      = OP_REG;
		 defparam i_DSP48.W_REG       = W_REG;
		 defparam i_DSP48.O_REG       = O_REG;
		 defparam i_DSP48.RST_SYNC    = RST_SYNC;
		 defparam i_DSP48.SIGNED      = SIGNED;
		 defparam i_DSP48.P_EXT       = P_EXT;
		 defparam i_DSP48.C_EXT       = C_EXT;
		 defparam i_DSP48.M_SEL       = M_SEL;
		 defparam i_DSP48.N_SEL       = N_SEL;
		 defparam i_DSP48.W_SEL       = W_SEL;
		 defparam i_DSP48.CASCOUT_SEL = CASCOUT_SEL;
		 defparam i_DSP48.ROUNDING    = ROUNDING;
		 defparam i_DSP48.A_REG_USE_CE   = A_REG_USE_CE;
		 defparam i_DSP48.B_REG_USE_CE   = B_REG_USE_CE;
		 defparam i_DSP48.C_REG_USE_CE   = C_REG_USE_CE;
		 defparam i_DSP48.OP_REG_USE_CE  = OP_REG_USE_CE;
		 defparam i_DSP48.P_REG_USE_CE   = P_REG_USE_CE;
		 defparam i_DSP48.W_REG_USE_CE   = W_REG_USE_CE;
		 defparam i_DSP48.O_REG_USE_CE   = O_REG_USE_CE;
		 defparam i_DSP48.A_REG_USE_RST  = A_REG_USE_RST;
		 defparam i_DSP48.B_REG_USE_RST  = B_REG_USE_RST;
		 defparam i_DSP48.C_REG_USE_RST  = C_REG_USE_RST;
		 defparam i_DSP48.OP_REG_USE_RST = OP_REG_USE_RST;
		 defparam i_DSP48.P_REG_USE_RST  = P_REG_USE_RST;
		 defparam i_DSP48.W_REG_USE_RST  = W_REG_USE_RST;
		 defparam i_DSP48.O_REG_USE_RST  = O_REG_USE_RST;
	  end
   endgenerate
endmodule

module EFX_DSP48_int (
   A, B, C, CASCIN, OP, SHIFT_ENA, CLK, CE, RST, O, CASCOUT, OVFL
);
   
   parameter MODE            = "NORMAL";
   parameter [0:0] A_REG     = 0;
   parameter [0:0] B_REG     = 0;
   parameter [0:0] C_REG     = 0;
   parameter [0:0] P_REG     = 0;
   parameter [0:0] OP_REG    = 0;
   parameter [0:0] W_REG     = 0;
   parameter [0:0] O_REG     = 0;
   parameter [0:0] RST_SYNC  = 0;
   parameter [0:0] SIGNED    = 1;
   parameter P_EXT           = "ALIGN_RIGHT";
   parameter C_EXT           = "ALIGN_RIGHT";
   parameter M_SEL           = "P";
   parameter N_SEL           = "C";
   parameter W_SEL           = "P";
   parameter CASCOUT_SEL     = "W";
   parameter ROUNDING        = "RNE";
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
   
   input [18:0]  A;
   input [17:0]  B;
   input [17:0]  C;
   input [47:0]  CASCIN;
   input [1:0] 	 OP;
   input 		 SHIFT_ENA, CLK, CE, RST;
   output [47:0] O;
   output [47:0] CASCOUT;
   output 		 OVFL;

   wire [18:0] 	 A_p;
   wire [17:0] 	 B_p, C_p;
   wire [1:0] 	 OP_p;
   wire [36:0] 	 P, P_p;
   wire [47:0] 	 C_a, P_a, M, N, X, W, W_p, S, O_p, CASCIN_asr18, CASCIN_lsr18;
   wire [15:0] 	 shift;
   wire 		 OVFL_w, OVFL_wp, OVFL_p;

   // Individual pipeline stages can ignore the CE & RST pins
   wire 		 CE_a, CE_b, CE_c, CE_op, CE_p, CE_w, CE_o;
   wire 		 RST_a, RST_b, RST_c, RST_op, RST_p, RST_w, RST_o;

   assign CE_a   = CE | ~A_REG_USE_CE;
   assign CE_b   = CE | ~B_REG_USE_CE;
   assign CE_c   = CE | ~C_REG_USE_CE;
   assign CE_op  = CE | ~OP_REG_USE_CE;
   assign CE_p   = CE | ~P_REG_USE_CE;
   assign CE_w   = CE | ~W_REG_USE_CE;
   assign CE_o   = CE | ~O_REG_USE_CE;
   assign RST_a  = RST & A_REG_USE_RST;
   assign RST_b  = RST & B_REG_USE_RST;
   assign RST_c  = RST & C_REG_USE_RST;
   assign RST_op = RST & OP_REG_USE_RST;
   assign RST_p  = RST & P_REG_USE_RST;
   assign RST_w  = RST & W_REG_USE_RST;
   assign RST_o  = RST & O_REG_USE_RST;

   // Mult Operator
   EFX_DSP48_pipe #(.W(19), .REG(A_REG), .SYNC(RST_SYNC)) A_pipe(.I(A), .CLK(CLK), .CE(CE_a), .RST(RST_a), .O(A_p));
   EFX_DSP48_pipe #(.W(18), .REG(B_REG), .SYNC(RST_SYNC)) B_pipe(.I(B), .CLK(CLK), .CE(CE_b), .RST(RST_b), .O(B_p));
   EFX_DSP48_mult_mode #(.MODE(MODE),.SIGNED(SIGNED)) mult(.A(A_p), .B(B_p), .O(P));
   EFX_DSP48_pipe #(.W(37), .REG(P_REG), .SYNC(RST_SYNC)) P_pipe(.I(P), .CLK(CLK), .CE(CE_p), .RST(RST_p), .O(P_p));

   // Mult Extender
   EFX_DSP48_p_extender #(.MODE(MODE), .SIGNED(SIGNED), .EXT(P_EXT)) ext_P(.I(P_p), .O(P_a));

   // C input and extender
   EFX_DSP48_pipe #(.W(18), .REG(C_REG), .SYNC(RST_SYNC)) C_pipe(.I(C), .CLK(CLK), .CE(CE_c), .RST(RST_c), .O(C_p));
   EFX_DSP48_c_extender #(.MODE(MODE), .SIGNED(SIGNED), .EXT(C_EXT)) ext_C(.I(C_p), .O(C_a));

   // CASCIN 18-bit shifter
   EFX_DSP48_shifter #(.W(48), .WS(5), .SIGNED(1)) ASR18_shifter(.I(CASCIN), .S(5'd18), .O(CASCIN_asr18));
   EFX_DSP48_shifter #(.W(48), .WS(5), .SIGNED(0)) LSR18_shifter(.I(CASCIN), .S(5'd18), .O(CASCIN_lsr18));
   
   // Choose Add/Sub Operator Inputs
   assign M = (M_SEL == "P") ? P_a : 
			  (M_SEL == "C") ? C_a :
			  (M_SEL == "ABC") ? {A_p[15:0],B_p[15:0],C_p[15:0]} : -1;
   

   wire [47:0] 	 CONST1;
   assign CONST1 = (MODE == "QUAD") ? 48'h001_001_001_001 : (MODE == "DUAL") ? 48'h000001_000001 : 48'd1;
   
   assign N = (N_SEL == "CONST0") ? 48'd0 :
			  (N_SEL == "CONST1") ? CONST1 :
			  (N_SEL == "C") ? C_a :
			  (N_SEL == "P") ? P_a :
			  (N_SEL == "CASCIN") ? CASCIN :
			  (N_SEL == "CASCIN_ASR18") ? CASCIN_asr18 :
			  (N_SEL == "CASCIN_LSR18") ? CASCIN_lsr18 :
			  (N_SEL == "W") ? W_p :
			  (N_SEL == "O") ? O_p : -1;

   // Add/Sub Operator
   EFX_DSP48_pipe #(.W(2), .REG(OP_REG), .SYNC(RST_SYNC)) OP_pipe(.I(OP), .CLK(CLK), .CE(CE_op), .RST(RST_op), .O(OP_p));
   EFX_DSP48_add_sub_mode #(.MODE(MODE), .SIGNED(SIGNED)) add_sub(.A(M), .B(N), .OP(OP_p), .O(X), .OVFL(OVFL_w));
   EFX_DSP48_pipe #(.W(48), .REG(W_REG), .SYNC(RST_SYNC)) W_pipe(.I(X), .CLK(CLK), .CE(CE_w), .RST(RST_w), .O(W_p));
   EFX_DSP48_pipe #(.W(1), .REG(W_REG), .SYNC(RST_SYNC)) OVFL_W_pipe(.I(OVFL_w), .CLK(CLK), .CE(CE_w), .RST(RST_w), .O(OVFL_wp));

   // Choose the shifter input W register or aligned multiplier
   assign W = (W_SEL == "P") ? P_a : W_p;
   EFX_DSP48_pipe #(.W(16), .REG(1)) shift_val(.I(C[15:0]), .CLK(CLK), .CE(SHIFT_ENA), .RST(RST), .O(shift));
   EFX_DSP48_shifter_mode #(.MODE(MODE), .SIGNED(SIGNED)) shifter(.I(W), .S(shift), .O(S));

   // Output pipeline
   EFX_DSP48_pipe #(.W(48), .REG(O_REG|(W_REG && W_SEL=="P")), .SYNC(RST_SYNC)) O_pipe(.I(S), .CLK(CLK), .CE(CE_o), .RST(RST_o), .O(O_p));
   EFX_DSP48_pipe #(.W(1), .REG(O_REG), .SYNC(RST_SYNC)) OVFL_O_pipe(.I(OVFL_wp), .CLK(CLK), .CE(CE_o), .RST(RST_o), .O(OVFL_p));
   assign O = O_p;
   assign OVFL = OVFL_p;

   // Choose Cascade Output
   assign CASCOUT = (CASCOUT_SEL == "C") ? C_a :
					(CASCOUT_SEL == "P") ? P_a :
					(CASCOUT_SEL == "W") ? W_p : 
					(CASCOUT_SEL == "ABC") ? {A_p[15:0],B_p[15:0],C_p[15:0]} : -1;
      
endmodule

module EFX_DSP48_float (
   A, B, C, CASCIN, OP, SHIFT_ENA, CLK, CE, RST, O, CASCOUT, OVFL
);
   
   parameter MODE            = "BFLOAT";
   parameter [0:0] A_REG     = 0;             // Ignored
   parameter [0:0] B_REG     = 0;             // Ignored
   parameter [0:0] C_REG     = 0;             // Ignored
   parameter [0:0] P_REG     = 0;             // Ignored
   parameter [0:0] OP_REG    = 0;             // Ignored
   parameter [0:0] W_REG     = 0;             // Ignored
   parameter [0:0] O_REG     = 0;
   parameter [0:0] RST_SYNC  = 0;
   parameter [0:0] SIGNED    = 1;             // Ignored
   parameter P_EXT           = "ALIGN_RIGHT"; // Ignored
   parameter C_EXT           = "ALIGN_RIGHT"; // Ignored
   parameter M_SEL           = "P";           // Ignored
   parameter N_SEL           = "C";
   parameter W_SEL           = "P";           // Ignored
   parameter CASCOUT_SEL     = "W";
   parameter ROUNDING        = "RNE";
   parameter [0:0] A_REG_USE_CE   = 1;
   parameter [0:0] B_REG_USE_CE   = 1;
   parameter [0:0] C_REG_USE_CE   = 1;
   parameter [0:0] OP_REG_USE_CE  = 1;
   parameter [0:0] P_REG_USE_CE   = 1;           // Ignored
   parameter [0:0] W_REG_USE_CE   = 1;           // Ignored
   parameter [0:0] O_REG_USE_CE   = 1;
   parameter [0:0] A_REG_USE_RST  = 1;
   parameter [0:0] B_REG_USE_RST  = 1;
   parameter [0:0] C_REG_USE_RST  = 1;
   parameter [0:0] OP_REG_USE_RST = 1;
   parameter [0:0] P_REG_USE_RST  = 1;           // Ignored
   parameter [0:0] W_REG_USE_RST  = 1;           // Ignored
   parameter [0:0] O_REG_USE_RST  = 1;
   
   input [18:0]  A;
   input [17:0]  B;
   input [17:0]  C;
   input [47:0]  CASCIN;
   input [1:0] 	 OP;
   input 		 SHIFT_ENA, CLK, CE, RST;
   output [47:0] O;
   output [47:0] CASCOUT;
   output 		 OVFL;

   // Special checking for BFLOAT mode
   reg 		finish_error = 0;
   initial begin
	  // Check for illegal modes
	  case(MODE)
		"BFLOAT" : ;
		default: begin
		 $display("ERROR: Illegal MODE %s", MODE);
		 finish_error = 1;
		end
	  endcase
	  // Check for illegal mux selection
	  case(N_SEL)
		"CONST0", "C", "CASCIN", "W" : ;
		default: begin
		 $display("ERROR: Illegal N_SEL %s", N_SEL);
		 finish_error = 1;
		end
	  endcase
	  case(CASCOUT_SEL)
		"W", "ABC" : ;
		default: begin
		 $display("ERROR: Illegal CASCOUT_SEL %s", CASCOUT_SEL);
		 finish_error = 1;
		end
	  endcase
	  case(ROUNDING)
		"RTZ", "RDOWN","RUP", "RTI", "RTO", "RNE" : ;
		default: begin
		 $display("ERROR: Illegal ROUNDING %s", ROUNDING);
		 finish_error = 1;
		end
	  endcase

	  if (finish_error == 1)
		#1 $finish();
   end

   localparam BF16_W = 16;
   localparam FP32_W = 32;
   
   wire [15:0] 	 A_p, B_p, C_p;
   wire [15:0] 	 A_bf, B_bf, C_bf;
   wire [1:0] 	 OP_p;
   wire [31:0] 	 C_fp;
   wire [47:0] 	 CASCIN_fp, N, R, R_p1, R_p2, R_p3, W_fp, W, O_p;
   wire [2:0] 	 ROUNDING_w;

   // Individual pipeline stages can ignore the CE & RST pins
   wire 		 CE_a, CE_b, CE_c, CE_op, CE_o;
   wire 		 RST_a, RST_b, RST_c, RST_op, RST_o;

   assign CE_a   = CE | ~A_REG_USE_CE;
   assign CE_b   = CE | ~B_REG_USE_CE;
   assign CE_c   = CE | ~C_REG_USE_CE;
   assign CE_op  = CE | ~OP_REG_USE_CE;
   assign CE_o   = CE | ~O_REG_USE_CE;
   assign RST_a  = RST & A_REG_USE_RST;
   assign RST_b  = RST & B_REG_USE_RST;
   assign RST_c  = RST & C_REG_USE_RST;
   assign RST_op = RST & OP_REG_USE_RST;
   assign RST_o  = RST & O_REG_USE_RST;

   // Input Registers, expects BF16 (only use the 16 LSB)
   EFX_DSP48_pipe #(.W(16), .REG(1'b1), .SYNC(RST_SYNC)) A_pipe(.I(A[15:0]), .CLK(CLK), .CE(CE_a), .RST(RST_a), .O(A_p));
   EFX_DSP48_pipe #(.W(16), .REG(1'b1), .SYNC(RST_SYNC)) B_pipe(.I(B[15:0]), .CLK(CLK), .CE(CE_b), .RST(RST_b), .O(B_p));
   EFX_DSP48_pipe #(.W(16), .REG(1'b1), .SYNC(RST_SYNC)) C_pipe(.I(C[15:0]), .CLK(CLK), .CE(CE_c), .RST(RST_c), .O(C_p));
   EFX_DSP48_pipe #(.W(2), .REG(1'b1), .SYNC(RST_SYNC)) OP_pipe(.I(OP), .CLK(CLK), .CE(CE_op), .RST(RST_op), .O(OP_p));

   // Subnormal numbers not supported
   fp_fmt_conv #(.R_W(48)) fp_fmt();
   assign A_bf = fp_fmt.adjust_bf_input(A_p);
   assign B_bf = fp_fmt.adjust_bf_input(B_p);
   assign C_bf = fp_fmt.adjust_bf_input(C_p);

   // Convert C input to FP32 (zero extend the mantissa)
   assign C_fp = {C_bf, 16'd0};

   // Convert CASCIN input to FP32 from internal representation (includes error flags)
   assign CASCIN_fp = fp_fmt.conv_rec_to_fp(CASCIN);

   // Choose the C input to the FMA block
   assign N = (N_SEL == "CONST0") ? 48'd0 :
			  (N_SEL == "CONST1") ? 48'd1 :              // Illegal (behaves the same as CONST0)
			  (N_SEL == "C") ? C_fp :
			  (N_SEL == "P") ? -1 :                      // Illegal
			  (N_SEL == "CASCIN") ? CASCIN_fp :
			  (N_SEL == "CASCIN_ASR18") ? -1 :            // Illegal
			  (N_SEL == "CASCIN_LSR18") ? -1 :            // Illegal
			  (N_SEL == "W") ? W_fp :
			  (N_SEL == "O") ? -1 : -1;                  // Illegal

   // Set the ROUNDING value
   assign ROUNDING_w = (ROUNDING == "RTZ") ? 3'b001 :        // Round to Zero
					   (ROUNDING == "RDOWN") ? 3'b010 :      // Round Down
					   (ROUNDING == "RUP") ? 3'b011 :        // Round Up
					   (ROUNDING == "RTI") ? 3'b100 :        // Round to Nearest, ties to infinity
					   (ROUNDING == "RTO") ? 3'b110 :        // Round to Odd
					   (ROUNDING == "RNE") ? 3'b000 : -1;    // Round to Nearest, ties to even
   

   // FMA (Fused-Multiply-Add) Block
   f_mulAdd fma (A_bf, B_bf, N[31:0], OP_p, ROUNDING_w, R);

   // FMA pipe-line
   EFX_DSP48_pipe #(.W(48), .REG(1), .SYNC(RST_SYNC)) R1_pipe(.I(R), .CLK(CLK), .CE(1'b1), .RST(RST), .O(R_p1));
   EFX_DSP48_pipe #(.W(48), .REG(1), .SYNC(RST_SYNC)) R2_pipe(.I(R_p1), .CLK(CLK), .CE(1'b1), .RST(RST), .O(R_p2));
   EFX_DSP48_pipe #(.W(48), .REG(1), .SYNC(RST_SYNC)) R3_pipe(.I(R_p2), .CLK(CLK), .CE(1'b1), .RST(RST), .O(R_p3));
   EFX_DSP48_pipe #(.W(48), .REG(1'b1), .SYNC(RST_SYNC)) W_pipe(.I(R_p3), .CLK(CLK), .CE(1'b1), .RST(RST), .O(W_fp));
   EFX_DSP48_pipe #(.W(48), .REG(O_REG), .SYNC(RST_SYNC)) O_pipe(.I(W_fp), .CLK(CLK), .CE(CE_o), .RST(RST_o), .O(O_p));
   assign O = O_p;

   // Overflow is always 0
   assign OVFL = 1'b0;

   // Cascade expects internal format
   assign W = fp_fmt.conv_fp_to_rec(W_fp);
   
   // Choose Cascade Output
   assign CASCOUT = (CASCOUT_SEL == "C") ? -1  :          // Illegal
					(CASCOUT_SEL == "P") ? -1  :          // Illegal
					(CASCOUT_SEL == "W") ? W   : 
					(CASCOUT_SEL == "ABC") ? {A_p[15:0],B_p[15:0],C_p[15:0]} : -1;

endmodule

module EFX_DSP48_pipe (I, CLK, CE, RST, O);
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

module EFX_DSP48_mult_mode (A, B, O);
   parameter MODE = "NORMAL";
   parameter SIGNED = 1;

   input [18:0] A;
   input [17:0] B;
   output [36:0] O;

   generate
	  case(MODE) 
		"NORMAL": begin
		   EFX_DSP48_mult #(.A_W(19), .B_W(18), .O_W(37), .SIGNED(SIGNED)) mult(.A(A), .B(B), .O(O));
		end
		"DUAL": begin
		   EFX_DSP48_mult #(.A_W(11), .B_W(10), .O_W(21), .SIGNED(SIGNED)) multA(.A(A[18:8]), .B(B[17:8]), .O(O[36:16]));
		   EFX_DSP48_mult #(.A_W(8), .B_W(8), .O_W(16), .SIGNED(SIGNED)) multB(.A(A[7:0]), .B(B[7:0]), .O(O[15:0]));
		end
		"QUAD": begin
		   EFX_DSP48_mult #(.A_W(7), .B_W(6), .O_W(13), .SIGNED(SIGNED)) multA(.A(A[18:12]), .B(B[17:12]), .O(O[36:24]));
		   EFX_DSP48_mult #(.A_W(4), .B_W(4), .O_W(8), .SIGNED(SIGNED)) multB(.A(A[11:8]), .B(B[11:8]), .O(O[23:16]));
		   EFX_DSP48_mult #(.A_W(4), .B_W(4), .O_W(8), .SIGNED(SIGNED)) multC(.A(A[7:4]), .B(B[7:4]), .O(O[15:8]));
		   EFX_DSP48_mult #(.A_W(4), .B_W(4), .O_W(8), .SIGNED(SIGNED)) multD(.A(A[3:0]), .B(B[3:0]), .O(O[7:0]));
		end
	  endcase
   endgenerate
   
endmodule

module EFX_DSP48_mult (A, B, O);
   parameter A_W = 19;
   parameter B_W = 18;
   parameter O_W = 37;
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

module EFX_DSP48_p_extender (I, O);
   parameter MODE = "NORMAL";
   parameter SIGNED = 1;
   parameter EXT = "ALIGN_RIGHT";

   input [36:0] I;
   output [47:0] O;

   generate
	  case (MODE)
		"NORMAL": begin
		   EFX_DSP48_extender #(.W_I(37),.W_O(48),.SIGNED(SIGNED),.EXT(EXT)) extA(.I(I), .O(O));
		end
		"DUAL": begin
		   EFX_DSP48_extender #(.W_I(21),.W_O(24),.SIGNED(SIGNED),.EXT(EXT)) extA(.I(I[36:16]), .O(O[47:24]));
		   EFX_DSP48_extender #(.W_I(16),.W_O(24),.SIGNED(SIGNED),.EXT(EXT)) extB(.I(I[15:0]),  .O(O[23:0]));
		end
		"QUAD": begin
		   if (EXT == "TEST") begin
			  // Only extend the MSB
			  EFX_DSP48_extender #(.W_I(13),.W_O(24),.SIGNED(SIGNED),.EXT("ALIGN_RIGHT")) extA(.I(I[36:24]), .O(O[47:24]));
			  EFX_DSP48_extender #(.W_I(8), .W_O(8),.SIGNED(SIGNED),.EXT("ALIGN_RIGHT")) extB(.I(I[23:16]), .O(O[23:16]));
			  EFX_DSP48_extender #(.W_I(8), .W_O(8),.SIGNED(SIGNED),.EXT("ALIGN_RIGHT")) extC(.I(I[15:8]),  .O(O[15:8]));
			  EFX_DSP48_extender #(.W_I(8), .W_O(8),.SIGNED(SIGNED),.EXT("ALIGN_RIGHT")) extD(.I(I[7:0]),   .O(O[7:0]));
		   end
		   else begin
			  // Truncate the 13-bit result
			  assign O[47:36] = (EXT === "ALIGN_RIGHT") ? I[35:24] : I[36:25];
			  EFX_DSP48_extender #(.W_I(8), .W_O(12),.SIGNED(SIGNED),.EXT(EXT)) extB(.I(I[23:16]), .O(O[35:24]));
			  EFX_DSP48_extender #(.W_I(8), .W_O(12),.SIGNED(SIGNED),.EXT(EXT)) extC(.I(I[15:8]),  .O(O[23:12]));
			  EFX_DSP48_extender #(.W_I(8), .W_O(12),.SIGNED(SIGNED),.EXT(EXT)) extD(.I(I[7:0]),   .O(O[11:0]));
		   end
		end
	  endcase
   endgenerate
   
endmodule

module EFX_DSP48_c_extender (I, O);
   parameter MODE = "NORMAL";
   parameter SIGNED = 1;
   parameter EXT = "ALIGN_RIGHT";

   input [17:0] I;
   output [47:0] O;

   generate
	  case (MODE)
		"NORMAL": begin
		   EFX_DSP48_extender #(.W_I(18),.W_O(48),.SIGNED(SIGNED),.EXT(EXT)) extA(.I(I), .O(O));
		end
		"DUAL": begin
		   EFX_DSP48_extender #(.W_I(10),.W_O(24),.SIGNED(SIGNED),.EXT(EXT)) extA(.I(I[17:8]), .O(O[47:24]));
		   EFX_DSP48_extender #(.W_I(8), .W_O(24),.SIGNED(SIGNED),.EXT(EXT)) extB(.I(I[7:0]), .O(O[23:0]));
		end
		"QUAD": begin
		   if (EXT == "TEST") begin
			  EFX_DSP48_extender #(.W_I(6), .W_O(36),.SIGNED(SIGNED),.EXT("ALIGN_RIGHT")) extA(.I(I[17:12]), .O(O[47:12]));
			  EFX_DSP48_extender #(.W_I(4), .W_O(4),.SIGNED(SIGNED),.EXT("ALIGN_RIGHT")) extB(.I(I[11:8]), .O(O[11:8]));
			  EFX_DSP48_extender #(.W_I(4), .W_O(4),.SIGNED(SIGNED),.EXT("ALIGN_RIGHT")) extC(.I(I[7:4]), .O(O[7:4]));
			  EFX_DSP48_extender #(.W_I(4), .W_O(4),.SIGNED(SIGNED),.EXT("ALIGN_RIGHT")) extD(.I(I[3:0]), .O(O[3:0]));
		   end
		   else begin
			  EFX_DSP48_extender #(.W_I(6), .W_O(12),.SIGNED(SIGNED),.EXT(EXT)) extA(.I(I[17:12]), .O(O[47:36]));
			  EFX_DSP48_extender #(.W_I(4), .W_O(12),.SIGNED(SIGNED),.EXT(EXT)) extB(.I(I[11:8]), .O(O[35:24]));
			  EFX_DSP48_extender #(.W_I(4), .W_O(12),.SIGNED(SIGNED),.EXT(EXT)) extC(.I(I[7:4]), .O(O[23:12]));
			  EFX_DSP48_extender #(.W_I(4), .W_O(12),.SIGNED(SIGNED),.EXT(EXT)) extD(.I(I[3:0]), .O(O[11:0]));
		   end
		end
	  endcase
   endgenerate
   
endmodule

module EFX_DSP48_extender (I, O);
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

module EFX_DSP48_shifter_mode (I, S, O);
   parameter MODE = "NORMAL";
   parameter SIGNED = 1;

   input [47:0] I;
   input [15:0] S;
   output [47:0] O;
	  
   generate
	  case(MODE) 
		"NORMAL": begin
		   EFX_DSP48_shifter #(.W(48), .SIGNED(SIGNED)) shiftA(.I(I), .S(S[3:0]), .O(O));
		end
		"DUAL": begin
		   EFX_DSP48_shifter #(.W(24), .SIGNED(SIGNED)) shiftA(.I(I[47:24]), .S(S[7:4]), .O(O[47:24]));
		   EFX_DSP48_shifter #(.W(24), .SIGNED(SIGNED)) shiftB(.I(I[23:0]),  .S(S[3:0]), .O(O[23:0]));
		end
		"QUAD": begin
		   EFX_DSP48_shifter #(.W(12), .SIGNED(SIGNED)) shiftA(.I(I[47:36]), .S(S[15:12]), .O(O[47:36]));
		   EFX_DSP48_shifter #(.W(12), .SIGNED(SIGNED)) shiftB(.I(I[35:24]), .S(S[11:8]),  .O(O[35:24]));
		   EFX_DSP48_shifter #(.W(12), .SIGNED(SIGNED)) shiftC(.I(I[23:12]), .S(S[7:4]),   .O(O[23:12]));
		   EFX_DSP48_shifter #(.W(12), .SIGNED(SIGNED)) shiftD(.I(I[11:0]),  .S(S[3:0]),   .O(O[11:0]));
		end
	  endcase
   endgenerate
   
endmodule

module EFX_DSP48_shifter (I, S, O);
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

module EFX_DSP48_add_sub_mode (A, B, OP, O, OVFL);
   parameter MODE = "NORMAL";
   parameter SIGNED = 1;

   input [47:0] A;
   input [47:0] B;
   input [1:0] 	OP;
   output [47:0] O;
   output 		 OVFL;

   wire [3:0] 	 OVFL_w;
   
   generate
	  case(MODE) 
		"NORMAL": begin
		   EFX_DSP48_add_sub #(.W(48), .SIGNED(SIGNED)) add_sub(.A(A), .B(B), .OP(OP), .O(O), .OVFL(OVFL));
		end
		"DUAL": begin
		   EFX_DSP48_add_sub #(.W(24), .SIGNED(SIGNED)) add_subA(.A(A[47:24]), .B(B[47:24]), .OP(OP), .O(O[47:24]), .OVFL(OVFL_w[1]));
		   EFX_DSP48_add_sub #(.W(24), .SIGNED(SIGNED)) add_subB(.A(A[23:0]), .B(B[23:0]), .OP(OP), .O(O[23:0]), .OVFL(OVFL_w[0]));
		   assign OVFL = OVFL_w[1] | OVFL_w[0];
		end
		"QUAD": begin
		   EFX_DSP48_add_sub #(.W(12), .SIGNED(SIGNED)) add_subA(.A(A[47:36]), .B(B[47:36]), .OP(OP), .O(O[47:36]), .OVFL(OVFL_w[3]));
		   EFX_DSP48_add_sub #(.W(12), .SIGNED(SIGNED)) add_subB(.A(A[35:24]), .B(B[35:24]), .OP(OP), .O(O[35:24]), .OVFL(OVFL_w[2]));
		   EFX_DSP48_add_sub #(.W(12), .SIGNED(SIGNED)) add_subC(.A(A[23:12]), .B(B[23:12]), .OP(OP), .O(O[23:12]), .OVFL(OVFL_w[1]));
		   EFX_DSP48_add_sub #(.W(12), .SIGNED(SIGNED)) add_subD(.A(A[11:0]),  .B(B[11:0]),  .OP(OP), .O(O[11:0]),  .OVFL(OVFL_w[0]));
		   assign OVFL = |OVFL_w;
		end
	  endcase
   endgenerate
   
endmodule

module EFX_DSP48_add_sub (A, B, OP, O, OVFL);
   parameter W = 48;
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

module f_mulAdd(a, b, c, op, rounding_mode, r);
    parameter A_W = 16;
    parameter B_W = 16;
    parameter C_W = 32;
    parameter R_W = 48;

    localparam BF16_W = 16;
    localparam BF16_N_EXP = 8;
    localparam BF16_N_FRAC = 7;

    localparam FP32_W = 32;
    localparam FP32_N_EXP = 8;
    localparam FP32_N_FRAC = 23;

    localparam defaultNaN_fp32 = 32'h7FC00000;

    localparam inexactBit = 0;
    localparam underflowBit = 1;
    localparam overflowBit = 2;
    localparam infBit = 3;
    localparam invalidBit = 4;

    localparam [4:0] inexactBitMask = (1'b1 << inexactBit);
    localparam [4:0] underflowBitMask = (1'b1 << underflowBit);
    localparam [4:0] overflowBitMask = (1'b1 << overflowBit);
    localparam [4:0] infBitMaskMask = (1'b1 << infBit);
    localparam [4:0] invalidBitMask = (1'b1 << invalidBit);

    input [A_W-1:0] a;
    input [B_W-1:0] b;
    input [C_W-1:0] c;
    input [1:0] op;
    input [2:0] rounding_mode;
    output [R_W-1:0] r;

    task automatic isSpecialValue_bf16;
        input [BF16_N_EXP-1:0] exp;
        input [BF16_N_FRAC-1:0] frac;
        output isNaN, isInf, isZero;

        begin
            // according to Wiki page
            isNaN = (&exp) && (|frac);
            isInf = (&exp) && ~(|frac);
            isZero = ~(|exp) && ~(|frac);
        end
    endtask

    task automatic decode_bf16_rep;
        input [BF16_W-1:0] f;
        output isNaN, isInf, isZero;
        output f_sign;
        output [BF16_N_EXP-1:0] f_exp;
        output [BF16_N_FRAC-1:0] f_frac;

        begin
            f_sign = f[BF16_W-1];
            f_exp = f[BF16_N_EXP+BF16_N_FRAC-1:BF16_N_FRAC];
            f_frac = (f_exp == 'd0) ? {BF16_N_FRAC{1'b0}} : f[BF16_N_FRAC-1:0];

            isSpecialValue_bf16(f_exp, f_frac, isNaN, isInf, isZero);
        end
    endtask

    task automatic isSpecialValue_fp32;
        input [FP32_N_EXP-1:0] exp;
        input [FP32_N_FRAC-1:0] frac;
        output isNaN, isInf, isZero;

        begin
            // according to Wiki page
            isNaN = (&exp) && (|frac);
            isInf = (&exp) && ~(|frac);
            isZero = ~(|exp) && ~(|frac);
        end
    endtask

    task automatic decode_fp32_rep;
        input [FP32_W-1:0] f;
        output isNaN, isInf, isZero;
        output f_sign;
        output [FP32_N_EXP-1:0] f_exp;
        output [FP32_N_FRAC-1:0] f_frac;

        begin
            f_sign = f[FP32_W-1];
            f_exp = f[FP32_N_EXP+FP32_N_FRAC-1:FP32_N_FRAC];
            f_frac = (f_exp == 'd0) ? {FP32_N_FRAC{1'b0}} : f[FP32_N_FRAC-1:0];

            isSpecialValue_fp32(f_exp, f_frac, isNaN, isInf, isZero);
        end
    endtask

    function automatic isSignalNaN_fp32;
        input [FP32_W-1:0] f;

        begin
            isSignalNaN_fp32 = (((f & 32'h7FC00000) == 32'h7F800000) && (f & 32'h003FFFFF));
        end
    endfunction

    function automatic isNaN_fp32;
        input [FP32_W-1:0] f;
        begin
            isNaN_fp32 =  (((~(f) & 32'h7F800000) == 0) && (f & 32'h007FFFFF));
        end
    endfunction

    function automatic [4:0] raiseExceptionFlag;
        input [4:0] currFlag;
        input [4:0] flagToSet;

        begin
            raiseExceptionFlag = currFlag | flagToSet;
        end
    endfunction

    task automatic propagateNaN_fp32;
        input [FP32_W-1:0] fa;
        input [FP32_W-1:0] fb;
        input [4:0] f_currFlag;

        output [FP32_W-1:0] fout;
        output [4:0] fout_exptFlag;

        begin : propagate
            reg is_fa_signal;
            reg is_fb_signal;
            reg [4:0] f_expt_flag;

            f_expt_flag = f_currFlag;

            is_fa_signal = isSignalNaN_fp32(fa);
            is_fb_signal = isSignalNaN_fp32(fb);

            if (is_fa_signal || is_fb_signal) begin
                f_expt_flag = raiseExceptionFlag(f_expt_flag, invalidBitMask);
            end

            fout = defaultNaN_fp32;
            fout_exptFlag = f_expt_flag;
        end
    endtask

    function automatic integer count_leading_zero;
        input [30:0] val;

        begin : cnt
            integer i;
            for (i=30; val[i]==0; i=i-1) begin
            end
            count_leading_zero = 30 - i;
        end
    endfunction

    function automatic [31:0] adjust_radix_pt;
        input [31:0] frac;
        input integer exp_diff;

        begin : adjust
            reg [31:0] adj_frac;
            reg [1:0] gr;
            reg s;

            if (exp_diff >= 2) begin
                gr = (frac & ((1<<exp_diff) - 1)) >> (exp_diff - 2);
            end
            else begin
                gr = {frac&exp_diff, 1'b0};
            end

            if (exp_diff >= 3) begin
                s = |(frac & ((1<<(exp_diff-2)) - 1));
            end
            else begin
                s = 1'b0;
            end

            adj_frac = {(frac >> exp_diff), gr, s};

            adjust_radix_pt = adj_frac;
        end
    endfunction

    function automatic find_rounding;
        input f_sign;
        input [31:0] f_frac;
        input integer rbit;
        input [2:0] rounding_mode;

        begin : round_value
            reg lsb, g, r, s;
            reg ulp;

            lsb = (rbit < 32) ? f_frac[rbit] : 1'b0;

            if (rbit >= 2) begin
                {g, r} = (f_frac & ((1<<rbit) - 1)) >> (rbit - 2);
            end
            else begin
                {g, r} = {f_frac&rbit, 1'b0};
            end

            if (rbit >= 3) begin
                s = |(f_frac & ((1<<(rbit-2)) - 1));
            end
            else begin
                s = 1'b0;
            end

            case (rounding_mode)
                3'b001: // rz
                begin
                    ulp = 1'b0;
                end
                3'b010: // rdown
                begin
                    ulp = (f_sign == 1 && ({g, r, s} != 3'b000))? 1'b1:1'b0;
                end
                3'b011: // rup
                begin
                    ulp = (f_sign == 0 && ({g, r, s} != 3'b000))? 1'b1:1'b0;
                end
                3'b100: // rnz
                begin
                    ulp = g;
                end
                3'b110: // rno
                begin
                    ulp = ({g, r, s} != 3'b000)? ~lsb : 1'b0;
                end
                default: //rne
                begin
                    if ({g, r, s} == 3'b100) begin
                        ulp = lsb;
                    end
                    else begin
                        ulp = g;
                    end
                end
            endcase

            find_rounding = ulp;
        end
    endfunction

    task automatic round_and_pack_fp32;
        input f_sign;
        input [FP32_N_EXP*2-1:0] f_exp;
        input [31:0] f_frac;
        input [4:0] f_currFlag;
        input [2:0] rounding_mode;

        output [31:0] f_round;
        output [4:0] f_exptFlag;

        begin : rounding
            // rounding 32 bits fraction to 23 bits
            // assume there are 2 bits at MSB have special use,
            // for example, the hidden bit "1" is at bit 30
            // therefore, 32-23-2 = 7 and the new LSB is at bit 7
            localparam integer RoundToBit = 7;

            reg signed [FP32_N_EXP*2-1:0] f_exp_round;
            reg [31:0] f_frac_round;
            reg [4:0] f_expt_flag;
            reg signed [FP32_N_EXP*2-1:0] exp_max, exp_min;

            integer rbit;

            reg lsb, g, r, s;
            reg ulp;

            rbit = RoundToBit;

            exp_max = (1 << FP32_N_EXP) - 2;
            exp_min = 'd1;

            ulp = find_rounding(f_sign, f_frac, RoundToBit, rounding_mode);

            f_exp_round = f_exp;
            f_frac_round = (f_frac >> RoundToBit) + ulp;
            f_expt_flag = f_currFlag;

            if (f_frac_round[24] == 1'b1) begin
                f_frac_round = f_frac_round >> 1;
                f_exp_round = f_exp_round + 1;
            end

            if ((f_frac&((1<<RoundToBit)-1)) != 'd0) begin
                f_expt_flag = raiseExceptionFlag(f_expt_flag, inexactBitMask);
            end

            if (f_exp_round > exp_max) begin
                if (rounding_mode == 3'b010) begin
                    f_round = (f_sign) ?
                        {f_sign, {FP32_N_EXP{1'b1}}, {FP32_N_FRAC{1'b0}}} :
                        {f_sign, {FP32_N_EXP-1{1'b1}}, 1'b0, {FP32_N_FRAC{1'b1}}};
                end
                else if (rounding_mode == 3'b011) begin
                    f_round = (f_sign) ?
                        {f_sign, {FP32_N_EXP-1{1'b1}}, 1'b0, {FP32_N_FRAC{1'b1}}} :
                        {f_sign, {FP32_N_EXP{1'b1}}, {FP32_N_FRAC{1'b0}}};
                end
                else if (rounding_mode == 3'b001 || rounding_mode == 3'b110) begin
                    f_round = {f_sign, {FP32_N_EXP-1{1'b1}}, 1'b0, {FP32_N_FRAC{1'b1}}};
                end
                else begin
                    f_round = {f_sign, {FP32_N_EXP{1'b1}}, {FP32_N_FRAC{1'b0}}};
                end

                f_expt_flag = raiseExceptionFlag(f_expt_flag, (overflowBitMask | inexactBitMask));

            end
            else if (f_exp_round < exp_min) begin
                // use original fraction
                // calculate the new round-to-bit by adding the addition bits when exp <= 0
                rbit = rbit + (-f_exp_round) + 1;

                if ((f_frac&((1<<rbit)-1)) != 'd0) begin
                    f_expt_flag = raiseExceptionFlag(f_expt_flag, (underflowBitMask | inexactBitMask));
                end

                // if bit 23 is 1 after round, exp + 1
                ulp = find_rounding(f_sign, f_frac, rbit, rounding_mode);
                f_frac_round = (f_frac >> rbit) + ulp;

                // become subnormal, set to zero
                f_round = (f_frac_round[23] == 1'b1) ?
                    {f_sign, ({(FP32_N_EXP+FP32_N_FRAC){1'b0}} | f_frac_round[23:0])} :
                    {f_sign, {(FP32_N_EXP+FP32_N_FRAC){1'b0}}};

            end
            else begin
                f_round = {f_sign, f_exp_round[FP32_N_EXP-1:0], f_frac_round[FP32_N_FRAC-1:0]};
            end

            f_exptFlag = f_expt_flag;
        end
    endtask

    task automatic muladd_fp32;
        input [BF16_W-1:0] a, b;
        input [FP32_W-1:0] c;
        input [1:0] op_mode;
        input [2:0] rounding_mode;
        output [FP32_W-1:0] p;
        output [4:0] exceptionFlag;

        begin : muladd
            reg a_sign;
            reg [BF16_N_EXP-1:0] a_exp;
            reg [BF16_N_FRAC-1:0] a_frac;
            reg isNaN_a, isInf_a, isZero_a;

            reg b_sign;
            reg [BF16_N_EXP-1:0] b_exp;
            reg [BF16_N_FRAC-1:0] b_frac;
            reg isNaN_b, isInf_b, isZero_b;

            reg c_sign;
            reg [FP32_N_EXP-1:0] c_exp;
            reg [FP32_N_FRAC-1:0] c_frac;
            reg isNaN_c, isInf_c, isZero_c;

            reg [FP32_N_EXP:0] exp_max, exp_min;
            reg signed [FP32_N_EXP-1:0] exp_bias;

            reg var_c_sign;

            reg var_p_sign;
            reg signed [FP32_N_EXP*2-1:0] var_p_exp;
            reg [31:0] var_p_frac;

            reg var_s_sign;
            reg [FP32_N_EXP*2-1:0] var_s_exp;
            // sign bit, carry,  hidden bit "1"
            // -> reserve 3 bits at MSB
            // save 3 bits when right-shift 
            // -> reserve 3 bits at LSB
            reg [31:0] var_c_frac;
            reg [31:0] var_s_frac;
            reg [FP32_W-1:0] var_s;
            reg [4:0] var_s_flag;

            integer exp_diff;
            integer n_sl;

            var_s = {(FP32_W-1){1'b0}};
            var_s_flag = {5{1'b0}};

            exp_bias = ((1 << FP32_N_EXP-1) - 1);
            exp_max = (1 << FP32_N_EXP) - 2;
            exp_min = 'd0;

            decode_bf16_rep(a, isNaN_a, isInf_a, isZero_a, a_sign, a_exp, a_frac);
            decode_bf16_rep(b, isNaN_b, isInf_b, isZero_b, b_sign, b_exp, b_frac);

            decode_fp32_rep(c, isNaN_c, isInf_c, isZero_c, c_sign, c_exp, c_frac);

            if (isNaN_a || isNaN_b) begin
                propagateNaN_fp32((a<<16), (b<<16), var_s_flag, var_s, var_s_flag);
                propagateNaN_fp32(var_s, c, var_s_flag, p, exceptionFlag);
                disable muladd;
            end

            if ((isInf_a && isZero_b) || (isZero_a && isInf_b)) begin
                p = defaultNaN_fp32;
                exceptionFlag = raiseExceptionFlag(var_s_flag, invalidBitMask);
                disable muladd;
            end

            var_c_sign = c_sign^op_mode[0];
            var_p_sign = a_sign^b_sign^op_mode[1];

            if (isInf_a || isInf_b) begin
                var_s = {var_p_sign, {FP32_N_EXP{1'b1}}, {FP32_N_FRAC{1'b0}}};
                if (isNaN_c) begin
                    propagateNaN_fp32(var_s, c, var_s_flag, p, exceptionFlag);
                end
                else if (isInf_c && var_p_sign != var_c_sign) begin
                    var_s = defaultNaN_fp32;
                    var_s_flag = raiseExceptionFlag(var_s_flag, invalidBitMask);

                    propagateNaN_fp32(var_s, c, var_s_flag, p, exceptionFlag);
                end
                else begin
                    p = var_s;
                    exceptionFlag = var_s_flag;
                end

                disable muladd;
            end

            if (isNaN_c) begin
                //p = c;
                propagateNaN_fp32('d0, c, var_s_flag, p, exceptionFlag);
                disable muladd;
            end

            if (isInf_c) begin
                //p = c;
                p = {var_c_sign, c_exp, c_frac};
                exceptionFlag = var_s_flag;
                disable muladd;
            end

            if (isZero_a || isZero_b) begin
                if (isZero_c && (var_p_sign^var_c_sign)) begin
                    p = {((rounding_mode == 3'b010)? 1'b1 : 1'b0), {31{1'b0}}};
                end
                else begin
                    //p = c;
                    p = {var_c_sign, c_exp, c_frac};
                end

                exceptionFlag = var_s_flag;
                disable muladd;
            end

            // mul part
            var_p_exp = $signed(a_exp - exp_bias) + $signed(b_exp - exp_bias) + exp_bias;

            // add back the hidden bit when multiply
            var_p_frac = ({1'b1, a_frac} * {1'b1, b_frac});

            // normalize product
            if (var_p_frac[15] == 1'b1) begin
                var_p_exp = var_p_exp + 1;
            end
            else begin
                var_p_frac = var_p_frac << 1;
            end

            // add part
            if (isZero_c) begin
                // rounding and pack
                round_and_pack_fp32(var_p_sign, var_p_exp,
                    (var_p_frac[15:0] << 15), var_s_flag, rounding_mode,
                    p, exceptionFlag);

                disable muladd;
            end

            var_p_frac = var_p_frac[15:0] << (3 + 8);
            var_c_frac = {1'b1, c_frac} << 3;

            exp_diff = $signed(var_p_exp) - $signed({1'b0, c_exp});

            if (exp_diff >= 0) begin
                // 3 extra bits (g,r,s) may add at LSB after radix adjustment
                var_p_frac = var_p_frac << 3;
                var_c_frac = adjust_radix_pt(var_c_frac, exp_diff);

                var_s_exp = var_p_exp;
            end
            else begin
                // 3 extra bits (g,r,s) may add at LSB after radix adjustment
                var_p_frac = adjust_radix_pt(var_p_frac, -exp_diff);
                var_c_frac = var_c_frac << 3;

                var_s_exp = c_exp;
            end

            var_p_frac = (var_p_sign)?-var_p_frac:var_p_frac;
            var_c_frac = (var_c_sign)?-var_c_frac:var_c_frac;

            var_s_frac = var_p_frac + var_c_frac;

            if (exp_diff == 0 && (var_p_sign^var_c_sign) && ~(|var_s_frac)) begin
                // complete cancel?
                var_s = {((rounding_mode == 3'b010)? 1'b1 : 1'b0), {31{1'b0}}};

            end
            else begin
                var_s_sign = var_s_frac[31];
                var_s_frac = (var_s_frac[31])?-var_s_frac:var_s_frac;

                // normalize sum
                // now, consider the hidden '1' at bit 30, instead of bit 29
                // -> will need to rounding the last 7 bits, instead of 6
                if (var_s_frac[30] == 1'b1) begin
                    var_s_exp = var_s_exp + 1;
                end
                else begin
                    // make sure the hidden '1' is at bit 30
                    var_s_frac = var_s_frac << 1;
                end

                n_sl = count_leading_zero(var_s_frac[30:0]);
                var_s_exp = var_s_exp - n_sl;
                var_s_frac = var_s_frac << n_sl;

                // rounding and pack
                round_and_pack_fp32(var_s_sign, var_s_exp, var_s_frac, var_s_flag, rounding_mode,
                    var_s, var_s_flag);
            end

            p = var_s;
            exceptionFlag = var_s_flag;
        end
    endtask

    reg [FP32_W-1:0] w_r;
    reg [4:0] w_r_expt_flag = {5{1'b0}};

    assign r = {w_r_expt_flag, {(R_W-FP32_W-5){1'b0}}, w_r};

    always @(*)
    begin
        muladd_fp32(a, b, c, op, rounding_mode, w_r, w_r_expt_flag);
    end

endmodule

module fp_fmt_conv();
    parameter R_W = 48;
    parameter EXP_W = 8;
    parameter FRAC_W = 23;
    parameter BF_FRAC_W = 7;

    localparam FP_W = EXP_W+FRAC_W+1;
    localparam BF_W = EXP_W+BF_FRAC_W+1;

    function automatic [FP_W-1:0] rec_to_fp;
        input [FP_W:0] rec_in;

        begin : convert_to_fp
            reg sign;
            reg signed [EXP_W+1:0] rec_exp;
            reg [FRAC_W-1:0] rec_frac;

            reg [EXP_W-1:0] fp_exp;
            reg [FRAC_W-1:0] fp_frac;

            reg signed [EXP_W:0] fp_exp_min;

            reg isSpecial;
            reg isNaN, isInf, isZero;
            reg isSubnormal;

            fp_exp_min = (1<<(EXP_W-1)) + 2;

            sign = rec_in[FP_W];
            rec_exp = rec_in[EXP_W+FRAC_W:FRAC_W];
            rec_frac = rec_in[FRAC_W-1:0];

            isSpecial = (rec_exp[EXP_W:EXP_W-1] == 2'b11);

            isNaN = isSpecial && rec_exp[EXP_W-2];
            isInf = isSpecial && !rec_exp[EXP_W-2];
            isZero = (rec_exp[EXP_W:EXP_W-2] == 3'b000);
            isSubnormal = (rec_exp < fp_exp_min);

            fp_exp = (isSubnormal) ? {EXP_W{1'b0}} :
                (isNaN || isInf) ? {EXP_W{1'b1}} : (rec_exp - fp_exp_min + 1);
            fp_frac = (isSubnormal || isInf) ? {FRAC_W{1'b0}} : rec_frac;
            rec_to_fp = {sign, fp_exp, fp_frac};
        end
    endfunction

    function automatic [FP_W:0] fp_to_rec;
        input [FP_W-1:0] fp_in;

        begin : convert_to_rec
            reg sign;
            reg [EXP_W-1:0] fp_exp;
            reg [FRAC_W-1:0] fp_frac;

            reg [EXP_W:0] rec_exp;
            reg [FRAC_W-1:0] rec_frac;

            reg [EXP_W:0] adj_exp;

            reg isSpecial, isExpZero;

            sign = fp_in[FP_W-1];
            fp_exp = fp_in[EXP_W+FRAC_W-1:FRAC_W];
            fp_frac = fp_in[FRAC_W-1:0];

            adj_exp = fp_exp + ((1 << (EXP_W-1)) | 1);

            isExpZero = (fp_exp == 0);
            isSpecial = (adj_exp[EXP_W:EXP_W-1]  == 2'b11);

            rec_exp[EXP_W:EXP_W-2] = (isSpecial)? {2'b11, (|fp_frac)} : (isExpZero)? 3'b000 : adj_exp[EXP_W:EXP_W-2];
            rec_exp[EXP_W-3:0] = adj_exp[EXP_W-3:0];

            rec_frac = (isExpZero)? {FRAC_W{1'b0}} : fp_frac;
            fp_to_rec = {sign, rec_exp, rec_frac};
        end
    endfunction

    function automatic [R_W-1:0] conv_rec_to_fp;
        input [R_W-1:0] in;

        begin
            conv_rec_to_fp = {in[R_W-1:R_W-5], {(R_W-FP_W-5){1'b0}}, rec_to_fp(in[FP_W:0])};
        end
    endfunction

    function automatic [R_W-1:0] conv_fp_to_rec;
        input [R_W-1:0] in;

        begin
            conv_fp_to_rec = {in[R_W-1:R_W-5], {(R_W-(FP_W+1)-5){1'b0}}, fp_to_rec(in[FP_W-1:0])};
        end
    endfunction

    function automatic [BF_W-1:0] adjust_bf_input;
        input [BF_W-1:0] bf_in;

        begin : cast_to_zero_if_denormal
            reg sign;
            reg [EXP_W-1:0] bf_exp;
            reg [BF_FRAC_W-1:0] bf_frac;

            reg [BF_FRAC_W-1:0] bf_out_frac;

            reg isExpZero;

            sign = bf_in[BF_W-1];
            bf_exp = bf_in[EXP_W+BF_FRAC_W-1:BF_FRAC_W];
            bf_frac = bf_in[BF_FRAC_W-1:0];

            isExpZero = (bf_exp == 0);

            bf_out_frac = (isExpZero)? {BF_FRAC_W{1'b0}} : bf_frac;
            adjust_bf_input = {sign, bf_exp, bf_out_frac};
        end
    endfunction

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
