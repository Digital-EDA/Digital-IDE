
/* 
 * CN: 如果使用`include "head_1.v" 则模块 dependence_1 使用的应该是 head_1.v 文件中的，
 *     而不会调用child_1.v中的 dependence_1 同名模块。
 * EN: 
 */

`include "child_1.v"
`define main_o out
module Main(
    input a, b, c,
    output Qus, Qs, `main_o
); 

dependence_1 dependence_1(
    .a(a),
    .b(b),
    .c(c),
    .Q(Qus)
);

dependence_2 dependence_2(
    .a(a),
    .b(b),
    .c(c),
    .Q(Qs)
);

endmodule