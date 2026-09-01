`timescale 1ns/1ns
module	OV7725_RAW_Config (
	input		[7:0]	LUT_INDEX,
	output	reg	[15:0]	LUT_DATA,
	output		[7:0]	LUT_SIZE
);

assign	LUT_SIZE = 8'd70;

//-----------------------------------------------------------------
/////////////////////	Config Data LUT	  //////////////////////////	
always@(*) begin
	case(LUT_INDEX)
//	OV7725 : VGA RGB565 Config
	//Read Data Index
//	0 :		LUT_DATA	=	{8'h0A, 8'h77};	//Product ID Number MSB (Read only)
//	1 :		LUT_DATA	=	{8'h0B, 8'h21};	//Product ID Number LSB (Read only)
	0 :		LUT_DATA	=	{8'h1C, 8'h7F};	//Manufacturer ID Byte - High (Read only)
	1 :		LUT_DATA	=	{8'h1D, 8'hA2};	//Manufacturer ID Byte - Low (Read only)
	//Write Data Index
	2	: 	LUT_DATA	= 	{8'h12, 8'h80};	// BIT[7]-Reset all the Reg 
	3 	: 	LUT_DATA	= 	{8'h3d, 8'h03};	//DC offset for analog process
	4 	: 	LUT_DATA	= 	{8'h15, 8'h02};	//COM10: href/vsync/pclk/data reverse(Vsync H valid)
	5 	: 	LUT_DATA	= 	{8'h17, 8'h22};	//VGA:	8'h22;	QVGA:	8'h3f;
	6 	: 	LUT_DATA	= 	{8'h18, 8'ha4};	//VGA:	8'ha4;	QVGA:	8'h50;
	7 	: 	LUT_DATA	=	{8'h19, 8'h07};	//VGA:	8'h07;	QVGA:	8'h03;
	8 	: 	LUT_DATA	= 	{8'h1a, 8'hf0};	//VGA:	8'hf0;	QVGA:	8'h78;
	9 	: 	LUT_DATA	= 	{8'h32, 8'h00};	//Bit[7]:Mirror image edge alignment 
	10	:	LUT_DATA 	= 	{8'h29, 8'hA0};	//VGA:	8'hA0;	QVGA:	8'hF0
	11	:	LUT_DATA 	= 	{8'h2C, 8'hF0};	//VGA:	8'hF0;	QVGA:	8'h78
	12	:	LUT_DATA	=	{8'h0d, 8'h41};	//Bypass PLL
	13	: 	LUT_DATA	= 	{8'h11, 8'h01};	//CLKRC,Finternal clock = Finput clk*PLL multiplier/[(CLKRC[5:0]+1)*2] = 25MHz*4/[(x+1)*2]
											//00: 50fps, 01:25fps, 03:12.5fps	(50Hz Fliter)
	14	: 	LUT_DATA	= 	{8'h12, 8'h03};	//BIT[6]:	0:VGA; 1;QVGA
											//BIT[3:2]:	01:RGB565
											//VGA:	00:YUV; 01:Processed Bayer RGB; 10:RGB;	11:Bayer RAW; BIT[7]-Reset all the Reg 
	15 	: 	LUT_DATA	= 	{8'h0c, 8'h10};	//COM3: Bit[7:6]:Vertical/Horizontal mirror image ON/OFF, Bit[0]:Color bar; Default:8'h10
	//DSP control
	16 	: 	LUT_DATA	= 	{8'h42, 8'h7f};	//BLC Blue Channel Target Value, Default: 8'h80
	17 	: 	LUT_DATA	= 	{8'h4d, 8'h09};	//BLC Red Channel Target Value, Default: 8'h80
	18	: 	LUT_DATA	= 	{8'h63, 8'hf0};	//AWB Control
	19	: 	LUT_DATA	= 	{8'h64, 8'hff};	//DSP_Ctrl1:
	20	: 	LUT_DATA	= 	{8'h65, 8'h00};	//DSP_Ctrl2:	
	21	: 	LUT_DATA	= 	{8'h66, 8'h00};	//{COM3[4](0x0C), DSP_Ctrl3[7]}:00:YUYV;	01:YVYU;	[10:UYVY]	11:VYUY	
	22 	: 	LUT_DATA	= 	{8'h67, 8'h02};	//DSP_Ctrl4:[1:0]00/01: YUV or RGB; 10: RAW8; 11: RAW10	
    //AGC AEC AWB
	23	:	LUT_DATA	=	{8'h13, 8'hff};
	24	:	LUT_DATA	=	{8'h0f, 8'hc5};
	25	:	LUT_DATA	=	{8'h14, 8'h11};
	26	:	LUT_DATA	=	{8'h22, 8'h98};	//Banding Filt er Minimum AEC Value; Default: 8'h09
	27	:	LUT_DATA	=	{8'h23, 8'h03};	//Banding Filter Maximum Step
	28	:	LUT_DATA	=	{8'h24, 8'h40};	//AGC/AEC - Stable Operating Region (Upper Limit)
	29	:	LUT_DATA	=	{8'h25, 8'h30};	//AGC/AEC - Stable Operating Region (Lower Limit)
	30	:	LUT_DATA	=	{8'h26, 8'ha1};	//AGC/AEC Fast Mode Operating Region
	31	:	LUT_DATA	=	{8'h2b, 8'h9e};	//TaiWan: 8'h00:60Hz Filter; Mainland: 8'h9e:50Hz Filter
	32	:	LUT_DATA	=	{8'h6b, 8'haa};	//AWB Control 3
	33	:	LUT_DATA	=	{8'h13, 8'hff};	//8'hff: AGC AEC AWB Enable; 8'hf0: AGC AEC AWB Disable;
	//matrix sharpness brightness contrast UV	
	34 	: 	LUT_DATA	= 	{8'h90, 8'h0a};	
	35 	: 	LUT_DATA	= 	{8'h91, 8'h01};
	36 	: 	LUT_DATA	= 	{8'h92, 8'h01};
	37 	: 	LUT_DATA	= 	{8'h93, 8'h01};
	38 	: 	LUT_DATA	= 	{8'h94, 8'h5f};
	39 	: 	LUT_DATA	= 	{8'h95, 8'h53};
	40 	: 	LUT_DATA	= 	{8'h96, 8'h11};
	41 	: 	LUT_DATA	= 	{8'h97, 8'h1a};
	42 	: 	LUT_DATA	= 	{8'h98, 8'h3d};
	43 	: 	LUT_DATA	= 	{8'h99, 8'h5a};
	44 	: 	LUT_DATA	= 	{8'h9a, 8'h1e};
	45 	: 	LUT_DATA	= 	{8'h9b, 8'h3f};	//Brightness 
	46 	: 	LUT_DATA	= 	{8'h9c, 8'h25};
	47 	: 	LUT_DATA	= 	{8'h9e, 8'h81};	
	48 	: 	LUT_DATA	= 	{8'ha6, 8'h06};
	49 	: 	LUT_DATA	= 	{8'ha7, 8'h65};
	50 	: 	LUT_DATA	= 	{8'ha8, 8'h65};
	51 	: 	LUT_DATA	= 	{8'ha9, 8'h80};
	52 	: 	LUT_DATA	= 	{8'haa, 8'h80};
	//Gamma correction
	53 	: 	LUT_DATA	= 	{8'h7e, 8'h0c};
	54 	: 	LUT_DATA	= 	{8'h7f, 8'h16};	//
	55 	: 	LUT_DATA	= 	{8'h80, 8'h2a};
	56 	: 	LUT_DATA	= 	{8'h81, 8'h4e};
	57 	: 	LUT_DATA	= 	{8'h82, 8'h61};
	58 	: 	LUT_DATA	= 	{8'h83, 8'h6f};
	59 	: 	LUT_DATA	= 	{8'h84, 8'h7b};
	60 	: 	LUT_DATA	= 	{8'h85, 8'h86};
	61 	: 	LUT_DATA	= 	{8'h86, 8'h8e};
	62 	: 	LUT_DATA	= 	{8'h87, 8'h97};
	63 	: 	LUT_DATA	= 	{8'h88, 8'ha4};
	64 	: 	LUT_DATA	= 	{8'h89, 8'haf};
	65 	: 	LUT_DATA	= 	{8'h8a, 8'hc5};
	66 	: 	LUT_DATA	= 	{8'h8b, 8'hd7};
	67 	: 	LUT_DATA	= 	{8'h8c, 8'he8};
	68 	: 	LUT_DATA	= 	{8'h8d, 8'h20};
	//Others
	69	:	LUT_DATA	=	{8'h0e, 8'h65};//night mode auto frame rate control
	default:LUT_DATA	=	{8'h1C, 8'h7F};
	endcase
end

endmodule
