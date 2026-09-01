`timescale 1 ns / 1 ns
/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   convenc.v - convenc
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Convolutional encoding module implementation.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: 'n.........'},
  {name: 'ivalid', wave: '01.......0'},
  {name: 'idata', wave: '0.101...0.'},
  {name: 'ovalid', wave: '0.1.......0'},
  {name: 'odata', wave: 'x.33333.33x', data: ['0','3','1','0','1','0','2']},
]}
*/
module convenc #(
        // Number of clock cycles delay.
        parameter CYCLES_NDELAY = 0,
        // Constraint length.
        parameter POLYNOM_DEPTH = 7, 
        // Generator polynomial for the 0th bit.
        // The MSB corresponds to the highest-order term.
        parameter POLYNOM_VSET0 = 7'b1001111, 
        // Generator polynomial for the 1th bit.
        // The MSB corresponds to the highest-order term.
        parameter POLYNOM_VSET1 = 7'b1101101, 
        // Initial value of the encoder.
        parameter DEFAULT_STATE = 7'b0000000
    )(
        // Clock input
        input         clock,
        // Asynchronous reset with active high
        input         reset,

        // @Flow Input valid
        // Synchronized input with the idata port
        input         ivalid,
        // @Flow The idata input port
        input         idata,
        
        // @Flow Output valid
        // Synchronized output with the odata port
        output        ovalid,
        // @Flow The odata output port
        output  [1:0] odata
    );

    reg     [POLYNOM_DEPTH-1:0]    shift;

    always @(posedge clock) begin
        if(reset) begin
            shift <= DEFAULT_STATE;
        end
        else begin
            if(ivalid) begin
                shift <= {shift[POLYNOM_DEPTH-2:0], idata};
            end
        end
    end

    reg       mvalid;
    reg [1:0] mdata;

    generate 
        if(CYCLES_NDELAY == 2) begin : DELAY2
            reg dvalid;
            always @(posedge clock or posedge reset) begin
                if (reset) begin            
                    mdata[0] <= 0;
                    mdata[1] <= 0;
                end
                else begin
                    mdata[0] <= ^(shift & POLYNOM_VSET0);
                    mdata[1] <= ^(shift & POLYNOM_VSET1);
                end
            end

            always @(posedge clock or posedge reset) begin
                if(reset) begin
                    mvalid <= 0;
                    dvalid <= 0;
                end
                else begin
                    dvalid <= ivalid;
                    mvalid <= dvalid;
                end                
            end
        end
        else if(CYCLES_NDELAY == 1) begin : DELAY1
            always @(*) begin
                mdata[0] = ^(shift & POLYNOM_VSET0);
                mdata[1] = ^(shift & POLYNOM_VSET1);
            end

            always @(posedge clock or posedge reset) begin
                if(reset) begin
                    mvalid <= 0;
                end
                else begin
                    mvalid <= ivalid;
                end                
            end
        end
        else begin : NODELAY
            always @(*) begin
                mvalid = ivalid;
                mdata[0] = ^({shift[POLYNOM_DEPTH-2:0], idata} & POLYNOM_VSET0);
                mdata[1] = ^({shift[POLYNOM_DEPTH-2:0], idata} & POLYNOM_VSET1);
            end
        end
    endgenerate

    assign  odata  = mdata;
    assign  ovalid = mvalid;

endmodule