module unpack #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        input  [EXP+FRA:0]  inA,
        input  [EXP+FRA:0]  inB,

        output              signA,
        output [EXP-1:0]    expoA,
        output [FRA : 0]    fracA,

        output              signB,
        output [EXP-1:0]    expoB,
        output [FRA : 0]    fracB
    );

    assign signA = inA[EXP+FRA];
    assign expoA = inA[EXP+FRA-1:FRA];
    assign fracA = {1'b1,inA[FRA-1:0]};

    assign signB = inB[EXP+FRA];
    assign expoB = inB[EXP+FRA-1:FRA];
    assign fracB = {1'b1,inB[FRA-1:0]};

endmodule  //unpack

module pairStep #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        input  [EXP-1:0] expoA,
        input  [EXP-1:0] expoB,

        input  [FRA:0]   ifracA,
        input  [FRA:0]   ifracB,

        output           over,
        output [EXP-1:0] oexpo,
        output [FRA:0]   ofracA,
        output [FRA:0]   ofracB
    );

    wire [EXP-1:0] preShift = (expoA > expoB) ? 
                            (expoA - expoB) : 
                            (expoB - expoA) ;

    assign over = preShift > (FRA + 1);
    wire [EXP-1:0] nShift = over ? FRA : preShift;

    assign oexpo  = (expoA > expoB) ? expoA : expoB;
    assign ofracA = (expoA > expoB) ? ifracA : (ifracA >> nShift);
    assign ofracB = (expoA > expoB) ? (ifracB >> nShift) : ifracB;

endmodule  //pairStep

module cksp #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        input   [EXP-1:0] expo,
        input   [FRA-1:0] frac,

        output  [2:0]     flag   
    );

    localparam EXP_FULL = 2**EXP - 1;  

    assign flag[0] = ((expo == 0) & (frac == 0)) ? 1 : 0;           // Zero
    assign flag[1] = ((expo == EXP_FULL) & (frac == 0)) ? 1 : 0;    // Inf
    assign flag[2] = ((expo == EXP_FULL) & (frac != 0)) ? 1 : 0;    // NaN

endmodule  //cksp

module pack #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        output  [EXP+FRA:0] out,
        input               sign,
        input [EXP-1:0]     expo,
        input [FRA-1:0]     frac
    );

    assign out = {sign,expo,frac};

endmodule  //pack

