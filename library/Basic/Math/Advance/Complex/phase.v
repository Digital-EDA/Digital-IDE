`timescale 1ns/1ns

/*
*   Date : 2024-07-01
*   Author : nitcloud
*   Module Name:   phase.v - phase
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Calculate the phase value of a signed complex number.
*   Dependencies: shiftTaps + divider
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '1010101010|1010101010'},
  {name: 'reset', wave: '10........|..........'},
  {name: 'ivalid', wave: '01.......0|..........', node:'.a'},
  {name: 'idata_r', wave: 'x3.3.3.3.x|..........', data: ['1','0','-1','0']},
  {name: 'idata_i', wave: 'x4.4.4.4.x|..........', data: ['0','1','0','-1']},
  {name: 'ovalid', wave: '0.........|.1.......0', node:'............b'},
  {name: 'phase', wave: 'x.........|.5.5.5.5.x', data: ['0','804','1608','-804']},
  ],
  edge: [
    'a~b DIVIDEND+5'
  ]
}
*/
module phase #(
        // Data Width
        parameter WIDTH = 32
    ) (
        // Clock input
        input clock,
        // Asynchronous reset with active high
        input reset,

        // @Flow Input valid
        // Synchronized input with the idata_r & idata_i port
        input ivalid,
        // @Flow The real of the signed input port
        input signed [WIDTH-1:0] idata_r,
        // @Flow The Imaginary of the signed input port
        input signed [WIDTH-1:0] idata_i,

        // @Flow Output valid
        // Synchronized output with the phase port
        output ovalid,
        // @Flow The signed phase output port
        // [-pi, pi] scaled up by [-1608, 1608] 
        output reg signed [15:0] phase
    );

    localparam ROTATE_WIDTH = 9;
    localparam INW  = 18 - ROTATE_WIDTH;
    localparam PI   = 32'b11001001000011111101; // 180°
    localparam OPI  = (INW >= 0) ? (PI >> INW) : (PI << -INW);            
    localparam DPI  = OPI<<1;
    localparam HPI  = OPI>>1;
    localparam QPI  = OPI>>2;
    localparam TQPI = HPI + QPI;
    
    reg  [WIDTH-1:0]  in_r;
    reg  [WIDTH-1:0]  in_i;
    reg  [WIDTH-1:0]  abs_r;
    reg  [WIDTH-1:0]  abs_i;
    reg  [WIDTH-1:0]  max;
    reg  [WIDTH-1:0]  min;
    wire [WIDTH-1:0]  quotient;
    wire [WIDTH-1:0]  dividend = (max > 4194304) ? min : {min[WIDTH-10:0], {9{1'b0}}};
    wire [WIDTH-10:0] divisor  = (max > 4194304) ? max[WIDTH-1:9] : max[WIDTH-10:0];

    wire div_in_stb;
    wire div_out_stb;


    wire [8:0] atan_addr = ((quotient > 511) ? 511 : quotient[8:0]);
    wire [8:0] atan_data;

    wire signed [9:0] mPhase = {1'b0, atan_data};

    reg  [2:0] quadrant;
    wire [2:0] rquadrant;

    // 1 cycle for abs
    // 1 cycle for quadrant
    reg [1:0] ivalid_r;
    always @(posedge clock or posedge reset) begin
        if(reset) begin
            ivalid_r <= 0;
        end
        else begin
            ivalid_r[0] <= ivalid;
            ivalid_r[1] <= ivalid_r[0];
        end
    end
    
    assign div_in_stb = ivalid_r[1];

    // 1 cycle for atan_lut
    // 1 cycle for rquadrant
    reg [1:0] ovalid_r;
    always @(posedge clock or posedge reset) begin
        if(reset) begin
            ovalid_r <= 0;
        end
        else begin
            ovalid_r[0] <= div_out_stb;
            ovalid_r[1] <= ovalid_r[0];
        end
    end
    
    assign ovalid = ovalid_r[1];

    divider #(
        .DIVIDEND(WIDTH),
        .DIVISOR(WIDTH-8)) 
    div_inst (
        .clock(clock),
        .reset(reset),

        .ivalid(div_in_stb),
        .dividend(dividend),
        .divisor({1'b0, divisor}),

        .ovalid(div_out_stb),
        .quotient(quotient)
    );

    wire mvalid;
    shiftTaps #(
        .WIDTH 		( 3   		),
        .SHIFT 		( WIDTH+2 	))
    u_shiftTaps(
        //ports
        .clock    		( clock    	  ),
        .reset    		( reset    	  ),
        .ivalid   		( 1'b1        ),
        .shiftin  		( quadrant    ),
        .ovalid         ( mvalid      ),
        .shiftout 		( rquadrant   )
    );

    reg [8:0] douta_buf;
    always @(posedge clock) begin
        if (reset) begin
            douta_buf <= 0;
        end
        else begin
            case (atan_addr)
                9'h000: douta_buf <= 9'b000000000;
                9'h001: douta_buf <= 9'b000000001;
                9'h002: douta_buf <= 9'b000000010;
                9'h003: douta_buf <= 9'b000000011;
                9'h004: douta_buf <= 9'b000000100;
                9'h005: douta_buf <= 9'b000000101;
                9'h006: douta_buf <= 9'b000000110;
                9'h007: douta_buf <= 9'b000000111;
                9'h008: douta_buf <= 9'b000001000;
                9'h009: douta_buf <= 9'b000001001;
                9'h00a: douta_buf <= 9'b000001010;
                9'h00b: douta_buf <= 9'b000001011;
                9'h00c: douta_buf <= 9'b000001100;
                9'h00d: douta_buf <= 9'b000001101;
                9'h00e: douta_buf <= 9'b000001110;
                9'h00f: douta_buf <= 9'b000001111;
                9'h010: douta_buf <= 9'b000010000;
                9'h011: douta_buf <= 9'b000010001;
                9'h012: douta_buf <= 9'b000010010;
                9'h013: douta_buf <= 9'b000010011;
                9'h014: douta_buf <= 9'b000010100;
                9'h015: douta_buf <= 9'b000010101;
                9'h016: douta_buf <= 9'b000010110;
                9'h017: douta_buf <= 9'b000010111;
                9'h018: douta_buf <= 9'b000011000;
                9'h019: douta_buf <= 9'b000011001;
                9'h01a: douta_buf <= 9'b000011010;
                9'h01b: douta_buf <= 9'b000011011;
                9'h01c: douta_buf <= 9'b000011100;
                9'h01d: douta_buf <= 9'b000011101;
                9'h01e: douta_buf <= 9'b000011110;
                9'h01f: douta_buf <= 9'b000011111;
                9'h020: douta_buf <= 9'b000100000;
                9'h021: douta_buf <= 9'b000100001;
                9'h022: douta_buf <= 9'b000100010;
                9'h023: douta_buf <= 9'b000100011;
                9'h024: douta_buf <= 9'b000100100;
                9'h025: douta_buf <= 9'b000100101;
                9'h026: douta_buf <= 9'b000100110;
                9'h027: douta_buf <= 9'b000100111;
                9'h028: douta_buf <= 9'b000101000;
                9'h029: douta_buf <= 9'b000101001;
                9'h02a: douta_buf <= 9'b000101010;
                9'h02b: douta_buf <= 9'b000101011;
                9'h02c: douta_buf <= 9'b000101100;
                9'h02d: douta_buf <= 9'b000101101;
                9'h02e: douta_buf <= 9'b000101110;
                9'h02f: douta_buf <= 9'b000101111;
                9'h030: douta_buf <= 9'b000110000;
                9'h031: douta_buf <= 9'b000110001;
                9'h032: douta_buf <= 9'b000110010;
                9'h033: douta_buf <= 9'b000110011;
                9'h034: douta_buf <= 9'b000110100;
                9'h035: douta_buf <= 9'b000110101;
                9'h036: douta_buf <= 9'b000110110;
                9'h037: douta_buf <= 9'b000110111;
                9'h038: douta_buf <= 9'b000111000;
                9'h039: douta_buf <= 9'b000111001;
                9'h03a: douta_buf <= 9'b000111010;
                9'h03b: douta_buf <= 9'b000111011;
                9'h03c: douta_buf <= 9'b000111100;
                9'h03d: douta_buf <= 9'b000111101;
                9'h03e: douta_buf <= 9'b000111110;
                9'h03f: douta_buf <= 9'b000111111;
                9'h040: douta_buf <= 9'b001000000;
                9'h041: douta_buf <= 9'b001000001;
                9'h042: douta_buf <= 9'b001000010;
                9'h043: douta_buf <= 9'b001000011;
                9'h044: douta_buf <= 9'b001000100;
                9'h045: douta_buf <= 9'b001000101;
                9'h046: douta_buf <= 9'b001000110;
                9'h047: douta_buf <= 9'b001000111;
                9'h048: douta_buf <= 9'b001001000;
                9'h049: douta_buf <= 9'b001001001;
                9'h04a: douta_buf <= 9'b001001001;
                9'h04b: douta_buf <= 9'b001001010;
                9'h04c: douta_buf <= 9'b001001011;
                9'h04d: douta_buf <= 9'b001001100;
                9'h04e: douta_buf <= 9'b001001101;
                9'h04f: douta_buf <= 9'b001001110;
                9'h050: douta_buf <= 9'b001001111;
                9'h051: douta_buf <= 9'b001010000;
                9'h052: douta_buf <= 9'b001010001;
                9'h053: douta_buf <= 9'b001010010;
                9'h054: douta_buf <= 9'b001010011;
                9'h055: douta_buf <= 9'b001010100;
                9'h056: douta_buf <= 9'b001010101;
                9'h057: douta_buf <= 9'b001010110;
                9'h058: douta_buf <= 9'b001010111;
                9'h059: douta_buf <= 9'b001011000;
                9'h05a: douta_buf <= 9'b001011001;
                9'h05b: douta_buf <= 9'b001011010;
                9'h05c: douta_buf <= 9'b001011011;
                9'h05d: douta_buf <= 9'b001011100;
                9'h05e: douta_buf <= 9'b001011101;
                9'h05f: douta_buf <= 9'b001011110;
                9'h060: douta_buf <= 9'b001011111;
                9'h061: douta_buf <= 9'b001100000;
                9'h062: douta_buf <= 9'b001100001;
                9'h063: douta_buf <= 9'b001100010;
                9'h064: douta_buf <= 9'b001100011;
                9'h065: douta_buf <= 9'b001100100;
                9'h066: douta_buf <= 9'b001100101;
                9'h067: douta_buf <= 9'b001100110;
                9'h068: douta_buf <= 9'b001100111;
                9'h069: douta_buf <= 9'b001101000;
                9'h06a: douta_buf <= 9'b001101001;
                9'h06b: douta_buf <= 9'b001101001;
                9'h06c: douta_buf <= 9'b001101010;
                9'h06d: douta_buf <= 9'b001101011;
                9'h06e: douta_buf <= 9'b001101100;
                9'h06f: douta_buf <= 9'b001101101;
                9'h070: douta_buf <= 9'b001101110;
                9'h071: douta_buf <= 9'b001101111;
                9'h072: douta_buf <= 9'b001110000;
                9'h073: douta_buf <= 9'b001110001;
                9'h074: douta_buf <= 9'b001110010;
                9'h075: douta_buf <= 9'b001110011;
                9'h076: douta_buf <= 9'b001110100;
                9'h077: douta_buf <= 9'b001110101;
                9'h078: douta_buf <= 9'b001110110;
                9'h079: douta_buf <= 9'b001110111;
                9'h07a: douta_buf <= 9'b001111000;
                9'h07b: douta_buf <= 9'b001111001;
                9'h07c: douta_buf <= 9'b001111010;
                9'h07d: douta_buf <= 9'b001111011;
                9'h07e: douta_buf <= 9'b001111100;
                9'h07f: douta_buf <= 9'b001111100;
                9'h080: douta_buf <= 9'b001111101;
                9'h081: douta_buf <= 9'b001111110;
                9'h082: douta_buf <= 9'b001111111;
                9'h083: douta_buf <= 9'b010000000;
                9'h084: douta_buf <= 9'b010000001;
                9'h085: douta_buf <= 9'b010000010;
                9'h086: douta_buf <= 9'b010000011;
                9'h087: douta_buf <= 9'b010000100;
                9'h088: douta_buf <= 9'b010000101;
                9'h089: douta_buf <= 9'b010000110;
                9'h08a: douta_buf <= 9'b010000111;
                9'h08b: douta_buf <= 9'b010001000;
                9'h08c: douta_buf <= 9'b010001001;
                9'h08d: douta_buf <= 9'b010001010;
                9'h08e: douta_buf <= 9'b010001011;
                9'h08f: douta_buf <= 9'b010001011;
                9'h090: douta_buf <= 9'b010001100;
                9'h091: douta_buf <= 9'b010001101;
                9'h092: douta_buf <= 9'b010001110;
                9'h093: douta_buf <= 9'b010001111;
                9'h094: douta_buf <= 9'b010010000;
                9'h095: douta_buf <= 9'b010010001;
                9'h096: douta_buf <= 9'b010010010;
                9'h097: douta_buf <= 9'b010010011;
                9'h098: douta_buf <= 9'b010010100;
                9'h099: douta_buf <= 9'b010010101;
                9'h09a: douta_buf <= 9'b010010110;
                9'h09b: douta_buf <= 9'b010010111;
                9'h09c: douta_buf <= 9'b010010111;
                9'h09d: douta_buf <= 9'b010011000;
                9'h09e: douta_buf <= 9'b010011001;
                9'h09f: douta_buf <= 9'b010011010;
                9'h0a0: douta_buf <= 9'b010011011;
                9'h0a1: douta_buf <= 9'b010011100;
                9'h0a2: douta_buf <= 9'b010011101;
                9'h0a3: douta_buf <= 9'b010011110;
                9'h0a4: douta_buf <= 9'b010011111;
                9'h0a5: douta_buf <= 9'b010100000;
                9'h0a6: douta_buf <= 9'b010100001;
                9'h0a7: douta_buf <= 9'b010100001;
                9'h0a8: douta_buf <= 9'b010100010;
                9'h0a9: douta_buf <= 9'b010100011;
                9'h0aa: douta_buf <= 9'b010100100;
                9'h0ab: douta_buf <= 9'b010100101;
                9'h0ac: douta_buf <= 9'b010100110;
                9'h0ad: douta_buf <= 9'b010100111;
                9'h0ae: douta_buf <= 9'b010101000;
                9'h0af: douta_buf <= 9'b010101001;
                9'h0b0: douta_buf <= 9'b010101010;
                9'h0b1: douta_buf <= 9'b010101010;
                9'h0b2: douta_buf <= 9'b010101011;
                9'h0b3: douta_buf <= 9'b010101100;
                9'h0b4: douta_buf <= 9'b010101101;
                9'h0b5: douta_buf <= 9'b010101110;
                9'h0b6: douta_buf <= 9'b010101111;
                9'h0b7: douta_buf <= 9'b010110000;
                9'h0b8: douta_buf <= 9'b010110001;
                9'h0b9: douta_buf <= 9'b010110010;
                9'h0ba: douta_buf <= 9'b010110010;
                9'h0bb: douta_buf <= 9'b010110011;
                9'h0bc: douta_buf <= 9'b010110100;
                9'h0bd: douta_buf <= 9'b010110101;
                9'h0be: douta_buf <= 9'b010110110;
                9'h0bf: douta_buf <= 9'b010110111;
                9'h0c0: douta_buf <= 9'b010111000;
                9'h0c1: douta_buf <= 9'b010111001;
                9'h0c2: douta_buf <= 9'b010111001;
                9'h0c3: douta_buf <= 9'b010111010;
                9'h0c4: douta_buf <= 9'b010111011;
                9'h0c5: douta_buf <= 9'b010111100;
                9'h0c6: douta_buf <= 9'b010111101;
                9'h0c7: douta_buf <= 9'b010111110;
                9'h0c8: douta_buf <= 9'b010111111;
                9'h0c9: douta_buf <= 9'b011000000;
                9'h0ca: douta_buf <= 9'b011000000;
                9'h0cb: douta_buf <= 9'b011000001;
                9'h0cc: douta_buf <= 9'b011000010;
                9'h0cd: douta_buf <= 9'b011000011;
                9'h0ce: douta_buf <= 9'b011000100;
                9'h0cf: douta_buf <= 9'b011000101;
                9'h0d0: douta_buf <= 9'b011000110;
                9'h0d1: douta_buf <= 9'b011000110;
                9'h0d2: douta_buf <= 9'b011000111;
                9'h0d3: douta_buf <= 9'b011001000;
                9'h0d4: douta_buf <= 9'b011001001;
                9'h0d5: douta_buf <= 9'b011001010;
                9'h0d6: douta_buf <= 9'b011001011;
                9'h0d7: douta_buf <= 9'b011001100;
                9'h0d8: douta_buf <= 9'b011001100;
                9'h0d9: douta_buf <= 9'b011001101;
                9'h0da: douta_buf <= 9'b011001110;
                9'h0db: douta_buf <= 9'b011001111;
                9'h0dc: douta_buf <= 9'b011010000;
                9'h0dd: douta_buf <= 9'b011010001;
                9'h0de: douta_buf <= 9'b011010001;
                9'h0df: douta_buf <= 9'b011010010;
                9'h0e0: douta_buf <= 9'b011010011;
                9'h0e1: douta_buf <= 9'b011010100;
                9'h0e2: douta_buf <= 9'b011010101;
                9'h0e3: douta_buf <= 9'b011010110;
                9'h0e4: douta_buf <= 9'b011010111;
                9'h0e5: douta_buf <= 9'b011010111;
                9'h0e6: douta_buf <= 9'b011011000;
                9'h0e7: douta_buf <= 9'b011011001;
                9'h0e8: douta_buf <= 9'b011011010;
                9'h0e9: douta_buf <= 9'b011011011;
                9'h0ea: douta_buf <= 9'b011011011;
                9'h0eb: douta_buf <= 9'b011011100;
                9'h0ec: douta_buf <= 9'b011011101;
                9'h0ed: douta_buf <= 9'b011011110;
                9'h0ee: douta_buf <= 9'b011011111;
                9'h0ef: douta_buf <= 9'b011100000;
                9'h0f0: douta_buf <= 9'b011100000;
                9'h0f1: douta_buf <= 9'b011100001;
                9'h0f2: douta_buf <= 9'b011100010;
                9'h0f3: douta_buf <= 9'b011100011;
                9'h0f4: douta_buf <= 9'b011100100;
                9'h0f5: douta_buf <= 9'b011100101;
                9'h0f6: douta_buf <= 9'b011100101;
                9'h0f7: douta_buf <= 9'b011100110;
                9'h0f8: douta_buf <= 9'b011100111;
                9'h0f9: douta_buf <= 9'b011101000;
                9'h0fa: douta_buf <= 9'b011101001;
                9'h0fb: douta_buf <= 9'b011101001;
                9'h0fc: douta_buf <= 9'b011101010;
                9'h0fd: douta_buf <= 9'b011101011;
                9'h0fe: douta_buf <= 9'b011101100;
                9'h0ff: douta_buf <= 9'b011101101;
                9'h100: douta_buf <= 9'b011101101;
                9'h101: douta_buf <= 9'b011101110;
                9'h102: douta_buf <= 9'b011101111;
                9'h103: douta_buf <= 9'b011110000;
                9'h104: douta_buf <= 9'b011110001;
                9'h105: douta_buf <= 9'b011110001;
                9'h106: douta_buf <= 9'b011110010;
                9'h107: douta_buf <= 9'b011110011;
                9'h108: douta_buf <= 9'b011110100;
                9'h109: douta_buf <= 9'b011110101;
                9'h10a: douta_buf <= 9'b011110101;
                9'h10b: douta_buf <= 9'b011110110;
                9'h10c: douta_buf <= 9'b011110111;
                9'h10d: douta_buf <= 9'b011111000;
                9'h10e: douta_buf <= 9'b011111000;
                9'h10f: douta_buf <= 9'b011111001;
                9'h110: douta_buf <= 9'b011111010;
                9'h111: douta_buf <= 9'b011111011;
                9'h112: douta_buf <= 9'b011111100;
                9'h113: douta_buf <= 9'b011111100;
                9'h114: douta_buf <= 9'b011111101;
                9'h115: douta_buf <= 9'b011111110;
                9'h116: douta_buf <= 9'b011111111;
                9'h117: douta_buf <= 9'b011111111;
                9'h118: douta_buf <= 9'b100000000;
                9'h119: douta_buf <= 9'b100000001;
                9'h11a: douta_buf <= 9'b100000010;
                9'h11b: douta_buf <= 9'b100000011;
                9'h11c: douta_buf <= 9'b100000011;
                9'h11d: douta_buf <= 9'b100000100;
                9'h11e: douta_buf <= 9'b100000101;
                9'h11f: douta_buf <= 9'b100000110;
                9'h120: douta_buf <= 9'b100000110;
                9'h121: douta_buf <= 9'b100000111;
                9'h122: douta_buf <= 9'b100001000;
                9'h123: douta_buf <= 9'b100001001;
                9'h124: douta_buf <= 9'b100001001;
                9'h125: douta_buf <= 9'b100001010;
                9'h126: douta_buf <= 9'b100001011;
                9'h127: douta_buf <= 9'b100001100;
                9'h128: douta_buf <= 9'b100001100;
                9'h129: douta_buf <= 9'b100001101;
                9'h12a: douta_buf <= 9'b100001110;
                9'h12b: douta_buf <= 9'b100001111;
                9'h12c: douta_buf <= 9'b100001111;
                9'h12d: douta_buf <= 9'b100010000;
                9'h12e: douta_buf <= 9'b100010001;
                9'h12f: douta_buf <= 9'b100010010;
                9'h130: douta_buf <= 9'b100010010;
                9'h131: douta_buf <= 9'b100010011;
                9'h132: douta_buf <= 9'b100010100;
                9'h133: douta_buf <= 9'b100010101;
                9'h134: douta_buf <= 9'b100010101;
                9'h135: douta_buf <= 9'b100010110;
                9'h136: douta_buf <= 9'b100010111;
                9'h137: douta_buf <= 9'b100010111;
                9'h138: douta_buf <= 9'b100011000;
                9'h139: douta_buf <= 9'b100011001;
                9'h13a: douta_buf <= 9'b100011010;
                9'h13b: douta_buf <= 9'b100011010;
                9'h13c: douta_buf <= 9'b100011011;
                9'h13d: douta_buf <= 9'b100011100;
                9'h13e: douta_buf <= 9'b100011101;
                9'h13f: douta_buf <= 9'b100011101;
                9'h140: douta_buf <= 9'b100011110;
                9'h141: douta_buf <= 9'b100011111;
                9'h142: douta_buf <= 9'b100011111;
                9'h143: douta_buf <= 9'b100100000;
                9'h144: douta_buf <= 9'b100100001;
                9'h145: douta_buf <= 9'b100100010;
                9'h146: douta_buf <= 9'b100100010;
                9'h147: douta_buf <= 9'b100100011;
                9'h148: douta_buf <= 9'b100100100;
                9'h149: douta_buf <= 9'b100100100;
                9'h14a: douta_buf <= 9'b100100101;
                9'h14b: douta_buf <= 9'b100100110;
                9'h14c: douta_buf <= 9'b100100111;
                9'h14d: douta_buf <= 9'b100100111;
                9'h14e: douta_buf <= 9'b100101000;
                9'h14f: douta_buf <= 9'b100101001;
                9'h150: douta_buf <= 9'b100101001;
                9'h151: douta_buf <= 9'b100101010;
                9'h152: douta_buf <= 9'b100101011;
                9'h153: douta_buf <= 9'b100101011;
                9'h154: douta_buf <= 9'b100101100;
                9'h155: douta_buf <= 9'b100101101;
                9'h156: douta_buf <= 9'b100101110;
                9'h157: douta_buf <= 9'b100101110;
                9'h158: douta_buf <= 9'b100101111;
                9'h159: douta_buf <= 9'b100110000;
                9'h15a: douta_buf <= 9'b100110000;
                9'h15b: douta_buf <= 9'b100110001;
                9'h15c: douta_buf <= 9'b100110010;
                9'h15d: douta_buf <= 9'b100110010;
                9'h15e: douta_buf <= 9'b100110011;
                9'h15f: douta_buf <= 9'b100110100;
                9'h160: douta_buf <= 9'b100110100;
                9'h161: douta_buf <= 9'b100110101;
                9'h162: douta_buf <= 9'b100110110;
                9'h163: douta_buf <= 9'b100110110;
                9'h164: douta_buf <= 9'b100110111;
                9'h165: douta_buf <= 9'b100111000;
                9'h166: douta_buf <= 9'b100111000;
                9'h167: douta_buf <= 9'b100111001;
                9'h168: douta_buf <= 9'b100111010;
                9'h169: douta_buf <= 9'b100111010;
                9'h16a: douta_buf <= 9'b100111011;
                9'h16b: douta_buf <= 9'b100111100;
                9'h16c: douta_buf <= 9'b100111100;
                9'h16d: douta_buf <= 9'b100111101;
                9'h16e: douta_buf <= 9'b100111110;
                9'h16f: douta_buf <= 9'b100111110;
                9'h170: douta_buf <= 9'b100111111;
                9'h171: douta_buf <= 9'b101000000;
                9'h172: douta_buf <= 9'b101000000;
                9'h173: douta_buf <= 9'b101000001;
                9'h174: douta_buf <= 9'b101000010;
                9'h175: douta_buf <= 9'b101000010;
                9'h176: douta_buf <= 9'b101000011;
                9'h177: douta_buf <= 9'b101000100;
                9'h178: douta_buf <= 9'b101000100;
                9'h179: douta_buf <= 9'b101000101;
                9'h17a: douta_buf <= 9'b101000110;
                9'h17b: douta_buf <= 9'b101000110;
                9'h17c: douta_buf <= 9'b101000111;
                9'h17d: douta_buf <= 9'b101001000;
                9'h17e: douta_buf <= 9'b101001000;
                9'h17f: douta_buf <= 9'b101001001;
                9'h180: douta_buf <= 9'b101001001;
                9'h181: douta_buf <= 9'b101001010;
                9'h182: douta_buf <= 9'b101001011;
                9'h183: douta_buf <= 9'b101001011;
                9'h184: douta_buf <= 9'b101001100;
                9'h185: douta_buf <= 9'b101001101;
                9'h186: douta_buf <= 9'b101001101;
                9'h187: douta_buf <= 9'b101001110;
                9'h188: douta_buf <= 9'b101001111;
                9'h189: douta_buf <= 9'b101001111;
                9'h18a: douta_buf <= 9'b101010000;
                9'h18b: douta_buf <= 9'b101010000;
                9'h18c: douta_buf <= 9'b101010001;
                9'h18d: douta_buf <= 9'b101010010;
                9'h18e: douta_buf <= 9'b101010010;
                9'h18f: douta_buf <= 9'b101010011;
                9'h190: douta_buf <= 9'b101010100;
                9'h191: douta_buf <= 9'b101010100;
                9'h192: douta_buf <= 9'b101010101;
                9'h193: douta_buf <= 9'b101010101;
                9'h194: douta_buf <= 9'b101010110;
                9'h195: douta_buf <= 9'b101010111;
                9'h196: douta_buf <= 9'b101010111;
                9'h197: douta_buf <= 9'b101011000;
                9'h198: douta_buf <= 9'b101011000;
                9'h199: douta_buf <= 9'b101011001;
                9'h19a: douta_buf <= 9'b101011010;
                9'h19b: douta_buf <= 9'b101011010;
                9'h19c: douta_buf <= 9'b101011011;
                9'h19d: douta_buf <= 9'b101011100;
                9'h19e: douta_buf <= 9'b101011100;
                9'h19f: douta_buf <= 9'b101011101;
                9'h1a0: douta_buf <= 9'b101011101;
                9'h1a1: douta_buf <= 9'b101011110;
                9'h1a2: douta_buf <= 9'b101011111;
                9'h1a3: douta_buf <= 9'b101011111;
                9'h1a4: douta_buf <= 9'b101100000;
                9'h1a5: douta_buf <= 9'b101100000;
                9'h1a6: douta_buf <= 9'b101100001;
                9'h1a7: douta_buf <= 9'b101100010;
                9'h1a8: douta_buf <= 9'b101100010;
                9'h1a9: douta_buf <= 9'b101100011;
                9'h1aa: douta_buf <= 9'b101100011;
                9'h1ab: douta_buf <= 9'b101100100;
                9'h1ac: douta_buf <= 9'b101100100;
                9'h1ad: douta_buf <= 9'b101100101;
                9'h1ae: douta_buf <= 9'b101100110;
                9'h1af: douta_buf <= 9'b101100110;
                9'h1b0: douta_buf <= 9'b101100111;
                9'h1b1: douta_buf <= 9'b101100111;
                9'h1b2: douta_buf <= 9'b101101000;
                9'h1b3: douta_buf <= 9'b101101001;
                9'h1b4: douta_buf <= 9'b101101001;
                9'h1b5: douta_buf <= 9'b101101010;
                9'h1b6: douta_buf <= 9'b101101010;
                9'h1b7: douta_buf <= 9'b101101011;
                9'h1b8: douta_buf <= 9'b101101011;
                9'h1b9: douta_buf <= 9'b101101100;
                9'h1ba: douta_buf <= 9'b101101101;
                9'h1bb: douta_buf <= 9'b101101101;
                9'h1bc: douta_buf <= 9'b101101110;
                9'h1bd: douta_buf <= 9'b101101110;
                9'h1be: douta_buf <= 9'b101101111;
                9'h1bf: douta_buf <= 9'b101101111;
                9'h1c0: douta_buf <= 9'b101110000;
                9'h1c1: douta_buf <= 9'b101110001;
                9'h1c2: douta_buf <= 9'b101110001;
                9'h1c3: douta_buf <= 9'b101110010;
                9'h1c4: douta_buf <= 9'b101110010;
                9'h1c5: douta_buf <= 9'b101110011;
                9'h1c6: douta_buf <= 9'b101110011;
                9'h1c7: douta_buf <= 9'b101110100;
                9'h1c8: douta_buf <= 9'b101110101;
                9'h1c9: douta_buf <= 9'b101110101;
                9'h1ca: douta_buf <= 9'b101110110;
                9'h1cb: douta_buf <= 9'b101110110;
                9'h1cc: douta_buf <= 9'b101110111;
                9'h1cd: douta_buf <= 9'b101110111;
                9'h1ce: douta_buf <= 9'b101111000;
                9'h1cf: douta_buf <= 9'b101111000;
                9'h1d0: douta_buf <= 9'b101111001;
                9'h1d1: douta_buf <= 9'b101111010;
                9'h1d2: douta_buf <= 9'b101111010;
                9'h1d3: douta_buf <= 9'b101111011;
                9'h1d4: douta_buf <= 9'b101111011;
                9'h1d5: douta_buf <= 9'b101111100;
                9'h1d6: douta_buf <= 9'b101111100;
                9'h1d7: douta_buf <= 9'b101111101;
                9'h1d8: douta_buf <= 9'b101111101;
                9'h1d9: douta_buf <= 9'b101111110;
                9'h1da: douta_buf <= 9'b101111110;
                9'h1db: douta_buf <= 9'b101111111;
                9'h1dc: douta_buf <= 9'b101111111;
                9'h1dd: douta_buf <= 9'b110000000;
                9'h1de: douta_buf <= 9'b110000001;
                9'h1df: douta_buf <= 9'b110000001;
                9'h1e0: douta_buf <= 9'b110000010;
                9'h1e1: douta_buf <= 9'b110000010;
                9'h1e2: douta_buf <= 9'b110000011;
                9'h1e3: douta_buf <= 9'b110000011;
                9'h1e4: douta_buf <= 9'b110000100;
                9'h1e5: douta_buf <= 9'b110000100;
                9'h1e6: douta_buf <= 9'b110000101;
                9'h1e7: douta_buf <= 9'b110000101;
                9'h1e8: douta_buf <= 9'b110000110;
                9'h1e9: douta_buf <= 9'b110000110;
                9'h1ea: douta_buf <= 9'b110000111;
                9'h1eb: douta_buf <= 9'b110000111;
                9'h1ec: douta_buf <= 9'b110001000;
                9'h1ed: douta_buf <= 9'b110001000;
                9'h1ee: douta_buf <= 9'b110001001;
                9'h1ef: douta_buf <= 9'b110001001;
                9'h1f0: douta_buf <= 9'b110001010;
                9'h1f1: douta_buf <= 9'b110001011;
                9'h1f2: douta_buf <= 9'b110001011;
                9'h1f3: douta_buf <= 9'b110001100;
                9'h1f4: douta_buf <= 9'b110001100;
                9'h1f5: douta_buf <= 9'b110001101;
                9'h1f6: douta_buf <= 9'b110001101;
                9'h1f7: douta_buf <= 9'b110001110;
                9'h1f8: douta_buf <= 9'b110001110;
                9'h1f9: douta_buf <= 9'b110001111;
                9'h1fa: douta_buf <= 9'b110001111;
                9'h1fb: douta_buf <= 9'b110010000;
                9'h1fc: douta_buf <= 9'b110010000;
                9'h1fd: douta_buf <= 9'b110010001;
                9'h1fe: douta_buf <= 9'b110010001;
                9'h1ff: douta_buf <= 9'b110010010;
            endcase
        end
    end

    assign atan_data = douta_buf;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            max <= 0;
            min <= 0;
            in_r <= 0;
            in_i <= 0;
            abs_r <= 0;
            abs_i <= 0;
            quadrant <= 0;
        end
        else begin            
            if (ivalid) begin
                // 1st cycle
                abs_r <= idata_r[WIDTH-1] ? (~idata_r+1) : idata_r;
                abs_i <= idata_i[WIDTH-1] ? (~idata_i+1) : idata_i;
                in_r <= idata_r;
                in_i <= idata_i;
            end
            // 2nd cycle
            if (abs_r >= abs_i) begin
                quadrant <= {in_r[WIDTH-1], in_i[WIDTH-1], 1'b0};
                max <= abs_r;
                min <= abs_i;
            end
            else begin
                quadrant <= {in_r[WIDTH-1], in_i[WIDTH-1], 1'b1};
                max <= abs_i;
                min <= abs_r;
            end

            case(rquadrant)
                3'b000: begin phase <=  mPhase; end
                3'b010: begin phase <= -mPhase; end
                3'b001: begin phase <=  HPI - mPhase; end
                3'b011: begin phase <=  mPhase - HPI; end
                3'b100: begin phase <=  OPI - mPhase; end
                3'b101: begin phase <=  HPI + mPhase; end
                3'b110: begin phase <=  mPhase - OPI; end
                3'b111: begin phase <= -HPI - mPhase; end
            endcase
        end
    end

endmodule
