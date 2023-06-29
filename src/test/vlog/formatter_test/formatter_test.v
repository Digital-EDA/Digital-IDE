module formatter_vlog #(  
    parameter INPUT_WIDTH = 12,  
    parameter OUTPUT_WIDTH = 12  
) (  
    input clk_in,  
    input rst_n,  
    input [INPUT_WIDTH - 1 : 0]data_in,  
    output [OUTPUT_WIDTH - 1 : 0]data_out  
); 

reg [3:0] cnt; always @(posedge clk_in or posedge rst_n) begin  if(rst_n) begin  cnt<=4'h0;  end  else begin  cnt<=cnt+4'h1;  end end endmodule //module_name 