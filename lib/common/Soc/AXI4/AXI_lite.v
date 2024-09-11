`timescale 1 ns / 1 ps

module AXI #(
	parameter integer OUTPUT_WIDTH      	= 12,
	parameter integer PHASE_WIDTH        	= 32,
	parameter integer C_S_AXI_DATA_WIDTH	= 32,
	parameter integer C_S_AXI_ADDR_WIDTH	= 4
) (
	// Users to add ports here
	
	// User ports ends
	// Do not modify the ports beyond this line

	input  wire  S_AXI_ACLK, 
	input  wire  S_AXI_ARESETN,

	input  wire  S_AXI_WVALID,
	output wire  S_AXI_RVALID,
	output wire  S_AXI_WREADY,
	input  wire  S_AXI_RREADY,

	input  wire  S_AXI_AWVALID,
	input  wire  S_AXI_ARVALID,
	output wire  S_AXI_AWREADY,
	output wire  S_AXI_ARREADY,

	input  wire  [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
	input  wire  [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
	input  wire  [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
	output wire  [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,

	input  wire  [2 : 0] S_AXI_AWPROT,
	input  wire  [2 : 0] S_AXI_ARPROT,

	output wire  [1 : 0] S_AXI_BRESP,
	output wire  [1 : 0] S_AXI_RRESP,

	output wire  S_AXI_BVALID,
	input  wire  S_AXI_BREADY,

	input  wire  [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB
);

// AXI4LITE signals
reg  							axi_awready;
reg  							axi_arready;
reg  							axi_bvalid;
reg  							axi_rvalid;
reg  							axi_wready;

reg [1 : 0] 					axi_bresp;
reg [1 : 0] 					axi_rresp;

reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
// Example-specific design signals
// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB          = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 1;
//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
//-- Number of Slave Registers 4
reg	                          aw_en;
wire	                      slv_reg_rden;
wire	                      slv_reg_wren;
reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
reg  [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
reg  [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;

integer	                      byte_index;
// I/O Connections assignments

assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	    = axi_wready;
assign S_AXI_BRESP	    = axi_bresp;
assign S_AXI_BVALID	    = axi_bvalid;
assign S_AXI_ARREADY	= axi_arready;
assign S_AXI_RDATA	    = axi_rdata;
assign S_AXI_RRESP	    = axi_rresp;
assign S_AXI_RVALID	    = axi_rvalid;
// Implement axi_awready generation
// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
// de-asserted when reset is low.

always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		axi_awready <= 1'b0;
		aw_en <= 1'b1;
	end 
	else begin    
		if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
			axi_awready <= 1'b1;
			aw_en <= 1'b0;
		end
		else if (S_AXI_BREADY && axi_bvalid) begin
				aw_en <= 1'b1;
				axi_awready <= 1'b0;
		end
		else begin
			axi_awready <= 1'b0;
		end
	end 
end       

// Implement axi_awaddr latching
// This process is used to latch the address when both 
// S_AXI_AWVALID and S_AXI_WVALID are valid. 
always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		axi_awaddr <= 0;
	end 
	else begin    
		if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
			// Write Address latching 
			axi_awaddr <= S_AXI_AWADDR;
		end
	end 
end       

// Implement axi_wready generation
// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
// de-asserted when reset is low. 
always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		axi_wready <= 1'b0;
	end 
	else begin    
		if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en ) begin
			axi_wready <= 1'b1;
		end
		else begin
			axi_wready <= 1'b0;
		end
	end 
end       

// Implement write response logic generation
// The write response and response valid signals are asserted by the slave 
// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
// This marks the acceptance of address and indicates the status of 
// write transaction.

always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		axi_bvalid  <= 0;
		axi_bresp   <= 2'b0;
	end 
	else begin    
		if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
			// indicates a valid write response is available
			axi_bvalid <= 1'b1;
			axi_bresp  <= 2'b0; // 'OKAY' response 
		end                   // work error responses in future
		else begin
			if (S_AXI_BREADY && axi_bvalid) begin
				axi_bvalid <= 1'b0; 
			end  
		end
	end
end   

// Implement axi_arready generation
// axi_arready is asserted for one S_AXI_ACLK clock cycle when
// S_AXI_ARVALID is asserted. axi_awready is 
// de-asserted when reset (active low) is asserted. 
// The read address is also latched when S_AXI_ARVALID is 
// asserted. axi_araddr is reset to zero on reset assertion.

always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		axi_arready <= 1'b0;
		axi_araddr  <= 32'b0;
	end 
	else begin    
		if (~axi_arready && S_AXI_ARVALID) begin
			// indicates that the slave has acceped the valid read address
			axi_arready <= 1'b1;
			// Read address latching
			axi_araddr  <= S_AXI_ARADDR;
		end
		else begin
			axi_arready <= 1'b0;
		end
	end 
end       

// Implement axi_arvalid generation
// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
// data are available on the axi_rdata bus at this instance. The 
// assertion of axi_rvalid marks the validity of read data on the 
// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
// is deasserted on reset (active low). axi_rresp and axi_rdata are 
// cleared to zero on reset (active low).  
always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		axi_rvalid <= 0;
		axi_rresp  <= 0;
	end 
	else begin    
		if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
			// Valid read data is available at the read data bus
			axi_rvalid <= 1'b1;
			axi_rresp  <= 2'b0; // 'OKAY' response
		end   
		else if (axi_rvalid && S_AXI_RREADY) begin
			// Read data is accepted by the master
			axi_rvalid <= 1'b0;
		end                
	end
end    

// Output register or memory read data
always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		axi_rdata  <= 0;
	end 
	else begin    
		if (slv_reg_rden) begin
			axi_rdata <= reg_data_out;     // register read data
		end   
	end
end  

// Implement memory mapped register select and write logic generation
// The write data is accepted and written to memory mapped registers when
// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
// select byte enables of slave registers while writing.
// These registers are cleared when reset (active low) is applied.
// Slave register write enable is asserted when valid address and data are available
// and the slave is ready to accept the write address and write data.
assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

always @( posedge S_AXI_ACLK ) begin
	if ( S_AXI_ARESETN == 1'b0 ) begin
		slv_reg0 <= 0;
		slv_reg1 <= 0;
		slv_reg2 <= 0;
		slv_reg3 <= 0;
	end
	else begin
		if (slv_reg_wren) begin
			case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
				4'd0:for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
							slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
						end
				4'd1:for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
							slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
						end 
				4'd2:for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
							slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
						end
				4'd3:for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) begin
							slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
						end
				default : 
					begin
						slv_reg0 <= slv_reg0;
						slv_reg1 <= slv_reg1;
						slv_reg2 <= slv_reg2;
						slv_reg3 <= slv_reg3;
					end
			endcase
		end
	end
end    

// Implement memory mapped register select and read logic generation
// Slave register read enable is asserted when valid address is available
// and the slave is ready to accept the read address.
assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
always @(*) begin
	case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
		4'd0 : reg_data_out <= slv_reg0;
		4'd1 : reg_data_out <= slv_reg1;
		4'd2 : reg_data_out <= slv_reg2;
		4'd3 : reg_data_out <= slv_reg3;
		default : reg_data_out <= 0;
	endcase
end
  
// Add user logic here

// User logic ends

endmodule
