`define cow 34

module dependence_1 (
    input port_a, port_b, port_c,
    output out_q
);
    // a & b | ((b & c) & (b | c))
    // &=*, |=+               AB + BC(B+C)
    // Distribute             AB + BBC + BCC
    // Simplify AA = A        AB + BC + BC
    // Simplify A + A = A     AB + BC
    // Factor                 B(A+C)

    assign out_q = port_b & (port_a | port_c);
endmodule


module test_1 (
    input port_a, port_b,
    output Q 
);
    assign Q = port_b & port_a;
endmodule