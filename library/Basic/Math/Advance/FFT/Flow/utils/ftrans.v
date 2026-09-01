`timescale 1ns/100ps
module ftrans #(
        parameter   FFT_STAGE = 7,

        // 1 : complex multiplications by twiddle
        // 0 : only  real-imaginary swapping and sign inversion 
        parameter   TRANS_MODE = 1,
        parameter   TWIDD_MODE = 1,
        parameter   TOTAL_STEP = 10,
        parameter   SCALE_KCOE = 1,
        parameter   TWID_WIDTH = 18,
        parameter   DATA_WIDTH = 18
    ) (
        input  iclk,
        input  rstn,
 
        input  ien,
        input  [TOTAL_STEP-1:0]   iaddr,
        input  [2*DATA_WIDTH-1:0] idata,

        output oen,
        output [TOTAL_STEP-1:0]   oaddr,
        output [2*DATA_WIDTH-1:0] odata
    );

    localparam CPLX_WIDTH = 2*DATA_WIDTH;

    localparam REAL_MSB = 2*DATA_WIDTH-1;        // 35
    localparam REAL_LSB = DATA_WIDTH;            // 18
    localparam IMAG_MSB = DATA_WIDTH - 1;        // 17
    localparam IMAG_LSB = 0;                    // 0

    // from multiply complex to complex
    localparam REAL_MMSB = 2*DATA_WIDTH-3;        // 33
    localparam REAL_MLSB = DATA_WIDTH-2;        // 16
    localparam IMAG_MMSB = 2*DATA_WIDTH-3;        // 33
    localparam IMAG_MLSB = DATA_WIDTH-2;        // 16

    reg roen;
    reg [TOTAL_STEP-1:0]   roaddr;
    reg [2*DATA_WIDTH-1:0] rodata;

    wire k1 = iaddr[FFT_STAGE-1];
    wire k2 = iaddr[FFT_STAGE-2];

    generate
        if(TRANS_MODE) begin : twiddle
            reg  [1:0]              valid;
            reg  [FFT_STAGE-1:0]    taddr;
            reg [TOTAL_STEP-1:0]    daddr;
            wire                    tvalid;
            wire [2*DATA_WIDTH-1:0] tdata; 

            wire [TWID_WIDTH-1:0]   twiddle_ore;
            wire [TWID_WIDTH-1:0]   twiddle_oim;

            wire                    mvalid;
            wire [DATA_WIDTH-1:0]   mul_ore;
            wire [DATA_WIDTH-1:0]   mul_oim;

            wire [FFT_STAGE-3:0] n3 = iaddr[FFT_STAGE-3:0];
            wire [FFT_STAGE-2:0] addr1 = k1 ? {1'b0, n3} : { (FFT_STAGE-1) {1'b0} };
            wire [FFT_STAGE-2:0] addr2 = k2 ? {n3, 1'b0} : { (FFT_STAGE-1) {1'b0} };

            always @(posedge iclk or negedge rstn) begin
                if (!rstn) begin
                    taddr <= 0;
                    valid <= 0;
                end 
                else begin
                    taddr <= addr1 + addr2;

                    valid[0] <= ien;
                    valid[1] <= valid[0];
                end
            end

            if (TWIDD_MODE) begin : ROM
                reg  [2*DATA_WIDTH-1:0] rdata; // register for delay idata
                reg  [2*DATA_WIDTH-1:0] cdata; // register for calculated idata

                always @(posedge iclk or negedge rstn) begin
                    if (!rstn) begin
                        rdata <= 0;
                        cdata <= 0;
                    end 
                    else begin
                        rdata <= idata;
                        cdata <= rdata;
                    end
                end

                ftwiddle #(
                    .FTWI_STAGE ( FFT_STAGE ))
                u_ftwiddle(
                    .iclk ( iclk        ),
                    .rstn ( rstn        ),
                    .idx  ( taddr       ),
                    .ore  ( twiddle_ore ),
                    .oim  ( twiddle_oim )
                );

                assign tvalid = valid[1];
                assign tdata = cdata;
            end
            else begin : CORDIC
                localparam ITERATIONS = (TWIDD_MODE[7:4] == 0) ? 16 : TWIDD_MODE[7:4];
                localparam XV_INITIAL = (1<<(TWID_WIDTH-2))-1;
                localparam SHIFT_LENG = ITERATIONS + 2;
                
                wire                  cvalid;
                wire [FFT_STAGE-1:0]  z_o;
                wire [TWID_WIDTH-1:0] cos;
                wire [TWID_WIDTH-1:0] sin;

                wire signed [FFT_STAGE-1:0] taddr_S = -$signed(taddr);
                wire [TWID_WIDTH-1:0]   z_buffer;
                if(FFT_STAGE < TWID_WIDTH) begin
                    assign z_buffer = {taddr_S,{(TWID_WIDTH - FFT_STAGE){1'b0}}};
                end 
                else begin
                    assign z_buffer = taddr_S[FFT_STAGE - 1 : FFT_STAGE - TWID_WIDTH];
                end

                cordic #(
                    .STYLE              ( "ROTATE"      ),
                    .CALMODE            ( "PRECISION"   ),
                    .XY_BITS            ( TWID_WIDTH    ),
                    .PH_BITS            ( TWID_WIDTH    ),
                    .ITERATIONS         ( ITERATIONS    ))
                u_cordic(
                    //ports
                    .clock          ( iclk          ),
                    .reset          ( ~rstn         ),
                    .ivalid         ( valid[0]      ),
                    .x_i            ( XV_INITIAL    ),
                    .y_i            ( 0             ),
                    .z_i            ( z_buffer        ),
                    .ovalid         (           ),
                    .x_o            ( cos           ),
                    .y_o            ( sin           ),
                    .z_o            ( z_o           )
                );

                assign twiddle_ore =  cos;
                assign twiddle_oim =  sin;

                shiftTaps #(
                    .WIDTH         ( CPLX_WIDTH  ),
                    .SHIFT         ( SHIFT_LENG  ))
                u_shiftTaps(
                    //ports
                    .clock      ( iclk        ),
                    .reset      ( ~rstn       ),

                    .ivalid     ( ien         ),
                    .shiftin    ( idata       ),

                    .ovalid     ( tvalid      ),
                    .shiftout   ( tdata       )
                );
            end

            cmplMult #(
                .SCALE_FACTOR(SCALE_KCOE),

                .REAL_WIDTH_A(DATA_WIDTH),
                .IMAG_WIDTH_A(DATA_WIDTH),

                .REAL_WIDTH_B(TWID_WIDTH),
                .IMAG_WIDTH_B(TWID_WIDTH),

                .REAL_WIDTH_O(DATA_WIDTH),
                .IMAG_WIDTH_O(DATA_WIDTH))
            u_cmplMult (
                .clock(iclk),
                .reset(~rstn),
                
                .ivalid(tvalid),
                .dataa_r(tdata[REAL_MSB:REAL_LSB]),
                .dataa_i(tdata[IMAG_MSB:IMAG_LSB]),
                .datab_r(twiddle_ore),
                .datab_i(twiddle_oim),

                .ovalid(mvalid),
                .result_r(mul_ore),
                .result_i(mul_oim)
            );

            always @(posedge iclk or negedge rstn) begin
                if (!rstn) begin
                    roen <= 0;
                    daddr <= 0;
                    roaddr <= 0;
                    rodata <= 0;
                end 
                else begin
                    if (mvalid) begin
                        daddr <= daddr + 1;
                        roaddr <= daddr;
                        rodata <= {mul_ore, mul_oim};
                    end
                    else begin
                        daddr <= 0;
                        roaddr <= 0;
                        rodata <= 0;
                    end
                    roen <= mvalid;
                end
            end
        end
        else begin : inversion
            always @(posedge iclk or negedge rstn) begin
                if (!rstn) begin
                    roen <= 0;
                    rodata <= 0;
                    roaddr <= 0;
                end
                else begin    
                    if({k1, k2} == 2'b11) begin
                        rodata[REAL_MSB:REAL_LSB] <=  idata[IMAG_MSB:IMAG_LSB];
                        rodata[IMAG_MSB:IMAG_LSB] <= -idata[REAL_MSB:REAL_LSB];
                    end
                    else begin
                        rodata <= idata;
                    end
                    roaddr <= iaddr;
                    roen <= ien;
                end
            end
        end
    endgenerate

    assign oen = roen;
    assign oaddr = roaddr;
    assign odata = rodata;

endmodule
