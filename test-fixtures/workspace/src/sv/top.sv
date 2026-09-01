module top;
    logic clk;
    logic result;

    child #(
        .WIDTH(8)
    ) u_child (
        .clk(clk),
        .out(result)
    );
endmodule
