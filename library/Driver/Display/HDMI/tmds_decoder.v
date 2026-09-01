/*
----------------------------------------
Stereoscopic Vision System
Senior Design Project - Team 11
California State University, Sacramento
Spring 2015 / Fall 2015
----------------------------------------
TMDS Encoder
Authors:  Miad Rouhani
Description:
  TMDS TMDSdecoder
*/

module tmds_decoder (
        input clock,
        input reset,
        input [9:0] tmds,

        output reg       de,
        output reg [1:0] ctrl,
        output reg [7:0] odata
    );

    localparam CRTPAR0 = 10'b1101010100;
    localparam CRTPAR1 = 10'b0010101011;
    localparam CRTPAR2 = 10'b0101010100;
    localparam CRTPAR3 = 10'b1010101011;

    wire [7:0] data;
    assign data = (tmds[9]) ? ~tmds[7:0] : tmds[7:0];

    always @ (posedge clock or posedge reset) begin
        if (reset) begin
            de <= 0; 
            ctrl <= 0;
            odata <= 0;
        end
        else begin    
            if(tmds==CRTPAR0) begin
                ctrl[0] <= 1'b0;
                ctrl[1]<= 1'b0;
                de <= 1'b0;
            end
            else if (tmds==CRTPAR1) begin
                ctrl[0] <= 1'b1;
                ctrl[1] <= 1'b0;
                de <= 1'b0;
            end
            else if (tmds==CRTPAR2) begin
                ctrl[0] <= 1'b0;
                ctrl[1] <= 1'b1;
                de <= 1'b0;
            end
            else if (tmds==CRTPAR3) begin
                ctrl[0] <= 1'b1;
                ctrl[1] <= 1'b1;
                de <= 1'b0;
            end
            else begin
                odata[0] <= data[0];
                odata[1] <= (tmds[8]) ? (data[1] ^ data[0]) : (data[1] ~^ data[0]);
                odata[2] <= (tmds[8]) ? (data[2] ^ data[1]) : (data[2] ~^ data[1]);
                odata[3] <= (tmds[8]) ? (data[3] ^ data[2]) : (data[3] ~^ data[2]);
                odata[4] <= (tmds[8]) ? (data[4] ^ data[3]) : (data[4] ~^ data[3]);
                odata[5] <= (tmds[8]) ? (data[5] ^ data[4]) : (data[5] ~^ data[4]);
                odata[6] <= (tmds[8]) ? (data[6] ^ data[5]) : (data[6] ~^ data[5]);
                odata[7] <= (tmds[8]) ? (data[7] ^ data[6]) : (data[7] ~^ data[6]);
                de <= 1'b1;
            end
        end
    end

endmodule
