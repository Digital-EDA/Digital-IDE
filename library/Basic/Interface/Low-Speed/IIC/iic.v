module iic_driver #(
        parameter DEVICE_ADDR = 7'b1010000,
        parameter CLK_FREQ    = 26'd50_000_000,
        parameter I2C_FREQ    = 19'd400_000,
        parameter PROTOCOL    = "IIC"
    ) (
        input             clock,
        input             reset,
        input             bit_ctrl,
        input             iic_exe,
        input             iic_rw_ctrl,
        input  [15:0]     iic_addr,
        input  [7:0]      iic_data_in,

        output reg [7:0]  iic_data_out,
        output reg        iic_ack,
        output reg        iic_done,
        output            scl,
        inout             sda,

        output            dri_clk
        //input             sda_in,
        //output reg        sda_out
    );

    localparam IDLE         = 5'd0;
    localparam START1       = 5'd1;

    localparam WRITE_DEVICE = 5'd2;
    localparam ACK_W1       = 5'd3;
    localparam WRITE_WORD1  = 5'd4;
    localparam ACK_W2       = 5'd5;
    localparam WRITE_WORD2  = 5'd6;
    localparam ACK_W3       = 5'd7;
    localparam WRITE_DATA   = 5'd8;
    localparam ACK_W4       = 5'd9;

    localparam READ_DEVICE1 = 5'd10;
    localparam ACK_R1       = 5'd11;
    localparam READ_WORD1   = 5'd12;
    localparam ACK_R2       = 5'd13;
    localparam READ_WORD2   = 5'd14;
    localparam ACK_R3       = 5'd15;
    localparam START2       = 5'd16;
    localparam READ_DEVICE2 = 5'd17;
    localparam ACK_R4       = 5'd18;
    localparam READ_DATA    = 5'd19;
    localparam ACK_R5       = 5'd20;

    localparam STOP         = 5'd21;

    localparam CNT = (CLK_FREQ/I2C_FREQ);

    //scl
    reg [$clog2(CNT) - 1 : 0] scl_cnt;
    reg [$clog2(CNT) - 1 : 0] dri_cnt;
    (* mark_debug = "TRUE" *)reg [4:0] state_now,state_next;

    wire stop_flag;
    wire keep_flag;//at this point, the level should remain unchanged
    wire mend_flag;//at this point, the level can change

    assign stop_flag = (state_now == IDLE)   || 
                    (state_now == START1) || 
                    (state_now == START2)
                        ? 1'b1 : 1'b0;

    assign keep_flag = (scl_cnt == (CNT/4) * 3 - 1'b1) ? 1'b1 : 1'b0;
    assign mend_flag = (scl_cnt == CNT/4 - 1'b1)       ? 1'b1 : 1'b0;

    assign scl = stop_flag ? 1'b1 : ((scl_cnt <= CNT/2 - 1'b1) ? 1'b0 : 1'b1);

    always @(posedge clock) begin
        if(reset == 1'b0)begin
            scl_cnt <= 9'd0;
        end
        else if(state_now == IDLE)begin
            scl_cnt <= 9'd0;
        end
        else begin
            if(scl_cnt == CNT - 1'b1)
                scl_cnt <= 9'd0;
            else 
                scl_cnt <= scl_cnt + 1'b1;
        end
    end

    always @(posedge clock) begin
        if(reset == 1'b0)begin
            dri_cnt <= 9'd0;
        end
        else begin
            if(dri_cnt == CNT - 1'b1)
                dri_cnt <= 9'd0;
            else 
                dri_cnt <= dri_cnt + 1'b1;
        end
    end

    //dri_clk
    assign dri_clk = (dri_cnt <= CNT/2 - 1'b1) ? 1'b1 : 1'b0;

    //state
    reg [3:0] bit_cnt;
    (* mark_debug = "TRUE" *)reg       sda_out;
    (* mark_debug = "TRUE" *)wire      sda_in;

    assign sda_in = sda;

    always @(posedge clock) begin
        if(reset == 1'b0)
            state_now <= IDLE;
        else 
            state_now <= state_next;
    end

    always @(*) begin
        if(reset == 1'b0)
            state_next <= IDLE;
        else begin
            case(state_now)
                IDLE:begin
                    if(iic_exe)
                        state_next <= START1;
                    else 
                        state_next <= IDLE;
                end
                START1:begin
                    if(scl_cnt == CNT - 1'b1)begin
                        if(iic_rw_ctrl)
                            state_next <= WRITE_DEVICE;
                        else 
                            state_next <= READ_DEVICE1;
                    end
                    else
                        state_next <= START1;
                end
                WRITE_DEVICE:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_W1;
                    else 
                        state_next <= WRITE_DEVICE;
                end
                ACK_W1:begin
                    if(iic_ack)begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= WRITE_WORD1;
                        else 
                            state_next <= ACK_W1;
                    end
                    else begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= STOP;
                        else 
                            state_next <= ACK_W1;
                    end
                end
                WRITE_WORD1:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_W2;
                    else 
                        state_next <= WRITE_WORD1;
                end
                ACK_W2:begin
                    if(iic_ack)begin
                        if(bit_ctrl)begin
                            if(scl_cnt == CNT - 1'b1)
                                state_next <= WRITE_WORD2;
                            else 
                                state_next <= ACK_W2;
                        end
                        else begin
                            if(scl_cnt == CNT - 1'b1)
                                state_next <= WRITE_DATA;
                            else 
                                state_next <= ACK_W2;
                        end
                    end
                    else begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= STOP;
                        else 
                            state_next <= ACK_W2;
                    end
                end
                WRITE_WORD2:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_W3;
                    else 
                        state_next <= WRITE_WORD2;
                end
                ACK_W3:begin
                    if(iic_ack)begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= WRITE_DATA;
                        else 
                            state_next <= ACK_W3;
                    end
                    else begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= STOP;
                        else 
                            state_next <= ACK_W3;
                    end
                end
                WRITE_DATA:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_W4;
                    else 
                        state_next <= WRITE_DATA;
                end
                ACK_W4:begin
                    if(iic_ack)begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= STOP;
                        else 
                            state_next <= ACK_W4;
                    end
                    else begin
                        state_next <= ACK_W4;
                    end
                end
                //{DEVICE_ADDR + WORD_ADDR + DATA}
                READ_DEVICE1:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_R1;
                    else 
                        state_next <= READ_DEVICE1;
                end
                ACK_R1:begin
                    if(iic_ack)begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= READ_WORD1;
                        else 
                            state_next <= ACK_R1;
                    end
                    else begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= STOP;
                        else 
                            state_next <= ACK_R1;
                    end
                end
                READ_WORD1:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_R2;
                    else 
                        state_next <= READ_WORD1;
                end
                ACK_R2:begin
                    if(iic_ack)begin
                        if(bit_ctrl)begin
                            if(scl_cnt == CNT - 1'b1)
                                state_next <= READ_WORD2;
                            else
                                state_next <= ACK_R2;
                        end
                        else begin
                            if(scl_cnt == CNT - 1'b1)
                                state_next <= START2;
                            else
                                state_next <= ACK_R2;
                        end
                    end
                    else begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= STOP;
                        else 
                            state_next <= ACK_R2;
                    end
                end
                READ_WORD2:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_R3;
                    else 
                        state_next <= READ_WORD2;
                end
                ACK_R3:begin
                    if(iic_ack)begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= START2;
                        else 
                            state_next <= ACK_R3;
                    end
                    else begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= STOP;
                        else 
                            state_next <= ACK_R3;
                    end
                end
                START2:begin
                    if(scl_cnt == CNT - 1'b1)
                        state_next <= READ_DEVICE2;
                    else    
                        state_next <= START2;
                end
                READ_DEVICE2:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_R4;
                    else 
                        state_next <= READ_DEVICE2;
                end
                ACK_R4:begin
                    if(iic_ack)begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= READ_DATA;
                        else 
                            state_next <= ACK_R4;
                    end
                    else begin
                        if(scl_cnt == CNT - 1'b1)
                            state_next <= STOP;
                        else 
                            state_next <= ACK_R4;
                    end
                end
                READ_DATA:begin
                    if(bit_cnt == 4'd8)
                        state_next <= ACK_R5;
                    else 
                        state_next <= READ_DATA;
                end
                ACK_R5:begin
                    if(scl_cnt == CNT - 1'b1)
                        state_next <= STOP;
                    else 
                        state_next <= ACK_R5;
                end
                STOP:begin
                    if(scl_cnt == CNT - 1'b1)
                        state_next <= IDLE;
                    else    
                        state_next <= STOP;
                end
                default:begin
                    state_next <= IDLE;
                end
            endcase
        end
    end

    //sda
    wire ack  = (state_now == ACK_W1) || 
                (state_now == ACK_W2) ||
                (state_now == ACK_W3) ||
                (state_now == ACK_W4) ||
                (state_now == ACK_R1) ||
                (state_now == ACK_R2) ||
                (state_now == ACK_R3) ||
                (state_now == ACK_R4) ||
                (state_now == ACK_R5) ? 1'b1 : 1'b0;

    wire turn = (state_now == IDLE)   ||
                (state_now == START1) ||
                (state_now == START2) ||
                (state_now == STOP) ? 1'b1 : 1'b0;

    //bit_cnt
    reg mend_cnt;

    always @(posedge clock) begin
        if(reset == 1'b0)begin
            bit_cnt  <= 4'd0;
            mend_cnt <= 1'b0;
        end
        else if(ack || turn)begin
            bit_cnt  <= 4'd0;
            mend_cnt <= 1'b0;
        end
        else begin
            if(mend_flag)
                mend_cnt <= 1'b1;
            if(mend_flag && mend_cnt)
                bit_cnt  <= bit_cnt + 1'b1;
        end
    end

    //sda_out
    always @(posedge clock) begin
        if(reset == 1'b0)
            sda_out <= 1'b1;
        else begin
            case(state_now)
                IDLE:begin
                    sda_out <= 1'b1;
                end
                START1:begin
                    if(scl_cnt <= CNT/2 - 1'b1)
                        sda_out <= 1'b1;
                    else 
                        sda_out <= 1'b0;
                end
                START2:begin
                    if(scl_cnt <= CNT/2 - 1'b1)
                        sda_out <= 1'b1;
                    else 
                        sda_out <= 1'b0;
                end
                WRITE_DEVICE:begin
                    case(bit_cnt)
                        4'd0: sda_out <= DEVICE_ADDR[6];
                        4'd1: sda_out <= DEVICE_ADDR[5];
                        4'd2: sda_out <= DEVICE_ADDR[4];
                        4'd3: sda_out <= DEVICE_ADDR[3];
                        4'd4: sda_out <= DEVICE_ADDR[2];
                        4'd5: sda_out <= DEVICE_ADDR[1];
                        4'd6: sda_out <= DEVICE_ADDR[0];
                        4'd7: sda_out <= 1'b0;
                        4'd8: sda_out <= 1'b0;
                        default:begin
                            sda_out <= 1'b0;
                        end
                    endcase
                end
                READ_DEVICE1:begin
                    case(bit_cnt)
                        4'd0: sda_out <= DEVICE_ADDR[6];
                        4'd1: sda_out <= DEVICE_ADDR[5];
                        4'd2: sda_out <= DEVICE_ADDR[4];
                        4'd3: sda_out <= DEVICE_ADDR[3];
                        4'd4: sda_out <= DEVICE_ADDR[2];
                        4'd5: sda_out <= DEVICE_ADDR[1];
                        4'd6: sda_out <= DEVICE_ADDR[0];
                        4'd7: sda_out <= 1'b0;
                        4'd8: sda_out <= 1'b0;
                        default:begin
                            sda_out <= 1'b0;
                        end
                    endcase
                end
                WRITE_WORD1:begin
                    if(bit_cnt == 4'd8)
                        sda_out <= sda_out;
                    else 
                        sda_out <= iic_addr[15 - bit_cnt];
                end
                READ_WORD1:begin
                    if(bit_cnt == 4'd8)
                        sda_out <= sda_out;
                    else 
                        sda_out <= iic_addr[15 - bit_cnt];
                end
                WRITE_WORD2:begin
                    if(bit_cnt == 4'd8)
                        sda_out <= sda_out;
                    else 
                        sda_out <= iic_addr[7 - bit_cnt];
                end
                READ_WORD2:begin
                    if(bit_cnt == 4'd8)
                        sda_out <= sda_out;
                    else 
                        sda_out <= iic_addr[7 - bit_cnt];
                end
                WRITE_DATA:begin
                    if(bit_cnt == 4'd8)
                        sda_out <= sda_out;
                    else 
                        sda_out <= iic_data_in[7 - bit_cnt];
                end
                READ_DEVICE2:begin
                    case(bit_cnt)
                        4'd0: sda_out <= DEVICE_ADDR[6];
                        4'd1: sda_out <= DEVICE_ADDR[5];
                        4'd2: sda_out <= DEVICE_ADDR[4];
                        4'd3: sda_out <= DEVICE_ADDR[3];
                        4'd4: sda_out <= DEVICE_ADDR[2];
                        4'd5: sda_out <= DEVICE_ADDR[1];
                        4'd6: sda_out <= DEVICE_ADDR[0];
                        4'd7: sda_out <= 1'b1;
                        4'd8: sda_out <= 1'b1;
                        default:begin
                            sda_out <= 1'b1;
                        end
                    endcase
                end
                STOP:begin
                    if(scl_cnt <= (CNT/4) * 3 - 1'b1)
                        sda_out <= 1'b0;
                    else 
                        sda_out <= 1'b1;
                end
                default:begin
                    sda_out <= 1'b0;
                end
            endcase
        end
    end

    //iic_data_out
    reg [7:0] r_iic_data_out;

    always @(posedge clock) begin
        if(reset == 1'b0)
            r_iic_data_out <= 8'd0;
        else if(state_now == READ_DATA)begin
            if(bit_cnt == 4'd8)
                r_iic_data_out              <= r_iic_data_out;
            else 
                r_iic_data_out[7 - bit_cnt] <= sda_in;
        end
    end

    always @(posedge clock) begin
        if(reset == 1'b0)
            iic_data_out <= 8'd0;
        else if(state_now == STOP)begin
            iic_data_out <= r_iic_data_out;
        end
    end

    //iic_ack
    generate if(PROTOCOL == "IIC") begin : IIC
        always @(posedge clock) begin
            if(reset == 1'b0)
                iic_ack <= 1'b0;
            else if(ack)begin
                if(keep_flag)begin
                    iic_ack <= ~sda_in;
                end
            end
            else begin
                iic_ack <= 1'b0;
            end
        end
    end
    endgenerate

    generate if(PROTOCOL == "SCCB") begin : SCCB
        always @(posedge clock) begin
            if(reset == 1'b0)
                iic_ack <= 1'b0;
            else if(ack)begin
                if(keep_flag)begin
                    iic_ack <= 1'b1;
                end
            end
            else begin
                iic_ack <= 1'b0;
            end
        end
    end
    endgenerate

    //iic_done
    always @(posedge clock) begin
        if(reset == 1'b0)begin
            iic_done <= 1'b0;
        end
        else if((state_now == STOP) && (scl_cnt == CNT - 1'b1))begin
            iic_done <= 1'b1;
        end
        else begin
            iic_done <= 1'b0;
        end
    end

    //sda
    assign sda = ((state_now != READ_DATA) && (ack != 1'b1)) ? sda_out : 1'bz;

endmodule
