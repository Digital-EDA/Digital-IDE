
module Motor #(
    parameter MAIN_FRE  = 50000000,
    parameter MOTOR_FRE = 1000
) (
    input         clock,
    input         reset,
    input         Trig,
    input  [15:0] Meter,

    output  reg   Motor_Control
);


localparam SET_TIME = MAIN_FRE/MOTOR_FRE/2;

/***************************************************/
//define the data lock
reg  trig_SIG;
reg  trig_SIG_buf;
wire trig_SIG_pose =  trig_SIG & ~trig_SIG_buf;
wire trig_SIG_nege = ~trig_SIG &  trig_SIG_buf;

always@(posedge clock or posedge reset) begin
    if (reset) begin
        trig_SIG <= 0;
        trig_SIG_buf <= 0;
    end
    else begin        
        trig_SIG <= Trig;
        trig_SIG_buf <= trig_SIG;
    end
end
/***************************************************/

/***************************************************/
//define the time counter
reg [15:0]      cnt0;
reg             Motor_Control_r;

always@(posedge clock or posedge reset) begin
    if (reset) begin
        cnt0 <= 0;
        Motor_Control_r <= 0;
    end
    else begin        
        if (cnt0 == SET_TIME) begin
            cnt0 <= 15'd0;                   
            Motor_Control_r <= ~Motor_Control_r;
        end
        else begin
            cnt0 <= cnt0 + 1'd1;          
        end
    end
end
/***************************************************/

/***************************************************/
//define the data lock
reg  motor_sig;
reg  motor_sig_buf;
wire motor_sig_pose =  motor_sig & ~motor_sig_buf;
wire motor_sig_nege = ~motor_sig & motor_sig_buf;
always@(posedge clock or posedge reset) begin
    if (reset) begin
        motor_sig <= 0;
        motor_sig_buf <= 0;
    end
    else begin        
        motor_sig <= Motor_Control_r;
        motor_sig_buf <= motor_sig;
    end
end
/***************************************************/

/***************************************************/
//define the time counter
reg [15:0]      cnt1;
reg             cnt_ce;
always@(posedge clock or posedge reset) begin
    if (reset) begin
        cnt1 <= 0;
        cnt_ce <= 0;
    end
    else begin        
        if (trig_SIG_pose) begin
            cnt_ce <= 1'd1;
        end
        else if(cnt1 == Meter) begin
            if (motor_sig_nege) begin
                cnt_ce <= 1'd0;
            end
            else begin
                cnt_ce <= cnt_ce;
            end
        end
        else begin
            cnt_ce <= cnt_ce;
        end
    end
end
/***************************************************/
reg             motor_ce;
always@(posedge clock or posedge reset) begin
    if (reset) begin
        motor_ce <= 0;
    end
    else begin        
        if (cnt_ce) begin
            if (motor_sig_pose) begin
                cnt1 <= cnt1 + 1'd1;          
                motor_ce <= 1'd1;
            end
            else begin
                motor_ce <= motor_ce;
            end
        end
        else begin
            cnt1 <= 16'd0; 
            motor_ce <= 1'd0;
        end
    end
end

always @(*) begin
	case (motor_ce) 
	    1'b0    : begin Motor_Control <= 1'b0; end
	    1'b1    : begin Motor_Control <= Motor_Control_r; end
	    default : begin Motor_Control <= 1'b0; end
	endcase
end


endmodule