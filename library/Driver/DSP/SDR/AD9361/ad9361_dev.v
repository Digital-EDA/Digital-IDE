`timescale 1ns/100ps

module ad9361_dev (
        // physical interface (receive)
        input              rx_clk_in_p,
        input              rx_clk_in_n,
        input              rx_frame_in_p,
        input              rx_frame_in_n,
        input   [5:0]      rx_data_in_p,
        input   [5:0]      rx_data_in_n,

        // physical interface (transmit)
        output             tx_clk_out_p,
        output             tx_clk_out_n,
        output             tx_frame_out_p,
        output             tx_frame_out_n,
        output  [5:0]      tx_data_out_p,
        output  [5:0]      tx_data_out_n,

        // clock (common to both receive and transmit)
        input              rst_n,
        input              tx_clk,
        output             rx_clk,

        // receive data path interface
        output reg         adc_valid,
        output reg [47:0]  adc_data,
        output reg         adc_status,
        input              adc_r1_mode,

        // transmit data path interface
        input              dac_valid,
        input   [47:0]     dac_data,
        input              dac_r1_mode
    );

    // this parameter controls the buffer type based on the target device.
    parameter   PCORE_DEVICE_TYPE = 0;

    // internal registers
    reg     [ 5:0]  rx_data_p;
    reg             rx_frame_p;
    reg     [ 1:0]  rx_ccnt;
    reg             rx_calign;
    reg             rx_align;
    reg     [11:0]  rx_data;
    reg     [ 1:0]  rx_frame;
    reg     [11:0]  rx_data_d;
    reg     [ 1:0]  rx_frame_d;
    reg             rx_error_r1;
    reg             rx_valid_r1;
    reg     [23:0]  rx_data_r1;
    reg             rx_error_r2;
    reg             rx_valid_r2;
    reg     [47:0]  rx_data_r2;
    reg             adc_p_valid;
    reg     [47:0]  adc_p_data;
    reg             adc_p_status;
    reg             adc_n_valid;
    reg     [47:0]  adc_n_data;
    reg             adc_n_status;
    reg             adc_valid_int;
    reg     [47:0]  adc_data_int;
    reg             adc_status_int;
    reg     [ 2:0]  tx_data_cnt;
    reg     [47:0]  tx_data;
    reg             tx_frame;
    reg     [ 5:0]  tx_data_p;
    reg     [ 5:0]  tx_data_n;
    reg             tx_n_frame;
    reg     [ 5:0]  tx_n_data_p;
    reg     [ 5:0]  tx_n_data_n;
    reg             tx_p_frame;
    reg     [ 5:0]  tx_p_data_p;
    reg     [ 5:0]  tx_p_data_n;

    // internal signals

    wire            rx_align_s;
    wire    [ 3:0]  rx_frame_s;
    wire    [ 3:0]  tx_data_sel_s;
    wire    [ 5:0]  rx_data_p_s;
    wire    [ 5:0]  rx_data_n_s;
    wire            rx_frame_p_s;
    wire            rx_frame_n_s;

    genvar          l_inst;

    // receive data path interface
    assign rx_align_s = rx_frame_n_s ^ rx_frame_p_s;

    always @(posedge rx_clk) begin
        rx_data_p <= rx_data_p_s;
        rx_frame_p <= rx_frame_p_s;
        rx_ccnt <= rx_ccnt + 1'b1;
        if (rx_ccnt == 2'd0) begin
            rx_calign <= rx_align;
            rx_align <= rx_align_s;
        end
        else begin
            rx_calign <= rx_calign;
            rx_align <= rx_align | rx_align_s;
        end
    end

    assign rx_frame_s = {rx_frame_d, rx_frame};

    always @(posedge rx_clk) begin
        if (rx_calign == 1'b1) begin
            rx_data <= {rx_data_p, rx_data_n_s};
            rx_frame <= {rx_frame_p, rx_frame_n_s};
        end
        else begin
            rx_data <= {rx_data_n_s, rx_data_p_s};
            rx_frame <= {rx_frame_n_s, rx_frame_p_s};
        end
        rx_data_d <= rx_data;
        rx_frame_d <= rx_frame;
    end

    // receive data path for single rf, frame is expected to qualify i/q msb only
    always @(posedge rx_clk) begin
        rx_error_r1 <= ((rx_frame_s == 4'b1100) || (rx_frame_s == 4'b0011)) ? 1'b0 : 1'b1;
        rx_valid_r1 <= (rx_frame_s == 4'b1100) ? 1'b1 : 1'b0;
        if (rx_frame_s == 4'b1100) begin
            rx_data_r1[11: 0] <= {rx_data_d[11:6], rx_data[11:6]};
            rx_data_r1[23:12] <= {rx_data_d[ 5:0], rx_data[ 5:0]};
        end
    end

    // receive data path for dual rf, frame is expected to qualify i/q msb and lsb for rf-1 only
    always @(posedge rx_clk) begin
        rx_error_r2 <= ((rx_frame_s == 4'b1111) || (rx_frame_s == 4'b1100) ||
                        (rx_frame_s == 4'b0000) || (rx_frame_s == 4'b0011)) ? 1'b0 : 1'b1;
        rx_valid_r2 <= (rx_frame_s == 4'b0000) ? 1'b1 : 1'b0;
        if (rx_frame_s == 4'b1111) begin
            rx_data_r2[11: 0] <= {rx_data_d[11:6], rx_data[11:6]};
            rx_data_r2[23:12] <= {rx_data_d[ 5:0], rx_data[ 5:0]};
        end
        if (rx_frame_s == 4'b0000) begin
            rx_data_r2[35:24] <= {rx_data_d[11:6], rx_data[11:6]};
            rx_data_r2[47:36] <= {rx_data_d[ 5:0], rx_data[ 5:0]};
        end
    end

    // receive data path mux
    always @(posedge rx_clk) begin
        if (adc_r1_mode == 1'b1) begin
            adc_p_valid <= rx_valid_r1;
            adc_p_data <= {24'd0, rx_data_r1};
            adc_p_status <= ~rx_error_r1;
        end
        else begin
            adc_p_valid <= rx_valid_r2;
            adc_p_data <= rx_data_r2;
            adc_p_status <= ~rx_error_r2;
        end
    end

    // transfer to a synchronous common clock
    always @(negedge rx_clk) begin
        adc_n_valid <= adc_p_valid;
        adc_n_data <= adc_p_data;
        adc_n_status <= adc_p_status;
    end

    always @(posedge rx_clk) begin
        adc_valid_int <= adc_n_valid;
        adc_data_int <= adc_n_data;
        adc_status_int <= adc_n_status;
        adc_valid <= adc_valid_int;
        if (adc_valid_int == 1'b1) begin
            adc_data <= adc_data_int;
        end
        adc_status <= adc_status_int;
    end

    // transmit data path mux (reverse of what receive does above)
    // the count simply selets the data muxing on the ddr outputs
    assign tx_data_sel_s = {tx_data_cnt[2], dac_r1_mode, tx_data_cnt[1:0]};

    always @(posedge tx_clk) begin
        if (dac_valid == 1'b1) begin
            tx_data_cnt <= 3'b100;
        end
        else if (tx_data_cnt[2] == 1'b1) begin
            tx_data_cnt <= tx_data_cnt + 1'b1;
        end
        if (dac_valid == 1'b1) begin
            tx_data <= dac_data;
        end
        case (tx_data_sel_s)
            4'b1111: begin
                tx_frame <= 1'b0;
                tx_data_p <= tx_data[ 5: 0];
                tx_data_n <= tx_data[17:12];
            end
            4'b1110: begin
                tx_frame <= 1'b1;
                tx_data_p <= tx_data[11: 6];
                tx_data_n <= tx_data[23:18];
            end
            4'b1101: begin
                tx_frame <= 1'b0;
                tx_data_p <= tx_data[ 5: 0];
                tx_data_n <= tx_data[17:12];
            end
            4'b1100: begin
                tx_frame <= 1'b1;
                tx_data_p <= tx_data[11: 6];
                tx_data_n <= tx_data[23:18];
            end
            4'b1011: begin
                tx_frame <= 1'b0;
                tx_data_p <= tx_data[29:24];
                tx_data_n <= tx_data[41:36];
            end
            4'b1010: begin
                tx_frame <= 1'b0;
                tx_data_p <= tx_data[35:30];
                tx_data_n <= tx_data[47:42];
            end
            4'b1001: begin
                tx_frame <= 1'b1;
                tx_data_p <= tx_data[ 5: 0];
                tx_data_n <= tx_data[17:12];
            end
            4'b1000: begin
                tx_frame <= 1'b1;
                tx_data_p <= tx_data[11: 6];
                tx_data_n <= tx_data[23:18];
            end
            default: begin
                tx_frame <= 1'b0;
                tx_data_p <= 6'd0;
                tx_data_n <= 6'd0;
            end
        endcase
    end

    // transfer data from a synchronous clock (skew less than 2ns)
    always @(negedge tx_clk) begin
        tx_n_frame <= tx_frame;
        tx_n_data_p <= tx_data_p;
        tx_n_data_n <= tx_data_n;
    end

    always @(posedge tx_clk) begin
        tx_p_frame <= tx_n_frame;
        tx_p_data_p <= tx_n_data_p;
        tx_p_data_n <= tx_n_data_n;
    end

    // receive data interface, ibuf -> idelay -> iddr
    generate
        for (l_inst = 0; l_inst <= 5; l_inst = l_inst + 1) begin: g_rx_data
            ad_lvds_in #(
                .BUFTYPE (PCORE_DEVICE_TYPE))
            i_rx_data (
                .rx_clk (rx_clk),
                .rx_data_in_p (rx_data_in_p[l_inst]),
                .rx_data_in_n (rx_data_in_n[l_inst]),
                .rx_data_p (rx_data_p_s[l_inst]),
                .rx_data_n (rx_data_n_s[l_inst])
            );
        end
    endgenerate

    // receive frame interface, ibuf -> idelay -> iddr
    ad_lvds_in #(
        .BUFTYPE (PCORE_DEVICE_TYPE))
    i_rx_frame (
        .rx_clk (rx_clk),
        .rx_data_in_p (rx_frame_in_p),
        .rx_data_in_n (rx_frame_in_n),
        .rx_data_p (rx_frame_p_s),
        .rx_data_n (rx_frame_n_s)
    );

    // transmit data interface, oddr -> obuf
    generate
        for (l_inst = 0; l_inst <= 5; l_inst = l_inst + 1) begin: g_tx_data
            ad_lvds_out #(
                .BUFTYPE (PCORE_DEVICE_TYPE))
            i_tx_data (
                .tx_clk (tx_clk),
                .tx_data_p (tx_p_data_p[l_inst]),
                .tx_data_n (tx_p_data_n[l_inst]),
                .tx_data_out_p (tx_data_out_p[l_inst]),
                .tx_data_out_n (tx_data_out_n[l_inst])
            );
        end
    endgenerate

    // transmit frame interface, oddr -> obuf
    ad_lvds_out #(
        .BUFTYPE (PCORE_DEVICE_TYPE))
    i_tx_frame (
        .tx_clk (rx_clk),
        .tx_data_p (tx_p_frame),
        .tx_data_n (tx_p_frame),
        .tx_data_out_p (tx_frame_out_p),
        .tx_data_out_n (tx_frame_out_n)
    );

    // transmit clock interface, oddr -> obuf
    ad_lvds_out #(
        .BUFTYPE (PCORE_DEVICE_TYPE))
    i_tx_clk (
        .tx_clk (tx_clk),
        .tx_data_p (1'b0),
        .tx_data_n (1'b1),
        .tx_data_out_p (tx_clk_out_p),
        .tx_data_out_n (tx_clk_out_n)
    );

    // device clock interface (receive clock)
    ad_lvds_clk #(
        .BUFTYPE (0))
    i_rx_clk (
        .clk_in_p (rx_clk_in_p),
        .clk_in_n (rx_clk_in_n),
        .tx_clk (rx_clk)
    );

endmodule
