`timescale 1ns/100ps
module spi_reg_cfg (
        input            clk,
        input            rst_n,

        //spi
        output           spi_enb,
        output           spi_clk,
        output           spi_di,
        input            spi_do,

        output           init_done
    );

    //AD9361 initial configuration
    wire              spi_wr_end;
    wire              spi_wr_req;
    wire [9:0]        spi_wr_addr;
    wire [7:0]        spi_wr_data;

    ad9361_init u_init_cfg (
        //input
        .clk           ( clk         ),
        .rst_n         ( rst_n       ),

        //output
        .spi_wr_end    ( spi_wr_end  ),
        .spi_wr_req    ( spi_wr_req  ),
        .spi_wr_addr   ( spi_wr_addr ),
        .spi_wr_data   ( spi_wr_data ),
        .init_done     ( init_done   )
    );

    spi u_spi (
        .clk           ( clk         ),
        .rst_n         ( rst_n       ),

        .wr_end        ( spi_wr_end  ),
        .wr_req        ( spi_wr_req  ),
        .wr_addr       ( spi_wr_addr ),
        .wr_data       ( spi_wr_data ),

        // .rd_end        ( spi_rd_end  ),
        // .rd_req        ( spi_rd_req  ),
        // .rd_addr       ( spi_rd_addr ),
        // .rd_data       ( spi_rd_data ),
 
        .spi_enb       ( spi_enb     ),
        .spi_clk       ( spi_clk     ),
        .spi_do        ( spi_do      ),
        .spi_di        ( spi_di      )
    );

endmodule
