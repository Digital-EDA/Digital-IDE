`timescale 1ns / 1ps
module CLK_Global #(
        parameter MULTIPL      = 20,
        parameter DIVCLK_DIV   = 1,
        parameter CLKIN_PERIOD = 20.000,

        parameter CLKOUT0_DIV = 2,
        parameter CLK0_PHASE  = 0.0,
        parameter CLKOUT1_DIV = 4,
        parameter CLK1_PHASE  = 0.0,
        parameter CLKOUT2_DIV = 5, 
        parameter CLK2_PHASE  = 0.0,
        parameter CLKOUT3_DIV = 10,
        parameter CLK3_PHASE  = 0.0
    ) (
        input     clock,
        input     reset,

        output    clk_out1,
        output    clk_out2,
        output    clk_out3,
        output    clk_out4,

        output    locked
    );

    wire clock_clk_gen;
    IBUF clkin_ibufg (
        .O (clock_clk_gen),
        .I (clock)
    );

    wire        clk_out1_clk_gen;
    wire        clk_out2_clk_gen;
    wire        clk_out3_clk_gen;
    wire        clk_out4_clk_gen;
    wire        clk_out5_clk_gen;
    wire        clk_out6_clk_gen;
    wire        clk_out7_clk_gen;

    wire [15:0] do_unused;
    wire        drdy_unused;
    wire        psdone_unused;
    wire        locked_int;
    wire        clkfbout_clk_gen;
    wire        clkfbout_buf_clk_gen;
    wire        clkfboutb_unused;
    wire 		clkout0b_unused;
    wire 		clkout1b_unused;
    wire 		clkout2b_unused;
    wire 		clkout3b_unused;
    wire 		clkout4_unused;
    wire        clkout5_unused;
    wire        clkout6_unused;
    wire        clkfbstopped_unused;
    wire        clkinstopped_unused;

    MMCME2_ADV # (
        .BANDWIDTH            ("LOW"),
        .CLKOUT4_CASCADE      ("FALSE"),
        .COMPENSATION         ("ZHOLD"),
        .STARTUP_WAIT         ("FALSE"),
        .DIVCLK_DIVIDE        (DIVCLK_DIV),
        .CLKFBOUT_MULT_F      (MULTIPL),
        .CLKFBOUT_PHASE       (0.000),
        .CLKFBOUT_USE_FINE_PS ("FALSE"),

        .CLKOUT0_DIVIDE_F     (CLKOUT0_DIV),
        .CLKOUT0_PHASE        (CLK0_PHASE),
        .CLKOUT0_DUTY_CYCLE   (0.500),
        .CLKOUT0_USE_FINE_PS  ("FALSE"),

        .CLKOUT1_DIVIDE       (CLKOUT1_DIV),
        .CLKOUT1_PHASE        (CLK1_PHASE),
        .CLKOUT1_DUTY_CYCLE   (0.500),
        .CLKOUT1_USE_FINE_PS  ("FALSE"),

        .CLKOUT2_DIVIDE       (CLKOUT2_DIV),
        .CLKOUT2_PHASE        (CLK2_PHASE),
        .CLKOUT2_DUTY_CYCLE   (0.500),
        .CLKOUT2_USE_FINE_PS  ("FALSE"),

        .CLKOUT3_DIVIDE       (CLKOUT3_DIV),
        .CLKOUT3_PHASE        (CLK3_PHASE),
        .CLKOUT3_DUTY_CYCLE   (0.500),
        .CLKOUT3_USE_FINE_PS  ("FALSE"),

        .CLKIN1_PERIOD        (CLKIN_PERIOD))
    mmcm_adv_inst (
        .CLKFBOUT            (clkfbout_clk_gen),
        .CLKFBOUTB           (clkfboutb_unused),

        .CLKOUT0             (clk_out1_clk_gen),
        .CLKOUT0B            (clkout0b_unused),

        .CLKOUT1             (clk_out2_clk_gen),
        .CLKOUT1B            (clkout1b_unused),

        .CLKOUT2             (clk_out3_clk_gen),
        .CLKOUT2B            (clkout2b_unused),

        .CLKOUT3             (clk_out4_clk_gen),
        .CLKOUT3B            (clkout3b_unused),

        .CLKOUT4             (clkout4_unused),
        .CLKOUT5             (clkout5_unused),
        .CLKOUT6             (clkout6_unused),
        // Input clock control
        .CLKFBIN             (clkfbout_buf_clk_gen),
        .CLKIN1              (clock_clk_gen),
        .CLKIN2              (1'b0),
        // Tied to always select the primary input clock
        .CLKINSEL            (1'b1),
        // Ports for dynamic reconfiguration
        .DADDR               (7'h0),
        .DCLK                (1'b0),
        .DEN                 (1'b0),
        .DI                  (16'h0),
        .DO                  (do_unused),
        .DRDY                (drdy_unused),
        .DWE                 (1'b0),
        // Ports for dynamic phase shift
        .PSCLK               (1'b0),
        .PSEN                (1'b0),
        .PSINCDEC            (1'b0),
        .PSDONE              (psdone_unused),
        // Other control and status signals
        .LOCKED              (locked),
        .CLKINSTOPPED        (clkinstopped_unused),
        .CLKFBSTOPPED        (clkfbstopped_unused),
        .PWRDWN              (1'b0),
        .RST                 (reset)
    );

    // PLLE2_ADV #(
    //     .BANDWIDTH           ("OPTIMIZED"),
    //     .COMPENSATION        ("ZHOLD"),
    //     .STARTUP_WAIT        ("FALSE"),
    //     .DIVCLK_DIVIDE       (1),
    //     .CLKFBOUT_MULT       (10),
    //     .CLKFBOUT_PHASE      (0.000),
    //     .CLKOUT0_DIVIDE      (2),
    //     .CLKOUT0_PHASE       (0.000),
    //     .CLKOUT0_DUTY_CYCLE  (0.500),
    //     .CLKIN1_PERIOD       (10.000))
    // plle2_adv_inst (
    //     .CLKFBOUT            (clkfbout_clk_wiz_0),
    //     .CLKOUT0             (clk_out1_clk_wiz_0),
    //     .CLKOUT1             (clkout1_unused),
    //     .CLKOUT2             (clkout2_unused),
    //     .CLKOUT3             (clkout3_unused),
    //     .CLKOUT4             (clkout4_unused),
    //     .CLKOUT5             (clkout5_unused),
    //     // Input clock control
    //     .CLKFBIN             (clkfbout_buf_clk_wiz_0),
    //     .CLKIN1              (clk_in1_clk_wiz_0),
    //     .CLKIN2              (1'b0),
    //     // Tied to always select the primary input clock
    //     .CLKINSEL            (1'b1),
    //     // Ports for dynamic reconfiguration
    //     .DADDR               (7'h0),
    //     .DCLK                (1'b0),
    //     .DEN                 (1'b0),
    //     .DI                  (16'h0),
    //     .DO                  (do_unused),
    //     .DRDY                (drdy_unused),
    //     .DWE                 (1'b0),
    //     // Other control and status signals
    //     .LOCKED              (locked_int),
    //     .PWRDWN              (1'b0),
    //     .RST                 (reset_high)
    // );

    // Clock Monitor clock assigning
    //--------------------------------------
    // Output buffering
    //-----------------------------------

    BUFG clkf_buf (
        .O (clkfbout_buf_clk_gen),
        .I (clkfbout_clk_gen)
    );


    BUFG clkout1_buf (
        .O   (clk_out1),
        .I   (clk_out1_clk_gen)
    );


    BUFG clkout2_buf (
        .O   (clk_out2),
        .I   (clk_out2_clk_gen)
    );

    BUFG clkout3_buf (
        .O   (clk_out3),
        .I   (clk_out3_clk_gen)
    );

    BUFG clkout4_buf (
        .O   (clk_out4),
        .I   (clk_out4_clk_gen)
    );

endmodule