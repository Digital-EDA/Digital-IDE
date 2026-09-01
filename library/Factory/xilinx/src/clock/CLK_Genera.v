//============================================================================================
/*
 * @Author       : sterben(Duan)
 * #LastAuthor   : sterben(Duan)
 * @Date         : 2019-09-27 00:00:20
 * #lastTime     : 2020-02-04 13:50:46
 * @FilePath     : src\Baise_Apply\CLK\CLK_GEN.v
 * @Description  :            
 */
//============================================================================================

module CLK_Genera #(
        // Multiplication
        parameter MULTIPL     = 20,
        parameter DIVCLK_DIV  = 1,

        parameter CLKOUT0_DIV = 2,
        parameter CLKOUT1_DIV = 4,
        parameter CLKOUT2_DIV = 5,
        parameter CLKOUT3_DIV = 10,
        parameter CLKOUT4_DIV = 20,
        parameter CLKOUT5_DIV = 1
    ) (
        input       clk_in,

        output      clk_out0,
        output      clk_out1,
        output      clk_out2,
        output      clk_out3,
        output      clk_out4,
        output      clk_out5,

        input       rstn,
        input       start_sig,
        output      locked,

        input [5:0] High_Time,
        input [5:0] Low_Time,
        input [5:0] Phase
    );



    /***************************************************/
    //define the data lock
    reg  start_sig_r;
    reg  start_sig_buf;
    wire start_sig_pose = start_sig_r & ~start_sig_buf;
    always@(posedge clk_in)
    begin
        start_sig_r   <= start_sig;
        start_sig_buf <= start_sig_r;
    end
    /***************************************************/

    /***************************************************/
    //define the state
    reg        den_r   = 0;
    reg        dwe_r   = 0;
    reg        dclk_r  = 0;
    reg        reset_r = 0;

    reg [3:0]  state   = 0;
    reg [6:0]  addr    = 0;
    reg [15:0] din_r   = 0;
    reg [15:0] dout_r  = 0;

    wire [6:0]  daddr;
    wire [15:0] din;
    wire [15:0] dout;

    wire        reset;
    wire        dclk;
    wire        dwe;
    wire        den; 
    wire        drdy; 
    
    always@(posedge clk_in or negedge rstn) begin
        if (!rstn) begin
            addr   <= 7'd0;
            din_r  <= 16'd0;
            dout_r <= 16'd0;
        end
        else begin
            case(state)
                4'd0:begin  if(start_sig_pose)begin 
                                reset_r<=1'b1;        				 
                                dclk_r <=1'b1;
                                den_r  <=1'b1; 
                                addr   <=7'h08;
                                state  <=state+1;
                                end 
                            end
                4'd1:begin  dclk_r<=1'b0;
                            state <=state+1; 
                            end
                4'd2:begin  dclk_r<=1'b1;
                            den_r <=1'b0;
                            if (drdy)begin
                                state <=state+1;
                                end
                            else begin
                                state <=4'd1;
                                end                                         
                            end
                4'd3:begin  dclk_r<=1'b0; 
                            dout_r<=dout|16'hefff;
                            state <=state+1; 
                            end
                4'd4:begin  dclk_r<=1'b1; 
                            dwe_r <=1'b1;
                            den_r <=1'b1; 
                            din_r <=dout_r&{4'b0001,High_Time,Low_Time}; 
                            state <=state+1; 
                            end
                4'd5:begin  dclk_r <=1'b0;  
                            state  <=state+1;
                            end
                4'd6:begin  dclk_r<=1'b1;
                            den_r  <=1'b0;
                            dwe_r  <=1'b0;
                            if (drdy)begin
                                state <=state+1;
                                end
                            else begin
                                state <=4'd5;
                                end                                         
                            end
                4'd7:begin  dclk_r<=1'b0; 
                            state <=state+1; 
                            end                        
                4'd8:begin  dclk_r<=1'b1; 
                            den_r <=1'b1;
                            addr  <=7'h09;
                            state <=state+1; 
                            end
                4'd9:begin  dclk_r <=1'b0;  
                            state  <=state+1;  
                            end
                4'd10:begin dclk_r <=1'b1;
                            den_r  <=1'b0;
                            if (drdy)begin
                                state <=state+1;
                                end
                            else begin
                                state <=4'd9;
                                end                                         
                            end
                4'd11:begin dclk_r<=1'b0; 
                            dout_r<=dout|16'h7fff;
                            state <=state+1; 
                            end
                4'd12:begin dclk_r<=1'b1; 
                            dwe_r <=1'b1;
                            den_r <=1'b1; 
                            din_r <=dout_r&{10'b1000010000,Phase};
                            state <=state+1; 
                            end
                4'd13:begin dclk_r <=1'b0;
                            state  <=state+1;  
                            end
                4'd14:begin dclk_r<=1'b1;
                            den_r  <=1'b0;
                            dwe_r  <=1'b0;
                            if (drdy)begin
                                state <=state+1;
                                end
                            else begin
                                state <=4'd13;
                                end                                         
                            end
                4'd15:begin dclk_r<=1'b0; 
                            reset_r<=1'b0;
                            state <=1'b0; 
                            end 
                default:begin state <= 0; end
            endcase
        end
    end
                            
    /***************************************************/
    wire        CLKFBIN;
    wire        CLKFBIN_buf;

    wire        CLKOUT0;
    wire        CLKOUT1;
    wire        CLKOUT2;
    wire        CLKOUT3;
    wire        CLKOUT4;
    wire        CLKOUT5;

    BUFG clkf_buf (
        .O (CLKFBIN_buf),
        .I (CLKFBIN)
    );

    //Clk_out=Clkin*MULT/DIVCLK_DIVIDE/CLKOUTx_DIVIDE;
    PLLE2_ADV #(
        .BANDWIDTH("OPTIMIZED"), //HIGH/LOW/OPTIMIZED
        .COMPENSATION("ZHOLD"), //SYSTEM_SYNCHRONOUS/SOURCE_SYNCHRONOUS/INTERNAL/EXTERNAL
        .STARTUP_WAIT("FALSE"),

        .CLKFBOUT_MULT(MULTIPL), //Multiplication factor for all output clocks
        .DIVCLK_DIVIDE(DIVCLK_DIV), //division factor for all clocks (1 to 52)
        .CLKFBOUT_PHASE(0.000), //Phase shift degress of all output clocks
        .REF_JITTER(0.100), //input reference jitter (0.000 to 0.999 U1%)

        .CLKIN1_PERIOD(20.000), //clock period(ns) of input clock on clkin 

        .CLKOUT0_DIVIDE(CLKOUT0_DIV), //Division factor for CLKOUT0 (1 to 28)
        .CLKOUT0_DUTY_CYCLE(0.5), //duty cycle for CLKOUT0 (0.01 TO 0.99)
        .CLKOUT0_PHASE(0.0), //phase shift degrees for CLK1UT0 (0.0 TO 360.0)

        .CLKOUT1_DIVIDE(CLKOUT1_DIV), //Division factor for CLKOUT1 (1 to 28)
        .CLKOUT1_DUTY_CYCLE(0.5), //duty cycle for CLKOUT1 (0.01 TO 0.99)
        .CLKOUT1_PHASE(0.0), //phase shift degrees for CLKOUT2 (0.0 TO 360.0)

        .CLKOUT2_DIVIDE(CLKOUT2_DIV), //Division factor for CLKOUT2 (1 to 28)
        .CLKOUT2_DUTY_CYCLE(0.5), //duty cycle for CLKOUT2 (0.01 TO 0.99)
        .CLKOUT2_PHASE(0.0), //phase shift degrees for CLKOUT2 (0.0 TO 360.0)

        .CLKOUT3_DIVIDE(CLKOUT3_DIV), //Division factor for CLKOUT3 (1 to 28)
        .CLKOUT3_DUTY_CYCLE(0.5), //duty cycle for CLKOUT3 (0.01 TO 0.99)
        .CLKOUT3_PHASE(0.0), //phase shift degrees for CLKOUT3 (0.0 TO 360.0)

        .CLKOUT4_DIVIDE(CLKOUT4_DIV), //Division factor for CLKOUT4 (1 to 28)
        .CLKOUT4_DUTY_CYCLE(0.5), //duty cycle for CLKOUT4 (0.01 TO 0.99)
        .CLKOUT4_PHASE(0.0), //phase shift degrees for CLKOUT4 (0.0 TO 360.0)

        .CLKOUT5_DIVIDE(CLKOUT5_DIV), //Division factor for CLKOUT5 (1 to 28)
        .CLKOUT5_DUTY_CYCLE(0.5), //duty cycle for CLKOUT5 (0.01 TO 0.99)
        .CLKOUT5_PHASE(0.0))  //phase shift degrees for CLKOUT5 (0.0 TO 360.0)
    pll_inst (
        .CLKIN1   ( clk_in ), //clock input 
        .CLKIN2   (  1'b0  ),
        .RST      ( reset  ), //asynchronous pll reset

        .CLKOUT0  ( CLKOUT0 ),
        .CLKOUT1  ( CLKOUT1 ),
        .CLKOUT2  ( CLKOUT2 ),
        .CLKOUT3  ( CLKOUT3 ),
        .CLKOUT4  ( CLKOUT4 ),
        .CLKOUT5  ( CLKOUT5 ),
        // Tied to always select the primary input clock
        .CLKINSEL            (1'b1),
        // Ports for dynamic reconfiguration
        .DADDR    ( daddr ),
        .DCLK     ( dclk  ),
        .DEN      ( den   ),
        .DI       ( din   ),
        .DO       ( dout  ),
        .DRDY     ( drdy  ),
        .DWE      ( dwe   ),

        .LOCKED   ( locked ),
        .PWRDWN   ( 1'b0),
        .CLKFBIN  ( CLKFBIN_buf ), //CLOCK feedback input 
        .CLKFBOUT ( CLKFBIN )      //General output feedback signall 
    );

    assign reset = reset_r;

    assign dclk  = dclk_r;
    assign dwe   = dwe_r;
    assign den   = den_r;

    assign daddr = addr;
    assign din   = din_r;

    BUFG clkout0_buf (
        .O   (clk_out0),
        .I   (CLKOUT0)
    );

    BUFG clkout1_buf (
        .O   (clk_out1),
        .I   (CLKOUT1)
    );

    BUFG clkout2_buf (
        .O   (clk_out2),
        .I   (CLKOUT2)
    );

    BUFG clkout3_buf (
        .O   (clk_out3),
        .I   (CLKOUT3)
    );

    BUFG clkout4_buf (
        .O   (clk_out4),
        .I   (CLKOUT4)
    );

    BUFG clkout5_buf (
        .O   (clk_out5),
        .I   (CLKOUT5)
    );

endmodule