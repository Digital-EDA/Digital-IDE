module AD9226 #(
        parameter signed CH_offset = 27
    )(
        input 			clock,
        input 			reset,
        input   [11:0] 	user_data,
        
        output 			adc_clk,
        output  [11:0] 	adc_data
    );

    reg signed [11:0] wave_CH_buf;
    always@(posedge clock or posedge reset) begin
        if(reset) begin
            wave_CH_buf <= 12'd0;
        end
        else begin
            wave_CH_buf[11] <= user_data[0];
            wave_CH_buf[10] <= user_data[1];
            wave_CH_buf[9]  <= user_data[2];
            wave_CH_buf[8]  <= user_data[3];
            wave_CH_buf[7]  <= user_data[4];
            wave_CH_buf[6]  <= user_data[5];
            wave_CH_buf[5]  <= user_data[6];
            wave_CH_buf[4]  <= user_data[7];
            wave_CH_buf[3]  <= user_data[8];
            wave_CH_buf[2]  <= user_data[9];
            wave_CH_buf[1]  <= user_data[10];
            wave_CH_buf[0]  <= user_data[11];
        end
    end

    assign adc_data = $signed(wave_CH_buf) + $signed(CH_offset);
    assign adc_clk  = clock;

endmodule

