package completion_pkg;
    parameter int IMPORTED_WIDTH = 8;
    typedef logic [IMPORTED_WIDTH-1:0] imported_word_t;

    function automatic logic imported_ready();
        return 1'b1;
    endfunction
endpackage

module wildcard_completion_consumer;
    import completion_pkg::*;
    logic child;
    logic sink;

    always_comb begin
        sink = chi;
        sink = IMP;
    end
endmodule

module named_completion_consumer;
    import completion_pkg::IMPORTED_WIDTH;
    logic sink;

    always_comb begin
        sink = IMP;
    end
endmodule
