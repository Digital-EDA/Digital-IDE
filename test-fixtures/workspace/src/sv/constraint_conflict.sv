module conflict_source (
    input  logic a0,
    input  logic a1,
    output logic o0,
    output logic o1
);
    assign o0 = ~a0;
    assign o1 = ~a1;
endmodule

module conflict_target (
    input  logic i0,
    input  logic i1,
    output logic y0,
    output logic y1
);
    assign y0 = i0;
    assign y1 = i1;
endmodule

module constraint_conflict (
    input  logic a0,
    input  logic a1,
    output logic y0,
    output logic y1
);
    logic upper;
    logic lower;

    conflict_source source (
        .a0(a0), .a1(a1), .o0(upper), .o1(lower)
    );
    conflict_target target (
        .i0(lower), .i1(upper), .y0(y0), .y1(y1)
    );
endmodule