module normal #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        input  [4:0]    iexpo,
        input  [11:0]   ifrac,

        output [4:0]    oexpo,
        output [9:0]    ofrac
    );

    assign ofrac = ifrac[11] ? ifrac[10:1] :
                ifrac[10] ? ifrac[9:0]  :
                ifrac[9]  ? {ifrac[8:0],1'b0} :
                ifrac[8]  ? {ifrac[7:0],2'b0} :
                ifrac[7]  ? {ifrac[6:0],3'b0} :
                ifrac[6]  ? {ifrac[5:0],4'b0} :
                ifrac[5]  ? {ifrac[4:0],5'b0} :
                ifrac[4]  ? {ifrac[3:0],6'b0} :
                ifrac[3]  ? {ifrac[2:0],7'b0} :
                ifrac[2]  ? {ifrac[1:0],8'b0} :
                ifrac[1]  ? {ifrac[0:0],9'b0} :
                ifrac[0]  ? 10'b0 : 10'b0;

    assign oexpo = ifrac[11] ? iexpo + 1  :
                ifrac[10] ? iexpo      :
                ifrac[9]  ? iexpo - 1  :
                ifrac[8]  ? iexpo - 2  :
                ifrac[7]  ? iexpo - 3  :
                ifrac[6]  ? iexpo - 4  :
                ifrac[5]  ? iexpo - 5  :
                ifrac[4]  ? iexpo - 6  : 
                ifrac[3]  ? iexpo - 7  : 
                ifrac[2]  ? iexpo - 8  :
                ifrac[1]  ? iexpo - 9  :
                ifrac[0]  ? iexpo - 10 : 0;

endmodule

module normal_mult #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        input  [4:0]    iexpo,
        input  [10:0]   ifrac,

        output [4:0]    oexpo,
        output [9:0]    ofrac
    );

    assign ofrac = ifrac[10] ? ifrac[9:0]        :
                ifrac[9]  ? {ifrac[8:0],1'b0} :
                ifrac[8]  ? {ifrac[7:0],2'b0} :
                ifrac[7]  ? {ifrac[6:0],3'b0} :
                ifrac[6]  ? {ifrac[5:0],4'b0} :
                ifrac[5]  ? {ifrac[4:0],5'b0} :
                ifrac[4]  ? {ifrac[3:0],6'b0} :
                ifrac[3]  ? {ifrac[2:0],7'b0} :
                ifrac[2]  ? {ifrac[1:0],8'b0} :
                ifrac[1]  ? {ifrac[0:0],9'b0} :
                ifrac[0]  ? 10'b0 : 10'b0;

    assign oexpo = ifrac[10] ? iexpo      :
                ifrac[9]  ? iexpo - 1  :
                ifrac[8]  ? iexpo - 2  :
                ifrac[7]  ? iexpo - 3  :
                ifrac[6]  ? iexpo - 4  :
                ifrac[5]  ? iexpo - 5  :
                ifrac[4]  ? iexpo - 6  : 
                ifrac[3]  ? iexpo - 7  : 
                ifrac[2]  ? iexpo - 8  :
                ifrac[1]  ? iexpo - 9  :
                ifrac[0]  ? iexpo - 10 : 0;

endmodule

module unpack_sequential #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        input                   aclk,
        input                   aresetn,

        input  [EXP+FRA:0]      inA,
        input                   S_A_tvalid,

        input  [EXP+FRA:0]      inB,
        input                   S_B_tvalid,

        output reg              signA,
        output reg [EXP-1:0]    expoA,
        output reg [FRA : 0]    fracA,
        output reg              M_A_tvalid,

        output reg              signB,
        output reg [EXP-1:0]    expoB,
        output reg [FRA : 0]    fracB,
        output reg              M_B_tvalid
    );

    always @(posedge aclk or posedge aresetn) begin
        if(aresetn)begin
            signA      <= 1'b0;
            signB      <= 1'b0;
            expoA      <= 1'b0;
            expoB      <= 1'b0;
            fracA      <= 1'b0;
            fracB      <= 1'b0;
            M_A_tvalid <= 1'b0;
            M_B_tvalid <= 1'b0;
        end
        else if(S_A_tvalid && S_B_tvalid)begin
            signA      <= inA[EXP+FRA];
            expoA      <= inA[EXP+FRA-1:FRA];
            fracA      <= {1'b1,inA[FRA-1:0]};
            M_A_tvalid <= 1'b1;
            signB      <= inB[EXP+FRA];
            expoB      <= inB[EXP+FRA-1:FRA];
            fracB      <= {1'b1,inB[FRA-1:0]};
            M_B_tvalid <= 1'b1;
        end
        else begin
            M_A_tvalid <= 1'b0;
            M_B_tvalid <= 1'b0;
        end
    end

endmodule  //unpack

module pairStep_sequential #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        input            aclk,
        input            aresetn,

        input  [EXP-1:0] expoA,
        input            S_A_tvalid,

        input  [EXP-1:0] expoB,
        input            S_B_tvalid,

        input  [FRA:0]   ifracA,
        input  [FRA:0]   ifracB,

        output reg           over,
        output reg [EXP-1:0] oexpo,
        output reg           M_tvalid,

        output reg [FRA:0]   ofracA,
        output reg           M_A_tvalid,

        output reg [FRA:0]   ofracB,
        output reg           M_B_tvalid
    );

    //The master and slave are ready at the same time

    wire [EXP-1:0] preShift = (expoA > expoB) ? 
                            (expoA - expoB) : 
                            (expoB - expoA) ;
    wire           over_reg = preShift > (FRA + 1);    
    wire [EXP-1:0] nShift   = over_reg ? FRA : preShift;

    always @(posedge aclk or posedge aresetn) begin
        if(aresetn)begin
            over       <= 1'b0;
            oexpo      <= 1'b0;
            ofracA     <= 1'b0;
            ofracB     <= 1'b0;
            M_tvalid   <= 1'b0;
            M_A_tvalid <= 1'b0;
            M_B_tvalid <= 1'b0;
        end
        else if(S_A_tvalid && S_B_tvalid)begin
            over       <= over_reg;
            oexpo      <= (expoA > expoB) ? expoA : expoB;
            ofracA     <= (expoA > expoB) ? ifracA : (ifracA >> nShift);
            ofracB     <= (expoA > expoB) ? (ifracB >> nShift) : ifracB;
            M_tvalid   <= 1'b1;
            M_A_tvalid <= 1'b1;
            M_B_tvalid <= 1'b1;
        end
        else begin
            M_tvalid   <= 1'b0;
            M_A_tvalid <= 1'b0;
            M_B_tvalid <= 1'b0;
        end
    end

endmodule  //pairStep

module normal_sequential #(
        parameter EXP = 3,
        parameter FRA = 4
    ) (
        input              aclk,
        input              aresetn,

        input  [4:0]       iexpo,
        input  [11:0]      ifrac,
        input              S_tvalid,

        output reg [4:0]   oexpo,
        output reg [9:0]   ofrac,
        output reg         M_tvalid,
        output reg [3:0]   cnt
    );

    always @(posedge aclk or posedge aresetn) begin
        if(aresetn)begin
            oexpo    <= 1'b0;
            ofrac    <= 1'b0;
            M_tvalid <= 1'b0;
            cnt      <= 1'b0;
        end
        else if(S_tvalid)begin
            M_tvalid <= 1'b1;
            if(ifrac[11])begin
                ofrac <= ifrac[10:1];
                oexpo <= iexpo + 1;
                cnt   <= 4'd11;
            end
            else if(ifrac[10])begin
                ofrac <= ifrac[9:0];
                oexpo <= iexpo;
                cnt   <= 4'd0;
            end
            else if(ifrac[9])begin
                ofrac <= {ifrac[8:0],1'b0};
                oexpo <= iexpo - 1;
                cnt   <= 4'd1;
            end
            else if(ifrac[8])begin
                ofrac <= {ifrac[7:0],2'b0};
                oexpo <= iexpo - 2;
                cnt   <= 4'd2;
            end
            else if(ifrac[7])begin
                ofrac <= {ifrac[6:0],3'b0};
                oexpo <= iexpo - 3;
                cnt   <= 4'd3;
            end
            else if(ifrac[6])begin
                ofrac <= {ifrac[5:0],4'b0};
                oexpo <= iexpo - 4;
                cnt   <= 4'd4;
            end
            else if(ifrac[5])begin
                ofrac <= {ifrac[4:0],5'b0};
                oexpo <= iexpo - 5;
                cnt   <= 4'd5;
            end
            else if(ifrac[4])begin
                ofrac <= {ifrac[3:0],6'b0};
                oexpo <= iexpo - 6;
                cnt   <= 4'd6;
            end
            else if(ifrac[3])begin
                ofrac <= {ifrac[2:0],7'b0};
                oexpo <= iexpo - 7;
                cnt   <= 4'd7;
            end
            else if(ifrac[2])begin
                ofrac <= {ifrac[1:0],8'b0};
                oexpo <= iexpo - 8;
                cnt   <= 4'd8;
            end
            else if(ifrac[1])begin
                ofrac <= {ifrac[0:0],9'b0};
                oexpo <= iexpo - 9;
                cnt   <= 4'd9;
            end
            else if(ifrac[0])begin
                ofrac <= 10'b0;
                oexpo <= iexpo - 10;
                cnt   <= 4'd10;
            end
            else begin
                ofrac <= 10'b0;
                oexpo <= 0;
            end
        end
        else begin
            M_tvalid <= 1'b0;
        end
    end

endmodule


















