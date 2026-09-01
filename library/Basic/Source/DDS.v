`timescale 1 ns / 1 ns

/*
*   Date : 2024-07-02
*   Author : nitcloud
*   Module Name:   DDS.v - DDS
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Direct digital frequency synthesis.
*   Dependencies: accuml + Sin
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

module DDS #(
        // Output signal width.
        parameter OUTPUT_WIDTH = 12,
        // Phase width.
        parameter PHASE_WIDTH  = 32
    ) (
        // Clock input
        input                       clock,
        // Asynchronous reset with active high
        input                       reset, 

        // Frequency control word.
        // (out clk frequency * 2^PHASE_WIDTH)/clock frequency
        input  [PHASE_WIDTH-1 : 0]  fre_word, 
        
        // Phase control word.
        // (out phase * 2^PHASE_WIDTH) / (clock frequency * 360°)
        input  [PHASE_WIDTH-1 : 0]  pha_word, 

        // Out Sine wave.
        output [OUTPUT_WIDTH-1 : 0] wave_sin,
        // Out Triangle wave.
        output [OUTPUT_WIDTH-1 : 0] wave_tri,
        // Out Sawtooth wave.
        output [OUTPUT_WIDTH-1 : 0] wave_saw
    ); 

    wire [PHASE_WIDTH-1:0] Q;

    accuml #(
        .WIDTH 		( PHASE_WIDTH 		))
    u_accuml(
        //ports
        .clock   		( clock   		),
        .reset   		( reset   		),
        .clr     		( 1'b0     		),
        .add_sub 		( 1'b0  		),
        .D       		( fre_word      ),
        .Q       		( Q       		)
    );

    reg [PHASE_WIDTH-1:0] phase;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            phase <= 0;
        end
        else begin
            phase <= Q + pha_word;
        end
    end

    reg [9:0] addr;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            addr <= 0;
        end
        else begin
            addr <= phase[PHASE_WIDTH-1:PHASE_WIDTH-10];
        end
    end

    wire [15:0]	douta;
    Sin u_Sin(
        //ports
        .clka  		( clock  		),
        .rsta  		( reset  		),
        .addra 		( addr  		),
        .douta 		( douta 		)
    );

    assign wave_sin = douta >>> (16-OUTPUT_WIDTH);
    assign wave_saw = phase[PHASE_WIDTH-1:PHASE_WIDTH-OUTPUT_WIDTH];
    assign wave_tri = wave_saw[OUTPUT_WIDTH-1] ? 
                      {{ wave_saw[OUTPUT_WIDTH-2]}, ~wave_saw[OUTPUT_WIDTH-3:0], 1'b0}: 
                      {{~wave_saw[OUTPUT_WIDTH-2]},  wave_saw[OUTPUT_WIDTH-3:0], 1'b0};

endmodule
