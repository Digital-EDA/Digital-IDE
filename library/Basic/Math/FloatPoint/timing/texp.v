module exp_taylor #(
        parameter EXP = 5,
        parameter FRA = 10
    ) (
        input   aclk,
        input   aresetn,

        //S_AXIS
        input [EXP+FRA:0] s_axis_tdata,
        input             s_axis_tvalid,
        output            s_axis_tready,

        //M_AXIS_RESULT
        output  [EXP+FRA:0] m_axis_result_tdata,
        output              m_axis_result_tvalid,

        output [2:0]       flag
    );


    // e^x = 1 + x + x^2/2! + x^3/3! + x^4/4! + x^5/5! + x^6/6!
    localparam taylor_iter = 7;

    wire [EXP+FRA:0] mul_out[5:0];

    assign mul_out[0] = s_axis_tdata;

    reg [4:0] valid;

    always @(posedge aclk or posedge aresetn) begin
        if(aresetn) begin
            valid <= 5'b0;
        end
        else begin
            valid <= {valid[3:0],s_axis_tvalid};
        end
    end

    reg             normal_flag;
    reg [EXP+FRA:0] result;

    always @(*) begin
        if(s_axis_tdata[EXP+FRA]) begin
            if(s_axis_tdata > 16'hc8da) begin
                normal_flag <= 1'b0;
                result      <= 16'h0000;
            end
            else begin
                normal_flag <= 1'b1;
                result      <= result;
            end
        end
        else begin
            if(s_axis_tdata > 16'h4980) begin
                normal_flag <= 1'b0;
                result      <= 16'h7c00;
            end
            else begin
                normal_flag <= 1'b1;
                result      <= result;
            end
        end
    end

    genvar i;
    generate
        for(i=0;i<5;i=i+1) begin
            mult #(
                .EXP 		( EXP 		),
                .FRA 		( FRA 		))
            u_nmult(
                //ports
                .aresetn    ( aresetn        ),
                .valid      ( valid[i]       ),
                .A    		 ( s_axis_tdata   ),
                .B    		 ( mul_out[i]     ),
                .Y    		 ( mul_out[i+1]   ),
                .flag 		 (  		      )
            );
        end
    endgenerate

    wire  [15:0] div[4:0];
    wire [15:0] divide[4:0];

    assign divide[0] = 16'h3800;
    assign divide[1] = 16'h3155;
    assign divide[2] = 16'h2955;
    assign divide[3] = 16'h2044;
    assign divide[4] = 16'h15b0;

    genvar j;
    generate
        for(j=0;j<5;j=j+1) begin
            mult #(
                .EXP 		( EXP 		),
                .FRA 		( FRA 		))
            u_div(
                //ports
                .aresetn    ( aresetn        ),
                .valid      ( valid[j]       ),
                .A    		 ( mul_out[j+1]   ),
                .B    		 ( divide[j]      ),
                .Y    		 ( div[j]         ),
                .flag 		 (  		      )
            );
        end
    endgenerate

    //1+x
    wire [15:0] add_one;

    add_sub #(
        .EXP 		( EXP 		),
        .FRA 		( FRA 		))
    u_add_sub(
        //ports
        .aresetn    ( aresetn           ),
        .valid      ( s_axis_tvalid     ),
        .A 		    ( 16'h3c00 		    ),
        .B 		    ( s_axis_tdata 		),
        .Y 		    ( add_one    		),
        .flag       (                   )
    );//the first

    wire [15:0] add_out[5:0];

    assign add_out[0] = add_one;

    genvar k;
    generate
        for(k=0;k<5;k=k+1) begin
            add_sub #(
                .EXP 		( EXP 		),
                .FRA 		( FRA 		))
            u_add(
                //ports
                .aresetn    ( aresetn           ),
                .valid      ( valid[k]          ),
                .A 		    ( add_out[k] 		),
                .B 		    ( div[k] 		    ),
                .Y 		    ( add_out[k+1] 		),
                .flag       (                   )
            );
        end
    endgenerate

    cksp #(
        .EXP (EXP),
        .FRA (FRA))
    u_cksp(
        .S_tvalid (valid[4]),
        .expo	   (m_axis_result_tdata[EXP+FRA-1:FRA]),
        .frac	   (m_axis_result_tdata[FRA-1:0]),

        .flag 	   (flag)
    );

    assign m_axis_result_tdata  = normal_flag ? add_out[5] : result;
    assign m_axis_result_tvalid = valid[4];

endmodule


