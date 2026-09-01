`timescale 1ns / 1ps

module AnalogMod #(
        parameter MODULE_TYPE  = "AMP",
        parameter ISDSBSC_SET  = 0,
        parameter INPUT_WIDTH  = 12,
        parameter PHASE_WIDTH  = 32,
        parameter MODUL_WIDTH  = 16,
        parameter OUTPUT_WIDTH = 12
    ) (
        input                     clk_cw,
        input                     clk_sw,
        input                     reset,

        input  [INPUT_WIDTH-1:0]  wave_in,

        //(fre*2^PHASE_WIDTH)/Fc
        input  [PHASE_WIDTH-1:0]  fre_word,     

        input  [PHASE_WIDTH-1:0]  pha_word, 

        //(2^DEEP_WIDTH-1)*percent
        input  [MODUL_WIDTH-1:0]  mod_word,

        input  [MODUL_WIDTH-1:0]  amp_word,

        output [OUTPUT_WIDTH-1:0] mod_wave
    );

    localparam SIGNAL_WIDTH = INPUT_WIDTH + MODUL_WIDTH;
    localparam OSHIFT_WIDTH = INPUT_WIDTH + MODUL_WIDTH - OUTPUT_WIDTH;
    localparam PSHIFT_WIDTH = INPUT_WIDTH + MODUL_WIDTH - PHASE_WIDTH;

    reg  signed [SIGNAL_WIDTH:0] wave;
    reg  [PHASE_WIDTH-1:0] pha;
    reg  [PHASE_WIDTH-1:0] fre;
    reg  [9:0]  addr;

    wire signed [15:0] sin;
    wire signed [15:0] out;
    wire [MODUL_WIDTH-1:0] modul_wave;
    wire [PHASE_WIDTH-1:0] Q;

    always @(posedge clk_sw or posedge reset) begin
        if(reset) begin
            wave <= 0;
        end
        else begin
            wave <= $signed(wave_in) * $signed({1'b0, mod_word});
        end
    end

    generate 
        if(MODULE_TYPE == "AMP") begin : AMP
            // add DC value or not
            wire [MODUL_WIDTH-1:0] modul_am__wave = {~wave[SIGNAL_WIDTH-1], wave[SIGNAL_WIDTH-2:INPUT_WIDTH]};
            wire [MODUL_WIDTH-1:0] modul_dsb_wave = wave[SIGNAL_WIDTH-1:INPUT_WIDTH];
            assign modul_wave = ISDSBSC_SET ? modul_dsb_wave : modul_am__wave;
            
            // frequence
            always @(posedge clk_cw or posedge reset) begin
                if(reset) begin
                    fre <= 0;
                end
                else begin
                    fre <= fre_word;
                end
            end

            // phase
            always @(posedge clk_cw or posedge reset) begin
                if(reset) begin
                    pha <= 0;
                end
                else begin
                    pha <= Q + pha_word;
                end
            end

            // amplitude
            reg signed [MODUL_WIDTH+16:0] modul_out;
            always @(posedge clk_cw or posedge reset) begin
                if(reset) begin
                    modul_out <= 0;
                end
                else begin
                    modul_out <= $signed({1'b0, modul_wave}) * $signed(sin);
                end
            end
            assign out = modul_out[MODUL_WIDTH+15:MODUL_WIDTH];

            // mult u0_mult(
            //     .CLK ( clk_cw       ),
            //     .A   ( sin          ),
            //     .B   ( modul_wave   ),
            //     .P   ( out          )
            // );
        end
        else if(MODULE_TYPE == "FRE") begin : AMP
            wire signed [PHASE_WIDTH:0] modul_fm__wave = (PSHIFT_WIDTH > 0) ? 
                                                         ((wave<<<1) >>> ( PSHIFT_WIDTH)) : 
                                                         ((wave<<<1) <<< (-PSHIFT_WIDTH));

            // frequence
            always @(posedge clk_sw or posedge reset) begin
                if(reset) begin
                    fre <= 0;
                end
                else begin
                    fre <= $signed(modul_fm__wave) + $signed({1'd0,fre_word});
                end
            end

            // phase
            always @(posedge clk_cw or posedge reset) begin
                if(reset) begin
                    pha <= 0;
                end
                else begin
                    pha <= Q + pha_word;
                end
            end

            // amplitude
            assign out = sin;
        end
        else if(MODULE_TYPE == "PHA") begin : AMP
            wire signed [PHASE_WIDTH:0] modul_pm__wave = (PSHIFT_WIDTH > 0) ? 
                                                         ((wave<<<1) >>> ( PSHIFT_WIDTH)) : 
                                                         ((wave<<<1) <<< (-PSHIFT_WIDTH));

            // frequence
            always @(posedge clk_cw or posedge reset) begin
                if(reset) begin
                    fre <= 0;
                end
                else begin
                    fre <= fre_word;
                end
            end

            // phase
            reg signed [MODUL_WIDTH+16:0] modul_out;
            always @(posedge clk_sw or posedge reset) begin
                if(reset) begin
                    modul_out <= 0;
                end
                else begin
                    modul_out <= pha_word + modul_pm__wave;
                end
            end

            always @(posedge clk_cw or posedge reset) begin
                if(reset) begin
                    pha <= 0;
                end
                else begin
                    pha <= Q + modul_out;
                end
            end

            // amplitude
            assign out = sin;
        end
    endgenerate
    
    accuml #(
        .WIDTH 		( PHASE_WIDTH   ))
    u_accuml(
        //ports
        .clock   		( clk_cw    ),
        .reset   		( reset     ),
        .clr     		( reset     ),
        .add_sub 		( 1'b0      ),
        .D       		( fre       ),
        .Q       		( Q         )
    );

    always @(posedge clk_cw or posedge reset) begin
        if (reset) begin
            addr <= 0;
        end
        else begin
            addr <= pha[PHASE_WIDTH-1:PHASE_WIDTH-10];
        end
    end

    Sin u_Sin(
        //ports
        .clka  		( clk_cw    ),
        .rsta  		( reset     ),
        .addra 		( addr      ),
        .douta 		( sin       )
    );

    // wire signed [15:0] amp_out;
    // mult u1_mult(
    //     .CLK ( clk_cw       ),
    //     .A   ( out          ),
    //     .B   ( amp_word     ),
    //     .P   ( amp_out      )
    // );

    // assign mod_wave = (amp_out >>> (16-OUTPUT_WIDTH));

    reg signed [MODUL_WIDTH+16:0] amp_out;
    always @(posedge clk_cw or posedge reset) begin
        if(reset) begin
            amp_out <= 0;
        end
        else begin
            amp_out <= $signed(out) * $signed({1'b0, amp_word});
        end
    end

    assign mod_wave = (OSHIFT_WIDTH > 0) ? ((amp_out<<<1) >>>   OSHIFT_WIDTH+1) : 
                                           ((amp_out<<<1) <<< (-OSHIFT_WIDTH+1));

endmodule
