`timescale 1ns/1ns

/*
*   Date : 2024-06-27
*   Author : nitcloud
*   Module Name:   Sort3.v - Sort3
*   Target Device: [Target FPGA and ASIC Device]
*   Tool versions: vivado 18.3 & DC 2016
*   Revision Historyc :
*   Revision :
*       Revision 0.01 - File Created
*   Description : 3-input unsigned data parallel sorting module.
*   Dependencies: none
*   Company : ncai Technology .Inc
*   Copyright(c) 1999, ncai Technology Inc, All right reserved
*/

/* @wavedrom
{signal: [
  {name: 'clock', wave: '10101010101010101'},
  {name: 'reset', wave: '10...............'},
  {name: 'data1', wave: 'x3.3.3.3.x.', data: ['10','20','35','50']},
  {name: 'data2', wave: 'x3.3.3.3.x.', data: ['5','25','30','50']},
  {name: 'data3', wave: 'x3.3.3.3.x.', data: ['15','30','25','50']},
  {name: 'max', wave: 'x4.4.4.4.x.', data: ['15','30','35','50']},
  {name: 'mid', wave: 'x4.4.4.4.x.', data: ['10','25','30','50']},
  {name: 'min', wave: 'x4.4.4.4.x.', data: ['5','20','25','50']},
]}
*/
module	Sort3 #(
        // Data width.
        parameter WIDTH = 16
    ) (
        // Clock input
        input				clock,
        // Asynchronous reset with active high
        input				reset,
        
        // The unsigned data1 input port
        input		[WIDTH-1:0]	data1, 
        // The unsigned data1 input port
        input		[WIDTH-1:0]	data2, 
        // The unsigned data1 input port
        input		[WIDTH-1:0]	data3,
        
        // The unsigned max output port
        output	reg	[WIDTH-1:0]	max_data, 
        // The unsigned mid output port
        output	reg	[WIDTH-1:0]	mid_data, 
        // The unsigned min output port
        output	reg	[WIDTH-1:0]	min_data
    );

    //-----------------------------------
    //Sort of 3 datas	
    always@(posedge clock or negedge reset) begin
        if(reset) begin
            max_data <= 0;
            mid_data <= 0;
            min_data <= 0;
        end
        else begin
            //get the max value
            if(data1 >= data2 && data1 >= data3) begin
                max_data <= data1;
            end
            else if(data2 >= data1 && data2 >= data3) begin
                max_data <= data2;
            end
            else begin
                max_data <= data3;
            end

            //get the mid value
            if((data1 >= data2 && data1 <= data3) || (data1 >= data3 && data1 <= data2)) begin
                mid_data <= data1;
            end
            else if((data2 >= data1 && data2 <= data3) || (data2 >= data3 && data2 <= data1)) begin
                mid_data <= data2;
            end
            else begin
                mid_data <= data3;
            end
                
            //ge the min value
            if(data1 <= data2 && data1 <= data3) begin
                min_data <= data1;
            end
            else if(data2 <= data1 && data2 <= data3) begin
                min_data <= data2;
            end
            else begin
                min_data <= data3;
            end
        end
    end

endmodule
