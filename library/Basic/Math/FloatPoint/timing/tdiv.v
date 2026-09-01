module tdiv #(
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
        //input            m_axis_result_tready,

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
    );//one

    reg  [EXP:0]       r_iexpo;
    reg  [EXP-1:0]     iexpo;
    wire [2*FRA+1:0]   r_frac;
    reg  [FRA + 1 : 0] fraction;
    reg  [FRA : 0]     r_ifrac;
    reg                r_sign;
    reg                sign;
    reg                r_S_normal_tvalid;
    reg                S_normal_tvalid;
    reg                abnormal_flag;

    assign r_frac = {fracA,{(FRA+1){1'b0}}};

    //The tail number is multiplied, the index is added and the partial order is reduced
    //Two clock cycles are consumed
    always @(posedge aclk or posedge aresetn) begin
        if(aresetn) begin
            r_iexpo             <= 1'b0;
            iexpo               <= 1'b0;
            fraction            <= 1'b0;
            r_ifrac             <= 1'b0;
            r_sign              <= 1'b0;
            sign                <= 1'b0;
            r_S_normal_tvalid   <= 1'b0;
            S_normal_tvalid     <= 1'b0;
            abnormal_flag       <= 1'b1;
        end
        else if(M_unpack_A_tvalid && M_unpack_B_tvalid) begin
            r_S_normal_tvalid   <= 1'b1;
            S_normal_tvalid     <= r_S_normal_tvalid;
            //whether A is infinitely small
            if(expoA == {(EXP){1'b0}})begin
                abnormal_flag       <= 1'b1;
                //A:small B:small output:big
                if(expoB == {(EXP){1'b0}})begin
                    sign            <= signA ^ signB;
                    iexpo           <= 2**EXP - 2;
                    r_ifrac         <= {(FRA+1){1'b0}};
                end
                //A:small B:other output:small
                else begin
                    sign            <= 1'b0;
                    iexpo           <= 2**EXP - 1;
                    r_ifrac         <= {(FRA+1){1'b0}};
                end
            end
            //A:big B:big output:big
            else if(expoA == 2**EXP - 1)begin
                sign                <= signA ^ signB;
                iexpo               <= 2**EXP - 2;
                r_ifrac             <= {(FRA+1){1'b0}};
                abnormal_flag       <= 1'b1;
            end
            //B:small output: big
            else if(expoB == {(EXP){1'b0}})begin
                sign            <= signA ^ signB;
                iexpo           <= 2**EXP - 2;
                r_ifrac         <= {(FRA+1){1'b0}};
                abnormal_flag   <= 1'b1;
            end
            //B:big output: small
            else if(expoB == 2**EXP - 1)begin
                sign            <= 1'b0;
                iexpo           <= 2**EXP - 1;
                r_ifrac         <= {(FRA+1){1'b0}};
                abnormal_flag   <= 1'b1;
            end
            else begin
                r_iexpo             <= expoA - expoB;
                fraction            <= r_frac/fracB;
                r_sign              <= signA ^ signB;
                abnormal_flag       <= 1'b0;
                //determine whether the result is a standard number
                if(r_iexpo + 2**(EXP-1) <= 1)begin
                    sign                <= 1'b0;
                    iexpo               <= {(EXP){1'b0}};
                    r_ifrac             <= {(FRA+1){1'b0}};
                end
                else begin
                    sign                <= r_sign;
                    iexpo               <= r_iexpo + (2**(EXP-1)-1);
                    //Self -entry treatment of high positions according to the low position
                    if(fraction[0]) begin
                        r_ifrac <= fraction[FRA + 1 : 1] + 1'b1;
                    end
                    else begin
                        r_ifrac <= fraction[FRA + 1 : 1];
                    end
                end
            end
        end
        else begin
            r_iexpo             <= 1'b0;
            iexpo               <= iexpo;
            fraction            <= 1'b0;
            r_ifrac             <= r_ifrac;
            r_sign              <= 1'b0;
            sign                <= r_sign;
            r_S_normal_tvalid   <= 1'b0;
            S_normal_tvalid     <= r_S_normal_tvalid;
            abnormal_flag       <= abnormal_flag;
        end
    end

    wire [FRA + 1 : 0] ifrac;
    wire [FRA - 1 : 0] ofrac;
    wire [EXP - 1 : 0] oexpo;
    wire               M_normal_tvalid;

    assign ifrac = abnormal_flag ? {1'b1,r_ifrac} : {1'b0,r_ifrac};

    //Specify the results
    //One clock cycles are consumed
    normal_sequential #(
        .EXP (EXP),
        .FRA (FRA))
    u_normal_sequential(
        .aclk           (aclk),
        .aresetn        (aresetn),

        .iexpo          (iexpo),
        .ifrac          (ifrac),
        .S_tvalid       (S_normal_tvalid),

        .oexpo          (oexpo),
        .ofrac          (ofrac),
        .M_tvalid       (M_normal_tvalid)
    );

    //Determine whether there are special numbers
    cksp #(
        .EXP (EXP),
        .FRA (FRA))
    u_cksp(
        .S_tvalid (M_normal_tvalid),
        .expo	  (oexpo),
        .frac	  (ofrac),

        .flag 	  (flag)
    );

    //Combine each part of the floating point number
    pack #(
        .EXP 		( EXP 		),
        .FRA 		( FRA 		))
    u_pack(
        //ports
        .S_tvalid  ( M_normal_tvalid    ),
        .out  		( m_axis_result_tdata),
        .sign 		( sign 		),
        .expo 		( oexpo 	),
        .frac 		( ofrac 	)
    );
         
    assign s_axis_a_tready = s_axis_a_tvalid;
    assign s_axis_b_tready = s_axis_b_tvalid;
    assign m_axis_result_tvalid = M_normal_tvalid;

endmodule