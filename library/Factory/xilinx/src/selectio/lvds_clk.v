`timescale 1ns/100ps

module lvds_clk #(
        parameter   BUFTYPE = "SERIES7"
    ) (
        input     clk_in_p,
        input     clk_in_n,
        output    clk
    );

    // wires
    wire      clk_ibuf_s;

    // instantiations
    IBUFGDS i_rx_clk_ibuf (
        .I  ( clk_in_p   ),
        .IB ( clk_in_n   ),
        .O  ( clk_ibuf_s )
    );

    generate
        if (BUFTYPE == "VIRTEX6") begin : VIRTEX6_BUF
            BUFR #(
                .BUFR_DIVIDE( "BYPASS" )) 
            i_clk_rbuf (
                .CLR    ( 1'b0       ),
                .CE     ( 1'b1       ),
                .I      ( clk_ibuf_s ),
                .O      ( clk        )
            );
        end
        else if (BUFTYPE == "SERIES7") begin : SERIES7_BUF
            BUFG i_clk_gbuf (
                .I ( clk_ibuf_s ),
                .O ( clk        )
            );
        end
    endgenerate



endmodule
