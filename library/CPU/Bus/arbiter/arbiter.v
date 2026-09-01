/*
    可配置参数仲裁器
*/

// 取消隐式声明线网类型
`default_nettype none

module arbiter #(
        // 端口数
        parameter PORTS                 = 4,
        // 是否启用轮询仲裁
        parameter ARB_TYPE_ROUND_ROBIN  = 0,
        // 是否启用阻塞仲裁
        parameter ARB_BLOCK             = 0,
        // 非 0 时阻止 acknowledge 断言，0 时请求取消断言
        parameter ARB_BLOCK_ACK         = 1,
        // 是否启用最低有效位优先仲裁
        parameter ARB_LSB_HIGH_PRIORITY = 0
    ) (
        input  wire                     clock,          // 时钟信号
        input  wire                     reset,          // 复位信号
        input  wire [PORTS-1:0]         request,        // 请求信号
        input  wire [PORTS-1:0]         acknowledge,    // 确认信号
        output wire [PORTS-1:0]         grant,          // 授权信号
        output wire                     grant_valid,    // 授权有效信号
        output wire [$clog2(PORTS)-1:0] grant_encoded   // 编码的授权信号
    );

    reg [PORTS-1:0]         grant_reg           = 0;    // 授权寄存器
    reg [PORTS-1:0]         grant_next;                 // 下一个授权值    
    reg                     grant_valid_reg     = 0;    // 授权有效寄存器
    reg                     grant_valid_next;           // 下一个授权有效值
    reg [$clog2(PORTS)-1:0] grant_encoded_reg   = 0;    // 编码的授权寄存器
    reg [$clog2(PORTS)-1:0] grant_encoded_next;         // 下一个编码的授权值

    assign grant_valid      = grant_valid_reg;
    assign grant            = grant_reg;
    assign grant_encoded    = grant_encoded_reg;

    wire                        request_valid;          // 请求有效信号
    wire [$clog2(PORTS)-1:0]    request_index;          // 请求索引
    wire [PORTS-1:0]            request_mask;           // 请求掩码

    // 优先编码器实例化
    priority_encoder #(
        .WIDTH(PORTS),
        .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)) 
    priority_encoder_inst (
        .input_unencoded(request),
        .output_valid(request_valid),
        .output_encoded(request_index),
        .output_unencoded(request_mask)
    );

    reg  [PORTS-1:0]            mask_reg = 0; 
    reg  [PORTS-1:0]            mask_next;

    wire                        masked_request_valid;   // 掩码请求有效信号
    wire [$clog2(PORTS)-1:0]    masked_request_index;   // 掩码请求索引
    wire [PORTS-1:0]            masked_request_mask;    // 掩码请求掩码

    // 优先编码器掩码实例化
    priority_encoder #(
        .WIDTH(PORTS),
        .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)) 
    priority_encoder_masked (
        .input_unencoded(request & mask_reg),
        .output_valid(masked_request_valid),
        .output_encoded(masked_request_index),
        .output_unencoded(masked_request_mask)
    );

    always @(*) begin
        // 初始化下一状态
        grant_next          = 0;
        grant_valid_next    = 0;
        grant_encoded_next  = 0;
        mask_next           = mask_reg;

        if (ARB_BLOCK && !ARB_BLOCK_ACK && grant_reg & request) begin
            // 授权的请求仍然有效，保持当前授权
            grant_valid_next    = grant_valid_reg;
            grant_next          = grant_reg;
            grant_encoded_next  = grant_encoded_reg;
        end 
        else if (ARB_BLOCK && ARB_BLOCK_ACK && grant_valid && !(grant_reg & acknowledge)) begin
            // 授权的请求未被确认，保持当前授权
            grant_valid_next    = grant_valid_reg;
            grant_next          = grant_reg;
            grant_encoded_next  = grant_encoded_reg;
        end 
        else if (request_valid) begin
            if (ARB_TYPE_ROUND_ROBIN) begin
                if (masked_request_valid) begin
                    // 轮询仲裁，并找到有效请求
                    grant_valid_next    = 1;
                    grant_next          = masked_request_mask;
                    grant_encoded_next  = masked_request_index;
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        mask_next = {PORTS{1'b1}} << (masked_request_index + 1);
                    end else begin
                        mask_next = {PORTS{1'b1}} >> (PORTS - masked_request_index);
                    end
                end 
                else begin
                    // 没有掩码请求，使用普通请求
                    grant_valid_next    = 1;
                    grant_next          = request_mask;
                    grant_encoded_next  = request_index;
                    if (ARB_LSB_HIGH_PRIORITY) begin
                        mask_next = {PORTS{1'b1}} << (request_index + 1);
                    end else begin
                        mask_next = {PORTS{1'b1}} >> (PORTS - request_index);
                    end
                end
            end 
            else begin
                // 非轮询仲裁，直接使用普通请求
                grant_valid_next    = 1;
                grant_next          = request_mask;
                grant_encoded_next  = request_index;
            end
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // 在复位信号时重置所有寄存器
            grant_reg           <= 0;
            grant_valid_reg     <= 0;
            grant_encoded_reg   <= 0;
            mask_reg            <= 0;
        end 
        else begin
            // 正常时钟周期更新寄存器
            grant_reg           <= grant_next;
            grant_valid_reg     <= grant_valid_next;
            grant_encoded_reg   <= grant_encoded_next;
            mask_reg            <= mask_next;
        end
    end

endmodule

`resetall
