/**
 * Periphary cell library
 */

`default_nettype wire

`celldefine
module EFX_IBUF(I, O);
    parameter PULL_OPTION = "NONE";
    input I /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;
    output O /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
endmodule
`endcelldefine

`celldefine
module EFX_OBUF(I, O);
    input I /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    output O /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;
endmodule
`endcelldefine

`celldefine
module EFX_IO_BUF(I, O, OE, IO);
    parameter PULL_OPTION = "NONE";
    input I /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    input OE /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    output O /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
    inout IO /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;
endmodule
`endcelldefine

`celldefine
module EFX_CLKOUT(CLK, CLKOUT);
    parameter IS_CLK_INVERTED = 0;
    input CLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    output CLKOUT /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;
endmodule
`endcelldefine

`celldefine
module EFX_IREG(I, CLK, O);
    parameter PULL_OPTION = "NONE";
    parameter IS_CLK_INVERTED = 0;
    input I /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;
    input CLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    output O /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
endmodule
`endcelldefine

`celldefine
module EFX_OREG(I, CLK, O);
    parameter IS_CLK_INVERTED = 0;
    input I /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    input CLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    output O /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;
endmodule
`endcelldefine

`celldefine
module EFX_IOREG(I, INCLK, OE, OUTCLK, O, IO);
    parameter IS_INCLK_INVERTED = 0;
    parameter IS_OUTCLK_INVERTED = 0;
    parameter PULL_OPTION = "NONE";
    input I /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    input INCLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    input OE /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    output O /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
    input OUTCLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    inout IO /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;

endmodule
`endcelldefine

`celldefine
module EFX_IDDIO(CLK, I, O_HI, O_LO);
    parameter IS_CLK_INVERTED = 0;
    parameter MODE = "DDIO";
    parameter PULL_OPTION = "NONE";
    input CLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    input I /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;
    output O_HI /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
    output O_LO /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
endmodule
`endcelldefine

`celldefine
module EFX_ODDIO(CLK, I_HI, I_LO, O);
    parameter IS_CLK_INVERTED = 0;
    parameter MODE = "DDIO";
    input CLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    input I_HI /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    input I_LO /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    output O /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;

endmodule
`endcelldefine

`celldefine
module EFX_GPIO_V1(I, O, OE, OUTCLK, INCLK, IO);
    parameter MODE = "INPUT";
    parameter OUT_REG = "BYPASS";
    parameter IN_REG = "BYPASS";
    parameter OE_REG = "BYPASS";
    parameter PULL_OPTION = "NONE";
    parameter IS_OUTCLK_INVERTED = 0;
    parameter IS_INCLK_INVERTED = 0;

    output I /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
    input  O /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    input OE /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=OUTPUT */;
    input OUTCLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    input INCLK /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
    inout  IO /* verific EFX_ATTRIBUTE_PORT__IO_EXTERNAL_PIN=TRUE */;
endmodule
`endcelldefine

`celldefine
module EFX_PLL_V1(CLKOUT0, CLKOUT1, CLKOUT2, LOCKED, RSTN, CLKIN);
    parameter integer N = 1;
    parameter integer M = 1;
    parameter integer O = 1;
    parameter integer CLKOUT0_DIV = 2;
    parameter integer CLKOUT1_DIV = 2;
    parameter integer CLKOUT2_DIV = 2;

    output CLKOUT0 /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
    output CLKOUT1 /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
    output CLKOUT2 /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
    output LOCKED /* verific EFX_ATTRIBUTE_PORT__CORE_USER_DIRECTION=INPUT */;
    input   RSTN;
    input CLKIN /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
endmodule
`endcelldefine

`celldefine
module EFX_OSC_V1(CLKOUT);
   output CLKOUT /* verific EFX_ATTRIBUTE_PORT__IS_CLKOUT_PIN=TRUE */;
endmodule
`endcelldefine

