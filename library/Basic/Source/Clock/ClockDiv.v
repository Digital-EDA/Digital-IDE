`timescale 1ns / 1ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   ClockAny.v - ClockAny
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : Integer divider.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

module ClockDiv #(
        // Bit width of the division factor.
        parameter WIDTH = 8
    ) (
        // Clock input
        input                 clock,
        // Asynchronous reset with active high
        input                 reset,
        
        // division factor.
        input  [WIDTH - 1:0]  N,
        // Out clk signal
        output                div_clk
    );

    reg [WIDTH-1:0] cnt_p;      // Rising edge counting unit
    reg [WIDTH-1:0] cnt_n;      // Falling edge counting unit
    reg             clk_in_p;   // Rising edge clock
    reg             clk_in_n;   // Falling edge clock

    // When N==1, it means no division. 
    // N[0] is used to determine if the number is odd or even; 
    // if it is 1, it indicates odd division, and if it is 0, it indicates even division.
    assign div_clk = (N == 1) ? clock : (N[0])   ? (clk_in_p | clk_in_n) : (clk_in_p);
            
    always@(posedge clock or posedge reset) begin
        if (reset) begin
            cnt_p <= 0;
        end
        else if (cnt_p == (N-1)) begin
            cnt_p <= 0;
        end
        else begin
            cnt_p <= cnt_p + 1;
        end
    end

    always@(posedge clock or posedge reset) begin
        if (reset) begin
            clk_in_p <= 1;
        end
        // N is shifted right by one position with the highest bit filled with zero, 
        // which is essentially N/2, but it shows a significant advantage when calculating odd numbers.
        else if (cnt_p < (N>>1)) begin
            clk_in_p <= 1;
        end
        else begin
            clk_in_p <= 0;    
        end
    end

    always@(posedge clock or posedge reset) begin
        if (reset) begin
            cnt_n <= 0;
        end
        else if (cnt_n == (N-1)) begin
            cnt_n <= 0;
        end
        else begin
            cnt_n <= cnt_n + 1;
        end
    end

    always@(posedge clock or posedge reset) begin
        if (reset) begin
            clk_in_n <= 1;
        end
        else if (cnt_n < (N>>1)) begin
            clk_in_n <= 1;
        end
        else begin
            clk_in_n <= 0;
        end
    end

endmodule

