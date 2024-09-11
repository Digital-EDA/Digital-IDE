module DDS_Gen #(
	parameter OUTPUT_WIDTH = 12,
	parameter PHASE_WIDTH  = 32
) (
    input                         clk,
    input  [PHASE_WIDTH  - 1 : 0] Fre_word, // (fre*4294967296)/clk/1000000
    input  [PHASE_WIDTH  - 1 : 0] Pha_word, // (fre*4294967296)/clk/1000000
    output [OUTPUT_WIDTH - 1 : 0] wave_out_sin,
	output [OUTPUT_WIDTH - 1 : 0] wave_out_tri,
	output [OUTPUT_WIDTH - 1 : 0] wave_out_saw
);

localparam [OUTPUT_WIDTH  - 1 : 0] DC_SUB = 2**(OUTPUT_WIDTH-1);

reg [OUTPUT_WIDTH - 1 : 0] wave_out_sin_r;
reg [OUTPUT_WIDTH - 1 : 0] wave_out_tri_r;
reg [OUTPUT_WIDTH - 1 : 0] wave_out_saw_r;

reg [PHASE_WIDTH - 1 : 0] addr_r0 = 0;
reg [PHASE_WIDTH - 1 : 0] addr_r1 = 0;
always @(posedge clk) begin
	addr_r0 <= addr_r0 + Fre_word;
	addr_r1 <= addr_r0 + Pha_word;
end


always @(posedge clk ) begin
	wave_out_saw_r <= addr_r1[PHASE_WIDTH - 1 : PHASE_WIDTH - OUTPUT_WIDTH];
end
assign wave_out_saw = wave_out_saw_r;

always @(posedge clk ) begin
	if (addr_r1[PHASE_WIDTH - 1])
		wave_out_tri_r <= (2**(OUTPUT_WIDTH + 1)-1) - addr_r1[PHASE_WIDTH - 1 : PHASE_WIDTH - OUTPUT_WIDTH - 1];
	else
		wave_out_tri_r <= addr_r1[PHASE_WIDTH - 1 : PHASE_WIDTH - OUTPUT_WIDTH - 1];
end
assign wave_out_tri = wave_out_tri_r - DC_SUB;

reg [9:0] addr_r = 0;
always @(posedge clk) begin
	addr_r <= addr_r1[PHASE_WIDTH  - 1 : PHASE_WIDTH  - 10];
end

reg  [7:0] addr; 
always @(*) begin
	case (addr_r[9:8]) 
	    2'b00    :   begin addr <= addr_r[7:0]; end
	    2'b01    :   begin addr <= addr_r[7:0] ^ 8'b1111_1111; end
	    2'b10    :   begin addr <= addr_r[7:0]; end
	    2'b11    :   begin addr <= addr_r[7:0] ^ 8'b1111_1111; end
	    default  :   begin addr <= 8'd0; end
	endcase
end

