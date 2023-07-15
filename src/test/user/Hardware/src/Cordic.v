`timescale 1ns / 1ps

module Cordic #(
	parameter XY_BITS      = 12,
	parameter PH_BITS      = 32,
	parameter ITERATIONS   = 32,
	parameter CORDIC_STYLE = "ROTATE",
	parameter PHASE_ACC    = "ON"
)(
	input   clk,
	input   RST,
	input   signed [XY_BITS-1:0] x_i,
	input   signed [XY_BITS-1:0] y_i,
	input   signed [PH_BITS-1:0] phase_in,

	output  signed [XY_BITS-1:0] x_o,
	output  signed [XY_BITS-1:0] y_o,
	output  signed [PH_BITS-1:0] phase_out,

	input   valid_in, 
	output  valid_out
);

localparam [XY_BITS-1:0] K_COS = (0.607252935 * 2**(XY_BITS-1))-2;

/*
//360°--2^16,phase_in = 16bits (input [15:0] phase_in)
//1°--2^16/360
*/
function [PH_BITS-1:0] tanangle;
input [4:0] i;
begin
	case (i)
		5'b00000: tanangle = (32'h20000000 >> (32 - PH_BITS));   //tan = 1/2^1 = 1/2
		5'b00001: tanangle = (32'h12e4051e >> (32 - PH_BITS));   //tan = 1/2^2 = 1/4
		5'b00010: tanangle = (32'h09fb385b >> (32 - PH_BITS));   //tan = 1/2^3 = 1/8
		5'b00011: tanangle = (32'h051111d4 >> (32 - PH_BITS));   //tan = 1/2^4 = 1/16
		5'b00100: tanangle = (32'h028b0d43 >> (32 - PH_BITS));   //tan = 1/2^5 = 1/32
		5'b00101: tanangle = (32'h0145d7e1 >> (32 - PH_BITS));   //tan = 1/2^6 = 1/64
		5'b00110: tanangle = (32'h00a2f61e >> (32 - PH_BITS));   //tan = 1/2^7 = 1/128
		5'b00111: tanangle = (32'h00517c55 >> (32 - PH_BITS));   //tan = 1/2^8 = 1/256
		5'b01000: tanangle = (32'h0028be53 >> (32 - PH_BITS));   //tan = 1/2^9 = 1/512
		5'b01001: tanangle = (32'h00145f2f >> (32 - PH_BITS));   //tan = 1/2^10 = 1/1024
		5'b01010: tanangle = (32'h000a2f98 >> (32 - PH_BITS));   //tan = 1/2^11 = 1/2048
		5'b01011: tanangle = (32'h000517cc >> (32 - PH_BITS));   //tan = 1/2^12 = 1/4096
		5'b01100: tanangle = (32'h00028be6 >> (32 - PH_BITS));   //tan = 1/2^13 = 1/8192
		5'b01101: tanangle = (32'h000145f3 >> (32 - PH_BITS));   //tan = 1/2^14 = 1/16384
		5'b01110: tanangle = (32'h0000a2fa >> (32 - PH_BITS));   //tan = 1/2^15 = 1/32768
		5'b01111: tanangle = (32'h0000517d >> (32 - PH_BITS));   //tan = 1/2^16 = 1/65536
		5'b10000: tanangle = (32'h000028be >> (32 - PH_BITS));   //tan = 1/2^17 = 1/131072
		5'b10001: tanangle = (32'h0000145f >> (32 - PH_BITS));   //tan = 1/2^18 = 1/262144
		5'b10010: tanangle = (32'h00000a30 >> (32 - PH_BITS));   //tan = 1/2^19 = 1/524288
		5'b10011: tanangle = (32'h00000518 >> (32 - PH_BITS));   //tan = 1/2^20 = 1/1048576
		5'b10100: tanangle = (32'h0000028c >> (32 - PH_BITS));   //tan = 1/2^21 = 1/2097152
		5'b10101: tanangle = (32'h00000146 >> (32 - PH_BITS));   //tan = 1/2^22 = 1/4194304
		5'b10110: tanangle = (32'h000000a3 >> (32 - PH_BITS));   //tan = 1/2^23 = 1/8388608
		5'b10111: tanangle = (32'h00000051 >> (32 - PH_BITS));   //tan = 1/2^24 = 1/16777216
		5'b11000: tanangle = (32'h00000029 >> (32 - PH_BITS));   //tan = 1/2^25 = 1/33554432
		5'b11001: tanangle = (32'h00000014 >> (32 - PH_BITS));   //tan = 1/2^26 = 1/67108864
		5'b11010: tanangle = (32'h0000000a >> (32 - PH_BITS));   //tan = 1/2^27 = 1/134217728
		5'b11011: tanangle = (32'h00000005 >> (32 - PH_BITS));   //tan = 1/2^28 = 1/268435456
		5'b11100: tanangle = (32'h00000003 >> (32 - PH_BITS));   //tan = 1/2^29 = 1/536870912
		5'b11101: tanangle = (32'h00000001 >> (32 - PH_BITS));   //tan = 1/2^30 = 1/1073741824
		5'b11110: tanangle = (32'h00000001 >> (32 - PH_BITS));   //tan = 1/2^31 = 1/2147483648
		5'b11111: tanangle = (32'h00000000 >> (32 - PH_BITS));   //tan = 1/2^32 = 1/4294967296
	endcase
end
endfunction

reg        [1:0] data_in_buff [ITERATIONS:0];
reg signed [XY_BITS-1:0]   x  [ITERATIONS:0];
reg signed [XY_BITS-1:0]   y  [ITERATIONS:0];
reg signed [PH_BITS-1:0]   z  [ITERATIONS:0];

integer m;
initial begin
	for (m = 0; m<=ITERATIONS; m=m+1) begin
		x[m] = 0;
	end    
end

integer n;
initial begin
	for (n = 0; n<=ITERATIONS; n=n+1) begin
		y[n] = 0;
	end    
end

integer s;
initial begin
	for (s = 0; s<=ITERATIONS; s=s+1) begin
		z[s] = 0;
	end    
end

integer k;
initial begin
	for (k = 0; k<=ITERATIONS; k=k+1) begin
		data_in_buff[k] = 0;
	end    
end

genvar i;
generate for(i=0;i<ITERATIONS;i=i+1) begin : CORDIC
always @ (posedge clk) begin
    if (RST) begin
      x[i+1] <= 0;
      y[i+1] <= 0;
      z[i+1] <= 0;
    end 
    else begin
		if (CORDIC_STYLE == "ROTATE") begin
			if (z[i] < 0) begin
				x[i+1] <= x[i] + (y[i]>>>i); 
				y[i+1] <= y[i] - (x[i]>>>i); 
				z[i+1] <= z[i] + tanangle(i);
			end 
			else begin
				x[i+1] <= x[i] - (y[i]>>>i); 
				y[i+1] <= y[i] + (x[i]>>>i); 
				z[i+1] <= z[i] - tanangle(i);
			end
	    end		
		else if(CORDIC_STYLE == "VECTOR") begin
			if (y[i] > 0) begin
				x[i+1] <= x[i] + (y[i]>>>i); 
				y[i+1] <= y[i] - (x[i]>>>i); 
				z[i+1] <= z[i] + tanangle(i);
			end else begin
				x[i+1] <= x[i] - (y[i]>>>i); 
				y[i+1] <= y[i] + (x[i]>>>i); 
				z[i+1] <= z[i] - tanangle(i);
			end
		end
	end
end
always @ (posedge clk) begin
	data_in_buff[i+1]  <= data_in_buff[i];
end
end 
endgenerate

generate if (CORDIC_STYLE == "ROTATE") begin : IQ_Gen
reg [PH_BITS - 1 : 0] Phase_input = 0;
if (PHASE_ACC == "ON") begin
	reg [PH_BITS - 1 : 0] addr_r0 = 0;
	always @(posedge clk) begin
		addr_r0 <= addr_r0 + phase_in;
	end
	always @(posedge clk) begin
		Phase_input <= addr_r0;
	end
end
else if (PHASE_ACC == "OFF") begin
	always @(posedge clk) begin
		Phase_input <= phase_in;
	end
end
always @(posedge clk) begin
	if(valid_in & (~RST)) begin
		x[0] <= K_COS;
		y[0] <= 0;
		z[0] <= Phase_input[PH_BITS - 3 : 0];
		data_in_buff[0] <= Phase_input[PH_BITS - 1 : PH_BITS - 2];
	end
	else begin
		x[0] <= 0;
		y[0] <= 0;
		z[0] <= 0;
		data_in_buff[0] <= 0;
	end
end
reg signed [XY_BITS-1:0] cos = 0;
reg signed [XY_BITS-1:0] sin = 0;
always @ (posedge clk) begin
	case(data_in_buff[ITERATIONS]) 
	2'b00:begin //if the phase is in first quadrant,the sin(X)=sin(A),cos(X)=cos(A)
	        cos <= x[ITERATIONS];
	        sin <= y[ITERATIONS];
	      end
	2'b01:begin //if the phase is in second quadrant,the sin(X)=sin(A+90)=cosA,cos(X)=cos(A+90)=-sinA
	        cos <= ~(y[ITERATIONS]) + 1'b1;//-sin
	        sin <= x[ITERATIONS];//cos
	      end
	2'b10:begin //if the phase is in third quadrant,the sin(X)=sin(A+180)=-sinA,cos(X)=cos(A+180)=-cosA
	        cos <= ~(x[ITERATIONS]) + 1'b1;//-cos
	        sin <= ~(y[ITERATIONS]) + 1'b1;//-sin
	      end
	2'b11:begin //if the phase is in forth quadrant,the sin(X)=sin(A+270)=-cosA,cos(X)=cos(A+270)=sinA
	        cos <= y[ITERATIONS];//sin
	        sin <= ~(x[ITERATIONS]) + 1'b1;//-cos
	      end
	endcase
end
assign x_o = cos;
assign y_o = sin;
assign phase_out = z[ITERATIONS];
end
endgenerate

generate if (CORDIC_STYLE == "VECTOR") begin : Demodule_Gen
localparam signed [PH_BITS-1:0] PHASE_COE = (2**(PH_BITS-2)) - 1;
//localparam MODUIUS_COE = ;
always @(posedge clk) begin
	if(valid_in & (~RST)) begin
		case ({x_i[XY_BITS-1],y_i[XY_BITS-1]}) 
		    2'b00 : begin   x[0] <=  {x_i[XY_BITS-1],x_i[XY_BITS-1:1]}; 
						    y[0] <=  {y_i[XY_BITS-1],y_i[XY_BITS-1:1]}; end
		    2'b01 : begin   x[0] <=  {x_i[XY_BITS-1],x_i[XY_BITS-1:1]}; 
			                y[0] <=  {y_i[XY_BITS-1],y_i[XY_BITS-1:1]}; end
		    2'b10 : begin   x[0] <=  {y_i[XY_BITS-1],y_i[XY_BITS-1:1]}; 
			                y[0] <= -{x_i[XY_BITS-1],x_i[XY_BITS-1:1]}; end
		    2'b11 : begin   x[0] <= -{y_i[XY_BITS-1],y_i[XY_BITS-1:1]}; 
			                y[0] <=  {x_i[XY_BITS-1],x_i[XY_BITS-1:1]}; end
		    default : begin x[0] <=  {x_i[XY_BITS-1],x_i[XY_BITS-1:1]}; 
			                y[0] <=  {y_i[XY_BITS-1],y_i[XY_BITS-1:1]}; end
		endcase
		z[0] <= phase_in;
		data_in_buff[0] <= {x_i[XY_BITS-1],y_i[XY_BITS-1]};
    end
	else begin
		x[0] <= 0;
		y[0] <= 0;
		z[0] <= 0;
		data_in_buff[0] <= 0;
	end
end
reg        [XY_BITS*2-1:0] Modulus = 0;
wire       [XY_BITS*2-1:0] Modulus_buf;
reg signed [PH_BITS - 1:0] phase_r = 0;
always @ (posedge clk) begin
	case(data_in_buff[ITERATIONS]) 
		2'b00:begin phase_r <= $signed(z[ITERATIONS]); end
		2'b01:begin phase_r <= $signed(z[ITERATIONS]); end
		2'b10:begin phase_r <= $signed(z[ITERATIONS]) + $signed(PHASE_COE); end
		2'b11:begin phase_r <= $signed(z[ITERATIONS]) - $signed(PHASE_COE); end
	endcase
	Modulus[XY_BITS:0] <= x[ITERATIONS];
end
assign Modulus_buf = (Modulus * 32'd39797)>>15;
assign x_o = Modulus_buf[XY_BITS-1:0];
assign y_o = y[ITERATIONS];
assign phase_out = phase_r;
end
endgenerate

reg [ITERATIONS+1:0] v = 0;
always @ (posedge clk) begin
	if (RST) 
		v <= 0;
	else begin
		v <= v << 1;
		v[0] <= valid_in;
	end
end
assign valid_out = v[ITERATIONS+1];

endmodule
