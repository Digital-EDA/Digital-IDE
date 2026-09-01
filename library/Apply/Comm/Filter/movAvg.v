`timescale 1 ns / 1 ns

/*
*   Date : 2024-07-01
*   Author : nitcloud
*   Module Name:   movAvg.v - movAvg
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Sliding window average filter.
*   Dependencies: shiftTaps
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '10101010101010101010101'},
  {name: 'reset', wave: '10.....................'},
  {name: 'ivalid', wave: '01010101010101010101010'},
  {name: 'idata', wave: 'x3.3.3.3.3.3.x.........', data: ['1','2','3','4','5','6']},
  {name: 'ovalid', wave: '0........10101010101010'},
  {name: 'odata', wave: 'x........4.4.4.4.4.4.x.', data: ['1','2','3','4','5','6']},
]}
*/
module movAvg #(
        // Data width.
        parameter WIDTH = 32,
        // Sliding window number.
        parameter WINDOW = 4
    ) (
        // Clock input
        input  clock,
        // Asynchronous reset with active high
        input  reset,

        // @Flow Input valid
        // Synchronized input with the idata port
        input  ivalid,
        // @Flow The input port
        input  signed [WIDTH-1:0] idata,

        // @Flow Output valid
        // Synchronized output with the odata port
        output ovalid,
        // @Flow The output port
        output signed [WIDTH-1:0] odata
    );

    localparam SUM_WIDTH = WIDTH + $clog2(WINDOW);

    reg                    done;
    reg signed [WIDTH-1:0] odata_buf;
    reg signed [(SUM_WIDTH-1):0] sum;

    wire 	                mvalid;
    wire signed [WIDTH-1:0] mdata;
    wire signed [SUM_WIDTH-1:0] ext_old_data = {{$clog2(WINDOW){mdata[WIDTH-1]}}, mdata};
    wire signed [SUM_WIDTH-1:0] ext_new_data = {{$clog2(WINDOW){idata[WIDTH-1]}}, idata};

    shiftTaps #(
        .WIDTH 		( WIDTH   	),
        .SHIFT 		( WINDOW 	))
    u_shiftTaps(
        //ports
        .clock    		( clock    		),
        .reset    		( reset    		),

        .ivalid   		( ivalid   		),
        .shiftin  		( idata  		),

        .ovalid   		( mvalid   		),
        .shiftout 		( mdata 		)
    );

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            odata_buf <= 0;
            sum <= 0;
        end
        else begin
            if (ivalid) begin
                odata_buf <= sum[SUM_WIDTH-1:$clog2(WINDOW)];
                if (done) begin
                    sum <= sum + ext_new_data - ext_old_data;
                end else begin
                    sum <= sum + ext_new_data;
                end
            end
        end
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            done <= 1'b0;
        end
        else begin
            if (mvalid && (~done)) begin
                done <= 1'b1;
            end
            else begin
                done <= done;
            end
        end
    end

    assign odata = odata_buf;
    assign ovalid = mvalid;

endmodule
