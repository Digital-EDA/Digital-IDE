module dependence_1 (
    input a, b, c,
    output Q 
);

    // a & b | ((b & c) & (b | c))
    // &=*, |=+               AB + BC(B+C)
    // Distribute             AB + BBC + BCC
    // Simplify AA = A        AB + BC + BC
    // Simplify A + A = A     AB + BC
    // Factor                 B(A+C)

    assign Q = a & (b | c);

endmodule

`include "adwada"

`define main dwwds
`define ada wss

/*

*/

`main

module dependence_2 (
    input a, b, c,
    output Q 
);

  assign Q = a & b | ((b & c) & (b | c));

endmodule