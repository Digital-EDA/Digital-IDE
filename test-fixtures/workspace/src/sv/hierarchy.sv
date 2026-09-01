module hierarchy (
    input  logic a,
    output logic y
);
    hierarchy_level_01 child (.a(a), .y(y));
endmodule

module hierarchy_level_01 (input logic a, output logic y);
    hierarchy_level_02 child (.a(a), .y(y));
endmodule

module hierarchy_level_02 (input logic a, output logic y);
    hierarchy_level_03 child (.a(a), .y(y));
endmodule

module hierarchy_level_03 (input logic a, output logic y);
    hierarchy_level_04 child (.a(a), .y(y));
endmodule

module hierarchy_level_04 (input logic a, output logic y);
    hierarchy_level_05 child (.a(a), .y(y));
endmodule

module hierarchy_level_05 (input logic a, output logic y);
    hierarchy_level_06 child (.a(a), .y(y));
endmodule

module hierarchy_level_06 (input logic a, output logic y);
    hierarchy_level_07 child (.a(a), .y(y));
endmodule

module hierarchy_level_07 (input logic a, output logic y);
    hierarchy_level_08 child (.a(a), .y(y));
endmodule

module hierarchy_level_08 (input logic a, output logic y);
    hierarchy_level_09 child (.a(a), .y(y));
endmodule

module hierarchy_level_09 (input logic a, output logic y);
    hierarchy_level_10 child (.a(a), .y(y));
endmodule

module hierarchy_level_10 (input logic a, output logic y);
    hierarchy_level_11 child (.a(a), .y(y));
endmodule

module hierarchy_level_11 (input logic a, output logic y);
    hierarchy_level_12 child (.a(a), .y(y));
endmodule

module hierarchy_level_12 (input logic a, output logic y);
    hierarchy_level_13 child (.a(a), .y(y));
endmodule

module hierarchy_level_13 (input logic a, output logic y);
    hierarchy_level_14 child (.a(a), .y(y));
endmodule

module hierarchy_level_14 (input logic a, output logic y);
    hierarchy_level_15 child (.a(a), .y(y));
endmodule

module hierarchy_level_15 (input logic a, output logic y);
    hierarchy_level_16 child (.a(a), .y(y));
endmodule

module hierarchy_level_16 (input logic a, output logic y);
    hierarchy_level_17 child (.a(a), .y(y));
endmodule

module hierarchy_level_17 (input logic a, output logic y);
    hierarchy_level_18 child (.a(a), .y(y));
endmodule

module hierarchy_level_18 (input logic a, output logic y);
    hierarchy_level_19 child (.a(a), .y(y));
endmodule

module hierarchy_level_19 (input logic a, output logic y);
    hierarchy_level_20 child (.a(a), .y(y));
endmodule

module hierarchy_level_20 (input logic a, output logic y);
    hierarchy_level_21 child (.a(a), .y(y));
endmodule

module hierarchy_level_21 (input logic a, output logic y);
    hierarchy_level_22 child (.a(a), .y(y));
endmodule

module hierarchy_level_22 (input logic a, output logic y);
    hierarchy_level_23 child (.a(a), .y(y));
endmodule

module hierarchy_level_23 (input logic a, output logic y);
    hierarchy_level_24 child (.a(a), .y(y));
endmodule

module hierarchy_level_24 (input logic a, output logic y);
    hierarchy_level_25 child (.a(a), .y(y));
endmodule

module hierarchy_level_25 (input logic a, output logic y);
    hierarchy_level_26 child (.a(a), .y(y));
endmodule

module hierarchy_level_26 (input logic a, output logic y);
    hierarchy_level_27 child (.a(a), .y(y));
endmodule

module hierarchy_level_27 (input logic a, output logic y);
    hierarchy_level_28 child (.a(a), .y(y));
endmodule

module hierarchy_level_28 (input logic a, output logic y);
    hierarchy_level_29 child (.a(a), .y(y));
endmodule

module hierarchy_level_29 (input logic a, output logic y);
    hierarchy_level_30 child (.a(a), .y(y));
endmodule

module hierarchy_level_30 (input logic a, output logic y);
    hierarchy_level_31 child (.a(a), .y(y));
endmodule

module hierarchy_level_31 (input logic a, output logic y);
    assign y = ~a;
endmodule
