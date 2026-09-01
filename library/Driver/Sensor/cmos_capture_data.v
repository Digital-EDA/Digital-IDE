module cmos_capture_data (
    input          rst_n,
    //camera_in
    input          cam_pclk,
    input          cam_vsync,
    input          cam_href,
    input   [7:0]  cam_data,
    //camera_out
    output         cmos_frame_vsync,
    output         cmos_frame_href,
    output         cmos_frame_valid,
    output  [15:0] cmos_frame_data
);

localparam WAIT_CNT = 4'd10;

reg        cam_vsync_d0;
reg        cam_href_d0;
reg [7:0]  cam_data_d0;

reg        cam_vsync_d1;
reg        cam_href_d1;

reg [3:0]  cam_vsync_cnt; //the number of a frame of data

wire       cam_vsync_pos; //the end of a frame of data

reg        frame_val; //register configuration has taken effect

reg        byte_flag; //1'b1 : 16bit data   1'b0 : wait
reg        byte_flag_d0;

reg [15:0] cmos_data;

//buffer
assign    cam_vsync_pos = (~cam_vsync_d1) & cam_vsync_d0;

always @(posedge cam_pclk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        cam_vsync_d0 <= 1'b0;
        cam_vsync_d1 <= 1'b0;
        cam_href_d0  <= 1'b0;
        cam_href_d1  <= 1'b0;
    end
    else begin
        cam_vsync_d0 <= cam_vsync;
        cam_vsync_d1 <= cam_vsync_d0;
        cam_href_d0  <= cam_href;
        cam_href_d1  <= cam_href_d0;
    end
end

//Collect images after waiting for register configuration to take effect
always @(posedge cam_pclk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        cam_vsync_cnt <= 4'd0;
    end
    else if(cam_vsync_pos && (cam_vsync_cnt < WAIT_CNT))begin
        cam_vsync_cnt <= cam_vsync_cnt + 1'b1;
    end
    else begin
        cam_vsync_cnt <= cam_vsync_cnt;
    end
end

//frame_val
always @(posedge cam_pclk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        frame_val <= 1'b0;
    end
    else if((cam_vsync_cnt == WAIT_CNT) && cam_vsync_pos)begin
        frame_val <= 1'b1;
    end
    else begin
        frame_val <= frame_val;
    end
end

//cmos_frame_vsync
assign cmos_frame_vsync = frame_val ? cam_vsync_d1 : 1'b0;

//cmos_frame_href
assign cmos_frame_href  = frame_val ? cam_href_d1  : 1'b0;

//cmos_frame_valid
assign cmos_frame_valid = frame_val ? byte_flag_d0 : 1'b0;

//cmos_frame_data
assign cmos_frame_data  = frame_val ? cmos_data    : 16'd0;

//Data concatenation
always @(posedge cam_pclk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        byte_flag <= 1'b0;
        cmos_data <= 16'd0;
    end
    else if(cam_href)begin
        byte_flag   <= ~byte_flag;
        cam_data_d0 <= cam_data;
        if(byte_flag)begin
            cmos_data <= {cam_data_d0,cam_data};
        end
    end
    else begin
        byte_flag <= 1'b0;
        cmos_data <= 16'd0;
    end
end

//byte_flag_d0
always @(posedge cam_pclk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        byte_flag_d0 <= 1'b0;
    end
    else begin
        byte_flag_d0 <= byte_flag;
    end
end

endmodule //cmos_capture_data
