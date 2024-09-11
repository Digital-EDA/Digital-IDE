module phase_acc(clr,en,rst,valid_out1,clk,add_sub,sel,D,Q);
    parameter DATASIZE=16;
    input  clr,en,rst,clk,add_sub,sel,valid_out1;
    input  [DATASIZE-1:0] D;
    output [DATASIZE:0]   Q;

    reg count0,count1,count2,count3;
    reg [DATASIZE:0] b_tmp,b_tmp0,b_tmp1,b_tmp2;
    reg [3:0] sum0;
    reg [7:0] sum1;
    reg [11:0] sum2;
    reg [16:0] sum3;
    reg add_sub0,add_sub1,add_sub2;
    reg clr0,clr1,clr2;
   
    always @(posedge clk) begin
        case({clr,add_sub})
            2'b00:{count0,sum0}<={1'b0,sum0}+{1'b0,D[3:0]};
            2'b01:{count0,sum0}<={1'b0,sum0}-{1'b0,D[3:0]};
            2'b10:{count0,sum0}<=5'b0+{1'b0,D[3:0]};
            default:{count0,sum0}<=5'b0-{1'b0,D[3:0]};
        endcase
        b_tmp0<=D;
        clr0<=clr;
        add_sub0<=add_sub;
    end
    
    always @(posedge clk)
    begin
        case({clr0,add_sub0})
            2'b00:{count1,sum1}<={{1'b0,sum1[7:4]}+{1'b0,b_tmp0[7:4]}+count0,sum0};
            2'b01:{count1,sum1}<={{1'b0,sum1[7:4]}-{1'b0,b_tmp0[7:4]}-count0,sum0};
            2'b10:{count1,sum1}<=5'b0+{1'b0,b_tmp0[7:4]};
            default:{count1,sum1}<=5'b0-{1'b0,b_tmp0[7:4]};
        endcase
        b_tmp1<=b_tmp0;
        clr1<=clr0;
        add_sub1<=add_sub0;
    end
    
    always @(posedge clk)
    begin
        case({clr1,add_sub1})
            2'b00:{count2,sum2}<={{1'b0,sum2[11:8]}+{1'b0,b_tmp1[11:8]}+count1,sum1};
            2'b01:{count2,sum2}<={{1'b0,sum2[11:8]}-{1'b0,b_tmp1[11:8]}-count1,sum1};
            2'b10:{count2,sum2}<=5'b0+{1'b0,b_tmp1[11:8]};
            default:{count2,sum2}<=5'b0-{1'b0,b_tmp1[11:8]};
        endcase
        b_tmp2<=b_tmp1;
        clr2<=clr1;
        add_sub2<=add_sub1;
    end
    
    always @(posedge clk) begin
        case({clr2,add_sub2})
            2'b00:sum3<={sum3[16:12]+{1'b0,b_tmp2[15:12]}+count2,sum2};
            2'b01:sum3<={sum3[16:12]-{1'b0,b_tmp2[15:12]}-count2,sum2};
            2'b10:sum3<=5'b0+{1'b0,b_tmp2[15:12]};
            default:sum3<=5'b0-{1'b0,b_tmp2[15:12]};
        endcase
    end
assign Q=sum3;
endmodule