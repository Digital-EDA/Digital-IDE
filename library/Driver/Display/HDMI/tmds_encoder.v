/*
----------------------------------------
Stereoscopic Vision System
Senior Design Project - Team 11
California State University, Sacramento
Spring 2015 / Fall 2015
----------------------------------------

TMDS Encoder

Authors:  Greg M. Crist, Jr. (gmcrist@gmail.com)

Description:
  TMDS Encoder
*/
module tmds_encoder(
        input clock,          // Clock signal
        input reset,          // Reset signal (active-low)
        input den,          // Display idata or control idata

        input [1:0] ctrl,   // Control bits
        input [7:0] idata,   // Input idata
        output reg [9:0] tmds  // TMDS output
    );

    // # of ones for idata, # of ones for q_m, # of zeros for q_m
    reg [3:0] n1d;
    reg [3:0] n1q_m;
    reg [3:0] n0q_m;

    // Buffer for first stage idata input
    reg [7:0] data_buf;

    // Buffer for first stage idata output
    wire [8:0] q_m;

    // operation for 1st stage idata transformation
    wire op;

    // signals for pipelining
    reg disp_en_q;
    reg disp_en_reg;
    reg [1:0] ctrl_q;
    reg [1:0] ctrl_reg;
    reg [8:0] q_m_reg;

    // Disparity counter
    reg [4:0] disparity;

    // 1st stage: 8-bit to 9-bit transformation

    // Determine XNOR vs XOR operation
    assign op = (n1d > 4'd4) || (n1d == 4'd4 && idata[0] == 1'b0);

    // Perform operation
    assign q_m[0] = data_buf[0];
    assign q_m[1] = (op) ? (q_m[0] ^~ data_buf[1]) : (q_m[0] ^ data_buf[1]);
    assign q_m[2] = (op) ? (q_m[1] ^~ data_buf[2]) : (q_m[1] ^ data_buf[2]);
    assign q_m[3] = (op) ? (q_m[2] ^~ data_buf[3]) : (q_m[2] ^ data_buf[3]);
    assign q_m[4] = (op) ? (q_m[3] ^~ data_buf[4]) : (q_m[3] ^ data_buf[4]);
    assign q_m[5] = (op) ? (q_m[4] ^~ data_buf[5]) : (q_m[4] ^ data_buf[5]);
    assign q_m[6] = (op) ? (q_m[5] ^~ data_buf[6]) : (q_m[5] ^ data_buf[6]);
    assign q_m[7] = (op) ? (q_m[6] ^~ data_buf[7]) : (q_m[6] ^ data_buf[7]);
    assign q_m[8] = (op) ? 1'b0 : 1'b1;
    
    always @ (posedge clock or posedge reset) begin
        if (reset) begin
            data_buf <= 0;
            n1d <= 0;
            n1q_m <= 0;
            n0q_m <= 0;
            disp_en_q <= 0;
            disp_en_reg <= 0;
            ctrl_q <= 0;
            ctrl_reg <= 0;
            q_m_reg <= 0;
        end
        else begin            
            data_buf <= idata;

            // Count the ones in the input idata
            n1d <= idata[0] + idata[1] + idata[2] + idata[3] + idata[4] + idata[5] + idata[6] + idata[7];

            // Count the ones from the first stage idata
            n1q_m <= q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];

            // Count the zeros from the first stage idata
            n0q_m <= 4'h8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);

            // Pipelining of key signals
            disp_en_q   <= den;
            disp_en_reg <= disp_en_q;

            ctrl_q      <= ctrl;
            ctrl_reg    <= ctrl_q;

            q_m_reg     <= q_m;
        end
    end

    // 2nd stage: 9-bit to 10-bit transformation
    always @ (posedge clock or posedge reset) begin
        if (reset) begin
            tmds <= 10'd0;
            disparity <= 5'd0;
        end
        else begin
            if (disp_en_reg) begin
                if ((disparity == 5'h0) | (n1q_m == n0q_m)) begin
                    tmds[9]   <= ~q_m_reg[8];
                    tmds[8]   <= q_m_reg[8];
                    tmds[7:0] <= (q_m_reg[8]) ? q_m_reg[7:0] : ~q_m_reg[7:0];

                    disparity <= (~q_m_reg[8]) ? (disparity + n0q_m - n1q_m) : (disparity + n1q_m - n0q_m);
                end
                else begin
                    if ((~disparity[4] & (n1q_m > n0q_m)) | (disparity[4] & (n0q_m > n1q_m))) begin
                        tmds[9]   <= 1'b1;
                        tmds[8]   <= q_m_reg[8];
                        tmds[7:0] <= ~q_m_reg[7:0];

                        disparity <= disparity + {q_m_reg[8], 1'b0} + (n0q_m - n1q_m);
                    end
                    else begin
                        tmds[9]   <= 1'b0;
                        tmds[8]   <= q_m_reg[8];
                        tmds[7:0] <= q_m_reg[7:0];

                        disparity <= disparity - {~q_m_reg[8], 1'b0} + (n1q_m - n0q_m);
                    end
                end
            end
            else begin
                // Control idata from: https://en.wikipedia.org/wiki/Transition-minimized_differential_signaling
                case (ctrl_reg)
                    2'b00: tmds <= 10'b1101010100;
                    2'b01: tmds <= 10'b0010101011;
                    2'b10: tmds <= 10'b0101010100;
                    default: tmds <= 10'b1010101011;
                endcase
    
                disparity <= 4'd0;
            end
        end
    end
endmodule