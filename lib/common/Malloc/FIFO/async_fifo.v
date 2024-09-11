//-------------------------------------------
// async FIFO
//-----------------------------------------------
`timescale  1ns/1ps
module async_fifo #(
   parameter W = 4'd8
) (
	//timing for wr
	input				wr_clk, 
	input				wr_reset_n, 
	input				wr_en, 
	output				full, 
	output				afull, 
	input  [W-1 : 0]	wr_data,
	//timing for rd
	input				rd_clk, 
	input				rd_reset_n,
	input				rd_en,
	output				empty,
	output				aempty,      
	output [W-1 : 0]	rd_data
);

parameter DP       = 3'd4;
parameter WR_FAST  = 1'b1;
parameter RD_FAST  = 1'b1;
parameter EMPTY_DP = 1'b0;
parameter FULL_DP  = DP;

parameter AW =  (DP == 2)   ? 1 : 
				(DP == 4)   ? 2 :
				(DP == 8)   ? 3 :
				(DP == 16)  ? 4 :
				(DP == 32)  ? 5 :
				(DP == 64)  ? 6 :
				(DP == 128) ? 7 :
				(DP == 256) ? 8 : 0;
// synopsys translate_off

initial begin
	if (AW == 0) begin
		$display ("%m : ERROR!!! Fifo depth %d not in range 2 to 256", DP);
	end // if (AW == 0)
end // initial begin

// synopsys translate_on

reg [W-1 : 0]    mem[DP-1 : 0];

/*********************** write side ************************/
reg  [AW:0] sync_rd_ptr_0, sync_rd_ptr_1; 
wire [AW:0] sync_rd_ptr;
reg  [AW:0] wr_ptr, grey_wr_ptr;
reg  [AW:0] grey_rd_ptr;
reg  full_q;
wire full_c;
wire afull_c;
wire [AW:0] wr_ptr_inc = wr_ptr + 1'b1;
wire [AW:0] wr_cnt = get_cnt(wr_ptr, sync_rd_ptr);

assign full_c  = (wr_cnt == FULL_DP) ? 1'b1 : 1'b0;
assign afull_c = (wr_cnt == FULL_DP-1) ? 1'b1 : 1'b0;

always @(posedge wr_clk or negedge wr_reset_n) begin
	if (!wr_reset_n) begin
		wr_ptr <= 0;
		grey_wr_ptr <= 0;
		full_q <= 0;	
	end
	else if (wr_en) begin
		wr_ptr <= wr_ptr_inc;
		grey_wr_ptr <= bin2grey(wr_ptr_inc);
		if (wr_cnt == (FULL_DP-1)) begin
			full_q <= 1'b1;
		end
	end
	else begin
		if (full_q && (wr_cnt<FULL_DP)) begin
			full_q <= 1'b0;
		end
	end
end

assign full  = (WR_FAST == 1) ? full_c : full_q;
assign afull = afull_c;

always @(posedge wr_clk) begin
	if (wr_en) begin
		mem[wr_ptr[AW-1:0]] <= wr_data;
	end
end

wire [AW:0] grey_rd_ptr_dly ;
assign #1 grey_rd_ptr_dly = grey_rd_ptr;

// read pointer synchronizer
always @(posedge wr_clk or negedge wr_reset_n) begin
	if (!wr_reset_n) begin
		sync_rd_ptr_0 <= 0;
		sync_rd_ptr_1 <= 0;
	end
	else begin
		sync_rd_ptr_0 <= grey_rd_ptr_dly;		
		sync_rd_ptr_1 <= sync_rd_ptr_0;
	end
end

assign sync_rd_ptr = grey2bin(sync_rd_ptr_1);

   /************************ read side *****************************/
reg  [AW:0] sync_wr_ptr_0, sync_wr_ptr_1; 
wire [AW:0] sync_wr_ptr;
reg  [AW:0] rd_ptr;
reg  empty_q;
wire empty_c;
wire aempty_c;
wire [AW:0] rd_ptr_inc = rd_ptr + 1'b1;
wire [AW:0] sync_wr_ptr_dec = sync_wr_ptr - 1'b1;
wire [AW:0] rd_cnt = get_cnt(sync_wr_ptr, rd_ptr);
 
assign empty_c  = (rd_cnt == 0) ? 1'b1 : 1'b0;
assign aempty_c = (rd_cnt == 1) ? 1'b1 : 1'b0;

always @(posedge rd_clk or negedge rd_reset_n) begin
	if (!rd_reset_n) begin
		rd_ptr <= 0;
		grey_rd_ptr <= 0;
		empty_q <= 1'b1;
	end
	else begin
		if (rd_en) begin
			rd_ptr <= rd_ptr_inc;
			grey_rd_ptr <= bin2grey(rd_ptr_inc);
			if (rd_cnt==(EMPTY_DP+1)) begin
				empty_q <= 1'b1;
			end
		end
		else begin
			if (empty_q && (rd_cnt!=EMPTY_DP)) begin
				empty_q <= 1'b0;
			end
		end
	end
end

assign empty  = (RD_FAST == 1) ? empty_c : empty_q;
assign aempty = aempty_c;

reg [W-1 : 0]  rd_data_q;

wire [W-1 : 0] rd_data_c = mem[rd_ptr[AW-1:0]];
always @(posedge rd_clk) begin
	rd_data_q <= rd_data_c;
end
assign rd_data  = (RD_FAST == 1) ? rd_data_c : rd_data_q;

wire [AW:0] grey_wr_ptr_dly ;
assign #1 grey_wr_ptr_dly =  grey_wr_ptr;

// write pointer synchronizer
always @(posedge rd_clk or negedge rd_reset_n) begin
	if (!rd_reset_n) begin
		sync_wr_ptr_0 <= 0;
		sync_wr_ptr_1 <= 0;
	end
	else begin
		sync_wr_ptr_0 <= grey_wr_ptr_dly;		
		sync_wr_ptr_1 <= sync_wr_ptr_0;
	end
end
assign sync_wr_ptr = grey2bin(sync_wr_ptr_1);

/************************ functions ******************************/
function [AW:0] bin2grey;
input [AW:0] bin;
reg [8:0] bin_8;
reg [8:0] grey_8;
begin
	bin_8 = bin;
	grey_8[1:0] = do_grey(bin_8[2:0]);
	grey_8[3:2] = do_grey(bin_8[4:2]);
	grey_8[5:4] = do_grey(bin_8[6:4]);
	grey_8[7:6] = do_grey(bin_8[8:6]);
	grey_8[8] = bin_8[8];
	bin2grey = grey_8;
end
endfunction

function [AW:0] grey2bin;
input [AW:0] grey;
reg [8:0] grey_8;
reg [8:0] bin_8;
begin
	grey_8 = grey;
	bin_8[8] = grey_8[8];
	bin_8[7:6] = do_bin({bin_8[8], grey_8[7:6]});
	bin_8[5:4] = do_bin({bin_8[6], grey_8[5:4]});
	bin_8[3:2] = do_bin({bin_8[4], grey_8[3:2]});
	bin_8[1:0] = do_bin({bin_8[2], grey_8[1:0]});
	grey2bin = bin_8;
end
endfunction


function [1:0] do_grey;
input [2:0] bin;
begin
	if (bin[2]) begin  // do reverse grey
		case (bin[1:0]) 
			2'b00: do_grey = 2'b10;
			2'b01: do_grey = 2'b11;
			2'b10: do_grey = 2'b01;
			2'b11: do_grey = 2'b00;
		endcase
	end
	else begin
		case (bin[1:0]) 
			2'b00: do_grey = 2'b00;
			2'b01: do_grey = 2'b01;
			2'b10: do_grey = 2'b11;
			2'b11: do_grey = 2'b10;
		endcase
	end
end
endfunction

function [1:0] do_bin;
input [2:0] grey;
begin
	if (grey[2]) begin	// actually bin[2]
		case (grey[1:0])
			2'b10: do_bin = 2'b00;
			2'b11: do_bin = 2'b01;
			2'b01: do_bin = 2'b10;
			2'b00: do_bin = 2'b11;
		endcase
	end
	else begin
		case (grey[1:0])
			2'b00: do_bin = 2'b00;
			2'b01: do_bin = 2'b01;
			2'b11: do_bin = 2'b10;
			2'b10: do_bin = 2'b11;
		endcase
	end
end
endfunction
			
function [AW:0] get_cnt;
input [AW:0] wr_ptr, rd_ptr;
begin
	if (wr_ptr >= rd_ptr) begin
		get_cnt = (wr_ptr - rd_ptr);	
	end
	else begin
		get_cnt = DP*2 - (rd_ptr - wr_ptr);
	end
end
endfunction

// synopsys translate_off
always @(posedge wr_clk) begin
	if (wr_en && full) begin
		$display($time, "%m Error! afifo overflow!");
		$stop;
	end
end

always @(posedge rd_clk) begin
	if (rd_en && empty) begin
		$display($time, "%m error! afifo underflow!");
		$stop;
	end
end
// synopsys translate_on

endmodule
