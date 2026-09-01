module AGC #(
        parameter KWIDTH = 8,
        parameter DWIDTH = 16
    )(
        input  wire 			        clock,
        input  wire 			        reset,

        input  wire        [KWIDTH-1:0] k_coef,
        input  wire        [DWIDTH-1:0] reference,

        input  wire signed [DWIDTH-1:0] x_in,
        output wire signed [DWIDTH-1:0] y_out
    );
        
    reg  signed [(DWIDTH*2)-1:0] gain;	

    wire        [(DWIDTH*2)-1:0] x_mod;		
    wire        [(DWIDTH*2)-1:0] ref_rms;	
    wire signed [(DWIDTH*2)-1:0] tmp_level;
    wire signed [(DWIDTH*2)-1:0] feedback;
    wire signed [KWIDTH:0]       a_coef_s;	

    assign r_rms     = (reference * reference);
    assign x_mod     = (y_out * y_out);
    
    assign a_coef_s  = { 1'b0, k_coef };
            
    assign tmp_level = $signed(r_rms - x_mod) >>> 1;
    assign feedback  = (tmp_level * a_coef_s) >>> (KWIDTH + 1);

    always @(posedge clock or negedge reset) begin	
        if (!reset) begin
            gain <= 0;
        end
        else begin
            gain <= gain + feedback;
        end
    end

    assign y_out = (gain * x_in) >>> DWIDTH;

endmodule
