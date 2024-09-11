
module \$__ZERO (output Y); assign Y = 1'b0; endmodule
module \$__ONE (output Y); assign Y = 1'b1; endmodule

module \$__CC_BUF (input A, output Y); assign Y = A; endmodule

module \$__CC_MUX (input A, B, C, output Y);
    CC_MX2 _TECHMAP_REPLACE_ (
        .D0(A), .D1(B), .S0(C),
        .Y(Y)
    );
endmodule


module \$__CC2_A (input A, B, output Y);
    CC_LUT2 #(
        .INIT(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B),
         .O(Y)
    );
endmodule

module \$__CC3_A_O (input A, B, E, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1010),
        .INIT_L01(4'b1000),
        .INIT_L10(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(E), .I1(), .I2(A), .I3(B),
         .O(Y)
    );
endmodule

module \$__CC3_A_X (input A, B, E, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1010),
        .INIT_L01(4'b1000),
        .INIT_L10(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(E), .I1(), .I2(A), .I3(B),
         .O(Y)
    );
endmodule

module \$__CC2_O (input A, B, output Y);
    CC_LUT2 #(
        .INIT(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B),
         .O(Y)
    );
endmodule

module \$__CC3_O_A (input A, B, E, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1010),
        .INIT_L01(4'b1110),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(E), .I1(), .I2(A), .I3(B),
         .O(Y)
    );
endmodule

module \$__CC3_O_X (input A, B, E, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1010),
        .INIT_L01(4'b1110),
        .INIT_L10(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(E), .I1(), .I2(A), .I3(B),
         .O(Y)
    );
endmodule

module \$__CC2_X (input A, B, output Y);
    CC_LUT2 #(
        .INIT(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B),
         .O(Y)
    );
endmodule

module \$__CC3_X_A (input A, B, E, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1010),
        .INIT_L01(4'b0110),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(E), .I1(), .I2(A), .I3(B),
         .O(Y)
    );
endmodule

module \$__CC3_X_O (input A, B, E, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1010),
        .INIT_L01(4'b0110),
        .INIT_L10(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(E), .I1(), .I2(A), .I3(B),
         .O(Y)
    );
endmodule

module \$__CC3_AA (input A, B, C, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b1010),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(),
         .O(Y)
    );
endmodule

module \$__CC4_AA_O (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AA_X (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC3_OO (input A, B, C, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1110),
        .INIT_L01(4'b1010),
        .INIT_L10(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(),
         .O(Y)
    );
endmodule

module \$__CC4_OO_A (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_OO_X (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC3_XX (input A, B, C, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b0110),
        .INIT_L01(4'b1010),
        .INIT_L10(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(),
         .O(Y)
    );
endmodule

module \$__CC4_XX_A (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_XX_O (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC3_AO (input A, B, C, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b1010),
        .INIT_L10(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(),
         .O(Y)
    );
endmodule

module \$__CC4_AO_A (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AO_O (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AO_X (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC3_OA (input A, B, C, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1110),
        .INIT_L01(4'b1010),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(),
         .O(Y)
    );
endmodule

module \$__CC4_OA_A (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_OA_O (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_OA_X (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC3_AX (input A, B, C, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b1010),
        .INIT_L10(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(),
         .O(Y)
    );
endmodule

module \$__CC4_AX_A (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AX_O (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AX_X (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC3_XA (input A, B, C, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b0110),
        .INIT_L01(4'b1010),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(),
         .O(Y)
    );
endmodule

module \$__CC4_XA_A (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_XA_O (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_XA_X (input A, B, C, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b1010),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AAA (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b1000),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_AAA_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AAA_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AAA_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AXA (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b1000),
        .INIT_L10(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_AXA_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AXA_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AXA_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_XAX (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b0110),
        .INIT_L01(4'b0110),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_XAX_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_XAX_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_XAX_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AAX (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b0110),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_AAX_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AAX_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AAX_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AXX (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b0110),
        .INIT_L10(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_AXX_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AXX_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AXX_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_XXX (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b0110),
        .INIT_L01(4'b0110),
        .INIT_L10(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_XXX_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_XXX_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_XXX_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b0110),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b0110),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AAO (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b1110),
        .INIT_L10(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_AAO_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AAO_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AAO_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1110),
        .INIT_L11(4'b1000),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AOA (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b1000),
        .INIT_L10(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_AOA_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AOA_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AOA_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b1000),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC4_AOX (input A, B, C, D, output Y);
    CC_L2T4 #(
        .INIT_L00(4'b1000),
        .INIT_L01(4'b0110),
        .INIT_L10(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D),
         .O(Y)
    );
endmodule

module \$__CC5_AOX_A (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b1000),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AOX_O (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b1110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule

module \$__CC5_AOX_X (input A, B, C, D, E, output Y);
    CC_L2T5 #(
        .INIT_L02(4'b1000),
        .INIT_L03(4'b0110),
        .INIT_L11(4'b1110),
        .INIT_L20(4'b0110),
    ) _TECHMAP_REPLACE_ (
         .I0(A), .I1(B), .I2(C), .I3(D), .I4(E),
         .O(Y)
    );
endmodule
