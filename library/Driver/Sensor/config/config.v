module cmos_config #(
    parameter    CMOS_TYPE  = "ov5640",
    parameter    DATA_TYPE  = "rgb565",
    parameter    CLOCK_MAIN = 100_000
) (
    input   sys_clk,
    input   sys_rstn,

	output  cmos_sclk,		//cmos i2c clock
	inout   cmos_sdat,		//cmos i2c data

    output  i2c_config_done
);

    localparam SIZE_WIDTH = (CMOS_TYPE == "ov5640")  ? 8 : 
                            (CMOS_TYPE == "ov7725")  ? 7 :
                            (CMOS_TYPE == "mt9v304") ? 7 : 8;
    localparam DATA_WIDTH = (CMOS_TYPE == "ov5640")  ? 23 : 
                            (CMOS_TYPE == "ov7725")  ? 15 :
                            (CMOS_TYPE == "mt9v304") ? 23 : 23;

    wire [SIZE_WIDTH:0]	LUT_INDEX;
    wire [SIZE_WIDTH:0]	LUT_SIZE;
    wire [DATA_WIDTH:0]	LUT_DATA;
    
    generate 
        if(CMOS_TYPE == "ov5640") begin : ov5640
            if(DATA_TYPE == "rgb565") begin : ov5640_rgb565
                OV5640_RGB565_Config u_OV5640_RGB565_Config(
                    //ports
                    .LUT_INDEX 		( LUT_INDEX 		),
                    .LUT_DATA  		( LUT_DATA  		),
                    .LUT_SIZE  		( LUT_SIZE  		)
                );
            end    
            else if(DATA_TYPE == "raw") begin : ov5640_raw
                OV5640_RAW_Config u_OV5640_RAW_Config(
                    //ports
                    .LUT_INDEX 		( LUT_INDEX 		),
                    .LUT_DATA  		( LUT_DATA  		),
                    .LUT_SIZE  		( LUT_SIZE  		)
                );
            end
        end
        else if(CMOS_TYPE == "ov7725") begin : ov7725
            if(DATA_TYPE == "rgb565") begin : ov7725_rgb565
                OV7725_RGB565_Config u_OV7725_RGB565_Config(
                    //ports
                    .LUT_INDEX 		( LUT_INDEX 		),
                    .LUT_DATA  		( LUT_DATA  		),
                    .LUT_SIZE  		( LUT_SIZE  		)
                );
            end    
            else if(DATA_TYPE == "raw") begin : ov7725_raw
                OV7725_RAW_Config u_OV7725_RAW_Config(
                    //ports
                    .LUT_INDEX 		( LUT_INDEX 		),
                    .LUT_DATA  		( LUT_DATA  		),
                    .LUT_SIZE  		( LUT_SIZE  		)
                );
            end
            else if(DATA_TYPE == "yuv422") begin : ov7725_yuv422
                OV7725_YUV422_Config u_OV7725_YUV422_Config(
                    //ports
                    .LUT_INDEX 		( LUT_INDEX 		),
                    .LUT_DATA  		( LUT_DATA  		),
                    .LUT_SIZE  		( LUT_SIZE  		)
                );
            end
        end
        else if(CMOS_TYPE == "mt9v304") begin : mt9v304
            if(DATA_TYPE == "raw") begin : mt9v304_raw
                MT9V034_RAW_Config u_MT9V034_RAW_Config(
                    //ports
                    .LUT_INDEX 		( LUT_INDEX 		),
                    .LUT_DATA  		( LUT_DATA  		),
                    .LUT_SIZE  		( LUT_SIZE  		)
                );
            end
        end
    endgenerate
        
    generate 
        if(CMOS_TYPE == "ov5640") begin : i2c_ov5640
            wire	[15:0]	i2c_rdata;		//i2c register data
            i2c_16b #(
                .CLK_FREQ	(CLOCK_MAIN),	//100 MHz
                .I2C_FREQ	(100_000))		//100 kHz(<= 400KHz)
            u_i2c_16b (
                //global clock
                .clk				(sys_clk),		//100MHz
                .rst_n				(sys_rstn),	//system reset
                        
                //i2c interface
                .i2c_sclk			(cmos_sclk),	//i2c clock
                .i2c_sdat			(cmos_sdat),	//i2c data for bidirection

                //i2c config data
                .i2c_config_index	(LUT_INDEX),	//i2c config reg index, read 2 reg and write xx reg
                .i2c_config_data	({8'h78, LUT_DATA}),	//i2c config data
                .i2c_config_size	(LUT_SIZE),	//i2c config data counte
                .i2c_config_done	(i2c_config_done),	//i2c config timing complete
                .i2c_rdata			(i2c_rdata)			//i2c register data while read i2c slave
            );
        end
        else if(CMOS_TYPE == "ov7725") begin : i2c_ov7725
            wire	[7:0]	i2c_rdata;		//i2c register data
            i2c_8b #(
                .CLK_FREQ	(CLOCK_MAIN),	//100 MHz
                .I2C_FREQ	(100_000))		//100 kHz(<= 400KHz)
            u_i2c_8b (
                //global clock
                .clk				(sys_clk),		//100MHz
                .rst_n				(sys_rstn),	//system reset
                        
                //i2c interface
                .i2c_sclk			(cmos_sclk),	//i2c clock
                .i2c_sdat			(cmos_sdat),	//i2c data for bidirection

                //i2c config data
                //i2c config reg index, read 2 reg and write xx reg
                .i2c_config_index	(LUT_INDEX),	
                .i2c_config_data	({8'h42, LUT_DATA}),	//TODO: i2c config data
                .i2c_config_size	(LUT_SIZE),	//i2c config data counte
                .i2c_config_done	(i2c_config_done),	//i2c config timing complete
                .i2c_rdata			(i2c_rdata)			//i2c register data while read i2c slave
            );
        end
    endgenerate
endmodule  //cmos_config
