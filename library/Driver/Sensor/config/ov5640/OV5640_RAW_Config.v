`timescale 1ns/1ns
module	OV5640_RAW_Config (
    input		[8:0]	LUT_INDEX,
    output	reg	[23:0]	LUT_DATA,
    output		[8:0]	LUT_SIZE
);
    assign		LUT_SIZE = 9'd313;

    //-----------------------------------------------------------------
    /////////////////////	Config Data LUT	  //////////////////////////
    always@(*) begin
        case(LUT_INDEX)
            //Read Data Index
            0:
                LUT_DATA	=	{16'h300A, 8'h56};	//Chip ID MSB
            1:
                LUT_DATA	=	{16'h300A, 8'h40};	//Chip ID LSB
            //Write Data Index
            2:
                LUT_DATA	= 	{16'h3008, 8'h42};
            3:
                LUT_DATA	= 	{16'h3103, 8'h03};
            4:
                LUT_DATA	= 	{16'h4005, 8'h1a};
            5:
                LUT_DATA	= 	{16'h4740, 8'h21};
            6:
                LUT_DATA	= 	{16'h3017, 8'hff};
            7:
                LUT_DATA	= 	{16'h3018, 8'hff};
            8:
                LUT_DATA	= 	{16'h3034, 8'h1a};	//PLL
            9:
                LUT_DATA	= 	{16'h3035, 8'h21};	//PLL
            10:
                LUT_DATA	= 	{16'h3036, 8'h46};	//PLL
            11:
                LUT_DATA	= 	{16'h3037, 8'h13};	//PLL
            12:
                LUT_DATA	= 	{16'h3108, 8'h01};
            13:
                LUT_DATA	= 	{16'h3630, 8'h36};
            14:
                LUT_DATA	= 	{16'h3631, 8'h0e};
            15:
                LUT_DATA	= 	{16'h3632, 8'he2};
            16:
                LUT_DATA	= 	{16'h3633, 8'h12};
            17:
                LUT_DATA	= 	{16'h3621, 8'he0};
            18:
                LUT_DATA	= 	{16'h3704, 8'ha0};
            19:
                LUT_DATA	= 	{16'h3703, 8'h5a};
            20:
                LUT_DATA	= 	{16'h3715, 8'h78};
            21:
                LUT_DATA	= 	{16'h3717, 8'h01};
            22:
                LUT_DATA	= 	{16'h370b, 8'h60};
            23:
                LUT_DATA	= 	{16'h3705, 8'h1a};
            24:
                LUT_DATA	= 	{16'h3905, 8'h02};
            25:
                LUT_DATA	= 	{16'h3906, 8'h10};
            26:
                LUT_DATA	= 	{16'h3901, 8'h0a};
            27:
                LUT_DATA	= 	{16'h3731, 8'h12};
            28:
                LUT_DATA	= 	{16'h3600, 8'h08};
            29:
                LUT_DATA	= 	{16'h3601, 8'h33};
            30:
                LUT_DATA	= 	{16'h302d, 8'h60};
            31:
                LUT_DATA	= 	{16'h3620, 8'h52};
            32:
                LUT_DATA	= 	{16'h371b, 8'h20};
            33:
                LUT_DATA	= 	{16'h471c, 8'h50};
            34:
                LUT_DATA	= 	{16'h3a13, 8'h43};
            35:
                LUT_DATA	= 	{16'h3a18, 8'h00};
            36:
                LUT_DATA	= 	{16'h3a19, 8'hb0};
            37:
                LUT_DATA	= 	{16'h3635, 8'h13};
            38:
                LUT_DATA	= 	{16'h3636, 8'h03};
            39:
                LUT_DATA	= 	{16'h3634, 8'h40};
            40:
                LUT_DATA	= 	{16'h3622, 8'h01};
            41:
                LUT_DATA	= 	{16'h3c01, 8'h34};
            42:
                LUT_DATA	= 	{16'h3c00, 8'h00};
            43:
                LUT_DATA	= 	{16'h3c04, 8'h28};
            44:
                LUT_DATA	= 	{16'h3c05, 8'h98};
            45:
                LUT_DATA	= 	{16'h3c06, 8'h00};
            46:
                LUT_DATA	= 	{16'h3c07, 8'h08};
            47:
                LUT_DATA	= 	{16'h3c08, 8'h00};
            48:
                LUT_DATA	= 	{16'h3c09, 8'h1c};
            49:
                LUT_DATA	= 	{16'h3c0a, 8'h9c};
            50:
                LUT_DATA	= 	{16'h3c0b, 8'h40};
            51:
                LUT_DATA	= 	{16'h3820, 8'h40};
            52:
                LUT_DATA	= 	{16'h3821, 8'h01};
            53:
                LUT_DATA	= 	{16'h3814, 8'h31};
            54:
                LUT_DATA	= 	{16'h3815, 8'h31};
            55:
                LUT_DATA	= 	{16'h3800, 8'h00};
            56:
                LUT_DATA	= 	{16'h3801, 8'h00};
            57:
                LUT_DATA	= 	{16'h3802, 8'h00};
            58:
                LUT_DATA	= 	{16'h3803, 8'h04};
            59:
                LUT_DATA	= 	{16'h3804, 8'h0a};
            60:
                LUT_DATA	= 	{16'h3805, 8'h3f};
            61:
                LUT_DATA	= 	{16'h3806, 8'h07};
            62:
                LUT_DATA	= 	{16'h3807, 8'h9b};	//	VGA		QVGA	SVGA	CIF		720P
            63:
                LUT_DATA	= 	{16'h3808, 8'h02};	//	02		01		03		01		05
            64:
                LUT_DATA	= 	{16'h3809, 8'h80};	//	80		40		20		60		00
            65:
                LUT_DATA	= 	{16'h380a, 8'h01};	//	01		00		02		01		02
            66:
                LUT_DATA	= 	{16'h380b, 8'he0};	//	e0		f0		58		20		d0
            67:
                LUT_DATA	= 	{16'h380c, 8'h07};	// Look for pdf Page39
            68:
                LUT_DATA	= 	{16'h380d, 8'h68};
            69:
                LUT_DATA	= 	{16'h380e, 8'h03};
            70:
                LUT_DATA	= 	{16'h380f, 8'hd8};
            71:
                LUT_DATA	= 	{16'h3810, 8'h00};
            72:
                LUT_DATA	= 	{16'h3811, 8'h10};
            73:
                LUT_DATA	= 	{16'h3812, 8'h00};
            74:
                LUT_DATA	= 	{16'h3813, 8'h06};
            75:
                LUT_DATA	= 	{16'h3618, 8'h00};
            76:
                LUT_DATA	= 	{16'h3612, 8'h29};
            77:
                LUT_DATA	= 	{16'h3708, 8'h64};
            78:
                LUT_DATA	= 	{16'h3709, 8'h52};
            79:
                LUT_DATA	= 	{16'h370c, 8'h03};
            80:
                LUT_DATA	= 	{16'h3a02, 8'h03};
            81:
                LUT_DATA	= 	{16'h3a03, 8'hd8};
            82:
                LUT_DATA	= 	{16'h3a08, 8'h01};
            83:
                LUT_DATA	= 	{16'h3a09, 8'h27};
            84:
                LUT_DATA	= 	{16'h3a0a, 8'h00};
            85:
                LUT_DATA	= 	{16'h3a0b, 8'hf6};
            86:
                LUT_DATA	= 	{16'h3a0e, 8'h03};
            87:
                LUT_DATA	= 	{16'h3a0d, 8'h04};
            88:
                LUT_DATA	= 	{16'h3a14, 8'h03};
            89:
                LUT_DATA	= 	{16'h3a15, 8'hd8};
            90:
                LUT_DATA	= 	{16'h4001, 8'h02};
            91:
                LUT_DATA	= 	{16'h4004, 8'h02};
            92:
                LUT_DATA	= 	{16'h3000, 8'h00};
            93:
                LUT_DATA	= 	{16'h3002, 8'h1c};
            94:
                LUT_DATA	= 	{16'h3004, 8'hff};
            95:
                LUT_DATA	= 	{16'h3006, 8'hc3};
            96:
                LUT_DATA	= 	{16'h300e, 8'h58};
            97:
                LUT_DATA	= 	{16'h302e, 8'h00};
            98:
                LUT_DATA	= 	{16'h4300, 8'h00};// RGB565:61 YUV422YUYV:30 ;RAW: 00/01/02/03
            99:
                LUT_DATA	= 	{16'h501f, 8'h01};// 00: ISP:YUV22 01:ISP:RGB
            100:
                LUT_DATA	= 	{16'h3016, 8'h02};
            101:
                LUT_DATA	= 	{16'h301c, 8'h02};
            102:
                LUT_DATA	= 	{16'h3019, 8'h02};
            103:
                LUT_DATA	= 	{16'h3019, 8'h00};
            104:
                LUT_DATA	= 	{16'h4713, 8'h03};
            105:
                LUT_DATA	= 	{16'h4407, 8'h04};
            106:
                LUT_DATA	= 	{16'h440e, 8'h00};
            107:
                LUT_DATA	= 	{16'h460b, 8'h35};
            108:
                LUT_DATA	= 	{16'h460c, 8'h20};
            109:
                LUT_DATA	= 	{16'h4837, 8'h22};
            110:
                LUT_DATA	= 	{16'h3824, 8'h02};
            111:
                LUT_DATA	= 	{16'h5000, 8'ha7};
            112:
                LUT_DATA	= 	{16'h5001, 8'ha3};
            113:
                LUT_DATA	= 	{16'h5180, 8'hff};
            114:
                LUT_DATA	= 	{16'h5181, 8'hf2};
            115:
                LUT_DATA	= 	{16'h5182, 8'h00};
            116:
                LUT_DATA	= 	{16'h5183, 8'h14};
            117:
                LUT_DATA	= 	{16'h5184, 8'h25};
            118:
                LUT_DATA	= 	{16'h5185, 8'h24};
            119:
                LUT_DATA	= 	{16'h5186, 8'h10};
            120:
                LUT_DATA	= 	{16'h5187, 8'h12};
            121:
                LUT_DATA	= 	{16'h5188, 8'h10};
            122:
                LUT_DATA	= 	{16'h5189, 8'h74};
            123:
                LUT_DATA	= 	{16'h518a, 8'h5e};
            124:
                LUT_DATA	= 	{16'h518b, 8'hac};
            125:
                LUT_DATA	= 	{16'h518c, 8'h83};
            126:
                LUT_DATA	= 	{16'h518d, 8'h3b};
            127:
                LUT_DATA	= 	{16'h518e, 8'h35};
            128:
                LUT_DATA	= 	{16'h518f, 8'h4f};
            129:
                LUT_DATA	= 	{16'h5190, 8'h42};
            130:
                LUT_DATA	= 	{16'h5191, 8'hf8};
            131:
                LUT_DATA	= 	{16'h5192, 8'h04};
            132:
                LUT_DATA	= 	{16'h5193, 8'h70};
            133:
                LUT_DATA	= 	{16'h5194, 8'hf0};
            134:
                LUT_DATA	= 	{16'h5195, 8'hf0};
            135:
                LUT_DATA	= 	{16'h5196, 8'h03};
            136:
                LUT_DATA	= 	{16'h5197, 8'h01};
            137:
                LUT_DATA	= 	{16'h5198, 8'h04};
            138:
                LUT_DATA	= 	{16'h5199, 8'h87};
            139:
                LUT_DATA	= 	{16'h519a, 8'h04};
            140:
                LUT_DATA	= 	{16'h519b, 8'h00};
            141:
                LUT_DATA	= 	{16'h519c, 8'h07};
            142:
                LUT_DATA	= 	{16'h519d, 8'h56};
            143:
                LUT_DATA	= 	{16'h519e, 8'h38};
            144:
                LUT_DATA	= 	{16'h5381, 8'h1e};
            145:
                LUT_DATA	= 	{16'h5382, 8'h5b};
            146:
                LUT_DATA	= 	{16'h5383, 8'h08};
            147:
                LUT_DATA	= 	{16'h5384, 8'h0a};
            148:
                LUT_DATA	= 	{16'h5385, 8'h7e};
            149:
                LUT_DATA	= 	{16'h5386, 8'h88};
            150:
                LUT_DATA	= 	{16'h5387, 8'h7c};
            151:
                LUT_DATA	= 	{16'h5388, 8'h6c};
            152:
                LUT_DATA	= 	{16'h5389, 8'h10};
            153:
                LUT_DATA	= 	{16'h538a, 8'h01};
            154:
                LUT_DATA	= 	{16'h538b, 8'h98};
            155:
                LUT_DATA	= 	{16'h5300, 8'h08};
            156:
                LUT_DATA	= 	{16'h5301, 8'h30};
            157:
                LUT_DATA	= 	{16'h5302, 8'h10};
            158:
                LUT_DATA	= 	{16'h5303, 8'h00};
            159:
                LUT_DATA	= 	{16'h5304, 8'h08};
            160:
                LUT_DATA	= 	{16'h5305, 8'h30};
            161:
                LUT_DATA	= 	{16'h5306, 8'h08};
            162:
                LUT_DATA	= 	{16'h5307, 8'h16};
            163:
                LUT_DATA	= 	{16'h5309, 8'h08};
            164:
                LUT_DATA	= 	{16'h530a, 8'h30};
            165:
                LUT_DATA	= 	{16'h530b, 8'h04};
            166:
                LUT_DATA	= 	{16'h530c, 8'h06};
            167:
                LUT_DATA	= 	{16'h5480, 8'h01};
            168:
                LUT_DATA	= 	{16'h5481, 8'h08};
            169:
                LUT_DATA	= 	{16'h5482, 8'h14};
            170:
                LUT_DATA	= 	{16'h5483, 8'h28};
            171:
                LUT_DATA	= 	{16'h5484, 8'h51};
            172:
                LUT_DATA	= 	{16'h5485, 8'h65};
            173:
                LUT_DATA	= 	{16'h5486, 8'h71};
            174:
                LUT_DATA	= 	{16'h5487, 8'h7d};
            175:
                LUT_DATA	= 	{16'h5488, 8'h87};
            176:
                LUT_DATA	= 	{16'h5489, 8'h91};
            177:
                LUT_DATA	= 	{16'h548a, 8'h9a};
            178:
                LUT_DATA	= 	{16'h548b, 8'haa};
            179:
                LUT_DATA	= 	{16'h548c, 8'hb8};
            180:
                LUT_DATA	= 	{16'h548d, 8'hcd};
            181:
                LUT_DATA	= 	{16'h548e, 8'hdd};
            182:
                LUT_DATA	= 	{16'h548f, 8'hea};
            183:
                LUT_DATA	= 	{16'h5490, 8'h1d};
            184:
                LUT_DATA	= 	{16'h5580, 8'h02};
            185:
                LUT_DATA	= 	{16'h5583, 8'h40};
            186:
                LUT_DATA	= 	{16'h5584, 8'h10};
            187:
                LUT_DATA	= 	{16'h5589, 8'h10};
            188:
                LUT_DATA	= 	{16'h558a, 8'h00};
            189:
                LUT_DATA	= 	{16'h558b, 8'hf8};
            190:
                LUT_DATA	= 	{16'h5800, 8'h23};
            191:
                LUT_DATA	= 	{16'h5801, 8'h15};
            192:
                LUT_DATA	= 	{16'h5802, 8'h10};
            193:
                LUT_DATA	= 	{16'h5803, 8'h10};
            194:
                LUT_DATA	= 	{16'h5804, 8'h15};
            195:
                LUT_DATA	= 	{16'h5805, 8'h23};
            196:
                LUT_DATA	= 	{16'h5806, 8'h0c};
            197:
                LUT_DATA	= 	{16'h5807, 8'h08};
            198:
                LUT_DATA	= 	{16'h5808, 8'h05};
            199:
                LUT_DATA	= 	{16'h5809, 8'h05};
            200:
                LUT_DATA	= 	{16'h580a, 8'h08};
            201:
                LUT_DATA	= 	{16'h580b, 8'h0c};
            202:
                LUT_DATA	= 	{16'h580c, 8'h07};
            203:
                LUT_DATA	= 	{16'h580d, 8'h03};
            204:
                LUT_DATA	= 	{16'h580e, 8'h00};
            205:
                LUT_DATA	= 	{16'h580f, 8'h00};
            206:
                LUT_DATA	= 	{16'h5810, 8'h03};
            207:
                LUT_DATA	= 	{16'h5811, 8'h07};
            208:
                LUT_DATA	= 	{16'h5812, 8'h07};
            209:
                LUT_DATA	= 	{16'h5813, 8'h03};
            210:
                LUT_DATA	= 	{16'h5814, 8'h00};
            211:
                LUT_DATA	= 	{16'h5815, 8'h00};
            212:
                LUT_DATA	= 	{16'h5816, 8'h03};
            213:
                LUT_DATA	= 	{16'h5817, 8'h07};
            214:
                LUT_DATA	= 	{16'h5818, 8'h0b};
            215:
                LUT_DATA	= 	{16'h5819, 8'h08};
            216:
                LUT_DATA	= 	{16'h581a, 8'h05};
            217:
                LUT_DATA	= 	{16'h581b, 8'h05};
            218:
                LUT_DATA	= 	{16'h581c, 8'h07};
            219:
                LUT_DATA	= 	{16'h581d, 8'h0b};
            220:
                LUT_DATA	= 	{16'h581e, 8'h2a};
            221:
                LUT_DATA	= 	{16'h581f, 8'h16};
            222:
                LUT_DATA	= 	{16'h5820, 8'h11};
            223:
                LUT_DATA	= 	{16'h5821, 8'h11};
            224:
                LUT_DATA	= 	{16'h5822, 8'h15};
            225:
                LUT_DATA	= 	{16'h5823, 8'h29};
            226:
                LUT_DATA	= 	{16'h5824, 8'hbf};
            227:
                LUT_DATA	= 	{16'h5825, 8'haf};
            228:
                LUT_DATA	= 	{16'h5826, 8'h9f};
            229:
                LUT_DATA	= 	{16'h5827, 8'haf};
            230:
                LUT_DATA	= 	{16'h5828, 8'hdf};
            231:
                LUT_DATA	= 	{16'h5829, 8'h6f};
            232:
                LUT_DATA	= 	{16'h582a, 8'h8e};
            233:
                LUT_DATA	= 	{16'h582b, 8'hab};
            234:
                LUT_DATA	= 	{16'h582c, 8'h9e};
            235:
                LUT_DATA	= 	{16'h582d, 8'h7f};
            236:
                LUT_DATA	= 	{16'h582e, 8'h4f};
            237:
                LUT_DATA	= 	{16'h582f, 8'h89};
            238:
                LUT_DATA	= 	{16'h5830, 8'h86};
            239:
                LUT_DATA	= 	{16'h5831, 8'h98};
            240:
                LUT_DATA	= 	{16'h5832, 8'h6f};
            241:
                LUT_DATA	= 	{16'h5833, 8'h4f};
            242:
                LUT_DATA	= 	{16'h5834, 8'h6e};
            243:
                LUT_DATA	= 	{16'h5835, 8'h7b};
            244:
                LUT_DATA	= 	{16'h5836, 8'h7e};
            245:
                LUT_DATA	= 	{16'h5837, 8'h6f};
            246:
                LUT_DATA	= 	{16'h5838, 8'hde};
            247:
                LUT_DATA	= 	{16'h5839, 8'hbf};
            248:
                LUT_DATA	= 	{16'h583a, 8'h9f};
            249:
                LUT_DATA	= 	{16'h583b, 8'hbf};
            250:
                LUT_DATA	= 	{16'h583c, 8'hec};
            251:
                LUT_DATA	= 	{16'h583d, 8'hdf};
            252:
                LUT_DATA	= 	{16'h5025, 8'h00};
            253:
                LUT_DATA	= 	{16'h3a0f, 8'h30};
            254:
                LUT_DATA	= 	{16'h3a10, 8'h28};
            255:
                LUT_DATA	= 	{16'h3a1b, 8'h30};
            256:
                LUT_DATA	= 	{16'h3a1e, 8'h26};
            257:
                LUT_DATA	= 	{16'h3a11, 8'h60};
            258:
                LUT_DATA	= 	{16'h3a1f, 8'h14};
            259:
                LUT_DATA	= 	{16'h3008, 8'h02};
            260:
                LUT_DATA	= 	{16'h5300, 8'h08};
            261:
                LUT_DATA	= 	{16'h5301, 8'h30};
            262:
                LUT_DATA	= 	{16'h5302, 8'h10};
            263:
                LUT_DATA	= 	{16'h5303, 8'h00};
            264:
                LUT_DATA	= 	{16'h5304, 8'h08};
            265:
                LUT_DATA	= 	{16'h5305, 8'h30};
            266:
                LUT_DATA	= 	{16'h5306, 8'h08};
            267:
                LUT_DATA	= 	{16'h5307, 8'h16};
            268:
                LUT_DATA	= 	{16'h5309, 8'h08};
            269:
                LUT_DATA	= 	{16'h530a, 8'h30};
            270:
                LUT_DATA	= 	{16'h530b, 8'h04};
            271:
                LUT_DATA	= 	{16'h530c, 8'h06};
            272:
                LUT_DATA	= 	{16'h3c07, 8'h08};
            273:
                LUT_DATA	= 	{16'h3820, 8'h46};	//上下翻转 flip 40/46
            274:
                LUT_DATA	= 	{16'h3821, 8'h01};	//左右翻转 mirror
            275:
                LUT_DATA	= 	{16'h3814, 8'h31};
            276:
                LUT_DATA	= 	{16'h3815, 8'h31};
            277:
                LUT_DATA	= 	{16'h3803, 8'h04};
            278:
                LUT_DATA	= 	{16'h3807, 8'h9b};
            279:
                LUT_DATA	= 	{16'h3808, 8'h02};
            280:
                LUT_DATA	= 	{16'h3809, 8'h80};
            281:
                LUT_DATA	= 	{16'h380a, 8'h01};
            282:
                LUT_DATA	= 	{16'h380b, 8'he0};
            283:
                LUT_DATA	= 	{16'h380c, 8'h07};
            284:
                LUT_DATA	= 	{16'h380d, 8'h68};
            285:
                LUT_DATA	= 	{16'h380e, 8'h03};
            286:
                LUT_DATA	= 	{16'h380f, 8'hd8};
            287:
                LUT_DATA	= 	{16'h3813, 8'h06};
            288:
                LUT_DATA	= 	{16'h3618, 8'h00};
            289:
                LUT_DATA	= 	{16'h3612, 8'h29};
            290:
                LUT_DATA	= 	{16'h3709, 8'h52};
            291:
                LUT_DATA	= 	{16'h370c, 8'h03};
            292:
                LUT_DATA	= 	{16'h3a02, 8'h03};
            293:
                LUT_DATA	= 	{16'h3a03, 8'hd8};
            294:
                LUT_DATA	= 	{16'h3a0e, 8'h03};
            295:
                LUT_DATA	= 	{16'h3a0d, 8'h04};
            296:
                LUT_DATA	= 	{16'h3a14, 8'h03};
            297:
                LUT_DATA	= 	{16'h3a15, 8'hd8};
            298:
                LUT_DATA	= 	{16'h4004, 8'h02};
            299:
                LUT_DATA	= 	{16'h3035, 8'h11};
            300:
                LUT_DATA	= 	{16'h3036, 8'h69};
            301:
                LUT_DATA	= 	{16'h4837, 8'h22};
            302:
                LUT_DATA	= 	{16'h5001, 8'ha3};
            303:
                LUT_DATA	= 	{16'h3000, 8'h20};
            304:
                LUT_DATA	= 	{16'h3022, 8'h00};
            305:
                LUT_DATA	= 	{16'h3023, 8'h00};
            306:
                LUT_DATA	= 	{16'h3024, 8'h00};
            307:
                LUT_DATA	= 	{16'h3025, 8'h00};
            308:
                LUT_DATA	= 	{16'h3026, 8'h00};
            309:
                LUT_DATA	= 	{16'h3027, 8'h00};
            310:
                LUT_DATA	= 	{16'h3028, 8'h00};
            311:
                LUT_DATA	= 	{16'h3029, 8'hFF};
            312:
                LUT_DATA	= 	{16'h3000, 8'h00};

            default:
                LUT_DATA	=	0;
        endcase
    end
endmodule
