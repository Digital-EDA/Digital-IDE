/*
奇数倍分频：奇数倍分频常常在论坛上有人问起,实际上,奇数倍分频有两种实现方法：
首先,完全可以通过计数器来实现,如进行三分频,通过待分频时钟 上升沿触发计数器进行模三计数,
当计数器计数到邻近值进行两次翻转,比如可以在计数器计数到1时,输出时钟进行翻转,计数到2时再次进行翻转。
即是在计数 值在邻近的1和2进行了两次翻转。这样实现的三分频占空比为1/3或者2/3。

如果要实现占空比为50%的三分频时钟,
可以通过待分频时钟下降沿触发计数,和上升沿同样的方法计数进行三分频,
然后下降沿产生的三分频时钟和上升沿产生的时钟进行相或运算,即可得到占空比为50%的三分频时钟。
这种方法可以 实现任意的奇数分频。
归类为一般的方法为：对于实现占空比为50%的N倍奇数分频,
首先进行上升沿触发进行模N计数,计数选定到某一个值进行输出时钟翻 转,然后经过（N-1）/2再次进行翻转得到一个占空比非50%奇数n分频时钟。
再者同时进行下降沿触发的模N计数,到和上升沿触发输出时钟翻转选定值相 同值时,
进行输出时钟时钟翻转,同样经过（N-1）/2时,输出时钟再次翻转生成占空比非50%的奇数n分频时钟。
两个占空比非50%的n分频时钟相或运 算,得到占空比为50%的奇数n分频时钟。

另外一种方法：对进行奇数倍n分频时钟,首先进行n/2分频（带小数,即等于(n-1)/2+0.5）,
然后再 进行二分频得到。得到占空比为50%的奇数倍分频。
*/

/*******************************************************************************/
// wire             clk_div;
// CLK_DIV #
// (.WIDTH(8))
// CLK_DIV_u
// (
//     .clk_in(clk_sys),
//     .rst_n(1'b1),
//     .N(2),
//     .clk_div(clk_div)
// );
/*******************************************************************************/
`timescale 1ns / 1ps
module CLK_DIV #
(
    parameter WIDTH = 8
)
(
    input                 clk_in,
    input                 rst_n,
    input  [WIDTH - 1:0]  N,
    output                clk_div
);

reg [WIDTH-1:0] cnt_p = 0;// 上升沿计数单位
reg [WIDTH-1:0] cnt_n = 0;// 下降沿计数单位
reg             clk_in_p = 0;// 上升沿时钟
reg             clk_in_n = 0;// 下降沿时钟

//其中N==1是判断不分频，N[0]是判断是奇数还是偶数，若为1则是奇数分频，若是偶数则是偶数分频。
assign clk_div = (N == 1) ? clk_in : (N[0])   ? (clk_in_p | clk_in_n) : (clk_in_p);
        
always@(posedge clk_in or negedge rst_n) begin
    if (!rst_n)
        cnt_p <= 0;
    else if (cnt_p == (N-1))
        cnt_p <= 0;
    else
        cnt_p <= cnt_p + 1;
end

always@(posedge clk_in or negedge rst_n) begin
    if (!rst_n) 
        clk_in_p <= 1;//此处设置为0也是可以的，这个没有硬性的要求，不管是取0还是取1结果都是正确的。
    else if (cnt_p < (N>>1))/*N整体向右移动一位，最高位补零，其实就是N/2，不过在计算奇数的时候有很明显的优越性*/
        clk_in_p <= 1;
    else
        clk_in_p <= 0;    
end

always@(negedge clk_in or negedge rst_n) begin
    if (!rst_n)
        cnt_n <= 0;
    else if (cnt_n == (N-1))
        cnt_n <= 0;
    else
        cnt_n <= cnt_n + 1;
end

always@(negedge clk_in or negedge rst_n) begin
    if (!rst_n)
        clk_in_n <= 1;
    else if (cnt_n < (N>>1))
        clk_in_n <= 1;
    else
        clk_in_n <= 0;
end

endmodule

