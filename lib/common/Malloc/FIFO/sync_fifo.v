`timescale  1ns/1ps
module sync_fifo #(
   parameter W = 8
)
(
	input 	    		clk, 
	input				reset_n, 
	input				rd_en,
	output [W-1 : 0]  	rd_data,
	input				wr_en, 
	input  [W-1 : 0]  	wr_data,
	output reg  		full, 
	output reg  		empty
);

parameter D = 4;

parameter AW  = (D == 4)   ? 2 :
				(D == 8)   ? 3 :
				(D == 16)  ? 4 :
				(D == 32)  ? 5 :
				(D == 64)  ? 6 :
				(D == 128) ? 7 :
				(D == 256) ? 8 : 0;
   
// synopsys translate_off
initial begin
	if (AW == 0) begin
	$display ("%m : ERROR!!! Fifo depth %d not in range 4 to 256", D);
	end // if (AW == 0)
end // initial begin

// synopsys translate_on

reg [W-1 : 0]    mem[D-1 : 0];
reg [AW-1 : 0]   rd_ptr, wr_ptr;
   
always @ (posedge clk or negedge reset_n) 
	if (reset_n == 1'b0) begin
		wr_ptr <= {AW{1'b0}} ;
	end
	else begin
		if (wr_en & !full) begin
		wr_ptr <= wr_ptr + 1'b1 ;
		end
	end

always @ (posedge clk or negedge reset_n) 
	if (reset_n == 1'b0) begin
		rd_ptr <= {AW{1'b0}} ;
	end
	else begin
		if (rd_en & !empty) begin
		rd_ptr <= rd_ptr + 1'b1 ;
		end
	end


always @ (posedge clk or negedge reset_n) 
	if (reset_n == 1'b0) begin
		empty <= 1'b1 ;
	end
	else begin
		empty <= (((wr_ptr - rd_ptr) == {{(AW-1){1'b0}}, 1'b1}) & rd_en & ~wr_en) ? 1'b1 : 
				((wr_ptr == rd_ptr) & ~rd_en & wr_en) ? 1'b0 : empty ;
	end

always @ (posedge clk or negedge reset_n) 
	if (reset_n == 1'b0) begin
		full <= 1'b0 ;
	end
	else begin
		full <= (((wr_ptr - rd_ptr) == {{(AW-1){1'b1}}, 1'b0}) & ~rd_en & wr_en) ? 1'b1 : 
				(((wr_ptr - rd_ptr) == {AW{1'b1}}) & rd_en & ~wr_en) ? 1'b0 : full ;
	end

always @ (posedge clk) 
	if (wr_en)
		mem[wr_ptr] <= wr_data;

assign  rd_data = mem[rd_ptr];


// synopsys translate_off
always @(posedge clk) begin
	if (wr_en && full) begin
		$display("%m : Error! sfifo overflow!");
	end
end

always @(posedge clk) begin
	if (rd_en && empty) begin
		$display("%m : error! sfifo underflow!");
	end
end
// synopsys translate_on
//---------------------------------------

endmodule


