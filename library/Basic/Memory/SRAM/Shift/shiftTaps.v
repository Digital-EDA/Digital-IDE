`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   shiftTaps.v - shiftTaps
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : 
*                 1. In Vivado, EDA can directly use BRAM for synthesis.
*   Dependencies: none(FPGA) auto for BRAM in vivado | RAM_IP with IC 
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '101010101010101010101'},
  {name: 'case1:ivalid', wave: '01...................'},
  {name: 'case2:ivalid', wave: '101010101010101010101'},
  {name: 'idata', wave: 'x4.4.4.4.4.x.........', data: ['data0','data1','data2','data3','data4']},
  {name: 'ivalid', wave: '0........1...........'},
  {name: 'odata', wave: 'x........5.5.5.5.5.x.', data: ['data0','data1','data2','data3','data4']},
]}
*/
module shiftTaps #(
        // Depth threshold; when the depth is greater than or equal to this threshold, 
        // SDPRAM is instantiated.
        parameter THRES = 512,
        // Data width.
        parameter WIDTH = 16,
        // Delay or shift length.
        parameter SHIFT = 1024
    ) (
        // Clock input
        input                   clock,
        // Asynchronous reset with active high
        input                   reset,

        // @Flow input valid
        input                   ivalid, 
        // @Flow input shift data
        input  [WIDTH - 1 : 0]  shiftin,

        // @Flow output valid
        output                  ovalid, 
        // @Flow output data 
        output [WIDTH - 1 : 0]  shiftout
    );

    localparam DELAY  = ((SHIFT - 1) > 0) ? (SHIFT - 1) : 0;
    localparam VALID  = (DELAY > 0) ? (DELAY - 1) : 0;
    localparam CWIDTH = ($clog2(DELAY) == 0) ? 0 : ($clog2(DELAY)  - 1);

    reg [DELAY :0]  valid;
    reg [CWIDTH:0]  count;

    generate 
        if(DELAY == 0) begin
            reg [WIDTH-1:0] odata;

            always @(posedge clock or posedge reset) begin
                if (reset) begin
                    odata <= 0;
                end 
                else begin            
                    if (ivalid) begin
                        odata <= shiftin;
                    end
                end
            end

            assign shiftout = odata;
        end
        else begin
            if(THRES <= WIDTH * DELAY) begin : RAM_IP
                SDPRAM #(
                    .WIDTH 		( WIDTH 		),
                    .DEPTH 		( DELAY  		))
                u_SDPRAM(
                    //ports
                    .clock  	( clock  		),
                    .reset   	( reset   		),

                    .wen   		( ivalid   		),
                    .ren        ( 1'b1          ),

                    .waddr 		( count 		),
                    .raddr 		( count 		),

                    .din  		( shiftin  		),
                    .dout 		( shiftout 		)
                );
            end
            else begin : BRAM
                reg [WIDTH-1:0] ram [DELAY-1:0];
                reg [WIDTH-1:0] odata;

                integer i;
                always @(posedge clock or posedge reset) begin
                    if (reset) begin
                        for (i = 0; i < DELAY; i = i+1) begin
                            ram[i] <= 0;
                        end
                        odata <= 0;
                    end 
                    else begin    
                        odata <= ram[count];        
                        if (ivalid) begin
                            ram[count] <= shiftin;  
                        end
                    end
                end

                assign shiftout = odata;
            end

            always @(posedge clock or posedge reset) begin
                if (reset) begin
                    count <= 0;
                end 
                else begin            
                    // if (ivalid) begin
                        count <= count + 1;
                        if (count == (DELAY-1)) begin
                            count <= 0;
                        end
                    // end
                end
            end

        end
    endgenerate

    // reg mask_valid;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            valid <= 0;
        end 
        else begin    
            valid <= (DELAY > 0) ? {valid[VALID:0], ivalid} : ivalid;
        end
    end

    assign ovalid = valid[DELAY];
    // always @(posedge clock or posedge reset) begin
    //     if (reset) begin
    //         valid <= 0;
    //         mask_valid <= 0;
    //     end 
    //     else begin    
    //         if(ivalid) begin
    //             valid <= (DELAY > 0) ? {valid[VALID:0], ivalid} : ivalid;                
    //         end 
    //         mask_valid <= DELAY > 0? valid[DELAY - 1]&ivalid : ivalid;
    //     end
    // end

    // assign ovalid = mask_valid;
    
endmodule

