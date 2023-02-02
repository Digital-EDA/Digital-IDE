// template
module  template  #(
        parameter    INPUT_WIDTH  = 12,
        parameter    OUTPUT_WIDTH = 12
    )(
        input [INPUT_WIDTH
               - 1 : 0]data_in,
        output reg clk_in = (INPUT_WIDTH -
                             OUTPUT_WIDTH) ,
        clk=9'hd0,
        input rst_n, RST,
        output [OUTPUT_WIDTH - 1 : 0] data_out
    );

endmodule  //template


module test # (
        parameter    INPUT_WIDTH  = 12,
        parameter    OUTPUT_WIDTH = 12
    )(
        input                           clk_in,
        input                           rst_n,
        input  [INPUT_WIDTH - 1 : 0]    data_in , [3:2] dasta_ff,
        output reg signed [OUTPUT_WIDTH - 1 : 0]   data_out,
        reg signed [OUTPUT_WIDTH - 1 : 0]   data_ff
    );

    wire               	valid_out;

    Cordic #(
               .XY_BITS      		( 12       		),
               .PH_BITS      		( 32       		),
               .ITERATIONS   		( 32       		),
               .CORDIC_STYLE 		( "ROTATE" 		),
               .PHASE_ACC    		( "ON"     		))
           u_Cordic(
               //input
               .clk_in    		( clk_in    		),
               .RST       		( RST       		),
               .x_i       		( x_i       		),
               .y_i       		( y_i       		),
               .phase_in  		( phase_in  		),
               .valid_in  		( valid_in  		),

               //output
               .x_o       		( x_o       		),
               .y_o       		( y_o       		),
               .phase_out 		( phase_out 		),
               .valid_out 		( valid_out 		)

               //inout
           );

    wire [3 : 0] 	count_high;
    wire [3 : 0] 	count_low;
    wire              	over;

    template u_template(
                 //input
                 .clk        		( clk        		),
                 .data       		( data       		),
                 .en         		( en         		),
                 .load       		( load       		),
                 .rst        		( rst        		),
                 .switch     		( switch     		),

                 //output
                 .count_high 		( count_high 		),
                 .count_low  		( count_low  		),
                 .over       		( over       		)

                 //inout
             );



endmodule  //test
