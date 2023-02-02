module dependence_2 (
    input a, b, c,
    output Q 
);

  assign Q = a & b | ((b & c) & (b | c));

endmodule