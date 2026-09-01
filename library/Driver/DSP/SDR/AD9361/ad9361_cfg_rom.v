module ad9361_cfg_rom(
        input              clk,
        input      [11:0]  addr,
        output reg [19:0]  data
    );

    always @(posedge clk) begin
        case(addr)
            12'd0:
                data <= 20'h3DF01; //Required for proper operation
            12'd1:
                data <= 20'h2A60E; // Enable Master Bias
            12'd2:
                data <= 20'h2A80E; // Set Bandgap Trim
            //12'd3: data <= 20'h29208; // Set DCXO Coarse Tune[5:0].  Coarse and Fine nominal values used with eval system.  Other nominal values may be needed in a customer system
            //12'd4: data <= 20'h29380; // Set DCXO Fine Tune [12:5]
            //12'd5: data <= 20'h29400; // Set DCXO Fine Tune [4:0]
            12'd3:
                data <= 20'h40000;
            12'd4:
                data <= 20'h40000;
            12'd5:
                data <= 20'h40000;
            12'd6:
                data <= 20'h2AB07; //Set RF PLL reflclk scale to REFCLK * 2
            12'd7:
                data <= 20'h2ACFF; //Set RF PLL reflclk scale to REFCLK * 2
            12'd8:
                data <= 20'h00917; //Enable Clocks
            12'd9:
                data <= 20'h40000; // 延迟一个spi时钟
            //set bbpll
            12'd10:
                data <= 20'h04500; //Set BBPLL reflclk scale to REFCLK /1
            12'd11:
                data <= 20'h04605; //Set BBPLL Loop Filter Charge Pump current
            12'd12:
                data <= 20'h048E8; //Set BBPLL Loop Filter C1, R1
            12'd13:
                data <= 20'h0495B; //Set BBPLL Loop Filter R2, C2, C1
            12'd14:
                data <= 20'h04A35; //Set BBPLL Loop Filter C3,R2
            12'd15:
                data <= 20'h04BE0; // Allow calibration to occur and set cal count to 1024 for max accuracy
            12'd16:
                data <= 20'h04E10; // Set calibration clock to REFCLK/4 for more accuracy
            12'd17:
                data <= 20'h04300;
            12'd18:
                data <= 20'h042A0;
            12'd19:
                data <= 20'h0410A;
            12'd20:
                data <= 20'h04421;
            12'd21:
                data <= 20'h03F05;
            12'd22:
                data <= 20'h03F01;
            12'd23:
                data <= 20'h04C86;
            12'd24:
                data <= 20'h04D01;
            12'd25:
                data <= 20'h04D05;
            12'd26:
                data <= 20'h40000;
            12'd27:
                data <= 20'h0025E;
            12'd28:
                data <= 20'h0035E;
            12'd29:
                data <= 20'h00403;
            12'd30:
                data <= 20'h00A02; // ADC_clock=BBPLL clock rate/(2^2)
            12'd31:
                data <= 20'h065FA;
            12'd32:
                data <= 20'h06000;
            12'd33:
                data <= 20'h06101;
            12'd34:
                data <= 20'h06200;
            12'd35:
                data <= 20'h065FE;
            12'd36:
                data <= 20'h06400;
            12'd37:
                data <= 20'h06400;
            12'd38:
                data <= 20'h06001;
            12'd39:
                data <= 20'h061F1;
            12'd40:
                data <= 20'h062FF;
            12'd41:
                data <= 20'h065FE;
            12'd42:
                data <= 20'h06400;
            12'd43:
                data <= 20'h06400;
            12'd44:
                data <= 20'h06002;
            12'd45:
                data <= 20'h061CF;
            12'd46:
                data <= 20'h062FF;
            12'd47:
                data <= 20'h065FE;
            12'd48:
                data <= 20'h06400;
            12'd49:
                data <= 20'h06400;
            12'd50:
                data <= 20'h06003;
            12'd51:
                data <= 20'h061C0;
            12'd52:
                data <= 20'h062FF;
            12'd53:
                data <= 20'h065FE;
            12'd54:
                data <= 20'h06400;
            12'd55:
                data <= 20'h06400;
            12'd56:
                data <= 20'h06004;
            12'd57:
                data <= 20'h061E8;
            12'd58:
                data <= 20'h062FF;
            12'd59:
                data <= 20'h065FE;
            12'd60:
                data <= 20'h06400;
            12'd61:
                data <= 20'h06400;
            12'd62:
                data <= 20'h06005;
            12'd63:
                data <= 20'h06120;
            12'd64:
                data <= 20'h06200;
            12'd65:
                data <= 20'h065FE;
            12'd66:
                data <= 20'h06400;
            12'd67:
                data <= 20'h06400;
            12'd68:
                data <= 20'h06006;
            12'd69:
                data <= 20'h0611A;
            12'd70:
                data <= 20'h06200;
            12'd71:
                data <= 20'h065FE;
            12'd72:
                data <= 20'h06400;
            12'd73:
                data <= 20'h06400;
            12'd74:
                data <= 20'h06007;
            12'd75:
                data <= 20'h061E3;
            12'd76:
                data <= 20'h062FF;
            12'd77:
                data <= 20'h065FE;
            12'd78:
                data <= 20'h06400;
            12'd79:
                data <= 20'h06400;
            12'd80:
                data <= 20'h06008;
            12'd81:
                data <= 20'h061E1;
            12'd82:
                data <= 20'h062FF;
            12'd83:
                data <= 20'h065FE;
            12'd84:
                data <= 20'h06400;
            12'd85:
                data <= 20'h06400;
            12'd86:
                data <= 20'h06009;
            12'd87:
                data <= 20'h0611F;
            12'd88:
                data <= 20'h06200;
            12'd89:
                data <= 20'h065FE;
            12'd90:
                data <= 20'h06400;
            12'd91:
                data <= 20'h06400;
            12'd92:
                data <= 20'h0600A;
            12'd93:
                data <= 20'h06128;
            12'd94:
                data <= 20'h06200;
            12'd95:
                data <= 20'h065FE;
            12'd96:
                data <= 20'h06400;
            12'd97:
                data <= 20'h06400;
            12'd98:
                data <= 20'h0600B;
            12'd99:
                data <= 20'h061DF;
            12'd100:
                data <= 20'h062FF;
            12'd101:
                data <= 20'h065FE;
            12'd102:
                data <= 20'h06400;
            12'd103:
                data <= 20'h06400;
            12'd104:
                data <= 20'h0600C;
            12'd105:
                data <= 20'h061CC;
            12'd106:
                data <= 20'h062FF;
            12'd107:
                data <= 20'h065FE;
            12'd108:
                data <= 20'h06400;
            12'd109:
                data <= 20'h06400;
            12'd110:
                data <= 20'h0600D;
            12'd111:
                data <= 20'h06124;
            12'd112:
                data <= 20'h06200;
            12'd113:
                data <= 20'h065FE;
            12'd114:
                data <= 20'h06400;
            12'd115:
                data <= 20'h06400;
            12'd116:
                data <= 20'h0600E;
            12'd117:
                data <= 20'h06143;
            12'd118:
                data <= 20'h06200;
            12'd119:
                data <= 20'h065FE;
            12'd120:
                data <= 20'h06400;
            12'd121:
                data <= 20'h06400;
            12'd122:
                data <= 20'h0600F;
            12'd123:
                data <= 20'h061DB;
            12'd124:
                data <= 20'h062FF;
            12'd125:
                data <= 20'h065FE;
            12'd126:
                data <= 20'h06400;
            12'd127:
                data <= 20'h06400;
            12'd128:
                data <= 20'h06010;
            12'd129:
                data <= 20'h061AC;
            12'd130:
                data <= 20'h062FF;
            12'd131:
                data <= 20'h065FE;
            12'd132:
                data <= 20'h06400;
            12'd133:
                data <= 20'h06400;
            12'd134:
                data <= 20'h06011;
            12'd135:
                data <= 20'h06126;
            12'd136:
                data <= 20'h06200;
            12'd137:
                data <= 20'h065FE;
            12'd138:
                data <= 20'h06400;
            12'd139:
                data <= 20'h06400;
            12'd140:
                data <= 20'h06012;
            12'd141:
                data <= 20'h06168;
            12'd142:
                data <= 20'h06200;
            12'd143:
                data <= 20'h065FE;
            12'd144:
                data <= 20'h06400;
            12'd145:
                data <= 20'h06400;
            12'd146:
                data <= 20'h06013;
            12'd147:
                data <= 20'h061DB;
            12'd148:
                data <= 20'h062FF;
            12'd149:
                data <= 20'h065FE;
            12'd150:
                data <= 20'h06400;
            12'd151:
                data <= 20'h06400;
            12'd152:
                data <= 20'h06014;
            12'd153:
                data <= 20'h06180;
            12'd154:
                data <= 20'h062FF;
            12'd155:
                data <= 20'h065FE;
            12'd156:
                data <= 20'h06400;
            12'd157:
                data <= 20'h06400;
            12'd158:
                data <= 20'h06015;
            12'd159:
                data <= 20'h06122; //
            12'd160:
                data <= 20'h06200;
            12'd161:
                data <= 20'h065FE;
            12'd162:
                data <= 20'h06400;
            12'd163:
                data <= 20'h06400;
            12'd164:
                data <= 20'h06016;
            12'd165:
                data <= 20'h0619A;
            12'd166:
                data <= 20'h06200;
            12'd167:
                data <= 20'h065FE;
            12'd168:
                data <= 20'h06400;
            12'd169:
                data <= 20'h06400;
            12'd170:
                data <= 20'h06017;
            12'd171:
                data <= 20'h061E2;
            12'd172:
                data <= 20'h062FF;
            12'd173:
                data <= 20'h065FE;
            12'd174:
                data <= 20'h06400;
            12'd175:
                data <= 20'h06400;
            12'd176:
                data <= 20'h06018;
            12'd177:
                data <= 20'h06147;
            12'd178:
                data <= 20'h062FF;
            12'd179:
                data <= 20'h065FE;
            12'd180:
                data <= 20'h06400;
            12'd181:
                data <= 20'h06400;
            12'd182:
                data <= 20'h06019;
            12'd183:
                data <= 20'h06117;
            12'd184:
                data <= 20'h06200;
            12'd185:
                data <= 20'h065FE;
            12'd186:
                data <= 20'h06400;
            12'd187:
                data <= 20'h06400;
            12'd188:
                data <= 20'h0601A;
            12'd189:
                data <= 20'h061DB;
            12'd190:
                data <= 20'h06200;
            12'd191:
                data <= 20'h065FE;
            12'd192:
                data <= 20'h06400;
            12'd193:
                data <= 20'h06400;
            12'd194:
                data <= 20'h0601B;
            12'd195:
                data <= 20'h061F3;
            12'd196:
                data <= 20'h062FF;
            12'd197:
                data <= 20'h065FE;
            12'd198:
                data <= 20'h06400;
            12'd199:
                data <= 20'h06400;
            12'd200:
                data <= 20'h0601C;
            12'd201:
                data <= 20'h061FF;
            12'd202:
                data <= 20'h062FE;
            12'd203:
                data <= 20'h065FE;
            12'd204:
                data <= 20'h06400;
            12'd205:
                data <= 20'h06400;
            12'd206:
                data <= 20'h0601D;
            12'd207:
                data <= 20'h061FF;
            12'd208:
                data <= 20'h062FF;
            12'd209:
                data <= 20'h065FE;
            12'd210:
                data <= 20'h06400;
            12'd211:
                data <= 20'h06400;
            12'd212:
                data <= 20'h0601E;
            12'd213:
                data <= 20'h0612B;
            12'd214:
                data <= 20'h06201;
            12'd215:
                data <= 20'h065FE;
            12'd216:
                data <= 20'h06400;
            12'd217:
                data <= 20'h06400;
            12'd218:
                data <= 20'h0601F;
            12'd219:
                data <= 20'h06113;
            12'd220:
                data <= 20'h06200;
            12'd221:
                data <= 20'h065FE;
            12'd222:
                data <= 20'h06400;
            12'd223:
                data <= 20'h06400;
            12'd224:
                data <= 20'h06020;
            12'd225:
                data <= 20'h061A5;
            12'd226:
                data <= 20'h062FE;
            12'd227:
                data <= 20'h065FE;
            12'd228:
                data <= 20'h06400;
            12'd229:
                data <= 20'h06400;
            12'd230:
                data <= 20'h06021;
            12'd231:
                data <= 20'h061D7;
            12'd232:
                data <= 20'h062FF;
            12'd233:
                data <= 20'h065FE;
            12'd234:
                data <= 20'h06400;
            12'd235:
                data <= 20'h06400;
            12'd236:
                data <= 20'h06022;
            12'd237:
                data <= 20'h06190;
            12'd238:
                data <= 20'h06201;
            12'd239:
                data <= 20'h065FE;
            12'd240:
                data <= 20'h06400;
            12'd241:
                data <= 20'h06400;
            12'd242:
                data <= 20'h06023;
            12'd243:
                data <= 20'h06146;
            12'd244:
                data <= 20'h06200;
            12'd245:
                data <= 20'h065FE;
            12'd246:
                data <= 20'h06400;
            12'd247:
                data <= 20'h06400;
            12'd248:
                data <= 20'h06024;
            12'd249:
                data <= 20'h06135;
            12'd250:
                data <= 20'h062FE;
            12'd251:
                data <= 20'h065FE;
            12'd252:
                data <= 20'h06400;
            12'd253:
                data <= 20'h06400;
            12'd254:
                data <= 20'h06025;
            12'd255:
                data <= 20'h06197;
            12'd256:
                data <= 20'h062FF;
            12'd257:
                data <= 20'h065FE;
            12'd258:
                data <= 20'h06400;
            12'd259:
                data <= 20'h06400;
            12'd260:
                data <= 20'h06026;
            12'd261:
                data <= 20'h0610E;
            12'd262:
                data <= 20'h06202;
            12'd263:
                data <= 20'h065FE;
            12'd264:
                data <= 20'h06400;
            12'd265:
                data <= 20'h06400;
            12'd266:
                data <= 20'h06027;
            12'd267:
                data <= 20'h06195;
            12'd268:
                data <= 20'h06200;
            12'd269:
                data <= 20'h065FE;
            12'd270:
                data <= 20'h06400;
            12'd271:
                data <= 20'h06400;
            12'd272:
                data <= 20'h06028;
            12'd273:
                data <= 20'h061A7;
            12'd274:
                data <= 20'h062FD;
            12'd275:
                data <= 20'h065FE;
            12'd276:
                data <= 20'h06400;
            12'd277:
                data <= 20'h06400;
            12'd278:
                data <= 20'h06029;
            12'd279:
                data <= 20'h06136;
            12'd280:
                data <= 20'h062FF;
            12'd281:
                data <= 20'h065FE;
            12'd282:
                data <= 20'h06400;
            12'd283:
                data <= 20'h06400;
            12'd284:
                data <= 20'h0602A;
            12'd285:
                data <= 20'h061AE;
            12'd286:
                data <= 20'h06202;
            12'd287:
                data <= 20'h065FE;
            12'd288:
                data <= 20'h06400;
            12'd289:
                data <= 20'h06400;
            12'd290:
                data <= 20'h0602B;
            12'd291:
                data <= 20'h0610D;
            12'd292:
                data <= 20'h06201;
            12'd293:
                data <= 20'h065FE;
            12'd294:
                data <= 20'h06400;
            12'd295:
                data <= 20'h06400;
            12'd296:
                data <= 20'h0602C;
            12'd297:
                data <= 20'h061F0;
            12'd298:
                data <= 20'h062FC;
            12'd299:
                data <= 20'h065FE;
            12'd300:
                data <= 20'h06400;
            12'd301:
                data <= 20'h06400;
            12'd302:
                data <= 20'h0602D;
            12'd303:
                data <= 20'h061A1;
            12'd304:
                data <= 20'h062FE;
            12'd305:
                data <= 20'h065FE;
            12'd306:
                data <= 20'h06400;
            12'd307:
                data <= 20'h06400;
            12'd308:
                data <= 20'h0602E;
            12'd309:
                data <= 20'h06183;
            12'd310:
                data <= 20'h06203;
            12'd311:
                data <= 20'h065FE;
            12'd312:
                data <= 20'h06400;
            12'd313:
                data <= 20'h06400;
            12'd314:
                data <= 20'h0602F;
            12'd315:
                data <= 20'h061C6;
            12'd316:
                data <= 20'h06201;
            12'd317:
                data <= 20'h065FE;
            12'd318:
                data <= 20'h06400;
            12'd319:
                data <= 20'h06400;
            12'd320:
                data <= 20'h06030;
            12'd321:
                data <= 20'h061F3;
            12'd322:
                data <= 20'h062FB;
            12'd323:
                data <= 20'h065FE;
            12'd324:
                data <= 20'h06400;
            12'd325:
                data <= 20'h06400;
            12'd326:
                data <= 20'h06031;
            12'd327:
                data <= 20'h061B6;
            12'd328:
                data <= 20'h062FD;
            12'd329:
                data <= 20'h065FE;
            12'd330:
                data <= 20'h06400;
            12'd331:
                data <= 20'h06400;
            12'd332:
                data <= 20'h06032;
            12'd333:
                data <= 20'h061B7;
            12'd334:
                data <= 20'h06204;
            12'd335:
                data <= 20'h065FE;
            12'd336:
                data <= 20'h06400;
            12'd337:
                data <= 20'h06400;
            12'd338:
                data <= 20'h06033;
            12'd339:
                data <= 20'h061F8;
            12'd340:
                data <= 20'h06202;
            12'd341:
                data <= 20'h065FE;
            12'd342:
                data <= 20'h06400;
            12'd343:
                data <= 20'h06400;
            12'd344:
                data <= 20'h06034;
            12'd345:
                data <= 20'h0616D;
            12'd346:
                data <= 20'h062FA;
            12'd347:
                data <= 20'h065FE;
            12'd348:
                data <= 20'h06400;
            12'd349:
                data <= 20'h06400;
            12'd350:
                data <= 20'h06035;
            12'd351:
                data <= 20'h0611A;
            12'd352:
                data <= 20'h062FC;
            12'd353:
                data <= 20'h065FE;
            12'd354:
                data <= 20'h06400;
            12'd355:
                data <= 20'h06400;
            12'd356:
                data <= 20'h06036;
            12'd357:
                data <= 20'h061BE;
            12'd358:
                data <= 20'h06206;
            12'd359:
                data <= 20'h065FE;
            12'd360:
                data <= 20'h06400;
            12'd361:
                data <= 20'h06400;
            12'd362:
                data <= 20'h06037;
            12'd363:
                data <= 20'h06141;
            12'd364:
                data <= 20'h06205;
            12'd365:
                data <= 20'h065FE;
            12'd366:
                data <= 20'h06400;
            12'd367:
                data <= 20'h06400;
            12'd368:
                data <= 20'h06038;
            12'd369:
                data <= 20'h06187;
            12'd370:
                data <= 20'h062F7;
            12'd371:
                data <= 20'h065FE;
            12'd372:
                data <= 20'h06400;
            12'd373:
                data <= 20'h06400;
            12'd374:
                data <= 20'h06039;
            12'd375:
                data <= 20'h06198;
            12'd376:
                data <= 20'h062F8;
            12'd377:
                data <= 20'h065FE;
            12'd378:
                data <= 20'h06400;
            12'd379:
                data <= 20'h06400;
            12'd380:
                data <= 20'h0603A;
            12'd381:
                data <= 20'h06160;
            12'd382:
                data <= 20'h0620B;
            12'd383:
                data <= 20'h065FE;
            12'd384:
                data <= 20'h06400;
            12'd385:
                data <= 20'h06400;
            12'd386:
                data <= 20'h0603B;
            12'd387:
                data <= 20'h0616D;
            12'd388:
                data <= 20'h0620B;
            12'd389:
                data <= 20'h065FE;
            12'd390:
                data <= 20'h06400;
            12'd391:
                data <= 20'h06400;
            12'd392:
                data <= 20'h0603C;
            12'd393:
                data <= 20'h06188;
            12'd394:
                data <= 20'h062EE;
            12'd395:
                data <= 20'h065FE;
            12'd396:
                data <= 20'h06400;
            12'd397:
                data <= 20'h06400;
            12'd398:
                data <= 20'h0603D;
            12'd399:
                data <= 20'h06140;
            12'd400:
                data <= 20'h062EA;
            12'd401:
                data <= 20'h065FE;
            12'd402:
                data <= 20'h06400;
            12'd403:
                data <= 20'h06400;
            12'd404:
                data <= 20'h0603E;
            12'd405:
                data <= 20'h06186;
            12'd406:
                data <= 20'h06227;
            12'd407:
                data <= 20'h065FE;
            12'd408:
                data <= 20'h06400;
            12'd409:
                data <= 20'h06400;
            12'd410:
                data <= 20'h0603F;
            12'd411:
                data <= 20'h06109;
            12'd412:
                data <= 20'h06272;
            12'd413:
                data <= 20'h065FE;
            12'd414:
                data <= 20'h06400;
            12'd415:
                data <= 20'h06400;
            12'd416:
                data <= 20'h06040;
            12'd417:
                data <= 20'h06109;
            12'd418:
                data <= 20'h06272;
            12'd419:
                data <= 20'h065FE;
            12'd420:
                data <= 20'h06400;
            12'd421:
                data <= 20'h06400;
            12'd422:
                data <= 20'h06041;
            12'd423:
                data <= 20'h06186;
            12'd424:
                data <= 20'h06227;
            12'd425:
                data <= 20'h065FE;
            12'd426:
                data <= 20'h06400;
            12'd427:
                data <= 20'h06400;
            12'd428:
                data <= 20'h06042;
            12'd429:
                data <= 20'h06140;
            12'd430:
                data <= 20'h062EA;
            12'd431:
                data <= 20'h065FE;
            12'd432:
                data <= 20'h06400;
            12'd433:
                data <= 20'h06400;
            12'd434:
                data <= 20'h06043;
            12'd435:
                data <= 20'h06188;
            12'd436:
                data <= 20'h062EE;
            12'd437:
                data <= 20'h065FE;
            12'd438:
                data <= 20'h06400;
            12'd439:
                data <= 20'h06400;
            12'd440:
                data <= 20'h06044;
            12'd441:
                data <= 20'h0616D;
            12'd442:
                data <= 20'h0620B;
            12'd443:
                data <= 20'h065FE;
            12'd444:
                data <= 20'h06400;
            12'd445:
                data <= 20'h06400;
            12'd446:
                data <= 20'h06045;
            12'd447:
                data <= 20'h06160;
            12'd448:
                data <= 20'h0620B;
            12'd449:
                data <= 20'h065FE;
            12'd450:
                data <= 20'h06400;
            12'd451:
                data <= 20'h06400;
            12'd452:
                data <= 20'h06046;
            12'd453:
                data <= 20'h06198;
            12'd454:
                data <= 20'h062F8;
            12'd455:
                data <= 20'h065FE;
            12'd456:
                data <= 20'h06400;
            12'd457:
                data <= 20'h06400;
            12'd458:
                data <= 20'h06047;
            12'd459:
                data <= 20'h06187;
            12'd460:
                data <= 20'h062F7;
            12'd461:
                data <= 20'h065FE;
            12'd462:
                data <= 20'h06400;
            12'd463:
                data <= 20'h06400;
            12'd464:
                data <= 20'h06048;
            12'd465:
                data <= 20'h06141;
            12'd466:
                data <= 20'h06205;
            12'd467:
                data <= 20'h065FE;
            12'd468:
                data <= 20'h06400;
            12'd469:
                data <= 20'h06400;
            12'd470:
                data <= 20'h06049;
            12'd471:
                data <= 20'h061BE;
            12'd472:
                data <= 20'h06206;
            12'd473:
                data <= 20'h065FE;
            12'd474:
                data <= 20'h06400;
            12'd475:
                data <= 20'h06400;
            12'd476:
                data <= 20'h0604A;
            12'd477:
                data <= 20'h0611A;
            12'd478:
                data <= 20'h062FC;
            12'd479:
                data <= 20'h065FE;
            12'd480:
                data <= 20'h06400;
            12'd481:
                data <= 20'h06400;
            12'd482:
                data <= 20'h0604B;
            12'd483:
                data <= 20'h0616D;
            12'd484:
                data <= 20'h062FA;
            12'd485:
                data <= 20'h065FE;
            12'd486:
                data <= 20'h06400;
            12'd487:
                data <= 20'h06400;
            12'd488:
                data <= 20'h0604C;
            12'd489:
                data <= 20'h061F8;
            12'd490:
                data <= 20'h06202;
            12'd491:
                data <= 20'h065FE;
            12'd492:
                data <= 20'h06400;
            12'd493:
                data <= 20'h06400;
            12'd494:
                data <= 20'h0604D;
            12'd495:
                data <= 20'h061B7;
            12'd496:
                data <= 20'h06204;
            12'd497:
                data <= 20'h065FE;
            12'd498:
                data <= 20'h06400;
            12'd499:
                data <= 20'h06400;
            12'd500:
                data <= 20'h0604E;
            12'd501:
                data <= 20'h061B6;
            12'd502:
                data <= 20'h062FD;
            12'd503:
                data <= 20'h065FE;
            12'd504:
                data <= 20'h06400;
            12'd505:
                data <= 20'h06400;
            12'd506:
                data <= 20'h0604F;
            12'd507:
                data <= 20'h061F3;
            12'd508:
                data <= 20'h062FB;
            12'd509:
                data <= 20'h065FE;
            12'd510:
                data <= 20'h06400;
            12'd511:
                data <= 20'h06400;
            12'd512:
                data <= 20'h06050;
            12'd513:
                data <= 20'h061C6;
            12'd514:
                data <= 20'h06201;
            12'd515:
                data <= 20'h065FE;
            12'd516:
                data <= 20'h06400;
            12'd517:
                data <= 20'h06400;
            12'd518:
                data <= 20'h06051;
            12'd519:
                data <= 20'h06183;
            12'd520:
                data <= 20'h06203;
            12'd521:
                data <= 20'h065FE;
            12'd522:
                data <= 20'h06400;
            12'd523:
                data <= 20'h06400;
            12'd524:
                data <= 20'h06052;
            12'd525:
                data <= 20'h061A1;
            12'd526:
                data <= 20'h062FE;
            12'd527:
                data <= 20'h065FE;
            12'd528:
                data <= 20'h06400;
            12'd529:
                data <= 20'h06400;
            12'd530:
                data <= 20'h06053;
            12'd531:
                data <= 20'h061F0;
            12'd532:
                data <= 20'h062FC;
            12'd533:
                data <= 20'h065FE;
            12'd534:
                data <= 20'h06400;
            12'd535:
                data <= 20'h06400;
            12'd536:
                data <= 20'h06054;
            12'd537:
                data <= 20'h0610D;
            12'd538:
                data <= 20'h06201;
            12'd539:
                data <= 20'h065FE;
            12'd540:
                data <= 20'h06400;
            12'd541:
                data <= 20'h06400;
            12'd542:
                data <= 20'h06055;
            12'd543:
                data <= 20'h061AE;
            12'd544:
                data <= 20'h06202;
            12'd545:
                data <= 20'h065FE;
            12'd546:
                data <= 20'h06400;
            12'd547:
                data <= 20'h06400;
            12'd548:
                data <= 20'h06056;
            12'd549:
                data <= 20'h06136;
            12'd550:
                data <= 20'h062FF;
            12'd551:
                data <= 20'h065FE;
            12'd552:
                data <= 20'h06400;
            12'd553:
                data <= 20'h06400;
            12'd554:
                data <= 20'h06057;
            12'd555:
                data <= 20'h061A7;
            12'd556:
                data <= 20'h062FD;
            12'd557:
                data <= 20'h065FE;
            12'd558:
                data <= 20'h06400;
            12'd559:
                data <= 20'h06400;
            12'd560:
                data <= 20'h06058;
            12'd561:
                data <= 20'h06195;
            12'd562:
                data <= 20'h06200;
            12'd563:
                data <= 20'h065FE;
            12'd564:
                data <= 20'h06400;
            12'd565:
                data <= 20'h06400;
            12'd566:
                data <= 20'h06059;
            12'd567:
                data <= 20'h0610E;
            12'd568:
                data <= 20'h06202;
            12'd569:
                data <= 20'h065FE;
            12'd570:
                data <= 20'h06400;
            12'd571:
                data <= 20'h06400;
            12'd572:
                data <= 20'h0605A;
            12'd573:
                data <= 20'h06197;
            12'd574:
                data <= 20'h062FF;
            12'd575:
                data <= 20'h065FE;
            12'd576:
                data <= 20'h06400;
            12'd577:
                data <= 20'h06400;
            12'd578:
                data <= 20'h0605B;
            12'd579:
                data <= 20'h06135;
            12'd580:
                data <= 20'h062FE;
            12'd581:
                data <= 20'h065FE;
            12'd582:
                data <= 20'h06400;
            12'd583:
                data <= 20'h06400;
            12'd584:
                data <= 20'h0605C;
            12'd585:
                data <= 20'h06146;
            12'd586:
                data <= 20'h06200;
            12'd587:
                data <= 20'h065FE;
            12'd588:
                data <= 20'h06400;
            12'd589:
                data <= 20'h06400;
            12'd590:
                data <= 20'h0605D;
            12'd591:
                data <= 20'h06190;
            12'd592:
                data <= 20'h06201;
            12'd593:
                data <= 20'h065FE;
            12'd594:
                data <= 20'h06400;
            12'd595:
                data <= 20'h06400;
            12'd596:
                data <= 20'h0605E;
            12'd597:
                data <= 20'h061D7;
            12'd598:
                data <= 20'h062FF;
            12'd599:
                data <= 20'h065FE;
            12'd600:
                data <= 20'h06400;
            12'd601:
                data <= 20'h06400;
            12'd602:
                data <= 20'h0605F;
            12'd603:
                data <= 20'h061A5;
            12'd604:
                data <= 20'h062FE;
            12'd605:
                data <= 20'h065FE;
            12'd606:
                data <= 20'h06400;
            12'd607:
                data <= 20'h06400;
            12'd608:
                data <= 20'h06060;
            12'd609:
                data <= 20'h06113;
            12'd610:
                data <= 20'h06200;
            12'd611:
                data <= 20'h065FE;
            12'd612:
                data <= 20'h06400;
            12'd613:
                data <= 20'h06400;
            12'd614:
                data <= 20'h06061;
            12'd615:
                data <= 20'h0612B;
            12'd616:
                data <= 20'h06201;
            12'd617:
                data <= 20'h065FE;
            12'd618:
                data <= 20'h06400;
            12'd619:
                data <= 20'h06400;
            12'd620:
                data <= 20'h06062;
            12'd621:
                data <= 20'h061FF;
            12'd622:
                data <= 20'h062FF;
            12'd623:
                data <= 20'h065FE;
            12'd624:
                data <= 20'h06400;
            12'd625:
                data <= 20'h06400;
            12'd626:
                data <= 20'h06063;
            12'd627:
                data <= 20'h061FF;
            12'd628:
                data <= 20'h062FE;
            12'd629:
                data <= 20'h065FE;
            12'd630:
                data <= 20'h06400;
            12'd631:
                data <= 20'h06400;
            12'd632:
                data <= 20'h06064;
            12'd633:
                data <= 20'h061F3;
            12'd634:
                data <= 20'h062FF;
            12'd635:
                data <= 20'h065FE;
            12'd636:
                data <= 20'h06400;
            12'd637:
                data <= 20'h06400;
            12'd638:
                data <= 20'h06065;
            12'd639:
                data <= 20'h061DB;
            12'd640:
                data <= 20'h06200;
            12'd641:
                data <= 20'h065FE;
            12'd642:
                data <= 20'h06400;
            12'd643:
                data <= 20'h06400;
            12'd644:
                data <= 20'h06066;
            12'd645:
                data <= 20'h06117;
            12'd646:
                data <= 20'h06200;
            12'd647:
                data <= 20'h065FE;
            12'd648:
                data <= 20'h06400;
            12'd649:
                data <= 20'h06400;
            12'd650:
                data <= 20'h06067;
            12'd651:
                data <= 20'h06147;
            12'd652:
                data <= 20'h062FF;
            12'd653:
                data <= 20'h065FE;
            12'd654:
                data <= 20'h06400;
            12'd655:
                data <= 20'h06400;
            12'd656:
                data <= 20'h06068;
            12'd657:
                data <= 20'h061E2;
            12'd658:
                data <= 20'h062FF;
            12'd659:
                data <= 20'h065FE;
            12'd660:
                data <= 20'h06400;
            12'd661:
                data <= 20'h06400;
            12'd662:
                data <= 20'h06069;
            12'd663:
                data <= 20'h0619A;
            12'd664:
                data <= 20'h06200;
            12'd665:
                data <= 20'h065FE;
            12'd666:
                data <= 20'h06400;
            12'd667:
                data <= 20'h06400;
            12'd668:
                data <= 20'h0606A;
            12'd669:
                data <= 20'h06122;
            12'd670:
                data <= 20'h06200;
            12'd671:
                data <= 20'h065FE;
            12'd672:
                data <= 20'h06400;
            12'd673:
                data <= 20'h06400;
            12'd674:
                data <= 20'h0606B;
            12'd675:
                data <= 20'h06180;
            12'd676:
                data <= 20'h062FF;
            12'd677:
                data <= 20'h065FE;
            12'd678:
                data <= 20'h06400;
            12'd679:
                data <= 20'h06400;
            12'd680:
                data <= 20'h0606C;
            12'd681:
                data <= 20'h061DB;
            12'd682:
                data <= 20'h062FF;
            12'd683:
                data <= 20'h065FE;
            12'd684:
                data <= 20'h06400;
            12'd685:
                data <= 20'h06400;
            12'd686:
                data <= 20'h0606D;
            12'd687:
                data <= 20'h06168;
            12'd688:
                data <= 20'h06200;
            12'd689:
                data <= 20'h065FE;
            12'd690:
                data <= 20'h06400;
            12'd691:
                data <= 20'h06400;
            12'd692:
                data <= 20'h0606E;
            12'd693:
                data <= 20'h06126;
            12'd694:
                data <= 20'h06200;
            12'd695:
                data <= 20'h065FE;
            12'd696:
                data <= 20'h06400;
            12'd697:
                data <= 20'h06400;
            12'd698:
                data <= 20'h0606F;
            12'd699:
                data <= 20'h061AC;
            12'd700:
                data <= 20'h062FF;
            12'd701:
                data <= 20'h065FE;
            12'd702:
                data <= 20'h06400;
            12'd703:
                data <= 20'h06400;
            12'd704:
                data <= 20'h06070;
            12'd705:
                data <= 20'h061DB;
            12'd706:
                data <= 20'h062FF;
            12'd707:
                data <= 20'h065FE;
            12'd708:
                data <= 20'h06400;
            12'd709:
                data <= 20'h06400;
            12'd710:
                data <= 20'h06071;
            12'd711:
                data <= 20'h06143;
            12'd712:
                data <= 20'h06200;
            12'd713:
                data <= 20'h065FE;
            12'd714:
                data <= 20'h06400;
            12'd715:
                data <= 20'h06400;
            12'd716:
                data <= 20'h06072;
            12'd717:
                data <= 20'h06124;
            12'd718:
                data <= 20'h06200;
            12'd719:
                data <= 20'h065FE;
            12'd720:
                data <= 20'h06400;
            12'd721:
                data <= 20'h06400;
            12'd722:
                data <= 20'h06073;
            12'd723:
                data <= 20'h061CC;
            12'd724:
                data <= 20'h062FF;
            12'd725:
                data <= 20'h065FE;
            12'd726:
                data <= 20'h06400;
            12'd727:
                data <= 20'h06400;
            12'd728:
                data <= 20'h06074;
            12'd729:
                data <= 20'h061DF;
            12'd730:
                data <= 20'h062FF;
            12'd731:
                data <= 20'h065FE;
            12'd732:
                data <= 20'h06400;
            12'd733:
                data <= 20'h06400;
            12'd734:
                data <= 20'h06075;
            12'd735:
                data <= 20'h06128;
            12'd736:
                data <= 20'h06200;
            12'd737:
                data <= 20'h065FE;
            12'd738:
                data <= 20'h06400;
            12'd739:
                data <= 20'h06400;
            12'd740:
                data <= 20'h06076;
            12'd741:
                data <= 20'h0611F;
            12'd742:
                data <= 20'h06200;
            12'd743:
                data <= 20'h065FE;
            12'd744:
                data <= 20'h06400;
            12'd745:
                data <= 20'h06400;
            12'd746:
                data <= 20'h06077;
            12'd747:
                data <= 20'h061E1;
            12'd748:
                data <= 20'h062FF;
            12'd749:
                data <= 20'h065FE;
            12'd750:
                data <= 20'h06400;
            12'd751:
                data <= 20'h06400;
            12'd752:
                data <= 20'h06078;
            12'd753:
                data <= 20'h061E3;
            12'd754:
                data <= 20'h062FF;
            12'd755:
                data <= 20'h065FE;
            12'd756:
                data <= 20'h06400;
            12'd757:
                data <= 20'h06400;
            12'd758:
                data <= 20'h06079;
            12'd759:
                data <= 20'h0611A;
            12'd760:
                data <= 20'h06200;
            12'd761:
                data <= 20'h065FE;
            12'd762:
                data <= 20'h06400;
            12'd763:
                data <= 20'h06400;
            12'd764:
                data <= 20'h0607A;
            12'd765:
                data <= 20'h06120;
            12'd766:
                data <= 20'h06200;
            12'd767:
                data <= 20'h065FE;
            12'd768:
                data <= 20'h06400;
            12'd769:
                data <= 20'h06400;
            12'd770:
                data <= 20'h0607B;
            12'd771:
                data <= 20'h061E8;
            12'd772:
                data <= 20'h062FF;
            12'd773:
                data <= 20'h065FE;
            12'd774:
                data <= 20'h06400;
            12'd775:
                data <= 20'h06400;
            12'd776:
                data <= 20'h0607C;
            12'd777:
                data <= 20'h061C0;
            12'd778:
                data <= 20'h062FF;
            12'd779:
                data <= 20'h065FE;
            12'd780:
                data <= 20'h06400;
            12'd781:
                data <= 20'h06400;
            12'd782:
                data <= 20'h0607D;
            12'd783:
                data <= 20'h061CF;
            12'd784:
                data <= 20'h062FF;
            12'd785:
                data <= 20'h065FE;
            12'd786:
                data <= 20'h06400;
            12'd787:
                data <= 20'h06400;
            12'd788:
                data <= 20'h0607E;
            12'd789:
                data <= 20'h061F1;
            12'd790:
                data <= 20'h062FF;
            12'd791:
                data <= 20'h065FE;
            12'd792:
                data <= 20'h06400;
            12'd793:
                data <= 20'h06400;
            12'd794:
                data <= 20'h0607F;
            12'd795:
                data <= 20'h06101;
            12'd796:
                data <= 20'h06200;
            12'd797:
                data <= 20'h065FE;
            12'd798:
                data <= 20'h06400;
            12'd799:
                data <= 20'h06400;
            12'd800:
                data <= 20'h065F8;

            //rx fir
            12'd801:
                data <= 20'h0F5FA;
            12'd802:
                data <= 20'h0F602;
            12'd803:
                data <= 20'h0F000;
            12'd804:
                data <= 20'h0F101;
            12'd805:
                data <= 20'h0F200;
            12'd806:
                data <= 20'h0F5FE;
            12'd807:
                data <= 20'h0F400;
            12'd808:
                data <= 20'h0F400;
            12'd809:
                data <= 20'h0F001;
            12'd810:
                data <= 20'h0F1F1;
            12'd811:
                data <= 20'h0F2FF;
            12'd812:
                data <= 20'h0F5FE;
            12'd813:
                data <= 20'h0F400;
            12'd814:
                data <= 20'h0F400;
            12'd815:
                data <= 20'h0F002;
            12'd816:
                data <= 20'h0F1CF;
            12'd817:
                data <= 20'h0F2FF;
            12'd818:
                data <= 20'h0F5FE;
            12'd819:
                data <= 20'h0F400;
            12'd820:
                data <= 20'h0F400;
            12'd821:
                data <= 20'h0F003;
            12'd822:
                data <= 20'h0F1C0;
            12'd823:
                data <= 20'h0F2FF;
            12'd824:
                data <= 20'h0F5FE;
            12'd825:
                data <= 20'h0F400;
            12'd826:
                data <= 20'h0F400;
            12'd827:
                data <= 20'h0F004;
            12'd828:
                data <= 20'h0F1E8;
            12'd829:
                data <= 20'h0F2FF;
            12'd830:
                data <= 20'h0F5FE;
            12'd831:
                data <= 20'h0F400;
            12'd832:
                data <= 20'h0F400;
            12'd833:
                data <= 20'h0F005;
            12'd834:
                data <= 20'h0F120;
            12'd835:
                data <= 20'h0F200;
            12'd836:
                data <= 20'h0F5FE;
            12'd837:
                data <= 20'h0F400;
            12'd838:
                data <= 20'h0F400;
            12'd839:
                data <= 20'h0F006;
            12'd840:
                data <= 20'h0F11A;
            12'd841:
                data <= 20'h0F200;
            12'd842:
                data <= 20'h0F5FE;
            12'd843:
                data <= 20'h0F400;
            12'd844:
                data <= 20'h0F400;
            12'd845:
                data <= 20'h0F007;
            12'd846:
                data <= 20'h0F1E3;
            12'd847:
                data <= 20'h0F2FF;
            12'd848:
                data <= 20'h0F5FE;
            12'd849:
                data <= 20'h0F400;
            12'd850:
                data <= 20'h0F400;
            12'd851:
                data <= 20'h0F008;
            12'd852:
                data <= 20'h0F1E1;
            12'd853:
                data <= 20'h0F2FF;
            12'd854:
                data <= 20'h0F5FE;
            12'd855:
                data <= 20'h0F400;
            12'd856:
                data <= 20'h0F400;
            12'd857:
                data <= 20'h0F009;
            12'd858:
                data <= 20'h0F11F;
            12'd859:
                data <= 20'h0F200;
            12'd860:
                data <= 20'h0F5FE;
            12'd861:
                data <= 20'h0F400;
            12'd862:
                data <= 20'h0F400;
            12'd863:
                data <= 20'h0F00A;
            12'd864:
                data <= 20'h0F128;
            12'd865:
                data <= 20'h0F200;
            12'd866:
                data <= 20'h0F5FE;
            12'd867:
                data <= 20'h0F400;
            12'd868:
                data <= 20'h0F400;
            12'd869:
                data <= 20'h0F00B;
            12'd870:
                data <= 20'h0F1DF;
            12'd871:
                data <= 20'h0F2FF;
            12'd872:
                data <= 20'h0F5FE;
            12'd873:
                data <= 20'h0F400;
            12'd874:
                data <= 20'h0F400;
            12'd875:
                data <= 20'h0F00C;
            12'd876:
                data <= 20'h0F1CC;
            12'd877:
                data <= 20'h0F2FF;
            12'd878:
                data <= 20'h0F5FE;
            12'd879:
                data <= 20'h0F400;
            12'd880:
                data <= 20'h0F400;
            12'd881:
                data <= 20'h0F00D;
            12'd882:
                data <= 20'h0F124;
            12'd883:
                data <= 20'h0F200;
            12'd884:
                data <= 20'h0F5FE;
            12'd885:
                data <= 20'h0F400;
            12'd886:
                data <= 20'h0F400;
            12'd887:
                data <= 20'h0F00E;
            12'd888:
                data <= 20'h0F143;
            12'd889:
                data <= 20'h0F200;
            12'd890:
                data <= 20'h0F5FE;
            12'd891:
                data <= 20'h0F400;
            12'd892:
                data <= 20'h0F400;
            12'd893:
                data <= 20'h0F00F;
            12'd894:
                data <= 20'h0F1DB;
            12'd895:
                data <= 20'h0F2FF;
            12'd896:
                data <= 20'h0F5FE;
            12'd897:
                data <= 20'h0F400;
            12'd898:
                data <= 20'h0F400;
            12'd899:
                data <= 20'h0F010;
            12'd900:
                data <= 20'h0F1AC;
            12'd901:
                data <= 20'h0F2FF;
            12'd902:
                data <= 20'h0F5FE;
            12'd903:
                data <= 20'h0F400;
            12'd904:
                data <= 20'h0F400;
            12'd905:
                data <= 20'h0F011;
            12'd906:
                data <= 20'h0F126;
            12'd907:
                data <= 20'h0F200;
            12'd908:
                data <= 20'h0F5FE;
            12'd909:
                data <= 20'h0F400;
            12'd910:
                data <= 20'h0F400;
            12'd911:
                data <= 20'h0F012;
            12'd912:
                data <= 20'h0F168;
            12'd913:
                data <= 20'h0F200;
            12'd914:
                data <= 20'h0F5FE;
            12'd915:
                data <= 20'h0F400;
            12'd916:
                data <= 20'h0F400;
            12'd917:
                data <= 20'h0F013;
            12'd918:
                data <= 20'h0F1DB;
            12'd919:
                data <= 20'h0F2FF;
            12'd920:
                data <= 20'h0F5FE;
            12'd921:
                data <= 20'h0F400;
            12'd922:
                data <= 20'h0F400;
            12'd923:
                data <= 20'h0F014;
            12'd924:
                data <= 20'h0F180;
            12'd925:
                data <= 20'h0F2FF;
            12'd926:
                data <= 20'h0F5FE;
            12'd927:
                data <= 20'h0F400;
            12'd928:
                data <= 20'h0F400;
            12'd929:
                data <= 20'h0F015;
            12'd930:
                data <= 20'h0F122;
            12'd931:
                data <= 20'h0F200;
            12'd932:
                data <= 20'h0F5FE;
            12'd933:
                data <= 20'h0F400;
            12'd934:
                data <= 20'h0F400;
            12'd935:
                data <= 20'h0F016;
            12'd936:
                data <= 20'h0F19A;
            12'd937:
                data <= 20'h0F200;
            12'd938:
                data <= 20'h0F5FE;
            12'd939:
                data <= 20'h0F400;
            12'd940:
                data <= 20'h0F400;
            12'd941:
                data <= 20'h0F017;
            12'd942:
                data <= 20'h0F1E2;
            12'd943:
                data <= 20'h0F2FF;
            12'd944:
                data <= 20'h0F5FE;
            12'd945:
                data <= 20'h0F400;
            12'd946:
                data <= 20'h0F400;
            12'd947:
                data <= 20'h0F018;
            12'd948:
                data <= 20'h0F147;
            12'd949:
                data <= 20'h0F2FF;
            12'd950:
                data <= 20'h0F5FE;
            12'd951:
                data <= 20'h0F400;
            12'd952:
                data <= 20'h0F400;
            12'd953:
                data <= 20'h0F019;
            12'd954:
                data <= 20'h0F117;
            12'd955:
                data <= 20'h0F200;
            12'd956:
                data <= 20'h0F5FE;
            12'd957:
                data <= 20'h0F400;
            12'd958:
                data <= 20'h0F400;
            12'd959:
                data <= 20'h0F01A;
            12'd960:
                data <= 20'h0F1DB;
            12'd961:
                data <= 20'h0F200;
            12'd962:
                data <= 20'h0F5FE;
            12'd963:
                data <= 20'h0F400;
            12'd964:
                data <= 20'h0F400;
            12'd965:
                data <= 20'h0F01B;
            12'd966:
                data <= 20'h0F1F3;
            12'd967:
                data <= 20'h0F2FF;
            12'd968:
                data <= 20'h0F5FE;
            12'd969:
                data <= 20'h0F400;
            12'd970:
                data <= 20'h0F400;
            12'd971:
                data <= 20'h0F01C;
            12'd972:
                data <= 20'h0F1FF;
            12'd973:
                data <= 20'h0F2FE;
            12'd974:
                data <= 20'h0F5FE;
            12'd975:
                data <= 20'h0F400;
            12'd976:
                data <= 20'h0F400;
            12'd977:
                data <= 20'h0F01D;
            12'd978:
                data <= 20'h0F1FF;
            12'd979:
                data <= 20'h0F2FF;
            12'd980:
                data <= 20'h0F5FE;
            12'd981:
                data <= 20'h0F400;
            12'd982:
                data <= 20'h0F400;
            12'd983:
                data <= 20'h0F01E;
            12'd984:
                data <= 20'h0F12B;
            12'd985:
                data <= 20'h0F201;
            12'd986:
                data <= 20'h0F5FE;
            12'd987:
                data <= 20'h0F400;
            12'd988:
                data <= 20'h0F400;
            12'd989:
                data <= 20'h0F01F;
            12'd990:
                data <= 20'h0F113;
            12'd991:
                data <= 20'h0F200;
            12'd992:
                data <= 20'h0F5FE;
            12'd993:
                data <= 20'h0F400;
            12'd994:
                data <= 20'h0F400;
            12'd995:
                data <= 20'h0F020;
            12'd996:
                data <= 20'h0F1A5;
            12'd997:
                data <= 20'h0F2FE;
            12'd998:
                data <= 20'h0F5FE;
            12'd999:
                data <= 20'h0F400;
            12'd1000:
                data <= 20'h0F400;
            12'd1001:
                data <= 20'h0F021;
            12'd1002:
                data <= 20'h0F1D7;
            12'd1003:
                data <= 20'h0F2FF;
            12'd1004:
                data <= 20'h0F5FE;
            12'd1005:
                data <= 20'h0F400;
            12'd1006:
                data <= 20'h0F400;
            12'd1007:
                data <= 20'h0F022;
            12'd1008:
                data <= 20'h0F190;
            12'd1009:
                data <= 20'h0F201;
            12'd1010:
                data <= 20'h0F5FE;
            12'd1011:
                data <= 20'h0F400;
            12'd1012:
                data <= 20'h0F400;
            12'd1013:
                data <= 20'h0F023;
            12'd1014:
                data <= 20'h0F146;
            12'd1015:
                data <= 20'h0F200;
            12'd1016:
                data <= 20'h0F5FE;
            12'd1017:
                data <= 20'h0F400;
            12'd1018:
                data <= 20'h0F400;
            12'd1019:
                data <= 20'h0F024;
            12'd1020:
                data <= 20'h0F135;
            12'd1021:
                data <= 20'h0F2FE;
            12'd1022:
                data <= 20'h0F5FE;
            12'd1023:
                data <= 20'h0F400;
            12'd1024:
                data <= 20'h0F400;
            12'd1025:
                data <= 20'h0F025;
            12'd1026:
                data <= 20'h0F197;
            12'd1027:
                data <= 20'h0F2FF;
            12'd1028:
                data <= 20'h0F5FE;
            12'd1029:
                data <= 20'h0F400;
            12'd1030:
                data <= 20'h0F400;
            12'd1031:
                data <= 20'h0F026;
            12'd1032:
                data <= 20'h0F10E;
            12'd1033:
                data <= 20'h0F202;
            12'd1034:
                data <= 20'h0F5FE;
            12'd1035:
                data <= 20'h0F400;
            12'd1036:
                data <= 20'h0F400;
            12'd1037:
                data <= 20'h0F027;
            12'd1038:
                data <= 20'h0F195;
            12'd1039:
                data <= 20'h0F200;
            12'd1040:
                data <= 20'h0F5FE;
            12'd1041:
                data <= 20'h0F400;
            12'd1042:
                data <= 20'h0F400;
            12'd1043:
                data <= 20'h0F028;
            12'd1044:
                data <= 20'h0F1A7;
            12'd1045:
                data <= 20'h0F2FD;
            12'd1046:
                data <= 20'h0F5FE;
            12'd1047:
                data <= 20'h0F400;
            12'd1048:
                data <= 20'h0F400;
            12'd1049:
                data <= 20'h0F029;
            12'd1050:
                data <= 20'h0F136;
            12'd1051:
                data <= 20'h0F2FF;
            12'd1052:
                data <= 20'h0F5FE;
            12'd1053:
                data <= 20'h0F400;
            12'd1054:
                data <= 20'h0F400;
            12'd1055:
                data <= 20'h0F02A;
            12'd1056:
                data <= 20'h0F1AE;
            12'd1057:
                data <= 20'h0F202;
            12'd1058:
                data <= 20'h0F5FE;
            12'd1059:
                data <= 20'h0F400;
            12'd1060:
                data <= 20'h0F400;
            12'd1061:
                data <= 20'h0F02B;
            12'd1062:
                data <= 20'h0F10D;
            12'd1063:
                data <= 20'h0F201;
            12'd1064:
                data <= 20'h0F5FE;
            12'd1065:
                data <= 20'h0F400;
            12'd1066:
                data <= 20'h0F400;
            12'd1067:
                data <= 20'h0F02C;
            12'd1068:
                data <= 20'h0F1F0;
            12'd1069:
                data <= 20'h0F2FC;
            12'd1070:
                data <= 20'h0F5FE;
            12'd1071:
                data <= 20'h0F400;
            12'd1072:
                data <= 20'h0F400;
            12'd1073:
                data <= 20'h0F02D;
            12'd1074:
                data <= 20'h0F1A1;
            12'd1075:
                data <= 20'h0F2FE;
            12'd1076:
                data <= 20'h0F5FE;
            12'd1077:
                data <= 20'h0F400;
            12'd1078:
                data <= 20'h0F400;
            12'd1079:
                data <= 20'h0F02E;
            12'd1080:
                data <= 20'h0F183;
            12'd1081:
                data <= 20'h0F203;
            12'd1082:
                data <= 20'h0F5FE;
            12'd1083:
                data <= 20'h0F400;
            12'd1084:
                data <= 20'h0F400;
            12'd1085:
                data <= 20'h0F02F;
            12'd1086:
                data <= 20'h0F1C6;
            12'd1087:
                data <= 20'h0F201;
            12'd1088:
                data <= 20'h0F5FE;
            12'd1089:
                data <= 20'h0F400;
            12'd1090:
                data <= 20'h0F400;
            12'd1091:
                data <= 20'h0F030;
            12'd1092:
                data <= 20'h0F1F3;
            12'd1093:
                data <= 20'h0F2FB;
            12'd1094:
                data <= 20'h0F5FE;
            12'd1095:
                data <= 20'h0F400;
            12'd1096:
                data <= 20'h0F400;
            12'd1097:
                data <= 20'h0F031;
            12'd1098:
                data <= 20'h0F1B6;
            12'd1099:
                data <= 20'h0F2FD;
            12'd1100:
                data <= 20'h0F5FE;
            12'd1101:
                data <= 20'h0F400;
            12'd1102:
                data <= 20'h0F400;
            12'd1103:
                data <= 20'h0F032;
            12'd1104:
                data <= 20'h0F1B7;
            12'd1105:
                data <= 20'h0F204;
            12'd1106:
                data <= 20'h0F5FE;
            12'd1107:
                data <= 20'h0F400;
            12'd1108:
                data <= 20'h0F400;
            12'd1109:
                data <= 20'h0F033;
            12'd1110:
                data <= 20'h0F1F8;
            12'd1111:
                data <= 20'h0F202;
            12'd1112:
                data <= 20'h0F5FE;
            12'd1113:
                data <= 20'h0F400;
            12'd1114:
                data <= 20'h0F400;
            12'd1115:
                data <= 20'h0F034;
            12'd1116:
                data <= 20'h0F16D;
            12'd1117:
                data <= 20'h0F2FA;
            12'd1118:
                data <= 20'h0F5FE;
            12'd1119:
                data <= 20'h0F400;
            12'd1120:
                data <= 20'h0F400;
            12'd1121:
                data <= 20'h0F035;
            12'd1122:
                data <= 20'h0F11A;
            12'd1123:
                data <= 20'h0F2FC;
            12'd1124:
                data <= 20'h0F5FE;
            12'd1125:
                data <= 20'h0F400;
            12'd1126:
                data <= 20'h0F400;
            12'd1127:
                data <= 20'h0F036;
            12'd1128:
                data <= 20'h0F1BE;
            12'd1129:
                data <= 20'h0F206;
            12'd1130:
                data <= 20'h0F5FE;
            12'd1131:
                data <= 20'h0F400;
            12'd1132:
                data <= 20'h0F400;
            12'd1133:
                data <= 20'h0F037;
            12'd1134:
                data <= 20'h0F141;
            12'd1135:
                data <= 20'h0F205;
            12'd1136:
                data <= 20'h0F5FE;
            12'd1137:
                data <= 20'h0F400;
            12'd1138:
                data <= 20'h0F400;
            12'd1139:
                data <= 20'h0F038;
            12'd1140:
                data <= 20'h0F187;
            12'd1141:
                data <= 20'h0F2F7;
            12'd1142:
                data <= 20'h0F5FE;
            12'd1143:
                data <= 20'h0F400;
            12'd1144:
                data <= 20'h0F400;
            12'd1145:
                data <= 20'h0F039;
            12'd1146:
                data <= 20'h0F198;
            12'd1147:
                data <= 20'h0F2F8;
            12'd1148:
                data <= 20'h0F5FE;
            12'd1149:
                data <= 20'h0F400;
            12'd1150:
                data <= 20'h0F400;
            12'd1151:
                data <= 20'h0F03A;
            12'd1152:
                data <= 20'h0F160;
            12'd1153:
                data <= 20'h0F20B;
            12'd1154:
                data <= 20'h0F5FE;
            12'd1155:
                data <= 20'h0F400;
            12'd1156:
                data <= 20'h0F400;
            12'd1157:
                data <= 20'h0F03B;
            12'd1158:
                data <= 20'h0F16D;
            12'd1159:
                data <= 20'h0F20B;
            12'd1160:
                data <= 20'h0F5FE;
            12'd1161:
                data <= 20'h0F400;
            12'd1162:
                data <= 20'h0F400;
            12'd1163:
                data <= 20'h0F03C;
            12'd1164:
                data <= 20'h0F188;
            12'd1165:
                data <= 20'h0F2EE;
            12'd1166:
                data <= 20'h0F5FE;
            12'd1167:
                data <= 20'h0F400;
            12'd1168:
                data <= 20'h0F400;
            12'd1169:
                data <= 20'h0F03D;
            12'd1170:
                data <= 20'h0F140;
            12'd1171:
                data <= 20'h0F2EA;
            12'd1172:
                data <= 20'h0F5FE;
            12'd1173:
                data <= 20'h0F400;
            12'd1174:
                data <= 20'h0F400;
            12'd1175:
                data <= 20'h0F03E;
            12'd1176:
                data <= 20'h0F186;
            12'd1177:
                data <= 20'h0F227;
            12'd1178:
                data <= 20'h0F5FE;
            12'd1179:
                data <= 20'h0F400;
            12'd1180:
                data <= 20'h0F400;
            12'd1181:
                data <= 20'h0F03F;
            12'd1182:
                data <= 20'h0F109;
            12'd1183:
                data <= 20'h0F272;
            12'd1184:
                data <= 20'h0F5FE;
            12'd1185:
                data <= 20'h0F400;
            12'd1186:
                data <= 20'h0F400;
            12'd1187:
                data <= 20'h0F040;
            12'd1188:
                data <= 20'h0F109;
            12'd1189:
                data <= 20'h0F272;
            12'd1190:
                data <= 20'h0F5FE;
            12'd1191:
                data <= 20'h0F400;
            12'd1192:
                data <= 20'h0F400;
            12'd1193:
                data <= 20'h0F041;
            12'd1194:
                data <= 20'h0F186;
            12'd1195:
                data <= 20'h0F227;
            12'd1196:
                data <= 20'h0F5FE;
            12'd1197:
                data <= 20'h0F400;
            12'd1198:
                data <= 20'h0F400;
            12'd1199:
                data <= 20'h0F042;
            12'd1200:
                data <= 20'h0F140;
            12'd1201:
                data <= 20'h0F2EA;
            12'd1202:
                data <= 20'h0F5FE;
            12'd1203:
                data <= 20'h0F400;
            12'd1204:
                data <= 20'h0F400;
            12'd1205:
                data <= 20'h0F043;
            12'd1206:
                data <= 20'h0F188;
            12'd1207:
                data <= 20'h0F2EE;
            12'd1208:
                data <= 20'h0F5FE;
            12'd1209:
                data <= 20'h0F400;
            12'd1210:
                data <= 20'h0F400;
            12'd1211:
                data <= 20'h0F044;
            12'd1212:
                data <= 20'h0F16D;
            12'd1213:
                data <= 20'h0F20B;
            12'd1214:
                data <= 20'h0F5FE;
            12'd1215:
                data <= 20'h0F400;
            12'd1216:
                data <= 20'h0F400;
            12'd1217:
                data <= 20'h0F045;
            12'd1218:
                data <= 20'h0F160;
            12'd1219:
                data <= 20'h0F20B;
            12'd1220:
                data <= 20'h0F5FE;
            12'd1221:
                data <= 20'h0F400;
            12'd1222:
                data <= 20'h0F400;
            12'd1223:
                data <= 20'h0F046;
            12'd1224:
                data <= 20'h0F198;
            12'd1225:
                data <= 20'h0F2F8;
            12'd1226:
                data <= 20'h0F5FE;
            12'd1227:
                data <= 20'h0F400;
            12'd1228:
                data <= 20'h0F400;
            12'd1229:
                data <= 20'h0F047;
            12'd1230:
                data <= 20'h0F187;
            12'd1231:
                data <= 20'h0F2F7;
            12'd1232:
                data <= 20'h0F5FE;
            12'd1233:
                data <= 20'h0F400;
            12'd1234:
                data <= 20'h0F400;
            12'd1235:
                data <= 20'h0F048;
            12'd1236:
                data <= 20'h0F141;
            12'd1237:
                data <= 20'h0F205;
            12'd1238:
                data <= 20'h0F5FE;
            12'd1239:
                data <= 20'h0F400;
            12'd1240:
                data <= 20'h0F400;
            12'd1241:
                data <= 20'h0F049;
            12'd1242:
                data <= 20'h0F1BE;
            12'd1243:
                data <= 20'h0F206;
            12'd1244:
                data <= 20'h0F5FE;
            12'd1245:
                data <= 20'h0F400;
            12'd1246:
                data <= 20'h0F400;
            12'd1247:
                data <= 20'h0F04A;
            12'd1248:
                data <= 20'h0F11A;
            12'd1249:
                data <= 20'h0F2FC;
            12'd1250:
                data <= 20'h0F5FE;
            12'd1251:
                data <= 20'h0F400;
            12'd1252:
                data <= 20'h0F400;
            12'd1253:
                data <= 20'h0F04B;
            12'd1254:
                data <= 20'h0F16D;
            12'd1255:
                data <= 20'h0F2FA;
            12'd1256:
                data <= 20'h0F5FE;
            12'd1257:
                data <= 20'h0F400;
            12'd1258:
                data <= 20'h0F400;
            12'd1259:
                data <= 20'h0F04C;
            12'd1260:
                data <= 20'h0F1F8;
            12'd1261:
                data <= 20'h0F202;
            12'd1262:
                data <= 20'h0F5FE;
            12'd1263:
                data <= 20'h0F400;
            12'd1264:
                data <= 20'h0F400;
            12'd1265:
                data <= 20'h0F04D;
            12'd1266:
                data <= 20'h0F1B7;
            12'd1267:
                data <= 20'h0F204;
            12'd1268:
                data <= 20'h0F5FE;
            12'd1269:
                data <= 20'h0F400;
            12'd1270:
                data <= 20'h0F400;
            12'd1271:
                data <= 20'h0F04E;
            12'd1272:
                data <= 20'h0F1B6;
            12'd1273:
                data <= 20'h0F2FD;
            12'd1274:
                data <= 20'h0F5FE;
            12'd1275:
                data <= 20'h0F400;
            12'd1276:
                data <= 20'h0F400;
            12'd1277:
                data <= 20'h0F04F;
            12'd1278:
                data <= 20'h0F1F3;
            12'd1279:
                data <= 20'h0F2FB;
            12'd1280:
                data <= 20'h0F5FE;
            12'd1281:
                data <= 20'h0F400;
            12'd1282:
                data <= 20'h0F400;
            12'd1283:
                data <= 20'h0F050;
            12'd1284:
                data <= 20'h0F1C6;
            12'd1285:
                data <= 20'h0F201;
            12'd1286:
                data <= 20'h0F5FE;
            12'd1287:
                data <= 20'h0F400;
            12'd1288:
                data <= 20'h0F400;
            12'd1289:
                data <= 20'h0F051;
            12'd1290:
                data <= 20'h0F183;
            12'd1291:
                data <= 20'h0F203;
            12'd1292:
                data <= 20'h0F5FE;
            12'd1293:
                data <= 20'h0F400;
            12'd1294:
                data <= 20'h0F400;
            12'd1295:
                data <= 20'h0F052;
            12'd1296:
                data <= 20'h0F1A1;
            12'd1297:
                data <= 20'h0F2FE;
            12'd1298:
                data <= 20'h0F5FE;
            12'd1299:
                data <= 20'h0F400;
            12'd1300:
                data <= 20'h0F400;
            12'd1301:
                data <= 20'h0F053;
            12'd1302:
                data <= 20'h0F1F0;
            12'd1303:
                data <= 20'h0F2FC;
            12'd1304:
                data <= 20'h0F5FE;
            12'd1305:
                data <= 20'h0F400;
            12'd1306:
                data <= 20'h0F400;
            12'd1307:
                data <= 20'h0F054;
            12'd1308:
                data <= 20'h0F10D;
            12'd1309:
                data <= 20'h0F201;
            12'd1310:
                data <= 20'h0F5FE;
            12'd1311:
                data <= 20'h0F400;
            12'd1312:
                data <= 20'h0F400;
            12'd1313:
                data <= 20'h0F055;
            12'd1314:
                data <= 20'h0F1AE;
            12'd1315:
                data <= 20'h0F202;
            12'd1316:
                data <= 20'h0F5FE;
            12'd1317:
                data <= 20'h0F400;
            12'd1318:
                data <= 20'h0F400;
            12'd1319:
                data <= 20'h0F056;
            12'd1320:
                data <= 20'h0F136;
            12'd1321:
                data <= 20'h0F2FF;
            12'd1322:
                data <= 20'h0F5FE;
            12'd1323:
                data <= 20'h0F400;
            12'd1324:
                data <= 20'h0F400;
            12'd1325:
                data <= 20'h0F057;
            12'd1326:
                data <= 20'h0F1A7;
            12'd1327:
                data <= 20'h0F2FD;
            12'd1328:
                data <= 20'h0F5FE;
            12'd1329:
                data <= 20'h0F400;
            12'd1330:
                data <= 20'h0F400;
            12'd1331:
                data <= 20'h0F058;
            12'd1332:
                data <= 20'h0F195;
            12'd1333:
                data <= 20'h0F200;
            12'd1334:
                data <= 20'h0F5FE;
            12'd1335:
                data <= 20'h0F400;
            12'd1336:
                data <= 20'h0F400;
            12'd1337:
                data <= 20'h0F059;
            12'd1338:
                data <= 20'h0F10E;
            12'd1339:
                data <= 20'h0F202;
            12'd1340:
                data <= 20'h0F5FE;
            12'd1341:
                data <= 20'h0F400;
            12'd1342:
                data <= 20'h0F400;
            12'd1343:
                data <= 20'h0F05A;
            12'd1344:
                data <= 20'h0F197;
            12'd1345:
                data <= 20'h0F2FF;
            12'd1346:
                data <= 20'h0F5FE;
            12'd1347:
                data <= 20'h0F400;
            12'd1348:
                data <= 20'h0F400;
            12'd1349:
                data <= 20'h0F05B;
            12'd1350:
                data <= 20'h0F135;
            12'd1351:
                data <= 20'h0F2FE;
            12'd1352:
                data <= 20'h0F5FE;
            12'd1353:
                data <= 20'h0F400;
            12'd1354:
                data <= 20'h0F400;
            12'd1355:
                data <= 20'h0F05C;
            12'd1356:
                data <= 20'h0F146;
            12'd1357:
                data <= 20'h0F200;
            12'd1358:
                data <= 20'h0F5FE;
            12'd1359:
                data <= 20'h0F400;
            12'd1360:
                data <= 20'h0F400;
            12'd1361:
                data <= 20'h0F05D;
            12'd1362:
                data <= 20'h0F190;
            12'd1363:
                data <= 20'h0F201;
            12'd1364:
                data <= 20'h0F5FE;
            12'd1365:
                data <= 20'h0F400;
            12'd1366:
                data <= 20'h0F400;
            12'd1367:
                data <= 20'h0F05E;
            12'd1368:
                data <= 20'h0F1D7;
            12'd1369:
                data <= 20'h0F2FF;
            12'd1370:
                data <= 20'h0F5FE;
            12'd1371:
                data <= 20'h0F400;
            12'd1372:
                data <= 20'h0F400;
            12'd1373:
                data <= 20'h0F05F;
            12'd1374:
                data <= 20'h0F1A5;
            12'd1375:
                data <= 20'h0F2FE;
            12'd1376:
                data <= 20'h0F5FE;
            12'd1377:
                data <= 20'h0F400;
            12'd1378:
                data <= 20'h0F400;
            12'd1379:
                data <= 20'h0F060;
            12'd1380:
                data <= 20'h0F113;
            12'd1381:
                data <= 20'h0F200;
            12'd1382:
                data <= 20'h0F5FE;
            12'd1383:
                data <= 20'h0F400;
            12'd1384:
                data <= 20'h0F400;
            12'd1385:
                data <= 20'h0F061;
            12'd1386:
                data <= 20'h0F12B;
            12'd1387:
                data <= 20'h0F201;
            12'd1388:
                data <= 20'h0F5FE;
            12'd1389:
                data <= 20'h0F400;
            12'd1390:
                data <= 20'h0F400;
            12'd1391:
                data <= 20'h0F062;
            12'd1392:
                data <= 20'h0F1FF;
            12'd1393:
                data <= 20'h0F2FF;
            12'd1394:
                data <= 20'h0F5FE;
            12'd1395:
                data <= 20'h0F400;
            12'd1396:
                data <= 20'h0F400;
            12'd1397:
                data <= 20'h0F063;
            12'd1398:
                data <= 20'h0F1FF;
            12'd1399:
                data <= 20'h0F2FE;
            12'd1400:
                data <= 20'h0F5FE;
            12'd1401:
                data <= 20'h0F400;
            12'd1402:
                data <= 20'h0F400;
            12'd1403:
                data <= 20'h0F064;
            12'd1404:
                data <= 20'h0F1F3;
            12'd1405:
                data <= 20'h0F2FF;
            12'd1406:
                data <= 20'h0F5FE;
            12'd1407:
                data <= 20'h0F400;
            12'd1408:
                data <= 20'h0F400;
            12'd1409:
                data <= 20'h0F065;
            12'd1410:
                data <= 20'h0F1DB;
            12'd1411:
                data <= 20'h0F200;
            12'd1412:
                data <= 20'h0F5FE;
            12'd1413:
                data <= 20'h0F400;
            12'd1414:
                data <= 20'h0F400;
            12'd1415:
                data <= 20'h0F066;
            12'd1416:
                data <= 20'h0F117;
            12'd1417:
                data <= 20'h0F200;
            12'd1418:
                data <= 20'h0F5FE;
            12'd1419:
                data <= 20'h0F400;
            12'd1420:
                data <= 20'h0F400;
            12'd1421:
                data <= 20'h0F067;
            12'd1422:
                data <= 20'h0F147;
            12'd1423:
                data <= 20'h0F2FF;
            12'd1424:
                data <= 20'h0F5FE;
            12'd1425:
                data <= 20'h0F400;
            12'd1426:
                data <= 20'h0F400;
            12'd1427:
                data <= 20'h0F068;
            12'd1428:
                data <= 20'h0F1E2;
            12'd1429:
                data <= 20'h0F2FF;
            12'd1430:
                data <= 20'h0F5FE;
            12'd1431:
                data <= 20'h0F400;
            12'd1432:
                data <= 20'h0F400;
            12'd1433:
                data <= 20'h0F069;
            12'd1434:
                data <= 20'h0F19A;
            12'd1435:
                data <= 20'h0F200;
            12'd1436:
                data <= 20'h0F5FE;
            12'd1437:
                data <= 20'h0F400;
            12'd1438:
                data <= 20'h0F400;
            12'd1439:
                data <= 20'h0F06A;
            12'd1440:
                data <= 20'h0F122;
            12'd1441:
                data <= 20'h0F200;
            12'd1442:
                data <= 20'h0F5FE;
            12'd1443:
                data <= 20'h0F400;
            12'd1444:
                data <= 20'h0F400;
            12'd1445:
                data <= 20'h0F06B;
            12'd1446:
                data <= 20'h0F180;
            12'd1447:
                data <= 20'h0F2FF;
            12'd1448:
                data <= 20'h0F5FE;
            12'd1449:
                data <= 20'h0F400;
            12'd1450:
                data <= 20'h0F400;
            12'd1451:
                data <= 20'h0F06C;
            12'd1452:
                data <= 20'h0F1DB;
            12'd1453:
                data <= 20'h0F2FF;
            12'd1454:
                data <= 20'h0F5FE;
            12'd1455:
                data <= 20'h0F400;
            12'd1456:
                data <= 20'h0F400;
            12'd1457:
                data <= 20'h0F06D;
            12'd1458:
                data <= 20'h0F168;
            12'd1459:
                data <= 20'h0F200;
            12'd1460:
                data <= 20'h0F5FE;
            12'd1461:
                data <= 20'h0F400;
            12'd1462:
                data <= 20'h0F400;
            12'd1463:
                data <= 20'h0F06E;
            12'd1464:
                data <= 20'h0F126;
            12'd1465:
                data <= 20'h0F200;
            12'd1466:
                data <= 20'h0F5FE;
            12'd1467:
                data <= 20'h0F400;
            12'd1468:
                data <= 20'h0F400;
            12'd1469:
                data <= 20'h0F06F;
            12'd1470:
                data <= 20'h0F1AC;
            12'd1471:
                data <= 20'h0F2FF;
            12'd1472:
                data <= 20'h0F5FE;
            12'd1473:
                data <= 20'h0F400;
            12'd1474:
                data <= 20'h0F400;
            12'd1475:
                data <= 20'h0F070;
            12'd1476:
                data <= 20'h0F1DB;
            12'd1477:
                data <= 20'h0F2FF;
            12'd1478:
                data <= 20'h0F5FE;
            12'd1479:
                data <= 20'h0F400;
            12'd1480:
                data <= 20'h0F400;
            12'd1481:
                data <= 20'h0F071;
            12'd1482:
                data <= 20'h0F143;
            12'd1483:
                data <= 20'h0F200;
            12'd1484:
                data <= 20'h0F5FE;
            12'd1485:
                data <= 20'h0F400;
            12'd1486:
                data <= 20'h0F400;
            12'd1487:
                data <= 20'h0F072;
            12'd1488:
                data <= 20'h0F124;
            12'd1489:
                data <= 20'h0F200;
            12'd1490:
                data <= 20'h0F5FE;
            12'd1491:
                data <= 20'h0F400;
            12'd1492:
                data <= 20'h0F400;
            12'd1493:
                data <= 20'h0F073;
            12'd1494:
                data <= 20'h0F1CC;
            12'd1495:
                data <= 20'h0F2FF;
            12'd1496:
                data <= 20'h0F5FE;
            12'd1497:
                data <= 20'h0F400;
            12'd1498:
                data <= 20'h0F400;
            12'd1499:
                data <= 20'h0F074;
            12'd1500:
                data <= 20'h0F1DF;
            12'd1501:
                data <= 20'h0F2FF;
            12'd1502:
                data <= 20'h0F5FE;
            12'd1503:
                data <= 20'h0F400;
            12'd1504:
                data <= 20'h0F400;
            12'd1505:
                data <= 20'h0F075;
            12'd1506:
                data <= 20'h0F128;
            12'd1507:
                data <= 20'h0F200;
            12'd1508:
                data <= 20'h0F5FE;
            12'd1509:
                data <= 20'h0F400;
            12'd1510:
                data <= 20'h0F400;
            12'd1511:
                data <= 20'h0F076;
            12'd1512:
                data <= 20'h0F11F;
            12'd1513:
                data <= 20'h0F200;
            12'd1514:
                data <= 20'h0F5FE;
            12'd1515:
                data <= 20'h0F400;
            12'd1516:
                data <= 20'h0F400;
            12'd1517:
                data <= 20'h0F077;
            12'd1518:
                data <= 20'h0F1E1;
            12'd1519:
                data <= 20'h0F2FF;
            12'd1520:
                data <= 20'h0F5FE;
            12'd1521:
                data <= 20'h0F400;
            12'd1522:
                data <= 20'h0F400;
            12'd1523:
                data <= 20'h0F078;
            12'd1524:
                data <= 20'h0F1E3;
            12'd1525:
                data <= 20'h0F2FF;
            12'd1526:
                data <= 20'h0F5FE;
            12'd1527:
                data <= 20'h0F400;
            12'd1528:
                data <= 20'h0F400;
            12'd1529:
                data <= 20'h0F079;
            12'd1530:
                data <= 20'h0F11A;
            12'd1531:
                data <= 20'h0F200;
            12'd1532:
                data <= 20'h0F5FE;
            12'd1533:
                data <= 20'h0F400;
            12'd1534:
                data <= 20'h0F400;
            12'd1535:
                data <= 20'h0F07A;
            12'd1536:
                data <= 20'h0F120;
            12'd1537:
                data <= 20'h0F200;
            12'd1538:
                data <= 20'h0F5FE;
            12'd1539:
                data <= 20'h0F400;
            12'd1540:
                data <= 20'h0F400;
            12'd1541:
                data <= 20'h0F07B;
            12'd1542:
                data <= 20'h0F1E8;
            12'd1543:
                data <= 20'h0F2FF;
            12'd1544:
                data <= 20'h0F5FE;
            12'd1545:
                data <= 20'h0F400;
            12'd1546:
                data <= 20'h0F400;
            12'd1547:
                data <= 20'h0F07C;
            12'd1548:
                data <= 20'h0F1C0;
            12'd1549:
                data <= 20'h0F2FF;
            12'd1550:
                data <= 20'h0F5FE;
            12'd1551:
                data <= 20'h0F400;
            12'd1552:
                data <= 20'h0F400;
            12'd1553:
                data <= 20'h0F07D;
            12'd1554:
                data <= 20'h0F1CF;
            12'd1555:
                data <= 20'h0F2FF;
            12'd1556:
                data <= 20'h0F5FE;
            12'd1557:
                data <= 20'h0F400;
            12'd1558:
                data <= 20'h0F400;
            12'd1559:
                data <= 20'h0F07E;
            12'd1560:
                data <= 20'h0F1F1;
            12'd1561:
                data <= 20'h0F2FF;
            12'd1562:
                data <= 20'h0F5FE;
            12'd1563:
                data <= 20'h0F400;
            12'd1564:
                data <= 20'h0F400;
            12'd1565:
                data <= 20'h0F07F;
            12'd1566:
                data <= 20'h0F101;
            12'd1567:
                data <= 20'h0F200;
            12'd1568:
                data <= 20'h0F5FE;
            12'd1569:
                data <= 20'h0F400;
            12'd1570:
                data <= 20'h0F400;
            12'd1571:
                data <= 20'h0F5F8;
            // Setup the Parallel Port (Digital Data Interface)
            12'd1572:
                data <= 20'h010C8;
            12'd1573:
                data <= 20'h01100;
            12'd1574:
                data <= 20'h01210;
            //    12'd1575: data <= 20'h0060B;//rx delay
            12'd1575:
                data <= 20'h00600;
            12'd1576:
                data <= 20'h00740;//tx delay
            12'd1577:
                data <= 20'h03C22;//
            12'd1578:
                data <= 20'h03DFF;//
            12'd1579:
                data <= 20'h03E0F;//
            //Setup AuxDAC
            12'd1580:
                data <= 20'h01800;
            12'd1581:
                data <= 20'h01900;
            12'd1582:
                data <= 20'h01A00;
            12'd1583:
                data <= 20'h01B00;
            12'd1584:
                data <= 20'h023FF;
            12'd1585:
                data <= 20'h02600;
            12'd1586:
                data <= 20'h03000;
            12'd1587:
                data <= 20'h03100;
            12'd1588:
                data <= 20'h03200;
            12'd1589:
                data <= 20'h03300;
            12'd1590:
                data <= 20'h00B00;
            12'd1591:
                data <= 20'h00C00;
            12'd1592:
                data <= 20'h00D03;
            12'd1593:
                data <= 20'h00F04;
            12'd1594:
                data <= 20'h01C10;
            12'd1595:
                data <= 20'h01D01;
            12'd1596:
                data <= 20'h03500;
            12'd1597:
                data <= 20'h036FF;
            12'd1598:
                data <= 20'h03A1E;
            12'd1599:
                data <= 20'h02000;
            12'd1600:
                data <= 20'h02703;
            12'd1601:
                data <= 20'h02800;
            12'd1602:
                data <= 20'h02900;
            12'd1603:
                data <= 20'h02A00;
            12'd1604:
                data <= 20'h02B00;
            12'd1605:
                data <= 20'h02C00;
            12'd1606:
                data <= 20'h02D00;
            12'd1607:
                data <= 20'h02E00;
            12'd1608:
                data <= 20'h02F00;
            //************************************************************
            // Setup RF PLL non-frequency-dependent registers
            //************************************************************
            12'd1609:
                data <= 20'h26100;
            12'd1610:
                data <= 20'h2A100;
            12'd1611:
                data <= 20'h2480B;
            12'd1612:
                data <= 20'h2880B;
            12'd1613:
                data <= 20'h24602;
            12'd1614:
                data <= 20'h28602;
            12'd1615:
                data <= 20'h2498E;
            12'd1616:
                data <= 20'h2898E;
            12'd1617:
                data <= 20'h23B80;
            12'd1618:
                data <= 20'h27B80;
            12'd1619:
                data <= 20'h2430D;
            12'd1620:
                data <= 20'h2830D;
            12'd1621:
                data <= 20'h23D00;
            12'd1622:
                data <= 20'h27D00;
            12'd1623:
                data <= 20'h01504;
            12'd1624:
                data <= 20'h01405;
            12'd1625:
                data <= 20'h01301;
            12'd1626:
                data <= 20'h40000;

            12'd1627:
                data <= 20'h23D04;
            12'd1628:
                data <= 20'h40000;
            12'd1629:
                data <= 20'h27D04;//
            12'd1630:
                data <= 20'h40000;
            12'd1631:
                data <= 20'h23D00;
            12'd1632:
                data <= 20'h27D00;
            //************************************************************
            // Setup Rx Frequency-Dependent Syntheisizer Registers
            //************************************************************
            12'd1633:
                data <= 20'h23A4A;
            12'd1634:
                data <= 20'h239C3;
            12'd1635:
                data <= 20'h2421F;
            12'd1636:
                data <= 20'h23878;
            12'd1637:
                data <= 20'h24500;
            12'd1638:
                data <= 20'h2510C;
            12'd1639:
                data <= 20'h25070;
            12'd1640:
                data <= 20'h23B92;
            12'd1641:
                data <= 20'h23ED4;
            12'd1642:
                data <= 20'h23FDF;
            12'd1643:
                data <= 20'h24009;

            12'd1644:
                data <= 20'h27A4A;
            12'd1645:
                data <= 20'h279C1;
            12'd1646:
                data <= 20'h2820E;
            12'd1647:
                data <= 20'h27878;
            12'd1648:
                data <= 20'h28500;
            12'd1649:
                data <= 20'h2910B;
            12'd1650:
                data <= 20'h29070;
            12'd1651:
                data <= 20'h27B96;
            12'd1652:
                data <= 20'h27EF4;
            12'd1653:
                data <= 20'h27FDF;
            12'd1654:
                data <= 20'h2800A;
            //************************************************************
            // Write Rx and Tx Frequency Words
            //************************************************************
            12'd1655:
                data <= 20'h233F5;
            12'd1656:
                data <= 20'h234FF;
            12'd1657:
                data <= 20'h2355B;
            12'd1658:
                data <= 20'h23200;
            12'd1659:
                data <= 20'h23188;
            12'd1660:
                data <= 20'h00511;

            12'd1661:
                data <= 20'h273F5;
            12'd1662:
                data <= 20'h274FF;
            12'd1663:
                data <= 20'h2755B;
            12'd1664:
                data <= 20'h27200;
            12'd1665:
                data <= 20'h27188;//9C
            12'd1666:
                data <= 20'h00511;

            12'd1667:
                data <= 20'h13F02;
            12'd1668:
                data <= 20'h1380F;
            12'd1669:
                data <= 20'h13978;
            12'd1670:
                data <= 20'h13A00;
            12'd1671:
                data <= 20'h13B00;
            12'd1672:
                data <= 20'h13F06;
            12'd1673:
                data <= 20'h13C00;
            12'd1674:
                data <= 20'h13C00;
            12'd1675:
                data <= 20'h1380E;
            12'd1676:
                data <= 20'h13974;
            12'd1677:
                data <= 20'h13A00;
            12'd1678:
                data <= 20'h13B0D;
            12'd1679:
                data <= 20'h13F06;
            12'd1680:
                data <= 20'h13C00;
            12'd1681:
                data <= 20'h13C00;
            12'd1682:
                data <= 20'h1380D;
            12'd1683:
                data <= 20'h13970;
            12'd1684:
                data <= 20'h13A00;
            12'd1685:
                data <= 20'h13B15;
            12'd1686:
                data <= 20'h13F06;
            12'd1687:
                data <= 20'h13C00;
            12'd1688:
                data <= 20'h13C00;
            12'd1689:
                data <= 20'h1380C;
            12'd1690:
                data <= 20'h1396C;
            12'd1691:
                data <= 20'h13A00;
            12'd1692:
                data <= 20'h13B1B;
            12'd1693:
                data <= 20'h13F06;
            12'd1694:
                data <= 20'h13C00;
            12'd1695:
                data <= 20'h13C00;
            12'd1696:
                data <= 20'h1380B;
            12'd1697:
                data <= 20'h13968;
            12'd1698:
                data <= 20'h13A00;
            12'd1699:
                data <= 20'h13B21;
            12'd1700:
                data <= 20'h13F06;
            12'd1701:
                data <= 20'h13C00;
            12'd1702:
                data <= 20'h13C00;
            12'd1703:
                data <= 20'h1380A;
            12'd1704:
                data <= 20'h13964;
            12'd1705:
                data <= 20'h13A00;
            12'd1706:
                data <= 20'h13B25;
            12'd1707:
                data <= 20'h13F06;
            12'd1708:
                data <= 20'h13C00;
            12'd1709:
                data <= 20'h13C00;
            12'd1710:
                data <= 20'h13809;
            12'd1711:
                data <= 20'h13960;
            12'd1712:
                data <= 20'h13A00;
            12'd1713:
                data <= 20'h13B29;
            12'd1714:
                data <= 20'h13F06;
            12'd1715:
                data <= 20'h13C00;
            12'd1716:
                data <= 20'h13C00;
            12'd1717:
                data <= 20'h13808;
            12'd1718:
                data <= 20'h1395C;
            12'd1719:
                data <= 20'h13A00;
            12'd1720:
                data <= 20'h13B2C;
            12'd1721:
                data <= 20'h13F06;
            12'd1722:
                data <= 20'h13C00;
            12'd1723:
                data <= 20'h13C00;
            12'd1724:
                data <= 20'h13807;
            12'd1725:
                data <= 20'h13958;
            12'd1726:
                data <= 20'h13A00;
            12'd1727:
                data <= 20'h13B2F;
            12'd1728:
                data <= 20'h13F06;
            12'd1729:
                data <= 20'h13C00;
            12'd1730:
                data <= 20'h13C00;
            12'd1731:
                data <= 20'h13806;
            12'd1732:
                data <= 20'h13954;
            12'd1733:
                data <= 20'h13A00;
            12'd1734:
                data <= 20'h13B31;
            12'd1735:
                data <= 20'h13F06;
            12'd1736:
                data <= 20'h13C00;
            12'd1737:
                data <= 20'h13C00;
            12'd1738:
                data <= 20'h13805;
            12'd1739:
                data <= 20'h13950;
            12'd1740:
                data <= 20'h13A00;
            12'd1741:
                data <= 20'h13B33;
            12'd1742:
                data <= 20'h13F06;
            12'd1743:
                data <= 20'h13C00;
            12'd1744:
                data <= 20'h13C00;
            12'd1745:
                data <= 20'h13804;
            12'd1746:
                data <= 20'h1394C;
            12'd1747:
                data <= 20'h13A00;
            12'd1748:
                data <= 20'h13B34;
            12'd1749:
                data <= 20'h13F06;
            12'd1750:
                data <= 20'h13C00;
            12'd1751:
                data <= 20'h13C00;
            12'd1752:
                data <= 20'h13803;
            12'd1753:
                data <= 20'h13948;
            12'd1754:
                data <= 20'h13A00;
            12'd1755:
                data <= 20'h13B35;
            12'd1756:
                data <= 20'h13F06;
            12'd1757:
                data <= 20'h13C00;
            12'd1758:
                data <= 20'h13C00;
            12'd1759:
                data <= 20'h13802;
            12'd1760:
                data <= 20'h13930;
            12'd1761:
                data <= 20'h13A00;
            12'd1762:
                data <= 20'h13B3A;
            12'd1763:
                data <= 20'h13F06;
            12'd1764:
                data <= 20'h13C00;
            12'd1765:
                data <= 20'h13C00;
            12'd1766:
                data <= 20'h13801;
            12'd1767:
                data <= 20'h13918;
            12'd1768:
                data <= 20'h13A00;
            12'd1769:
                data <= 20'h13B3D;
            12'd1770:
                data <= 20'h13F06;
            12'd1771:
                data <= 20'h13C00;
            12'd1772:
                data <= 20'h13C00;
            12'd1773:
                data <= 20'h13800;
            12'd1774:
                data <= 20'h13900;
            12'd1775:
                data <= 20'h13A00;
            12'd1776:
                data <= 20'h13B3E;
            12'd1777:
                data <= 20'h13F06;
            12'd1778:
                data <= 20'h13C00;
            12'd1779:
                data <= 20'h13C00;
            12'd1780:
                data <= 20'h13F02;
            12'd1781:
                data <= 20'h13C00;
            12'd1782:
                data <= 20'h13C00;
            12'd1783:
                data <= 20'h13F00;
            12'd1784:
                data <= 20'h1371A;
            12'd1785:
                data <= 20'h13000;
            12'd1786:
                data <= 20'h13100;
            12'd1787:
                data <= 20'h13200;
            12'd1788:
                data <= 20'h13320;
            12'd1789:
                data <= 20'h1371E;
            12'd1790:
                data <= 20'h13400;
            12'd1791:
                data <= 20'h13400;
            12'd1792:
                data <= 20'h13001;
            12'd1793:
                data <= 20'h13100;
            12'd1794:
                data <= 20'h13200;
            12'd1795:
                data <= 20'h13300;
            12'd1796:
                data <= 20'h1371E;
            12'd1797:
                data <= 20'h13400;
            12'd1798:
                data <= 20'h13400;
            12'd1799:
                data <= 20'h13002;
            12'd1800:
                data <= 20'h13100;
            12'd1801:
                data <= 20'h13200;
            12'd1802:
                data <= 20'h13300;
            12'd1803:
                data <= 20'h1371E;
            12'd1804:
                data <= 20'h13400;
            12'd1805:
                data <= 20'h13400;
            12'd1806:
                data <= 20'h13003;
            12'd1807:
                data <= 20'h13100;
            12'd1808:
                data <= 20'h13201;
            12'd1809:
                data <= 20'h13300;
            12'd1810:
                data <= 20'h1371E;
            12'd1811:
                data <= 20'h13400;
            12'd1812:
                data <= 20'h13400;
            12'd1813:
                data <= 20'h13004;
            12'd1814:
                data <= 20'h13100;
            12'd1815:
                data <= 20'h13202;
            12'd1816:
                data <= 20'h13300;
            12'd1817:
                data <= 20'h1371E;
            12'd1818:
                data <= 20'h13400;
            12'd1819:
                data <= 20'h13400;
            12'd1820:
                data <= 20'h13005;
            12'd1821:
                data <= 20'h13100;
            12'd1822:
                data <= 20'h13203;
            12'd1823:
                data <= 20'h13300;
            12'd1824:
                data <= 20'h1371E;
            12'd1825:
                data <= 20'h13400;
            12'd1826:
                data <= 20'h13400;
            12'd1827:
                data <= 20'h13006;
            12'd1828:
                data <= 20'h13100;
            12'd1829:
                data <= 20'h13204;
            12'd1830:
                data <= 20'h13300;
            12'd1831:
                data <= 20'h1371E;
            12'd1832:
                data <= 20'h13400;
            12'd1833:
                data <= 20'h13400;
            12'd1834:
                data <= 20'h13007;
            12'd1835:
                data <= 20'h13100;
            12'd1836:
                data <= 20'h13205;
            12'd1837:
                data <= 20'h13300;
            12'd1838:
                data <= 20'h1371E;
            12'd1839:
                data <= 20'h13400;
            12'd1840:
                data <= 20'h13400;
            12'd1841:
                data <= 20'h13008;
            12'd1842:
                data <= 20'h13101;
            12'd1843:
                data <= 20'h13203;
            12'd1844:
                data <= 20'h13320;
            12'd1845:
                data <= 20'h1371E;
            12'd1846:
                data <= 20'h13400;
            12'd1847:
                data <= 20'h13400;
            12'd1848:
                data <= 20'h13009;
            12'd1849:
                data <= 20'h13101;
            12'd1850:
                data <= 20'h13204;
            12'd1851:
                data <= 20'h13300;
            12'd1852:
                data <= 20'h1371E;
            12'd1853:
                data <= 20'h13400;
            12'd1854:
                data <= 20'h13400;
            12'd1855:
                data <= 20'h1300A;
            12'd1856:
                data <= 20'h13101;
            12'd1857:
                data <= 20'h13205;
            12'd1858:
                data <= 20'h13300;
            12'd1859:
                data <= 20'h1371E;
            12'd1860:
                data <= 20'h13400;
            12'd1861:
                data <= 20'h13400;
            12'd1862:
                data <= 20'h1300B;
            12'd1863:
                data <= 20'h13101;
            12'd1864:
                data <= 20'h13206;
            12'd1865:
                data <= 20'h13300;
            12'd1866:
                data <= 20'h1371E;
            12'd1867:
                data <= 20'h13400;
            12'd1868:
                data <= 20'h13400;
            12'd1869:
                data <= 20'h1300C;
            12'd1870:
                data <= 20'h13101;
            12'd1871:
                data <= 20'h13207;
            12'd1872:
                data <= 20'h13300;
            12'd1873:
                data <= 20'h1371E;
            12'd1874:
                data <= 20'h13400;
            12'd1875:
                data <= 20'h13400;
            12'd1876:
                data <= 20'h1300D;
            12'd1877:
                data <= 20'h13101;
            12'd1878:
                data <= 20'h13208;
            12'd1879:
                data <= 20'h13300;
            12'd1880:
                data <= 20'h1371E;
            12'd1881:
                data <= 20'h13400;
            12'd1882:
                data <= 20'h13400;
            12'd1883:
                data <= 20'h1300E;
            12'd1884:
                data <= 20'h13101;
            12'd1885:
                data <= 20'h13209;
            12'd1886:
                data <= 20'h13300;
            12'd1887:
                data <= 20'h1371E;
            12'd1888:
                data <= 20'h13400;
            12'd1889:
                data <= 20'h13400;
            12'd1890:
                data <= 20'h1300F;
            12'd1891:
                data <= 20'h13101;
            12'd1892:
                data <= 20'h1320A;
            12'd1893:
                data <= 20'h13300;
            12'd1894:
                data <= 20'h1371E;
            12'd1895:
                data <= 20'h13400;
            12'd1896:
                data <= 20'h13400;
            12'd1897:
                data <= 20'h13010;
            12'd1898:
                data <= 20'h13101;
            12'd1899:
                data <= 20'h1320B;
            12'd1900:
                data <= 20'h13300;
            12'd1901:
                data <= 20'h1371E;
            12'd1902:
                data <= 20'h13400;
            12'd1903:
                data <= 20'h13400;
            12'd1904:
                data <= 20'h13011;
            12'd1905:
                data <= 20'h13101;
            12'd1906:
                data <= 20'h1320C;
            12'd1907:
                data <= 20'h13300;
            12'd1908:
                data <= 20'h1371E;
            12'd1909:
                data <= 20'h13400;
            12'd1910:
                data <= 20'h13400;
            12'd1911:
                data <= 20'h13012;
            12'd1912:
                data <= 20'h13101;
            12'd1913:
                data <= 20'h1320D;
            12'd1914:
                data <= 20'h13300;
            12'd1915:
                data <= 20'h1371E;
            12'd1916:
                data <= 20'h13400;
            12'd1917:
                data <= 20'h13400;
            12'd1918:
                data <= 20'h13013;
            12'd1919:
                data <= 20'h13101;
            12'd1920:
                data <= 20'h1320E;
            12'd1921:
                data <= 20'h13300;
            12'd1922:
                data <= 20'h1371E;
            12'd1923:
                data <= 20'h13400;
            12'd1924:
                data <= 20'h13400;
            12'd1925:
                data <= 20'h13014;
            12'd1926:
                data <= 20'h13102;
            12'd1927:
                data <= 20'h13209;
            12'd1928:
                data <= 20'h13320;
            12'd1929:
                data <= 20'h1371E;
            12'd1930:
                data <= 20'h13400;
            12'd1931:
                data <= 20'h13400;
            12'd1932:
                data <= 20'h13015;
            12'd1933:
                data <= 20'h13102;
            12'd1934:
                data <= 20'h1320A;
            12'd1935:
                data <= 20'h13300;
            12'd1936:
                data <= 20'h1371E;
            12'd1937:
                data <= 20'h13400;
            12'd1938:
                data <= 20'h13400;
            12'd1939:
                data <= 20'h13016;
            12'd1940:
                data <= 20'h13102;
            12'd1941:
                data <= 20'h1320B;
            12'd1942:
                data <= 20'h13300;
            12'd1943:
                data <= 20'h1371E;
            12'd1944:
                data <= 20'h13400;
            12'd1945:
                data <= 20'h13400;
            12'd1946:
                data <= 20'h13017;
            12'd1947:
                data <= 20'h13102;
            12'd1948:
                data <= 20'h1320C;
            12'd1949:
                data <= 20'h13300;
            12'd1950:
                data <= 20'h1371E;
            12'd1951:
                data <= 20'h13400;
            12'd1952:
                data <= 20'h13400;
            12'd1953:
                data <= 20'h13018;
            12'd1954:
                data <= 20'h13102;
            12'd1955:
                data <= 20'h1320D;
            12'd1956:
                data <= 20'h13300;
            12'd1957:
                data <= 20'h1371E;
            12'd1958:
                data <= 20'h13400;
            12'd1959:
                data <= 20'h13400;
            12'd1960:
                data <= 20'h13019;
            12'd1961:
                data <= 20'h13102;
            12'd1962:
                data <= 20'h1320E;
            12'd1963:
                data <= 20'h13300;
            12'd1964:
                data <= 20'h1371E;
            12'd1965:
                data <= 20'h13400;
            12'd1966:
                data <= 20'h13400;
            12'd1967:
                data <= 20'h1301A;
            12'd1968:
                data <= 20'h13102;
            12'd1969:
                data <= 20'h1320F;
            12'd1970:
                data <= 20'h13300;
            12'd1971:
                data <= 20'h1371E;
            12'd1972:
                data <= 20'h13400;
            12'd1973:
                data <= 20'h13400;
            12'd1974:
                data <= 20'h1301B;
            12'd1975:
                data <= 20'h13102;
            12'd1976:
                data <= 20'h13210;
            12'd1977:
                data <= 20'h13300;
            12'd1978:
                data <= 20'h1371E;
            12'd1979:
                data <= 20'h13400;
            12'd1980:
                data <= 20'h13400;
            12'd1981:
                data <= 20'h1301C;
            12'd1982:
                data <= 20'h13102;
            12'd1983:
                data <= 20'h1322B;
            12'd1984:
                data <= 20'h13320;
            12'd1985:
                data <= 20'h1371E;
            12'd1986:
                data <= 20'h13400;
            12'd1987:
                data <= 20'h13400;
            12'd1988:
                data <= 20'h1301D;
            12'd1989:
                data <= 20'h13102;
            12'd1990:
                data <= 20'h1322C;
            12'd1991:
                data <= 20'h13300;
            12'd1992:
                data <= 20'h1371E;
            12'd1993:
                data <= 20'h13400;
            12'd1994:
                data <= 20'h13400;
            12'd1995:
                data <= 20'h1301E;
            12'd1996:
                data <= 20'h13104;
            12'd1997:
                data <= 20'h13227;
            12'd1998:
                data <= 20'h13320;
            12'd1999:
                data <= 20'h1371E;
            12'd2000:
                data <= 20'h13400;
            12'd2001:
                data <= 20'h13400;
            12'd2002:
                data <= 20'h1301F;
            12'd2003:
                data <= 20'h13104;
            12'd2004:
                data <= 20'h13228;
            12'd2005:
                data <= 20'h13300;
            12'd2006:
                data <= 20'h1371E;
            12'd2007:
                data <= 20'h13400;
            12'd2008:
                data <= 20'h13400;
            12'd2009:
                data <= 20'h13020;
            12'd2010:
                data <= 20'h13104;
            12'd2011:
                data <= 20'h13229;
            12'd2012:
                data <= 20'h13300;
            12'd2013:
                data <= 20'h1371E;
            12'd2014:
                data <= 20'h13400;
            12'd2015:
                data <= 20'h13400;
            12'd2016:
                data <= 20'h13021;
            12'd2017:
                data <= 20'h13104;
            12'd2018:
                data <= 20'h1322A;
            12'd2019:
                data <= 20'h13300;
            12'd2020:
                data <= 20'h1371E;
            12'd2021:
                data <= 20'h13400;
            12'd2022:
                data <= 20'h13400;
            12'd2023:
                data <= 20'h13022;
            12'd2024:
                data <= 20'h13104;
            12'd2025:
                data <= 20'h1322B;
            12'd2026:
                data <= 20'h13300;
            12'd2027:
                data <= 20'h1371E;
            12'd2028:
                data <= 20'h13400;
            12'd2029:
                data <= 20'h13400;
            12'd2030:
                data <= 20'h13023;
            12'd2031:
                data <= 20'h13124;
            12'd2032:
                data <= 20'h13221;
            12'd2033:
                data <= 20'h13320;
            12'd2034:
                data <= 20'h1371E;
            12'd2035:
                data <= 20'h13400;
            12'd2036:
                data <= 20'h13400;
            12'd2037:
                data <= 20'h13024;
            12'd2038:
                data <= 20'h13124;
            12'd2039:
                data <= 20'h13222;
            12'd2040:
                data <= 20'h13300;
            12'd2041:
                data <= 20'h1371E;
            12'd2042:
                data <= 20'h13400;
            12'd2043:
                data <= 20'h13400;
            12'd2044:
                data <= 20'h13025;
            12'd2045:
                data <= 20'h13144;
            12'd2046:
                data <= 20'h13220;
            12'd2047:
                data <= 20'h13320;
            12'd2048:
                data <= 20'h1371E;
            12'd2049:
                data <= 20'h13400;
            12'd2050:
                data <= 20'h13400;
            12'd2051:
                data <= 20'h13026;
            12'd2052:
                data <= 20'h13144;
            12'd2053:
                data <= 20'h13221;
            12'd2054:
                data <= 20'h13300;
            12'd2055:
                data <= 20'h1371E;
            12'd2056:
                data <= 20'h13400;
            12'd2057:
                data <= 20'h13400;
            12'd2058:
                data <= 20'h13027;
            12'd2059:
                data <= 20'h13144;
            12'd2060:
                data <= 20'h13222;
            12'd2061:
                data <= 20'h13300;
            12'd2062:
                data <= 20'h1371E;
            12'd2063:
                data <= 20'h13400;
            12'd2064:
                data <= 20'h13400;
            12'd2065:
                data <= 20'h13028;
            12'd2066:
                data <= 20'h13144;
            12'd2067:
                data <= 20'h13223;
            12'd2068:
                data <= 20'h13300;
            12'd2069:
                data <= 20'h1371E;
            12'd2070:
                data <= 20'h13400;
            12'd2071:
                data <= 20'h13400;
            12'd2072:
                data <= 20'h13029;
            12'd2073:
                data <= 20'h13144;
            12'd2074:
                data <= 20'h13224;
            12'd2075:
                data <= 20'h13300;
            12'd2076:
                data <= 20'h1371E;
            12'd2077:
                data <= 20'h13400;
            12'd2078:
                data <= 20'h13400;
            12'd2079:
                data <= 20'h1302A;
            12'd2080:
                data <= 20'h13144;
            12'd2081:
                data <= 20'h13225;
            12'd2082:
                data <= 20'h13300;
            12'd2083:
                data <= 20'h1371E;
            12'd2084:
                data <= 20'h13400;
            12'd2085:
                data <= 20'h13400;
            12'd2086:
                data <= 20'h1302B;
            12'd2087:
                data <= 20'h13144;
            12'd2088:
                data <= 20'h13226;
            12'd2089:
                data <= 20'h13300;
            12'd2090:
                data <= 20'h1371E;
            12'd2091:
                data <= 20'h13400;
            12'd2092:
                data <= 20'h13400;
            12'd2093:
                data <= 20'h1302C;
            12'd2094:
                data <= 20'h13144;
            12'd2095:
                data <= 20'h13227;
            12'd2096:
                data <= 20'h13300;
            12'd2097:
                data <= 20'h1371E;
            12'd2098:
                data <= 20'h13400;
            12'd2099:
                data <= 20'h13400;
            12'd2100:
                data <= 20'h1302D;
            12'd2101:
                data <= 20'h13144;
            12'd2102:
                data <= 20'h13228;
            12'd2103:
                data <= 20'h13300;
            12'd2104:
                data <= 20'h1371E;
            12'd2105:
                data <= 20'h13400;
            12'd2106:
                data <= 20'h13400;
            12'd2107:
                data <= 20'h1302E;
            12'd2108:
                data <= 20'h13144;
            12'd2109:
                data <= 20'h13229;
            12'd2110:
                data <= 20'h13300;
            12'd2111:
                data <= 20'h1371E;
            12'd2112:
                data <= 20'h13400;
            12'd2113:
                data <= 20'h13400;
            12'd2114:
                data <= 20'h1302F;
            12'd2115:
                data <= 20'h13144;
            12'd2116:
                data <= 20'h1322A;
            12'd2117:
                data <= 20'h13300;
            12'd2118:
                data <= 20'h1371E;
            12'd2119:
                data <= 20'h13400;
            12'd2120:
                data <= 20'h13400;
            12'd2121:
                data <= 20'h13030;
            12'd2122:
                data <= 20'h13144;
            12'd2123:
                data <= 20'h1322B;
            12'd2124:
                data <= 20'h13300;
            12'd2125:
                data <= 20'h1371E;
            12'd2126:
                data <= 20'h13400;
            12'd2127:
                data <= 20'h13400;
            12'd2128:
                data <= 20'h13031;
            12'd2129:
                data <= 20'h13144;
            12'd2130:
                data <= 20'h1322C;
            12'd2131:
                data <= 20'h13300;
            12'd2132:
                data <= 20'h1371E;
            12'd2133:
                data <= 20'h13400;
            12'd2134:
                data <= 20'h13400;
            12'd2135:
                data <= 20'h13032;
            12'd2136:
                data <= 20'h13144;
            12'd2137:
                data <= 20'h1322D;
            12'd2138:
                data <= 20'h13300;
            12'd2139:
                data <= 20'h1371E;
            12'd2140:
                data <= 20'h13400;
            12'd2141:
                data <= 20'h13400;
            12'd2142:
                data <= 20'h13033;
            12'd2143:
                data <= 20'h13144;
            12'd2144:
                data <= 20'h1322E;
            12'd2145:
                data <= 20'h13300;
            12'd2146:
                data <= 20'h1371E;
            12'd2147:
                data <= 20'h13400;
            12'd2148:
                data <= 20'h13400;
            12'd2149:
                data <= 20'h13034;
            12'd2150:
                data <= 20'h13144;
            12'd2151:
                data <= 20'h1322F;
            12'd2152:
                data <= 20'h13300;
            12'd2153:
                data <= 20'h1371E;
            12'd2154:
                data <= 20'h13400;
            12'd2155:
                data <= 20'h13400;
            12'd2156:
                data <= 20'h13035;
            12'd2157:
                data <= 20'h13144;
            12'd2158:
                data <= 20'h13230;
            12'd2159:
                data <= 20'h13300;
            12'd2160:
                data <= 20'h1371E;
            12'd2161:
                data <= 20'h13400;
            12'd2162:
                data <= 20'h13400;
            12'd2163:
                data <= 20'h13036;
            12'd2164:
                data <= 20'h13144;
            12'd2165:
                data <= 20'h13231;
            12'd2166:
                data <= 20'h13300;
            12'd2167:
                data <= 20'h1371E;
            12'd2168:
                data <= 20'h13400;
            12'd2169:
                data <= 20'h13400;
            12'd2170:
                data <= 20'h13037;
            12'd2171:
                data <= 20'h13164;
            12'd2172:
                data <= 20'h1322E;
            12'd2173:
                data <= 20'h13320;
            12'd2174:
                data <= 20'h1371E;
            12'd2175:
                data <= 20'h13400;
            12'd2176:
                data <= 20'h13400;
            12'd2177:
                data <= 20'h13038;
            12'd2178:
                data <= 20'h13164;
            12'd2179:
                data <= 20'h1322F;
            12'd2180:
                data <= 20'h13300;
            12'd2181:
                data <= 20'h1371E;
            12'd2182:
                data <= 20'h13400;
            12'd2183:
                data <= 20'h13400;
            12'd2184:
                data <= 20'h13039;
            12'd2185:
                data <= 20'h13164;
            12'd2186:
                data <= 20'h13230;
            12'd2187:
                data <= 20'h13300;
            12'd2188:
                data <= 20'h1371E;
            12'd2189:
                data <= 20'h13400;
            12'd2190:
                data <= 20'h13400;
            12'd2191:
                data <= 20'h1303A;
            12'd2192:
                data <= 20'h13164;
            12'd2193:
                data <= 20'h13231;
            12'd2194:
                data <= 20'h13300;
            12'd2195:
                data <= 20'h1371E;
            12'd2196:
                data <= 20'h13400;
            12'd2197:
                data <= 20'h13400;
            12'd2198:
                data <= 20'h1303B;
            12'd2199:
                data <= 20'h13164;
            12'd2200:
                data <= 20'h13232;
            12'd2201:
                data <= 20'h13300;
            12'd2202:
                data <= 20'h1371E;
            12'd2203:
                data <= 20'h13400;
            12'd2204:
                data <= 20'h13400;
            12'd2205:
                data <= 20'h1303C;
            12'd2206:
                data <= 20'h13164;
            12'd2207:
                data <= 20'h13233;
            12'd2208:
                data <= 20'h13300;
            12'd2209:
                data <= 20'h1371E;
            12'd2210:
                data <= 20'h13400;
            12'd2211:
                data <= 20'h13400;
            12'd2212:
                data <= 20'h1303D;
            12'd2213:
                data <= 20'h13164;
            12'd2214:
                data <= 20'h13234;
            12'd2215:
                data <= 20'h13300;
            12'd2216:
                data <= 20'h1371E;
            12'd2217:
                data <= 20'h13400;
            12'd2218:
                data <= 20'h13400;
            12'd2219:
                data <= 20'h1303E;
            12'd2220:
                data <= 20'h13164;
            12'd2221:
                data <= 20'h13235;
            12'd2222:
                data <= 20'h13300;
            12'd2223:
                data <= 20'h1371E;
            12'd2224:
                data <= 20'h13400;
            12'd2225:
                data <= 20'h13400;
            12'd2226:
                data <= 20'h1303F;
            12'd2227:
                data <= 20'h13164;
            12'd2228:
                data <= 20'h13236;
            12'd2229:
                data <= 20'h13300;
            12'd2230:
                data <= 20'h1371E;
            12'd2231:
                data <= 20'h13400;
            12'd2232:
                data <= 20'h13400;
            12'd2233:
                data <= 20'h13040;
            12'd2234:
                data <= 20'h13164;
            12'd2235:
                data <= 20'h13237;
            12'd2236:
                data <= 20'h13300;
            12'd2237:
                data <= 20'h1371E;
            12'd2238:
                data <= 20'h13400;
            12'd2239:
                data <= 20'h13400;
            12'd2240:
                data <= 20'h13041;
            12'd2241:
                data <= 20'h13164;
            12'd2242:
                data <= 20'h13238;
            12'd2243:
                data <= 20'h13300;
            12'd2244:
                data <= 20'h1371E;
            12'd2245:
                data <= 20'h13400;
            12'd2246:
                data <= 20'h13400;
            12'd2247:
                data <= 20'h13042;
            12'd2248:
                data <= 20'h13165;
            12'd2249:
                data <= 20'h13238;
            12'd2250:
                data <= 20'h13320;
            12'd2251:
                data <= 20'h1371E;
            12'd2252:
                data <= 20'h13400;
            12'd2253:
                data <= 20'h13400;
            12'd2254:
                data <= 20'h13043;
            12'd2255:
                data <= 20'h13166;
            12'd2256:
                data <= 20'h13238;
            12'd2257:
                data <= 20'h13320;
            12'd2258:
                data <= 20'h1371E;
            12'd2259:
                data <= 20'h13400;
            12'd2260:
                data <= 20'h13400;
            12'd2261:
                data <= 20'h13044;
            12'd2262:
                data <= 20'h13167;
            12'd2263:
                data <= 20'h13238;
            12'd2264:
                data <= 20'h13320;
            12'd2265:
                data <= 20'h1371E;
            12'd2266:
                data <= 20'h13400;
            12'd2267:
                data <= 20'h13400;
            12'd2268:
                data <= 20'h13045;
            12'd2269:
                data <= 20'h13168;
            12'd2270:
                data <= 20'h13238;
            12'd2271:
                data <= 20'h13320;
            12'd2272:
                data <= 20'h1371E;
            12'd2273:
                data <= 20'h13400;
            12'd2274:
                data <= 20'h13400;
            12'd2275:
                data <= 20'h13046;
            12'd2276:
                data <= 20'h13169;
            12'd2277:
                data <= 20'h13238;
            12'd2278:
                data <= 20'h13320;
            12'd2279:
                data <= 20'h1371E;
            12'd2280:
                data <= 20'h13400;
            12'd2281:
                data <= 20'h13400;
            12'd2282:
                data <= 20'h13047;
            12'd2283:
                data <= 20'h1316A;
            12'd2284:
                data <= 20'h13238;
            12'd2285:
                data <= 20'h13320;
            12'd2286:
                data <= 20'h1371E;
            12'd2287:
                data <= 20'h13400;
            12'd2288:
                data <= 20'h13400;
            12'd2289:
                data <= 20'h13048;
            12'd2290:
                data <= 20'h1316B;
            12'd2291:
                data <= 20'h13238;
            12'd2292:
                data <= 20'h13320;
            12'd2293:
                data <= 20'h1371E;
            12'd2294:
                data <= 20'h13400;
            12'd2295:
                data <= 20'h13400;
            12'd2296:
                data <= 20'h13049;
            12'd2297:
                data <= 20'h1316C;
            12'd2298:
                data <= 20'h13238;
            12'd2299:
                data <= 20'h13320;
            12'd2300:
                data <= 20'h1371E;
            12'd2301:
                data <= 20'h13400;
            12'd2302:
                data <= 20'h13400;
            12'd2303:
                data <= 20'h1304A;
            12'd2304:
                data <= 20'h1316D;
            12'd2305:
                data <= 20'h13238;
            12'd2306:
                data <= 20'h13320;
            12'd2307:
                data <= 20'h1371E;
            12'd2308:
                data <= 20'h13400;
            12'd2309:
                data <= 20'h13400;
            12'd2310:
                data <= 20'h1304B;
            12'd2311:
                data <= 20'h1316E;
            12'd2312:
                data <= 20'h13238;
            12'd2313:
                data <= 20'h13320;
            12'd2314:
                data <= 20'h1371E;
            12'd2315:
                data <= 20'h13400;
            12'd2316:
                data <= 20'h13400;
            12'd2317:
                data <= 20'h1304C;
            12'd2318:
                data <= 20'h1316F;
            12'd2319:
                data <= 20'h13238;
            12'd2320:
                data <= 20'h13320;
            12'd2321:
                data <= 20'h1371E;
            12'd2322:
                data <= 20'h13400;
            12'd2323:
                data <= 20'h13400;
            12'd2324:
                data <= 20'h1304D;
            12'd2325:
                data <= 20'h13100;
            12'd2326:
                data <= 20'h13200;
            12'd2327:
                data <= 20'h13300;
            12'd2328:
                data <= 20'h1371E;
            12'd2329:
                data <= 20'h13400;
            12'd2330:
                data <= 20'h13400;
            12'd2331:
                data <= 20'h1304E;
            12'd2332:
                data <= 20'h13100;
            12'd2333:
                data <= 20'h13200;
            12'd2334:
                data <= 20'h13300;
            12'd2335:
                data <= 20'h1371E;
            12'd2336:
                data <= 20'h13400;
            12'd2337:
                data <= 20'h13400;
            12'd2338:
                data <= 20'h1304F;
            12'd2339:
                data <= 20'h13100;
            12'd2340:
                data <= 20'h13200;
            12'd2341:
                data <= 20'h13300;
            12'd2342:
                data <= 20'h1371E;
            12'd2343:
                data <= 20'h13400;
            12'd2344:
                data <= 20'h13400;
            12'd2345:
                data <= 20'h13050;
            12'd2346:
                data <= 20'h13100;
            12'd2347:
                data <= 20'h13200;
            12'd2348:
                data <= 20'h13300;
            12'd2349:
                data <= 20'h1371E;
            12'd2350:
                data <= 20'h13400;
            12'd2351:
                data <= 20'h13400;
            12'd2352:
                data <= 20'h13051;
            12'd2353:
                data <= 20'h13100;
            12'd2354:
                data <= 20'h13200;
            12'd2355:
                data <= 20'h13300;
            12'd2356:
                data <= 20'h1371E;
            12'd2357:
                data <= 20'h13400;
            12'd2358:
                data <= 20'h13400;
            12'd2359:
                data <= 20'h13052;
            12'd2360:
                data <= 20'h13100;
            12'd2361:
                data <= 20'h13200;
            12'd2362:
                data <= 20'h13300;
            12'd2363:
                data <= 20'h1371E;
            12'd2364:
                data <= 20'h13400;
            12'd2365:
                data <= 20'h13400;
            12'd2366:
                data <= 20'h13053;
            12'd2367:
                data <= 20'h13100;
            12'd2368:
                data <= 20'h13200;
            12'd2369:
                data <= 20'h13300;
            12'd2370:
                data <= 20'h1371E;
            12'd2371:
                data <= 20'h13400;
            12'd2372:
                data <= 20'h13400;
            12'd2373:
                data <= 20'h13054;
            12'd2374:
                data <= 20'h13100;
            12'd2375:
                data <= 20'h13200;
            12'd2376:
                data <= 20'h13300;
            12'd2377:
                data <= 20'h1371E;
            12'd2378:
                data <= 20'h13400;
            12'd2379:
                data <= 20'h13400;
            12'd2380:
                data <= 20'h13055;
            12'd2381:
                data <= 20'h13100;
            12'd2382:
                data <= 20'h13200;
            12'd2383:
                data <= 20'h13300;
            12'd2384:
                data <= 20'h1371E;
            12'd2385:
                data <= 20'h13400;
            12'd2386:
                data <= 20'h13400;
            12'd2387:
                data <= 20'h13056;
            12'd2388:
                data <= 20'h13100;
            12'd2389:
                data <= 20'h13200;
            12'd2390:
                data <= 20'h13300;
            12'd2391:
                data <= 20'h1371E;
            12'd2392:
                data <= 20'h13400;
            12'd2393:
                data <= 20'h13400;
            12'd2394:
                data <= 20'h13057;
            12'd2395:
                data <= 20'h13100;
            12'd2396:
                data <= 20'h13200;
            12'd2397:
                data <= 20'h13300;
            12'd2398:
                data <= 20'h1371E;
            12'd2399:
                data <= 20'h13400;
            12'd2400:
                data <= 20'h13400;
            12'd2401:
                data <= 20'h13058;
            12'd2402:
                data <= 20'h13100;
            12'd2403:
                data <= 20'h13200;
            12'd2404:
                data <= 20'h13300;
            12'd2405:
                data <= 20'h1371E;
            12'd2406:
                data <= 20'h13400;
            12'd2407:
                data <= 20'h13400;
            12'd2408:
                data <= 20'h13059;
            12'd2409:
                data <= 20'h13100;
            12'd2410:
                data <= 20'h13200;
            12'd2411:
                data <= 20'h13300;
            12'd2412:
                data <= 20'h1371E;
            12'd2413:
                data <= 20'h13400;
            12'd2414:
                data <= 20'h13400;
            12'd2415:
                data <= 20'h1305A;
            12'd2416:
                data <= 20'h13100;
            12'd2417:
                data <= 20'h13200;
            12'd2418:
                data <= 20'h13300;
            12'd2419:
                data <= 20'h1371E;
            12'd2420:
                data <= 20'h13400;
            12'd2421:
                data <= 20'h13400;
            12'd2422:
                data <= 20'h1371A;
            12'd2423:
                data <= 20'h13400;
            12'd2424:
                data <= 20'h13400;
            12'd2425:
                data <= 20'h13700;
            //AGC SLOW ATTACK
            12'd2426:
                data <= 20'h0FAEA;
            12'd2427:
                data <= 20'h0FB08;
            12'd2428:
                data <= 20'h0FC03;
            12'd2429:
                data <= 20'h0FD4C;
            12'd2430:
                data <= 20'h0FE48;
            12'd2431:
                data <= 20'h1006F;
            12'd2432:
                data <= 20'h1010A;
            12'd2433:
                data <= 20'h10308;
            12'd2434:
                data <= 20'h1042F;
            12'd2435:
                data <= 20'h1053A;
            12'd2436:
                data <= 20'h10622;
            12'd2437:
                data <= 20'h1072B;
            12'd2438:
                data <= 20'h10831;
            12'd2439:
                data <= 20'h1110A;
            12'd2440:
                data <= 20'h11A27;
            12'd2441:
                data <= 20'h1200C;
            12'd2442:
                data <= 20'h121AA;
            12'd2443:
                data <= 20'h122AA;
            12'd2444:
                data <= 20'h12311;
            12'd2445:
                data <= 20'h124F5;
            12'd2446:
                data <= 20'h1253B;
            12'd2447:
                data <= 20'h12803;
            12'd2448:
                data <= 20'h12956;
            12'd2449:
                data <= 20'h12A22;
            //RX BASEBAND FILTER
            12'd2450:
                data <= 20'h1FB00;	//02
            12'd2451:
                data <= 20'h1FC40;
            12'd2452:
                data <= 20'h1F8A2;	//21
            12'd2453:
                data <= 20'h1F91E; //1F
            12'd2454:
                data <= 20'h1D53F;
            12'd2455:
                data <= 20'h1C003;
            12'd2456:
                data <= 20'h1E202;
            12'd2457:
                data <= 20'h1E302;
            12'd2458:
                data <= 20'h01680;
            12'd2459:
                data <= 20'h40000;
            12'd2460:
                data <= 20'h1E203;
            12'd2461:
                data <= 20'h1E303;
            //************************************************************
            // TX Baseband Filter Tuning (Real BW: 2.500000 MHz) 3dB Filter
            // Corner @ 4.000000 MHz)
            //************************************************************
            12'd2462:
                data <= 20'h0D68E;	//1D
            12'd2463:
                data <= 20'h0D71E;
            12'd2464:
                data <= 20'h0CA22;
            12'd2465:
                data <= 20'h01640;
            12'd2466:
                data <= 20'h40000;
            12'd2467:
                data <= 20'h0CA26;
            12'd2468:
                data <= 20'h1DBE0;
            12'd2469:
                data <= 20'h1DD6D; //15
            12'd2470:
                data <= 20'h1DF6D; //15
            12'd2471:
                data <= 20'h1DC40;
            12'd2472:
                data <= 20'h1DE40;
            //************************************************************
            // TX Secondary Filter Calibration Setup:  Real Bandwidth
            // 2.500000MHz, 3dB Corner @ 12.500000MHz
            //************************************************************
            12'd2473:
                data <= 20'h0D23F; //34
            12'd2474:
                data <= 20'h0D101; //01
            12'd2475:
                data <= 20'h0D059;
            12'd2476:
                data <= 20'h20000;
            12'd2477:
                data <= 20'h20100;
            12'd2478:
                data <= 20'h20200;
            12'd2479:
                data <= 20'h20324;
            12'd2480:
                data <= 20'h20424;
            12'd2481:
                data <= 20'h20500;
            12'd2482:
                data <= 20'h20600;
            12'd2483:
                data <= 20'h2077C;
            12'd2484:
                data <= 20'h20850; //4F
            12'd2485:
                data <= 20'h2093C;
            12'd2486:
                data <= 20'h20A4B;
            12'd2487:
                data <= 20'h20B32;
            12'd2488:
                data <= 20'h20C4E;
            12'd2489:
                data <= 20'h20D30;
            12'd2490:
                data <= 20'h20E00;
            12'd2491:
                data <= 20'h20F7F;
            12'd2492:
                data <= 20'h2107F;
            12'd2493:
                data <= 20'h2117F;
            12'd2494:
                data <= 20'h21249;
            12'd2495:
                data <= 20'h21349;
            12'd2496:
                data <= 20'h21449;
            12'd2497:
                data <= 20'h2154C;
            12'd2498:
                data <= 20'h2164C;
            12'd2499:
                data <= 20'h2174C;
            12'd2500:
                data <= 20'h2182E;
            12'd2501:
                data <= 20'h21999;
            12'd2502:
                data <= 20'h21A1C;
            12'd2503:
                data <= 20'h21B14;
            12'd2504:
                data <= 20'h21C99;
            12'd2505:
                data <= 20'h21D1C;
            12'd2506:
                data <= 20'h21E13;
            12'd2507:
                data <= 20'h21F98;
            12'd2508:
                data <= 20'h2201C;
            12'd2509:
                data <= 20'h22127;
            12'd2510:
                data <= 20'h22228;
            12'd2511:
                data <= 20'h22340;
            12'd2512:
                data <= 20'h22440;
            12'd2513:
                data <= 20'h2252C;
            12'd2514:
                data <= 20'h22600;
            12'd2515:
                data <= 20'h22700;
            12'd2516:
                data <= 20'h1933F;
            12'd2517:
                data <= 20'h1900F;
            12'd2518:
                data <= 20'h19401;
            12'd2519:
                data <= 20'h01601;
            12'd2520:
                data <= 20'h40000;
            12'd2521:
                data <= 20'h18520;
            12'd2522:
                data <= 20'h18632;
            12'd2523:
                data <= 20'h18724;
            12'd2524:
                data <= 20'h18B83;
            12'd2525:
                data <= 20'h18805;
            12'd2526:
                data <= 20'h18930;
            12'd2527:
                data <= 20'h01602;
            12'd2528:
                data <= 20'h40000;
            12'd2529:
                data <= 20'h0A015;
            12'd2530:
                data <= 20'h0A300;
            12'd2531:
                data <= 20'h0A17B;
            12'd2532:
                data <= 20'h0A9FF;
            12'd2533:
                data <= 20'h0A27F;
            12'd2534:
                data <= 20'h0A501;
            12'd2535:
                data <= 20'h0A601;
            12'd2536:
                data <= 20'h0AA25;
            12'd2537:
                data <= 20'h0A4F0;
            12'd2538:
                data <= 20'h0AE00;
            12'd2539:
                data <= 20'h169C0;
            12'd2540:
                data <= 20'h01610;
            12'd2541:
                data <= 20'h40000;
            12'd2542:
                data <= 20'h16A75;
            12'd2543:
                data <= 20'h16B95;
            12'd2544:
                data <= 20'h169CF;
            12'd2545:
                data <= 20'h18BAD;
            12'd2546:
                data <= 20'h01210;
            12'd2547:
                data <= 20'h01301;
            12'd2548:
                data <= 20'h01504;
            12'd2549:
                data <= 20'h07300;//设置发射通道1衰减，十六进制转成十进制乘以0.25就是实际的衰减
            12'd2550:
                data <= 20'h07400;
            12'd2551:
                data <= 20'h075FF;
            12'd2552:
                data <= 20'h07600;
            12'd2553:
                data <= 20'h15008;
            12'd2554:
                data <= 20'h15100;
            12'd2555:
                data <= 20'h152FF;
            12'd2556:
                data <= 20'h15300;
            12'd2557:
                data <= 20'h15400;
            12'd2558:
                data <= 20'h15500;
            12'd2559:
                data <= 20'h15600;
            12'd2560:
                data <= 20'h15700;
            12'd2561:
                data <= 20'h15801;
            12'd2562:
                data <= 20'h15C62;
            12'd2563:
                data <= 20'h40000;
            12'd2564:
                data <= 20'h01428;
            12'd2565:
                data <= 20'h80000;
            default :
                data <= 20'h80000;
        endcase
    end
    
endmodule
