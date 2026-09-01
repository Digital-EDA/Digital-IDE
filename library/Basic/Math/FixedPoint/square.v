//==================================================================================================
//  Filename      : Square.v
//  Created On    : 2019-05-12 17:06:04
//  Last Modified : 2019-05-12 17:06:04
//  Author 		  : DUAN
//  Revision      : By sublime_3   
//					module version is 1.0
//  Description   : 开平方根模块
//					相关计算公式 :Q=(uint32_t)sqrt(D)
//                  
//         			端口定义    ：D:数据输入    (d_width：数据输入的位宽)
//                  			 Q：计算后的得数的整数部分
//         			         	 R：	计算后的得数的余数部分
//                  			 ivalid ：数据输入有效位
//         			         	 dout_tvalid：数据输出有效位
//	Note          : 本代码遵循BSD开源协议			
//==================================================================================================
`timescale 1ns / 1ps
module Square #(
        parameter DWIDTH = 32,
        parameter QWIDTH = DWIDTH / 2,
        parameter RWIDTH = QWIDTH + 1
    )(
        input      clock,
        input      reset,
        input      ivalid,

        input      [DWIDTH-1:0] D,
        output reg [QWIDTH-1:0] Q,
        output reg [RWIDTH-1:0] R,
        output reg ovalid
    );
    


    reg [DWIDTH-1:0] D_t[QWIDTH:1];
    reg [QWIDTH-1:0] Q_t[QWIDTH:1];
    reg signed [RWIDTH-1:0] R_t[QWIDTH:1];
    reg din_tvalid_t[QWIDTH:1];
    
    always@(posedge clock) begin
        if(!reset) begin
            R_t[QWIDTH]<={RWIDTH{1'b0}};
            D_t[QWIDTH]<={DWIDTH{1'b0}};
            Q_t[QWIDTH]<={QWIDTH{1'b0}};
            din_tvalid_t[QWIDTH]<=1'b0;
        end
        else begin
            if(ivalid) begin
                R_t[QWIDTH]<={R[RWIDTH-3:0],D[DWIDTH-1:DWIDTH-2]} - {{QWIDTH-1{1'b0}},2'b01};
                D_t[QWIDTH]<=D;
                Q_t[QWIDTH]<={QWIDTH{1'b0}};
                din_tvalid_t[QWIDTH]<=1'b1;
            end
            else begin
                R_t[QWIDTH]<={RWIDTH{1'b0}};
                D_t[QWIDTH]<={DWIDTH{1'b0}};
                Q_t[QWIDTH]<={QWIDTH{1'b0}};
                din_tvalid_t[QWIDTH]<=1'b0;
            end
        end
    end
            
    generate
    genvar i;
    for(i=QWIDTH-1; i>=1; i=i-1) begin : U
        always@(posedge clock or posedge reset) begin
            if(reset) begin
                Q_t[i]<={QWIDTH{1'b0}};
                R_t[i]<={RWIDTH{1'b0}};
                D_t[i]<={DWIDTH{1'b0}};
                din_tvalid_t[i]<=1'b0;
            end
            else begin
                if(din_tvalid_t[i+1]) begin
                    if(R_t[i+1]>=0) begin
                        Q_t[i]<={Q_t[i+1][QWIDTH-2:0],1'b1};
                        R_t[i]<={R_t[i+1][RWIDTH-3:0],D_t[i+1][2*i-1:2*i-2]} - {1'b0,Q_t[i+1][QWIDTH-4:0],1'b1,2'b01};
                        D_t[i]<=D_t[i+1];
                        din_tvalid_t[i]<=1'b1;
                    end
                    else begin
                        Q_t[i]<={Q_t[i+1][QWIDTH-2:0],1'b0};
                        R_t[i]<={R_t[i+1][RWIDTH-3:0],D_t[i+1][2*i-1:2*i-2]} + {1'b0,Q_t[i+1][QWIDTH-4:0],1'b0,2'b11};
                        D_t[i]<=D_t[i+1];
                        din_tvalid_t[i]<=1'b1;
                    end
                end
                else begin
                    Q_t[i]<={QWIDTH{1'b0}};
                    R_t[i]<={RWIDTH{1'b0}};
                    D_t[i]<={DWIDTH{1'b0}};
                    din_tvalid_t[i]<=1'b0;
                end
            end
        end
    end
    endgenerate
    
    always@(posedge clock or posedge reset) begin
        if(reset) begin
            Q<={QWIDTH{1'b0}};
            R<={RWIDTH{1'b0}};
            ovalid<=1'b0;
        end
        else begin
            if(din_tvalid_t[1]) begin
                if(R_t[1]>=0) begin
                    Q<={Q_t[1][QWIDTH-2:0],1'b1};
                    R<=R_t[1];
                end
                else begin
                    Q<={Q_t[1][QWIDTH-2:0],1'b0};
                    R<=R_t[1] + {1'b0,Q_t[1][QWIDTH-3:0],1'b0,1'b1};
                end
                    ovalid<=1'b1;
            end
            else begin
                Q<={QWIDTH{1'b0}};
                R<={RWIDTH{1'b0}};
                ovalid<=1'b0;
            end
        end
    end
 
endmodule
