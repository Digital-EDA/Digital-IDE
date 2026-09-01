`timescale 1 ns / 1 ns

/*
*   Date : 2024-07-07
*   Author : nitcloud
*   Module Name:   Modulation.v - Modulation
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Digital modulation module implementation.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/
module DigitalMod (
        input  wire [2:0]  bpsc,
        input  wire [5:0]  bits,
        output reg  [31:0] iq
    );

    // combinatorial logic
    always @(*) begin
        iq = {16'h0000, 16'h0000};
        if(bpsc == 1) begin : BPSK
            case(bits[0])
                1'b0:	iq = {16'hC000, 16'h0000};
                1'b1:	iq = {16'h4000, 16'h0000};
            endcase
        end 
        else if(bpsc == 2) begin : QPSK
            case(bits[1:0])
                2'b00:	iq = {16'hD2BF, 16'hD2BF};
                2'b10:	iq = {16'hD2BF, 16'h2D41};

                2'b01:	iq = {16'h2D41, 16'hD2BF};
                2'b11:	iq = {16'h2D41, 16'h2D41};
            endcase
        end 
        else if(bpsc == 4) begin : QAM16
            case(bits[3:0])
                4'b0000:	iq = {16'hC349, 16'hC349};
                4'b1000:	iq = {16'hC349, 16'hEBC3};
                4'b1100:	iq = {16'hC349, 16'h143D};
                4'b0100:	iq = {16'hC349, 16'h3CB7};

                4'b0010:	iq = {16'hEBC3, 16'hC349};
                4'b1010:	iq = {16'hEBC3, 16'hEBC3};
                4'b1110:	iq = {16'hEBC3, 16'h143D};
                4'b0110:	iq = {16'hEBC3, 16'h3CB7};

                4'b0011:	iq = {16'h143D, 16'hC349};
                4'b1011:	iq = {16'h143D, 16'hEBC3};
                4'b1111:	iq = {16'h143D, 16'h143D};
                4'b0111:	iq = {16'h143D, 16'h3CB7};

                4'b0001:	iq = {16'h3CB7, 16'hC349};
                4'b1001:	iq = {16'h3CB7, 16'hEBC3};
                4'b1101:	iq = {16'h3CB7, 16'h143D};
                4'b0101:	iq = {16'h3CB7, 16'h3CB7};
            endcase
        end 
        else if(bpsc == 6) begin : QAM64
            case(bits[5:0])
                6'b000000:	iq = {16'hBAE0, 16'hBAE0};
                6'b100000:	iq = {16'hBAE0, 16'hCEA0};
                6'b110000:	iq = {16'hBAE0, 16'hE260};
                6'b010000:	iq = {16'hBAE0, 16'hF620};
                6'b011000:	iq = {16'hBAE0, 16'h09E0};
                6'b111000:	iq = {16'hBAE0, 16'h1DA0};
                6'b101000:	iq = {16'hBAE0, 16'h3160};
                6'b001000:	iq = {16'hBAE0, 16'h4520};

                6'b000100:	iq = {16'hCEA0, 16'hBAE0};
                6'b100100:	iq = {16'hCEA0, 16'hCEA0};
                6'b110100:	iq = {16'hCEA0, 16'hE260};
                6'b010100:	iq = {16'hCEA0, 16'hF620};
                6'b011100:	iq = {16'hCEA0, 16'h09E0};
                6'b111100:	iq = {16'hCEA0, 16'h1DA0};
                6'b101100:	iq = {16'hCEA0, 16'h3160};
                6'b001100:	iq = {16'hCEA0, 16'h4520};

                6'b000110:	iq = {16'hE260, 16'hBAE0};
                6'b100110:	iq = {16'hE260, 16'hCEA0};
                6'b110110:	iq = {16'hE260, 16'hE260};
                6'b010110:	iq = {16'hE260, 16'hF620};
                6'b011110:	iq = {16'hE260, 16'h09E0};
                6'b111110:	iq = {16'hE260, 16'h1DA0};
                6'b101110:	iq = {16'hE260, 16'h3160};
                6'b001110:	iq = {16'hE260, 16'h4520};

                6'b000010:	iq = {16'hF620, 16'hBAE0};
                6'b100010:	iq = {16'hF620, 16'hCEA0};
                6'b110010:	iq = {16'hF620, 16'hE260};
                6'b010010:	iq = {16'hF620, 16'hF620};
                6'b011010:	iq = {16'hF620, 16'h09E0};
                6'b111010:	iq = {16'hF620, 16'h1DA0};
                6'b101010:	iq = {16'hF620, 16'h3160};
                6'b001010:	iq = {16'hF620, 16'h4520};

                6'b000011:	iq = {16'h09E0, 16'hBAE0};
                6'b100011:	iq = {16'h09E0, 16'hCEA0};
                6'b110011:	iq = {16'h09E0, 16'hE260};
                6'b010011:	iq = {16'h09E0, 16'hF620};
                6'b011011:	iq = {16'h09E0, 16'h09E0};
                6'b111011:	iq = {16'h09E0, 16'h1DA0};
                6'b101011:	iq = {16'h09E0, 16'h3160};
                6'b001011:	iq = {16'h09E0, 16'h4520};

                6'b000111:	iq = {16'h1DA0, 16'hBAE0};
                6'b100111:	iq = {16'h1DA0, 16'hCEA0};
                6'b110111:	iq = {16'h1DA0, 16'hE260};
                6'b010111:	iq = {16'h1DA0, 16'hF620};
                6'b011111:	iq = {16'h1DA0, 16'h09E0};
                6'b111111:	iq = {16'h1DA0, 16'h1DA0};
                6'b101111:	iq = {16'h1DA0, 16'h3160};
                6'b001111:	iq = {16'h1DA0, 16'h4520};

                6'b000101:	iq = {16'h3160, 16'hBAE0};
                6'b100101:	iq = {16'h3160, 16'hCEA0};
                6'b110101:	iq = {16'h3160, 16'hE260};
                6'b010101:	iq = {16'h3160, 16'hF620};
                6'b011101:	iq = {16'h3160, 16'h09E0};
                6'b111101:	iq = {16'h3160, 16'h1DA0};
                6'b101101:	iq = {16'h3160, 16'h3160};
                6'b001101:	iq = {16'h3160, 16'h4520};

                6'b000001:	iq = {16'h4520, 16'hBAE0};
                6'b100001:	iq = {16'h4520, 16'hCEA0};
                6'b110001:	iq = {16'h4520, 16'hE260};
                6'b010001:	iq = {16'h4520, 16'hF620};
                6'b011001:	iq = {16'h4520, 16'h09E0};
                6'b111001:	iq = {16'h4520, 16'h1DA0};
                6'b101001:	iq = {16'h4520, 16'h3160};
                6'b001001:	iq = {16'h4520, 16'h4520};
            endcase
        end
    end

endmodule
