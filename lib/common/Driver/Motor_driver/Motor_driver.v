/********************************************
wire             Motor_Control;
Motor_driver Motor_driver_u(
    .clk_in(clk_50m),
    .rst_n(1'd1),
    .Trig(Trig),
    .Meter(16'd4),

    .Motor_Control(Motor_Control)
);
********************************************/
module Motor_driver (
    input         clk_in,
    input         rst_n,
    input         Trig,
    input  [15:0] Meter,

    output  reg   Motor_Control
);

parameter MAIN_FRE  = 50000000;
parameter MOTOR_FRE = 1000;
parameter SET_TIME  = MAIN_FRE/MOTOR_FRE/2;

/***************************************************/
//define the data lock
reg  Trig_SIG = 0;
reg  Trig_SIG_buf = 0;
wire Trig_SIG_pose =  Trig_SIG & ~Trig_SIG_buf;
wire Trig_SIG_nege =  ~Trig_SIG & Trig_SIG_buf;

always@(posedge clk_in) begin
    Trig_SIG <= Trig;
    Trig_SIG_buf <= Trig_SIG;
end
/***************************************************/

/***************************************************/
//define the time counter
reg [15:0]      cnt0 = 0;
reg             Motor_Control_r = 0;

always@(posedge clk_in) begin
    if (cnt0 == SET_TIME) begin
        cnt0 <= 15'd0;                   
        Motor_Control_r <= ~Motor_Control_r;
    end
    else
        cnt0 <= cnt0 + 1'd1;          
end
/***************************************************/

/***************************************************/
//define the data lock
reg  motor_sig = 0;
reg  motor_sig_buf = 0;
wire motor_sig_pose =  motor_sig & ~motor_sig_buf;
wire motor_sig_nege =  ~motor_sig & motor_sig_buf;
always@(posedge clk_in) begin
    motor_sig <= Motor_Control_r;
    motor_sig_buf <= motor_sig;
end
/***************************************************/

/***************************************************/
//define the time counter
reg [15:0]      cnt1 = 0;
reg             CNT_CE = 0;
always@(posedge clk_in) begin
	if (Trig_SIG_pose) begin
		CNT_CE <= 1'd1;
	end
	else if(cnt1 == Meter) begin
		if (motor_sig_nege) begin
			CNT_CE <= 1'd0;
		end
		else begin
			CNT_CE <= CNT_CE;
		end
	end
	else begin
		CNT_CE <= CNT_CE;
	end
end
/***************************************************/
reg             MOTOR_CE = 0;
always @(posedge clk_in) begin
	if (CNT_CE) begin
		if (motor_sig_pose) begin
	    	cnt1 <= cnt1 + 1'd1;            //cnt1 counter = cnt1 counter + 1
	        MOTOR_CE <= 1'd1;
		end
		else begin
			MOTOR_CE <= MOTOR_CE;
		end
	end
	else begin
		cnt1 <= 16'd0; 
		MOTOR_CE <= 1'd0;
	end
end

always @(*) begin
	case (MOTOR_CE) 
	    1'b0    :   begin Motor_Control <= 1'b0; end
	    1'b1    :   begin Motor_Control <= Motor_Control_r; end
	    default :   begin Motor_Control <= 1'b0; end
	endcase
end


endmodule