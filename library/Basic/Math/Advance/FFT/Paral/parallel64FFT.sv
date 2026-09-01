module parallel64FFT #(
        parameter SCALE_KCOE = 1,
        parameter DATA_WIDTH = 13
    ) (
        input  iclk,
        input  rstn,

        input  ivaild,
        input  signed [DATA_WIDTH-1:0] ireal [7:0][7:0],
        input  signed [DATA_WIDTH-1:0] iimag [7:0][7:0],

        output ovaild,
        output signed [DATA_WIDTH-1:0] oreal [7:0][7:0],
        output signed [DATA_WIDTH-1:0] oimag [7:0][7:0]
    );

    localparam CPMULT_DLY = 2;

    reg [CPMULT_DLY:0] rvaild;

    wire [7:0] mvaild;
    wire signed [DATA_WIDTH-1:0] mreal [7:0][7:0];
    wire signed [DATA_WIDTH-1:0] mimag [7:0][7:0];

    wire signed [DATA_WIDTH-1:0] wreal [7:0][7:0];
    wire signed [DATA_WIDTH-1:0] wimag [7:0][7:0];

    wire signed [DATA_WIDTH-1:0] nreal [7:0][7:0];
    wire signed [DATA_WIDTH-1:0] nimag [7:0][7:0];

    wire [7:0]  vaild;

    genvar n;
    generate for(n = 0 ; n < 8; n = n + 1) begin : U0
        paral_stage u_parallel8FFT (
            .iclk (iclk),
            .rstn (rstn),

            .ivaild (ivaild),
            .ireal  (ireal[n]),
            .iimag  (iimag[n]),

            .ovaild (mvaild[n]),
            .oreal  (mreal[n]),
            .oimag  (mimag[n])
        );
    end
    endgenerate

    wire [12:0] rtwiddle [63:0];
    wire [12:0] itwiddle [63:0];
    ptwiddle (
        .rtwiddle ( rtwiddle ),
        .itwiddle ( itwiddle )
    );

    genvar i;
    generate for(i = 0 ; i < 64; i = i + 1) begin : U1      
        cmpl_mul #(
            .CPMULT_DLY         ( CPMULT_DLY   ),
            .SCALE_KCOE 		( SCALE_KCOE ),
            .REAL_WIDTH_A 		( DATA_WIDTH   ),
            .IMAG_WIDTH_A 		( DATA_WIDTH   ),
  
            .REAL_WIDTH_B 		( DATA_WIDTH   ),
            .IMAG_WIDTH_B 		( DATA_WIDTH   ),
  
            .REAL_WIDTH_O 		( DATA_WIDTH   ),
            .IMAG_WIDTH_O 		( DATA_WIDTH   ))
        u_cmpl_mul(
            //ports
            .iclk      		( iclk ),
            .rstn     		( rstn ),

            .dataa_r  		( mreal[i/8][i%8] ),
            .dataa_i  		( mimag[i/8][i%8] ),

            .datab_r  		( rtwiddle[i] ),
            .datab_i  		( itwiddle[i] ),

            .result_r 		( wreal[i/8][i%8] ),
            .result_i 		( wimag[i/8][i%8] )
        );
    end
    endgenerate 

    always @(posedge iclk or negedge rstn) begin
        if (!rstn) begin
            rvaild <= 0;
        end else begin    
            rvaild <= {rvaild[CPMULT_DLY-1:0], mvaild[0]};
        end
    end
    
    assign nreal[0] = {wreal[0][0], wreal[1][0], wreal[2][0], wreal[3][0], wreal[4][0], wreal[5][0], wreal[6][0], wreal[7][0]};
    assign nreal[1] = {wreal[0][1], wreal[1][1], wreal[2][1], wreal[3][1], wreal[4][1], wreal[5][1], wreal[6][1], wreal[7][1]};
    assign nreal[2] = {wreal[0][2], wreal[1][2], wreal[2][2], wreal[3][2], wreal[4][2], wreal[5][2], wreal[6][2], wreal[7][2]};
    assign nreal[3] = {wreal[0][3], wreal[1][3], wreal[2][3], wreal[3][3], wreal[4][3], wreal[5][3], wreal[6][3], wreal[7][3]};
    assign nreal[4] = {wreal[0][4], wreal[1][4], wreal[2][4], wreal[3][4], wreal[4][4], wreal[5][4], wreal[6][4], wreal[7][4]};
    assign nreal[5] = {wreal[0][5], wreal[1][5], wreal[2][5], wreal[3][5], wreal[4][5], wreal[5][5], wreal[6][5], wreal[7][5]};
    assign nreal[6] = {wreal[0][6], wreal[1][6], wreal[2][6], wreal[3][6], wreal[4][6], wreal[5][6], wreal[6][6], wreal[7][6]};
    assign nreal[7] = {wreal[0][7], wreal[1][7], wreal[2][7], wreal[3][7], wreal[4][7], wreal[5][7], wreal[6][7], wreal[7][7]};

    assign nimag[0] = {wimag[0][0], wimag[1][0], wimag[2][0], wimag[3][0], wimag[4][0], wimag[5][0], wimag[6][0], wimag[7][0]};
    assign nimag[1] = {wimag[0][1], wimag[1][1], wimag[2][1], wimag[3][1], wimag[4][1], wimag[5][1], wimag[6][1], wimag[7][1]};
    assign nimag[2] = {wimag[0][2], wimag[1][2], wimag[2][2], wimag[3][2], wimag[4][2], wimag[5][2], wimag[6][2], wimag[7][2]};
    assign nimag[3] = {wimag[0][3], wimag[1][3], wimag[2][3], wimag[3][3], wimag[4][3], wimag[5][3], wimag[6][3], wimag[7][3]};
    assign nimag[4] = {wimag[0][4], wimag[1][4], wimag[2][4], wimag[3][4], wimag[4][4], wimag[5][4], wimag[6][4], wimag[7][4]};
    assign nimag[5] = {wimag[0][5], wimag[1][5], wimag[2][5], wimag[3][5], wimag[4][5], wimag[5][5], wimag[6][5], wimag[7][5]};
    assign nimag[6] = {wimag[0][6], wimag[1][6], wimag[2][6], wimag[3][6], wimag[4][6], wimag[5][6], wimag[6][6], wimag[7][6]};
    assign nimag[7] = {wimag[0][7], wimag[1][7], wimag[2][7], wimag[3][7], wimag[4][7], wimag[5][7], wimag[6][7], wimag[7][7]};

    genvar m;
    generate for(m = 0 ; m < 8; m = m + 1) begin : U2      
        paral_stage u_parallel8FFT (
            .iclk (iclk),
            .rstn (rstn),

            .ivaild (rvaild[CPMULT_DLY]),
            .ireal  (nreal[m]),
            .iimag  (nimag[m]),

            .ovaild (vaild[m]),
            .oreal  (oreal[m]),
            .oimag  (oimag[m])
        );
    end
    endgenerate

    assign ovaild = vaild[0];
    
endmodule