module clkdiv(
    input clk50,
    input rst_n,
    output reg clkout
);
    reg [15:0] cnt;
    always @(posedge clk50 or negedge rst_n)
    begin
        if(!rst_n)
        begin
            cnt <= 16'b0;
            clkout <= 1'b0;
        end
        else if(cnt == 16'd162) 
        begin
            clkout <= 1'b1;
            cnt <= cnt + 16'd1;
        end
            else if(cnt == 16'd325) 
        begin
            clkout <= 1'b0;
            cnt <= 16'd0;
        end
            else 
        begin
            cnt <= cnt + 16'd1;
        end
    end
endmodule