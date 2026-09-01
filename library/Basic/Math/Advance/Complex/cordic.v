`timescale 1ns / 1ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   cordic.v - cordic
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : CORDIC algorithm implementation. Supports circular system only.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

module cordic #(
        // Rotation mode in the corresponding system.
        // ROTATE | VECTOR
        parameter STYLE      = "ROTATE",
        // Output calculation mode: 
        // FAST : fast calculation mode, only the accuracy of the phase output is ensured, 
        //        while the XY coordinates are output after being scaled by a fixed value. 
        // PRECISION  : In precise calculation mode, the outputs are accurate values.
        // SPRECISION : In shift precise calculation mode, the accurate outputs perform 
        //              arithmetic shifts to prevent output overflow.
        parameter CALMODE    = "FAST",
        // Data bit width of the input and output XY coordinates.
        parameter XY_BITS    = 12,
        // Data bit width of the input and output Phase.
        parameter PH_BITS    = 32,
        // Number of loop iterations.
        parameter ITERATIONS = 32
    )(
        // Clock input
        input   clock,
        // Asynchronous reset with active high
        input   reset,

        // @Flow Input valid
        input   ivalid, 
        // @Flow The X-coordinate of the signed input port
        input   signed [XY_BITS-1:0] x_i,
        // @Flow The Y-coordinate of the signed input port
        input   signed [XY_BITS-1:0] y_i,
        // @Flow The Phase of the signed input port
        input   signed [PH_BITS-1:0] z_i,

        // @Flow Output valid
        // Synchronized output with the modulus port
        output  ovalid,
        // @Flow The X-coordinate of the signed output port
        output  signed [XY_BITS-1:0] x_o,
        // @Flow The Y-coordinate of the signed output port
        output  signed [XY_BITS-1:0] y_o,
        // @Flow The Phase of the signed output port
        output  signed [PH_BITS-1:0] z_o
    );

    // localparam        [15:0] K_COE = 16'd39797;
    localparam signed [PH_BITS-1:0] PHASE_COE = (2**(PH_BITS-2)) - 1;

    /*
    //360°--2^16,z_i = 16bits (input [15:0] z_i)
    //1°--2^16/360
    */
    function [PH_BITS-1:0] tanangle;
        input [4:0] i;
        begin
            case (i)
                5'b00000: tanangle = (32'h20000000 >> (32 - PH_BITS));   // 45 degrees
                5'b00001: tanangle = (32'h12e4051e >> (32 - PH_BITS));   // 26.56
                5'b00010: tanangle = (32'h09fb385b >> (32 - PH_BITS));   // 14.036243467926479
                5'b00011: tanangle = (32'h051111d4 >> (32 - PH_BITS));   // 7.125016348901798
                5'b00100: tanangle = (32'h028b0d43 >> (32 - PH_BITS));   // 3.576334374997351
                5'b00101: tanangle = (32'h0145d7e1 >> (32 - PH_BITS));   // 1.7899106082460694
                5'b00110: tanangle = (32'h00a2f61e >> (32 - PH_BITS));   // 0.8951737102110744
                5'b00111: tanangle = (32'h00517c55 >> (32 - PH_BITS));   // 0.4476141708605531
                5'b01000: tanangle = (32'h0028be53 >> (32 - PH_BITS));   // 0.22381050036853808
                5'b01001: tanangle = (32'h00145f2f >> (32 - PH_BITS));   // 0.1119056770662069
                5'b01010: tanangle = (32'h000a2f98 >> (32 - PH_BITS));   // 0.055952891893803675
                5'b01011: tanangle = (32'h000517cc >> (32 - PH_BITS));   // 0.027976452617003676
                5'b01100: tanangle = (32'h00028be6 >> (32 - PH_BITS));   // 0.013988227142265016
                5'b01101: tanangle = (32'h000145f3 >> (32 - PH_BITS));   // 0.006994113675352919
                5'b01110: tanangle = (32'h0000a2fa >> (32 - PH_BITS));   // 0.003497056850704011
                5'b01111: tanangle = (32'h0000517d >> (32 - PH_BITS));   // 0.0017485284269804495
                5'b10000: tanangle = (32'h000028be >> (32 - PH_BITS));   // 0.0008742642136937803
                5'b10001: tanangle = (32'h0000145f >> (32 - PH_BITS));   // 0.00043713210687233457
                5'b10010: tanangle = (32'h00000a30 >> (32 - PH_BITS));   // 0.00021856605343934784
                5'b10011: tanangle = (32'h00000518 >> (32 - PH_BITS));   // 0.00010928302672007149
                5'b10100: tanangle = (32'h0000028c >> (32 - PH_BITS));   // 0  
                5'b10101: tanangle = (32'h00000146 >> (32 - PH_BITS));   // 0  
                5'b10110: tanangle = (32'h000000a3 >> (32 - PH_BITS));   // 0 
                5'b10111: tanangle = (32'h00000051 >> (32 - PH_BITS));   // 0 
                5'b11000: tanangle = (32'h00000029 >> (32 - PH_BITS));   // 0 
                5'b11001: tanangle = (32'h00000014 >> (32 - PH_BITS));   // 0 
                5'b11010: tanangle = (32'h0000000a >> (32 - PH_BITS));   // 0 
                5'b11011: tanangle = (32'h00000005 >> (32 - PH_BITS));   // 0 
                5'b11100: tanangle = (32'h00000003 >> (32 - PH_BITS));   // 0 
                5'b11101: tanangle = (32'h00000001 >> (32 - PH_BITS));   // 0 
                5'b11110: tanangle = (32'h00000001 >> (32 - PH_BITS));   // 0 
                5'b11111: tanangle = (32'h00000000 >> (32 - PH_BITS));   // 0 
            endcase
        end
    endfunction

    reg         [1:0]            sign  [ITERATIONS:0];
    reg  signed [XY_BITS+1:0]    x     [ITERATIONS:0];
    reg  signed [XY_BITS+1:0]    y     [ITERATIONS:0];
    reg  signed [PH_BITS+1:0]    z     [ITERATIONS:0];
    wire        [ITERATIONS-1:0] state;

    // Data input preprocessing.
    wire [1:0] isign = (STYLE == "ROTATE") ? (z_i[PH_BITS-1:PH_BITS-2])   :
                       (STYLE == "VECTOR") ? ({x_i[XY_BITS-1],y_i[XY_BITS-1]}) : 
                                             (z_i[PH_BITS-1:PH_BITS-2]);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            x[0] <= 0;
            y[0] <= 0;
            z[0] <= 0;
            sign[0] <= 0;
        end
        else begin
            if(ivalid) begin
                if (STYLE == "ROTATE") begin    
                    case (isign) 
                        2'b00   : begin x[0] <=  x_i; y[0] <=  y_i; z[0] <= z_i; end // 1
                        2'b01   : begin x[0] <= -y_i; y[0] <=  x_i; z[0] <= z_i - PHASE_COE; end // 2
                        2'b10   : begin x[0] <=  y_i; y[0] <= -x_i; z[0] <= z_i + PHASE_COE; end // 3
                        2'b11   : begin x[0] <=  x_i; y[0] <=  y_i; z[0] <= z_i; end // 4
                        default : begin x[0] <=  x_i; y[0] <=  y_i; z[0] <= z_i; end
                    endcase
                end
                else if (STYLE == "VECTOR") begin
                    case (isign) 
                        2'b00   : begin x[0] <=  x_i; y[0] <=  y_i; z[0] <= z_i; end // 1
                        2'b01   : begin x[0] <=  x_i; y[0] <=  y_i; z[0] <= z_i; end // 4
                        2'b10   : begin x[0] <=  y_i; y[0] <= -x_i; z[0] <= z_i + PHASE_COE; end // 2
                        2'b11   : begin x[0] <= -y_i; y[0] <=  x_i; z[0] <= z_i - PHASE_COE; end // 3
                        default : begin x[0] <=  x_i; y[0] <=  y_i; z[0] <= z_i; end
                    endcase
                end
                sign[0] <= isign;
            end
        end
    end

    // CORDIC core, performing rotation iterations.
    genvar i;
    generate for(i=0; i < ITERATIONS; i=i+1) begin : CORDIC
        assign state[i] = (STYLE == "ROTATE") ? (z[i] < 0) :
                          (STYLE == "VECTOR") ? (y[i] > 0) : (z[i] < 0);
        always @ (posedge clock or posedge reset) begin
            if (reset) begin
                x[i+1] <= 0;
                y[i+1] <= 0;
                z[i+1] <= 0;
            end 
            else begin
                if (state[i]) begin
                    x[i+1] <= x[i] + (((y[i] == -1) & (i > 0)) ? 0 : (y[i]>>>i)); 
                    y[i+1] <= y[i] - (((x[i] == -1) & (i > 0)) ? 0 : (x[i]>>>i)); 
                    z[i+1] <= z[i] + tanangle(i);
                end 
                else begin
                    x[i+1] <= x[i] - (((y[i] == -1) & (i > 0)) ? 0 : (y[i]>>>i)); 
                    y[i+1] <= y[i] + (((x[i] == -1) & (i > 0)) ? 0 : (x[i]>>>i)); 
                    z[i+1] <= z[i] - tanangle(i);
                end
            end
        end

        always @ (posedge clock or posedge reset) begin
            if (reset) begin
                sign[i+1] <= 0;
            end
            else begin
                sign[i+1]  <= sign[i];
            end
        end
    end 
    endgenerate

    // 
    generate if(CALMODE == "FAST") begin : FAST
        assign x_o = x[ITERATIONS] >>> 2;
        assign y_o = y[ITERATIONS] >>> 2;
    end
    else if(CALMODE == "PRECISION") begin : PRECISION
        localparam [14:0] K_COE = 15'd9949;

        wire signed [XY_BITS+16:0] x_m = ($signed(x[ITERATIONS]) * $signed(K_COE));
        assign x_o = x_m >>> 14;
        
        wire signed [XY_BITS+16:0] y_m = ($signed(y[ITERATIONS]) * $signed(K_COE));
        assign y_o = y_m >>> 14;
    end
    else if(CALMODE == "SPRECISION") begin : SPRECISION
        localparam [14:0] K_COE = 15'd9949;

        wire signed [XY_BITS+16:0] x_m = ($signed(x[ITERATIONS]) * $signed(K_COE));
        assign x_o = x_m >>> 15;
        
        wire signed [XY_BITS+16:0] y_m = ($signed(y[ITERATIONS]) * $signed(K_COE));
        assign y_o = y_m >>> 15;
    end
    endgenerate

    assign z_o = z[ITERATIONS];

    // Output valid synchronization section.
    reg [ITERATIONS:0] v;
    always @ (posedge clock or posedge reset) begin
        if (reset) begin
            v <= 0;
        end
        else begin
            v <= v << 1;
            v[0] <= ivalid;
        end
    end
    assign ovalid = v[ITERATIONS];

endmodule
