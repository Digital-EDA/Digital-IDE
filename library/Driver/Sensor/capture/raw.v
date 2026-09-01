`timescale 1ns/1ns
module capturer_raw #(
    //Wait n fps for steady(OmniVision need 10 Frame)
    parameter CMOS_FRAME_WAITCNT = 4'd10 
) (
    //global clock
    input				sys_rstn,				//global reset

    //CMOS Sensor Interface
    input				cmos_pclk,			//24MHz CMOS Pixel clock input
    input				cmos_vsync,			//H : Data Valid; L : Frame Sync(Set it by register)
    input				cmos_href,			//H : Data vaild, L : Line Sync
    input		[7:0]	cmos_data,			//8 bits cmos data input

    //CMOS SYNC Data output
    output				cmos_frame_vsync,	//cmos frame data vsync valid signal
    output				cmos_frame_href,	//cmos frame data href vaild  signal
    output		[7:0]	cmos_frame_data,	//cmos frame RAW output

    //user interface
    output	reg	[7:0]	cmos_fps_rate		//cmos frame output rate
);

//-----------------------------------------------------
//Sensor HS & VS Vaild Capture
/**************************************************
         _________________________________
VS______|                                 |________
                _______	 	     _______
HS_____________|       |__...___|       |____________
**************************************************/
//-------------------------------------------------------------
//sync the frame vsync and href signal and generate frame begin & end signal
reg	[1:0]	cmos_vsync_r, cmos_href_r;
reg	[7:0]	cmos_data_r0, cmos_data_r1;
always@(posedge cmos_pclk or negedge sys_rstn) begin
    if(!sys_rstn) begin
        cmos_vsync_r <= 0;
        cmos_href_r <= 0;
        {cmos_data_r1, cmos_data_r0} <= 0;
    end
    else begin
        cmos_vsync_r <= {cmos_vsync_r[0], cmos_vsync};
        cmos_href_r <= {cmos_href_r[0], cmos_href};
        {cmos_data_r1, cmos_data_r0} <= {cmos_data_r0, cmos_data};
    end
end
//wire	cmos_vsync_begin 	= 	(~cmos_vsync_r[1] & cmos_vsync_r[0]) ? 1'b1 : 1'b0;
wire	cmos_vsync_end 		= 	(cmos_vsync_r[1] & ~cmos_vsync_r[0]) ? 1'b1 : 1'b0;

//----------------------------------------------------------------------------------
//Wait for Sensor output Data valid 10 Frame of OmniVision
reg	[3:0]	cmos_fps_cnt;
always@(posedge cmos_pclk or negedge sys_rstn) begin
    if(!sys_rstn)
        cmos_fps_cnt <= 0;
    else begin	//Wait until cmos init complete
        if(cmos_fps_cnt < CMOS_FRAME_WAITCNT)
            cmos_fps_cnt <= cmos_vsync_end ? cmos_fps_cnt + 1'b1 : cmos_fps_cnt;
        else
            cmos_fps_cnt <= CMOS_FRAME_WAITCNT;
    end
end

//----------------------------------------------------------------------------------
//Come ture frame synchronization to ignore error frame or has not capture when vsync begin
reg		frame_sync_flag;
always@(posedge cmos_pclk or negedge sys_rstn) begin
    if(!sys_rstn)
        frame_sync_flag <= 0;
    else if(cmos_fps_cnt == CMOS_FRAME_WAITCNT && cmos_vsync_end == 1)
        frame_sync_flag <= 1;
    else
        frame_sync_flag <= frame_sync_flag;
end


assign	cmos_frame_vsync = frame_sync_flag ? cmos_vsync_r[1] : 1'b0;//DFF 2 clocks
assign	cmos_frame_href  = frame_sync_flag ? cmos_href_r[1] : 1'b0;	//DFF 2 clocks
assign	cmos_frame_data	 = frame_sync_flag ? cmos_data_r1 : 8'd0;	//DFF 2 clocks

//----------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------
//Delay 2s for cmos fps counter
localparam	DELAY_TOP = 2 * 24_000000;	//2s delay
reg	[27:0]	delay_cnt;
always@(posedge cmos_pclk or negedge sys_rstn) begin
    if(!sys_rstn)
        delay_cnt <= 0;
    else if(delay_cnt < DELAY_TOP - 1'b1)
        delay_cnt <= delay_cnt + 1'b1;
    else
        delay_cnt <= 0;
end
wire delay_2s = (delay_cnt == DELAY_TOP - 1'b1) ? 1'b1 : 1'b0;

//-------------------------------------
//cmos image output rate counter
reg	[8:0]	cmos_fps_cnt2;
always@(posedge cmos_pclk or negedge sys_rstn) begin
    if(!sys_rstn) begin
        cmos_fps_cnt2 <= 0;
        cmos_fps_rate <= 0;
    end
    else if(delay_2s == 1'b0) begin	//time is not reached
        cmos_fps_cnt2 <= cmos_vsync_end ? cmos_fps_cnt2 + 1'b1 : cmos_fps_cnt2;
        cmos_fps_rate <= cmos_fps_rate;
    end
    else begin	//time up
        cmos_fps_cnt2 <= 0;
        cmos_fps_rate <= cmos_fps_cnt2[8:1];	//divide by 2
    end
end

endmodule
