module crc32 #(
        parameter RUNMODE = 0,
        parameter DIWIDTH = 32,
        parameter DOWIDTH = 32
    )(
        input                clock,
        input                reset,

        input                ivalid,
        input  [DIWIDTH-1:0] data_in,
        
        output [DOWIDTH-1:0] crc_out
    );

    generate 
        if(RUNMODE) begin : U
            wire [3 :0] index;
            reg  [31:0] crc_table;
            reg  [31:0] crc_reg;

            always @(*) begin
                case(index)
                    4'b0000: begin crc_table = 32'h4DBDF21C; end
                    4'b0001: begin crc_table = 32'h500AE278; end
                    4'b0010: begin crc_table = 32'h76D3D2D4; end
                    4'b0011: begin crc_table = 32'h6B64C2B0; end
                    4'b0100: begin crc_table = 32'h3B61B38C; end
                    4'b0101: begin crc_table = 32'h26D6A3E8; end
                    4'b0110: begin crc_table = 32'h000F9344; end
                    4'b0111: begin crc_table = 32'h1DB88320; end
                    4'b1000: begin crc_table = 32'hA005713C; end
                    4'b1001: begin crc_table = 32'hBDB26158; end
                    4'b1010: begin crc_table = 32'h9B6B51F4; end
                    4'b1011: begin crc_table = 32'h86DC4190; end
                    4'b1100: begin crc_table = 32'hD6D930AC; end
                    4'b1101: begin crc_table = 32'hCB6E20C8; end
                    4'b1110: begin crc_table = 32'hEDB71064; end
                    4'b1111: begin crc_table = 32'hF0000000; end
                endcase
            end

            assign index = crc_reg[3:0] ^ data_in;

            always @(posedge clock or posedge reset) begin
                if (reset) begin
                    crc_reg <= 0;
                end
                else begin            
                    if(ivalid) begin
                        crc_reg <= {4'b0000, crc_reg[31:4]} ^ crc_table;
                    end
                end
            end

            assign crc_out = crc_reg;
        end
        else begin
            reg [31:0] lfsr_q;
            reg [31:0] lfsr_c;

            assign crc_out = lfsr_q;

            always @(*) begin
                lfsr_c[0]  = ^ {40'b0100_0001_00000000_00000000_00000000_0100_0001 ^ {lfsr_q, data_in}};
                lfsr_c[1]  = ^ {40'b1100_0011_00000000_00000000_00000000_1100_0011 ^ {lfsr_q, data_in}};
                lfsr_c[2]  = ^ {40'b1100_0111_00000000_00000000_00000000_1100_0111 ^ {lfsr_q, data_in}};
                lfsr_c[3]  = ^ {40'b1000_1110_00000000_00000000_00000000_1000_1110 ^ {lfsr_q, data_in}};
                lfsr_c[4]  = ^ {40'b0101_1101_00000000_00000000_00000000_0101_1101 ^ {lfsr_q, data_in}};
                lfsr_c[5]  = ^ {40'b1111_1011_00000000_00000000_00000000_1111_1011 ^ {lfsr_q, data_in}};
                lfsr_c[6]  = ^ {40'b1111_0110_00000000_00000000_00000000_1111_0110 ^ {lfsr_q, data_in}};
                lfsr_c[7]  = ^ {40'b1010_1101_00000000_00000000_00000000_1010_1101 ^ {lfsr_q, data_in}};
                lfsr_c[8]  = ^ {40'b0001_1011_00000000_00000000_00000001_0001_1011 ^ {lfsr_q, data_in}};
                lfsr_c[9]  = ^ {40'b0011_0110_00000000_00000000_00000010_0011_0110 ^ {lfsr_q, data_in}};
                lfsr_c[10] = ^ {40'b0010_1101_00000000_00000000_00000100_0010_1101 ^ {lfsr_q, data_in}};
                lfsr_c[11] = ^ {40'b0001_1011_00000000_00000000_00001000_0001_1011 ^ {lfsr_q, data_in}};
                lfsr_c[12] = ^ {40'b0111_0111_00000000_00000000_00010000_0111_0111 ^ {lfsr_q, data_in}};
                lfsr_c[13] = ^ {40'b1110_1110_00000000_00000000_00100000_1110_1110 ^ {lfsr_q, data_in}};
                lfsr_c[14] = ^ {40'b1101_1100_00000000_00000000_01000000_1101_1100 ^ {lfsr_q, data_in}};
                lfsr_c[15] = ^ {40'b1011_1000_00000000_00000000_10000000_1011_1000 ^ {lfsr_q, data_in}};
                lfsr_c[16] = ^ {40'b0011_0001_00000000_00000001_00000000_0011_0001 ^ {lfsr_q, data_in}};
                lfsr_c[17] = ^ {40'b0110_0010_00000000_00000010_00000000_0110_0010 ^ {lfsr_q, data_in}};
                lfsr_c[18] = ^ {40'b1100_0100_00000000_00000100_00000000_1100_0100 ^ {lfsr_q, data_in}};
                lfsr_c[19] = ^ {40'b1000_1000_00000000_00001000_00000000_1000_1000 ^ {lfsr_q, data_in}};
                lfsr_c[20] = ^ {40'b0001_0000_00000000_00010000_00000000_0001_0000 ^ {lfsr_q, data_in}};
                lfsr_c[21] = ^ {40'b0010_0000_00000000_00100000_00000000_0010_0000 ^ {lfsr_q, data_in}};
                lfsr_c[22] = ^ {40'b0000_0001_00000000_01000000_00000000_0000_0001 ^ {lfsr_q, data_in}};
                lfsr_c[23] = ^ {40'b0100_0011_00000000_10000000_00000000_0100_0011 ^ {lfsr_q, data_in}};
                lfsr_c[24] = ^ {40'b1000_0110_00000001_00000000_00000000_1000_0110 ^ {lfsr_q, data_in}};
                lfsr_c[25] = ^ {40'b0000_1100_00000010_00000000_00000000_0000_1100 ^ {lfsr_q, data_in}};
                lfsr_c[26] = ^ {40'b0101_1001_00000100_00000000_00000000_0101_1001 ^ {lfsr_q, data_in}};
                lfsr_c[27] = ^ {40'b1011_0010_00001000_00000000_00000000_1011_0010 ^ {lfsr_q, data_in}};
                lfsr_c[28] = ^ {40'b0110_0100_00010000_00000000_00000000_0110_0100 ^ {lfsr_q, data_in}};
                lfsr_c[29] = ^ {40'b1100_1000_00100000_00000000_00000000_1100_1000 ^ {lfsr_q, data_in}};
                lfsr_c[30] = ^ {40'b1001_0000_01000000_00000000_00000000_1001_0000 ^ {lfsr_q, data_in}};
                lfsr_c[31] = ^ {40'b0010_0000_10000000_00000000_00000000_0010_0000 ^ {lfsr_q, data_in}};
            end // always

            always @(posedge clock or posedge reset) begin
                if(reset) begin
                    lfsr_q <= {32{1'b1}};
                end
                else begin
                    lfsr_q <= ivalid ? lfsr_c : lfsr_q;
                end
            end // always
        end
    endgenerate

endmodule // crc
