module congestion (
    input  logic [47:0] a,
    output logic [47:0] y
);
    genvar index;
    generate
        for (index = 0; index < 48; index = index + 1) begin : parallel_path
            assign y[index] = ~a[index];
        end
    endgenerate
endmodule
