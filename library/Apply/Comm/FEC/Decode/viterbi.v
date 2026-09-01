`timescale 1ns / 1ns

module viterbi #(
        parameter POLYNOM_DEPTH = 3, 
        parameter POLYNOM_VSET0 = 3'b111, 
        parameter POLYNOM_VSET1 = 3'b101, 
        parameter DEFAULT_STATE = 3'b000
    )(
        input clock,
        input reset,
        input [1:0] idata,
        input [1:0] ivalid,
        output [POLYNOM_DEPTH-1:0] odata,
        output [POLYNOM_DEPTH-1:0] ovalid,
        output oerror
    );

    localparam DEFAULT_00 = ^({DEFAULT_STATE, 1'b0} & POLYNOM_VSET0);
    localparam DEFAULT_01 = ^({DEFAULT_STATE, 1'b0} & POLYNOM_VSET1);
    localparam DEFAULT_10 = ^({DEFAULT_STATE, 1'b1} & POLYNOM_VSET0);
    localparam DEFAULT_11 = ^({DEFAULT_STATE, 1'b1} & POLYNOM_VSET1);

    /********************************************************************************/
    /* Regs and wires */
    /********************************************************************************/
     
    wire    [1:0]                  w_idata = idata & ivalid;
    reg     [POLYNOM_DEPTH-1:0]    r_odata = 0;
    reg     [POLYNOM_DEPTH-1:0]    r_valid = 0;

    //data decoding after find error
    reg     [POLYNOM_DEPTH-1:0]    r_shift_in = DEFAULT_STATE;

    // code data if input 0 and 1
    reg     [1:0]                  r_mod_in_0 = {DEFAULT_01, DEFAULT_00};
    reg     [1:0]                  r_mod_in_1 = {DEFAULT_11, DEFAULT_10};

    // shift data if input 0 and 1
    wire    [POLYNOM_DEPTH-1:0]    w_shift_in_0 = {r_shift_in, 1'b0};
    wire    [POLYNOM_DEPTH-1:0]    w_shift_in_1 = {r_shift_in, 1'b1};
    wire    [POLYNOM_DEPTH-1:0]    w_shift_in_xx  [3:0];

    //fix erro reg
    reg     [POLYNOM_DEPTH-1:0]    r_flag_error = 0;

    //TODO
    reg     [POLYNOM_DEPTH*2-1:0]  r_mod_in_0d0;
    reg     [POLYNOM_DEPTH*2-1:0]  r_mod_in_0d1;
    reg     [POLYNOM_DEPTH*2-1:0]  r_mod_in_1d0;
    reg     [POLYNOM_DEPTH*2-1:0]  r_mod_in_1d1;

    reg     [POLYNOM_DEPTH*2-1:0]  r_in_data_old;
    reg     [POLYNOM_DEPTH*2-1:0]  r_in_data_mask;
    wire    [POLYNOM_DEPTH*2-1:0]  w_in_data_shift = {r_in_data_old, w_idata};
    wire    [POLYNOM_DEPTH*2-1:0]  w_in_mask_shift = {r_in_data_mask, ivalid};

    reg     [POLYNOM_DEPTH-1:0]    r_decod_in_0dx;
    reg     [POLYNOM_DEPTH-1:0]    r_decod_in_1dx;

    reg     [POLYNOM_DEPTH-1:0]    r_shift_in_0dx = DEFAULT_STATE;
    reg     [POLYNOM_DEPTH-1:0]    r_shift_in_1dx = DEFAULT_STATE;
    wire    [POLYNOM_DEPTH-1:0]    w_shift_in_xdx  [3:0];
    wire    [POLYNOM_DEPTH-1:0]    w_shift_in_xdxx [7:0];
 
    assign odata  = r_odata;
    assign ovalid = r_valid;
    assign oerror = r_flag_error;

    genvar i_xx, i_xxx, i_xdxx;
    generate 
        for(i_xx = 0 ; i_xx < 4; i_xx = i_xx + 1) begin : U_wire_xx
            assign w_shift_in_xx[i_xx] = {r_shift_in, i_xx[1:0]};
        end
        for(i_xdxx = 0 ; i_xdxx < 4; i_xdxx = i_xdxx + 1) begin : U_wire_xdxx
            assign w_shift_in_xdxx[i_xdxx] = {r_shift_in_0dx, i_xdxx[1:0]};
            assign w_shift_in_xdxx[i_xdxx + 4] = {r_shift_in_1dx, i_xdxx[1:0]};
        end
    endgenerate

    assign w_shift_in_xdx[2'b00] = {r_shift_in_0dx, 1'b0};
    assign w_shift_in_xdx[2'b01] = {r_shift_in_0dx, 1'b1};
    assign w_shift_in_xdx[2'b10] = {r_shift_in_1dx, 1'b0};
    assign w_shift_in_xdx[2'b11] = {r_shift_in_1dx, 1'b1};

    always @(posedge clock) begin
        if(reset) begin
            r_mod_in_0 <= {DEFAULT_01, DEFAULT_00};
            r_mod_in_1 <= {DEFAULT_11, DEFAULT_10};
            r_flag_error <= 0;
            r_shift_in <= DEFAULT_STATE;
            r_shift_in_0dx <= DEFAULT_STATE;
            r_shift_in_1dx <= DEFAULT_STATE;
        end
        else begin
            if(ivalid && !r_flag_error) begin : _DEFAULT_decoding
                if(w_idata == (r_mod_in_1 & ivalid)) begin
                    r_shift_in <= w_shift_in_1;
                    r_mod_in_0[0] <= ^(w_shift_in_xx[2'b10] & POLYNOM_VSET0);
                    r_mod_in_0[1] <= ^(w_shift_in_xx[2'b10] & POLYNOM_VSET1);
                    r_mod_in_1[0] <= ^(w_shift_in_xx[2'b11] & POLYNOM_VSET0);
                    r_mod_in_1[1] <= ^(w_shift_in_xx[2'b11] & POLYNOM_VSET1);
                    r_odata[0] <= 1;
                end
                else if(w_idata == (r_mod_in_0 & ivalid)) begin
                    r_shift_in <= w_shift_in_0; 
                    r_mod_in_0[0] <= ^(w_shift_in_xx[2'b00] & POLYNOM_VSET0);
                    r_mod_in_0[1] <= ^(w_shift_in_xx[2'b00] & POLYNOM_VSET1);
                    r_mod_in_1[0] <= ^(w_shift_in_xx[2'b01] & POLYNOM_VSET0);
                    r_mod_in_1[1] <= ^(w_shift_in_xx[2'b01] & POLYNOM_VSET1);
                    r_odata[0] <= 0;
                end
                else begin : _find_error
                    r_flag_error <= 1;

                    r_shift_in_0dx <= w_shift_in_0;
                    r_shift_in_1dx <= w_shift_in_1;

                    r_mod_in_0d0 <= {0, ^(w_shift_in_xx[2'b00] & POLYNOM_VSET1), ^(w_shift_in_xx[2'b00] & POLYNOM_VSET0)};
                    r_mod_in_0d1 <= {0, ^(w_shift_in_xx[2'b01] & POLYNOM_VSET1), ^(w_shift_in_xx[2'b01] & POLYNOM_VSET0)};
                    r_mod_in_1d0 <= {0, ^(w_shift_in_xx[2'b10] & POLYNOM_VSET1), ^(w_shift_in_xx[2'b10] & POLYNOM_VSET0)};
                    r_mod_in_1d1 <= {0, ^(w_shift_in_xx[2'b11] & POLYNOM_VSET1), ^(w_shift_in_xx[2'b11] & POLYNOM_VSET0)};

                    r_decod_in_0dx <= 0;
                    r_decod_in_1dx <= 1;

                    r_in_data_old <= 0;
                    r_in_data_mask <= 0;
                end
            end
            else if(ivalid && r_flag_error) begin : _fix_error
                if(ivalid == 2'b11) begin//if come 2 bytes so i can fix error
                    r_flag_error <= 0;
                    if(w_in_data_shift == (r_mod_in_1d1 & w_in_mask_shift)) begin
                        r_shift_in <= w_shift_in_xdx[2'b11];
                        r_odata <= {r_decod_in_1dx, 1'b1};
                        r_mod_in_0[0] <= ^(w_shift_in_xdxx[3'b110] & POLYNOM_VSET0);
                        r_mod_in_0[1] <= ^(w_shift_in_xdxx[3'b110] & POLYNOM_VSET1);
                        r_mod_in_1[0] <= ^(w_shift_in_xdxx[3'b111] & POLYNOM_VSET0);
                        r_mod_in_1[1] <= ^(w_shift_in_xdxx[3'b111] & POLYNOM_VSET1);
                    end
                    else if(w_in_data_shift == (r_mod_in_1d0 & w_in_mask_shift)) begin
                        r_shift_in <= w_shift_in_xdx[2'b10];
                        r_odata <= {r_decod_in_1dx, 1'b0};
                        r_mod_in_0[0] <= ^(w_shift_in_xdxx[3'b100] & POLYNOM_VSET0);
                        r_mod_in_0[1] <= ^(w_shift_in_xdxx[3'b100] & POLYNOM_VSET1);
                        r_mod_in_1[0] <= ^(w_shift_in_xdxx[3'b101] & POLYNOM_VSET0);
                        r_mod_in_1[1] <= ^(w_shift_in_xdxx[3'b101] & POLYNOM_VSET1);
                    end
                    else if(w_in_data_shift == (r_mod_in_0d1 & w_in_mask_shift)) begin
                        r_shift_in <= w_shift_in_xdx[2'b01];
                        r_odata <= {r_decod_in_0dx, 1'b1};
                        r_mod_in_0[0] <= ^(w_shift_in_xdxx[3'b010] & POLYNOM_VSET0);
                        r_mod_in_0[1] <= ^(w_shift_in_xdxx[3'b010] & POLYNOM_VSET1);
                        r_mod_in_1[0] <= ^(w_shift_in_xdxx[3'b011] & POLYNOM_VSET0);
                        r_mod_in_1[1] <= ^(w_shift_in_xdxx[3'b011] & POLYNOM_VSET1);
                    end
                    else begin
                        r_shift_in <= w_shift_in_xdx[2'b00];
                        r_odata <= {r_decod_in_0dx, 1'b0};
                        r_mod_in_0[0] <= ^(w_shift_in_xdxx[3'b000] & POLYNOM_VSET0);
                        r_mod_in_0[1] <= ^(w_shift_in_xdxx[3'b000] & POLYNOM_VSET1);
                        r_mod_in_1[0] <= ^(w_shift_in_xdxx[3'b001] & POLYNOM_VSET0);
                        r_mod_in_1[1] <= ^(w_shift_in_xdxx[3'b001] & POLYNOM_VSET1);
                    end
                end
                else begin
                    // TODO
                    r_flag_error <= {r_flag_error, 1'b1};
                    
                    r_in_data_old <= {r_in_data_old, w_idata};
                    r_in_data_mask <= {r_in_data_mask, ivalid};


                    // //next posible data
                    if(w_idata == (r_mod_in_0d1 & ivalid))         
                        r_mod_in_0d0 <= {r_mod_in_0d0, /*r_mod_in_0d1[1:0],*/ ^(w_shift_in_xdxx[3'b010] & POLYNOM_VSET1), ^(w_shift_in_xdxx[3'b010] & POLYNOM_VSET0)};
                    else                                            
                        r_mod_in_0d0 <= {r_mod_in_0d0, ^(w_shift_in_xdxx[3'b000] & POLYNOM_VSET1), ^(w_shift_in_xdxx[3'b000] & POLYNOM_VSET0)};

                    if(w_idata == (r_mod_in_0d1 & ivalid))         
                        r_mod_in_0d1 <= {r_mod_in_0d1, ^(w_shift_in_xdxx[3'b011] & POLYNOM_VSET1), ^(w_shift_in_xdxx[3'b011] & POLYNOM_VSET0)};
                    else                                            
                        r_mod_in_0d1 <= {r_mod_in_0d1, /*r_mod_in_0d0[1:0],*/ ^(w_shift_in_xdxx[3'b001] & POLYNOM_VSET1), ^(w_shift_in_xdxx[3'b001] & POLYNOM_VSET0)};

                    if(w_idata == (r_mod_in_1d1 & ivalid))         
                        r_mod_in_1d0 <= {r_mod_in_1d0, /*r_mod_in_1d1[1:0],*/ ^(w_shift_in_xdxx[3'b110] & POLYNOM_VSET1), ^(w_shift_in_xdxx[3'b110] & POLYNOM_VSET0)};
                    else                                            
                        r_mod_in_1d0 <= {r_mod_in_1d0, ^(w_shift_in_xdxx[3'b100] & POLYNOM_VSET1), ^(w_shift_in_xdxx[3'b100] & POLYNOM_VSET0)};

                    if(w_idata == (r_mod_in_1d1 & ivalid))         
                        r_mod_in_1d1 <= {r_mod_in_1d1, ^(w_shift_in_xdxx[3'b111] & POLYNOM_VSET1), ^(w_shift_in_xdxx[3'b111] & POLYNOM_VSET0)};
                    else                                            
                        r_mod_in_1d1 <= {r_mod_in_1d1, /*r_mod_in_1d0[1:0],*/ ^(w_shift_in_xdxx[3'b101] & POLYNOM_VSET1), ^(w_shift_in_xdxx[3'b101] & POLYNOM_VSET0)};


                    //decod shift
                    if(w_idata == (r_mod_in_0d1 & ivalid))         
                        r_shift_in_0dx <= {r_shift_in_0dx, 1'b1};
                    else                                            
                        r_shift_in_0dx <= {r_shift_in_0dx, 1'b0};

                    if(w_idata == (r_mod_in_1d1 & ivalid))         
                        r_shift_in_1dx <= {r_shift_in_1dx, 1'b1};
                    else                                            
                        r_shift_in_1dx <= {r_shift_in_1dx, 1'b0};


                    //decod val
                    if(w_idata == (r_mod_in_0d1 & ivalid))         
                        r_decod_in_0dx <= {r_decod_in_0dx, 1'b1};
                    else                                            
                        r_decod_in_0dx <= {r_decod_in_0dx, 1'b0};

                    if(w_idata == (r_mod_in_1d1 & ivalid))         
                        r_decod_in_1dx <= {r_decod_in_1dx, 1'b1};
                    else                                            
                        r_decod_in_1dx <= {r_decod_in_1dx, 1'b0};

                end
            end
        end
    end

    always @(posedge clock) begin
        if(reset) begin
            r_valid <= 0;
        end
        else begin
            if(ivalid) begin
                if(r_flag_error && ivalid[0] && ivalid[1])        
                    r_valid <= {r_flag_error, 1'b1};
                else if(w_idata == (r_mod_in_0 & ivalid))          
                    r_valid <= !r_flag_error;
                else if(w_idata == (r_mod_in_1 & ivalid))          
                    r_valid <= !r_flag_error;
                else                                                
                    r_valid <= 0;
            end
            else    
                r_valid <= 0;
        end
    end

endmodule