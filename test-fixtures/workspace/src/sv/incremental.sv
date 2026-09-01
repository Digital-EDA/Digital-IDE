module incremental (
    input  logic a0,
    input  logic a1,
    output logic y0,
    output logic y1,
    output logic constant_guard
);
    assign y0 = a0;
    assign y1 = 1'b0;
    assign constant_guard = 1'b0;
endmodule
