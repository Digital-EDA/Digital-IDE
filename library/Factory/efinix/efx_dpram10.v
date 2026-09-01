/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020 Efinix Inc. All rights reserved.
//
// Efinix Dual-Port Block RAM (BRAM):
//
// This is a 10K true dual-port RAM
//
// The A & B ports can
// Be in any of the following WIDTHs:
//   8  --> 1024x8
//   4  --> 2048x4
//   2  --> 4096x2
//   1  --> 8192x1
//   10 --> 1024x10
//   5  --> 2048x5
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

module EFX_DPRAM10
(
   CLKA, WEA, CLKEA, RSTA, ADDRENA, WDATAA, ADDRA, RDATAA,
   CLKB, WEB, CLKEB, RSTB, ADDRENB, WDATAB, ADDRB, RDATAB
);
   

   parameter [0:0] CLKA_POLARITY    = 1'b1;
   parameter [0:0] CLKEA_POLARITY   = 1'b1;
   parameter [0:0] WEA_POLARITY     = 1'b1;
   parameter [0:0] ADDRENA_POLARITY = 1'b1;
   parameter [0:0] RSTA_POLARITY    = 1'b1;
   parameter [0:0] CLKB_POLARITY    = 1'b1;
   parameter [0:0] CLKEB_POLARITY   = 1'b1;
   parameter [0:0] WEB_POLARITY     = 1'b1;
   parameter [0:0] ADDRENB_POLARITY = 1'b1;
   parameter [0:0] RSTB_POLARITY    = 1'b1;
   // Need to add all the data & address input  polarity inversion parameters
   parameter READ_WIDTH_A = 8;
   parameter WRITE_WIDTH_A = 8;
   parameter READ_WIDTH_B = 8;
   parameter WRITE_WIDTH_B = 8;
   parameter OUTPUT_REG_A = 1'b0;
   parameter OUTPUT_REG_B = 1'b0;
   parameter WRITE_MODE_A = "READ_FIRST";
   parameter WRITE_MODE_B = "READ_FIRST";
   parameter RESET_RAM_A = "ASYNC";
   parameter RESET_OUTREG_A = "ASYNC";
   parameter RESET_RAM_B = "ASYNC";
   parameter RESET_OUTREG_B = "ASYNC";
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

   localparam READ_AWIDTH_A = 
			    (READ_WIDTH_A == 1) ? 13 :
			    (READ_WIDTH_A == 2) ? 12 :
			    (READ_WIDTH_A == 4) ? 11 :
			    (READ_WIDTH_A == 5) ? 11 :
			    (READ_WIDTH_A == 8) ? 10 :
			    (READ_WIDTH_A == 10) ? 10 :-1;
   
   localparam WRITE_AWIDTH_A = 
			    (WRITE_WIDTH_A == 1) ? 13 :
			    (WRITE_WIDTH_A == 2) ? 12 :
			    (WRITE_WIDTH_A == 4) ? 11 :
			    (WRITE_WIDTH_A == 5) ? 11 :
			    (WRITE_WIDTH_A == 8) ? 10 :
			    (WRITE_WIDTH_A == 10) ? 10 :-1;

   // Greater of Read and Write widths defines input size
   localparam AWIDTH_A = (READ_AWIDTH_A > WRITE_AWIDTH_A) ? READ_AWIDTH_A : WRITE_AWIDTH_A;
   localparam DWIDTH_A = (READ_WIDTH_A > WRITE_WIDTH_A) ? WRITE_WIDTH_A : READ_WIDTH_A;
   
   localparam READ_AWIDTH_B = 
			    (READ_WIDTH_B == 1) ? 13 :
			    (READ_WIDTH_B == 2) ? 12 :
			    (READ_WIDTH_B == 4) ? 11 :
			    (READ_WIDTH_B == 5) ? 11 :
			    (READ_WIDTH_B == 8) ? 10 :
			    (READ_WIDTH_B == 10) ? 10 :-1;
   
   localparam WRITE_AWIDTH_B = 
			    (WRITE_WIDTH_B == 1) ? 13 :
			    (WRITE_WIDTH_B == 2) ? 12 :
			    (WRITE_WIDTH_B == 4) ? 11 :
			    (WRITE_WIDTH_B == 5) ? 11 :
			    (WRITE_WIDTH_B == 8) ? 10 :
			    (WRITE_WIDTH_B == 10) ? 10 :-1;
   
   // Greater of Read and Write widths defines input size
   localparam AWIDTH_B = (READ_AWIDTH_B > WRITE_AWIDTH_B) ? READ_AWIDTH_B : WRITE_AWIDTH_B;
   localparam DWIDTH_B = (READ_WIDTH_B > WRITE_WIDTH_B) ? WRITE_WIDTH_B : READ_WIDTH_B;

   
   localparam MEMORY_SIZE = 512*20;

   localparam READ_FIRST = 0;
   localparam WRITE_FIRST = 1;
   localparam WRITE_NOT_READ = 2;
   
   input 			CLKA, WEA, CLKEA, RSTA, ADDRENA;
   input 			CLKB, WEB, CLKEB, RSTB, ADDRENB;
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
   wire     RSTA_net;
   wire     ADDRENA_net;
   wire     WEB_net;
   wire     CLKEB_net;
   wire     RSTB_net;
   wire     ADDRENB_net;

   // Pull unused address lines low, to mirror EFX synthesis behavior.
   wire [AWIDTH_A-1:0] ADDRA_net;
   wire [AWIDTH_B-1:0] ADDRB_net;
   reg [AWIDTH_A-1:0] ADDRA_r;
   reg [AWIDTH_B-1:0] ADDRB_r;

   // Default values for optional control signals
   assign (weak0, weak1) WEA_net     = ~WEA_POLARITY;
   assign (weak0, weak1) CLKEA_net   = CLKEA_POLARITY;
   assign (weak0, weak1) RSTA_net    = ~RSTA_POLARITY;
   assign (weak0, weak1) ADDRENA_net = ADDRENA_POLARITY;
   assign (weak0, weak1) WEB_net     = ~WEB_POLARITY;
   assign (weak0, weak1) CLKEB_net   = CLKEB_POLARITY;
   assign (weak0, weak1) RSTB_net    = ~RSTB_POLARITY;
   assign (weak0, weak1) ADDRENB_net = ADDRENB_POLARITY;

   assign (weak0, weak1) ADDRA_net = {AWIDTH_A{1'b0}};
   assign (weak0, weak1) ADDRB_net = {AWIDTH_B{1'b0}};

   // Now assign the input
   assign WEA_net     = WEA;
   assign CLKEA_net   = CLKEA;
   assign RSTA_net    = RSTA;
   assign ADDRENA_net = ADDRENA;
   assign WEB_net     = WEB;
   assign CLKEB_net   = CLKEB;
   assign RSTB_net    = RSTB;
   assign ADDRENB_net = ADDRENB;

   assign ADDRA_net = ADDRA;
   assign ADDRB_net = ADDRB;

   function COMPATIBLE_WIDTH;
	  input integer 	w1, w2;
	  COMPATIBLE_WIDTH = ((((w1==1)||(w1==2)||(w1==4)||(w1==8))&&((w2==1)||(w2==2)||(w2==4)||(w2==8))) ||
					(((w1==5)||(w1==10))&&((w2==5)||(w2==10))));
   endfunction

   
   reg 		finish_error = 0;
   initial begin
	  // Check for illegal modes, address width will be -1
	  if (READ_AWIDTH_A == -1) begin
		 $display("ERROR:Illegal READ WIDTH Port A %d", READ_WIDTH_A);
		 finish_error = 1;
	  end
	  if (WRITE_AWIDTH_A == -1) begin
		 $display("ERROR:Illegal WRITE WIDTH Port A %d", WRITE_WIDTH_A);
		 finish_error = 1;
	  end
	  if (READ_AWIDTH_B == -1) begin
		 $display("ERROR:Illegal READ WIDTH Port B %d", READ_WIDTH_B);
		 finish_error = 1;
	  end
	  if (WRITE_AWIDTH_B == -1) begin
		 $display("ERROR:Illegal WRITE WIDTH Port B %d", WRITE_WIDTH_B);
		 finish_error = 1;
	  end
	  if (~COMPATIBLE_WIDTH(READ_WIDTH_A,WRITE_WIDTH_A)) begin
		 $display("ERROR: Port A READ WIDTH %d cannot be used with WRITE WIDTH %d", READ_WIDTH_A, WRITE_WIDTH_A);
		 finish_error = 1;
	  end
	  if (~COMPATIBLE_WIDTH(READ_WIDTH_B,WRITE_WIDTH_B)) begin
		 $display("ERROR: Port B READ WIDTH %d cannot be used with WRITE WIDTH %d", READ_WIDTH_B, WRITE_WIDTH_B);
		 finish_error = 1;
	  end
	  if (~COMPATIBLE_WIDTH(READ_WIDTH_A,READ_WIDTH_B)||~COMPATIBLE_WIDTH(WRITE_WIDTH_A,WRITE_WIDTH_B)) begin
		 $display("ERROR: Port A READ/WRITE WIDTHS %d/%d cannot be used with Port B READ/WRITE WIDTHs %d/%d", 
				  READ_WIDTH_A, WRITE_WIDTH_A, READ_WIDTH_B, WRITE_WIDTH_B);
		 finish_error = 1;
	  end
	  // Check for illegal write modes
	  if (WRITE_MODE_A != "READ_FIRST" && WRITE_MODE_A != "WRITE_FIRST" && WRITE_MODE_A != "NO_CHANGE") begin
		 $display("ERROR:Illegal WRITE_MODE A %s", WRITE_MODE_A);
		 finish_error = 1;
	  end
	  if (WRITE_MODE_B != "READ_FIRST" && WRITE_MODE_B != "WRITE_FIRST" && WRITE_MODE_B != "NO_CHANGE") begin
		 $display("ERROR:Illegal WRITE_MODE B %s", WRITE_MODE_B);
		 finish_error = 1;
	  end
	  if (RESET_RAM_A != "ASYNC" && RESET_RAM_A != "SYNC" && RESET_RAM_A != "NONE") begin
		 $display("ERROR: Illegal RESET_RAM_A setting %s", RESET_RAM_A);
		 finish_error = 1;
	  end
	  if (RESET_RAM_B != "ASYNC" && RESET_RAM_B != "SYNC" && RESET_RAM_B != "NONE") begin
		 $display("ERROR: Illegal RESET_RAM_B setting %s", RESET_RAM_B);
		 finish_error = 1;
	  end
	  if (RESET_OUTREG_A != "ASYNC" && RESET_OUTREG_A != "NONE") begin
		 $display("ERROR: Illegal RESET_OUTREG_A setting %s", RESET_OUTREG_A);
		 finish_error = 1;
	  end
	  if (RESET_OUTREG_B != "ASYNC" && RESET_OUTREG_B != "NONE") begin
		 $display("ERROR: Illegal RESET_OUTREG_B setting %s", RESET_OUTREG_B);
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
   wire 			CLKA_i, WEA_i, CLKEA_i, RSTA_i, ADDRENA_i;
   wire 			CLKB_i, WEB_i, CLKEB_i, RSTB_i, ADDRENB_i;

   assign CLKA_i    = CLKA_POLARITY    ~^ CLKA;
   assign CLKEA_i   = CLKEA_POLARITY   ~^ CLKEA_net;
   assign RSTA_i    = RSTA_POLARITY    ~^ RSTA_net;
   assign ADDRENA_i = ADDRENA_POLARITY ~^ ADDRENA_net;
   assign WEA_i     = WEA_POLARITY     ~^ WEA_net;
   assign CLKB_i    = CLKB_POLARITY    ~^ CLKB;
   assign CLKEB_i   = CLKEB_POLARITY   ~^ CLKEB_net;
   assign RSTB_i    = RSTB_POLARITY    ~^ RSTB_net;
   assign ADDRENB_i = ADDRENB_POLARITY ~^ ADDRENB_net;
   assign WEB_i     = WEB_POLARITY     ~^ WEB_net;

   //////////////////////////////////////////////////////////////
   // Port A
   //////////////////////////////////////////////////////////////
   // Wires for the configurable reset controls
   wire 			ram_async_rsta, ram_sync_rsta, outreg_async_rsta;
   assign ram_async_rsta    = (RESET_RAM_A == "ASYNC")    ? RSTA_i : 1'b0;
   assign ram_sync_rsta     = (RESET_RAM_A == "SYNC")     ? RSTA_i : 1'b0;
   assign outreg_async_rsta = (RESET_OUTREG_A == "ASYNC") ? RSTA_i : 1'b0;
   
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

   always@(posedge CLKA_i) begin
     if (CLKEA_i) begin
		// Only update the address latch if not stalled
		ADDRA_r = ADDRENA_i ? ADDRA_net : ADDRA_r;

		// Do an early read, write and late read
		// Then decide what do do with the read data
		read_rama(ADDRA_r[AWIDTH_A-1:AWIDTH_A - READ_AWIDTH_A], RDATAA_early);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		write_rama(ADDRA_r[AWIDTH_A-1:AWIDTH_A - WRITE_AWIDTH_A], WDATAA, WEA_i);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		read_rama(ADDRA_r[AWIDTH_A-1:AWIDTH_A - READ_AWIDTH_A], RDATAA_late);
		#0;
	 end
   end 

   // Decide which data to output
   always@(posedge CLKA_i or posedge ram_async_rsta) begin
	  if (ram_async_rsta) begin
		 RDATAA_out <= {READ_WIDTH_A{1'b0}};
      end 
	  else begin
		 // Delay for the read/write/read to happen
		 #0; #0; #0;
		 if (CLKEA_i) begin
			// Check for sync reset
			if (ram_sync_rsta) begin 
			   RDATAA_out <= {READ_WIDTH_A{1'b0}};
	        end 
			else begin
			   // Based on the write mode decide which read data to use
			   if (WRITE_MODE_A == "READ_FIRST") begin
				  RDATAA_out <= RDATAA_early;
			   end
			   else if (WRITE_MODE_A == "WRITE_FIRST") begin
				  if (WEA_i) RDATAA_out <= WDATAA;
				  else RDATAA_out <= RDATAA_late;
			   end
			   else /* (WRITE_MODE_A == "NO_CHANGE") */ begin
				  RDATAA_out <= WEA_i ? RDATAA_out : RDATAA_early;
			   end
			end
		 end
	  end
   end

   // Optional output register
   generate if (OUTPUT_REG_A) 
	 begin
		always@(posedge CLKA_i or posedge outreg_async_rsta) begin
		   if (outreg_async_rsta) RDATAA_reg <= {READ_WIDTH_A{1'b0}};
		   else if (CLKEA_i) RDATAA_reg <= RDATAA_out;
		end

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
   // Wires for the configurable reset controls
   wire 			ram_async_rstb, ram_sync_rstb, outreg_async_rstb;
   assign ram_async_rstb    = (RESET_RAM_B == "ASYNC")    ? RSTB_i : 1'b0;
   assign ram_sync_rstb     = (RESET_RAM_B == "SYNC")     ? RSTB_i : 1'b0;
   assign outreg_async_rstb = (RESET_OUTREG_B == "ASYNC") ? RSTB_i : 1'b0;
   
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

   always@(posedge CLKB_i) begin
     if (CLKEB_i) begin
		// Only update the address latch if not stalled
		ADDRB_r = ADDRENB_i ? ADDRB_net : ADDRB_r;

		// Do an early read, write and late read
		// Then decide what do do with the read data
		read_ramb(ADDRB_r[AWIDTH_B-1:AWIDTH_B - READ_AWIDTH_B], RDATAB_early);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		write_ramb(ADDRB_r[AWIDTH_B-1:AWIDTH_B - WRITE_AWIDTH_B], WDATAB, WEB_i);
		#0; // Use #0 delay blocking assignments to allow cross port read/write
		read_ramb(ADDRB_r[AWIDTH_B-1:AWIDTH_B - READ_AWIDTH_B], RDATAB_late);
		#0;
		
	 end
   end

   // Choose the Read value to output
   always@(posedge CLKB_i or posedge ram_async_rstb) begin
	  if (ram_async_rstb) begin
		 RDATAB_out <= {READ_WIDTH_B{1'b0}};
      end
	  else begin
		 // Delay for the read/write/read to happen
		 #0; #0; #0;
		 if (CLKEB_i) begin
			if (ram_sync_rstb) begin
			   RDATAB_out <= {READ_WIDTH_B{1'b0}};
	        end 
			else begin
			   // Based on the write mode decide which read data to use
			   if (WRITE_MODE_B == "READ_FIRST") begin
				  RDATAB_out <= RDATAB_early;
			   end
			   else if (WRITE_MODE_B == "WRITE_FIRST") begin
				  if (WEB_i) RDATAB_out <= WDATAB;
				  else RDATAB_out <= RDATAB_late;
			   end
			   else /* (WRITE_MODE_B == "NO_CHANGE") */ begin
				  RDATAB_out <= WEB_i ? RDATAB_out : RDATAB_early;
			   end
			end
		 end
	  end
   end
   
   // Optional output register
   generate if (OUTPUT_REG_B) 
	 begin
		always@(posedge CLKB_i or posedge outreg_async_rstb) begin
		   if (outreg_async_rstb) RDATAB_reg <= {READ_WIDTH_B{1'b0}};
		   else if (CLKEB_i)RDATAB_reg <= RDATAB_out;
		end

		assign RDATAB = RDATAB_reg;
	 end
   else
	 begin
		assign RDATAB = RDATAB_out;
	 end
   endgenerate

endmodule // EFX_DPRAM10

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
