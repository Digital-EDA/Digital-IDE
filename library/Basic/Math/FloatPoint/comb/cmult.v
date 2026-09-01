module cmult #(
        parameter EXP = 4,
        parameter FRA = 3
    ) (
        input			   aresetn,
        input			   valid,
        input  [EXP+FRA:0] A,
        input  [EXP+FRA:0] B,
        output [EXP+FRA:0] Y,
        output [2:0]       flag
    );

    wire 	        signA, signB;
    wire [EXP-1:0]	expoA, expoB;
    wire [FRA:0]	fracA, fracB;

    unpack #(
        .EXP 		( EXP ),
        .FRA 		( FRA ))
    u_unpackA(
        //ports
        .inA   ( A     ), .inB   ( B     ),
        .signA ( signA ), .expoA ( expoA ), .fracA ( fracA ),
        .signB ( signB ), .expoB ( expoB ), .fracB ( fracB )
    );

    reg  [EXP:0]       r_iexpo;
    reg  [EXP-1:0]     iexpo;
    reg  [2*FRA+1:0]   fraction;
    reg                r_sign;
    reg                sign;
    reg  [FRA:0]       r_ifrac;
    reg                r_S_normal_tvalid;
    reg                S_normal_tvalid;
    reg                abnormal_flag;

    //The tail number is multiplied, the index is added and the partial order is reduced
    //Two clock cycles are consumed
    always @(*) begin
        if(aresetn) begin
            r_iexpo             <= 1'b0;
            iexpo               <= 1'b0;
            fraction            <= 1'b0;
            r_sign              <= 1'b0;
            sign                <= r_sign;
            r_ifrac             <= 1'b0;
        end
        else if(valid) begin
            //Determine whether the input is a standard number
            //input: big output: big
            if(expoA == 2**EXP-1 || expoB == 2**EXP-1) begin
                sign            <= 1'b0;
                iexpo           <= 2**EXP - 2;
                r_ifrac         <= {(FRA+1){1'b0}};
            end
            else if(expoA == {(EXP){1'b0}} || expoB == {(EXP){1'b0}}) begin
                sign            <= 1'b0;
                iexpo           <= 2**EXP - 1;
                r_ifrac         <= {(FRA+1){1'b0}};
            end
            else begin
                r_iexpo             <= expoA + expoB;
                fraction            <= fracA * fracB;
                r_sign              <= signA ^ signB;
                //determine whether the result is a standard number
                if(r_iexpo <= (2**(EXP-1)-1)) begin
                    sign                <= 1'b0;
                    iexpo               <= {(EXP){1'b0}};
                    r_ifrac             <= {(FRA+1){1'b0}};
                end
                else begin
                    iexpo               <= r_iexpo - (2**(EXP-1) - 2);
                    sign                <= r_sign;
                    //Self -entry treatment of high positions according to the low position
                    if(fraction[FRA]) begin
                        r_ifrac <= fraction[2*FRA+1:FRA+1] + 1'b1;
                    end
                    else begin
                        r_ifrac <= fraction[2*FRA+1:FRA+1];
                    end
                end
            end
        end
        else begin
            r_iexpo             <= 1'b0;
            iexpo               <= 1'b0;
            fraction            <= 1'b0;
            r_sign              <= 1'b0;
            sign                <= r_sign;
            r_ifrac             <= 1'b0;
        end
    end

    wire [FRA     : 0] ifrac;
    wire [FRA - 1 : 0] ofrac;
    wire [EXP - 1 : 0] oexpo;

    assign ifrac = r_ifrac;

    normal_mult #(
        .EXP 	(EXP),
        .FRA 	(FRA))
    u_normal(
        .iexpo		(iexpo),
        .ifrac		(ifrac),

        .oexpo		(oexpo),
        .ofrac		(ofrac)
    );

    cksp #(
        .EXP (EXP),
        .FRA (FRA))
    u_cksp(
        .expo	(oexpo),
        .frac	(ofrac),

        .flag	(flag)
    );

    pack #(
        .EXP 		( EXP 		),
        .FRA 		( FRA 		))
    u_pack(
        //ports
        .S_tvalid  (1'b1       ),
        .out  		( Y  		),
        .sign 		( sign 		),
        .expo 		( oexpo 	),
        .frac 		( ofrac 	)
    );


endmodule  //mult
