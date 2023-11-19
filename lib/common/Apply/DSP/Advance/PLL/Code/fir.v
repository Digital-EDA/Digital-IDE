module FIR(clock, reset, data_in, data_out);
   input         clock;
   input         reset;
   input [11:0]  data_in;
   output [11:0] data_out;
   reg [11:0]    data_out;
   
   
   reg [15:0]    d0;
   reg [15:0]    d1;
   reg [15:0]    d2;
   reg [15:0]    d3;
   reg [15:0]    d4;
   reg [15:0]    d5;
   reg [15:0]    d6;
   reg [15:0]    d7;
   reg [15:0]    d8;
   reg [15:0]    d9;
   reg [15:0]    d10;
   reg [15:0]    d11;
   reg [15:0]    d12;
   reg [15:0]    d13;
   reg [15:0]    d14;
   reg [15:0]    d15;
   reg [15:0]    sum;
   
   
   always @(posedge clock or posedge reset)
      if (reset == 1'b1)
      begin
         d0 <= {16{1'b0}};
         d1 <= {16{1'b0}};
         d2 <= {16{1'b0}};
         d3 <= {16{1'b0}};
         d4 <= {16{1'b0}};
         d5 <= {16{1'b0}};
         d6 <= {16{1'b0}};
         d7 <= {16{1'b0}};
         d8 <= {16{1'b0}};
         d9 <= {16{1'b0}};
         d10 <= {16{1'b0}};
         d11 <= {16{1'b0}};
         d12 <= {16{1'b0}};
         d13 <= {16{1'b0}};
         d14 <= {16{1'b0}};
         d15 <= {16{1'b0}};
         sum <= {16{1'b0}};
         data_out <= {12{1'b0}};
      end
      else 
      begin
         d0 <= {data_in[11], data_in[11], data_in[11], data_in[11], data_in};
         d1 <= d0;
         d2 <= d1;
         d3 <= d2;
         d4 <= d3;
         d5 <= d4;
         d6 <= d5;
         d7 <= d6;
         d8 <= d7;
         d9 <= d8;
         d10 <= d9;
         d11 <= d10;
         d12 <= d11;
         d13 <= d12;
         d14 <= d13;
         d15 <= d14;
         sum <= (d0 + d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8 + d9 + d10 + d11 + d12 + d13 + d14 + d15) >> 4;
         data_out <= (sum[11:0]);
      end
   
endmodule
