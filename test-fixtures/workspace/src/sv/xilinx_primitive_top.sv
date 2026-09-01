module xilinx_primitive_top;
    logic clock_in;
    logic clock_buffered;

    IBUF u_ibuf (
        .I(clock_in),
        .O(clock_buffered)
    );

    missing_block u_missing ();
endmodule
