module ov5640_dri #(
    parameter CLK_FREQ    = 26'd50_000_000,
    parameter I2C_FREQ    = 19'd250_000,
	parameter DEVICE_ADDR = 7'h3c
) (
    input             sys_clk,
    input             sys_rst,

	//pixel
    input   [12:0]    cmos_h_pixel ,
    input   [12:0]    cmos_v_pixel ,
    input   [12:0]    total_h_pixel,
    input   [12:0]    total_v_pixel,

	//camera
	input			  cam_pclk,
	input			  cam_vsync,
	input			  cam_href,
	input	[7:0]	  cam_data,

	output			  cam_reset,
    output            cam_scl,
    inout             cam_sda,

    output            init_done,

	//cmos_frame
	output        	  cmos_frame_vsync,
	output        	  cmos_frame_href,
	output        	  cmos_frame_valid,
	output  [15:0] 	  cmos_frame_data
);

wire [7:0]  	iic_data_out;
wire        	iic_ack;
wire        	iic_done;
wire        	dri_clk;

wire        	iic_exe;
wire [23:0] 	iic_data;
wire        	iic_rw_ctrl;

assign 			cam_reset = 1'b1;

ov5640_cfg u_ov5640_cfg(
	.sys_clk       	( sys_clk        ),
	.iic_clk       	( dri_clk        ),
	.sys_rst       	( sys_rst        ),
	
    .iic_data_r    	( iic_data_out   ),
	.iic_done      	( iic_done       ),
	.cmos_h_pixel  	( cmos_h_pixel   ),
	.cmos_v_pixel  	( cmos_v_pixel   ),
	.total_h_pixel 	( total_h_pixel  ),
	.total_v_pixel 	( total_v_pixel  ),
	
    .iic_exe       	( iic_exe        ),
	.iic_data      	( iic_data       ),
	.iic_rw_ctrl   	( iic_rw_ctrl    ),
	.init_done     	( init_done      ));

iic_driver #(
	.DEVICE_ADDR 	( 7'h3c         ),
	.CLK_FREQ    	( CLK_FREQ      ),
	.I2C_FREQ    	( I2C_FREQ      ),
	.PROTOCOL    	( "SCCB"        ))
u_iic_driver(
	.sys_clk      	( sys_clk       ),
	.sys_rst      	( sys_rst       ),
	
    .bit_ctrl     	( 1'b1          ),
	.iic_exe      	( iic_exe       ),
	.iic_rw_ctrl  	( iic_rw_ctrl   ),
	.iic_addr     	( iic_data[23:8]),
	.iic_data_in  	( iic_data[7:0] ),
	
    .iic_data_out 	( iic_data_out  ),
	.iic_ack      	( iic_ack       ),
	.iic_done     	( iic_done      ),
	.scl          	( cam_scl       ),
	.sda          	( cam_sda       ),
	.dri_clk      	( dri_clk       ));

cmos_capture_data u_cmos_capture_data(
	.rst_n            	( sys_rst           ),
	
	.cam_pclk         	( cam_pclk          ),
	.cam_vsync        	( cam_vsync         ),
	.cam_href         	( cam_href          ),
	.cam_data         	( cam_data          ),
	
	.cmos_frame_vsync 	( cmos_frame_vsync  ),
	.cmos_frame_href  	( cmos_frame_href   ),
	.cmos_frame_valid 	( cmos_frame_valid  ),
	.cmos_frame_data  	( cmos_frame_data   ));

endmodule  //ov5640_dri
