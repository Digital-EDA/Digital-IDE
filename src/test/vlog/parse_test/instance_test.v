`include "./Cordic.v"
module instance_test (
    input  input_a,
    input  input_b,
    output output_c
);

    assign output_c = input_a & input_b;

    
endmodule