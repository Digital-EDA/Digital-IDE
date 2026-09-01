`timescale 1ns/100ps

module ad_lvds_out (
        // data interface
        input               tx_clk,
        input               tx_data_p,
        input               tx_data_n,
        output              tx_data_out_p,
        output              tx_data_out_n
    );

    // parameters
    parameter   BUFTYPE = 0;

    // internal signals
    wire                tx_data_oddr_s;

    // transmit data interface, oddr -> odelay -> obuf
    ODDR #(
        .DDR_CLK_EDGE ("SAME_EDGE"),
        .INIT (1'b0),
        .SRTYPE ("ASYNC"))
    i_tx_data_oddr (
        .CE (1'b1),
        .R (1'b0),
        .S (1'b0),
        .C (tx_clk),
        .D1 (tx_data_p),
        .D2 (tx_data_n),
        .Q (tx_data_oddr_s)
    );

    OBUFDS i_tx_data_obuf (
        .I (tx_data_oddr_s),
        .O (tx_data_out_p),
        .OB (tx_data_out_n)
    );

endmodule
