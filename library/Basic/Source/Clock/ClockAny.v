`timescale 1 ns / 1 ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   ClockAny.v - ClockAny
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Arbitrary frequency generator module.
*   Dependencies: PhaseAcc
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

module ClockAny # (
        // Phase width.
        parameter PHASE_WIDTH = 32
    ) (
        // Clock input
        input                    clock,
        // Asynchronous reset with active high
        input                    reset,

        // Frequency control word.
        // (out clk frequency * 2^PHASE_WIDTH)/clock frequency
        input  [PHASE_WIDTH-1:0] sample_fre,
        // Out clk signal
        output		             sample_clk
    );

    wire [PHASE_WIDTH-1:0]	Q;

    PhaseAcc #(
        .WIDTH 		( PHASE_WIDTH ))
    u_PhaseAcc(
        //ports
        .clock   		( clock      ),
        .reset   		( reset      ),
        .clr     		( 1'b0       ),
        .add_sub 		( 1'b0       ),
        .D       		( sample_fre ),
        .Q       		( Q          )
    );

    assign sample_clk = Q[PHASE_WIDTH-1];

endmodule
