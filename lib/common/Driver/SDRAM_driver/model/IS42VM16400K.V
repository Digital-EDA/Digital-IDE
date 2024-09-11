/************************************************************************
*
* Copyright(c) ISSI Inc., 2010
*
* == 64M Low power SDRAM behavioral Model by ESC ==
*
* Address : 1940 Zanker Road San Jose,CA95112-4216,U.S.A.
* Tel : +1-408-969-6600, Fax : +1-408-969-7800
*
* Revision : Rev0.0 (2010.10.4)
*
* Running Options
*  +S50     : Set AC timing parameter for -50(200MHz  )
*  +S60     : Set AC timing parameter for -60(166MHz  )
*  +S75     : Set AC timing parameter for -75(133MHz  )
*  +VERBOSE : Display internal operation status
*
************************************************************************/

`timescale 1ns / 1ps

    module IS42VM16400K (dq, addr, ba, clk, cke, csb, rasb, casb, web, dqm);

    parameter no_of_bank =       2;
    parameter no_of_addr =      12;
    parameter no_of_data =      16;
    parameter no_of_col  =       8;
    parameter no_of_dqm  =       2;
    parameter mem_sizes  = 1048575;


    // Timing Parameters for -50 PC200 
    `ifdef S50
    parameter tAC3 =   5.0;
    parameter tHZ3 =   5.0;
    parameter tAC2 =   8.0;
    parameter tHZ2 =   8.0;
    parameter tOH  =   2.0;
    parameter tMRD =   2.0;
    parameter tRAS =  40.0;
    parameter tRC  =  55.0;
    parameter tRCD =  18.0;
    parameter tRFC =  60.0;
    parameter tXSR =  60.0;
    parameter tRP  =  15.0;
    parameter tRRD =  10.0;
    parameter tDPLa =  5.0;
    parameter tDPLm =  12.0;
    parameter tDPDX =  100000.0;
    `endif


    // Timing Parameters for -60 PC166 
    `ifdef S60
    parameter tAC3 =   5.5;
    parameter tHZ3 =   5.5;
    parameter tAC2 =   8.0;
    parameter tHZ2 =   8.0;
    parameter tOH  =   2.5;
    parameter tMRD =   2.0;     
    parameter tRAS =  42.0;
    parameter tRC  =  60.0;
    parameter tRCD =  18.0;
    parameter tRFC =  66.0;
    parameter tXSR =  66.0;
    parameter tRP  =  18.0;
    parameter tRRD =  12.0;
    parameter tDPLa =  6.0;     
    parameter tDPLm =  12.0;     
    parameter tDPDX =  100000.0;   
    `endif

    // Timing Parameters for -75 PC133 
    `ifdef S75
    parameter tAC3 =   6.0;
    parameter tHZ3 =   6.0;
    parameter tAC2 =   8.0;
    parameter tHZ2 =   8.0;
    parameter tOH  =   2.5;
    parameter tMRD =   2.0;    
    parameter tRAS =  45.0;
    parameter tRC  =  67.5;
    parameter tRCD =  22.5;
    parameter tRFC =  67.5;
    parameter tXSR =  67.5;
    parameter tRP  =  22.5;
    parameter tRRD =  15.0;
    parameter tDPLa =  7.5;  
    parameter tDPLm =  15.0; 
    parameter tDPDX =  100000.0;
    `endif


    inout     [no_of_data - 1 : 0] dq;
    input     [no_of_addr - 1 : 0] addr;
    input     [no_of_bank - 1 : 0] ba;
    input                         clk;
    input                         cke;
    input                         csb;
    input                         rasb;
    input                         casb;
    input                         web;
    input     [no_of_dqm - 1 : 0]  dqm;

`protect

    reg       [no_of_data - 1 : 0] bank0 [0 : mem_sizes];
    reg       [no_of_data - 1 : 0] bank1 [0 : mem_sizes];
    reg       [no_of_data - 1 : 0] bank2 [0 : mem_sizes];
    reg       [no_of_data - 1 : 0] bank3 [0 : mem_sizes];

    reg       [no_of_bank - 1 : 0] bank_addr [0 : 3];                 // bank address Pipeline
    reg       [no_of_col - 1 : 0] Col_addr [0 : 3];                 // Column address Pipeline
    reg                   [3 : 0] Command [0 : 3];                  // Command Operation Pipeline
    reg       [no_of_dqm - 1 : 0] dqm_reg0, dqm_reg1;               // DQM Operation Pipeline
    reg       [no_of_dqm - 1 : 0] dqm_save [0 : 3];   	            // DQM Operation Pipeline
    reg       [no_of_addr - 1 : 0] B0_row_addr, B1_row_addr, B2_row_addr, B3_row_addr;

    reg       [no_of_addr - 1 : 0] Mode_reg;
    reg       [no_of_addr - 1 : 0] EMode_reg;
    reg       [no_of_data - 1 : 0] dq_reg, dq_dqm;
    reg        [no_of_col - 1 : 0] Col_temp, Burst_counter;

    reg                           Act_b0, Act_b1, Act_b2, Act_b3;    // bank Activate
    reg                           Pc_b0, Pc_b1, Pc_b2, Pc_b3;        // bank Precharge

    reg                   [1 : 0] bank_precharge       [0 : 3];     // Precharge Command
    reg                           A10_precharge        [0 : 3];     // addr[10] = 1 (All banks)
    reg                           Auto_precharge       [0 : 3];     // RW Auto Precharge (bank)
    reg                           Read_precharge       [0 : 3];     // R  Auto Precharge
    reg                           Write_precharge      [0 : 3];     //  W Auto Precharge
    reg                           RW_interrupt_read    [0 : 3];     // RW Interrupt Read with Auto Precharge
    reg                           RW_interrupt_write   [0 : 3];     // RW Interrupt Write with Auto Precharge
    reg                   [1 : 0] RW_interrupt_bank;                // RW Interrupt bank
    integer                       RW_interrupt_counter [0 : 3];     // RW Interrupt Counter
    integer                       Count_precharge      [0 : 3];     // RW Auto Precharge Counter

    reg                           Data_in_enable;
    reg                           Data_out_enable;

    reg       [no_of_bank - 1 : 0] bank, Prev_bank;
    reg       [no_of_addr - 1 : 0] Row;
    reg        [no_of_col - 1 : 0] Col, Col_brst;

    reg 		[19:0]	  ccc;
    reg 		[3:0]	  bit;
    reg 		[2:0]	  CL;
    reg 		[8:0]	  BL;
    reg  	    RIW_violate; 
    reg  	    Dout_Drive_Flag;
    reg  	    Pre_Dout_Drive_Flag;
    reg		    [10:0] Count_at_Read;
    reg  	    Read_cmd_received;
    reg  	    Read_cmd_received_cke;
    reg  	    Write_cmd_received_cke;
    reg  	    state_act_pwrdn,state_pre_pwrdn,state_dpdn,state_self;
    reg  	    dpdn_check_start;
    reg  	    [10:0] Read_cmd_count;
    reg  	    [10:0] Read_cmd_count_cke;
    reg  	    [10:0] Write_cmd_count_cke;
    reg  	    [3:0] cmp_count;
    // Internal system clock
    reg                           ckeZ, Sys_clk;

    // Commands Decode
    wire      Active_enable    = ~csb & ~rasb &  casb &  web ;
    wire      Aref_enable      = ~csb & ~rasb & ~casb &  web & cke;
    wire      Sref_enable      = ~csb & ~rasb & ~casb &  web & ~cke;
    wire      Burst_term       = ~csb &  rasb &  casb & ~web & cke;
    wire      Deep_pwrdn       = ~csb &  rasb &  casb & ~web & ~cke;
    wire      Mode_reg_enable  = ~csb & ~rasb & ~casb & ~web & ~ba[1] & ~ba[0];
    wire      EMode_reg_enable = ~csb & ~rasb & ~casb & ~web & ba[1] & ~ba[0];
    wire      Prech_enable     = ~csb & ~rasb &  casb & ~web ;
    wire      Read_enable      = ~csb &  rasb & ~casb &  web ;
    wire      Write_enable     = ~csb &  rasb & ~casb & ~web ;

    // Burst Length Decode
    wire      Burst_length_1   = ~Mode_reg[2] & ~Mode_reg[1] & ~Mode_reg[0];
    wire      Burst_length_2   = ~Mode_reg[2] & ~Mode_reg[1] &  Mode_reg[0];
    wire      Burst_length_4   = ~Mode_reg[2] &  Mode_reg[1] & ~Mode_reg[0];
    wire      Burst_length_8   = ~Mode_reg[2] &  Mode_reg[1] &  Mode_reg[0];
    wire      Burst_length_f   =  Mode_reg[2] &  Mode_reg[1] &  Mode_reg[0];

    // CAS Latency Decode
    wire      Cas_latency_1    = ~Mode_reg[6] & ~Mode_reg[5] &  Mode_reg[4];
    wire      Cas_latency_2    = ~Mode_reg[6] &  Mode_reg[5] & ~Mode_reg[4];
    wire      Cas_latency_3    = ~Mode_reg[6] &  Mode_reg[5] &  Mode_reg[4];

    // Write Burst Mode
    wire      Write_burst_mode = Mode_reg[9];

`ifdef VERBOSE
    wire      Debug            = 1'b1;                          // Debug messages : 1 = On
`else
    wire      Debug            = 1'b0;                          // Debug messages : 1 = On
