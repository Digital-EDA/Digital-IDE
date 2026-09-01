`timescale 1ns/100ps

module ad_lvds_in (
        // data interface
        input               rx_clk,
        input               rx_data_in_p,
        input               rx_data_in_n,
        output              rx_data_p,
        output  reg         rx_data_n
    );

    // parameters
    parameter   BUFTYPE = 0;

    // internal signals
    wire                rx_data_n_s;
    wire                rx_data_ibuf_s;
    wire                rx_data_idelay_s;

    // receive data interface, ibuf -> idelay -> iddr
    IBUFDS i_rx_data_ibuf (
        .I  (rx_data_in_p),
        .IB (rx_data_in_n),
        .O  (rx_data_ibuf_s)
    );

    IDDR #(
        .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"),
        .INIT_Q1 (1'b0),
        .INIT_Q2 (1'b0),
        .SRTYPE ("ASYNC"))
    i_rx_data_iddr (
        .CE (1'b1),
        .R (1'b0),
        .S (1'b0),
        .C (rx_clk),
        .D (rx_data_ibuf_s),
        .Q1 (rx_data_p),
        .Q2 (rx_data_n_s)
    );

    always @(posedge rx_clk) begin
        rx_data_n <= rx_data_n_s;
    end

endmodule
