/* 
 * EN: A simple demo to test search order of dependence
 *     current file -> macro include -> whole project
 *     expect dependence_1 from child_1.v (macro include)
 *     expect dependence_2 from child_2.v (whole project)
 *     cannot find dependence_3
 */

`include "child_1.v"
`define main out

module Main (
    input a, b, c,
    output Qus, Qs, `main
);

dependence_1 u_dependence_1(
    .a(a),
    .b(b),
    .c(c),
    .Q(Qus)
);

dependence_2 u_dependence_2(
    .a(a),
    .b(b),
    .c(c),
    .Q(Qs)
);

dependence_3 u_dependence_3(
    .a(a),
    .b(b),
    .c(c),
    .Q(Qs)
);

endmodule

/* @wavedrom this is wavedrom demo1
{
    signal : [
        { name: "clk",  wave: "p......" },
        { name: "bus",  wave: "x.34.5x", data: "head body tail" },
        { name: "wire", wave: "0.1..0." }
    ]
}
*/


/* @wavedrom this is wavedrom demo2
{ 
    signal: [
    { name: "pclk", wave: 'p.......' },
    { name: "Pclk", wave: 'P.......' },
    { name: "nclk", wave: 'n.......' },
    { name: "Nclk", wave: 'N.......' },
    {},
    { name: 'clk0', wave: 'phnlPHNL' },
    { name: 'clk1', wave: 'xhlhLHl.' },
    { name: 'clk2', wave: 'hpHplnLn' },
    { name: 'clk3', wave: 'nhNhplPl' },
    { name: 'clk4', wave: 'xlh.L.Hx' },
]}
*/