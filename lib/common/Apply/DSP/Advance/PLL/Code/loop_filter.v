module loop_filter(CLK, RESET, C, D1, D2);
   input         CLK;
   input         RESET;
   input [7:0]   C;
   output [11:0] D1;
   output [11:0] D2;
   reg [11:0]    D1;
   reg [11:0]    D2;
   
   
   reg [11:0]    E;
   reg [11:0]    dtemp;
   
   
always @(posedge CLK or posedge RESET)
	if (RESET == 1'b1) begin
		D1 <= {12{1'b0}};
		D2 <= {12{1'b0}};
		E <= {12{1'b0}};
		dtemp <= {12{1'b0}};
	end
	else begin
		dtemp <= ({C[7], C[7], C[7], C, 1'b0}) + dtemp - E;
		E <= {dtemp[11], dtemp[11], dtemp[11], dtemp[11], dtemp[11:4]};
		D1 <= dtemp;
		D2 <= {dtemp[11:4], 4'b0000};
	end
   
endmodule
