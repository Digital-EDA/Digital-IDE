module AD6645 (
        input 		   clock,
        input 		   reset,
        input  [13:0]  dc_value,
        input  [13:0]  ad_data,
        output [13:0]  wave_ch
    );

    reg [13:0] wave_CH_buf;

    always@(posedge clock or posedge reset) begin
        if(reset) begin
            wave_CH_buf <= 14'd0;
        end
        else begin
            wave_CH_buf <= ad_data;
        end
    end
    
    assign wave_ch = wave_CH_buf - dc_value;

endmodule 