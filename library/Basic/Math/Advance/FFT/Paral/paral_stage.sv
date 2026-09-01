module paral_stage #(
        parameter SCALE_KCOE = 1,
        parameter DATA_WIDTH = 13
    ) (
        input  iclk,
        input  rstn,

        input  ivaild,
        input  signed [DATA_WIDTH-1:0] ireal [7:0],
        input  signed [DATA_WIDTH-1:0] iimag [7:0],

        output ovaild,
        output signed [DATA_WIDTH-1:0] oreal [7:0],
        output signed [DATA_WIDTH-1:0] oimag [7:0]
    );

    localparam TWIDDLE_WIDTH = 14;
    reg signed [DATA_WIDTH-1:0] mreal [7:0][7:0];
    reg signed [DATA_WIDTH-1:0] mimag [7:0][7:0];
    wire [7:0] mvaild;
    wire [7:0]  vaild;

    int i;

    // line 1
    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[0][i] <= 0;
                mimag[0][i] <= 0;
            end
        end
        else begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[0][i] <= ireal[i];
                mimag[0][i] <= iimag[i];
            end
        end
    end

    // line 2
    // 1,   0.707 - 0.707i, -i, -0.707 - 0.707i
    // -1, -0.707 + 0.707i,  i,  0.707 + 0.707i
    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[1][i] <= 0;
            end
        end
        else begin
            // 1
            mreal[1][0] <= ireal[0]; 
            mimag[1][0] <= iimag[0];

            // 0.707 - 0.707i 
            mreal[1][1] <= (($signed(ireal[1]) + $signed(iimag[1])) * 2895) >> TWIDDLE_WIDTH;
            mimag[1][1] <= (($signed(iimag[1]) - $signed(ireal[1])) * 2895) >> TWIDDLE_WIDTH;

            // -i
            mreal[1][2] <=  iimag[2];
            mimag[1][2] <= -ireal[2];

            // -0.707 - 0.707i
            mreal[1][3] <= (($signed(iimag[3]) - $signed(ireal[3])) *  2895) >> TWIDDLE_WIDTH;
            mimag[1][3] <= (($signed(ireal[3]) + $signed(iimag[3])) * -2895) >> TWIDDLE_WIDTH;

            // -1
            mreal[1][4] <= -ireal[4]; 
            mimag[1][4] <= -iimag[4];

            // -0.707 + 0.707i
            mreal[1][5] <= (($signed(iimag[5]) + $signed(ireal[5])) * -2895) >> TWIDDLE_WIDTH;
            mimag[1][5] <= (($signed(ireal[5]) - $signed(iimag[5])) *  2895) >> TWIDDLE_WIDTH;

            // i
            mreal[1][6] <= -iimag[6];
            mimag[1][6] <=  ireal[6];

            // 0.707 + 0.707i
            mreal[1][7] <= (($signed(ireal[7]) - $signed(iimag[7])) * 2895) >> TWIDDLE_WIDTH;
            mimag[1][7] <= (($signed(ireal[7]) + $signed(iimag[7])) * 2895) >> TWIDDLE_WIDTH;
        end
    end

    // line 3
    // 1, -i, -1, i
    // 1, -i, -1, i
    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[2][i] <= 0;
                mimag[2][i] <= 0;
            end
        end
        else begin
            // 1
            mreal[2][0] <= ireal[0]; 
            mimag[2][0] <= iimag[0];

            // -i
            mreal[2][1] <=  iimag[1];
            mimag[2][1] <= -ireal[1];

            // -1
            mreal[2][2] <= -ireal[2]; 
            mimag[2][2] <= -iimag[2];

            // i
            mreal[2][3] <= -iimag[3];
            mimag[2][3] <=  ireal[3];

            // 1
            mreal[2][4] <= ireal[4]; 
            mimag[2][4] <= iimag[4];

            // -i
            mreal[2][5] <=  iimag[5];
            mimag[2][5] <= -ireal[5];

            // -1
            mreal[2][6] <= -ireal[6]; 
            mimag[2][6] <= -iimag[6];

            // i
            mreal[2][7] <= -iimag[7];
            mimag[2][7] <=  ireal[7];
        end
    end

    // line 4
    // 1,  -0.707 - 0.707i,  i,  0.707 - 0.707i
    // -1,  0.707 + 0.707i, -i, -0.707 + 0.707i
    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[3][i] <= 0;
                mimag[3][i] <= 0;
            end
        end
        else begin
            // 1
            mreal[3][0] <= ireal[0]; 
            mimag[3][0] <= iimag[0];

            // -0.707 - 0.707i
            mreal[3][1] <= (($signed(iimag[1]) - $signed(ireal[1])) *  2895) >> TWIDDLE_WIDTH;
            mimag[3][1] <= (($signed(ireal[1]) + $signed(iimag[1])) * -2895) >> TWIDDLE_WIDTH;
           
            // i
            mreal[3][2] <= -iimag[2];
            mimag[3][2] <=  ireal[2];
           
            // 0.707 - 0.707i 
            mreal[3][3] <= (($signed(ireal[3]) + $signed(iimag[3])) * 2895) >> TWIDDLE_WIDTH;
            mimag[3][3] <= (($signed(iimag[3]) - $signed(ireal[3])) * 2895) >> TWIDDLE_WIDTH;
           
            // -1
            mreal[3][4] <= -ireal[4]; 
            mimag[3][4] <= -iimag[4];

            // 0.707 + 0.707i
            mreal[3][5] <= (($signed(ireal[5]) - $signed(iimag[5])) * 2895) >> TWIDDLE_WIDTH;
            mimag[3][5] <= (($signed(ireal[5]) + $signed(iimag[5])) * 2895) >> TWIDDLE_WIDTH;

            // -i
            mreal[3][6] <=  iimag[6];
            mimag[3][6] <= -ireal[6];

            // -0.707 + 0.707i
            mreal[3][7] <= (($signed(iimag[7]) + $signed(ireal[7])) * -2895) >> TWIDDLE_WIDTH;
            mimag[3][7] <= (($signed(ireal[7]) - $signed(iimag[7])) *  2895) >> TWIDDLE_WIDTH;
        end
    end

    // line 5
    // 1, -1, 1, -1
    // 1, -1, 1, -1
    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[4][i] <= 0;
                mimag[4][i] <= 0;
            end
        end
        else begin
            // 1
            mreal[4][0] <= ireal[0]; 
            mimag[4][0] <= iimag[0];

            // -1
            mreal[4][1] <= -ireal[1];
            mimag[4][1] <= -iimag[1];

            // 1
            mreal[4][2] <= ireal[2]; 
            mimag[4][2] <= iimag[2];

            // -1
            mreal[4][3] <= -ireal[3];
            mimag[4][3] <= -iimag[3];

            // 1
            mreal[4][4] <= ireal[4]; 
            mimag[4][4] <= iimag[4];

            // -1
            mreal[4][5] <= -ireal[5];
            mimag[4][5] <= -iimag[5];

            // 1
            mreal[4][6] <= ireal[6]; 
            mimag[4][6] <= iimag[6];

            // -1
            mreal[4][7] <= -ireal[7];
            mimag[4][7] <= -iimag[7];
        end
    end

    // line 6
    // 1,  -0.707 + 0.707i, -i,  0.707 + 0.707i
    // -1,  0.707 - 0.707i,  i, -0.707 - 0.707i
    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[5][i] <= 0;
                mimag[5][i] <= 0;
            end
        end
        else begin
            // 1
            mreal[5][0] <= ireal[0]; 
            mimag[5][0] <= iimag[0];

            // -0.707 + 0.707i
            mreal[5][1] <= (($signed(iimag[1]) + $signed(ireal[1])) * -2895) >> TWIDDLE_WIDTH;
            mimag[5][1] <= (($signed(ireal[1]) - $signed(iimag[1])) *  2895) >> TWIDDLE_WIDTH;
            
            // -i
            mreal[5][2] <=  iimag[2];
            mimag[5][2] <= -ireal[2];
            
            // 0.707 + 0.707i
            mreal[5][3] <= (($signed(ireal[3]) - $signed(iimag[3])) * 2895) >> TWIDDLE_WIDTH;
            mimag[5][3] <= (($signed(ireal[3]) + $signed(iimag[3])) * 2895) >> TWIDDLE_WIDTH;
            
            // -1
            mreal[5][4] <= -ireal[4]; 
            mimag[5][4] <= -iimag[4];
            
            // 0.707 - 0.707i 
            mreal[5][5] <= (($signed(ireal[5]) + $signed(iimag[5])) * 2895) >> TWIDDLE_WIDTH;
            mimag[5][5] <= (($signed(iimag[5]) - $signed(ireal[5])) * 2895) >> TWIDDLE_WIDTH;
            
            // i
            mreal[5][6] <= -iimag[6];
            mimag[5][6] <=  ireal[6];
           
            // -0.707 - 0.707i
            mreal[5][7] <= (($signed(iimag[7]) - $signed(ireal[7])) *  2895) >> TWIDDLE_WIDTH;
            mimag[5][7] <= (($signed(ireal[7]) + $signed(iimag[7])) * -2895) >> TWIDDLE_WIDTH;
        end
    end

    // line 7
    // 1, i, -1, -i
    // 1, i, -1, -i
    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[6][i] <= 0;
                mimag[6][i] <= 0;
            end
        end
        else begin
            // 1
            mreal[6][0] <= ireal[0]; 
            mimag[6][0] <= iimag[0];

            // i
            mreal[6][1] <= -iimag[1];
            mimag[6][1] <=  ireal[1];
            
            // -1
            mreal[6][2] <= -ireal[2]; 
            mimag[6][2] <= -iimag[2];
            
            // -i
            mreal[6][3] <=  iimag[3];
            mimag[6][3] <= -ireal[3];

            // 1
            mreal[6][4] <= ireal[4]; 
            mimag[6][4] <= iimag[4];

            // i
            mreal[6][5] <= -iimag[5];
            mimag[6][5] <=  ireal[5];
            
            // -1
            mreal[6][6] <= -ireal[6]; 
            mimag[6][6] <= -iimag[6];
            
            // -i
            mreal[6][7] <=  iimag[7];
            mimag[6][7] <= -ireal[7];
        end
    end

    // line 8
    //  1,  0.707 + 0.707i,  i, -0.707 + 0.707i
    // -1, -0.707 - 0.707i, -i,  0.707 - 0.707i
    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 8; i=i+1) begin
                mreal[7][i] <= 0;
                mimag[7][i] <= 0;
            end
        end
        else begin
            // 1
            mreal[7][0] <= ireal[0]; 
            mimag[7][0] <= iimag[0];

            // 0.707 + 0.707i
            mreal[7][1] <= (($signed(ireal[1]) - $signed(iimag[1])) * 2895) >> TWIDDLE_WIDTH;
            mimag[7][1] <= (($signed(ireal[1]) + $signed(iimag[1])) * 2895) >> TWIDDLE_WIDTH;
            
            // i
            mreal[7][2] <= -iimag[2];
            mimag[7][2] <=  ireal[2];
           
            // -0.707 + 0.707i
            mreal[7][3] <= (($signed(iimag[3]) + $signed(ireal[3])) * -2895) >> TWIDDLE_WIDTH;
            mimag[7][3] <= (($signed(ireal[3]) - $signed(iimag[3])) *  2895) >> TWIDDLE_WIDTH;
            
            // -1
            mreal[7][4] <= -ireal[4]; 
            mimag[7][4] <= -iimag[4];
            
            // -0.707 - 0.707i
            mreal[7][5] <= (($signed(iimag[5]) - $signed(ireal[5])) *  2895) >> TWIDDLE_WIDTH;
            mimag[7][5] <= (($signed(ireal[5]) + $signed(iimag[5])) * -2895) >> TWIDDLE_WIDTH;

            // -i
            mreal[7][6] <=  iimag[6];
            mimag[7][6] <= -ireal[6];
            
            // 0.707 - 0.707i 
            mreal[7][7] <= (($signed(ireal[7]) + $signed(iimag[7])) * 2895) >> TWIDDLE_WIDTH;
            mimag[7][7] <= (($signed(iimag[7]) - $signed(ireal[7])) * 2895) >> TWIDDLE_WIDTH;        
        end
    end

    genvar n;
    generate for(n = 0 ; n < 8; n = n + 1) begin : U      
        paral_8add #(
            .DATA_WIDTH(DATA_WIDTH))
        u0_paral_8add(
            .iclk       ( iclk ),
            .rstn       ( rstn ),

            .ivaild     ( mvaild   ),
            .rink       ( mreal[n] ),
            .iink       ( mimag[n] ),

            .ovaild     ( vaild[n] ),
            .rout       ( oreal[n] ),
            .iout       ( oreal[n] )
        );
    end
    endgenerate

    assign ovaild = vaild[0];
    
