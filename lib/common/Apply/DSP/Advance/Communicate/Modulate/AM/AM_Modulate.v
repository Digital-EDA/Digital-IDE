`timescale 1ns / 1ps

module AM_Modulate #(
    parameter INPUT_WIDTH  = 12,
    parameter PHASE_WIDTH  = 32,
	parameter DEEP_WIDTH   = 16,
    parameter OUTPUT_WIDTH = 12
) (
    input                         clk,
    input                         RST,
    input  [INPUT_WIDTH  - 1 : 0] wave_in,
    input  [PHASE_WIDTH  - 1 : 0] center_fre,   //(fre*2^PHASE_WIDTH)/Fc
    input  [DEEP_WIDTH   - 1 : 0] modulate_deep,//(2^DEEP_WIDTH-1)*percent   
    output [OUTPUT_WIDTH - 1 : 0] AM_wave
);

localparam [INPUT_WIDTH - 1 : 0] DC_Value = 2**(INPUT_WIDTH-1);

reg        [INPUT_WIDTH  - 1 : 0] wave_in_r = 0;
always @(posedge clk) begin
    if (RST) begin
        wave_in_r <= 0;
    end
    else begin
        wave_in_r <= wave_in;
    end
end

reg signed [INPUT_WIDTH + DEEP_WIDTH : 0] data_r0 = 0;
always @(posedge clk) begin
    if (RST) begin
        data_r0 <= 0;
    end
    else begin
        data_r0 <= $signed(wave_in_r) * $signed({1'b0,modulate_deep});
    end
end

reg signed [INPUT_WIDTH  - 1 : 0] data_r1 = 0;
always @(posedge clk) begin
    if (RST) begin
        data_r1 <= 0;
    end
    else begin
        data_r1 <= data_r0[INPUT_WIDTH + DEEP_WIDTH - 1 : DEEP_WIDTH];
    end
end

reg        [INPUT_WIDTH : 0] data_r2 = 0;
always @(posedge clk) begin
    if (RST) begin
        data_r2 <= 0;
    end
    else begin
        data_r2 <= $signed(data_r1) + $signed({1'b0,DC_Value});
    end
end

reg [PHASE_WIDTH - 1 : 0] addr_r0 = 0;
always @(posedge clk) begin
    addr_r0 <= addr_r0 + center_fre;
end

reg [9:0] addr_r1 = 0;
always @(posedge clk) begin
    addr_r1 <= addr_r0[PHASE_WIDTH - 1 : PHASE_WIDTH - 10];
end

reg  [7:0] addr = 0; 
always @(*) begin
    case (addr_r1[9:8]) 
        2'b00    :   begin addr <= addr_r1[7:0]; end
        2'b01    :   begin addr <= addr_r1[7:0] ^ 8'b1111_1111; end
        2'b10    :   begin addr <= addr_r1[7:0]; end
        2'b11    :   begin addr <= addr_r1[7:0] ^ 8'b1111_1111; end
        default  :   begin addr <= 8'd0; end
    endcase
end

reg signed [13:0] wave_out_r = 0;
always @(*) begin
    case (addr)
        8'd0 : begin wave_out_r <= 0; end
        8'd1 : begin wave_out_r <= 50; end
        8'd2 : begin wave_out_r <= 101; end
        8'd3 : begin wave_out_r <= 151; end
        8'd4 : begin wave_out_r <= 201; end
        8'd5 : begin wave_out_r <= 252; end
        8'd6 : begin wave_out_r <= 302; end
        8'd7 : begin wave_out_r <= 352; end
        8'd8 : begin wave_out_r <= 402; end
        8'd9 : begin wave_out_r <= 453; end
        8'd10 : begin wave_out_r <= 503; end
        8'd11 : begin wave_out_r <= 553; end
        8'd12 : begin wave_out_r <= 603; end
        8'd13 : begin wave_out_r <= 653; end
        8'd14 : begin wave_out_r <= 703; end
        8'd15 : begin wave_out_r <= 754; end
        8'd16 : begin wave_out_r <= 804; end
        8'd17 : begin wave_out_r <= 854; end
        8'd18 : begin wave_out_r <= 904; end
        8'd19 : begin wave_out_r <= 954; end
        8'd20 : begin wave_out_r <= 1004; end
        8'd21 : begin wave_out_r <= 1054; end
        8'd22 : begin wave_out_r <= 1103; end
        8'd23 : begin wave_out_r <= 1153; end
        8'd24 : begin wave_out_r <= 1203; end
        8'd25 : begin wave_out_r <= 1253; end
        8'd26 : begin wave_out_r <= 1302; end
        8'd27 : begin wave_out_r <= 1352; end
        8'd28 : begin wave_out_r <= 1402; end
        8'd29 : begin wave_out_r <= 1451; end
        8'd30 : begin wave_out_r <= 1501; end
        8'd31 : begin wave_out_r <= 1550; end
        8'd32 : begin wave_out_r <= 1600; end
        8'd33 : begin wave_out_r <= 1649; end
        8'd34 : begin wave_out_r <= 1698; end
        8'd35 : begin wave_out_r <= 1747; end
        8'd36 : begin wave_out_r <= 1796; end
        8'd37 : begin wave_out_r <= 1845; end
        8'd38 : begin wave_out_r <= 1894; end
        8'd39 : begin wave_out_r <= 1943; end
        8'd40 : begin wave_out_r <= 1992; end
        8'd41 : begin wave_out_r <= 2041; end
        8'd42 : begin wave_out_r <= 2090; end
        8'd43 : begin wave_out_r <= 2138; end
        8'd44 : begin wave_out_r <= 2187; end
        8'd45 : begin wave_out_r <= 2235; end
        8'd46 : begin wave_out_r <= 2284; end
        8'd47 : begin wave_out_r <= 2332; end
        8'd48 : begin wave_out_r <= 2380; end
        8'd49 : begin wave_out_r <= 2428; end
        8'd50 : begin wave_out_r <= 2476; end
        8'd51 : begin wave_out_r <= 2524; end
        8'd52 : begin wave_out_r <= 2572; end
        8'd53 : begin wave_out_r <= 2620; end
        8'd54 : begin wave_out_r <= 2667; end
        8'd55 : begin wave_out_r <= 2715; end
        8'd56 : begin wave_out_r <= 2762; end
        8'd57 : begin wave_out_r <= 2809; end
        8'd58 : begin wave_out_r <= 2857; end
        8'd59 : begin wave_out_r <= 2904; end
        8'd60 : begin wave_out_r <= 2951; end
        8'd61 : begin wave_out_r <= 2998; end
        8'd62 : begin wave_out_r <= 3044; end
        8'd63 : begin wave_out_r <= 3091; end
        8'd64 : begin wave_out_r <= 3137; end
        8'd65 : begin wave_out_r <= 3184; end
        8'd66 : begin wave_out_r <= 3230; end
        8'd67 : begin wave_out_r <= 3276; end
        8'd68 : begin wave_out_r <= 3322; end
        8'd69 : begin wave_out_r <= 3368; end
        8'd70 : begin wave_out_r <= 3414; end
        8'd71 : begin wave_out_r <= 3460; end
        8'd72 : begin wave_out_r <= 3505; end
        8'd73 : begin wave_out_r <= 3551; end
        8'd74 : begin wave_out_r <= 3596; end
        8'd75 : begin wave_out_r <= 3641; end
        8'd76 : begin wave_out_r <= 3686; end
        8'd77 : begin wave_out_r <= 3731; end
        8'd78 : begin wave_out_r <= 3776; end
        8'd79 : begin wave_out_r <= 3820; end
        8'd80 : begin wave_out_r <= 3865; end
        8'd81 : begin wave_out_r <= 3909; end
        8'd82 : begin wave_out_r <= 3953; end
        8'd83 : begin wave_out_r <= 3997; end
        8'd84 : begin wave_out_r <= 4041; end
        8'd85 : begin wave_out_r <= 4085; end
        8'd86 : begin wave_out_r <= 4128; end
        8'd87 : begin wave_out_r <= 4172; end
        8'd88 : begin wave_out_r <= 4215; end
        8'd89 : begin wave_out_r <= 4258; end
        8'd90 : begin wave_out_r <= 4301; end
        8'd91 : begin wave_out_r <= 4343; end
        8'd92 : begin wave_out_r <= 4386; end
        8'd93 : begin wave_out_r <= 4428; end
        8'd94 : begin wave_out_r <= 4471; end
        8'd95 : begin wave_out_r <= 4513; end
        8'd96 : begin wave_out_r <= 4555; end
        8'd97 : begin wave_out_r <= 4596; end
        8'd98 : begin wave_out_r <= 4638; end
        8'd99 : begin wave_out_r <= 4679; end
        8'd100 : begin wave_out_r <= 4720; end
        8'd101 : begin wave_out_r <= 4761; end
        8'd102 : begin wave_out_r <= 4802; end
        8'd103 : begin wave_out_r <= 4843; end
        8'd104 : begin wave_out_r <= 4883; end
        8'd105 : begin wave_out_r <= 4924; end
        8'd106 : begin wave_out_r <= 4964; end
        8'd107 : begin wave_out_r <= 5004; end
        8'd108 : begin wave_out_r <= 5044; end
        8'd109 : begin wave_out_r <= 5083; end
        8'd110 : begin wave_out_r <= 5122; end
        8'd111 : begin wave_out_r <= 5162; end
        8'd112 : begin wave_out_r <= 5201; end
        8'd113 : begin wave_out_r <= 5239; end
        8'd114 : begin wave_out_r <= 5278; end
        8'd115 : begin wave_out_r <= 5316; end
        8'd116 : begin wave_out_r <= 5354; end
        8'd117 : begin wave_out_r <= 5392; end
        8'd118 : begin wave_out_r <= 5430; end
        8'd119 : begin wave_out_r <= 5468; end
        8'd120 : begin wave_out_r <= 5505; end
        8'd121 : begin wave_out_r <= 5542; end
        8'd122 : begin wave_out_r <= 5579; end
        8'd123 : begin wave_out_r <= 5616; end
        8'd124 : begin wave_out_r <= 5652; end
        8'd125 : begin wave_out_r <= 5689; end
        8'd126 : begin wave_out_r <= 5725; end
        8'd127 : begin wave_out_r <= 5761; end
        8'd128 : begin wave_out_r <= 5796; end
        8'd129 : begin wave_out_r <= 5832; end
        8'd130 : begin wave_out_r <= 5867; end
        8'd131 : begin wave_out_r <= 5902; end
        8'd132 : begin wave_out_r <= 5937; end
        8'd133 : begin wave_out_r <= 5971; end
        8'd134 : begin wave_out_r <= 6006; end
        8'd135 : begin wave_out_r <= 6040; end
        8'd136 : begin wave_out_r <= 6074; end
        8'd137 : begin wave_out_r <= 6107; end
        8'd138 : begin wave_out_r <= 6141; end
        8'd139 : begin wave_out_r <= 6174; end
        8'd140 : begin wave_out_r <= 6207; end
        8'd141 : begin wave_out_r <= 6239; end
        8'd142 : begin wave_out_r <= 6272; end
        8'd143 : begin wave_out_r <= 6304; end
        8'd144 : begin wave_out_r <= 6336; end
        8'd145 : begin wave_out_r <= 6368; end
        8'd146 : begin wave_out_r <= 6399; end
        8'd147 : begin wave_out_r <= 6431; end
        8'd148 : begin wave_out_r <= 6462; end
        8'd149 : begin wave_out_r <= 6493; end
        8'd150 : begin wave_out_r <= 6523; end
        8'd151 : begin wave_out_r <= 6553; end
        8'd152 : begin wave_out_r <= 6584; end
        8'd153 : begin wave_out_r <= 6613; end
        8'd154 : begin wave_out_r <= 6643; end
        8'd155 : begin wave_out_r <= 6672; end
        8'd156 : begin wave_out_r <= 6701; end
        8'd157 : begin wave_out_r <= 6730; end
        8'd158 : begin wave_out_r <= 6759; end
        8'd159 : begin wave_out_r <= 6787; end
        8'd160 : begin wave_out_r <= 6815; end
        8'd161 : begin wave_out_r <= 6843; end
        8'd162 : begin wave_out_r <= 6870; end
        8'd163 : begin wave_out_r <= 6897; end
        8'd164 : begin wave_out_r <= 6925; end
        8'd165 : begin wave_out_r <= 6951; end
        8'd166 : begin wave_out_r <= 6978; end
        8'd167 : begin wave_out_r <= 7004; end
        8'd168 : begin wave_out_r <= 7030; end
        8'd169 : begin wave_out_r <= 7056; end
        8'd170 : begin wave_out_r <= 7081; end
        8'd171 : begin wave_out_r <= 7106; end
        8'd172 : begin wave_out_r <= 7131; end
        8'd173 : begin wave_out_r <= 7156; end
        8'd174 : begin wave_out_r <= 7180; end
        8'd175 : begin wave_out_r <= 7204; end
        8'd176 : begin wave_out_r <= 7228; end
        8'd177 : begin wave_out_r <= 7251; end
        8'd178 : begin wave_out_r <= 7275; end
        8'd179 : begin wave_out_r <= 7298; end
        8'd180 : begin wave_out_r <= 7320; end
        8'd181 : begin wave_out_r <= 7343; end
        8'd182 : begin wave_out_r <= 7365; end
        8'd183 : begin wave_out_r <= 7387; end
        8'd184 : begin wave_out_r <= 7408; end
        8'd185 : begin wave_out_r <= 7430; end
        8'd186 : begin wave_out_r <= 7451; end
        8'd187 : begin wave_out_r <= 7472; end
        8'd188 : begin wave_out_r <= 7492; end
        8'd189 : begin wave_out_r <= 7512; end
        8'd190 : begin wave_out_r <= 7532; end
        8'd191 : begin wave_out_r <= 7552; end
        8'd192 : begin wave_out_r <= 7571; end
        8'd193 : begin wave_out_r <= 7590; end
        8'd194 : begin wave_out_r <= 7609; end
        8'd195 : begin wave_out_r <= 7627; end
        8'd196 : begin wave_out_r <= 7646; end
        8'd197 : begin wave_out_r <= 7664; end
        8'd198 : begin wave_out_r <= 7681; end
        8'd199 : begin wave_out_r <= 7698; end
        8'd200 : begin wave_out_r <= 7715; end
        8'd201 : begin wave_out_r <= 7732; end
        8'd202 : begin wave_out_r <= 7749; end
        8'd203 : begin wave_out_r <= 7765; end
        8'd204 : begin wave_out_r <= 7781; end
        8'd205 : begin wave_out_r <= 7796; end
        8'd206 : begin wave_out_r <= 7812; end
        8'd207 : begin wave_out_r <= 7827; end
        8'd208 : begin wave_out_r <= 7841; end
        8'd209 : begin wave_out_r <= 7856; end
        8'd210 : begin wave_out_r <= 7870; end
        8'd211 : begin wave_out_r <= 7884; end
        8'd212 : begin wave_out_r <= 7897; end
        8'd213 : begin wave_out_r <= 7910; end
        8'd214 : begin wave_out_r <= 7923; end
        8'd215 : begin wave_out_r <= 7936; end
        8'd216 : begin wave_out_r <= 7948; end
        8'd217 : begin wave_out_r <= 7960; end
        8'd218 : begin wave_out_r <= 7972; end
        8'd219 : begin wave_out_r <= 7983; end
        8'd220 : begin wave_out_r <= 7994; end
        8'd221 : begin wave_out_r <= 8005; end
        8'd222 : begin wave_out_r <= 8016; end
        8'd223 : begin wave_out_r <= 8026; end
        8'd224 : begin wave_out_r <= 8036; end
        8'd225 : begin wave_out_r <= 8045; end
        8'd226 : begin wave_out_r <= 8055; end
        8'd227 : begin wave_out_r <= 8064; end
        8'd228 : begin wave_out_r <= 8072; end
        8'd229 : begin wave_out_r <= 8081; end
        8'd230 : begin wave_out_r <= 8089; end
        8'd231 : begin wave_out_r <= 8097; end
        8'd232 : begin wave_out_r <= 8104; end
        8'd233 : begin wave_out_r <= 8111; end
        8'd234 : begin wave_out_r <= 8118; end
        8'd235 : begin wave_out_r <= 8125; end
        8'd236 : begin wave_out_r <= 8131; end
        8'd237 : begin wave_out_r <= 8137; end
        8'd238 : begin wave_out_r <= 8142; end
        8'd239 : begin wave_out_r <= 8148; end
        8'd240 : begin wave_out_r <= 8153; end
        8'd241 : begin wave_out_r <= 8157; end
        8'd242 : begin wave_out_r <= 8162; end
        8'd243 : begin wave_out_r <= 8166; end
        8'd244 : begin wave_out_r <= 8170; end
        8'd245 : begin wave_out_r <= 8173; end
        8'd246 : begin wave_out_r <= 8176; end
        8'd247 : begin wave_out_r <= 8179; end
        8'd248 : begin wave_out_r <= 8182; end
        8'd249 : begin wave_out_r <= 8184; end
        8'd250 : begin wave_out_r <= 8186; end
        8'd251 : begin wave_out_r <= 8188; end
        8'd252 : begin wave_out_r <= 8189; end
        8'd253 : begin wave_out_r <= 8190; end
        8'd254 : begin wave_out_r <= 8191; end
        8'd255 : begin wave_out_r <= 8191; end
        default : begin wave_out_r <= 0; end
    endcase
end

reg signed [13 : 0] AM_Carry_r0 = 0;
always @(*) begin
    case (addr_r1[9]) 
        1'b0    :   begin AM_Carry_r0 <= wave_out_r[13 : 0]; end
        1'b1    :   begin AM_Carry_r0 <= - wave_out_r[13 : 0]; end
        default :   begin AM_Carry_r0 <= 14'd0; end
    endcase
end

reg signed [13 : 0] AM_Carry_r1 = 0;
always @(posedge clk) begin
    if (RST) begin
        AM_Carry_r1 <= 0;
    end
    else begin
        AM_Carry_r1 <= AM_Carry_r0;
    end
end

reg signed [INPUT_WIDTH + 14 : 0] AM_wave_r0 = 0;
always @(posedge clk) begin
    if (RST) begin
        AM_wave_r0 <= 0;
    end
    else begin
        AM_wave_r0 <= $signed(AM_Carry_r1) * $signed({1'b0,data_r2});
    end
end

reg signed [OUTPUT_WIDTH - 1 : 0] AM_wave_r1 = 0;
always @(posedge clk) begin
    if (RST) begin
        AM_wave_r1 <= 0;
    end
    else begin
        AM_wave_r1 <= AM_wave_r0[INPUT_WIDTH + 13 : INPUT_WIDTH + 14 - OUTPUT_WIDTH];
    end
end
assign AM_wave = AM_wave_r1;

endmodule
