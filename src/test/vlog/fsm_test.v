module fsm_test(
        input                clock,
        input                reset,
        input      [2 : 0]   req_0,
        input      [2 : 0]   req_1,
        output reg [2 : 0]   gnt_0,
        output reg [2 : 0]   gnt_1
    );

    reg [2:0] state;

    parameter IDLE = 3'h1;
    parameter GNT0 = 3'd2;
    parameter GNT1 = 3'b100;

    always @ (posedge clock) begin : FSM
        if (reset == 1'b1) begin
            state <= #1 IDLE;
            gnt_0 <= 0;
            gnt_1 <= 0;
        end
        else
        case(state)
            IDLE :
                if (req_0 == 1'b1) begin
                    state <= #1 GNT0;
                    gnt_0 <= 1;
                end
                else if (req_1 == 1'b1) begin
                    gnt_1 <= 1;
                    state <= #1 GNT1;
                end
                else begin
                    state <= #1 IDLE; //example comment
                end
            GNT0 :
                if (req_0 == 1'b1) begin
                    state <= #1 GNT0;
                end
                else begin
                    gnt_0 <= 0;
                    state <= #1 IDLE;
                end
            GNT1 :
                if (req_1 == 1'b1) begin
                    state <= #1 GNT1;
                end
                else begin
                    gnt_1 <= 0;
                    state <= #1 IDLE;
                end
            default :
                state <= #1 IDLE;
        endcase
    end


endmodule  //module_name
