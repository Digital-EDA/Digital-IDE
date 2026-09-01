module ov5640_cfg #(
    parameter MODE = "MIPI"
)
(
    input             sys_clk,
    input             iic_clk,
    input             sys_rst,

    input   [7:0]     iic_data_r,
    input             iic_done,
    input   [12:0]    cmos_h_pixel ,
    input   [12:0]    cmos_v_pixel ,
    input   [12:0]    total_h_pixel,
    input   [12:0]    total_v_pixel,

    output reg        iic_exe,
    output reg [23:0] iic_data,
    output reg        iic_rw_ctrl,
    output reg        init_done
    
);

localparam REG_NUM = (MODE == "MIPI") ? 8'd124 : 8'd250;

reg [12:0] start_init_cnt;
reg [7:0]  init_reg_cnt;

//wait 20ms for camera reset
always @(posedge iic_clk or negedge sys_rst) begin
    if(sys_rst == 1'b0)begin
        start_init_cnt <= 13'd0;
    end
    else if(start_init_cnt < 13'd5000)begin
        start_init_cnt <= start_init_cnt + 1'b1;
    end
end

//iic_exe
always @(posedge sys_clk) begin
    if(sys_rst == 1'b0)begin
        iic_exe <= 1'b0;
    end
    //when camera finish reset,start config registers
    else if(start_init_cnt == 13'd4999)begin
        iic_exe <= 1'b1;
    end
    //when one of registers has been configed,start next 
    else if(iic_done && (init_reg_cnt < REG_NUM))begin
        iic_exe <= 1'b1;
    end
    else begin
        iic_exe <= 1'b0;
    end
end

//init_reg_cnt
always @(posedge sys_clk) begin
    if(sys_rst == 1'b0)begin
        init_reg_cnt <= 8'd0;
    end
    else if(iic_done)begin
        init_reg_cnt <= init_reg_cnt + 1'b1;
    end
end

//iic_rw_ctrl
always @(posedge sys_clk) begin
    if(sys_rst == 1'b0)begin
        iic_rw_ctrl <= 1'b0;
    end
    else if(init_reg_cnt == 8'd2)begin
        iic_rw_ctrl <= 1'b1;
    end
end

//init_done
always @(posedge sys_clk) begin
    if(sys_rst == 1'b0)begin
        init_done <= 1'b0;
    end
    else if(init_reg_cnt == REG_NUM && iic_done)begin
        init_done <= 1'b1;
    end
end

generate if(MODE == "CMOS") begin : CMOS_CAMERA
    
    //iic_data
    always @(posedge sys_clk) begin
        if(sys_rst == 1'b0)begin
            iic_data <= 24'd0;
        end
        else begin
            case(init_reg_cnt)
                8'd0  : iic_data <= {16'h300a,8'h0}; 
                8'd1  : iic_data <= {16'h300b,8'h0}; 
                8'd2  : iic_data <= {16'h3008,8'h82}; 
                8'd3  : iic_data <= {16'h3008,8'h02}; 
                8'd4  : iic_data <= {16'h3103,8'h02}; //Bit[1]:1 PLL Clock
                //FREX/VSYNC/HREF/PCLK/D[9:6]
                8'd5  : iic_data <= {8'h30,8'h17,8'hff};//NO VSYNC HREF
                //D[5:0]/GPIO1/GPIO0 
                8'd6  : iic_data <= {16'h3018,8'hff};//NO DATA
                8'd7  : iic_data <= {16'h3037,8'h13}; 
                8'd8  : iic_data <= {16'h3108,8'h01};
                8'd9  : iic_data <= {16'h3630,8'h36};
                8'd10 : iic_data <= {16'h3631,8'h0e};
                8'd11 : iic_data <= {16'h3632,8'he2};
                8'd12 : iic_data <= {16'h3633,8'h12};
                8'd13 : iic_data <= {16'h3621,8'he0};
                8'd14 : iic_data <= {16'h3704,8'ha0};
                8'd15 : iic_data <= {16'h3703,8'h5a};
                8'd16 : iic_data <= {16'h3715,8'h78};
                8'd17 : iic_data <= {16'h3717,8'h01};
                8'd18 : iic_data <= {16'h370b,8'h60};
                8'd19 : iic_data <= {16'h3705,8'h1a};
                8'd20 : iic_data <= {16'h3905,8'h02};
                8'd21 : iic_data <= {16'h3906,8'h10};
                8'd22 : iic_data <= {16'h3901,8'h0a};
                8'd23 : iic_data <= {16'h3731,8'h12};
                8'd24 : iic_data <= {16'h3600,8'h08}; 
                8'd25 : iic_data <= {16'h3601,8'h33}; 
                8'd26 : iic_data <= {16'h302d,8'h60}; 
                8'd27 : iic_data <= {16'h3620,8'h52};
                8'd28 : iic_data <= {16'h371b,8'h20};
                8'd29 : iic_data <= {16'h471c,8'h50};
                8'd30 : iic_data <= {16'h3a13,8'h43}; //AEC
                8'd31 : iic_data <= {16'h3a18,8'h00}; //AEC 
                8'd32 : iic_data <= {16'h3a19,8'hf8}; //AEC 
                8'd33 : iic_data <= {16'h3635,8'h13};
                8'd34 : iic_data <= {16'h3636,8'h03};
                8'd35 : iic_data <= {16'h3634,8'h40};
                8'd36 : iic_data <= {16'h3622,8'h01};
                8'd37 : iic_data <= {16'h3c01,8'h34};
                8'd38 : iic_data <= {16'h3c04,8'h28};
                8'd39 : iic_data <= {16'h3c05,8'h98};
                8'd40 : iic_data <= {16'h3c06,8'h00}; //light meter 1 
                8'd41 : iic_data <= {16'h3c07,8'h08}; //light meter 1 
                8'd42 : iic_data <= {16'h3c08,8'h00}; //light meter 2 
                8'd43 : iic_data <= {16'h3c09,8'h1c}; //light meter 2 
                8'd44 : iic_data <= {16'h3c0a,8'h9c}; //sample number[15:8]
                8'd45 : iic_data <= {16'h3c0b,8'h40}; //sample number[7:0]
                8'd46 : iic_data <= {16'h3810,8'h00}; //Timing Hoffset[11:8]
                8'd47 : iic_data <= {16'h3811,8'h10}; //Timing Hoffset[7:0]
                8'd48 : iic_data <= {16'h3812,8'h00}; //Timing Voffset[10:8]
                8'd49 : iic_data <= {16'h3708,8'h64};
                8'd50 : iic_data <= {16'h4001,8'h02}; //BLC
                8'd51 : iic_data <= {16'h4005,8'h1a}; //BLC
                8'd52 : iic_data <= {16'h3000,8'h00}; 
                8'd53 : iic_data <= {16'h3004,8'hff}; 
                8'd54 : iic_data <= {16'h4300,8'h61}; //RGB565
                8'd55 : iic_data <= {16'h501f,8'h01}; //ISP RGB
                8'd56 : iic_data <= {16'h440e,8'h00};
                8'd57 : iic_data <= {16'h5000,8'ha7}; //ISP
                8'd58 : iic_data <= {16'h3a0f,8'h30}; //stable range in high
                8'd59 : iic_data <= {16'h3a10,8'h28}; //stable range in low
                8'd60 : iic_data <= {16'h3a1b,8'h30}; //stable range out high
                8'd61 : iic_data <= {16'h3a1e,8'h26}; //stable range out low
                8'd62 : iic_data <= {16'h3a11,8'h60}; //fast zone high
                8'd63 : iic_data <= {16'h3a1f,8'h14}; //fast zone low
                //LENC 16'h5800~16'h583d
                8'd64 : iic_data <= {16'h5800,8'h23}; 
                8'd65 : iic_data <= {16'h5801,8'h14};
                8'd66 : iic_data <= {16'h5802,8'h0f};
                8'd67 : iic_data <= {16'h5803,8'h0f};
                8'd68 : iic_data <= {16'h5804,8'h12};
                8'd69 : iic_data <= {16'h5805,8'h26};
                8'd70 : iic_data <= {16'h5806,8'h0c};
                8'd71 : iic_data <= {16'h5807,8'h08};
                8'd72 : iic_data <= {16'h5808,8'h05};
                8'd73 : iic_data <= {16'h5809,8'h05};
                8'd74 : iic_data <= {16'h580a,8'h08};
                8'd75 : iic_data <= {16'h580b,8'h0d};
                8'd76 : iic_data <= {16'h580c,8'h08};
                8'd77 : iic_data <= {16'h580d,8'h03};
                8'd78 : iic_data <= {16'h580e,8'h00};
                8'd79 : iic_data <= {16'h580f,8'h00};
                8'd80 : iic_data <= {16'h5810,8'h03};
                8'd81 : iic_data <= {16'h5811,8'h09};
                8'd82 : iic_data <= {16'h5812,8'h07};
                8'd83 : iic_data <= {16'h5813,8'h03};
                8'd84 : iic_data <= {16'h5814,8'h00};
                8'd85 : iic_data <= {16'h5815,8'h01};
                8'd86 : iic_data <= {16'h5816,8'h03};
                8'd87 : iic_data <= {16'h5817,8'h08};
                8'd88 : iic_data <= {16'h5818,8'h0d};
                8'd89 : iic_data <= {16'h5819,8'h08};
                8'd90 : iic_data <= {16'h581a,8'h05};
                8'd91 : iic_data <= {16'h581b,8'h06};
                8'd92 : iic_data <= {16'h581c,8'h08};
                8'd93 : iic_data <= {16'h581d,8'h0e};
                8'd94 : iic_data <= {16'h581e,8'h29};
                8'd95 : iic_data <= {16'h581f,8'h17};
                8'd96 : iic_data <= {16'h5820,8'h11};
                8'd97 : iic_data <= {16'h5821,8'h11};
                8'd98 : iic_data <= {16'h5822,8'h15};
                8'd99 : iic_data <= {16'h5823,8'h28};
                8'd100: iic_data <= {16'h5824,8'h46};
                8'd101: iic_data <= {16'h5825,8'h26};
                8'd102: iic_data <= {16'h5826,8'h08};
                8'd103: iic_data <= {16'h5827,8'h26};
                8'd104: iic_data <= {16'h5828,8'h64};
                8'd105: iic_data <= {16'h5829,8'h26};
                8'd106: iic_data <= {16'h582a,8'h24};
                8'd107: iic_data <= {16'h582b,8'h22};
                8'd108: iic_data <= {16'h582c,8'h24};
                8'd109: iic_data <= {16'h582d,8'h24};
                8'd110: iic_data <= {16'h582e,8'h06};
                8'd111: iic_data <= {16'h582f,8'h22};
                8'd112: iic_data <= {16'h5830,8'h40};
                8'd113: iic_data <= {16'h5831,8'h42};
                8'd114: iic_data <= {16'h5832,8'h24};
                8'd115: iic_data <= {16'h5833,8'h26};
                8'd116: iic_data <= {16'h5834,8'h24};
                8'd117: iic_data <= {16'h5835,8'h22};
                8'd118: iic_data <= {16'h5836,8'h22};
                8'd119: iic_data <= {16'h5837,8'h26};
                8'd120: iic_data <= {16'h5838,8'h44};
                8'd121: iic_data <= {16'h5839,8'h24};
                8'd122: iic_data <= {16'h583a,8'h26};
                8'd123: iic_data <= {16'h583b,8'h28};
                8'd124: iic_data <= {16'h583c,8'h42};
                8'd125: iic_data <= {16'h583d,8'hce};
                //AWB 16'h5180~16'h519e
                8'd126: iic_data <= {16'h5180,8'hff};
                8'd127: iic_data <= {16'h5181,8'hf2};
                8'd128: iic_data <= {16'h5182,8'h00};
                8'd129: iic_data <= {16'h5183,8'h14};
                8'd130: iic_data <= {16'h5184,8'h25};
                8'd131: iic_data <= {16'h5185,8'h24};
                8'd132: iic_data <= {16'h5186,8'h09};
                8'd133: iic_data <= {16'h5187,8'h09};
                8'd134: iic_data <= {16'h5188,8'h09};
                8'd135: iic_data <= {16'h5189,8'h75};
                8'd136: iic_data <= {16'h518a,8'h54};
                8'd137: iic_data <= {16'h518b,8'he0};
                8'd138: iic_data <= {16'h518c,8'hb2};
                8'd139: iic_data <= {16'h518d,8'h42};
                8'd140: iic_data <= {16'h518e,8'h3d};
                8'd141: iic_data <= {16'h518f,8'h56};
                8'd142: iic_data <= {16'h5190,8'h46};
                8'd143: iic_data <= {16'h5191,8'hf8};
                8'd144: iic_data <= {16'h5192,8'h04};
                8'd145: iic_data <= {16'h5193,8'h70};
                8'd146: iic_data <= {16'h5194,8'hf0};
                8'd147: iic_data <= {16'h5195,8'hf0};
                8'd148: iic_data <= {16'h5196,8'h03};
                8'd149: iic_data <= {16'h5197,8'h01};
                8'd150: iic_data <= {16'h5198,8'h04};
                8'd151: iic_data <= {16'h5199,8'h12};
                8'd152: iic_data <= {16'h519a,8'h04};
                8'd153: iic_data <= {16'h519b,8'h00};
                8'd154: iic_data <= {16'h519c,8'h06};
                8'd155: iic_data <= {16'h519d,8'h82};
                8'd156: iic_data <= {16'h519e,8'h38};
                //Gamma 16'h5480~16'h5490
                8'd157: iic_data <= {16'h5480,8'h01}; 
                8'd158: iic_data <= {16'h5481,8'h08};
                8'd159: iic_data <= {16'h5482,8'h14};
                8'd160: iic_data <= {16'h5483,8'h28};
                8'd161: iic_data <= {16'h5484,8'h51};
                8'd162: iic_data <= {16'h5485,8'h65};
                8'd163: iic_data <= {16'h5486,8'h71};
                8'd164: iic_data <= {16'h5487,8'h7d};
                8'd165: iic_data <= {16'h5488,8'h87};
                8'd166: iic_data <= {16'h5489,8'h91};
                8'd167: iic_data <= {16'h548a,8'h9a};
                8'd168: iic_data <= {16'h548b,8'haa};
                8'd169: iic_data <= {16'h548c,8'hb8};
                8'd170: iic_data <= {16'h548d,8'hcd};
                8'd171: iic_data <= {16'h548e,8'hdd};
                8'd172: iic_data <= {16'h548f,8'hea};
                8'd173: iic_data <= {16'h5490,8'h1d};
                //16'h5381~16'h538b
                8'd174: iic_data <= {16'h5381,8'h1e};
                8'd175: iic_data <= {16'h5382,8'h5b};
                8'd176: iic_data <= {16'h5383,8'h08};
                8'd177: iic_data <= {16'h5384,8'h0a};
                8'd178: iic_data <= {16'h5385,8'h7e};
                8'd179: iic_data <= {16'h5386,8'h88};
                8'd180: iic_data <= {16'h5387,8'h7c};
                8'd181: iic_data <= {16'h5388,8'h6c};
                8'd182: iic_data <= {16'h5389,8'h10};
                8'd183: iic_data <= {16'h538a,8'h01};
                8'd184: iic_data <= {16'h538b,8'h98};
                //16'h5580~16'h558b
                8'd185: iic_data <= {16'h5580,8'h06};
                8'd186: iic_data <= {16'h5583,8'h40};
                8'd187: iic_data <= {16'h5584,8'h10};
                8'd188: iic_data <= {16'h5589,8'h10};
                8'd189: iic_data <= {16'h558a,8'h00};
                8'd190: iic_data <= {16'h558b,8'hf8};
                8'd191: iic_data <= {16'h501d,8'h40}; //ISP MISC
                //(16'h5300~16'h530c)
                8'd192: iic_data <= {16'h5300,8'h08};
                8'd193: iic_data <= {16'h5301,8'h30};
                8'd194: iic_data <= {16'h5302,8'h10};
                8'd195: iic_data <= {16'h5303,8'h00};
                8'd196: iic_data <= {16'h5304,8'h08};
                8'd197: iic_data <= {16'h5305,8'h30};
                8'd198: iic_data <= {16'h5306,8'h08};
                8'd199: iic_data <= {16'h5307,8'h16};
                8'd200: iic_data <= {16'h5309,8'h08};
                8'd201: iic_data <= {16'h530a,8'h30};
                8'd202: iic_data <= {16'h530b,8'h04};
                8'd203: iic_data <= {16'h530c,8'h06};
                8'd204: iic_data <= {16'h5025,8'h00};
                //input clock =24Mhz, PCLK = 48Mhz
                8'd205: iic_data <= {16'h3035,8'h11}; 
                8'd206: iic_data <= {16'h3036,8'h3c}; 
                8'd207: iic_data <= {16'h3c07,8'h08};

                8'd208: iic_data <= {16'h3820,8'h46};
                8'd209: iic_data <= {16'h3821,8'h01};
                8'd210: iic_data <= {16'h3814,8'h31};
                8'd211: iic_data <= {16'h3815,8'h31};
                8'd212: iic_data <= {16'h3800,8'h00};
                8'd213: iic_data <= {16'h3801,8'h00};
                8'd214: iic_data <= {16'h3802,8'h00};
                8'd215: iic_data <= {16'h3803,8'h04};
                8'd216: iic_data <= {16'h3804,8'h0a};
                8'd217: iic_data <= {16'h3805,8'h3f};
                8'd218: iic_data <= {16'h3806,8'h07};
                8'd219: iic_data <= {16'h3807,8'h9b};
            
                8'd220: iic_data <= {16'h3808,{4'd0,cmos_h_pixel[11:8]}};
            
                8'd221: iic_data <= {16'h3809,cmos_h_pixel[7:0]};
            
                8'd222: iic_data <= {16'h380a,{5'd0,cmos_v_pixel[10:8]}};
            
                8'd223: iic_data <= {16'h380b,cmos_v_pixel[7:0]};
            
                8'd224: iic_data <= {16'h380c,{3'd0,total_h_pixel[12:8]}};
            
                8'd225: iic_data <= {16'h380d,total_h_pixel[7:0]};
            
                8'd226: iic_data <= {16'h380e,{3'd0,total_v_pixel[12:8]}};
               
                8'd227: iic_data <= {16'h380f,total_v_pixel[7:0]};
                8'd228: iic_data <= {16'h3813,8'h06};
                8'd229: iic_data <= {16'h3618,8'h00};
                8'd230: iic_data <= {16'h3612,8'h29};
                8'd231: iic_data <= {16'h3709,8'h52};
                8'd232: iic_data <= {16'h370c,8'h03};
                8'd233: iic_data <= {16'h3a02,8'h17}; //60Hz max exposure
                8'd234: iic_data <= {16'h3a03,8'h10}; //60Hz max exposure
                8'd235: iic_data <= {16'h3a14,8'h17}; //50Hz max exposure
                8'd236: iic_data <= {16'h3a15,8'h10}; //50Hz max exposure
                8'd237: iic_data <= {16'h4004,8'h02}; 
                8'd238: iic_data <= {16'h4713,8'h03}; //JPEG mode 3
                8'd239: iic_data <= {16'h4407,8'h04}; 
                8'd240: iic_data <= {16'h460c,8'h22};     
                8'd241: iic_data <= {16'h4837,8'h22}; //DVP CLK divider
                8'd242: iic_data <= {16'h3824,8'h02}; //DVP CLK divider
                8'd243: iic_data <= {16'h5001,8'ha3}; 
                8'd244: iic_data <= {16'h3b07,8'h0a}; 

                8'd245: iic_data <= {16'h503d,8'h00};

                8'd246: iic_data <= {16'h3016,8'h02};
                8'd247: iic_data <= {16'h301c,8'h02};
                8'd248: iic_data <= {16'h3019,8'h02};
                8'd249: iic_data <= {16'h3019,8'h00};

                default : iic_data <= {16'h300a,8'h00};
            endcase
        end
    end

end
endgenerate

generate if(MODE == "MIPI") begin : MIPI_CAMERA
    
    //iic_data
    always @(posedge sys_clk) begin
        if(sys_rst == 1'b0)begin
            iic_data <= 24'd0;
        end
        else begin
            case(init_reg_cnt)
                8'd0  : iic_data <= {16'h300a,8'h0}; 
                8'd1  : iic_data <= {16'h300b,8'h0};
                //write 
                8'd2  : iic_data <= {16'h3103, 8'h11};
                8'd3  : iic_data <= {16'h3008, 8'h82};
                8'd4  : iic_data <= {16'h3008, 8'h42};
                8'd5  : iic_data <= {16'h3103, 8'h03};
                8'd6  : iic_data <= {16'h3017, 8'h00};
                8'd7  : iic_data <= {16'h3018, 8'h00};
                8'd8  : iic_data <= {16'h3034, 8'h18};
                8'd9  : iic_data <= {16'h3035, 8'h11};
                8'd10 : iic_data <= {16'h3036, 8'h38};
                8'd11 : iic_data <= {16'h3037, 8'h11};
                8'd12 : iic_data <= {16'h3108, 8'h01};
                8'd13 : iic_data <= {16'h303D, 8'h10};
                8'd14 : iic_data <= {16'h303B, 8'h19};
                8'd15 : iic_data <= {16'h3630, 8'h2e};
                8'd16 : iic_data <= {16'h3631, 8'h0e};
                8'd17 : iic_data <= {16'h3632, 8'he2};
                8'd18 : iic_data <= {16'h3633, 8'h23};
                8'd19 : iic_data <= {16'h3621, 8'he0};
                8'd20 : iic_data <= {16'h3704, 8'ha0};
                8'd21 : iic_data <= {16'h3703, 8'h5a};
                8'd22 : iic_data <= {16'h3715, 8'h78};
                8'd23 : iic_data <= {16'h3717, 8'h01};
                8'd24 : iic_data <= {16'h370b, 8'h60};
                8'd25 : iic_data <= {16'h3705, 8'h1a};
                8'd26 : iic_data <= {16'h3905, 8'h02};
                8'd27 : iic_data <= {16'h3906, 8'h10};
                8'd28 : iic_data <= {16'h3901, 8'h0a};
                8'd29 : iic_data <= {16'h3731, 8'h02};
                8'd30 : iic_data <= {16'h3600, 8'h37};
                8'd31 : iic_data <= {16'h3601, 8'h33};
                8'd32 : iic_data <= {16'h302d, 8'h60};
                8'd33 : iic_data <= {16'h3620, 8'h52};
                8'd34 : iic_data <= {16'h371b, 8'h20};
                8'd35 : iic_data <= {16'h471c, 8'h50};
                8'd36 : iic_data <= {16'h3a13, 8'h43};
                8'd37 : iic_data <= {16'h3a18, 8'h00};
                8'd38 : iic_data <= {16'h3a19, 8'hf8};
                8'd39 : iic_data <= {16'h3635, 8'h13};
                8'd40 : iic_data <= {16'h3636, 8'h06};
                8'd41 : iic_data <= {16'h3634, 8'h44};
                8'd42 : iic_data <= {16'h3622, 8'h01};
                8'd43 : iic_data <= {16'h3c01, 8'h34};
                8'd44 : iic_data <= {16'h3c04, 8'h28};
                8'd45 : iic_data <= {16'h3c05, 8'h98};
                8'd46 : iic_data <= {16'h3c06, 8'h00};
                8'd47 : iic_data <= {16'h3c07, 8'h08};
                8'd48 : iic_data <= {16'h3c08, 8'h00};
                8'd49 : iic_data <= {16'h3c09, 8'h1c};
                8'd50 : iic_data <= {16'h3c0a, 8'h9c};
                8'd51 : iic_data <= {16'h3c0b, 8'h40};
                8'd52 : iic_data <= {16'h503d, 8'h00};
                8'd53 : iic_data <= {16'h3820, 8'h46};
                8'd54 : iic_data <= {16'h300e, 8'h45};
                8'd55 : iic_data <= {16'h4800, 8'h14};
                8'd56 : iic_data <= {16'h302e, 8'h08};
                8'd57 : iic_data <= {16'h4300, 8'h6f};
                8'd58 : iic_data <= {16'h501f, 8'h01};
                8'd59 : iic_data <= {16'h4713, 8'h03};
                8'd60 : iic_data <= {16'h4407, 8'h04};
                8'd61 : iic_data <= {16'h440e, 8'h00};
                8'd62 : iic_data <= {16'h460b, 8'h35};
                8'd63 : iic_data <= {16'h460c, 8'h20};
                8'd64 : iic_data <= {16'h3824, 8'h01};
                8'd65 : iic_data <= {16'h5000, 8'h07};
                8'd66 : iic_data <= {16'h5001, 8'h03};
                8'd67 : iic_data <= {16'h3008, 8'h42};
                8'd68 : iic_data <= {16'h3035, 8'h21};
                8'd69 : iic_data <= {16'h3036, 8'h46};
                8'd70 : iic_data <= {16'h3037, 8'h05};
                8'd71 : iic_data <= {16'h3108, 8'h11};
                8'd72 : iic_data <= {16'h3034, 8'h1A};
                8'd73 : iic_data <= {16'h3800, 8'h01};
                8'd74 : iic_data <= {16'h3801, 8'h50};
                8'd75 : iic_data <= {16'h3802, 8'h01};
                8'd76 : iic_data <= {16'h3803, 8'hAA};
                8'd77 : iic_data <= {16'h3804, 8'h08};
                8'd78 : iic_data <= {16'h3805, 8'hEF};
                8'd79 : iic_data <= {16'h3806, 8'h05};
                8'd80 : iic_data <= {16'h3807, 8'hF9};
                8'd81 : iic_data <= {16'h3810, 8'h00};
                8'd82 : iic_data <= {16'h3811, 8'h10};
                8'd83 : iic_data <= {16'h3812, 8'h00};
                8'd84 : iic_data <= {16'h3813, 8'h0C};
                8'd85 : iic_data <= {16'h3808, 8'h07};
                8'd86 : iic_data <= {16'h3809, 8'h80};
                8'd87 : iic_data <= {16'h380a, 8'h04};
                8'd88 : iic_data <= {16'h380b, 8'h38};
                8'd89 : iic_data <= {16'h380c, 8'h09};
                8'd90 : iic_data <= {16'h380d, 8'hC4};
                8'd91 : iic_data <= {16'h380e, 8'h04};
                8'd92 : iic_data <= {16'h380f, 8'h60};
                8'd93 : iic_data <= {16'h3814, 8'h11};
                8'd94 : iic_data <= {16'h3815, 8'h11};
                8'd95 : iic_data <= {16'h3821, 8'h00};
                8'd96 : iic_data <= {16'h4837, 8'h24};
                8'd97 : iic_data <= {16'h3618, 8'h00};
                8'd98 : iic_data <= {16'h3612, 8'h59};
                8'd99 : iic_data <= {16'h3708, 8'h64};
                8'd100: iic_data <= {16'h3709, 8'h52};
                8'd101: iic_data <= {16'h370c, 8'h03};
                8'd102: iic_data <= {16'h4300, 8'h00};
                8'd103: iic_data <= {16'h501f, 8'h03};
                8'd104: iic_data <= {16'h3406, 8'h00};
                8'd105: iic_data <= {16'h5192, 8'h04};
                8'd106: iic_data <= {16'h5191, 8'hf8};
                8'd107: iic_data <= {16'h518d, 8'h26};
                8'd108: iic_data <= {16'h518f, 8'h42};
                8'd109: iic_data <= {16'h518e, 8'h2b};
                8'd110: iic_data <= {16'h5190, 8'h42};
                8'd111: iic_data <= {16'h518b, 8'hd0};
                8'd112: iic_data <= {16'h518c, 8'hbd};
                8'd113: iic_data <= {16'h5187, 8'h18};
                8'd114: iic_data <= {16'h5188, 8'h18};
                8'd115: iic_data <= {16'h5189, 8'h56};
                8'd116: iic_data <= {16'h518a, 8'h5c};
                8'd117: iic_data <= {16'h5186, 8'h1c};
                8'd118: iic_data <= {16'h5181, 8'h50};
                8'd119: iic_data <= {16'h5184, 8'h20};
                8'd120: iic_data <= {16'h5182, 8'h11};
                8'd121: iic_data <= {16'h5183, 8'h00};
                8'd122: iic_data <= {16'h5001, 8'h03};
                8'd123: iic_data <= {16'h3008, 8'h02};
            
                default : iic_data <= {16'h300a,8'h00};
            endcase
        end
    end

end
endgenerate

endmodule //ov5640_cfg