reg signed [13:0] wave_sin_buf;
always @(*) begin
	case (addr)
		8'd0 : begin wave_sin_buf <= 0; end
		8'd1 : begin wave_sin_buf <= 50; end
		8'd2 : begin wave_sin_buf <= 101; end
		8'd3 : begin wave_sin_buf <= 151; end
		8'd4 : begin wave_sin_buf <= 201; end
		8'd5 : begin wave_sin_buf <= 252; end
		8'd6 : begin wave_sin_buf <= 302; end
		8'd7 : begin wave_sin_buf <= 352; end
		8'd8 : begin wave_sin_buf <= 402; end
		8'd9 : begin wave_sin_buf <= 453; end
		8'd10 : begin wave_sin_buf <= 503; end
		8'd11 : begin wave_sin_buf <= 553; end
		8'd12 : begin wave_sin_buf <= 603; end
		8'd13 : begin wave_sin_buf <= 653; end
		8'd14 : begin wave_sin_buf <= 703; end
		8'd15 : begin wave_sin_buf <= 754; end
		8'd16 : begin wave_sin_buf <= 804; end
		8'd17 : begin wave_sin_buf <= 854; end
		8'd18 : begin wave_sin_buf <= 904; end
		8'd19 : begin wave_sin_buf <= 954; end
		8'd20 : begin wave_sin_buf <= 1004; end
		8'd21 : begin wave_sin_buf <= 1054; end
		8'd22 : begin wave_sin_buf <= 1103; end
		8'd23 : begin wave_sin_buf <= 1153; end
		8'd24 : begin wave_sin_buf <= 1203; end
		8'd25 : begin wave_sin_buf <= 1253; end
		8'd26 : begin wave_sin_buf <= 1302; end
		8'd27 : begin wave_sin_buf <= 1352; end
		8'd28 : begin wave_sin_buf <= 1402; end
		8'd29 : begin wave_sin_buf <= 1451; end
		8'd30 : begin wave_sin_buf <= 1501; end
		8'd31 : begin wave_sin_buf <= 1550; end
		8'd32 : begin wave_sin_buf <= 1600; end
		8'd33 : begin wave_sin_buf <= 1649; end
		8'd34 : begin wave_sin_buf <= 1698; end
		8'd35 : begin wave_sin_buf <= 1747; end
		8'd36 : begin wave_sin_buf <= 1796; end
		8'd37 : begin wave_sin_buf <= 1845; end
		8'd38 : begin wave_sin_buf <= 1894; end
		8'd39 : begin wave_sin_buf <= 1943; end
		8'd40 : begin wave_sin_buf <= 1992; end
		8'd41 : begin wave_sin_buf <= 2041; end
		8'd42 : begin wave_sin_buf <= 2090; end
		8'd43 : begin wave_sin_buf <= 2138; end
		8'd44 : begin wave_sin_buf <= 2187; end
		8'd45 : begin wave_sin_buf <= 2235; end
		8'd46 : begin wave_sin_buf <= 2284; end
		8'd47 : begin wave_sin_buf <= 2332; end
		8'd48 : begin wave_sin_buf <= 2380; end
		8'd49 : begin wave_sin_buf <= 2428; end
		8'd50 : begin wave_sin_buf <= 2476; end
		8'd51 : begin wave_sin_buf <= 2524; end
		8'd52 : begin wave_sin_buf <= 2572; end
		8'd53 : begin wave_sin_buf <= 2620; end
		8'd54 : begin wave_sin_buf <= 2667; end
		8'd55 : begin wave_sin_buf <= 2715; end
		8'd56 : begin wave_sin_buf <= 2762; end
		8'd57 : begin wave_sin_buf <= 2809; end
		8'd58 : begin wave_sin_buf <= 2857; end
		8'd59 : begin wave_sin_buf <= 2904; end
		8'd60 : begin wave_sin_buf <= 2951; end
		8'd61 : begin wave_sin_buf <= 2998; end
		8'd62 : begin wave_sin_buf <= 3044; end
		8'd63 : begin wave_sin_buf <= 3091; end
		8'd64 : begin wave_sin_buf <= 3137; end
		8'd65 : begin wave_sin_buf <= 3184; end
		8'd66 : begin wave_sin_buf <= 3230; end
		8'd67 : begin wave_sin_buf <= 3276; end
		8'd68 : begin wave_sin_buf <= 3322; end
		8'd69 : begin wave_sin_buf <= 3368; end
		8'd70 : begin wave_sin_buf <= 3414; end
		8'd71 : begin wave_sin_buf <= 3460; end
		8'd72 : begin wave_sin_buf <= 3505; end
		8'd73 : begin wave_sin_buf <= 3551; end
		8'd74 : begin wave_sin_buf <= 3596; end
		8'd75 : begin wave_sin_buf <= 3641; end
		8'd76 : begin wave_sin_buf <= 3686; end
		8'd77 : begin wave_sin_buf <= 3731; end
		8'd78 : begin wave_sin_buf <= 3776; end
		8'd79 : begin wave_sin_buf <= 3820; end
		8'd80 : begin wave_sin_buf <= 3865; end
		8'd81 : begin wave_sin_buf <= 3909; end
		8'd82 : begin wave_sin_buf <= 3953; end
		8'd83 : begin wave_sin_buf <= 3997; end
		8'd84 : begin wave_sin_buf <= 4041; end
		8'd85 : begin wave_sin_buf <= 4085; end
		8'd86 : begin wave_sin_buf <= 4128; end
		8'd87 : begin wave_sin_buf <= 4172; end
		8'd88 : begin wave_sin_buf <= 4215; end
		8'd89 : begin wave_sin_buf <= 4258; end
		8'd90 : begin wave_sin_buf <= 4301; end
		8'd91 : begin wave_sin_buf <= 4343; end
		8'd92 : begin wave_sin_buf <= 4386; end
		8'd93 : begin wave_sin_buf <= 4428; end
		8'd94 : begin wave_sin_buf <= 4471; end
		8'd95 : begin wave_sin_buf <= 4513; end
		8'd96 : begin wave_sin_buf <= 4555; end
		8'd97 : begin wave_sin_buf <= 4596; end
		8'd98 : begin wave_sin_buf <= 4638; end
		8'd99 : begin wave_sin_buf <= 4679; end
		8'd100 : begin wave_sin_buf <= 4720; end
		8'd101 : begin wave_sin_buf <= 4761; end
		8'd102 : begin wave_sin_buf <= 4802; end
		8'd103 : begin wave_sin_buf <= 4843; end
		8'd104 : begin wave_sin_buf <= 4883; end
		8'd105 : begin wave_sin_buf <= 4924; end
		8'd106 : begin wave_sin_buf <= 4964; end
		8'd107 : begin wave_sin_buf <= 5004; end
		8'd108 : begin wave_sin_buf <= 5044; end
		8'd109 : begin wave_sin_buf <= 5083; end
		8'd110 : begin wave_sin_buf <= 5122; end
		8'd111 : begin wave_sin_buf <= 5162; end
		8'd112 : begin wave_sin_buf <= 5201; end
		8'd113 : begin wave_sin_buf <= 5239; end
		8'd114 : begin wave_sin_buf <= 5278; end
		8'd115 : begin wave_sin_buf <= 5316; end
		8'd116 : begin wave_sin_buf <= 5354; end
		8'd117 : begin wave_sin_buf <= 5392; end
		8'd118 : begin wave_sin_buf <= 5430; end
		8'd119 : begin wave_sin_buf <= 5468; end
		8'd120 : begin wave_sin_buf <= 5505; end
		8'd121 : begin wave_sin_buf <= 5542; end
		8'd122 : begin wave_sin_buf <= 5579; end
		8'd123 : begin wave_sin_buf <= 5616; end
		8'd124 : begin wave_sin_buf <= 5652; end
		8'd125 : begin wave_sin_buf <= 5689; end
		8'd126 : begin wave_sin_buf <= 5725; end
		8'd127 : begin wave_sin_buf <= 5761; end
		8'd128 : begin wave_sin_buf <= 5796; end
		8'd129 : begin wave_sin_buf <= 5832; end
		8'd130 : begin wave_sin_buf <= 5867; end
		8'd131 : begin wave_sin_buf <= 5902; end
		8'd132 : begin wave_sin_buf <= 5937; end
		8'd133 : begin wave_sin_buf <= 5971; end
		8'd134 : begin wave_sin_buf <= 6006; end
		8'd135 : begin wave_sin_buf <= 6040; end
		8'd136 : begin wave_sin_buf <= 6074; end
		8'd137 : begin wave_sin_buf <= 6107; end
		8'd138 : begin wave_sin_buf <= 6141; end
		8'd139 : begin wave_sin_buf <= 6174; end
		8'd140 : begin wave_sin_buf <= 6207; end
		8'd141 : begin wave_sin_buf <= 6239; end
		8'd142 : begin wave_sin_buf <= 6272; end
		8'd143 : begin wave_sin_buf <= 6304; end
		8'd144 : begin wave_sin_buf <= 6336; end
		8'd145 : begin wave_sin_buf <= 6368; end
		8'd146 : begin wave_sin_buf <= 6399; end
		8'd147 : begin wave_sin_buf <= 6431; end
		8'd148 : begin wave_sin_buf <= 6462; end
		8'd149 : begin wave_sin_buf <= 6493; end
		8'd150 : begin wave_sin_buf <= 6523; end
		8'd151 : begin wave_sin_buf <= 6553; end
		8'd152 : begin wave_sin_buf <= 6584; end
		8'd153 : begin wave_sin_buf <= 6613; end
		8'd154 : begin wave_sin_buf <= 6643; end
		8'd155 : begin wave_sin_buf <= 6672; end
		8'd156 : begin wave_sin_buf <= 6701; end
		8'd157 : begin wave_sin_buf <= 6730; end
		8'd158 : begin wave_sin_buf <= 6759; end
		8'd159 : begin wave_sin_buf <= 6787; end
		8'd160 : begin wave_sin_buf <= 6815; end
		8'd161 : begin wave_sin_buf <= 6843; end
		8'd162 : begin wave_sin_buf <= 6870; end
		8'd163 : begin wave_sin_buf <= 6897; end
		8'd164 : begin wave_sin_buf <= 6925; end
		8'd165 : begin wave_sin_buf <= 6951; end
		8'd166 : begin wave_sin_buf <= 6978; end
		8'd167 : begin wave_sin_buf <= 7004; end
		8'd168 : begin wave_sin_buf <= 7030; end
		8'd169 : begin wave_sin_buf <= 7056; end
		8'd170 : begin wave_sin_buf <= 7081; end
		8'd171 : begin wave_sin_buf <= 7106; end
		8'd172 : begin wave_sin_buf <= 7131; end
		8'd173 : begin wave_sin_buf <= 7156; end
		8'd174 : begin wave_sin_buf <= 7180; end
		8'd175 : begin wave_sin_buf <= 7204; end
		8'd176 : begin wave_sin_buf <= 7228; end
		8'd177 : begin wave_sin_buf <= 7251; end
		8'd178 : begin wave_sin_buf <= 7275; end
		8'd179 : begin wave_sin_buf <= 7298; end
		8'd180 : begin wave_sin_buf <= 7320; end
		8'd181 : begin wave_sin_buf <= 7343; end
		8'd182 : begin wave_sin_buf <= 7365; end
		8'd183 : begin wave_sin_buf <= 7387; end
		8'd184 : begin wave_sin_buf <= 7408; end
		8'd185 : begin wave_sin_buf <= 7430; end
		8'd186 : begin wave_sin_buf <= 7451; end
		8'd187 : begin wave_sin_buf <= 7472; end
		8'd188 : begin wave_sin_buf <= 7492; end
		8'd189 : begin wave_sin_buf <= 7512; end
		8'd190 : begin wave_sin_buf <= 7532; end
		8'd191 : begin wave_sin_buf <= 7552; end
		8'd192 : begin wave_sin_buf <= 7571; end
		8'd193 : begin wave_sin_buf <= 7590; end
		8'd194 : begin wave_sin_buf <= 7609; end
		8'd195 : begin wave_sin_buf <= 7627; end
		8'd196 : begin wave_sin_buf <= 7646; end
		8'd197 : begin wave_sin_buf <= 7664; end
		8'd198 : begin wave_sin_buf <= 7681; end
		8'd199 : begin wave_sin_buf <= 7698; end
		8'd200 : begin wave_sin_buf <= 7715; end
		8'd201 : begin wave_sin_buf <= 7732; end
		8'd202 : begin wave_sin_buf <= 7749; end
		8'd203 : begin wave_sin_buf <= 7765; end
		8'd204 : begin wave_sin_buf <= 7781; end
		8'd205 : begin wave_sin_buf <= 7796; end
		8'd206 : begin wave_sin_buf <= 7812; end
		8'd207 : begin wave_sin_buf <= 7827; end
		8'd208 : begin wave_sin_buf <= 7841; end
		8'd209 : begin wave_sin_buf <= 7856; end
		8'd210 : begin wave_sin_buf <= 7870; end
		8'd211 : begin wave_sin_buf <= 7884; end
		8'd212 : begin wave_sin_buf <= 7897; end
		8'd213 : begin wave_sin_buf <= 7910; end
		8'd214 : begin wave_sin_buf <= 7923; end
		8'd215 : begin wave_sin_buf <= 7936; end
		8'd216 : begin wave_sin_buf <= 7948; end
		8'd217 : begin wave_sin_buf <= 7960; end
		8'd218 : begin wave_sin_buf <= 7972; end
		8'd219 : begin wave_sin_buf <= 7983; end
		8'd220 : begin wave_sin_buf <= 7994; end
		8'd221 : begin wave_sin_buf <= 8005; end
		8'd222 : begin wave_sin_buf <= 8016; end
		8'd223 : begin wave_sin_buf <= 8026; end
		8'd224 : begin wave_sin_buf <= 8036; end
		8'd225 : begin wave_sin_buf <= 8045; end
		8'd226 : begin wave_sin_buf <= 8055; end
		8'd227 : begin wave_sin_buf <= 8064; end
		8'd228 : begin wave_sin_buf <= 8072; end
		8'd229 : begin wave_sin_buf <= 8081; end
		8'd230 : begin wave_sin_buf <= 8089; end
		8'd231 : begin wave_sin_buf <= 8097; end
		8'd232 : begin wave_sin_buf <= 8104; end
		8'd233 : begin wave_sin_buf <= 8111; end
		8'd234 : begin wave_sin_buf <= 8118; end
		8'd235 : begin wave_sin_buf <= 8125; end
		8'd236 : begin wave_sin_buf <= 8131; end
		8'd237 : begin wave_sin_buf <= 8137; end
		8'd238 : begin wave_sin_buf <= 8142; end
		8'd239 : begin wave_sin_buf <= 8148; end
		8'd240 : begin wave_sin_buf <= 8153; end
		8'd241 : begin wave_sin_buf <= 8157; end
		8'd242 : begin wave_sin_buf <= 8162; end
		8'd243 : begin wave_sin_buf <= 8166; end
		8'd244 : begin wave_sin_buf <= 8170; end
		8'd245 : begin wave_sin_buf <= 8173; end
		8'd246 : begin wave_sin_buf <= 8176; end
		8'd247 : begin wave_sin_buf <= 8179; end
		8'd248 : begin wave_sin_buf <= 8182; end
		8'd249 : begin wave_sin_buf <= 8184; end
		8'd250 : begin wave_sin_buf <= 8186; end
		8'd251 : begin wave_sin_buf <= 8188; end
		8'd252 : begin wave_sin_buf <= 8189; end
		8'd253 : begin wave_sin_buf <= 8190; end
		8'd254 : begin wave_sin_buf <= 8191; end
		8'd255 : begin wave_sin_buf <= 8191; end
		default : begin wave_sin_buf <= 0; end
	endcase
end

always @(*) begin
	case (addr_r[9]) 
	    1'b0    :   begin wave_out_sin_r <=  wave_sin_buf[13 : 14 - OUTPUT_WIDTH]; end
	    1'b1    :   begin wave_out_sin_r <= -wave_sin_buf[13 : 14 - OUTPUT_WIDTH]; end
	    default :   begin wave_out_sin_r <= 14'd0; end
	endcase
end
assign wave_out_sin = wave_out_sin_r;
endmodule