module Sin #(
        parameter SPEED = "HIGH"
    ) (
        input         clka,
        input         rsta,
        input  [9:0]  addra,
        output [15:0] douta
    );

    reg [7:0] addr; 
    always @(posedge clka or posedge rsta) begin
        if (rsta) begin
            addr <= 8'd0;
        end
        else begin            
            case (addra[9:8]) 
                2'b00   : begin addr <=  addra[7:0]; end
                2'b01   : begin addr <= ~addra[7:0]; end
                2'b10   : begin addr <=  addra[7:0]; end
                2'b11   : begin addr <= ~addra[7:0]; end
                default : begin addr <= 8'd0; end
            endcase
        end
    end

    reg [15:0] douta_buf;
    always @(posedge clka) begin
        if (rsta) begin
            douta_buf <= 0;
        end
        else begin
            case (addr)
                8'h00: douta_buf <= 16'b0000000000000000;
                8'h01: douta_buf <= 16'b0000000011001001;
                8'h02: douta_buf <= 16'b0000000110010010;
                8'h03: douta_buf <= 16'b0000001001011011;
                8'h04: douta_buf <= 16'b0000001100100100;
                8'h05: douta_buf <= 16'b0000001111101101;
                8'h06: douta_buf <= 16'b0000010010110110;
                8'h07: douta_buf <= 16'b0000010101111111;
                8'h08: douta_buf <= 16'b0000011001000111;
                8'h09: douta_buf <= 16'b0000011100010000;
                8'h0A: douta_buf <= 16'b0000011111011001;
                8'h0B: douta_buf <= 16'b0000100010100010;
                8'h0C: douta_buf <= 16'b0000100101101010;
                8'h0D: douta_buf <= 16'b0000101000110011;
                8'h0E: douta_buf <= 16'b0000101011111011;
                8'h0F: douta_buf <= 16'b0000101111000011;
                8'h10: douta_buf <= 16'b0000110010001011;
                8'h11: douta_buf <= 16'b0000110101010011;
                8'h12: douta_buf <= 16'b0000111000011011;
                8'h13: douta_buf <= 16'b0000111011100011;
                8'h14: douta_buf <= 16'b0000111110101011;
                8'h15: douta_buf <= 16'b0001000001110010;
                8'h16: douta_buf <= 16'b0001000100111001;
                8'h17: douta_buf <= 16'b0001001000000001;
                8'h18: douta_buf <= 16'b0001001011001000;
                8'h19: douta_buf <= 16'b0001001110001110;
                8'h1A: douta_buf <= 16'b0001010001010101;
                8'h1B: douta_buf <= 16'b0001010100011011;
                8'h1C: douta_buf <= 16'b0001010111100010;
                8'h1D: douta_buf <= 16'b0001011010101000;
                8'h1E: douta_buf <= 16'b0001011101101101;
                8'h1F: douta_buf <= 16'b0001100000110011;
                8'h20: douta_buf <= 16'b0001100011111000;
                8'h21: douta_buf <= 16'b0001100110111101;
                8'h22: douta_buf <= 16'b0001101010000010;
                8'h23: douta_buf <= 16'b0001101101000111;
                8'h24: douta_buf <= 16'b0001110000001011;
                8'h25: douta_buf <= 16'b0001110011001111;
                8'h26: douta_buf <= 16'b0001110110010011;
                8'h27: douta_buf <= 16'b0001111001010110;
                8'h28: douta_buf <= 16'b0001111100011001;
                8'h29: douta_buf <= 16'b0001111111011100;
                8'h2A: douta_buf <= 16'b0010000010011111;
                8'h2B: douta_buf <= 16'b0010000101100001;
                8'h2C: douta_buf <= 16'b0010001000100011;
                8'h2D: douta_buf <= 16'b0010001011100101;
                8'h2E: douta_buf <= 16'b0010001110100110;
                8'h2F: douta_buf <= 16'b0010010001100111;
                8'h30: douta_buf <= 16'b0010010100101000;
                8'h31: douta_buf <= 16'b0010010111101000;
                8'h32: douta_buf <= 16'b0010011010101000;
                8'h33: douta_buf <= 16'b0010011101100111;
                8'h34: douta_buf <= 16'b0010100000100110;
                8'h35: douta_buf <= 16'b0010100011100101;
                8'h36: douta_buf <= 16'b0010100110100011;
                8'h37: douta_buf <= 16'b0010101001100001;
                8'h38: douta_buf <= 16'b0010101100011111;
                8'h39: douta_buf <= 16'b0010101111011100;
                8'h3A: douta_buf <= 16'b0010110010011000;
                8'h3B: douta_buf <= 16'b0010110101010101;
                8'h3C: douta_buf <= 16'b0010111000010001;
                8'h3D: douta_buf <= 16'b0010111011001100;
                8'h3E: douta_buf <= 16'b0010111110000111;
                8'h3F: douta_buf <= 16'b0011000001000001;
                8'h40: douta_buf <= 16'b0011000011111011;
                8'h41: douta_buf <= 16'b0011000110110101;
                8'h42: douta_buf <= 16'b0011001001101110;
                8'h43: douta_buf <= 16'b0011001100100110;
                8'h44: douta_buf <= 16'b0011001111011110;
                8'h45: douta_buf <= 16'b0011010010010110;
                8'h46: douta_buf <= 16'b0011010101001101;
                8'h47: douta_buf <= 16'b0011011000000100;
                8'h48: douta_buf <= 16'b0011011010111010;
                8'h49: douta_buf <= 16'b0011011101101111;
                8'h4A: douta_buf <= 16'b0011100000100100;
                8'h4B: douta_buf <= 16'b0011100011011000;
                8'h4C: douta_buf <= 16'b0011100110001100;
                8'h4D: douta_buf <= 16'b0011101001000000;
                8'h4E: douta_buf <= 16'b0011101011110010;
                8'h4F: douta_buf <= 16'b0011101110100101;
                8'h50: douta_buf <= 16'b0011110001010110;
                8'h51: douta_buf <= 16'b0011110100000111;
                8'h52: douta_buf <= 16'b0011110110111000;
                8'h53: douta_buf <= 16'b0011111001101000;
                8'h54: douta_buf <= 16'b0011111100010111;
                8'h55: douta_buf <= 16'b0011111111000101;
                8'h56: douta_buf <= 16'b0100000001110011;
                8'h57: douta_buf <= 16'b0100000100100001;
                8'h58: douta_buf <= 16'b0100000111001110;
                8'h59: douta_buf <= 16'b0100001001111010;
                8'h5A: douta_buf <= 16'b0100001100100101;
                8'h5B: douta_buf <= 16'b0100001111010000;
                8'h5C: douta_buf <= 16'b0100010001111010;
                8'h5D: douta_buf <= 16'b0100010100100100;
                8'h5E: douta_buf <= 16'b0100010111001101;
                8'h5F: douta_buf <= 16'b0100011001110101;
                8'h60: douta_buf <= 16'b0100011100011100;
                8'h61: douta_buf <= 16'b0100011111000011;
                8'h62: douta_buf <= 16'b0100100001101001;
                8'h63: douta_buf <= 16'b0100100100001111;
                8'h64: douta_buf <= 16'b0100100110110100;
                8'h65: douta_buf <= 16'b0100101001011000;
                8'h66: douta_buf <= 16'b0100101011111011;
                8'h67: douta_buf <= 16'b0100101110011110;
                8'h68: douta_buf <= 16'b0100110000111111;
                8'h69: douta_buf <= 16'b0100110011100001;
                8'h6A: douta_buf <= 16'b0100110110000001;
                8'h6B: douta_buf <= 16'b0100111000100001;
                8'h6C: douta_buf <= 16'b0100111010111111;
                8'h6D: douta_buf <= 16'b0100111101011110;
                8'h6E: douta_buf <= 16'b0100111111111011;
                8'h6F: douta_buf <= 16'b0101000010010111;
                8'h70: douta_buf <= 16'b0101000100110011;
                8'h71: douta_buf <= 16'b0101000111001110;
                8'h72: douta_buf <= 16'b0101001001101001;
                8'h73: douta_buf <= 16'b0101001100000010;
                8'h74: douta_buf <= 16'b0101001110011011;
                8'h75: douta_buf <= 16'b0101010000110011;
                8'h76: douta_buf <= 16'b0101010011001010;
                8'h77: douta_buf <= 16'b0101010101100000;
                8'h78: douta_buf <= 16'b0101010111110101;
                8'h79: douta_buf <= 16'b0101011010001010;
                8'h7A: douta_buf <= 16'b0101011100011101;
                8'h7B: douta_buf <= 16'b0101011110110000;
                8'h7C: douta_buf <= 16'b0101100001000010;
                8'h7D: douta_buf <= 16'b0101100011010100;
                8'h7E: douta_buf <= 16'b0101100101100100;
                8'h7F: douta_buf <= 16'b0101100111110011;
                8'h80: douta_buf <= 16'b0101101010000010;
                8'h81: douta_buf <= 16'b0101101100010000;
                8'h82: douta_buf <= 16'b0101101110011101;
                8'h83: douta_buf <= 16'b0101110000101001;
                8'h84: douta_buf <= 16'b0101110010110100;
                8'h85: douta_buf <= 16'b0101110100111110;
                8'h86: douta_buf <= 16'b0101110111000111;
                8'h87: douta_buf <= 16'b0101111001010000;
                8'h88: douta_buf <= 16'b0101111011010111;
                8'h89: douta_buf <= 16'b0101111101011110;
                8'h8A: douta_buf <= 16'b0101111111100011;
                8'h8B: douta_buf <= 16'b0110000001101000;
                8'h8C: douta_buf <= 16'b0110000011101100;
                8'h8D: douta_buf <= 16'b0110000101101111;
                8'h8E: douta_buf <= 16'b0110000111110001;
                8'h8F: douta_buf <= 16'b0110001001110001;
                8'h90: douta_buf <= 16'b0110001011110010;
                8'h91: douta_buf <= 16'b0110001101110001;
                8'h92: douta_buf <= 16'b0110001111101111;
                8'h93: douta_buf <= 16'b0110010001101100;
                8'h94: douta_buf <= 16'b0110010011101000;
                8'h95: douta_buf <= 16'b0110010101100011;
                8'h96: douta_buf <= 16'b0110010111011101;
                8'h97: douta_buf <= 16'b0110011001010111;
                8'h98: douta_buf <= 16'b0110011011001111;
                8'h99: douta_buf <= 16'b0110011101000110;
                8'h9A: douta_buf <= 16'b0110011110111101;
                8'h9B: douta_buf <= 16'b0110100000110010;
                8'h9C: douta_buf <= 16'b0110100010100110;
                8'h9D: douta_buf <= 16'b0110100100011001;
                8'h9E: douta_buf <= 16'b0110100110001100;
                8'h9F: douta_buf <= 16'b0110100111111101;
                8'hA0: douta_buf <= 16'b0110101001101101;
                8'hA1: douta_buf <= 16'b0110101011011100;
                8'hA2: douta_buf <= 16'b0110101101001010;
                8'hA3: douta_buf <= 16'b0110101110111000;
                8'hA4: douta_buf <= 16'b0110110000100100;
                8'hA5: douta_buf <= 16'b0110110010001111;
                8'hA6: douta_buf <= 16'b0110110011111001;
                8'hA7: douta_buf <= 16'b0110110101100010;
                8'hA8: douta_buf <= 16'b0110110111001010;
                8'hA9: douta_buf <= 16'b0110111000110000;
                8'hAA: douta_buf <= 16'b0110111010010110;
                8'hAB: douta_buf <= 16'b0110111011111011;
                8'hAC: douta_buf <= 16'b0110111101011111;
                8'hAD: douta_buf <= 16'b0110111111000001;
                8'hAE: douta_buf <= 16'b0111000000100011;
                8'hAF: douta_buf <= 16'b0111000010000011;
                8'hB0: douta_buf <= 16'b0111000011100010;
                8'hB1: douta_buf <= 16'b0111000101000001;
                8'hB2: douta_buf <= 16'b0111000110011110;
                8'hB3: douta_buf <= 16'b0111000111111010;
                8'hB4: douta_buf <= 16'b0111001001010101;
                8'hB5: douta_buf <= 16'b0111001010101111;
                8'hB6: douta_buf <= 16'b0111001100000111;
                8'hB7: douta_buf <= 16'b0111001101011111;
                8'hB8: douta_buf <= 16'b0111001110110101;
                8'hB9: douta_buf <= 16'b0111010000001011;
                8'hBA: douta_buf <= 16'b0111010001011111;
                8'hBB: douta_buf <= 16'b0111010010110010;
                8'hBC: douta_buf <= 16'b0111010100000100;
                8'hBD: douta_buf <= 16'b0111010101010101;
                8'hBE: douta_buf <= 16'b0111010110100101;
                8'hBF: douta_buf <= 16'b0111010111110100;
                8'hC0: douta_buf <= 16'b0111011001000001;
                8'hC1: douta_buf <= 16'b0111011010001110;
                8'hC2: douta_buf <= 16'b0111011011011001;
                8'hC3: douta_buf <= 16'b0111011100100011;
                8'hC4: douta_buf <= 16'b0111011101101100;
                8'hC5: douta_buf <= 16'b0111011110110100;
                8'hC6: douta_buf <= 16'b0111011111111010;
                8'hC7: douta_buf <= 16'b0111100001000000;
                8'hC8: douta_buf <= 16'b0111100010000100;
                8'hC9: douta_buf <= 16'b0111100011000111;
                8'hCA: douta_buf <= 16'b0111100100001001;
                8'hCB: douta_buf <= 16'b0111100101001010;
                8'hCC: douta_buf <= 16'b0111100110001010;
                8'hCD: douta_buf <= 16'b0111100111001000;
                8'hCE: douta_buf <= 16'b0111101000000101;
                8'hCF: douta_buf <= 16'b0111101001000010;
                8'hD0: douta_buf <= 16'b0111101001111101;
                8'hD1: douta_buf <= 16'b0111101010110110;
                8'hD2: douta_buf <= 16'b0111101011101111;
                8'hD3: douta_buf <= 16'b0111101100100110;
                8'hD4: douta_buf <= 16'b0111101101011101;
                8'hD5: douta_buf <= 16'b0111101110010010;
                8'hD6: douta_buf <= 16'b0111101111000101;
                8'hD7: douta_buf <= 16'b0111101111111000;
                8'hD8: douta_buf <= 16'b0111110000101001;
                8'hD9: douta_buf <= 16'b0111110001011010;
                8'hDA: douta_buf <= 16'b0111110010001001;
                8'hDB: douta_buf <= 16'b0111110010110111;
                8'hDC: douta_buf <= 16'b0111110011100011;
                8'hDD: douta_buf <= 16'b0111110100001111;
                8'hDE: douta_buf <= 16'b0111110100111001;
                8'hDF: douta_buf <= 16'b0111110101100010;
                8'hE0: douta_buf <= 16'b0111110110001010;
                8'hE1: douta_buf <= 16'b0111110110110000;
                8'hE2: douta_buf <= 16'b0111110111010110;
                8'hE3: douta_buf <= 16'b0111110111111010;
                8'hE4: douta_buf <= 16'b0111111000011101;
                8'hE5: douta_buf <= 16'b0111111000111111;
                8'hE6: douta_buf <= 16'b0111111001011111;
                8'hE7: douta_buf <= 16'b0111111001111111;
                8'hE8: douta_buf <= 16'b0111111010011101;
                8'hE9: douta_buf <= 16'b0111111010111010;
                8'hEA: douta_buf <= 16'b0111111011010101;
                8'hEB: douta_buf <= 16'b0111111011110000;
                8'hEC: douta_buf <= 16'b0111111100001001;
                8'hED: douta_buf <= 16'b0111111100100001;
                8'hEE: douta_buf <= 16'b0111111100111000;
                8'hEF: douta_buf <= 16'b0111111101001101;
                8'hF0: douta_buf <= 16'b0111111101100010;
                8'hF1: douta_buf <= 16'b0111111101110101;
                8'hF2: douta_buf <= 16'b0111111110000111;
                8'hF3: douta_buf <= 16'b0111111110010111;
                8'hF4: douta_buf <= 16'b0111111110100111;
                8'hF5: douta_buf <= 16'b0111111110110101;
                8'hF6: douta_buf <= 16'b0111111111000010;
                8'hF7: douta_buf <= 16'b0111111111001110;
                8'hF8: douta_buf <= 16'b0111111111011000;
                8'hF9: douta_buf <= 16'b0111111111100001;
                8'hFA: douta_buf <= 16'b0111111111101001;
                8'hFB: douta_buf <= 16'b0111111111110000;
                8'hFC: douta_buf <= 16'b0111111111110110;
                8'hFD: douta_buf <= 16'b0111111111111010;
                8'hFE: douta_buf <= 16'b0111111111111101;
                8'hFF: douta_buf <= 16'b0111111111111111;
            endcase
        end
    end

    reg [1:0] state; 
    always @(posedge clka or posedge rsta) begin
        if (rsta) begin
            state <= 2'd0;
        end
        else begin       
            state[0] <= addra[9];
            state[1] <= state[0];
        end
    end

    generate 
        if(SPEED == "HIGH") begin : HIGH        
            reg [15:0] sin; 
            always @(posedge clka or posedge rsta) begin
                if (rsta) begin
                    sin <= 16'd0;
                end
                else begin       
                    if (state[1]) begin
                        sin <= ~douta_buf;
                    end
                    else begin
                        sin <= douta_buf;
                    end
                end
            end

            assign douta = sin;
        end
        else if(SPEED == "LOW") begin : LOW  
            assign douta = state[1] ? (~douta_buf + 1) : douta_buf;
        end
    endgenerate
    
endmodule
