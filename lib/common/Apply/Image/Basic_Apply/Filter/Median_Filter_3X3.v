`timescale 1ns/1ns
module	Median_Filter_3X3 (
	input			    clk,
	input			    rst_n,

	input		[7:0]	data11, data12, data13,
	input		[7:0]	data21, data22, data23,
	input		[7:0]	data31, data32, data33,
	
	output		[7:0]	target_data
);

//--------------------------------------------------------------------------------------
//FPGA Median Filter Sort order
//	  	   Pixel				 Sort1					  Sort2				 Sort3
//	[   P1  P2   P3 ]	[   Max1  Mid1   Min1 ]	
//	[   P4  P5   P6 ]	[   Max2  Mid2   Min2 ]	[Max_min, Mid_mid, Min_max]	mid_valid
//	[   P7  P8   P9 ]	[   Max3  Mid3   Min3 ]

//Step1
wire	[7:0]	max_data1, mid_data1, min_data1;
Sort3	u_Sort3_1 (
	.clk		(clk),
	.rst_n		(rst_n),
	
	.data1		(data11), 
	.data2		(data12), 
	.data3		(data13),
	
	.max_data	(max_data1),
	.mid_data	(mid_data1),
	.min_data   (min_data1)
);

wire	[7:0]	max_data2, mid_data2, min_data2;
Sort3	u_Sort3_2 (
	.clk		(clk),
	.rst_n		(rst_n),
	
	.data1		(data21), 
	.data2		(data22), 
	.data3		(data23),
	
	.max_data	(max_data2),
	.mid_data	(mid_data2),
	.min_data   (min_data2)
);

wire	[7:0]	max_data3, mid_data3, min_data3;
Sort3	u_Sort3_3 (
	.clk		(clk),
	.rst_n		(rst_n),
	
	.data1		(data31), 
	.data2		(data32), 
	.data3		(data33),
	
	.max_data	(max_data3),
	.mid_data	(mid_data3),
	.min_data	(min_data3)
);

//Step2
wire	[7:0]	max_min_data, mid_mid_data, min_max_data;
Sort3	u_Sort3_4 (
	.clk		(clk),
	.rst_n		(rst_n),
	
	.data1		(max_data1), 
	.data2		(max_data2), 
	.data3		(max_data3),
	
	.max_data	(),
	.mid_data	(),
	.min_data   (max_min_data)
);

Sort3	u_Sort3_5 (
	.clk		(clk),
	.rst_n		(rst_n),
	
	.data1		(mid_data1), 
	.data2		(mid_data2), 
	.data3		(mid_data3),
	
	.max_data	(),
	.mid_data	(mid_mid_data),
	.min_data   ()
);

Sort3	u_Sort3_6 (
	.clk		(clk),
	.rst_n		(rst_n),
	
	.data1		(min_data1), 
	.data2		(min_data2), 
	.data3		(min_data3),
	
	.max_data	(min_max_data),
	.mid_data	(),
	.min_data   ()
);

//step3
Sort3	u_Sort3_7 (
	.clk		(clk),
	.rst_n		(rst_n),
	
	.data1		(max_min_data), 
	.data2		(mid_mid_data), 
	.data3		(min_max_data),
	
	.max_data	(),
	.mid_data	(target_data),
	.min_data   ()
);

endmodule
