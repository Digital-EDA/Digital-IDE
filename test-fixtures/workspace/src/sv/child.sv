module child #(
    parameter int WIDTH = 8
) (
    input  logic clk,
    output logic out
);
    logic target;
    logic [WIDTH-1:0] value;

    always_ff @(posedge clk) begin : worker
        target <= !target;
        value <= value + 1'b1;
        $display("target=%0b", target);
    end

    assign out = target;

    leaf u_leaf();
endmodule