endmodule

module paral_8add #(
        parameter DATA_WIDTH = 12
    ) (
        input  iclk,
        input  rstn,

        input  ivaild,
        input signed  [DATA_WIDTH-1:0] rink [7:0],
        input signed  [DATA_WIDTH-1:0] iink [7:0],

        output ovaild,
        output signed [DATA_WIDTH+2:0] rout,
        output signed [DATA_WIDTH+2:0] iout
    );

    reg signed [DATA_WIDTH:0]   L1rout [3:0];
    reg signed [DATA_WIDTH:0]   L1iout [3:0];

    reg signed [DATA_WIDTH+1:0] L2rout [1:0];
    reg signed [DATA_WIDTH+1:0] L2iout [1:0];

    reg signed [DATA_WIDTH+2:0] L3rout;
    reg signed [DATA_WIDTH+2:0] L3iout;

    reg [3:0] vaild;
    integer i;

    always @(posedge iclk or negedge rstn) begin
        if (!rstn) begin
            vaild <= 0;
        end else begin    
            vaild <= {vaild[2:0], ivaild};
        end
    end

    assign ovaild = vaild[3];

    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            for (i = 0; i < 4; i=i+1) begin
                L1rout[i] <= 0;
                L1iout[i] <= 0;
            end
        end
        else begin
            L1rout[0] <= $signed(rink[0]) + $signed(rink[1]);
            L1rout[1] <= $signed(rink[2]) + $signed(rink[3]);
            L1rout[2] <= $signed(rink[4]) + $signed(rink[5]);
            L1rout[3] <= $signed(rink[6]) + $signed(rink[7]);

            L1iout[0] <= $signed(iink[0]) + $signed(iink[1]);
            L1iout[1] <= $signed(iink[2]) + $signed(iink[3]);
            L1iout[2] <= $signed(iink[4]) + $signed(iink[5]);
            L1iout[3] <= $signed(iink[6]) + $signed(iink[7]);
        end
    end

    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            L2rout[0] <= 0;
            L2rout[1] <= 0;
            L2iout[0] <= 0;
            L2iout[1] <= 0;
        end
        else begin
            L2rout[0] <= $signed(L1rout[0]) + $signed(L1rout[1]);
            L2rout[1] <= $signed(L1rout[2]) + $signed(L1rout[3]);

            L2iout[0] <= $signed(L1iout[0]) + $signed(L1iout[1]);
            L2iout[1] <= $signed(L1iout[2]) + $signed(L1iout[3]);
        end
    end

    always @(posedge iclk or negedge rstn) begin
        if(!rstn) begin
            L3rout <= 0;
            L3iout <= 0;
        end
        else begin
            L3rout <= $signed(L2rout[0]) + $signed(L2rout[1]);
            L3iout <= $signed(L2iout[0]) + $signed(L2iout[1]);
        end
    end

    assign rout = L3rout;
    assign rout = L3rout;

endmodule  // paral_8add
