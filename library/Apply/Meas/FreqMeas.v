module FreqMeas #(
        parameter MWIDTH = 32
    )(
        input			        clock,
        input			        reset,

        input			        square,

        input      [MWIDTH-1:0] gateNum,

        output                  ovalid,
        // Gate-in period count of 
        // the square wave to be measured.
        output     [MWIDTH-1:0] squ_cnt
    );

    reg              tgate;
    reg [MWIDTH-1:0] tcount;
    always @(posedge clock or posedge reset) begin        
        if(reset) begin
            tgate  <= 1'b0;
            tcount <= 0;
        end
        else if(tcount >= gateNum) begin
            tgate <= ~tgate;
            tcount <= 0;
        end
        else begin
            tcount <= tcount + 1'b1;
        end
    end

    reg               sgate;
    reg [MWIDTH-1:0]  scount;
    always @(posedge square) begin        
        if(tgate == 1'b1) begin
            sgate <= 1'b1;
        end
        else begin
            sgate <= 1'b0;
        end

        if(sgate == 1'b1) begin
            scount <= scount + 1'b1;
        end
        else begin  
            scount <= 0;
        end
    end

    // always @(negedge square) begin
    //     if(sgate == 1'b1) begin
    //         scount <= scount + 1'b1;
    //     end
    //     else begin  
    //         scount <= 'd0;
    //     end
    // end
    
    reg  gate;
    reg  gate_buf;
    wire gate_neg = ~gate & gate_buf;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            gate <= 1'b0;
            gate_buf <= 1'b0;
        end
        else begin
            gate <= sgate;
            gate_buf <= gate;
        end
    end

    reg               tvalid;
    reg [MWIDTH-1:0]  fre_cnt;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            tvalid  <= 1'b0;
            fre_cnt <= 0;
        end
        else begin            
            if (gate_neg) begin
                fre_cnt <= scount;
            end
            else begin
                fre_cnt <= fre_cnt;
            end

            tvalid <= gate_neg;
        end
    end

    assign ovalid = tvalid;
    assign squ_cnt = fre_cnt;

endmodule