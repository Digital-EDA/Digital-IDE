module accuml #(
    parameter WIDTH = 16
) (
    input clock,
    input reset,
    input clr,
    input add_sub,
    input [WIDTH-1:0] D,
    output [WIDTH-1:0] Q
);
    localparam DATA_WIDTH = WIDTH / 4;
    reg count0, count1, count2;
    reg [WIDTH:0] b_tmp0, b_tmp1, b_tmp2;
    reg [(DATA_WIDTH*1)-1:0] sum0;
    reg [(DATA_WIDTH*2)-1:0] sum1;
    reg [(DATA_WIDTH*3)-1:0] sum2;
    reg [(DATA_WIDTH*4)-1:0] sum3;
    reg add_sub0, add_sub1, add_sub2;
    reg clr0, clr1, clr2;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            sum0 <= 0;
            clr0 <= 0;
            count0 <= 0;
            b_tmp0 <= 0;
            add_sub0 <= 0;
        end else begin
            case ({clr, add_sub})
                2'b00: {count0, sum0} <= {1'b0, sum0} + {1'b0, D[(DATA_WIDTH*1)-1:0]};
                2'b01: {count0, sum0} <= {1'b0, sum0} - {1'b0, D[(DATA_WIDTH*1)-1:0]};
                2'b10: {count0, sum0} <= 0 + {1'b0, D[(DATA_WIDTH*1)-1:0]};
                default: {count0, sum0} <= 0 - {1'b0, D[(DATA_WIDTH*1)-1:0]};
            endcase
            clr0 <= clr;
            b_tmp0 <= D;
            add_sub0 <= add_sub;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            sum1 <= 0;
            clr1 <= 0;
            count1 <= 0;
            b_tmp1 <= 0;
            add_sub1 <= 0;
        end else begin
            case ({clr0, add_sub0})
                2'b00: {count1, sum1} <= {{1'b0, sum1[(DATA_WIDTH*2)-1:DATA_WIDTH]} +
                                          {1'b0, b_tmp0[(DATA_WIDTH*2)-1:DATA_WIDTH]} + count0, sum0};
                2'b01: {count1, sum1} <= {{1'b0, sum1[(DATA_WIDTH*2)-1:DATA_WIDTH]} -
                                          {1'b0, b_tmp0[(DATA_WIDTH*2)-1:DATA_WIDTH]} - count0, sum0};
                2'b10: {count1, sum1} <= 0 + {1'b0, b_tmp0[(DATA_WIDTH*2)-1:DATA_WIDTH]};
                default: {count1, sum1} <= 0 - {1'b0, b_tmp0[(DATA_WIDTH*2)-1:DATA_WIDTH]};
            endcase
            clr1 <= clr0;
            b_tmp1 <= b_tmp0;
            add_sub1 <= add_sub0;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            sum2 <= 0;
            clr2 <= 0;
            count2 <= 0;
            b_tmp2 <= 0;
            add_sub2 <= 0;
        end else begin
            case ({clr1, add_sub1})
                2'b00: {count2, sum2} <= {{1'b0, sum2[(DATA_WIDTH*3)-1:DATA_WIDTH*2]} +
                                          {1'b0, b_tmp1[(DATA_WIDTH*3)-1:DATA_WIDTH*2]} + count1, sum1};
                2'b01: {count2, sum2} <= {{1'b0, sum2[(DATA_WIDTH*3)-1:DATA_WIDTH*2]} -
                                          {1'b0, b_tmp1[(DATA_WIDTH*3)-1:DATA_WIDTH*2]} - count1, sum1};
                2'b10: {count2, sum2} <= 0 + {1'b0, b_tmp1[(DATA_WIDTH*3)-1:DATA_WIDTH*2]};
                default: {count2, sum2} <= 0 - {1'b0, b_tmp1[(DATA_WIDTH*3)-1:DATA_WIDTH*2]};
            endcase
            b_tmp2 <= b_tmp1;
            clr2 <= clr1;
            add_sub2 <= add_sub1;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            sum3 <= 0;
        end else begin
            case ({clr2, add_sub2})
                2'b00: sum3 <= {sum3[(DATA_WIDTH*4)-1:DATA_WIDTH*3] +
                                     {1'b0, b_tmp2[(DATA_WIDTH*4)-1:DATA_WIDTH*3]} + count2, sum2};
                2'b01: sum3 <= {sum3[(DATA_WIDTH*4)-1:DATA_WIDTH*3] -
                                     {1'b0, b_tmp2[(DATA_WIDTH*4)-1:DATA_WIDTH*3]} - count2, sum2};
                2'b10: sum3 <= 0 + {1'b0, b_tmp2[(DATA_WIDTH*4)-1:DATA_WIDTH*3]};
                default: sum3 <= 0 - {1'b0, b_tmp2[(DATA_WIDTH*4)-1:DATA_WIDTH*3]};
            endcase
        end
    end

    assign Q = sum3;
endmodule
