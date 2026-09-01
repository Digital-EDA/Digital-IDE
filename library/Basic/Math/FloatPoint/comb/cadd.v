module cadd #(
        parameter EXP = 3,
        parameter FRA = 4
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

    wire 			over;
    wire [EXP-1:0]	mexpo;
    wire [FRA:0]	ofracA;
    wire [FRA:0]	ofracB;

    pairStep #(
        .EXP 		( EXP 		),
        .FRA 		( FRA 		))
    u_pairStep(
        //ports
        .expoA  		( expoA  		), 
        .expoB  		( expoB  		),
        .ifracA 		( fracA 		), 
        .ifracB 		( fracB 		),

        .over   		( over   		),
        .oexpo  		( mexpo  		),
        .ofracA 		( ofracA 		),
        .ofracB 		( ofracB 		)
    );

    wire compare = ofracA > ofracB;
    wire state   = signA ^ signB;

    reg           sign;
    reg [FRA+1:0] ifrac;
    reg [EXP-1:0] iexpo;

    always @(*) begin
        if(aresetn) begin
            sign            <= 1'b0;
            ifrac           <= 1'b0;
            iexpo           <= 1'b0;
        end
        else if(valid) begin
            //input: big output: big
            if(expoA == 2**EXP - 1 || expoB == 2**EXP - 1) begin
                sign        <= 1'b0;
                iexpo       <= 2**EXP - 1;
                ifrac       <= {1'b1,{(FRA){1'b0}}};
            end
            //A: small B: small output: small
            else if(expoA == {(EXP){1'b0}} && expoB == {(EXP){1'b0}}) begin
                sign        <= 1'b0;
                iexpo       <= {(EXP){1'b0}};
                ifrac       <= {2'b01,{(FRA){1'b0}}};
            end
            //A: small output: B
            else if(expoA == {(EXP){1'b0}}) begin
                sign        <= signB;
                iexpo       <= expoB;
                ifrac       <= {1'b0,fracB};
            end
            //B: small output: A
            else if(expoB == {(EXP){1'b0}}) begin
                sign  <= signA;
                iexpo <= expoA;
                ifrac <= {1'b0,fracA};
            end
            else begin
                iexpo <= mexpo;
                sign  <= (ofracA == ofracB) ? 1'b0 : compare ? signA : signB;
                if(state) begin
                    if(compare)
                        ifrac <= ofracA - ofracB;
                    else
                        ifrac <= ofracB - ofracA;
                end
                else begin
                    ifrac <= ofracA + ofracB;
                end
            end
        end
        else begin
            sign  <= 1'b0;
            ifrac <= 1'b0;
            iexpo <= 1'b0;
        end
    end

    wire [EXP-1:0]	oexpo;
    wire [FRA-1:0]	ofrac;

    normal #(
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

        .flag 	(flag)
    );

    // ���ʱ˭���˭�ķ���
    pack #(
        .EXP 		( EXP 		),
        .FRA 		( FRA 		))
    u_pack(
        //ports
        .S_tvalid	( 1'b1		),
        .out  		( Y  		),
        .sign 		( sign 		),
        .expo 		( oexpo 	),
        .frac 		( ofrac 	)
    );

endmodule  //add_sub






