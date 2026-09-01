module tadd #(
        parameter EXP = 5,
        parameter FRA = 10
    ) (
        input             aclk,
        input             aresetn,

        //S_AXIS_A
        input [EXP+FRA:0] s_axis_a_tdata,
        input             s_axis_a_tvalid,
        output            s_axis_a_tready,

        //S_AXIS_B
        input [EXP+FRA:0] s_axis_b_tdata,
        input             s_axis_b_tvalid,
        output            s_axis_b_tready,

        //M_AXIS_RESULT
        //m_axis_result_tdata: Output specifications, non-specified number output to 0
        output [EXP+FRA:0] m_axis_result_tdata,
        //the output is invalid
        output             m_axis_result_tvalid,
        //input              m_axis_result_tready,

        //Zero: flag[0]=1  Inf: flag[1] = 1  NaN: flag[2] = 1
        output [2:0]       flag
    );

    wire 	        signA, signB;
    wire [EXP-1:0]	expoA, expoB;
    wire [FRA:0]	fracA, fracB;
    wire            M_unpack_A_tvalid;
    wire            M_unpack_B_tvalid;

    //disassemble for each part of the floating point number
    //One clock cycles are consumed
    unpack_sequential #(
        .EXP (EXP),
        .FRA (FRA))
    u_unpack_sequential(
        .aclk           (aclk),
        .aresetn        (aresetn),

        .inA            (s_axis_a_tdata),
        .S_A_tvalid     (s_axis_a_tvalid),

        .inB            (s_axis_b_tdata),
        .S_B_tvalid     (s_axis_b_tvalid),

        .signA          (signA),
        .expoA          (expoA),
        .fracA          (fracA),
        .M_A_tvalid     (M_unpack_A_tvalid),

        .signB          (signB),
        .expoB          (expoB),
        .fracB          (fracB),
        .M_B_tvalid     (M_unpack_B_tvalid)
    );

    wire 	        over;
    wire [EXP-1:0]	mexpo;
    wire [FRA:0]	ofracA;
    wire [FRA:0]	ofracB;
    wire            M_pairStep_tvalid;
    wire            M_pairStep_A_tvalid;
    wire            M_pairStep_B_tvalid;

    //pairStep
    //One clock cycles are consumed
    pairStep_sequential #(
        .EXP (EXP),
        .FRA (FRA))
    u_pairStep_sequential(
        .aclk               (aclk),
        .aresetn            (aresetn),

        .expoA              (expoA),
        .S_A_tvalid         (M_unpack_A_tvalid),

        .expoB              (expoB),
        .S_B_tvalid         (M_unpack_B_tvalid),

        .ifracA             (fracA),
        .ifracB             (fracB),

        .over               (over),
        .oexpo              (mexpo),
        .M_tvalid           (M_pairStep_tvalid),

        .ofracA             (ofracA),
        .M_A_tvalid         (M_pairStep_A_tvalid),

        .ofracB             (ofracB),
        .M_B_tvalid         (M_pairStep_B_tvalid)
    );

    //add
    //One clock cycles are consumed
    wire compare = ofracA > ofracB;
    reg  state;

    reg  r_signA;
    reg  r_signB;
    reg [EXP-1:0] r_expoA, r_expoB;
    reg [FRA:0]	  r_fracA, r_fracB;

    always @(posedge aclk or posedge aresetn) begin
        if(aresetn) begin
            r_signA <= 1'b0;
            r_signB <= 1'b0;
            r_expoA <= 1'b0;
            r_expoB <= 1'b0;
            r_fracA <= 1'b0;
            r_fracB <= 1'b0;
        end
        else begin
            r_signA <= signA;
            r_signB <= signB;
            r_expoA <= expoA;
            r_expoB <= expoB;
            r_fracA <= fracA;
            r_fracB <= fracB;
        end
    end

    always @(posedge aclk or posedge aresetn) begin
        if(aresetn)
            state <= 1'b0;
        else
            state <= signA ^ signB;
    end

    reg           r_sign;
    reg           sign;
    reg [FRA+1:0] ifrac;
    reg [EXP-1:0] iexpo;

    reg           S_normal_tvalid;

    always @(posedge aclk) begin
        if(aresetn) begin
            r_sign          <= 1'b0;
            ifrac           <= 1'b0;
            iexpo           <= 1'b0;
            S_normal_tvalid <= 1'b0;
        end
        else if(!M_pairStep_tvalid) begin
            S_normal_tvalid <= 1'b0;
        end
        else begin
            S_normal_tvalid <= 1'b1;
            //input: big output: big
            if(expoA == 2**EXP - 1 || expoB == 2**EXP - 1) begin
                r_sign      <= 1'b0;
                iexpo       <= 2**EXP - 1;
                ifrac       <= {1'b1,{(FRA){1'b0}}};
            end
            //A: small B: small output: small
            else if(expoA == {(EXP){1'b0}} && expoB == {(EXP){1'b0}}) begin
                r_sign      <= 1'b0;
                iexpo       <= {(EXP){1'b0}};
                ifrac       <= {2'b01,{(FRA){1'b0}}};
            end
            //A: small output: B
            else if(expoA == {(EXP){1'b0}}) begin
                r_sign      <= r_signB;
                iexpo       <= r_expoB;
                ifrac       <= {1'b0,r_fracB};
            end
            //B: small output: A
            else if(expoB == {(EXP){1'b0}}) begin
                r_sign      <= r_signA;
                iexpo       <= r_expoA;
                ifrac       <= {1'b0,r_fracA};
            end
            else begin
                iexpo           <= mexpo;
                ///sign            <= (ofracA == ofracB) ? 1'b0 : compare ? signA : signB;
                if(ofracA == ofracB) begin
                    sign <= 1'b0;
                end
                else begin
                    if(compare)
                        r_sign <= r_signA;
                    else
                        r_sign <= r_signB;
                end
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
    end

    always @(posedge aclk) begin
        sign   <= r_sign;
    end

    //Specify the results
    //One clock cycles are consumed
    reg  [EXP-1:0]	r_iexpo;
    wire [EXP-1:0]	r_oexpo;
    wire [FRA-1:0]	r_ofrac;
    reg  [EXP-1:0]	oexpo;
    reg  [FRA-1:0]	ofrac;
    wire            M_normal_tvalid;
    wire [3:0]      cnt;

    normal_sequential #(
        .EXP (EXP),
        .FRA (FRA))
    u_normal_sequential(
        .aclk           (aclk),
        .aresetn        (aresetn),

        .iexpo          (iexpo),
        .ifrac          (ifrac),
        .S_tvalid       (S_normal_tvalid),

        .oexpo          (r_oexpo),
        .ofrac          (r_ofrac),
        .M_tvalid       (M_normal_tvalid),
        .cnt            (cnt            )
    );

    always @(posedge aclk) begin
        r_iexpo     <= iexpo;
    end

    always @(*) begin
        //left
        if(cnt != 4'd11) begin
            //not a standard number
            if(r_iexpo < cnt) begin
                oexpo   <= 1'b0;
                ofrac   <= 1'b0;
            end
            else begin
                oexpo   <= r_oexpo;
                ofrac   <= r_ofrac;
            end
        end
        //right
        else begin
            oexpo   <= r_oexpo;
            ofrac   <= r_ofrac;
        end
    end

    //Determine whether there are special numbers
    cksp #(
        .EXP (EXP),
        .FRA (FRA))
    u_cksp(
        .expo	   (oexpo),
        .frac	   (ofrac),

        .flag 	   (flag)
    );

    //Combine each part of the floating point number
    pack #(
        .EXP 		( EXP 		),
        .FRA 		( FRA 		))
    u_pack(
        //ports
        .out  		( m_axis_result_tdata    ),
        .sign 		( sign 		),
        .expo 		( oexpo 	),
        .frac 		( ofrac 	)
    );

    assign s_axis_a_tready      = s_axis_a_tvalid;
    assign s_axis_b_tready      = s_axis_b_tvalid;
    assign m_axis_result_tvalid = M_normal_tvalid;

endmodule
