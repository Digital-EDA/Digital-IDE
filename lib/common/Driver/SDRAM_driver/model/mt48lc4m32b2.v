//////////////////////////////////////////////////////////////////////////////
//  File name : mt48lc4m32b2.v
//////////////////////////////////////////////////////////////////////////////
//  Copyright (C) 2006 Free Model Foundry; http://www.freemodelfoundry.com
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//
//  MODIFICATION HISTORY:
//
//  version: |  author:       |  mod date:  | changes made:
//    V1.0     I.Milutinovic     06 Apr 18    Initial release
//
//////////////////////////////////////////////////////////////////////////////
//  PART DESCRIPTION:
//
//  Library:    RAM
//  Technology: LVTTL
//  Part:       MT48LC4M32B2
//
//  Description: 1M x 32 x 4Banks SDRAM
//
//////////////////////////////////////////////////////////////////////////////
//  Known Bugs:
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION                                                       //
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/100 ps

module mt48lc4m32b2
    (
     A11      ,
     A10      ,
     A9       ,
     A8       ,
     A7       ,
     A6       ,
     A5       ,
     A4       ,
     A3       ,
     A2       ,
     A1       ,
     A0       ,

     DQ31      ,
     DQ30      ,
     DQ29      ,
     DQ28      ,
     DQ27      ,
     DQ26      ,
     DQ25      ,
     DQ24      ,
     DQ23      ,
     DQ22      ,
     DQ21      ,
     DQ20      ,
     DQ19      ,
     DQ18      ,
     DQ17      ,
     DQ16      ,
     DQ15      ,
     DQ14      ,
     DQ13      ,
     DQ12      ,
     DQ11      ,
     DQ10      ,
     DQ9       ,
     DQ8       ,
     DQ7       ,
     DQ6       ,
     DQ5       ,
     DQ4       ,
     DQ3       ,
     DQ2       ,
     DQ1       ,
     DQ0       ,

     BA0  ,
     BA1  ,
     DQM3 ,
     DQM2 ,
     DQM1 ,
     DQM0 ,
     CLK  ,
     CKE  ,
     WENeg  ,
     RASNeg ,
     CSNeg  ,
     CASNeg );

    ////////////////////////////////////////////////////////////////////////
    // Port / Part Pin Declarations
    ////////////////////////////////////////////////////////////////////////
    input  A11  ;
    input  A10  ;
    input  A9   ;
    input  A8   ;
    input  A7   ;
    input  A6   ;
    input  A5   ;
    input  A4   ;
    input  A3   ;
    input  A2   ;
    input  A1   ;
    input  A0   ;

    inout  DQ31   ;
    inout  DQ30   ;
    inout  DQ29   ;
    inout  DQ28   ;
    inout  DQ27   ;
    inout  DQ26   ;
    inout  DQ25   ;
    inout  DQ24   ;
    inout  DQ23   ;
    inout  DQ22   ;
    inout  DQ21   ;
    inout  DQ20   ;
    inout  DQ19   ;
    inout  DQ18   ;
    inout  DQ17   ;
    inout  DQ16   ;
    inout  DQ15   ;
    inout  DQ14   ;
    inout  DQ13   ;
    inout  DQ12   ;
    inout  DQ11   ;
    inout  DQ10   ;
    inout  DQ9   ;
    inout  DQ8   ;
    inout  DQ7   ;
    inout  DQ6   ;
    inout  DQ5   ;
    inout  DQ4   ;
    inout  DQ3   ;
    inout  DQ2   ;
    inout  DQ1   ;
    inout  DQ0   ;

    input  BA0   ;
    input  BA1   ;
    input  DQM3  ;
    input  DQM2  ;
    input  DQM1  ;
    input  DQM0  ;
    input  CLK   ;
    input  CKE   ;
    input  WENeg  ;
    input  RASNeg ;
    input  CSNeg  ;
    input  CASNeg ;

    // interconnect path delay signals
    wire   A11_ipd  ;
    wire   A10_ipd  ;
    wire   A9_ipd   ;
    wire   A8_ipd   ;
    wire   A7_ipd   ;
    wire   A6_ipd   ;
    wire   A5_ipd   ;
    wire   A4_ipd   ;
    wire   A3_ipd   ;
    wire   A2_ipd   ;
    wire   A1_ipd   ;
    wire   A0_ipd   ;

    wire [11 : 0] A;
    assign        A = {A11_ipd,
                               A10_ipd,
                               A9_ipd,
                               A8_ipd,
                               A7_ipd,
                               A6_ipd,
                               A5_ipd,
                               A4_ipd,
                               A3_ipd,
                               A2_ipd,
                               A1_ipd,
                               A0_ipd };

    wire          DQ31_ipd   ;
    wire          DQ30_ipd   ;
    wire          DQ29_ipd   ;
    wire          DQ28_ipd   ;
    wire          DQ27_ipd   ;
    wire          DQ26_ipd   ;
    wire          DQ25_ipd   ;
    wire          DQ24_ipd   ;
    wire          DQ23_ipd   ;
    wire          DQ22_ipd   ;
    wire          DQ21_ipd   ;
    wire          DQ20_ipd   ;
    wire          DQ19_ipd   ;
    wire          DQ18_ipd   ;
    wire          DQ17_ipd   ;
    wire          DQ16_ipd   ;
    wire          DQ15_ipd   ;
    wire          DQ14_ipd   ;
    wire          DQ13_ipd   ;
    wire          DQ12_ipd   ;
    wire          DQ11_ipd   ;
    wire          DQ10_ipd   ;
    wire          DQ9_ipd   ;
    wire          DQ8_ipd   ;
    wire          DQ7_ipd   ;
    wire          DQ6_ipd   ;
    wire          DQ5_ipd   ;
    wire          DQ4_ipd   ;
    wire          DQ3_ipd   ;
    wire          DQ2_ipd   ;
    wire          DQ1_ipd   ;
    wire          DQ0_ipd   ;

    wire [31 : 0 ] DQIn;
    assign      DQIn = { DQ31_ipd,
                         DQ30_ipd,
                         DQ29_ipd,
                         DQ28_ipd,
                         DQ27_ipd,
                         DQ26_ipd,
                         DQ25_ipd,
                         DQ24_ipd,
                         DQ23_ipd,
                         DQ22_ipd,
                         DQ21_ipd,
                         DQ20_ipd,
                         DQ19_ipd,
                         DQ18_ipd,
                         DQ17_ipd,
                         DQ16_ipd,
                         DQ15_ipd,
                         DQ14_ipd,
                         DQ13_ipd,
                         DQ12_ipd,
                         DQ11_ipd,
                         DQ10_ipd,
                         DQ9_ipd,
                         DQ8_ipd,
                         DQ7_ipd,
                         DQ6_ipd,
                         DQ5_ipd,
                         DQ4_ipd,
                         DQ3_ipd,
                         DQ2_ipd,
                         DQ1_ipd,
                         DQ0_ipd };

    wire [31 : 0] DQOut;
    assign      DQOut = { DQ31,
                          DQ30,
                          DQ29,
                          DQ28,
                          DQ27,
                          DQ26,
                          DQ25,
                          DQ24,
                          DQ23,
                          DQ22,
                          DQ21,
                          DQ20,
                          DQ19,
                          DQ18,
                          DQ17,
                          DQ16,
                          DQ15,
                          DQ14,
                          DQ13,
                          DQ12,
                          DQ11,
                          DQ10,
                          DQ9,
                          DQ8,
                          DQ7,
                          DQ6,
                          DQ5,
                          DQ4,
                          DQ3,
                          DQ2,
                          DQ1,
                          DQ0 };

    wire  BA0_ipd   ;
    wire  BA1_ipd   ;
    wire  DQM3_ipd  ;
    wire  DQM2_ipd  ;
    wire  DQM1_ipd  ;
    wire  DQM0_ipd  ;
    wire  CLK_ipd   ;
    wire  CKE_ipd   ;
    wire  WENeg_ipd  ;
    wire  RASNeg_ipd ;
    wire  CSNeg_ipd  ;
    wire  CASNeg_ipd ;

    integer bank;
    integer bank_tmp;

    //  internal delays
    reg rct_in ;
    reg rct_out;
    reg [3:0] rcdt_in ;
    reg [3:0] rcdt_out;
    reg pre_in        ;
    reg pre_out       ;
    reg refreshed_in  ;
    reg refreshed_out ;
    reg rcar_out      ;
    reg rcar_in       ;
    reg wrt_in        ;
    reg wrt_out       ;
    reg [3:0] ras_in  = 1'b0;
    reg [3:0] ras_out = 1'b0;

    reg [31 : 0] DQ_zd = 32'bz;
    assign {DQ31_zd,
            DQ30_zd,
            DQ29_zd,
            DQ28_zd,
            DQ27_zd,
            DQ26_zd,
            DQ25_zd,
            DQ24_zd,
            DQ23_zd,
            DQ22_zd,
            DQ21_zd,
            DQ20_zd,
            DQ19_zd,
            DQ18_zd,
            DQ17_zd,
            DQ16_zd,
            DQ15_zd,
            DQ14_zd,
            DQ13_zd,
            DQ12_zd,
            DQ11_zd,
            DQ10_zd,
            DQ9_zd,
            DQ8_zd,
            DQ7_zd,
            DQ6_zd,
            DQ5_zd,
            DQ4_zd,
            DQ3_zd,
            DQ2_zd,
            DQ1_zd,
            DQ0_zd } = DQ_zd;

    parameter UserPreload   = 1'b1;
    parameter mem_file_name = "none";  //"mt48lc4m32b2.mem";
    parameter TimingModel   = "DefaultTimingModel";
    parameter PartID        = "mt48lc4m32b2";
    parameter hi_bank       = 3;
    parameter depth         = 25'h100000;

    reg PoweredUp = 1'b0;
    reg CKEreg    = 1'b0;
    reg CAS_Lat ;
    reg CAS_Lat2;
    reg [31:0] DataDrive = 32'bz ;

    // Memory array declaration
    integer Mem [0:(hi_bank+1)*depth*4-1];

    // Type definition for state machine
    parameter pwron           = 5'd0;
    parameter precharge       = 5'd1;
    parameter idle            = 5'd2;
    parameter mode_set        = 5'd3;
    parameter self_refresh    = 5'd4;
    parameter auto_refresh    = 5'd5;
    parameter pwrdwn          = 5'd6;
    parameter bank_act        = 5'd7;
    parameter bank_act_pwrdwn = 5'd8;
    parameter write           = 5'd9;
    parameter write_suspend   = 5'd10;
    parameter read            = 5'd11;
    parameter read_suspend    = 5'd12;
    parameter write_auto_pre  = 5'd13;
    parameter read_auto_pre   = 5'd14;

    reg [4:0] statebank [hi_bank:0];

    // Type definition for commands
    parameter desl = 4'd0;
    parameter nop  = 4'd1;
    parameter bst  = 4'd2;
    parameter rd   = 4'd3;
    parameter writ = 4'd4;
    parameter act  = 4'd5;
    parameter pre  = 4'd6;
    parameter mrs  = 4'd7;
    parameter ref  = 4'd8;

    reg [3:0] command = desl;

    // burst type
    parameter sequential = 1'b0;
    parameter interleave = 1'b1;
    reg Burst ;

    // write burst mode
    parameter programmed = 1'b0;
    parameter single     = 1'b1;
    reg WB ;

    //burst sequences
    integer  intab [0:63];

    reg [19:0] MemAddr [hi_bank:0];
    integer BurstCnt   [hi_bank:0];
    integer StartAddr  [hi_bank:0];
    integer BurstInc   [hi_bank:0];
    integer BaseLoc    [hi_bank:0];

    integer Loc;
    integer BurstLen;
    integer Burst_Bits;

    reg written = 1'b0;
    reg chip_en = 1'b0;

    integer cur_bank;
    reg [11:0] ModeReg ;
    integer Ref_Cnt = 0;

    time Next_Ref = 0;
    reg [8*8:1] BankString ;

    reg Viol = 1'b0;
    reg [31:0] DataDriveOut = 32'bz;
    reg [31:0] DataDrive1 = 32'bz;
    reg [31:0] DataDrive2 = 32'bz;
    reg [31:0] DataDrive3 = 32'bz;

    reg DQM0_reg0 ;
    reg DQM0_reg1 ;
    reg DQM0_reg2 ;
    reg DQM1_reg0 ;
    reg DQM1_reg1 ;
    reg DQM1_reg2 ;
    reg DQM2_reg0 ;
    reg DQM2_reg1 ;
    reg DQM2_reg2 ;
    reg DQM3_reg0 ;
    reg DQM3_reg1 ;
    reg DQM3_reg2 ;

    // tdevice values: values for internal delays
    time tdevice_TRC   = 0;
    time tdevice_TRCAR = 0;
    time tdevice_TRCD  = 0;
    time tdevice_TRP   = 0;
    time tdevice_TWR   = 0;

    ///////////////////////////////////////////////////////////////////////////
    //Interconnect Path Delay Section
    ///////////////////////////////////////////////////////////////////////////
    buf   (A11_ipd, A11);
    buf   (A10_ipd, A10);
    buf   (A9_ipd , A9 );
    buf   (A8_ipd , A8 );
    buf   (A7_ipd , A7 );
    buf   (A6_ipd , A6 );
    buf   (A5_ipd , A5 );
    buf   (A4_ipd , A4 );
    buf   (A3_ipd , A3 );
    buf   (A2_ipd , A2 );
    buf   (A1_ipd , A1 );
    buf   (A0_ipd , A0 );

    buf   (DQ31_ipd , DQ31 );
    buf   (DQ30_ipd , DQ30 );
    buf   (DQ29_ipd , DQ29 );
    buf   (DQ28_ipd , DQ28 );
    buf   (DQ27_ipd , DQ27 );
    buf   (DQ26_ipd , DQ26 );
    buf   (DQ25_ipd , DQ25 );
    buf   (DQ24_ipd , DQ24 );
    buf   (DQ23_ipd , DQ23 );
    buf   (DQ22_ipd , DQ22 );
    buf   (DQ21_ipd , DQ21 );
    buf   (DQ20_ipd , DQ20 );
    buf   (DQ19_ipd , DQ19 );
    buf   (DQ18_ipd , DQ18 );
    buf   (DQ17_ipd , DQ17 );
    buf   (DQ16_ipd , DQ16 );
    buf   (DQ15_ipd , DQ15 );
    buf   (DQ14_ipd , DQ14 );
    buf   (DQ13_ipd , DQ13 );
    buf   (DQ12_ipd , DQ12 );
    buf   (DQ11_ipd , DQ11 );
    buf   (DQ10_ipd , DQ10 );
    buf   (DQ9_ipd  , DQ9 );
    buf   (DQ8_ipd  , DQ8 );
    buf   (DQ7_ipd  , DQ7 );
    buf   (DQ6_ipd  , DQ6 );
    buf   (DQ5_ipd  , DQ5 );
    buf   (DQ4_ipd  , DQ4 );
    buf   (DQ3_ipd  , DQ3 );
    buf   (DQ2_ipd  , DQ2 );
    buf   (DQ1_ipd  , DQ1 );
    buf   (DQ0_ipd  , DQ0 );

    buf   (CASNeg_ipd, CASNeg);
    buf   (RASNeg_ipd, RASNeg);
    buf   (BA0_ipd   , BA0   );
    buf   (BA1_ipd   , BA1   );
    buf   (DQM0_ipd  , DQM0  );
    buf   (DQM1_ipd  , DQM1  );
    buf   (DQM2_ipd  , DQM2  );
    buf   (DQM3_ipd  , DQM3  );
    buf   (CLK_ipd   , CLK   );
    buf   (CKE_ipd   , CKE   );
    buf   (WENeg_ipd , WENeg );
    buf   (CSNeg_ipd , CSNeg );

    ///////////////////////////////////////////////////////////////////////////
    // Propagation  delay Section
    ///////////////////////////////////////////////////////////////////////////
    nmos   (DQ31 ,   DQ31_zd  , 1);
    nmos   (DQ30 ,   DQ30_zd  , 1);
    nmos   (DQ29 ,   DQ29_zd  , 1);
    nmos   (DQ28 ,   DQ28_zd  , 1);
    nmos   (DQ27 ,   DQ27_zd  , 1);
    nmos   (DQ26 ,   DQ26_zd  , 1);
    nmos   (DQ25 ,   DQ25_zd  , 1);
    nmos   (DQ24 ,   DQ24_zd  , 1);
    nmos   (DQ23 ,   DQ23_zd  , 1);
    nmos   (DQ22 ,   DQ22_zd  , 1);
    nmos   (DQ21 ,   DQ21_zd  , 1);
    nmos   (DQ20 ,   DQ20_zd  , 1);
    nmos   (DQ19 ,   DQ19_zd  , 1);
    nmos   (DQ18 ,   DQ18_zd  , 1);
    nmos   (DQ17 ,   DQ17_zd  , 1);
    nmos   (DQ16 ,   DQ16_zd  , 1);
    nmos   (DQ15 ,   DQ15_zd  , 1);
    nmos   (DQ14 ,   DQ14_zd  , 1);
    nmos   (DQ13 ,   DQ13_zd  , 1);
    nmos   (DQ12 ,   DQ12_zd  , 1);
    nmos   (DQ11 ,   DQ11_zd  , 1);
    nmos   (DQ10 ,   DQ10_zd  , 1);
    nmos   (DQ9  ,   DQ9_zd   , 1);
    nmos   (DQ8  ,   DQ8_zd   , 1);
    nmos   (DQ7  ,   DQ7_zd   , 1);
    nmos   (DQ6  ,   DQ6_zd   , 1);
    nmos   (DQ5  ,   DQ5_zd   , 1);
    nmos   (DQ4  ,   DQ4_zd   , 1);
    nmos   (DQ3  ,   DQ3_zd   , 1);
    nmos   (DQ2  ,   DQ2_zd   , 1);
    nmos   (DQ1  ,   DQ1_zd   , 1);
    nmos   (DQ0  ,   DQ0_zd   , 1);

    wire deg;
    wire chip_act;
    assign chip_act = chip_en;

    wire chip_act_deg;
    assign chip_act_deg = chip_act && deg;

    wire cas_latency1;
    wire cas_latency2;
    wire cas_latency3;

    assign cas_latency1 = CAS_Lat && ~CAS_Lat2;
    assign cas_latency2 = ~CAS_Lat && CAS_Lat2;
    assign cas_latency3 = CAS_Lat && CAS_Lat2;

    specify
        // tipd delays: interconnect path delays, mapped to input port delays.
        // In Verilog it is not necessary to declare any tipd delay variables,
        // they can be taken from SDF file
        // With all the other delays real delays would be taken from SDF file

        // tpd delays
        specparam   tpd_CLK_DQ1    = 1;
        specparam   tpd_CLK_DQ2    = 1;
        specparam   tpd_CLK_DQ3    = 1;

        // tpw values: pulse widths
        specparam   tpw_CLK_posedge = 1;
        specparam   tpw_CLK_negedge = 1;

        // tsetup values: setup times
        specparam   tsetup_DQ0_CLK  = 1;  // tDS

        // thold values: hold times
        specparam   thold_DQ0_CLK   = 1;  // tDH

        // tperiod_min: minimum clock period = 1/max freq
        specparam    tperiod_CLK_cl0_eq_1_posedge        = 1; //tCK
        specparam    tperiod_CLK_cl1_eq_1_posedge        = 1;
        specparam    tperiod_CLK_cl2_eq_1_posedge        = 1;

        // tdevice values: values for internal delays
        specparam         tdevice_REF      = 15625 ;
        specparam         tdevice_TRASmin  = 42;
        specparam         tdevice_TRASmax  = 120000;

        ///////////////////////////////////////////////////////////////////////
        // Input Port Delays don't require Verilog description
        ///////////////////////////////////////////////////////////////////////
        // Path delays                                                       //
        ///////////////////////////////////////////////////////////////////////
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ0) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ1) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ2) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ3) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ4) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ5) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ6) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ7) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ8) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ9) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ10) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ11) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ12) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ13) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ14) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ15) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ16) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ17) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ18) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ19) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ20) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ21) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ22) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ23) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ24) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ25) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ26) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ27) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ28) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ29) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ30) = tpd_CLK_DQ1;
        if (CAS_Lat && ~CAS_Lat2) (CLK *> DQ31) = tpd_CLK_DQ1;

        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ0) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ1) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ2) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ3) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ4) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ5) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ6) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ7) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ8) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ9) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ10) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ11) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ12) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ13) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ14) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ15) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ16) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ17) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ18) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ19) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ20) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ21) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ22) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ23) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ24) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ25) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ26) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ27) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ28) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ29) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ30) = tpd_CLK_DQ2;
        if (~CAS_Lat && CAS_Lat2) (CLK *> DQ31) = tpd_CLK_DQ2;

        if (CAS_Lat && CAS_Lat2) (CLK *> DQ0) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ1) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ2) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ3) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ4) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ5) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ6) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ7) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ8) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ9) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ10) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ11) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ12) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ13) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ14) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ15) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ16) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ17) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ18) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ19) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ20) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ21) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ22) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ23) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ24) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ25) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ26) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ27) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ28) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ29) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ30) = tpd_CLK_DQ3;
        if (CAS_Lat && CAS_Lat2) (CLK *> DQ31) = tpd_CLK_DQ3;

        ////////////////////////////////////////////////////////////////////////
        // Timing Check Section
        ////////////////////////////////////////////////////////////////////////
        $setup (BA0 , posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (BA1 , posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (DQM0, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (DQM1, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (DQM2, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (DQM3, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (CKE  , posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (WENeg, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (CSNeg, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (CASNeg, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (RASNeg, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);

        $setup (DQ0 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ1 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ2 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ3 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ4 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ5 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ6 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ7 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ8 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ9 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ10 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ11 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ12 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ13 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ14 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ15 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ16 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ17 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ18 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ19 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ20 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ21 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ22 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ23 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ24 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ25 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ26 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ27 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ28 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ29 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ30 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);
        $setup (DQ31 ,posedge CLK &&& chip_act_deg, tsetup_DQ0_CLK, Viol);

        $setup (A0, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A1, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A2, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A3, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A4, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A5, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A6, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A7, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A8, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A9, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A10, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);
        $setup (A11, posedge CLK &&& chip_act, tsetup_DQ0_CLK, Viol);

        $hold (posedge CLK &&& chip_act, BA0, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, BA1, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, DQM0, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, DQM1, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, DQM2, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, DQM3, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, CKE , thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, CASNeg, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, RASNeg, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, WENeg, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, CSNeg, thold_DQ0_CLK, Viol);

        $hold (posedge CLK &&& chip_act, A0, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A1, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A2, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A3, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A4, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A5, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A6, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A7, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A8, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A9, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A10, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act, A11, thold_DQ0_CLK, Viol);

        $hold (posedge CLK &&& chip_act_deg, DQ0, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ1, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ2, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ3, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ4, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ5, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ6, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ7, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ8, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ9, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ10, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ11, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ12, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ13, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ14, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ15, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ16, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ17, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ18, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ19, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ20, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ21, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ22, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ23, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ24, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ25, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ26, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ27, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ28, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ29, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ30, thold_DQ0_CLK, Viol);
        $hold (posedge CLK &&& chip_act_deg, DQ31, thold_DQ0_CLK, Viol);

        $width (posedge CLK &&& chip_act, tpw_CLK_posedge);
        $width (negedge CLK &&& chip_act, tpw_CLK_negedge);

        $period (posedge CLK &&& cas_latency1, tperiod_CLK_cl0_eq_1_posedge);
        $period (posedge CLK &&& cas_latency2, tperiod_CLK_cl1_eq_1_posedge);
        $period (posedge CLK &&& cas_latency3, tperiod_CLK_cl2_eq_1_posedge);

    endspecify

    task generate_out ;
        output [31:0] DataDrive;
        input Bank;
        integer Bank;
        integer location;
    begin
        location = Bank * depth * 4 + Loc;

        DataDrive[7:0] = 8'bx;
        if (Mem[location] > -1)
            DataDrive[7:0] = Mem[location];

        DataDrive[15:8] = 8'bx;
        if (Mem[location+1] > -1)
            DataDrive[15:8] = Mem[location+1];

        DataDrive[23:16] = 8'bx;
        if (Mem[location+2] > -1)
            DataDrive[23:16] = Mem[location+2];

        DataDrive[31:24] = 8'bx;
        if (Mem[location+3] > -1)
            DataDrive[31:24] = Mem[location+3];
    end
    endtask

    task MemWrite;
        input Bank;
        integer Bank;
        integer location;
    begin
        location = Bank * depth * 4 + Loc;

        if (~DQM0_ipd)
        begin
            Mem[location] = -1;
            if (~Viol)
                Mem[location] = DQIn[7:0];
        end

        if (~DQM1_ipd)
        begin
            Mem[location+1] = -1;
            if (~Viol)
                Mem[location+1] = DQIn[15:8];
        end

        if (~DQM2_ipd)
        begin
            Mem[location+2] = -1;
            if (~Viol)
                Mem[location+2] = DQIn[23:16];
        end

        if (~DQM3_ipd)
        begin
            Mem[location+3] = -1;
            if (~Viol)
                Mem[location+3] = DQIn[31:24];
        end
    end
    endtask

    task BurstIncProc;
        input Bank;
        integer Bank;
    begin
        BurstInc[Bank] = 0;
        if (Burst_Bits == 1)
            BurstInc[Bank] = A[0:0];
        if (Burst_Bits == 2)
            BurstInc[Bank] = A[1:0];
        if (Burst_Bits == 3)
            BurstInc[Bank] = A[2:0];
        if (Burst_Bits == 7)
            BurstInc[Bank] = A[6:0];
    end
    endtask

    task NextStateAuto;
        input Bank;
        input state;
        integer Bank;
        reg [4:0] state;
    begin
        if (~A[10])
            statebank[Bank] = state;
        else if (A[10])
            if (state == write)
                statebank[Bank] = write_auto_pre;
            else
                statebank[Bank] = read_auto_pre;
    end
    endtask

    //////////////////////////////////////////////////////////////////////////
    // Main Behavior Block                                                  //
    //////////////////////////////////////////////////////////////////////////

    // chech when data is generated from model to avoid setup/hold check in
    // those occasion
    reg   deq;
    always @(DQIn, DQOut)
        begin
            if (DQIn==DQOut)
                deq=1'b1;
            else
                deq=1'b0;
        end
    assign deg=deq;

    // initialize burst sequences
    initial
    begin
        intab[0] = 0;
        intab[1] = 1;
        intab[2] = 2;
        intab[3] = 3;
        intab[4] = 4;
        intab[5] = 5;
        intab[6] = 6;
        intab[7] = 7;
        intab[8] = 1;
        intab[9] = 0;
        intab[10] = 3;
        intab[11] = 2;
        intab[12] = 5;
        intab[13] = 4;
        intab[14] = 7;
        intab[15] = 6;
        intab[16] = 2;
        intab[17] = 3;
        intab[18] = 0;
        intab[19] = 1;
        intab[20] = 6;
        intab[21] = 7;
        intab[22] = 4;
        intab[23] = 5;
        intab[24] = 3;
        intab[25] = 2;
        intab[26] = 1;
        intab[27] = 0;
        intab[28] = 7;
        intab[29] = 6;
        intab[30] = 5;
        intab[31] = 4;
        intab[32] = 4;
        intab[33] = 5;
        intab[34] = 6;
        intab[35] = 7;
        intab[36] = 0;
        intab[37] = 1;
        intab[38] = 2;
        intab[39] = 3;
        intab[40] = 5;
        intab[41] = 4;
        intab[42] = 7;
        intab[43] = 6;
        intab[44] = 1;
        intab[45] = 0;
        intab[46] = 3;
        intab[47] = 2;
        intab[48] = 6;
        intab[49] = 7;
        intab[50] = 4;
        intab[51] = 5;
        intab[52] = 2;
        intab[53] = 3;
        intab[54] = 0;
        intab[55] = 1;
        intab[56] = 7;
        intab[57] = 6;
        intab[58] = 5;
        intab[59] = 4;
        intab[60] = 3;
        intab[61] = 2;
        intab[62] = 1;
        intab[63] = 0;
    end

    // initialize memory and load preload files if any
    initial
    begin: InitMemory
    integer i;
        for (i=0; i<=((hi_bank+1)*depth*4 - 1); i=i+1)
        begin
            Mem[i] = -1;
        end
        // Memory preload file
        // mt48lc4m32b2.mem file
        //   @bbbbbb - <bbbbbb> stands for address within memory,
        //   dd      - <dd> is word to be written at Mem(bbbbbb++)
        //              (bbbbbb is incremented at every load)
        if (UserPreload && !(mem_file_name == "none"))
            $readmemh(mem_file_name,Mem);
    end

    //Power Up time 100 us;
    initial
    begin
        PoweredUp = 1'b0;
        statebank[0] = pwron;
        statebank[1] = pwron;
        statebank[2] = pwron;
        statebank[3] = pwron;
        #100000 PoweredUp = 1'b1;
    end

    always @(posedge wrt_in)
    begin:TWRrise
        #tdevice_TWR wrt_out = wrt_in;
    end

    always @(negedge wrt_in)
    begin:TWRfall
        #1 wrt_out = wrt_in;
    end

    always @(posedge ras_in[0])
    begin:TRASrise0
        ras_out[0] <= #tdevice_TRASmin ras_in[0];
    end

    always @(negedge ras_in[0])
    begin:TRASfall0
        ras_out[0] <= #tdevice_TRASmax ras_in[0];
    end

    always @(posedge ras_in[1])
    begin:TRASrise1
        ras_out[1] <= #tdevice_TRASmin ras_in[1];
    end

    always @(negedge ras_in[1])
    begin:TRASfall1
        ras_out[1] <= #tdevice_TRASmax ras_in[1];
    end

    always @(posedge ras_in[2])
    begin:TRASrise2
        ras_out[2] <= #tdevice_TRASmin ras_in[2];
    end
    always @(negedge ras_in[2])
    begin:TRASfall2
        ras_out[2] <= #tdevice_TRASmax ras_in[2];
    end

    always @(posedge ras_in[3])
    begin:TRASrise3
        ras_out[3] <= #tdevice_TRASmin ras_in[3];
    end

    always @(negedge ras_in[3])
    begin:TRASfall3
        ras_out[3] <= #tdevice_TRASmax ras_in[3];
    end

    always @(posedge rcdt_in[0])
    begin:TRCDrise0
        rcdt_out[0] <= #5 1'b1;
    end
    always @(negedge rcdt_in[0])
    begin:TRCDfall0
        rcdt_out[0] <= #tdevice_TRCD 1'b0;
    end

    always @(posedge rcdt_in[1])
    begin:TRCDrise1
        rcdt_out[1] <= #5 1'b1;
    end
    always @(negedge rcdt_in[1])
    begin:TRCDfall1
        rcdt_out[1] <= #tdevice_TRCD 1'b0;
    end

    always @(posedge rcdt_in[2])
    begin:TRCDrise2
        rcdt_out[2] <= #5 1'b1;
    end
    always @(negedge rcdt_in[2])
    begin:TRCDfall2
        rcdt_out[2] <= #tdevice_TRCD 1'b0;
    end

    always @(posedge rcdt_in[3])
    begin:TRCDrise3
        rcdt_out[3] <= #5 1'b1;
    end
    always @(negedge rcdt_in[3])
    begin:TRCDfall3
        rcdt_out[3] <= #tdevice_TRCD 1'b0;
    end

    /////////////////////////////////////////////////////////////////////////
    // Functional Section
    /////////////////////////////////////////////////////////////////////////
    always @(posedge CLK)
    begin
        if ($time > Next_Ref && PoweredUp && Ref_Cnt > 0)
        begin
            Ref_Cnt = Ref_Cnt - 1;
            Next_Ref = $time + tdevice_REF;
        end
        if (CKEreg)
        begin
            if (~CSNeg_ipd)
                chip_en = 1;
            else
                chip_en = 0;
        end

        if (CKEreg && ~CSNeg_ipd)
        begin
            if (DQM0_ipd == 1'bx)
                $display(" Unusable value for DQM0 ");
            if (DQM1_ipd == 1'bx)
                $display(" Unusable value for DQM1 ");
            if (DQM2_ipd == 1'bx)
                $display(" Unusable value for DQM2 ");
            if (DQM3_ipd == 1'bx)
                $display(" Unusable value for DQM3 ");
            if (WENeg_ipd == 1'bx)
                $display(" Unusable value for WENeg ");
            if (RASNeg_ipd == 1'bx)
                $display(" Unusable value for RASNeg ");
            if (CASNeg_ipd == 1'bx)
                $display(" Unusable value for CASNeg ");

            // Command Decode
            if (RASNeg_ipd && CASNeg_ipd && WENeg_ipd)
                command = nop;
            else if (~RASNeg_ipd && CASNeg_ipd && WENeg_ipd)
                command = act;
            else if (RASNeg_ipd && ~CASNeg_ipd && WENeg_ipd)
                command = rd;
            else if (RASNeg_ipd && ~CASNeg_ipd && ~WENeg_ipd)
                command = writ;
            else if (RASNeg_ipd && CASNeg_ipd && ~WENeg_ipd)
                command = bst;
            else if (~RASNeg_ipd && CASNeg_ipd && ~WENeg_ipd)
                command = pre;
            else if (~RASNeg_ipd && ~CASNeg_ipd && WENeg_ipd)
                command = ref;
            else if (~RASNeg_ipd && ~CASNeg_ipd && ~WENeg_ipd)
                command = mrs;

            //  PowerUp Check
            if (~(PoweredUp) && command != nop)
            begin
                $display (" Incorrect power up. Command issued before ");
                $display (" power up complete. ");
            end

            //  Bank Decode
            if (~BA0_ipd && ~BA1_ipd)
                cur_bank = 0;
            else if (BA0_ipd && ~BA1_ipd)
                cur_bank = 1;
            else if (~BA0_ipd && BA1_ipd)
                cur_bank = 2;
            else if (BA0_ipd && BA1_ipd)
                cur_bank = 3;
            else
            begin
                $display ("Could not decode bank selection - results");
                $display ("may be incorrect.");
            end
        end

        // The Big State Machine
        if (CKEreg)
        begin
            if (CSNeg_ipd == 1'bx)
                $display ("Unusable value for CSNeg");

            if (CSNeg_ipd)
                command = nop;

            // DQM pipeline
            DQM0_reg2 = DQM0_reg1;
            DQM0_reg1 = DQM0_reg0;
            DQM0_reg0 = DQM0_ipd;
            DQM1_reg2 = DQM1_reg1;
            DQM1_reg1 = DQM1_reg0;
            DQM1_reg0 = DQM1_ipd;
            DQM2_reg2 = DQM2_reg1;
            DQM2_reg1 = DQM2_reg0;
            DQM2_reg0 = DQM2_ipd;
            DQM3_reg2 = DQM3_reg1;
            DQM3_reg1 = DQM3_reg0;
            DQM3_reg0 = DQM3_ipd;

            // by default data drive is Z, might get over written in one
            // of the passes below
            DataDrive = 32'bz;

            for (bank = 0; bank <= hi_bank; bank = bank + 1)
            begin
                case (statebank[bank])
                pwron :
                begin
                    if (~DQM0_ipd)
                    begin
                        $display ("DQM0 must be held high during");
                        $display ("initialization.");
                    end
                    if (~DQM1_ipd)
                    begin
                        $display ("DQM1 must be held high during");
                        $display ("initialization.");
                    end
                    if (~DQM2_ipd)
                    begin
                        $display ("DQM2 must be held high during");
                        $display ("initialization.");
                    end
                    if (~DQM3_ipd)
                    begin
                        $display ("DQM3 must be held high during");
                        $display ("initialization.");
                    end

                    if (~PoweredUp)
                    begin
                        if (command != nop)
                            $display ("Only NOPs allowed during power up.");
                        DataDrive = 32'bz;
                    end
                    else if (command == pre && (cur_bank == bank || A[10]))
                    begin
                        statebank[bank] = precharge;
                        statebank[bank] <= #tdevice_TRP idle;
                    end
                end

                precharge :
                begin
                    if (cur_bank == bank)
                    // It is only an error if this bank is selected
                        if (command != nop && command != pre)
                        begin
                            $display ("Illegal command received ");
                            $display ("during precharge.",$time);
                        end
                end

                idle :
                begin
                    if (command == nop || command == bst || command == pre
                        || cur_bank != bank)
                    begin
                    end
                    else if (command == mrs)
                    begin
                        if (statebank[0] == idle && statebank[1] == idle &&
                            statebank[2] == idle && statebank[3] == idle)
                        begin
                            ModeReg = A;
                            statebank[bank] = mode_set;
                        end
                    end
                    else if (command == ref)
                    begin
                        if (statebank[0] == idle && statebank[1] == idle &&
                            statebank[2] == idle && statebank[3] == idle)
                            if (CKE)
                            begin
                                statebank[bank] = auto_refresh;
                                statebank[bank] <= #tdevice_TRCAR idle;
                            end
                            else
                            begin
                                statebank[0] = self_refresh;
                                statebank[1] = self_refresh;
                                statebank[2] = self_refresh;
                                statebank[3] = self_refresh;
                            end
                    end
                    else if (command == act)
                    begin
                        statebank[bank] = bank_act;
                        ras_in[bank] = 1'b1;
                        ras_in [bank] <= #70 1'b0;
                        rct_in = 1'b1;
                        rct_in <= #1 1'b0;
                        rcdt_in[bank] = 1'b1;
                        rcdt_in[bank] <= #1 1'b0;
                        MemAddr[bank][19:8] = A; // latch row addr
                    end
                    else
               $display ("Illegal command received in idle state.",$time);
                end

                mode_set :
                begin
                    if (ModeReg[7] != 0 || ModeReg[8] != 0)
                        $display ("Illegal operating mode set.");
                    if (command != nop)
                    begin
                        $display ("Illegal command received during mode");
                        $display ("set.",$time);
                    end

                    // read burst length
                    if (ModeReg[2:0] == 3'b000)
                    begin
                        BurstLen = 1;
                        Burst_Bits = 0;
                    end
                    else if (ModeReg[2:0] == 3'b001)
                    begin
                        BurstLen = 2;
                        Burst_Bits = 1;
                    end
                    else if (ModeReg[2:0] == 3'b010)
                    begin
                        BurstLen = 4;
                        Burst_Bits = 2;
                    end
                    else if (ModeReg[2:0] == 3'b011)
                    begin
                        BurstLen = 8;
                        Burst_Bits = 3;
                    end
                    else if (ModeReg[2:0] == 3'b111)
                    begin
                        BurstLen = 256;
                        Burst_Bits = 7;
                    end
                    else
                        $display ("Invalid burst length specified.");

                    // read burst type
                    if (~ModeReg[3])
                        Burst = sequential;
                    else if (ModeReg[3])
                        Burst = interleave;
                    else
                        $display ("Invalid burst type specified.");

                    // read CAS latency
                    if (ModeReg[6:4] == 3'b001)
                    begin
                        CAS_Lat = 1'b1;
                        CAS_Lat2 = 1'b0;
                    end
                    else if (ModeReg[6:4] == 3'b010)
                    begin
                        CAS_Lat = 1'b0;
                        CAS_Lat2 = 1'b1;
                    end
                    else if (ModeReg[6:4] == 3'b011)
                    begin
                        CAS_Lat = 1'b1;
                        CAS_Lat2 = 1'b1;
                    end
                    else
                        $display ("CAS Latency set incorrecty");

                    // write burst mode
                    if (~ModeReg[9])
                        WB = programmed;
                    else if (ModeReg[9])
                        WB = single;
                    else
                        $display ("Invalid burst type specified.");

                    statebank[bank] = idle;
                end

                auto_refresh :
                begin
                    if (Ref_Cnt < 4096)
                        Ref_Cnt = Ref_Cnt + 1;
                    if (command != nop)
                    begin
                        $display ("Illegal command received during");
                        $display ("auto_refresh.",$time);
                    end
                end

                bank_act :
                begin
                    if (command == pre && (cur_bank == bank || A[10]))
                    begin
                        if (~ras_out[bank])
                        begin
                            $display ("precharge command does not meet tRAS");
                            $display ("time", $time);
                        end
                        statebank[bank] = precharge;
                        statebank[bank] <= #tdevice_TRP idle;
                    end
                    else if (command == nop || command == bst
                        || cur_bank != bank)
                    begin
                    end
                    else if (command == rd)
                    begin
                        if (rcdt_out[bank])
                        begin
                            $display ("read command received too soon");
                            $display ("after active",$time);
                        end
                        if (A[10] == 1'bx)
                        begin
                            $display ("A(10) = X during read command.");
                            $display ("Next state unknown.");
                        end
                        MemAddr[bank][7:0] = 8'b0;// clr old addr
                        // latch col addr
                        if (Burst_Bits == 0)
                            MemAddr[bank][7:0] = A[7:0];
                        if (Burst_Bits == 1)
                            MemAddr[bank][7:1] = A[7:1];
                        if (Burst_Bits == 2)
                            MemAddr[bank][7:2] = A[7:2];
                        if (Burst_Bits == 3)
                            MemAddr[bank][7:3] = A[7:3];
                        if (Burst_Bits == 7)
                            MemAddr[bank][7:7] = A[7:7];
                        BurstIncProc(bank);
                        StartAddr[bank] = BurstInc[bank] % 8;
                        BaseLoc[bank] = MemAddr[bank];
                        Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                        generate_out(DataDrive,bank);
                        BurstCnt[bank] = 1;
                        NextStateAuto(bank, read);
                        bank_tmp = bank;
                    end
                    else if (command == writ)
                    begin
                        if (rcdt_out[bank])
                        begin
                            $display ("write command received too soon");
                            $display ("after active",$time);
                        end
                        if (A[10] == 1'bx)
                        begin
                            $display ("A(10) = X during write command.");
                            $display ("Next state unknown.");
                        end
                        MemAddr[bank][7:0] = 8'b0; // clr old addr
                        BurstIncProc(bank);
                        // latch col addr
                        if (Burst_Bits == 0)
                            MemAddr[bank][7:0] = A[7:0];
                        if (Burst_Bits == 1)
                            MemAddr[bank][7:1] = A[7:1];
                        if (Burst_Bits == 2)
                            MemAddr[bank][7:2] = A[7:2];
                        if (Burst_Bits == 3)
                            MemAddr[bank][7:3] = A[7:3];
                        if (Burst_Bits == 7)
                            MemAddr[bank][7:7] = A[7:7];
                        StartAddr[bank] = BurstInc[bank] % 8;
                        BaseLoc[bank] = MemAddr[bank];
                        Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                        MemWrite(bank);
                        BurstCnt[bank] = 1'b1;
                        wrt_in = 1'b1;
                        NextStateAuto(bank, write);
                        written = 1'b1;
                    end
                    else if (cur_bank == bank || command == mrs)
                    begin
                        $display ("Illegal command received in");
                        $display ("active state",$time);
                    end
                end

                write :
                begin
                    if (command == bst)
                    begin
                        statebank[bank] = bank_act;
                        BurstCnt[bank] = 1'b0;
                    end
                    else if (command == rd)
                        if (cur_bank == bank)
                        begin
                            MemAddr[bank][7:0] = 8'b0;// clr old addr
                            BurstIncProc(bank);
                            // latch col addr
                            if (Burst_Bits == 0)
                                MemAddr[bank][7:0] = A[7:0];
                            if (Burst_Bits == 1)
                                MemAddr[bank][7:1] = A[7:1];
                            if (Burst_Bits == 2)
                                MemAddr[bank][7:2] = A[7:2];
                            if (Burst_Bits == 3)
                                MemAddr[bank][7:3] = A[7:3];
                            if (Burst_Bits == 7)
                                MemAddr[bank][7:7] = A[7:7];
                            StartAddr[bank] = BurstInc[bank] % 8;
                            BaseLoc[bank] = MemAddr[bank];
                            Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                            generate_out(DataDrive, bank);
                            BurstCnt[bank] = 1'b1;
                            NextStateAuto(bank, read);
                        end
                        else
                            statebank[bank] = bank_act;
                    else if (command == writ)
                        if (cur_bank == bank)
                        begin
                            MemAddr[bank][7:0] = 8'b0;// clr old addr
                            BurstIncProc(bank);
                            // latch col addr
                            if (Burst_Bits == 0)
                                MemAddr[bank][7:0] = A[7:0];
                            if (Burst_Bits == 1)
                                MemAddr[bank][7:1] = A[7:1];
                            if (Burst_Bits == 2)
                                MemAddr[bank][7:2] = A[7:2];
                            if (Burst_Bits == 3)
                                MemAddr[bank][7:3] = A[7:3];
                            if (Burst_Bits == 7)
                                MemAddr[bank][7:7] = A[7:7];
                            StartAddr[bank] = BurstInc[bank] % 8;
                            BaseLoc[bank] = MemAddr[bank];
                            Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                            MemWrite(bank);
                            BurstCnt[bank] = 1'b1;
                            wrt_in = 1'b1;
                            if (A[10])
                                statebank[bank] = write_auto_pre;
                        end
                        else
                            statebank[bank] = bank_act;
                    else if (command == pre && (cur_bank == bank || A[10]))
                    begin
                        if (~ras_out[bank])
                        begin
                $display ("precharge command does not meet tRAS time",$time);
                        end
                        if (~DQM0_ipd)
                        begin
                            $display ("DQM0 should be held high, data is");
                            $display ("lost.",$time);
                        end
                        if (~DQM1_ipd)
                        begin
                            $display ("DQM1 should be held high, data is");
                            $display ("lost.",$time);
                        end
                        if (~DQM2_ipd)
                        begin
                            $display ("DQM2 should be held high, data is");
                            $display ("lost.",$time);
                        end
                        if (~DQM2_ipd)
                        begin
                            $display ("DQM2 should be held high, data is");
                            $display ("lost.",$time);
                        end
                        wrt_in = 1'b0;
                        statebank[bank] = precharge;
                        statebank[bank] <= #tdevice_TRP idle;
                    end
                    else if (command == nop || cur_bank != bank)
                        if (BurstCnt[bank] == BurstLen || WB == single)
                        begin
                            statebank[bank] = bank_act;
                            BurstCnt[bank] = 1'b0;
                            ras_in[bank] = 1'b1;
                        end
                        else
                        begin
                            if (Burst == sequential)
                                BurstInc[bank] = (BurstInc[bank]+1) % BurstLen;
                            else
                                BurstInc[bank] =
                                intab[StartAddr[bank]*8 + BurstCnt[bank]];
                            Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                            MemWrite(bank);
                            BurstCnt[bank] = BurstCnt[bank] + 1;
                            wrt_in = 1'b1;
                        end
                    else if (cur_bank == bank)
                    $display ("Illegal command received in write state",$time);
                end

                read :
                begin
                    if (command == bst)
                    begin
                        statebank[bank] = bank_act;
                        BurstCnt[bank] = 1'b0;
                    end
                    else if (command == rd)
                        if (cur_bank == bank)
                        begin
                            MemAddr[bank][7:0] = 8'b0;// clr old addr
                            BurstIncProc(bank);
                            // latch col addr
                            if (Burst_Bits == 0)
                                MemAddr[bank][7:0] = A[7:0];
                            if (Burst_Bits == 1)
                                MemAddr[bank][7:1] = A[7:1];
                            if (Burst_Bits == 2)
                                MemAddr[bank][7:2] = A[7:2];
                            if (Burst_Bits == 3)
                                MemAddr[bank][7:3] = A[7:3];
                            if (Burst_Bits == 7)
                                MemAddr[bank][7:7] = A[7:7];
                            StartAddr[bank] = BurstInc[bank] % 8;
                            BaseLoc[bank] = MemAddr[bank];
                            Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                            generate_out(DataDrive, bank);
                            BurstCnt[bank] = 1'b1;
                            NextStateAuto(bank, read);
                        end
                        else
                            statebank[bank] = bank_act;
                    else if (command == writ)
                        if (cur_bank == bank)
                        begin
                            if (rcdt_out[bank])
                            begin
                $display ("write command received too soon after active",$time);
                            end
                            if (A[10] == 1'bx)
                            begin
                                $display ("A(10) = X during write command.");
                                $display ("Next state unknown.");
                            end

                            MemAddr[bank][7:0] = 8'b0;// clr old addr
                            BurstIncProc(bank);
                            // latch col addr
                            if (Burst_Bits == 0)
                                MemAddr[bank][7:0] = A[7:0];
                            if (Burst_Bits == 1)
                                MemAddr[bank][7:1] = A[7:1];
                            if (Burst_Bits == 2)
                                MemAddr[bank][7:2] = A[7:2];
                            if (Burst_Bits == 3)
                                MemAddr[bank][7:3] = A[7:3];
                            if (Burst_Bits == 7)
                                MemAddr[bank][7:7] = A[7:7];
                            StartAddr[bank] = BurstInc[bank] % 8;
                            BaseLoc[bank] = MemAddr[bank];
                            Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                            MemWrite(bank);
                            BurstCnt[bank] = 1'b1;
                            wrt_in = 1'b1;
                            NextStateAuto(bank,write);
                        end
                        else
                            statebank[bank] = bank_act;

                    else if (command == pre && (cur_bank == bank || A[10]))
                    begin
                        if (~ras_out[bank])
                        begin
                  $display ("Precharge command does not meet tRAS time",$time);
                        end
                        statebank[bank] = precharge;
                        statebank[bank] <= #tdevice_TRP idle;
                    end

                    else if (command == nop || cur_bank != bank)
                    begin
                        if (BurstCnt[bank] == BurstLen)
                        begin
                            statebank[bank] = bank_act;
                            BurstCnt[bank] = 1'b0;
                            ras_in[bank] = 1'b1;
                        end
                        else
                        begin
                            if (Burst == sequential)
                                BurstInc[bank] = (BurstInc[bank]+1) % BurstLen;
                            else
                                BurstInc[bank] =
                                intab[StartAddr[bank]*8 + BurstCnt[bank]];

                            Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                            generate_out(DataDrive, bank);
                            BurstCnt[bank] = BurstCnt[bank] + 1;
                        end
                    end
                    else if (cur_bank == bank)
                    $display ("Illegal command received in read state",$time);
                end

                write_auto_pre :
                begin
                    if (command == nop || cur_bank != bank)
                        if (BurstCnt[bank] == BurstLen || WB == single)
                        begin
                            statebank[bank] = precharge;
                            statebank[bank] <= #tdevice_TRP idle;
                            BurstCnt[bank] = 1'b0;
                            ras_in[bank] = 1'b1;
                        end
                        else
                        begin
                            if (Burst == sequential)
                                BurstInc[bank] = (BurstInc[bank]+1) % BurstLen;
                            else
                                BurstInc[bank] =
                                intab[StartAddr[bank]*8 + BurstCnt[bank]];
                            Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                            MemWrite(bank);
                            BurstCnt[bank] = BurstCnt[bank] + 1;
                            wrt_in = 1'b1;
                        end
                    else
                    $display ("Illegal command received in write state.",$time);
                end

                read_auto_pre :
                begin
                    if (command == nop || (cur_bank != bank && command != rd
                        && command != writ))
                        if (BurstCnt[bank] == BurstLen)
                        begin
                            statebank[bank] = precharge;
                            statebank[bank] <= #tdevice_TRP idle;
                            BurstCnt[bank] = 1'b0;
                            ras_in[bank] = 1'b1;
                        end
                        else
                        begin
                            if (Burst == sequential)
                                BurstInc[bank] = (BurstInc[bank]+1) % BurstLen;
                            else
                                BurstInc[bank] =
                                intab[StartAddr[bank]*8 + BurstCnt[bank]];
                            Loc = 4*(BaseLoc[bank] + BurstInc[bank]);
                            generate_out(DataDrive, bank);
                            BurstCnt[bank] = BurstCnt[bank] + 1;
                        end
                    else if ((command == rd || command == writ) && cur_bank
                        != bank)
                    begin
                        statebank[bank] = precharge;
                        statebank[bank] <= #tdevice_TRP idle;
                    end
                    else
                    $display ("Illegal command received in read state",$time);
                end
                endcase
            end

            // Check Refresh Status
            if (written && (Ref_Cnt == 0))
                $display ("memory not refreshed (by ref_cnt)", $time);

            DataDrive3 = DataDrive2;
            DataDrive2 = DataDrive1;
            DataDrive1 = DataDrive;

        end

        //  Latency adjustments and DQM read masking
        if (~DQM0_reg1)
            if (CAS_Lat && CAS_Lat2)
                DataDriveOut[7:0] = DataDrive3[7:0];
            else if (~CAS_Lat && CAS_Lat2)
                DataDriveOut[7:0] = DataDrive2[7:0];
            else
                DataDriveOut[7:0] = DataDrive1[7:0];
        else
            DataDriveOut[7:0] = 8'bz;

        if (~DQM1_reg1)
            if (CAS_Lat && CAS_Lat2)
                DataDriveOut[15:8] = DataDrive3[15:8];
            else if (~CAS_Lat && CAS_Lat2)
                DataDriveOut[15:8] = DataDrive2[15:8];
            else
                DataDriveOut[15:8] = DataDrive1[15:8];
        else
            DataDriveOut[15:8] = 8'bz;

        if (~DQM2_reg1)
            if (CAS_Lat && CAS_Lat2)
                DataDriveOut[23:16] = DataDrive3[23:16];
            else if (~CAS_Lat && CAS_Lat2)
                DataDriveOut[23:16] = DataDrive2[23:16];
            else
                DataDriveOut[23:16] = DataDrive1[23:16];
        else
            DataDriveOut[23:16] = 8'bz;

        if (~DQM3_reg1)
            if (CAS_Lat && CAS_Lat2)
                DataDriveOut[31:24] = DataDrive3[31:24];
            else if (~CAS_Lat && CAS_Lat2)
                DataDriveOut[31:24] = DataDrive2[31:24];
            else
                DataDriveOut[31:24] = DataDrive1[31:24];
        else
            DataDriveOut[31:24] = 8'bz;

        // The Powering-up State Machine
        if (~CKEreg && CKE_ipd)
        begin
            if (CSNeg_ipd == 1'bx)
                $display ("Unusable value for CSNeg");
            if (CSNeg_ipd)
                command = nop;

            case (statebank[cur_bank])
            write_suspend :
            begin
                statebank[cur_bank] = write;
            end

            read_suspend :
            begin
                statebank[cur_bank] = read;
            end

            self_refresh :
            begin
                statebank[0] <= #tdevice_TRP idle;
                statebank[1] <= #tdevice_TRP idle;
                statebank[2] <= #tdevice_TRP idle;
                statebank[3] <= #tdevice_TRP idle;
                Ref_Cnt = 4096;
                if (command != nop)
                begin
                    $display ("Illegal command received during self");
                    $display ("refresh",$time);
                end
            end

            pwrdwn :
            begin
                statebank[0] = idle;
                statebank[1] = idle;
                statebank[2] = idle;
                statebank[3] = idle;
            end

            bank_act_pwrdwn :
            begin
                statebank[cur_bank] = bank_act;
            end
            endcase
        end

        // The Powering-down State Machine
        if (CKEreg && ~CKE_ipd)
        begin
            if (CSNeg_ipd == 1'bx)
                $display ("Unusable value for CSNeg");
            if (CSNeg_ipd)
                command = nop;

            case (statebank[cur_bank])
            idle :
            begin
                if (command == nop)
                begin
                    statebank[0] = pwrdwn;
                    statebank[1] = pwrdwn;
                    statebank[2] = pwrdwn;
                    statebank[3] = pwrdwn;
                end
            end

            write :
            begin
                statebank[cur_bank] = write_suspend;
            end

            read :
            begin
                statebank[cur_bank] = read_suspend;
            end

            bank_act :
            begin
                statebank[cur_bank] = bank_act_pwrdwn;
            end
            endcase
        end

        CKEreg = CKE_ipd;
    end

    always @(DataDriveOut)
    begin
        DQ_zd = DataDriveOut;
    end

    reg TRC_In , TRCAR_In;
    reg TRCD_In , TRP_In , TWR_In;
    wire TRC_Out, TRCAR_Out, TRCD_Out, TRP_Out, TWR_Out;

    BUFFER    BUF_TRC    (TRC_Out  , TRC_In);
    BUFFER    BUF_TRCAR  (TRCAR_Out, TRCAR_In);
    BUFFER    BUF_TRCD   (TRCD_Out , TRCD_In);
    BUFFER    BUF_TRP    (TRP_Out  , TRP_In);
    BUFFER    BUF_TWR    (TWR_Out  , TWR_In);

    initial
    begin
        TRC_In   = 1;
        TRCAR_In = 1;
        TRCD_In  = 1'b1;
        TRP_In   = 1;
        TWR_In   = 1;
    end

    always @(posedge TRC_Out)
    begin
        tdevice_TRC = $time;
    end

    always @(posedge TRCAR_Out)
    begin
        tdevice_TRCAR = $time;
    end

    always @(posedge TRCD_Out)
    begin
        tdevice_TRCD = $time;
    end

    always @(posedge TRP_Out)
    begin
        tdevice_TRP = $time;
    end

    always @(posedge TWR_Out)
    begin
        tdevice_TWR = $time;
    end

endmodule

module BUFFER (OUT,IN);
    input IN;
    output OUT;
        buf (OUT, IN);
endmodule
