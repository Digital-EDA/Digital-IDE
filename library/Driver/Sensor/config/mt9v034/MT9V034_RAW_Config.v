`timescale 1ns/1ns
module	MT9V034_RAW_Config (
	input		[7:0]	LUT_INDEX,
	output	reg	[23:0]	LUT_DATA,
	output		[7:0]	LUT_SIZE
);

assign	LUT_SIZE = 8'd5;

//-----------------------------------------------------------------
/////////////////////	Config Data LUT	  //////////////////////////	
always@(*) begin
	case(LUT_INDEX)
//	MT9V034 Register
	//Read Data Index
	0	:	LUT_DATA	=	{8'hFE, 16'hBEEF};	//Register Lock Code(0xBEEF: unlocked, 0xDEAD: locked)
	1	:	LUT_DATA	=	{8'h00, 16'h1313};	//Chip Verision (Read only)
	//Write Data Index
	//[Reset Registers]
	2	: 	LUT_DATA	= 	{8'h0C, 16'h0001};	// BIT[1:0]-Reset the Registers, At least 15 clocks
	3 	: 	LUT_DATA	= 	{8'h0C, 16'h0000};	// BIT[1:0]-Reset the Registers
	//[Vertical/Hortical Mirror]
	4	:	LUT_DATA	= 	{8'h0D, 16'h0330};	// BIT[4] : ROW Flip;	BIT[5]:	Column Flip
										
	
	default:LUT_DATA	=	{8'h00, 16'h1313};	//Chip Verision (Read only)
	endcase
end

endmodule