`endif

    wire      dq_chk           = Sys_clk & Data_in_enable;      // Check setup/hold time for DQ
    
    // CKE function
    wire      clk_suspend_write= (Act_b0 | Act_b1 | Act_b2 | Act_b3) & Write_cmd_received_cke;
    wire      clk_suspend_read = (Act_b0 | Act_b1 | Act_b2 | Act_b3) & Read_cmd_received_cke;
    wire      act_pwrdn        = (Act_b0 | Act_b1 | Act_b2 | Act_b3) & (~Read_cmd_received_cke & ~Write_cmd_received_cke);
    wire      pch_pwrdn        = (Pc_b0 & Pc_b1 & Pc_b2 & Pc_b3) & (~Read_cmd_received_cke | ~Write_cmd_received_cke);

    assign    dq               = dq_reg;                        // DQ buffer

    // Commands Operation
    `define   ACT       0
    `define   NOP       1
    `define   READ      2
    `define   WRITE     3
    `define   PRECH     4
    `define   A_REF     5
    `define   BST       6
    `define   LMR       7

    // Timing Check variable
    real  MRD_chk;
    real  WR_chkm0, WR_chkm1, WR_chkm2, WR_chkm3;
    real  RFC_chk, RRD_chk;
    real  RC_chk0, RC_chk1, RC_chk2, RC_chk3 ;
    real  RAS_chk0, RAS_chk1, RAS_chk2, RAS_chk3 ;
    real  RCD_chk0, RCD_chk1, RCD_chk2, RCD_chk3 ;
    real  RP_chk0, RP_chk1, RP_chk2, RP_chk3 ;
    real  SELF_chk, DPDN_chk ;

    initial begin
	mem_init;
        dq_reg = {no_of_data{1'bz}};
        Data_in_enable = 0; Data_out_enable = 0;
        Act_b0 = 1; Act_b1 = 1; Act_b2 = 1; Act_b3 = 1; 
        Pc_b0 = 0; Pc_b1 = 0; Pc_b2 = 0; Pc_b3 = 0; 
        WR_chkm0 = 0; WR_chkm1 = 0; WR_chkm2 = 0; WR_chkm3 = 0;
        RW_interrupt_read[0] = 0; RW_interrupt_read[1] = 0; RW_interrupt_read[2] = 0; RW_interrupt_read[3] = 0;
        RW_interrupt_write[0] = 0; RW_interrupt_write[1] = 0; RW_interrupt_write[2] = 0; RW_interrupt_write[3] = 0;
        MRD_chk = 0; RFC_chk = 0; RRD_chk = 0;
        RAS_chk0 = 0; RAS_chk1 = 0; RAS_chk2 = 0; RAS_chk3 = 0; 
        RCD_chk0 = 0; RCD_chk1 = 0; RCD_chk2 = 0; RCD_chk3 = 0; 
        RC_chk0 = 0; RC_chk1 = 0; RC_chk2 = 0; RC_chk3 = 0; 
        RP_chk0 = 0; RP_chk1 = 0; RP_chk2 = 0; RP_chk3 = 0;
        SELF_chk = 0; DPDN_chk = 0;
    	Read_cmd_received=0;
    	Read_cmd_count=0;
    	Read_cmd_received_cke=0;
    	Read_cmd_count_cke=0;
    	Write_cmd_received_cke=0;
    	Write_cmd_count_cke=0;
    	state_act_pwrdn=0;
    	state_pre_pwrdn=0;
    	state_dpdn=0;
    	state_self=0;
    	dpdn_check_start=0;
	EMode_reg=0;
	Mode_reg=0;
	Count_at_Read=0;

        $timeformat (-9, 2, " ns", 12);
    end

    // System clock generator
    always begin
        @ (posedge clk) begin
            Sys_clk = ckeZ;
            ckeZ = cke;
        end
        @ (negedge clk) begin
            Sys_clk = 1'b0;
        end
    end

    always @ (posedge clk) begin
        // CKE Exit
        if (cke === 1'b1) begin
          if (state_self === 1'b1) begin
            state_self = 1'b0;
	    SELF_chk=$realtime;
            if (Debug) $display ("Time = %t : OPERATION = SREFX : Self Refresh exit", $realtime);
          end else if (state_dpdn == 1'b1) begin
            state_dpdn = 1'b0;
	    DPDN_chk=$realtime;
            if (Debug) $display ("Time = %t : OPERATION = DPDNX : Deep Powerdown exit", $realtime);
          end else if (state_act_pwrdn == 1'b1) begin
            state_act_pwrdn = 1'b0;
            if (Debug) $display ("Time = %t : OPERATION = APDNX : Active Power down exit", $realtime);
          end else if (state_pre_pwrdn == 1'b1) begin
            state_pre_pwrdn = 1'b0;
            if (Debug) $display ("Time = %t : OPERATION = PPDNX : Precharge Power down exit", $realtime);
          end
        end
    end


    always @ (Dout_Drive_Flag) begin

        if(Cas_latency_2 ==1) begin

        Pre_Dout_Drive_Flag <= #tHZ2 Dout_Drive_Flag;

        end else if(Cas_latency_3 ==1) begin

        Pre_Dout_Drive_Flag <= #tHZ3 Dout_Drive_Flag;

        end

    end




    always @ (posedge Sys_clk) begin
        // Internal Commamd Pipelined
        Command[0] = Command[1];
        Command[1] = Command[2];
        Command[2] = Command[3];
        Command[3] = `NOP;

        Col_addr[0] = Col_addr[1];
        Col_addr[1] = Col_addr[2];
        Col_addr[2] = Col_addr[3];
        Col_addr[3] = {no_of_col{1'b0}};

        bank_addr[0] = bank_addr[1];
        bank_addr[1] = bank_addr[2];
        bank_addr[2] = bank_addr[3];
        bank_addr[3] = 2'b00;

        bank_precharge[0] = bank_precharge[1];
        bank_precharge[1] = bank_precharge[2];
        bank_precharge[2] = bank_precharge[3];
        bank_precharge[3] = 2'b00;

        A10_precharge[0] = A10_precharge[1];
        A10_precharge[1] = A10_precharge[2];
        A10_precharge[2] = A10_precharge[3];
        A10_precharge[3] = 1'b0;

        // dqm pipeline for Read
        dqm_reg0 = dqm_reg1;
        dqm_reg1 = dqm;

	dqm_save[3]=dqm_save[2];
	dqm_save[2]=dqm_save[1];
	dqm_save[1]=dqm_save[0];
	dqm_save[0]=dqm;


	if (Read_cmd_received == 1'b1) begin
	   Read_cmd_count = Read_cmd_count + 1;
	end
	else begin
	   Read_cmd_count = 4'b0;
 	end
	//if (Read_cmd_count == (BL+CL+1)) begin
	if (Read_cmd_count == Count_at_Read+(BL+CL+1)) begin
	   Read_cmd_received = 1'b0;
	end

        // Count for CKE
        if (Read_cmd_received_cke == 1'b1) begin
           Read_cmd_count_cke = Read_cmd_count_cke + 1;
        end
        else begin
           Read_cmd_count_cke = 4'b0;
        end
        if (Read_cmd_count_cke == (BL+CL-1)) begin
           Read_cmd_received_cke = 1'b0;
        end

        // Count for CKE
        if (Write_cmd_received_cke == 1'b1) begin
           Write_cmd_count_cke = Write_cmd_count_cke + 1;
        end
        else begin
           Write_cmd_count_cke = 4'b0;
        end
        if (Write_cmd_count_cke == BL) begin
           Write_cmd_received_cke = 1'b0;
        end



        // Read or Write with Auto Precharge Counter
        if (Auto_precharge[0] === 1'b1) begin
            Count_precharge[0] = Count_precharge[0] + 1;
        end
        if (Auto_precharge[1] === 1'b1) begin
            Count_precharge[1] = Count_precharge[1] + 1;
        end
        if (Auto_precharge[2] === 1'b1) begin
            Count_precharge[2] = Count_precharge[2] + 1;
        end
        if (Auto_precharge[3] === 1'b1) begin
            Count_precharge[3] = Count_precharge[3] + 1;
        end

        // Read or Write Interrupt Counter
        if (RW_interrupt_write[0] === 1'b1) begin
            RW_interrupt_counter[0] = RW_interrupt_counter[0] + 1;
        end
        if (RW_interrupt_write[1] === 1'b1) begin
            RW_interrupt_counter[1] = RW_interrupt_counter[1] + 1;
        end
        if (RW_interrupt_write[2] === 1'b1) begin
            RW_interrupt_counter[2] = RW_interrupt_counter[2] + 1;
        end
        if (RW_interrupt_write[3] === 1'b1) begin
            RW_interrupt_counter[3] = RW_interrupt_counter[3] + 1;
        end

        // tMRD Counter
        MRD_chk = MRD_chk + 1;

        // Auto Refresh
        if (Aref_enable === 1'b1) begin
            if (Debug) begin
                //$display ("%m : at time %t AREF : Auto Refresh", $realtime);
                $display ("Time = %t : OPERATION = AREF  : Auto Refresh", $realtime);
            end

            // DPDXN to Auto Refresh
            if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                $display ("Time = %t : ERROR : Pwrup violation(DPDX to AREF)", $realtime);
            end

            // Self exit to Auto Refresh
            if ($realtime - SELF_chk < tXSR) begin
                $display ("Time = %t : ERROR : tXSR violation(SREFX to AREF)", $realtime);
            end

            // Auto Refresh to Auto Refresh
            if ($realtime - RFC_chk < tRFC) begin
                //$display ("%m : at time %t ERROR: tRFC violation during Auto Refresh", $realtime);
                $display ("Time = %t : ERROR : tRFC violation(AREF to AREF)", $realtime);
            end

            // Precharge to Auto Refresh
            if (($realtime - RP_chk0 < tRP)) begin
                //$display ("%m : at time %t ERROR: tRP violation during Auto Refresh", $realtime);
                $display ("Time = %t : ERROR : tRP violation(PRECHARGE0 to AREF)", $realtime);
            end
            if (($realtime - RP_chk1 < tRP)) begin
                //$display ("%m : at time %t ERROR: tRP violation during Auto Refresh", $realtime);
                $display ("Time = %t : ERROR : tRP violation(PRECHARGE1 to AREF)", $realtime);
            end
            if (($realtime - RP_chk2 < tRP)) begin
                //$display ("%m : at time %t ERROR: tRP violation during Auto Refresh", $realtime);
                $display ("Time = %t : ERROR : tRP violation(PRECHARGE2 to AREF)", $realtime);
            end
            if (($realtime - RP_chk3 < tRP)) begin
                //$display ("%m : at time %t ERROR: tRP violation during Auto Refresh", $realtime);
                $display ("Time = %t : ERROR : tRP violation(PRECHARGE3 to AREF)", $realtime);
            end


            // Precharge to Refresh
            if (Pc_b0 === 1'b0 || Pc_b1 === 1'b0 || Pc_b2 === 1'b0 || Pc_b3 === 1'b0) begin
                //$display ("%m : at time %t ERROR: All banks must be Precharge before Auto Refresh", $realtime);
                $display ("Time = %t : ERROR : All banks must be Precharged before AREF", $realtime);
            end

            // Load Mode Register to Auto Refresh
            if (MRD_chk < tMRD) begin
                //$display ("%m : at time %t ERROR: tMRD violation during Auto Refresh", $realtime);
                $display ("Time = %t : ERROR : tMRD violation(MRS to AREF)", $realtime);
            end

            // Record Current tRFC time
            RFC_chk = $realtime;
        end
        
        // Load Mode Register
        if (Mode_reg_enable === 1'b1) begin
            // Register Mode
            Mode_reg = addr;

            // Decode CAS Latency, Burst Length, Burst Type, and Write Burst Mode
            if (Debug) begin
                //$display ("%m : at time %t LMR  : Load Mode Register", $realtime);
                $display ("Time = %t : OPERATION = MRS   : Load Mode Register", $realtime);
                // CAS Latency
                case (addr[6 : 4])
                    3'b010  : $display ("                                 CAS Latency      = 2"); 
                    3'b011  : $display ("                                 CAS Latency      = 3");
                    default : $display ("                                 CAS Latency      = Reserved");
                endcase
                case (addr[6 : 4])
                    3'b010  : CL=2;
                    3'b011  : CL=3;
                    default : CL=3;
                endcase

                // Burst Length
                case (addr[2 : 0])
                    3'b000  : $display ("                                 Burst Length     = 1");
                    3'b001  : $display ("                                 Burst Length     = 2");
                    3'b010  : $display ("                                 Burst Length     = 4");
                    3'b011  : $display ("                                 Burst Length     = 8");
                    3'b111  : $display ("                                 Burst Length     = Full");
                    default : $display ("                                 Burst Length     = Reserved");
                endcase

                case (addr[2 : 0])
                    3'b000  : BL=1;
                    3'b001  : BL=2;
                    3'b010  : BL=4;
                    3'b011  : BL=8;
                    3'b111  : BL=512;
                    default : BL=4;
                endcase


                // Burst Type
                if (addr[3] === 1'b0) begin
                    $display ("                                 Burst Type       = Sequential");
                end else if (addr[3] === 1'b1) begin
                    $display ("                                 Burst Type       = Interleaved");
                end else begin
                    $display ("                                 Burst Type       = Reserved");
                end

                // Write Burst Mode
                if (addr[9] === 1'b0) begin
                    $display ("                                 Write Burst Mode = Programmed Burst Length");
                end else if (addr[9] === 1'b1) begin
                    $display ("                                 Write Burst Mode = Single Location Access");
                end else begin
                    $display ("                                 Write Burst Mode = Reserved");
                end
            end

            // Precharge to Load Mode Register
            if (Pc_b0 === 1'b0 && Pc_b1 === 1'b0 && Pc_b2 === 1'b0 && Pc_b3 === 1'b0 ) begin
                //$display ("%m : at time %t ERROR: all banks must be Precharge before Load Mode Register", $realtime);
                $display ("Time = %t : ERROR : all banks must be Precharge before Load Mode Register", $realtime);
            end

            // Precharge to Load Mode Register
            if (($realtime - RP_chk0 < tRP) || ($realtime - RP_chk1 < tRP) ||
                ($realtime - RP_chk2 < tRP) || ($realtime - RP_chk3 < tRP)) begin
                //$display ("%m : at time %t ERROR: tRP violation during Load Mode Register", $realtime);
                $display ("Time = %t : ERROR : tRP violation(PRECHARGE to MRS)", $realtime);
            end

            // Auto Refresh to Load Mode Register
            if ($realtime - RFC_chk < tRFC) begin
                //$display ("%m : at time %t ERROR: tRFC violation during Load Mode Register", $realtime);
                $display ("Time = %t : ERROR : tRFC violation(AREF to MRS)", $realtime);
            end

            // Load Mode Register to Load Mode Register
            if (MRD_chk < tMRD) begin
                //$display ("%m : at time %t ERROR: tMRD violation during Load Mode Register", $realtime);
                $display ("Time = %t : ERROR : tMRD violation(MRS to MRS)", $realtime);
            end

            // Reset MRD Counter
            MRD_chk = 0;
        end

        // Load Extended Mode Register
        if (EMode_reg_enable === 1'b1) begin
            // Register Mode
            EMode_reg = addr;

            // Decode Driver Strength, Maximum Case Temp, Self Refresh Coverage
            if (Debug) begin
                //$display ("%m : at time %t LMR  : Load Mode Register", $realtime);
                $display ("Time = %t : OPERATION = EMRS  : Load Extended Mode Register", $realtime);
                // Driver Strength
                case (addr[6 : 5])
                    2'b00   : $display ("                                 Driver Strength        = Full");
                    2'b01   : $display ("                                 Driver Strength        = 1/2");
                    2'b10   : $display ("                                 Driver Strength        = 1/4");
                    2'b11   : $display ("                                 Driver Strength        = 1/8");
                    default : $display ("                                 Driver Strength        = Reserved");
                endcase

                // Self Refresh Coverage
                case (addr[2 : 0])
                    3'b000   : $display ("                                 Self Refresh Coverage  = All Banks");
                    3'b001   : $display ("                                 Self Refresh Coverage  = TWO Bank");
                    3'b010   : $display ("                                 Self Refresh Coverage  = One Bank");
                    3'b101   : $display ("                                 Self Refresh Coverage  = Half of one Banks");
                    3'b110   : $display ("                                 Self Refresh Coverage  = Quater of one Banks");
                    default  : $display ("                                 Self Refresh Coverage  = Reserved");
                endcase

            end

            // Precharge to Load Mode Register
            if (Pc_b0 === 1'b0 && Pc_b1 === 1'b0 && Pc_b2 === 1'b0 && Pc_b3 === 1'b0) begin
                //$display ("%m : at time %t ERROR: all banks must be Precharge before Load Mode Register", $realtime);
                $display ("Time = %t : ERROR : all banks must be Precharge before Load Mode Register", $realtime);
            end

            // Precharge to Load Mode Register
            if (($realtime - RP_chk0 < tRP) || ($realtime - RP_chk1 < tRP) ||
                ($realtime - RP_chk2 < tRP) || ($realtime - RP_chk3 < tRP)) begin
                //$display ("%m : at time %t ERROR: tRP violation during Load Mode Register", $realtime);
                $display ("Time = %t : ERROR : tRP violation(PRECHARGE to EMRS)", $realtime);
            end

            // Auto Refresh to Load Mode Register
            if ($realtime - RFC_chk < tRFC) begin
                //$display ("%m : at time %t ERROR: tRFC violation during Load Mode Register", $realtime);
                $display ("Time = %t : ERROR : tRFC violation(AREF to EMRS)", $realtime);
            end

            // Load Mode Register to Load Mode Register
            if (MRD_chk < tMRD) begin
                //$display ("%m : at time %t ERROR: tMRD violation during Load Mode Register", $realtime);
                $display ("Time = %t : ERROR : tMRD violation(MRS to EMRS)", $realtime);
            end

            // Reset MRD Counter
            MRD_chk = 0;
        end
        
        // Active Block (Latch bank address and Row address)
        if (Active_enable === 1'b1) begin
            // Activate an open bank can corrupt data
            if ((ba === 2'b00 && Act_b0 === 1'b1) || (ba === 2'b01 && Act_b1 === 1'b1) || 
                (ba === 2'b10 && Act_b2 === 1'b1) || (ba === 2'b11 && Act_b3 === 1'b1)) begin
                //$display ("%m : at time %t ERROR: bank already activated -- data can be corrupted", $realtime);
                $display ("Time = %t : ERROR : bank already activated -- data could be corrupted", $realtime);
               // $display ("Time = %t : Bank = %d, Act_b0 = %d, Act_b2 = %d", $realtime, ba, Act_b0, Act_b2);
            end

            // Activate bank 0
            if (ba === 2'b00 && Pc_b0 === 1'b1) begin
                // Debug Message
                if (Debug) begin
                    //$display ("%m : at time %t ACT  : bank = 0 Row = %d", $realtime, addr);
                    $display ("Time = %t : OPERATION = ACT   : bank = 0 Row = 'h%h", $realtime, addr);
                end

                // Self exit to ACTIVE
                if ($realtime - SELF_chk < tXSR) begin
                    $display ("Time = %t : ERROR : tXSR violation(SREFX to ACT0)", $realtime);
                end

                // DPDXN to Precharge
                if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                    $display ("Time = %t : ERROR : Pwrup violation(DPDX to ACT0)", $realtime);
                end

                // ACTIVE to ACTIVE command period
                if ($realtime - RC_chk0 < tRC) begin
                    //$display ("%m : at time %t ERROR: tRC violation during Activate bank 0", $realtime);
                    $display ("Time = %t : ERROR : tRC violation (ACT0 to ACT0) ", $realtime);
                end

                // Precharge to Activate bank 0
                if ($realtime - RP_chk0 < tRP) begin
                    //$display ("%m : at time %t ERROR: tRP violation during Activate bank 0", $realtime);
                    $display ("Time = %t : ERROR : tRP violation (PRECHARGE0 to PRECHARGE0) ", $realtime);
                end

                // Record variables
                Act_b0 = 1'b1;
                Pc_b0 = 1'b0;
                B0_row_addr = addr [no_of_addr - 1 : 0];
                RAS_chk0 = $realtime;
                RC_chk0 = $realtime;
                RCD_chk0 = $realtime;
            end

            // Activate bank 1
            if (ba === 2'b01 && Pc_b1 === 1'b1) begin
                // Debug Message
                if (Debug) begin
                    //$display ("%m : at time %t ACT  : bank = 1 Row = %d", $realtime, addr);
                    $display ("Time = %t : OPERATION = ACT   : bank = 1 Row = 'h%h", $realtime, addr);
                end

                // DPDXN to Precharge
                if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                    $display ("Time = %t : ERROR : Pwrup violation(DPDX to ACT1)", $realtime);
                end

                // Self exit to ACTIVE
                if ($realtime - SELF_chk < tXSR) begin
                    $display ("Time = %t : ERROR : tXSR violation(SREFX to ACT1)", $realtime);
                end

                // ACTIVE to ACTIVE command period
                if ($realtime - RC_chk1 < tRC) begin
                    //$display ("%m : at time %t ERROR: tRC violation during Activate bank 1", $realtime);
                    $display ("Time = %t : ERROR : tRC violation (ACT1 to ACT1) ", $realtime);
                end

                // Precharge to Activate bank 1
                if ($realtime - RP_chk1 < tRP) begin
                    //$display ("%m : at time %t ERROR: tRP violation during Activate bank 1", $realtime);
                    $display ("Time = %t : ERROR : tRP violation (PRECHARGE1 to PRECHARGE1) ", $realtime);
                end

                // Record variables
                Act_b1 = 1'b1;
                Pc_b1 = 1'b0;
                B1_row_addr = addr [no_of_addr - 1 : 0];
                RAS_chk1 = $realtime;
                RC_chk1 = $realtime;
                RCD_chk1 = $realtime;
            end

            // Activate bank 2
            if (ba === 2'b10 && Pc_b2 === 1'b1) begin
                // Debug Message
                if (Debug) begin
                    //$display ("%m : at time %t ACT  : bank = 2 Row = %d", $realtime, addr);
                    $display ("Time = %t : OPERATION = ACT   : bank = 2 Row = 'h%h", $realtime, addr);
                end

                // DPDXN to Precharge
                if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                    $display ("Time = %t : ERROR : Pwrup violation(DPDX to ACT2)", $realtime);
                end

                // Self exit to ACTIVE
                if ($realtime - SELF_chk < tXSR) begin
                    $display ("Time = %t : ERROR : tXSR violation(SREFX to ACT2)", $realtime);
                end

                // ACTIVE to ACTIVE command period
                if ($realtime - RC_chk2 < tRC) begin
                    //$display ("%m : at time %t ERROR: tRC violation during Activate bank 2", $realtime);
                    $display ("Time = %t : ERROR : tRC violation (ACT2 to ACT2) ", $realtime);
                end

                // Precharge to Activate bank 2
                if ($realtime - RP_chk2 < tRP) begin
                    //$display ("%m : at time %t ERROR: tRP violation during Activate bank 2", $realtime);
                    $display ("Time = %t : ERROR : tRP violation (PRECHARGE2 to PRECHARGE2) ", $realtime);
                end

                // Record variables
                Act_b2 = 1'b1;
                Pc_b2 = 1'b0;
                B2_row_addr = addr [no_of_addr - 1 : 0];
                RAS_chk2 = $realtime;
                RC_chk2 = $realtime;
                RCD_chk2 = $realtime;
            end

            // Activate bank 3
            if (ba === 2'b11 && Pc_b3 === 1'b1) begin
                // Debug Message
                if (Debug) begin
                    //$display ("%m : at time %t ACT  : bank = 3 Row = %d", $realtime, addr);
                    $display ("Time = %t : OPERATION = ACT   : bank = 3 Row = 'h%h", $realtime, addr);
                end

                // DPDXN to Precharge
                if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                    $display ("Time = %t : ERROR : Pwrup violation(DPDX to ACT3)", $realtime);
                end

                // Self exit to ACTIVE
                if ($realtime - SELF_chk < tXSR) begin
                    $display ("Time = %t : ERROR : tXSR violation(SREFX to ACT3)", $realtime);
                end

                // ACTIVE to ACTIVE command period
                if ($realtime - RC_chk3 < tRC) begin
                    //$display ("%m : at time %t ERROR: tRC violation during Activate bank 3", $realtime);
                    $display ("Time = %t : ERROR : tRC violation (ACT1 to ACT3) ", $realtime);
                end

                // Precharge to Activate bank 3
                if ($realtime - RP_chk3 < tRP) begin
                    //$display ("%m : at time %t ERROR: tRP violation during Activate bank 3", $realtime);
                    $display ("Time = %t : ERROR : tRP violation (PRECHARGE3 to PRECHARGE3) ", $realtime);
                end

                // Record variables
                Act_b3 = 1'b1;
                Pc_b3 = 1'b0;
                B3_row_addr = addr [no_of_addr - 1 : 0];
                RAS_chk3 = $realtime;
                RC_chk3 = $realtime;
                RCD_chk3 = $realtime;
            end

            // Active other bank to Active bank A
            if ((Prev_bank != ba) && ($realtime - RRD_chk < tRRD) && (ba === 2'b00)) begin
                //$display ("%m : at time %t ERROR: tRRD violation during Activate bank = %d", $realtime, ba);
                  $display ("Time = %t : ERROR : tRRD violation(ACT Others to ACT0) ", $realtime);
            end

            // Active other bank to Active bank B
            if ((Prev_bank != ba) && ($realtime - RRD_chk < tRRD) && (ba === 2'b01)) begin
                //$display ("%m : at time %t ERROR: tRRD violation during Activate bank = %d", $realtime, ba);
                  $display ("Time = %t : ERROR : tRRD violation(ACT Others to ACT1) ", $realtime);
            end

            // Active other bank to Active bank C
            if ((Prev_bank != ba) && ($realtime - RRD_chk < tRRD) && (ba === 2'b10)) begin
                //$display ("%m : at time %t ERROR: tRRD violation during Activate bank = %d", $realtime, ba);
                  $display ("Time = %t : ERROR : tRRD violation(ACT Others to ACT2) ", $realtime);
            end

            // Active other bank to Active bank D
            if ((Prev_bank != ba) && ($realtime - RRD_chk < tRRD) && (ba === 2'b11)) begin
                //$display ("%m : at time %t ERROR: tRRD violation during Activate bank = %d", $realtime, ba);
                  $display ("Time = %t : ERROR : tRRD violation(ACT Others to ACT3) ", $realtime);
            end

            // Auto Refresh to Activate
            if ($realtime - RFC_chk < tRFC) begin
                //$display ("%m : at time %t ERROR: tRFC violation during Activate bank = %d", $realtime, ba);
                $display ("Time = %t : ERROR : tRFC violation(AREF to ACT)", $realtime);
            end

            // Load Mode Register to Active
            if (MRD_chk < tMRD ) begin
                //$display ("%m : at time %t ERROR: tMRD violation during Activate bank = %d", $realtime, ba);
                $display ("Time = %t : ERROR : tMRD violation(MRS to ACT)", $realtime);
            end

            // Record variables for checking violation
            RRD_chk = $realtime;
            Prev_bank = ba;
        end
        
        // Precharge Block
        if (Prech_enable == 1'b1) begin
            // Load Mode Register to Precharge
            if ($realtime - MRD_chk < tMRD) begin
                //$display ("%m : at time %t ERROR: tMRD violaiton during Precharge", $realtime);
                $display ("Time = %t : ERROR : tMRD violation(MRS to PRECHARGE)", $realtime);
            end

	    //Precharge bank 0

            if ((addr[10] === 1'b1 || (addr[10] === 1'b0 && ba === 2'b00)) && Act_b0 === 1'b1) begin
                Act_b0 = 1'b0;
                Pc_b0 = 1'b1;
                RP_chk0 = $realtime;

                if (Debug) begin
                    //$display ("%m : at time %t ACT  : bank = 0 Row = %d", $realtime, addr);
                    $display ("Time = %t : OPERATION = PCHG  : bank = 0 ", $realtime);
 		end

                // DPDXN to Precharge
                if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                    $display ("Time = %t : ERROR : Pwrup violation(DPDX to PRECHARGE0)", $realtime);
                end

                // Activate to Precharge
                if ($realtime - RAS_chk0 < tRAS) begin
                    //$display ("%m : at time %t ERROR: tRAS violation during Precharge", $realtime);
                    $display ("Time = %t : ERROR : tRAS violation(ACT0 to PRECHARGE0)", $realtime);
                end

                // tWR violation check for write
                if ($realtime - WR_chkm0 < tDPLm) begin
                    //$display ("%m : at time %t ERROR: tWR violation during Precharge", $realtime);
                    $display ("Time = %t : ERROR : tDPL violation(LAST DATA to PRECHARGE0)", $realtime);
                end
            end

            // Precharge bank 1

            if ((addr[10] === 1'b1 || (addr[10] === 1'b0 && ba === 2'b01)) && Act_b1 === 1'b1) begin
                Act_b1 = 1'b0;
                Pc_b1 = 1'b1;
                RP_chk1 = $realtime;

                if (Debug) begin
                    //$display ("%m : at time %t ACT  : bank = 1 Row = %d", $realtime, addr);
                    $display ("Time = %t : OPERATION = PCHG  : bank = 1 ", $realtime);
 		end

                // DPDXN to Precharge
                if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                    $display ("Time = %t : ERROR : Pwrup violation(DPDX to PRECHARGE1)", $realtime);
                end

                // Activate to Precharge
                if ($realtime - RAS_chk1 < tRAS) begin
                    //$display ("%m : at time %t ERROR: tRAS violation during Precharge", $realtime);
                    $display ("Time = %t : ERROR : tRAS violation(ACT1 to PRECHARGE1)", $realtime);
                end

                // tWR violation check for write
                if ($realtime - WR_chkm1 < tDPLm) begin
                    //$display ("%m : at time %t ERROR: tWR violation during Precharge", $realtime);
                    $display ("Time = %t : ERROR : tDPL violation(LAST DATA to PRECHARGE1)", $realtime);
                end
            end

            // Precharge bank 2

            if ((addr[10] === 1'b1 || (addr[10] === 1'b0 && ba === 2'b10)) && Act_b2 === 1'b1) begin
                Act_b2 = 1'b0;
                Pc_b2 = 1'b1;
                RP_chk2 = $realtime;

                if (Debug) begin
                    //$display ("%m : at time %t ACT  : bank = 2 Row = %d", $realtime, addr);
                    $display ("Time = %t : OPERATION = PCHG  : bank = 2 ", $realtime);
                end

                // DPDXN to Precharge
                if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                    $display ("Time = %t : ERROR : Pwrup violation(DPDX to PRECHARGE2)", $realtime);
                end

                // Activate to Precharge
                if ($realtime - RAS_chk2 < tRAS) begin
                    //$display ("%m : at time %t ERROR: tRAS violation during Precharge", $realtime);
                    $display ("Time = %t : ERROR : tRAS violation(ACT2 to PRECHARGE2)", $realtime);
                end

                // tWR violation check for write
                if ($realtime - WR_chkm2 < tDPLm) begin
                    //$display ("%m : at time %t ERROR: tWR violation during Precharge", $realtime);
                    $display ("Time = %t : ERROR : tDPL violation(LAST DATA to PRECHARGE2)", $realtime);
                end
            end

            // Precharge bank 3

            if ((addr[10] === 1'b1 || (addr[10] === 1'b0 && ba === 2'b11)) && Act_b3 === 1'b1) begin
                Act_b3 = 1'b0;
                Pc_b3 = 1'b1;
                RP_chk3 = $realtime;

                if (Debug) begin
                    //$display ("%m : at time %t ACT  : bank = 3 Row = %d", $realtime, addr);
                    $display ("Time = %t : OPERATION = PCHG  : bank = 3 ", $realtime);
                end

                // DPDXN to Precharge
                if (($realtime - DPDN_chk < tDPDX) && (dpdn_check_start)) begin
                    $display ("Time = %t : ERROR : Pwrup violation(DPDX to PRECHARGE3)", $realtime);
                end

                // Activate to Precharge
                if ($realtime - RAS_chk3 < tRAS) begin
                    //$display ("%m : at time %t ERROR: tRAS violation during Precharge", $realtime);
                    $display ("Time = %t : ERROR : tRAS violation(ACT3 to PRECHARGE3)", $realtime);
                end

                // tWR violation check for write
                if ($realtime - WR_chkm3 < tDPLm) begin
                    //$display ("%m : at time %t ERROR: tWR violation during Precharge", $realtime);
                    $display ("Time = %t : ERROR : tDPL violation(LAST DATA to PRECHARGE3)", $realtime);
                end
            end


            // Terminate a Write Immediately (if same bank or all banks)
            if (Data_in_enable === 1'b1 && (bank === ba || addr[10] === 1'b1)) begin
                Data_in_enable = 1'b0;
            end

            // Precharge Command Pipeline for Read
            if (Cas_latency_3 === 1'b1) begin
                Command[2] = `PRECH;
                bank_precharge[2] = ba;
                A10_precharge[2] = addr[10];
            end else if (Cas_latency_2 === 1'b1) begin
                Command[1] = `PRECH;
                bank_precharge[1] = ba;
                A10_precharge[1] = addr[10];
            end
        end
        
        // Burst terminate
        if (Burst_term === 1'b1) begin
            // Terminate a Write Immediately
            if (Data_in_enable == 1'b1) begin
                Data_in_enable = 1'b0;
            end

            // Terminate a Read Depend on CAS Latency
            if (Cas_latency_3 === 1'b1) begin
                Command[2] = `BST;
            end else if (Cas_latency_2 == 1'b1) begin
                Command[1] = `BST;
            end

            // Display debug message
            if (Debug) begin
                //$display ("%m : at time %t BST  : Burst Terminate",$realtime);
                  $display ("Time = %t : OPERATION = BST   : Burst Stop", $realtime);
            end
        end
        
        // Read, Write, Column Latch
        if (Read_enable === 1'b1) begin

	    Read_cmd_received = 1'b1;
	    Read_cmd_received_cke = 1'b1;
	    //Read_cmd_count = 0;
	    Count_at_Read = Read_cmd_count;
	    Read_cmd_count_cke = 0;
	    Write_cmd_received_cke = 1'b0;

            // Check to see if bank is open (ACT)
            if ((ba == 2'b00 && Pc_b0 == 1'b1) || (ba == 2'b01 && Pc_b1 == 1'b1) || 
                (ba == 2'b10 && Pc_b2 == 1'b1) || (ba == 2'b11 && Pc_b3 == 1'b1)) begin 
                //$display("%m : at time %t ERROR: bank is not Activated for Read", $realtime);
                  $display ("Time = %t : ERROR : bank is not Activated for Read", $realtime);
            end

            // Activate to Read or Write
            if ((ba == 2'b00) && ($realtime - RCD_chk0 < tRCD) ||
                (ba == 2'b01) && ($realtime - RCD_chk1 < tRCD) ||
                (ba == 2'b10) && ($realtime - RCD_chk2 < tRCD) ||
                (ba == 2'b11) && ($realtime - RCD_chk3 < tRCD)) begin 
                //$display("%m : at time %t ERROR: tRCD violation during Read", $realtime);
                  $display ("Time = %t : ERROR : tRCD violation(ACT to READ)", $realtime);
            end

            // CAS Latency pipeline
            if (Cas_latency_3 == 1'b1) begin
                Command[2] = `READ;
                Col_addr[2] = addr;
                bank_addr[2] = ba;
            end else if (Cas_latency_2 == 1'b1) begin
                Command[1] = `READ;
                Col_addr[1] = addr;
                bank_addr[1] = ba;
            end

            // Read interrupt Write (terminate Write immediately)
            if (Data_in_enable == 1'b1) begin
                Data_in_enable = 1'b0;

                // Interrupting a Write with Autoprecharge
                if (Auto_precharge[RW_interrupt_bank] == 1'b1 && Write_precharge[RW_interrupt_bank] == 1'b1) begin
                    RW_interrupt_write[RW_interrupt_bank] = 1'b1;
                    RW_interrupt_counter[RW_interrupt_bank] = 0;

                    // Display debug message
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Read interrupt Write with Autoprecharge", $realtime);
                        $display ("Time = %t : OPERATION = Read interrupt Write with Autoprecharge", $realtime);
                    end
                end
            end

            // Read with Auto Precharge
            if (addr[10] == 1'b1) begin
                Auto_precharge[ba] = 1'b1;
                Count_precharge[ba] = 0;
                RW_interrupt_bank = ba;
                Read_precharge[ba] = 1'b1;
            end
        end

        // Write Command
        if (Write_enable == 1'b1) begin

	    RIW_violate=1'b0;	
	    if ((Pre_Dout_Drive_Flag == 1'b1) || (Dout_Drive_Flag == 1'b1)) begin 
                  $display ("Time = %t : ERROR : Read and Write Data collision", $realtime);
	    end
	    else if ((Data_out_enable == 1'b1) && (&(dqm_save[1]) != 1'b1)) begin
                  $display ("Time = %t : ERROR : Read and Write Data collision", $realtime);
	    end


    	    Write_cmd_received_cke=1'b1;
    	    Read_cmd_received=1'b0;
    	    Read_cmd_received_cke=1'b0;
	    Write_cmd_count_cke=1'b0;

            // Activate to Write
            if ((ba == 2'b00 && Pc_b0 == 1'b1) || (ba == 2'b01 && Pc_b1 == 1'b1) ||
                (ba == 2'b10 && Pc_b2 == 1'b1) || (ba == 2'b11 && Pc_b3 == 1'b1)) begin 
                //$display("%m : at time %t ERROR: bank is not Activated for Write", $realtime);
                  $display ("Time = %t : ERROR : bank is not Activated for Write", $realtime);
            end

            if ((ba == 2'b00) && ($realtime - RCD_chk0 < tRCD)) begin
                  $display ("Time = %t : ERROR = %t, %t: tRCD violation(ACT0 to WRITE)", $realtime, RCD_chk0,$realtime-RCD_chk0);
            end
            if ((ba == 2'b01) && ($realtime - RCD_chk1 < tRCD)) begin
                  $display ("Time = %t : ERROR = %t, %t: tRCD violation(ACT1 to WRITE)", $realtime, RCD_chk1,$realtime-RCD_chk1);
            end
            if ((ba == 2'b10) && ($realtime - RCD_chk2 < tRCD)) begin
                  $display ("Time = %t : ERROR = %t, %t: tRCD violation(ACT2 to WRITE)", $realtime, RCD_chk2,$realtime-RCD_chk2);
            end
            if ((ba == 2'b11) && ($realtime - RCD_chk3 < tRCD)) begin
                  $display ("Time = %t : ERROR = %t, %t: tRCD violation(ACT3 to WRITE)", $realtime, RCD_chk3,$realtime-RCD_chk3);
            end


            // Latch Write command, bank, and Column
            Command[0] = `WRITE;
            Command[1] = `NOP;
            Col_addr[0] = addr;
            bank_addr[0] = ba;

            // Write interrupt Write (terminate Write immediately)
            if (Data_in_enable == 1'b1) begin
                Data_in_enable = 1'b0;

                // Interrupting a Write with Autoprecharge
                if (Auto_precharge[RW_interrupt_bank] == 1'b1 && Write_precharge[RW_interrupt_bank] == 1'b1) begin
                    RW_interrupt_write[RW_interrupt_bank] = 1'b1;

                    // Display debug message
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Read bank %d interrupt Write bank %d with Autoprecharge", $realtime, ba, RW_interrupt_bank);
                        $display ("Time = %t : OPERATION = Write bank %d interrupt Write bank %d with Autoprecharge", $realtime, ba, RW_interrupt_bank);

                    end
                end
            end

            // Write interrupt Read (terminate Read immediately)
            if (Data_out_enable == 1'b1) begin
                Data_out_enable = 1'b0;
                
                // Interrupting a Read with Autoprecharge
                if (Auto_precharge[RW_interrupt_bank] == 1'b1 && Read_precharge[RW_interrupt_bank] == 1'b1) begin
                    RW_interrupt_read[RW_interrupt_bank] = 1'b1;

                    // Display debug message
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Write bank %d interrupt Read bank %d with Autoprecharge", $realtime, ba, RW_interrupt_bank);
                        $display ("Time = %t : OPERATION = Write bank %d interrupt Read bank %d with Autoprecharge", $realtime, ba, RW_interrupt_bank);
                    end
                end
            end

            // Write with Auto Precharge
            if (addr[10] == 1'b1) begin
                Auto_precharge[ba] = 1'b1;
                Count_precharge[ba] = 0;
                RW_interrupt_bank = ba;
                Write_precharge[ba] = 1'b1;
            end
        end

        /*
            Write with Auto Precharge Calculation
                The device start internal precharge when:
                    1.  Meet minimum tRAS requirement
                and 2.  tWR cycle(s) after last valid data
                 or 3.  Interrupt by a Read or Write (with or without Auto Precharge)

            Note: Model is starting the internal precharge 1 cycle after they meet all the
                  requirement but tRP will be compensate for the time after the 1 cycle.
        */
        if ((Auto_precharge[0] == 1'b1) && (Write_precharge[0] == 1'b1)) begin
            if ((($realtime - RAS_chk0 >= tRAS) &&                                                          // Case 1
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [0] >= 1) ||   // Case 2
                 (Burst_length_2 == 1'b1                              && Count_precharge [0] >= 2) ||
                 (Burst_length_4 == 1'b1                              && Count_precharge [0] >= 4) ||
                 (Burst_length_8 == 1'b1                              && Count_precharge [0] >= 8))) ||
                 (RW_interrupt_write[0] == 1'b1 && RW_interrupt_counter[0] >= 1)) begin                 // Case 3
                    Auto_precharge[0] = 1'b0;
                    Write_precharge[0] = 1'b0;
                    RW_interrupt_write[0] = 1'b0;
                    Pc_b0 = 1'b1;
                    Act_b0 = 1'b0;
                    RP_chk0 = $realtime + tDPLa;
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Start Internal Auto Precharge for bank 0", $realtime);
                        $display ("Time = %t : OPERATION = Start Internal Auto Precharge for bank 0", $realtime+tDPLa);
                    end
            end
        end
        if ((Auto_precharge[1] == 1'b1) && (Write_precharge[1] == 1'b1)) begin
            if ((($realtime - RAS_chk1 >= tRAS) &&                                                          // Case 1
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [1] >= 1) ||   // Case 2
                 (Burst_length_2 == 1'b1                              && Count_precharge [1] >= 2) ||
                 (Burst_length_4 == 1'b1                              && Count_precharge [1] >= 4) ||
                 (Burst_length_8 == 1'b1                              && Count_precharge [1] >= 8))) ||
                 (RW_interrupt_write[1] == 1'b1 && RW_interrupt_counter[1] >= 1)) begin                 // Case 3
                    Auto_precharge[1] = 1'b0;
                    Write_precharge[1] = 1'b0;
                    RW_interrupt_write[1] = 1'b0;
                    Pc_b1 = 1'b1;
                    Act_b1 = 1'b0;
                    RP_chk1 = $realtime + tDPLa;
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Start Internal Auto Precharge for bank 1", $realtime);
                        $display ("Time = %t : OPERATION = Start Internal Auto Precharge for bank 1", $realtime+tDPLa);
                    end
            end
        end
        if ((Auto_precharge[2] == 1'b1) && (Write_precharge[2] == 1'b1)) begin
            if ((($realtime - RAS_chk2 >= tRAS) &&                                                          // Case 1
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [2] >= 1) ||   // Case 2
                 (Burst_length_2 == 1'b1                              && Count_precharge [2] >= 2) ||
                 (Burst_length_4 == 1'b1                              && Count_precharge [2] >= 4) ||
                 (Burst_length_8 == 1'b1                              && Count_precharge [2] >= 8))) ||
                 (RW_interrupt_write[2] == 1'b1 && RW_interrupt_counter[2] >= 1)) begin                 // Case 3
                    Auto_precharge[2] = 1'b0;
                    Write_precharge[2] = 1'b0;
                    RW_interrupt_write[2] = 1'b0;
                    Pc_b2 = 1'b1;
                    Act_b2 = 1'b0;
                    RP_chk2 = $realtime + tDPLa;
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Start Internal Auto Precharge for bank 2", $realtime);
                        $display ("Time = %t : OPERATION = Start Internal Auto Precharge for bank 2", $realtime+tDPLa);
                    end
            end
        end
        if ((Auto_precharge[3] == 1'b1) && (Write_precharge[3] == 1'b1)) begin
            if ((($realtime - RAS_chk3 >= tRAS) &&                                                          // Case 1
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [3] >= 1) ||   // Case 2
                 (Burst_length_2 == 1'b1                              && Count_precharge [3] >= 2) ||
                 (Burst_length_4 == 1'b1                              && Count_precharge [3] >= 4) ||
                 (Burst_length_8 == 1'b1                              && Count_precharge [3] >= 8))) ||
                 (RW_interrupt_write[3] == 1'b1 && RW_interrupt_counter[3] >= 1)) begin                 // Case 3
                    Auto_precharge[3] = 1'b0;
                    Write_precharge[3] = 1'b0;
                    RW_interrupt_write[3] = 1'b0;
                    Pc_b3 = 1'b1;
                    Act_b3 = 1'b0;
                    RP_chk3 = $realtime + tDPLa;
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Start Internal Auto Precharge for bank 3", $realtime);
                        $display ("Time = %t : OPERATION = Start Internal Auto Precharge for bank 3", $realtime+tDPLa);
                    end
            end
        end

        //  Read with Auto Precharge Calculation
        //      The device start internal precharge:
        //          1.  Meet minimum tRAS requirement
        //      and 2.  CAS Latency - 1 cycles before last burst
        //       or 3.  Interrupt by a Read or Write (with or without AutoPrecharge)
        if ((Auto_precharge[0] == 1'b1) && (Read_precharge[0] == 1'b1)) begin
            if ((($realtime - RAS_chk0 >= tRAS) &&                                                      // Case 1
                ((Burst_length_1 == 1'b1 && Count_precharge[0] >= 1) ||                             // Case 2
                 (Burst_length_2 == 1'b1 && Count_precharge[0] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[0] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[0] >= 8))) ||
                 (RW_interrupt_read[0] == 1'b1)) begin                                              // Case 3
                    Pc_b0 = 1'b1;
                    Act_b0 = 1'b0;
                    RP_chk0 = $realtime;
                    Auto_precharge[0] = 1'b0;
                    Read_precharge[0] = 1'b0;
                    RW_interrupt_read[0] = 1'b0;
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Start Internal Auto Precharge for bank 0", $realtime);
                        $display ("Time = %t : OPERATION = Start Internal Auto Precharge for bank 0", $realtime);
                    end
            end
        end
        if ((Auto_precharge[1] == 1'b1) && (Read_precharge[1] == 1'b1)) begin
            if ((($realtime - RAS_chk1 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[1] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge[1] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[1] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[1] >= 8))) ||
                 (RW_interrupt_read[1] == 1'b1)) begin
                    Pc_b1 = 1'b1;
                    Act_b1 = 1'b0;
                    RP_chk1 = $realtime;
                    Auto_precharge[1] = 1'b0;
                    Read_precharge[1] = 1'b0;
                    RW_interrupt_read[1] = 1'b0;
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Start Internal Auto Precharge for bank 1", $realtime);
                        $display ("Time = %t : OPERATION = Start Internal Auto Precharge for bank 1", $realtime);
                    end
            end
        end
        if ((Auto_precharge[2] == 1'b1) && (Read_precharge[2] == 1'b1)) begin
            if ((($realtime - RAS_chk2 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[2] >= 1) ||
                 (Burst_length_2 == 1'b1 && Count_precharge[2] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[2] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[2] >= 8))) ||
                 (RW_interrupt_read[2] == 1'b1)) begin
                    Pc_b2 = 1'b1;
                    Act_b2 = 1'b0;
                    RP_chk2 = $realtime;
                    Auto_precharge[2] = 1'b0;
                    Read_precharge[2] = 1'b0;
                    RW_interrupt_read[2] = 1'b0;
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Start Internal Auto Precharge for bank 2", $realtime);
                        $display ("Time = %t : OPERATION = Start Internal Auto Precharge for bank 2", $realtime);
                    end
            end
        end
        if ((Auto_precharge[3] == 1'b1) && (Read_precharge[3] == 1'b1)) begin
            if ((($realtime - RAS_chk3 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[3] >= 1) ||
                 (Burst_length_2 == 1'b1 && Count_precharge[3] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[3] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[3] >= 8))) ||
                 (RW_interrupt_read[3] == 1'b1)) begin
                    Pc_b3 = 1'b1;
                    Act_b3 = 1'b0;
                    RP_chk3 = $realtime;
                    Auto_precharge[3] = 1'b0;
                    Read_precharge[3] = 1'b0;
                    RW_interrupt_read[3] = 1'b0;
                    if (Debug) begin
                        //$display ("%m : at time %t NOTE : Start Internal Auto Precharge for bank 3", $realtime);
                        $display ("Time = %t : OPERATION = Start Internal Auto Precharge for bank 3", $realtime);
                    end
            end
        end

        // CKE Function
        if (cke === 1'b0) begin
          if (Sref_enable === 1'b1) begin
	    state_self = 1'b1;
            if (Debug) begin
		$display ("Time = %t : OPERATION = SREF  : Self Refresh", $realtime);
		if (EMode_reg[2:0]==3'b000) $display ("		Refresh Full Bank");

                if (EMode_reg[2:0]==3'b001) begin
                     $display ("                Refresh Only TWO Bank");
                     abbank_init;
		end

		if (EMode_reg[2:0]==3'b010) begin
		     $display ("		Refresh Only One Bank(BANK A)");
		     bbank_init;
	        end
		if (EMode_reg[2:0]==3'b101) begin
		     $display ("		Refresh Only half of one Bank(BANK A, A10=0)");
		     half_init;
	        end
		if (EMode_reg[2:0]==3'b110) begin
		     $display ("		Refresh Only Quarter of one Bank(BANK A, A10=0)");
		     quat_init;
	        end
	    end

            // Precharge to Auto Refresh
            if (($realtime - RP_chk0 < tRP) || ($realtime - RP_chk1 < tRP) ||
                ($realtime - RP_chk2 < tRP) || ($realtime - RP_chk3 < tRP))
                $display ("Time = %t : ERROR : tRP violation(PRECHARGE to SREF)", $realtime);

            // Precharge to Refresh
            if (Pc_b0 === 1'b0 || Pc_b1 === 1'b0 || Pc_b2 === 1'b0 || Pc_b3 === 1'b0) 
		$display ("Time = %t : ERROR : All banks must be Precharged before SREF", $realtime);

            // Load Mode Register to Self Refresh
            if (MRD_chk < tMRD) 
		$display ("Time = %t : ERROR : tMRD violation(MRS to SREF)", $realtime);

	  end else if (Deep_pwrdn == 1'b1) begin
	    state_dpdn = 1'b1;
	    dpdn_check_start = 1'b1;
            Act_b0 = 0; Act_b1 = 0; Act_b2 = 0; Act_b3 = 0;
            Pc_b0 = 1; Pc_b1 = 1; Pc_b2 = 1; Pc_b3 = 1;
	    mem_init;
            if (Debug) $display ("Time = %t : OPERATION = DPDN  : Deep Powerdown", $realtime);

            // Precharge to Auto Refresh
            if (($realtime - RP_chk0 < tRP) || ($realtime - RP_chk1 < tRP) ||
                ($realtime - RP_chk2 < tRP) || ($realtime - RP_chk3 < tRP))
                $display ("Time = %t : ERROR : tRP violation(PRECHARGE to DPDN)", $realtime);

            // Precharge to Refresh
            if (Pc_b0 === 1'b0 || Pc_b1 === 1'b0 || Pc_b2 === 1'b0 || Pc_b3 === 1'b0)
                $display ("Time = %t : ERROR : All banks must be Precharged before DPDN", $realtime);

          end else if (act_pwrdn == 1'b1) begin
	    state_act_pwrdn = 1'b1;
            if (Debug) $display ("Time = %t : OPERATION = APDN  : Active Power down", $realtime);
          end else if (pch_pwrdn == 1'b1) begin
	    state_pre_pwrdn = 1'b1;
            if (Debug) $display ("Time = %t : OPERATION = PPDN  : Precharge Power down", $realtime);
	  end else if (clk_suspend_write == 1'b1) begin 
            if (Debug) $display ("Time = %t : OPERATION = CKSW   : Clock Suspend during Write", $realtime);
          end else if (clk_suspend_read == 1'b1) begin
            if (Debug) $display ("Time = %t : OPERATION = CKSR   : Clock Suspend during Read", $realtime);
          end
        end

        // Internal Precharge or Bst
        if (Command[0] == `PRECH) begin                         // Precharge terminate a read with same bank or all banks
            if (bank_precharge[0] == bank || A10_precharge[0] == 1'b1) begin
                if (Data_out_enable == 1'b1) begin
                    Data_out_enable = 1'b0;
                end
            end
        end else if (Command[0] == `BST) begin                  // BST terminate a read to current bank
            if (Data_out_enable == 1'b1) begin
                Data_out_enable = 1'b0;
            end
        end

        if (Data_out_enable == 1'b0) begin
            dq_reg <= #tOH {no_of_data{1'bz}};
	    Dout_Drive_Flag <= #tOH 1'b0;
        end

        // Detect Read or Write command
        if (Command[0] == `READ) begin
            bank = bank_addr[0];
            Col = Col_addr[0];
            Col_brst = Col_addr[0];
            case (bank_addr[0])
                2'b00 : Row = B0_row_addr;
                2'b01 : Row = B1_row_addr;
                2'b10 : Row = B2_row_addr;
                2'b11 : Row = B3_row_addr;

            endcase
            Burst_counter = 0;
            Data_in_enable = 1'b0;
            Data_out_enable = 1'b1;
        end else if (Command[0] == `WRITE) begin
            bank = bank_addr[0];
            Col = Col_addr[0];
            Col_brst = Col_addr[0];
            case (bank_addr[0])
                2'b00 : Row = B0_row_addr;
                2'b01 : Row = B1_row_addr;
                2'b10 : Row = B2_row_addr;
                2'b11 : Row = B3_row_addr;
            endcase
            Burst_counter = 0;
            Data_in_enable = 1'b1;
            Data_out_enable = 1'b0;
        end

        // DQ buffer (Driver/Receiver)
        if (Data_in_enable == 1'b1) begin                                   // Writing Data to Memory
            // Array buffer
            case (bank)
                2'b00 : dq_dqm = bank0 [{Row, Col}];
                2'b01 : dq_dqm = bank1 [{Row, Col}];
                2'b10 : dq_dqm = bank2 [{Row, Col}];
                2'b11 : dq_dqm = bank3 [{Row, Col}];
            endcase

            // dqm operation
            if (dqm[0] == 1'b0) begin
                dq_dqm [ 7 : 0] = dq [ 7 : 0 ] & dq [ 7 : 0 ];
            end
            if (dqm[1] == 1'b0) begin
                dq_dqm [15 : 8] = dq [15 : 8] & dq [15 : 8];
            end

	    
	    
            // Write to memory
            case (bank)
                2'b00 : bank0 [{Row, Col}] = dq_dqm;
                2'b01 : bank1 [{Row, Col}] = dq_dqm;
                2'b10 : bank2 [{Row, Col}] = dq_dqm;
                2'b11 : bank3 [{Row, Col}] = dq_dqm;
            endcase

            // Display debug message
            if (dqm !== 2'b11) begin
                // Record tWR for manual precharge
                if (bank == 2'b00) WR_chkm0 = $realtime;
                if (bank == 2'b01) WR_chkm1 = $realtime;
                if (bank == 2'b10) WR_chkm2 = $realtime;
                if (bank == 2'b11) WR_chkm3 = $realtime;

                if (Debug) begin
                    //$display("%m : at time %t WRITE: bank = %d Row = %d, Col = %d, Data = %d", $realtime, bank, Row, Col, dq_dqm);
                    $display ("Time = %t : OPERATION = WRITE : bank = %d Row = 'h%h, Col = 'h%h, Data = 'h%h", $realtime, bank, Row, Col, dq_dqm);
                end
            end else begin
                if (Debug) begin
                    //$display("%m : at time %t WRITE: bank = %d Row = %d, Col = %d, Data = Hi-Z due to DQM", $realtime, bank, Row, Col);
                    $display ("Time = %t : OPERATION = WRITE : bank = %d Row = 'h%h, Col = 'h%h, Data = Hi-Z due to DQM", $realtime, bank, Row, Col);
                end
            end

            // Advance burst counter subroutine

        	if(Cas_latency_2 == 1) begin

               		 #tHZ2 Burst_decode;

        	end else if(Cas_latency_3 == 1) begin

               		 #tHZ3 Burst_decode;

        	end


        end else if (Data_out_enable == 1'b1) begin                         // Reading Data from Memory
            // Array buffer
            case (bank)
                2'b00 : dq_dqm = bank0[{Row, Col}];
                2'b01 : dq_dqm = bank1[{Row, Col}];
                2'b10 : dq_dqm = bank2[{Row, Col}];
                2'b11 : dq_dqm = bank3[{Row, Col}];
            endcase


            // dqm operation
            if (dqm_reg0 [0] == 1'b1) begin
                dq_dqm [ 7 : 0] = 8'bz;
            end
            if (dqm_reg0 [1] == 1'b1) begin
                dq_dqm [15 : 8] = 8'bz;
            end

            if(Cas_latency_2 ==1) begin

            // Display debug message
            if ( &(dqm_reg0) != 1'b1) begin
                dq_reg = #tAC2 dq_dqm;
                Dout_Drive_Flag = 1'b1;
                if (Debug) begin
                    //$display("%m : at time %t READ : bank = %d Row = %d, Col = %d, Data = %d", $realtime, bank, Row, Col, dq_reg);
                    $display ("Time = %t : OPERATION = READ  : bank = %d Row = 'h%h, Col = 'h%h, Data = 'h%h", $realtime, bank, Row, Col, dq_reg);
                end
            end else begin
                dq_reg = #tHZ2 {no_of_data{1'bz}};
                Dout_Drive_Flag = 1'b0;
                if (Debug) begin
                    //$display("%m : at time %t READ : bank = %d Row = %d, Col = %d, Data = Hi-Z due to DQM", $realtime, bank, Row, Col);
                    $display ("Time = %t : OPERATION = READ  : bank = %d Row = 'h%h, Col = 'h%h, Data = Hi-Z due to DQM", $realtime, bank, Row, Col);

                end
            end

            end else if(Cas_latency_3 ==1) begin

            // Display debug message
            if ( &(dqm_reg0) != 1'b1) begin
                dq_reg = #tAC3 dq_dqm;
                Dout_Drive_Flag = 1'b1;
                if (Debug) begin
                    //$display("%m : at time %t READ : bank = %d Row = %d, Col = %d, Data = %d", $realtime, bank, Row, Col, dq_reg);
                    $display ("Time = %t : OPERATION = READ  : bank = %d Row = 'h%h, Col = 'h%h, Data = 'h%h", $realtime, bank, Row, Col, dq_reg);
                end
            end else begin
                dq_reg = #tHZ3 {no_of_data{1'bz}};
                Dout_Drive_Flag = 1'b0;
                if (Debug) begin
                    //$display("%m : at time %t READ : bank = %d Row = %d, Col = %d, Data = Hi-Z due to DQM", $realtime, bank, Row, Col);
                    $display ("Time = %t : OPERATION = READ  : bank = %d Row = 'h%h, Col = 'h%h, Data = Hi-Z due to DQM", $realtime, bank, Row, Col);

                end
            end

           end
		
            // Advance burst counter subroutine
            Burst_decode;
        end
    end

    // Burst counter decode
    task Burst_decode;
        begin
            // Advance Burst Counter
            Burst_counter = Burst_counter + 1;

            // Burst Type
            if (Mode_reg[3] == 1'b0) begin                                  // Sequential Burst
                Col_temp = Col + 1;
            end else if (Mode_reg[3] == 1'b1) begin                         // Interleaved Burst
                Col_temp[2] =  Burst_counter[2] ^  Col_brst[2];
                Col_temp[1] =  Burst_counter[1] ^  Col_brst[1];
                Col_temp[0] =  Burst_counter[0] ^  Col_brst[0];
            end

            // Burst Length
            if (Burst_length_2) begin                                       // Burst Length = 2
                Col [0] = Col_temp [0];
            end else if (Burst_length_4) begin                              // Burst Length = 4
                Col [1 : 0] = Col_temp [1 : 0];
            end else if (Burst_length_8) begin                              // Burst Length = 8
                Col [2 : 0] = Col_temp [2 : 0];
            end else begin                                                  // Burst Length = FULL
                Col = Col_temp;
            end

            // Burst Read Single Write            
            if (Write_burst_mode == 1'b1) begin
                Data_in_enable = 1'b0;
            end

            // Data Counter
            if (Burst_length_1 == 1'b1) begin
                if (Burst_counter >= 1) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_2 == 1'b1) begin
                if (Burst_counter >= 2) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_4 == 1'b1) begin
                if (Burst_counter >= 4) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_8 == 1'b1) begin
                if (Burst_counter >= 8) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end
        end
    endtask

    task mem_init;
	begin
	  for (ccc=0;ccc<'b1000_0000_0000_0000_0000;ccc=ccc+1)
	  begin
	      bank0[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
	      bank1[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
	      bank2[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
	      bank3[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
	      //bank0[ccc]=16'b1111_1111_1111_1111;
	      //bank1[ccc]=16'b1111_1111_1111_1111;
	  end
	end
    endtask

    task abbank_init;
        begin
          for (ccc=0;ccc<'b1000_0000_0000_0000_0000;ccc=ccc+1)
          begin
	      bank0[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;	      
              bank1[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
          end
        end
    endtask


    task bbank_init;
        begin
          for (ccc=0;ccc<'b1000_0000_0000_0000_0000;ccc=ccc+1)
          begin
              bank1[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
          end
        end
    endtask

    task half_init;
        begin
	  bbank_init;
          for (ccc='b0100_0000_0000_0000_0000;ccc<'b1000_0000_0000_0000_0000;ccc=ccc+1)
          begin
              bank0[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
          end
        end
    endtask

    task quat_init;
        begin
	  bbank_init;
          for (ccc='b0010_0000_0000_0000_0000;ccc<'b1000_0000_0000_0000_0000;ccc=ccc+1)
          begin
              bank0[ccc]=32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx;
          end
        end
    endtask
`endprotect

    // Timing Parameters 
    specify
        specparam
          `ifdef S50
            tAH  =  1.0,                                        // addr, ba Hold Time
            tAS  =  1.5,                                        // addr, ba Setup Time
            tCH  =  2.5,                                        // Clock High-Level Width
            tCL  =  2.5,                                        // Clock Low-Level Width
            tCK  =  5.0,                                        // Clock Cycle Time
            tDH  =  1.0,                                        // Data-in Hold Time
            tDS  =  1.5,                                        // Data-in Setup Time
            tCKH =  1.0,                                        // CKE Hold  Time
            tCKS =  1.5,                                        // CKE Setup Time
            tCMH =  1.0,                                        // CSB, RASB, CASB, WEB, DQMB Hold  Time
            tCMS =  1.5;                                        // CSB, RASB, CASB, WEB, DQMB Setup Time
          `endif

          `ifdef S60
            tAH  =  1.0,                                        // addr, ba Hold Time
            tAS  =  1.5,                                        // addr, ba Setup Time
            tCH  =  2.5,                                        // Clock High-Level Width
            tCL  =  2.5,                                        // Clock Low-Level Width
            tCK  =  6.0,                                        // Clock Cycle Time
            tDH  =  1.0,                                        // Data-in Hold Time
            tDS  =  1.5,                                        // Data-in Setup Time
            tCKH =  1.0,                                        // CKE Hold  Time
            tCKS =  1.5,                                        // CKE Setup Time
            tCMH =  1.0,                                        // CSB, RASB, CASB, WEB, DQMB Hold  Time
            tCMS =  1.5;                                        // CSB, RASB, CASB, WEB, DQMB Setup Time
          `endif

          `ifdef S75
            tAH  =  1.0,                                        // addr, ba Hold Time
            tAS  =  2.0,                                        // addr, ba Setup Time
            tCH  =  2.5,                                        // Clock High-Level Width
            tCL  =  2.5,                                        // Clock Low-Level Width
            tCK  =  7.5,                                        // Clock Cycle Time
            tDH  =  1.0,                                        // Data-in Hold Time
            tDS  =  2.0,                                        // Data-in Setup Time
            tCKH =  1.0,                                        // CKE Hold  Time
            tCKS =  2.0,                                        // CKE Setup Time
            tCMH =  1.0,                                        // CSB, RASB, CASB, WEB, DQMB Hold  Time
            tCMS =  2.0;                                        // CSB, RASB, CASB, WEB, DQMB Setup Time
          `endif


        $width    (posedge clk,           tCH);
        $width    (negedge clk,           tCL);
        $period   (negedge clk,           tCK);
        $period   (posedge clk,           tCK);
        $setuphold(posedge clk,    cke,   tCKS, tCKH);
        $setuphold(posedge clk,    csb,  tCMS, tCMH);
        $setuphold(posedge clk,    casb, tCMS, tCMH);
        $setuphold(posedge clk,    rasb, tCMS, tCMH);
        $setuphold(posedge clk,    web,  tCMS, tCMH);
        $setuphold(posedge clk,    addr,  tAS,  tAH);
        $setuphold(posedge clk,    ba,    tAS,  tAH);
        $setuphold(posedge clk,    dqm,   tCMS, tCMH);
        $setuphold(posedge dq_chk, dq,    tDS,  tDH);
    endspecify


endmodule
