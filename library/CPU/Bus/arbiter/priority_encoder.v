/*
    可配置参数优先编码器
*/

// 取消隐式声明线网类型
`default_nettype none

module priority_encoder #(
        // 位宽
        parameter WIDTH             = 4,
        // 是否启用最低有效位优先
        parameter LSB_HIGH_PRIORITY = 0
    ) (
        input  wire [WIDTH-1:0]         input_unencoded,    // 输入的未编码信号
        output wire                     output_valid,       // 输出的有效信号
        output wire [$clog2(WIDTH)-1:0] output_encoded,     // 输出的编码信号
        output wire [WIDTH-1:0]         output_unencoded    // 输出的未编码信号(仅保留最高有效位信号)
    );

    parameter LEVELS    = WIDTH > 2 ? $clog2(WIDTH) : 1;
    parameter W         = 2 ** LEVELS;

    // 将输入填充为2的幂
    wire [W-1:0]    input_padded = {{W-WIDTH{1'b0}}, input_unencoded};

    wire [W/2-1:0]  stage_valid[LEVELS-1:0];
    wire [W/2-1:0]  stage_enc[LEVELS-1:0];

    generate
    genvar l, n;

    // 处理输入位；为每对生成有效位和编码位
    for (n = 0; n < W/2; n = n + 1) begin : loop_in
        assign stage_valid[0][n] = |input_padded[n*2+1:n*2];
        if (LSB_HIGH_PRIORITY) begin
            // 高位为最低有效位
            assign stage_enc[0][n] = !input_padded[n*2+0];
        end else begin
            // 低位为最低有效位
            assign stage_enc[0][n] = input_padded[n*2+1];
        end
    end



    for (l = 1; l < LEVELS; l = l + 1) begin : loop_levels
        for (n = 0; n < W/(2*2**l); n = n + 1) begin : loop_compress
            assign stage_valid[l][n] = |stage_valid[l-1][n*2+1:n*2];
            if (LSB_HIGH_PRIORITY) begin
                // 高位为最低有效位
                assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+0] ? {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]} : {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]};
            end else begin
                // 低位为最低有效位
                assign stage_enc[l][(n+1)*(l+1)-1:n*(l+1)] = stage_valid[l-1][n*2+1] ? {1'b1, stage_enc[l-1][(n*2+2)*l-1:(n*2+1)*l]} : {1'b0, stage_enc[l-1][(n*2+1)*l-1:(n*2+0)*l]};
            end
        end
    end

    endgenerate

    assign output_valid     = stage_valid[LEVELS-1];
    assign output_encoded   = output_valid ? stage_enc[LEVELS-1] : 0;
    assign output_unencoded = output_valid ? 1 << output_encoded : 0;
    // assign output_unencoded = 1 << output_encoded;

endmodule

`resetall
