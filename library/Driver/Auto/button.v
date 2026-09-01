`timescale 1 ns / 100 ps
module button #(
        parameter N = 32,           // debounce timer bitwidth
        parameter FREQ = 60,        //model clock :Mhz
        parameter MAX_TIME = 20     //ms
    ) (
        input       clock, 
        input       reset, 
        input       button_in,
        output reg  button_pos,
        output reg  button_neg,
        output reg  button_out
    );
    //// ---------------- internal constants --------------
    localparam TIMER_MAX_VAL =   MAX_TIME * 1000 * FREQ;
    ////---------------- internal variables ---------------
    reg  button_out_d0;
    reg  [N-1 : 0]  q_reg;      // timing regs
    reg  [N-1 : 0]  q_next;
    reg  DFF1, DFF2;             // input flip-flops
    wire q_add;                 // control flags
    wire q_reset;
    //// ------------------------------------------------------

    ////contenious assignment for counter control
    assign q_reset = (DFF1 ^ DFF2);          // xor input flip flops to look for level chage to reset counter
    assign q_add = ~(q_reg == TIMER_MAX_VAL); // add to counter when q_reg msb is equal to 0

    //// combo counter to manage q_next 
    always @ (q_reset, q_add, q_reg) begin
        case({q_reset , q_add})
            2'b00   : q_next <= q_reg;
            2'b01   : q_next <= q_reg + 1;
            default : q_next <= { N {1'b0} };
        endcase     
    end

    //// Flip flop inputs and q_reg update
    always @ (posedge clock or posedge reset) begin
        if(reset) begin
            DFF1 <= 1'b0;
            DFF2 <= 1'b0;
            q_reg <= { N {1'b0} };
        end
        else begin
            DFF1 <= button_in;
            DFF2 <= DFF1;
            q_reg <= q_next;
        end
    end

    //// counter control
    always @ (posedge clock or posedge reset) begin
        if(reset) begin
            button_out <= 1'b1;
        end
        else if(q_reg == TIMER_MAX_VAL) begin
            button_out <= DFF2;
        end
        else begin
            button_out <= button_out;
        end
    end

    always @ ( posedge clock or posedge reset) begin
        if(reset) begin
            button_out_d0 <= 1'b1;
            button_pos <= 1'b0;
            button_neg <= 1'b0;
        end
        else begin
            button_out_d0 <= button_out;
            button_pos <= ~button_out_d0 & button_out;
            button_neg <= button_out_d0 & ~button_out;
        end	
    end

endmodule


