`timescale 1 ns / 1 ns

/*
*   Date : 2024-07-01
*   Author : nitcloud
*   Module Name:   rst_sys.v - rst_sys
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : 
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

module rst_sys (
        input  wire        clock,
        input  wire        iasyn, 
        output reg         osync
    );

    reg buffer;

    always @(posedge clock or negedge iasyn) begin
        if(iasyn) begin
            {osync, buffer} <= 2'b1;
        end 
        else begin
            {osync, buffer} <= {buffer, 1'b0};
        end
    end

endmodule
