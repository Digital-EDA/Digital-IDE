-------------------------------------------------------------------------------
-- Copyright (c) 1995/2004 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 11.1
--  \   \         Description : Xilinx Fast Functional Simulation Library Component
--  /   /                  18X18 Signed Multiplier Followed by Three-Input Adder plus ALU with Pipeline Registers
-- /___/   /\     Filename : DSP48E1.vhd
-- \   \  /  \    Timestamp : Tue Mar 18 13:58:36 PDT 2008
--  \___\/\___\
--
-- Revision:
--    03/18/08 - Initial version.
--    05/14/08 - IR472886 fix.
--    05/19/08 - IR 473330 Fix for qa/qb_o_reg1 when AREG/BREG = 1
--    28/05/08 - CR 472154 Removed Vital GSR constructs
--    07/12/08 - IR 472222 Removed SIM_MODE attribute
--    07/18/08 - IR 477318 Overflow/Underflow generate statment issue
--    07/31/08 - IR 478377 Fixed qcarryin_o_mux7
--    08/18/08 - IR 478378 Fixed mult sign extension
--    09/22/08 - IR 490045 Fixed qad_o_mux output
--    10/02/08 - IR 491365 fixed Vital timing constructs  
--    10/10/08 - IR 491951 Pattern Detect fix
--    01/08/09 - CR 501854 -- Fixed invalid pdet comparison when there is a X in pattern.
--    03/02/09 - CR 510304 Carryout should output "X" during multiply
--    06/02/09 - CR 523600 Carryout "X"ed out before the register
--    06/05/09 - CR 523917 Carryout is "X"ed one clock cycle ahead of previous DSP48E
--    07/07/09 - CR 525163 DRC checks for USE_MULT/OPMODE combinations
--    07/21/09 - CR 527637 Fixed incorrect error message for MREG 
--    08/31/10 - CR 574213 Carryout "X"ing mismatches between verilog and vhdl
--    10/17/10 - CR 573535 Updated DRC check (carryinsel=100) since carrycascout is now always registered
--    10/20/10 - CR 574337 Output X after a certain DRC violation
--    06/23/11 - CR 612706 Removed Power Saving DRCs to Match UG
--    09/30/11 - CR 619940 -- Enhanced DRC warning
--    11/04/11 - CR 632559 -- Fixed issues caused by 619940
--    04/05/12 - PR 603477 Fast model version
--    10/17/12 - 682802 - convert GSR H/L to 1/0
-- End Revision
----- CELL DSP48E1 -----

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_SIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library STD;
use STD.TEXTIO.all;


library unisim;
use unisim.vpkg.all;
use unisim.vcomponents.all;

entity DSP48E1 is

  generic(

        ACASCREG	: integer		:= 1;
        ADREG		: integer		:= 1;
        ALUMODEREG	: integer		:= 1;
        AREG		: integer		:= 1;
        AUTORESET_PATDET	: string	:= "NO_RESET";
        A_INPUT		: string		:= "DIRECT";
        BCASCREG	: integer		:= 1;
        BREG		: integer		:= 1;
        B_INPUT		: string		:= "DIRECT";
        CARRYINREG	: integer		:= 1;
        CARRYINSELREG	: integer		:= 1;
        CREG		: integer		:= 1;
        DREG		: integer		:= 1;
        INMODEREG	: integer		:= 1;
        IS_ALUMODE_INVERTED : std_logic_vector (3 downto 0) := "0000";
        IS_CARRYIN_INVERTED : bit := '0';
        IS_CLK_INVERTED     : bit := '0';
        IS_INMODE_INVERTED  : std_logic_vector (4 downto 0) := "00000";
        IS_OPMODE_INVERTED  : std_logic_vector (6 downto 0) := "0000000";
        MASK            : bit_vector            := X"3FFFFFFFFFFF";
        MREG		: integer		:= 1;
        OPMODEREG	: integer		:= 1;
        PATTERN         : bit_vector            := X"000000000000";
        PREG		: integer		:= 1;
        SEL_MASK	: string		:= "MASK";
        SEL_PATTERN	: string		:= "PATTERN";
        USE_DPORT	: boolean		:= FALSE;
        USE_MULT	: string		:= "MULTIPLY";
        USE_PATTERN_DETECT	: string	:= "NO_PATDET";
        USE_SIMD	: string		:= "ONE48"
        );

  port(
        ACOUT                   : out std_logic_vector(29 downto 0);
        BCOUT                   : out std_logic_vector(17 downto 0);
        CARRYCASCOUT            : out std_ulogic;
        CARRYOUT                : out std_logic_vector(3 downto 0);
        MULTSIGNOUT             : out std_ulogic;
        OVERFLOW                : out std_ulogic;
        P                       : out std_logic_vector(47 downto 0);
        PATTERNBDETECT          : out std_ulogic;
        PATTERNDETECT           : out std_ulogic;
        PCOUT                   : out std_logic_vector(47 downto 0);
        UNDERFLOW               : out std_ulogic;

        A                       : in  std_logic_vector(29 downto 0);
        ACIN                    : in  std_logic_vector(29 downto 0);
        ALUMODE                 : in  std_logic_vector(3 downto 0);
        B                       : in  std_logic_vector(17 downto 0);
        BCIN                    : in  std_logic_vector(17 downto 0);
        C                       : in  std_logic_vector(47 downto 0);
        CARRYCASCIN             : in  std_ulogic;
        CARRYIN                 : in  std_ulogic;
        CARRYINSEL              : in  std_logic_vector(2 downto 0);
        CEA1                    : in  std_ulogic;
        CEA2                    : in  std_ulogic;
        CEAD                    : in  std_ulogic;
        CEALUMODE               : in  std_ulogic;
        CEB1                    : in  std_ulogic;
        CEB2                    : in  std_ulogic;
        CEC                     : in  std_ulogic;
        CECARRYIN               : in  std_ulogic;
        CECTRL                  : in  std_ulogic;
        CED                     : in  std_ulogic;
        CEINMODE                : in  std_ulogic;
        CEM                     : in  std_ulogic;
        CEP                     : in  std_ulogic;
        CLK                     : in  std_ulogic;
        D                       : in  std_logic_vector(24 downto 0);
        INMODE                  : in  std_logic_vector(4 downto 0);
        MULTSIGNIN              : in std_ulogic;
        OPMODE                  : in  std_logic_vector(6 downto 0);
        PCIN                    : in  std_logic_vector(47 downto 0);
        RSTA                    : in  std_ulogic;
        RSTALLCARRYIN           : in  std_ulogic;
        RSTALUMODE              : in  std_ulogic;
        RSTB                    : in  std_ulogic;
        RSTC                    : in  std_ulogic;
        RSTCTRL                 : in  std_ulogic;
        RSTD                    : in  std_ulogic;
        RSTINMODE               : in  std_ulogic;
        RSTM                    : in  std_ulogic;
        RSTP                    : in  std_ulogic
      );

end DSP48E1;

-- architecture body                    --

architecture DSP48E1_V of DSP48E1 is

    function find_x (
      lhs : in std_logic_vector (47 downto 0);
      rhs : in std_logic_vector (47 downto 0)
    ) return boolean is
    variable test_bit : std_ulogic := '0';
    variable found_x : boolean := false;
    variable i : integer := 0;
    begin

       found_x := false;

       for i in 0 to 47 loop
         test_bit := lhs(i);
         if (test_bit /= '0' and test_bit /= '1') then
              found_x := true;
         end if;
       end loop;
       for i in 0 to 47 loop
         test_bit := rhs(i);
         if (test_bit /= '0' and test_bit /= '1') then
              found_x := true;
         end if;
       end loop;
      return found_x;
    end;

    procedure invalid_opmode_preg_msg( OPMODE : IN string ; 
                                   CARRYINSEL : IN string ) is
    variable Message : line;
    begin
       Write ( Message, string'("OPMODE Input Warning : The OPMODE "));
       Write ( Message,  OPMODE);
       Write ( Message, string'(" with CARRYINSEL "));
       Write ( Message,  CARRYINSEL);
       Write ( Message, string'(" to DSP48E1 instance "));
       Write ( Message, string'("requires attribute PREG set to 1."));
       assert false report Message.all severity Warning;
       DEALLOCATE (Message);
    end invalid_opmode_preg_msg;

    procedure invalid_opmode_preg_msg_logic( OPMODE : IN string ) is
    variable Message : line;
    begin
       Write ( Message, string'("OPMODE Input Warning : The OPMODE "));
       Write ( Message,  OPMODE);
       Write ( Message, string'(" to DSP48E1 instance "));
       Write ( Message, string'("requires attribute PREG set to 1."));
       assert false report Message.all severity Warning;
       DEALLOCATE (Message);
    end invalid_opmode_preg_msg_logic;

    procedure invalid_opmode_mreg_msg( OPMODE : IN string ; 
                                   CARRYINSEL : IN string ) is
    variable Message : line;
    begin
       Write ( Message, string'("OPMODE Input Warning : The OPMODE "));
       Write ( Message,  OPMODE);
       Write ( Message, string'(" with CARRYINSEL "));
       Write ( Message,  CARRYINSEL);
       Write ( Message, string'(" to DSP48E1 instance "));
       Write ( Message, string'("requires attribute MREG set to 1."));
       assert false report Message.all severity Warning;
       DEALLOCATE (Message);
    end invalid_opmode_mreg_msg;

    procedure invalid_opmode_no_mreg_msg( OPMODE : IN string ; 
                                      CARRYINSEL : IN string ) is
    variable Message : line;
    begin
       Write ( Message, string'("OPMODE Input Warning : The OPMODE "));
       Write ( Message,  OPMODE);
       Write ( Message, string'(" with CARRYINSEL "));
       Write ( Message,  CARRYINSEL);
       Write ( Message, string'(" to DSP48E1 instance "));
       Write ( Message, string'("requires attribute MREG set to 0."));
       assert false report Message.all severity Warning;
       DEALLOCATE (Message);
    end invalid_opmode_no_mreg_msg;



  TYPE AluFuntionType is (INVALID_ALU, ADD_ALU, ADD_XY_NOTZ_ALU, NOT_XYZC_ALU, SUBTRACT_ALU, NOT_ALU, 
                          AND_ALU, OR_ALU, XOR_ALU, NAND_ALU, NOR_ALU, 
                          XNOR_ALU, X_AND_NOT_Z_ALU, NOT_X_OR_Z_ALU, X_OR_NOT_Z_ALU,
                          X_NOR_Z_ALU, NOT_X_AND_Z_ALU);

  constant SYNC_PATH_DELAY : time := 100 ps;

  constant MAX_ACOUT      : integer    := 30;
  constant MAX_BCOUT      : integer    := 18;
  constant MAX_CARRYOUT   : integer    := 4;
  constant MAX_P          : integer    := 48;
  constant MAX_PCOUT      : integer    := 48;

  constant MAX_A          : integer    := 30;
  constant MAX_ACIN       : integer    := 30;
  constant MAX_ALUMODE    : integer    := 4;
  constant MAX_A_MULT     : integer    := 25;
  constant MAX_B          : integer    := 18;
  constant MAX_B_MULT     : integer    := 18;
  constant MAX_BCIN       : integer    := 18;
  constant MAX_C          : integer    := 48;
  constant MAX_D          : integer    := 25;
  constant MAX_CARRYINSEL : integer    := 3;
  constant MAX_INMODE     : integer    := 5;
  constant MAX_OPMODE     : integer    := 7;
  constant MAX_PCIN       : integer    := 48;

  constant MAX_ALU_FULL   : integer    := 48;
  constant MAX_ALU_HALF   : integer    := 24;
  constant MAX_ALU_QUART  : integer    := 12;

  constant MAX_PREADD     : integer    := 25;

  constant MSB_ACOUT      : integer    := MAX_ACOUT - 1;
  constant MSB_BCOUT      : integer    := MAX_BCOUT - 1;
  constant MSB_CARRYOUT   : integer    := MAX_CARRYOUT - 1;
  constant MSB_P          : integer    := MAX_P - 1;
  constant MSB_PCOUT      : integer    := MAX_PCOUT - 1;


  constant MSB_A          : integer    := MAX_A - 1;
  constant MSB_ACIN       : integer    := MAX_ACIN - 1;
  constant MSB_ALUMODE    : integer    := MAX_ALUMODE - 1;
  constant MSB_A_MULT     : integer    := MAX_A_MULT - 1;
  constant MSB_B          : integer    := MAX_B - 1;
  constant MSB_B_MULT     : integer    := MAX_B_MULT - 1;
  constant MSB_BCIN       : integer    := MAX_BCIN - 1;
  constant MSB_C          : integer    := MAX_C - 1;
  constant MSB_CARRYINSEL : integer    := MAX_CARRYINSEL - 1;
  constant MSB_OPMODE     : integer    := MAX_OPMODE - 1;
  constant MSB_PCIN       : integer    := MAX_PCIN - 1;

  constant MSB_ALU_FULL   : integer    := MAX_ALU_FULL - 1;
  constant MSB_ALU_HALF   : integer    := MAX_ALU_HALF - 1;
  constant MSB_ALU_QUART  : integer    := MAX_ALU_QUART - 1;

  constant SHIFT_MUXZ     : integer    := 17;

  constant MSB_D          : integer    := MAX_D - 1;
  constant MSB_INMODE     : integer    := MAX_INMODE - 1;
  constant MSB_PREADD     : integer    := MAX_PREADD - 1;

  signal IS_ALUMODE_INVERTED_BIN : std_logic_vector (3 downto 0) := IS_ALUMODE_INVERTED;
  signal IS_CARRYIN_INVERTED_BIN : std_ulogic := TO_X01(IS_CARRYIN_INVERTED);
  signal IS_CLK_INVERTED_BIN     : std_ulogic := TO_X01(IS_CLK_INVERTED);
  signal IS_INMODE_INVERTED_BIN  : std_logic_vector (4 downto 0) := IS_INMODE_INVERTED;
  signal IS_OPMODE_INVERTED_BIN  : std_logic_vector (6 downto 0) := IS_OPMODE_INVERTED;

  signal 	A_ipd		: std_logic_vector(MSB_A downto 0) := (others => '0');
  signal 	ACIN_ipd	: std_logic_vector(MSB_ACIN downto 0) := (others => '0');
  signal 	ALUMODE_ipd	: std_logic_vector(MSB_ALUMODE downto 0) := (others => '0');
  signal 	B_ipd		: std_logic_vector(MSB_B downto 0) := (others => '0');
  signal 	BCIN_ipd	: std_logic_vector(MSB_BCIN downto 0) := (others => '0');
  signal 	C_ipd		: std_logic_vector(MSB_C downto 0)    := (others => '0');
  signal 	CARRYCASCIN_ipd	: std_ulogic := '0';
  signal 	CARRYIN_ipd	: std_ulogic := '0';
  signal 	CARRYINSEL_ipd	: std_logic_vector(MSB_CARRYINSEL downto 0)  := (others => '0');
  signal 	CEA1_ipd	: std_ulogic := '0';
  signal 	CEA2_ipd	: std_ulogic := '0';
  signal 	CEAD_ipd	: std_ulogic := '0';
  signal 	CEALUMODE_ipd	: std_ulogic := '0';
  signal 	CEB1_ipd	: std_ulogic := '0';
  signal 	CEB2_ipd	: std_ulogic := '0';
  signal 	CEC_ipd		: std_ulogic := '0';
  signal 	CECARRYIN_ipd	: std_ulogic := '0';
  signal 	CECTRL_ipd	: std_ulogic := '0';
  signal 	CED_ipd		: std_ulogic := '0';
  signal 	CEINMODE_ipd	: std_ulogic := '0';
  signal 	CEM_ipd		: std_ulogic := '0';
  signal 	CEP_ipd		: std_ulogic := '0';
  signal 	CLK_ipd		: std_ulogic := '0';
  signal 	D_ipd		: std_logic_vector(MSB_D downto 0)  := (others => '0');
  signal 	INMODE_ipd	: std_logic_vector(MSB_INMODE downto 0)  := (others => '0');
--signal GSR            : std_ulogic := '0';
--signal 	GSR_ipd		: std_ulogic := '0';
  signal 	MULTSIGNIN_ipd		: std_ulogic := '0';
  signal 	OPMODE_ipd	: std_logic_vector(MSB_OPMODE downto 0)  := (others => '0');
  signal 	PCIN_ipd	: std_logic_vector(MSB_PCIN downto 0) := (others => '0');
  signal 	RSTA_ipd	: std_ulogic := '0';
  signal 	RSTALLCARRYIN_ipd	: std_ulogic := '0';
  signal 	RSTALUMODE_ipd	: std_ulogic := '0';
  signal 	RSTB_ipd	: std_ulogic := '0';
  signal 	RSTC_ipd	: std_ulogic := '0';
  signal 	RSTCTRL_ipd	: std_ulogic := '0';
  signal 	RSTD_ipd	: std_ulogic := '0';
  signal 	RSTINMODE_ipd	: std_ulogic := '0';
  signal 	RSTM_ipd	: std_ulogic := '0';
  signal 	RSTP_ipd	: std_ulogic := '0';


  signal 	A_dly		: std_logic_vector(MSB_A downto 0) := (others => '0');
  signal 	ACIN_dly	: std_logic_vector(MSB_ACIN downto 0) := (others => '0');
  signal 	ALUMODE_dly	: std_logic_vector(MSB_ALUMODE downto 0) := (others => '0');
  signal 	B_dly		: std_logic_vector(MSB_B downto 0) := (others => '0');
  signal 	BCIN_dly	: std_logic_vector(MSB_BCIN downto 0) := (others => '0');
  signal 	C_dly		: std_logic_vector(MSB_C downto 0)    := (others => '0');
  signal 	CARRYCASCIN_dly	: std_ulogic := '0';
  signal 	CARRYIN_dly	: std_ulogic := '0';
  signal 	CARRYINSEL_dly	: std_logic_vector(MSB_CARRYINSEL downto 0)  := (others => '0');
  signal 	CEA1_dly	: std_ulogic := '0';
  signal 	CEA2_dly	: std_ulogic := '0';
  signal 	CEAD_dly	: std_ulogic := '0';
  signal 	CEALUMODE_dly	: std_ulogic := '0';
  signal 	CEB1_dly	: std_ulogic := '0';
  signal 	CEB2_dly	: std_ulogic := '0';
  signal 	CEC_dly		: std_ulogic := '0';
  signal 	CECARRYIN_dly	: std_ulogic := '0';
  signal 	CECTRL_dly	: std_ulogic := '0';
  signal 	CED_dly		: std_ulogic := '0';
  signal 	CEINMODE_dly	: std_ulogic := '0';
  signal 	CEM_dly		: std_ulogic := '0';
  signal 	CEP_dly		: std_ulogic := '0';
  signal 	CLK_dly		: std_ulogic := '0';
  signal 	D_dly		: std_logic_vector(MSB_D downto 0)  := (others => '0');
  signal 	INMODE_dly	: std_logic_vector(MSB_INMODE downto 0)  := (others => '0');
  signal 	GSR_dly		: std_ulogic := '0';
  signal 	MULTSIGNIN_dly	: std_ulogic := '0';
  signal 	OPMODE_dly	: std_logic_vector(MSB_OPMODE downto 0)  := (others => '0');
  signal 	PCIN_dly	: std_logic_vector(MSB_PCIN downto 0) := (others => '0');
  signal 	RSTA_dly	: std_ulogic := '0';
  signal 	RSTALLCARRYIN_dly	: std_ulogic := '0';
  signal 	RSTALUMODE_dly	: std_ulogic := '0';
  signal 	RSTB_dly	: std_ulogic := '0';
  signal 	RSTC_dly	: std_ulogic := '0';
  signal 	RSTCTRL_dly	: std_ulogic := '0';
  signal 	RSTD_dly	: std_ulogic := '0';
  signal 	RSTINMODE_dly	: std_ulogic := '0';
  signal 	RSTM_dly	: std_ulogic := '0';
  signal 	RSTP_dly	: std_ulogic := '0';


  signal	ACOUT_zd	: std_logic_vector(MSB_ACOUT downto 0) := (others => '0');
  signal	BCOUT_zd	: std_logic_vector(MSB_BCOUT downto 0) := (others => '0');
  signal 	CARRYCASCOUT_zd	: std_ulogic := '0';
  signal	CARRYOUT_zd	: std_logic_vector(MSB_CARRYOUT downto 0) := (others => '0');
  signal 	OVERFLOW_zd	: std_ulogic := '0';
  signal	P_zd		: std_logic_vector(MSB_P downto 0) := (others => '0');
  signal 	PATTERNBDETECT_zd	: std_ulogic := '0';
  signal 	PATTERNDETECT_zd	: std_ulogic := '0';
  signal	PCOUT_zd	: std_logic_vector(MSB_PCOUT downto 0) := (others => '0');
  signal 	UNDERFLOW_zd	: std_ulogic := '0';
  signal 	MULTSIGNOUT_zd	: std_ulogic;
  
  --- Internal Signal Declarations
  signal	a_o_mux		: std_logic_vector(MSB_A downto 0) := (others => '0');
  signal	qa_o_reg1	: std_logic_vector(MSB_A downto 0) := (others => '0');
  signal	qa_o_reg2	: std_logic_vector(MSB_A downto 0) := (others => '0');
  signal	qa_o_mux	: std_logic_vector(MSB_A downto 0) := (others => '0');
  signal	qacout_o_mux	: std_logic_vector(MSB_ACOUT downto 0) := (others => '0');

  signal	b_o_mux		: std_logic_vector(MSB_B downto 0) := (others => '0');
  signal	qb_o_reg1	: std_logic_vector(MSB_B downto 0) := (others => '0');
  signal	qb_o_reg2	: std_logic_vector(MSB_B downto 0) := (others => '0');
  signal	qb_o_mux	: std_logic_vector(MSB_B downto 0) := (others => '0');
  signal	qbcout_o_mux	: std_logic_vector(MSB_BCOUT downto 0) := (others => '0');

  signal	qc_o_reg        : std_logic_vector(MSB_C downto 0) := (others => '0');
  signal	qc_o_mux	: std_logic_vector(MSB_C downto 0) := (others => '0');

-- new  D 
  signal	d_o_mux		: std_logic_vector(MSB_D downto 0) := (others => '0');
  signal	qd_o_mux	: std_logic_vector(MSB_D downto 0) := (others => '0');
  signal	qd_o_reg1	: std_logic_vector(MSB_D downto 0) := (others => '0');

-- new  INMODE 
  signal	qinmode_o_mux		: std_logic_vector(MSB_INMODE downto 0) := (others => '0');
  signal	qinmode_o_reg		: std_logic_vector(MSB_INMODE downto 0) := (others => '0');

-- new  
  signal	d_portion		: std_logic_vector(MSB_D downto 0) := (others => '0');
  signal	a_preaddsub		: std_logic_vector(MSB_PREADD downto 0) := (others => '0');
  signal	ad_addsub		: std_logic_vector(MSB_A_MULT downto 0) := (others => '0');
  signal	ad_mult			: std_logic_vector(MSB_A_MULT downto 0) := (others => '0');
  signal	qad_o_reg1		: std_logic_vector(MSB_A_MULT downto 0) := (others => '0');
  signal	qad_o_mux		: std_logic_vector(MSB_A_MULT downto 0) := (others => '0');
  
  signal	b_mult			: std_logic_vector(MSB_B_MULT downto 0) := (others => '0');
  
  signal	mult_o_int	: std_logic_vector((MSB_A_MULT + MSB_B_MULT + 1) downto 0) := (others => '0');
  signal	mult_o_reg	: std_logic_vector((MSB_A_MULT + MSB_B_MULT + 1) downto 0) := (others => '0');
  signal	mult_o_mux	: std_logic_vector((MSB_A_MULT + MSB_B_MULT + 1) downto 0) := (others => '0');

  signal	opmode_o_reg	: std_logic_vector(MSB_OPMODE downto 0) := (others => '0');
  signal	opmode_o_mux	: std_logic_vector(MSB_OPMODE downto 0) := (others => '0');

  signal	muxx_o_mux	: std_logic_vector(MSB_P downto 0) := (others => '0');
  signal	muxy_o_mux	: std_logic_vector(MSB_P downto 0) := (others => '0');
  signal	muxz_o_mux	: std_logic_vector(MSB_P downto 0) := (others => '0');

  signal	carryinsel_o_reg	: std_logic_vector(MSB_CARRYINSEL downto 0) := (others => '0');
  signal	carryinsel_o_mux	: std_logic_vector(MSB_CARRYINSEL downto 0) := (others => '0');

  signal	qcarryin_o_reg0	: std_ulogic := '0';
  signal	carryin_o_mux0	: std_ulogic := '0';
  signal	qcarryin_o_reg7	: std_ulogic := '0';
  signal	carryin_o_mux7	: std_ulogic := '0';

  signal	carryin_o_mux	: std_ulogic := '0';

  signal	qp_o_reg	: std_logic_vector(MSB_P downto 0) := (others => '0');
  signal	qp_o_mux	: std_logic_vector(MSB_P downto 0) := (others => '0');

  signal	reg_p_int       : std_logic_vector(47 downto 0) := (others => '0');
  signal	p_o_int         : std_logic_vector(47 downto 0) := (others => '0');

  signal	output_x_sig	: std_ulogic := '0';

  signal	RST_META          : std_ulogic := '0';

  signal	DefDelay          : time := 10 ps;

  signal	opmode_valid_flg   : boolean := true;
  signal	alumode_valid_flg  : boolean := true;

  signal	AluFunction	: AluFuntionType := INVALID_ALU;

  signal	alumode_o_reg	: std_logic_vector(MSB_ALUMODE downto 0) := (others => '0');
  signal	alumode_o_mux	: std_logic_vector(MSB_ALUMODE downto 0) := (others => '0');

  signal	carrycascout_o  : std_ulogic := '0';
  signal	carrycascout_o_reg  : std_ulogic := '0';
  signal	carrycascout_o_mux  : std_ulogic := '0';
  signal	carryout_o_hw	: std_logic_vector(MSB_CARRYOUT downto 0) := (others => '0');
  signal	carryout_o	: std_logic_vector(MSB_CARRYOUT downto 0) := (others => '0');
  signal	carryout_o_reg	: std_logic_vector(MSB_CARRYOUT downto 0) := (others => '0');
  signal	carryout_o_mux	: std_logic_vector(MSB_CARRYOUT downto 0) := (others => '0');
  signal        carryout_x_o    : std_logic_vector(MSB_CARRYOUT downto 0) := (others => 'X');
  signal	overflow_o      : std_ulogic := '0';
  signal	pdetb_o         : std_ulogic := '0';
  signal	pdetb_o_reg1    : std_ulogic := '0';
  signal	pdetb_o_reg2    : std_ulogic := '0';
  signal	pdet_o          : std_ulogic := '0';
  signal	pdet_o_reg1     : std_ulogic := '0';
  signal	pdet_o_reg2     : std_ulogic := '0';
  signal	underflow_o     : std_ulogic := '0';

  signal	alu_o		: std_logic_vector(MSB_P downto 0) := (others => '0');
  signal	pattern_qp	: std_logic_vector(MSB_P downto 0) := (others => '0');
  signal	mask_qp		: std_logic_vector(MSB_P downto 0) := (others => '0');

  signal        multsignout_o_reg : std_ulogic;
  signal        multsignout_o_mux : std_ulogic;
  signal        multsignout_o_opmode : std_ulogic;

  signal	OPMODE_NUMBER	: integer		:= -1;

  signal	ping_opmode_drc_check : std_ulogic := '0';

  signal        y_mac_cascd     	: std_logic_vector(MSB_P downto 0) := (others => '0');
  signal	carryin_o_mux_tmp	: std_ulogic := '0';
  signal	the_auto_reset_patdet	: boolean := true;

  signal        the_pattern     	: std_logic_vector(MSB_P downto 0) := (others => '0');
  signal        the_mask     		: std_logic_vector(MSB_P downto 0) := (others => '0');

  signal 	comux 			: std_logic_vector(MSB_ALU_FULL downto 0) := (others => '0');
  signal 	smux 			: std_logic_vector(MSB_ALU_FULL downto 0) := (others => '0');

  signal 	s0 			: std_logic_vector(MAX_ALU_QUART downto 0) := (others => '0');
  signal 	s1 			: std_logic_vector(MAX_ALU_QUART downto 0) := (others => '0');
  signal 	s2 			: std_logic_vector(MAX_ALU_QUART downto 0) := (others => '0');
  signal 	s3 			: std_logic_vector((MAX_ALU_QUART + 1) downto 0) := (others => '0');

  signal 	cout0 			: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout0_prt1 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout0_prt2 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout1 			: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout1_prt1 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout1_prt2 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout2 			: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout2_prt1 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout2_prt2 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout3 			: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout3_prt1 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout3_prt2 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout4 			: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout4_prt1 		: std_logic_vector(1 downto 0) := (others => '0');
  signal 	cout4_prt2 		: std_logic_vector(1 downto 0) := (others => '0');

--  signal	cout0			: std_ulogic := '0';
--  signal	cout1			: std_ulogic := '0';
--  signal	cout2			: std_ulogic := '0';
--  signal	cout3			: std_ulogic := '0';
--  signal	cout4			: std_ulogic := '0';

  signal	co11_lsb		: std_ulogic := '0';
  signal	co23_lsb		: std_ulogic := '0';
  signal	co35_lsb		: std_ulogic := '0';

  signal	C1			: std_ulogic := '0';
  signal	C2			: std_ulogic := '0';
  signal	C3			: std_ulogic := '0';

begin


  A_dly          	 <= A              	after 0 ps;
  ACIN_dly       	 <= ACIN           	after 0 ps;
  ALUMODE_dly    	 <= ALUMODE xor IS_ALUMODE_INVERTED_BIN       	after 0 ps;
  B_dly          	 <= B              	after 0 ps;
  BCIN_dly       	 <= BCIN           	after 0 ps;
  C_dly          	 <= C              	after 0 ps;
  CARRYCASCIN_dly	 <= CARRYCASCIN    	after 0 ps;
  CARRYIN_dly    	 <= CARRYIN xor IS_CARRYIN_INVERTED_BIN       	after 0 ps;
  CARRYINSEL_dly 	 <= CARRYINSEL     	after 0 ps;
  CEA1_dly       	 <= CEA1           	after 0 ps;
  CEA2_dly       	 <= CEA2           	after 0 ps;
  CEAD_dly       	 <= CEAD           	after 0 ps;
  CEALUMODE_dly  	 <= CEALUMODE      	after 0 ps;
  CEB1_dly       	 <= CEB1           	after 0 ps;
  CEB2_dly       	 <= CEB2           	after 0 ps;
  CEC_dly        	 <= CEC            	after 0 ps;
  CECARRYIN_dly  	 <= CECARRYIN      	after 0 ps;
  CECTRL_dly     	 <= CECTRL         	after 0 ps;
  CED_dly        	 <= CED            	after 0 ps;
  CEINMODE_dly   	 <= CEINMODE       	after 0 ps;
  CEM_dly        	 <= CEM            	after 0 ps;
  CEP_dly        	 <= CEP            	after 0 ps;
  CLK_dly        	 <= CLK xor IS_CLK_INVERTED_BIN           	after 0 ps;
  D_dly          	 <= D              	after 0 ps;
  INMODE_dly     	 <= INMODE xor IS_INMODE_INVERTED_BIN        	after 0 ps;
  MULTSIGNIN_dly 	 <= MULTSIGNIN     	after 0 ps;
  OPMODE_dly     	 <= OPMODE xor IS_OPMODE_INVERTED_BIN        	after 0 ps;
  PCIN_dly       	 <= PCIN           	after 0 ps;
  RSTA_dly       	 <= RSTA           	after 0 ps;
  RSTALLCARRYIN_dly	 <= RSTALLCARRYIN  	after 0 ps;
  RSTALUMODE_dly 	 <= RSTALUMODE     	after 0 ps;
  RSTB_dly       	 <= RSTB           	after 0 ps;
  RSTC_dly       	 <= RSTC           	after 0 ps;
  RSTCTRL_dly    	 <= RSTCTRL        	after 0 ps;
  RSTD_dly       	 <= RSTD           	after 0 ps;
  RSTINMODE_dly  	 <= RSTINMODE      	after 0 ps;
  RSTM_dly       	 <= RSTM           	after 0 ps;
  RSTP_dly       	 <= RSTP           	after 0 ps;
  GSR_dly          <= TO_X01(GSR)      after 0 ps;

  --------------------
  --  BEHAVIOR SECTION
  --------------------

--####################################################################
--#####                        Initialization                      ###
--####################################################################
 prcs_init:process
  begin

----------- Checks for AREG ----------------------
    case AREG is
      when 0|1|2 =>
      when others =>
         assert false
         report "Attribute Syntax Error: Legal values for AREG are 0 or 1 or 2"
         severity Failure;
    end case;

----------- Checks for ACASCREG and (ACASCREG vs AREG) ----------------------
      
    case AREG is
      when 0 => if(AREG /= ACASCREG) then
              assert false
              report "Attribute Syntax Error : The attribute ACASCREG on DSP48E1 has to be set to 0 when attribute AREG = 0."
              severity Failure;
           end if;
      when 1 => if(AREG /= ACASCREG) then
              assert false
              report "Attribute Syntax Error : The attribute ACASCREG on DSP48E1 has to be set to 1 when attribute AREG = 1."
              severity Failure;
           end if;
      when 2 => if((AREG /= ACASCREG) and ((AREG-1) /= ACASCREG))then
              assert false
              report "Attribute Syntax Error : The attribute ACASCREG on DSP48E1 has to be set to either 2 or 1 when attribute AREG = 2."
              severity Failure;
           end if;
      when others => null;
    end case;

----------- Checks for BREG ----------------------
    case BREG is
      when 0|1|2 =>
      when others =>
         assert false
         report "Attribute Syntax Error: Legal values for BREG are 0 or 1 or 2"
         severity Failure;
    end case;

----------- Checks for BCASCREG and (BCASCREG vs BREG) ----------------------

    case BREG is
      when 0 => if(BREG /= BCASCREG) then
              assert false
              report "Attribute Syntax Error : The attribute BCASCREG on DSP48E1 has to be set to 0 when attribute BREG = 0."
              severity Failure;
           end if;
      when 1 => if(BREG /= BCASCREG) then
              assert false
              report "Attribute Syntax Error : The attribute BCASCREG on DSP48E1 has to be set to 1 when attribute BREG = 1."
              severity Failure;
           end if;
      when 2 => if((BREG /= BCASCREG) and ((BREG-1) /= BCASCREG))then
              assert false
              report "Attribute Syntax Error : The attribute BCASCREG on DSP48E1 has to be set to either 2 or 1 when attribute BREG = 2."
              severity Failure;
           end if;
      when others => null;
    end case;

----------- Check for AUTORESET_OVER_UNDER_FLOW ----------------------

--   case AUTORESET_OVER_UNDER_FLOW is
--      when true | false => null;
--      when others =>
--         assert false
--         report "Attribute Syntax Error: Legal values for AUTORESET_OVER_UNDER_FLOW are true or fasle"
--         severity Failure;
--    end case;
         
----------- Check for AUTORESET_PATDET ----------------------

    if((AUTORESET_PATDET /="NO_RESET") and (AUTORESET_PATDET /="RESET_MATCH") and (AUTORESET_PATDET /="RESET_NOT_MATCH")) then
        assert false
        report "Attribute Syntax Error: Legal values for AUTORESET_PATDET are NO_RESET or RESET_MATCH or RESET_NOT_MATCH."
        severity Failure;
    end if;
         
----------- Check for USE_MULT ----------------------

     if((USE_MULT /="NONE") and (USE_MULT /="MULTIPLY") and (USE_MULT /="DYNAMIC")) then
        assert false
        report "Attribute Syntax Error: Legal values for USE_MULT are MULTIPLY, DYNAMIC or NONE."
        severity Failure;
     end if;

----------- Check for USE_PATTERN_DETECT ----------------------

    if((USE_PATTERN_DETECT /="PATDET") and (USE_PATTERN_DETECT /="NO_PATDET")) then
        assert false
        report "Attribute Syntax Error: Legal values for USE_PATTERN_DETECT are PATDET or NO_PATDET."
        severity Failure;
    end if;

--*********************************************************
--*** ADDITIONAL DRC
--*********************************************************
-- CR 219407  --  (1)
--    if((AUTORESET_PATTERN_DETECT = TRUE) and (USE_PATTERN_DETECT = "NO_PATDET")) then
--        assert false
--        report "Attribute Syntax Error : The attribute USE_PATTERN_DETECT on DSP48E1 instance must be set to PATDET in order to use AUTORESET_PATTERN_DETECT equals TRUE. Failure to do so could make timing reports inaccurate. "
--        severity Warning;
--    end if;

--*********************************************************
--*** New Attribute DRC
--*********************************************************

    ----------- ADREG check 
    case ADREG is
      when 0|1 => null;
      when others =>
         assert false
         report "Attribute Syntax Error: Legal values for ADREG are 0 or 1 "
         severity Failure;
    end case;

    ----------- DREG check 
    case DREG is
      when 0|1 => null;
      when others =>
         assert false
         report "Attribute Syntax Error: Legal values for DREG are 0 or 1 "
         severity Failure;
    end case;

    ----------- INMODEREG check 
    case INMODEREG is
      when 0|1 => null;
      when others =>
         assert false
         report "Attribute Syntax Error: Legal values for INMODEREG are 0 or 1 "
         severity Failure;
    end case;

    ----------- USE_DPORT check 
    case USE_DPORT is
      when true | false => null;
      when others =>
         assert false
         report "Attribute Syntax Error: Legal values for USE_DPORT are true or false"
         severity Failure;
    end case;

--    612706  - following DRS were removed to match UG
    ----------- Additional DRCs for Power Savings

------------------------------------------------------------
    ping_opmode_drc_check   <= '1' after 100010 ps;
------------------------------------------------------------

    wait;
  end process prcs_init;
--####################################################################
--#####    Input Register A with two levels of registers and a mux ###
--####################################################################
  prcs_a_in:process(A_dly, ACIN_dly)
  begin
     if(A_INPUT ="DIRECT") then
        a_o_mux <= A_dly;
     elsif(A_INPUT ="CASCADE") then
        a_o_mux <= ACIN_dly;
     else
        assert false
        report "Attribute Syntax Error: Legal values for A_INPUT are DIRECT or CASCADE."
        severity Failure;
     end if;
  end process prcs_a_in;
------------------------------------------------------------------
  prcs_qa_2lvl:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
          qa_o_reg1 <= ( others => '0');
          qa_o_reg2 <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTA_dly = '1') then
               qa_o_reg1 <= ( others => '0');
               qa_o_reg2 <= ( others => '0');
            elsif (RSTA_dly = '0') then
               case AREG is
                    when 1 =>
                       if(CEA1_dly = '1') then
                          qa_o_reg1 <= a_o_mux;
                       end if;
                       if(CEA2_dly = '1') then
                          qa_o_reg2 <= a_o_mux;
                       end if;
                    when 2 =>
                       if(CEA1_dly = '1') then
                          qa_o_reg1 <= a_o_mux;
                       end if;
                       if(CEA2_dly = '1') then
                          qa_o_reg2 <= qa_o_reg1;
                       end if;
                    when others => null;
               end case;
            end if;
         end if;
      end if;
  end process prcs_qa_2lvl;
------------------------------------------------------------------
  prcs_qa_o_mux:process(a_o_mux, qa_o_reg2)
  begin
     case AREG is
       when 0   => qa_o_mux <= a_o_mux;
       when 1|2 => qa_o_mux <= qa_o_reg2;
       when others =>
            assert false
            report "Attribute Syntax Error: Legal values for AREG are 0 or 1 or 2"
            severity Failure;
     end case;
  end process prcs_qa_o_mux;
------------------------------------------------------------------
  prcs_qacout_o_mux:process(qa_o_mux, qa_o_reg1)
  begin
     case ACASCREG is
       when 1 => case AREG is
                   when 2 => qacout_o_mux <= qa_o_reg1;
                   when others =>  qacout_o_mux <= qa_o_mux;
                 end case;
       when others =>  qacout_o_mux <= qa_o_mux;
     end case;

  end process prcs_qacout_o_mux;

-- new -----
---------------Preadd ------------------------------------------------

  a_preaddsub <= (others => '0')         when (qinmode_o_mux(1) = '1') else
                  qa_o_reg1(24 downto 0) when (qinmode_o_mux(0) = '1') else
                  qa_o_mux(24 downto 0)  when (qinmode_o_mux(0) = '0');

--####################################################################
--#####    Input Register B with two levels of registers and a mux ###
--####################################################################
 prcs_b_in:process(B_dly, BCIN_dly)
  begin
     if(B_INPUT ="DIRECT") then
        b_o_mux <= B_dly;
     elsif(B_INPUT ="CASCADE") then
        b_o_mux <= BCIN_dly;
     else
        assert false
        report "Attribute Syntax Error: Legal values for B_INPUT are DIRECT or CASCADE."
        severity Failure;
     end if;
     
  end process prcs_b_in;
------------------------------------------------------------------
 prcs_qb_2lvl:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
          qb_o_reg1 <= ( others => '0');
          qb_o_reg2 <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTB_dly = '1') then
               qb_o_reg1 <= ( others => '0');
               qb_o_reg2 <= ( others => '0');
            elsif (RSTB_dly = '0') then
               case BREG is
                    when 1 =>
                       if(CEB1_dly = '1') then
                          qb_o_reg1 <= b_o_mux;
                       end if;
                       if(CEB2_dly = '1') then
                          qb_o_reg2 <= b_o_mux;
                       end if;
                    when 2 =>
                       if(CEB1_dly = '1') then
                          qb_o_reg1 <= b_o_mux;
                       end if;
                       if(CEB2_dly = '1') then
                          qb_o_reg2 <= qb_o_reg1;
                       end if;
                    when others => null;
               end case;
            end if;
         end if;
      end if;
  end process prcs_qb_2lvl;
------------------------------------------------------------------
  prcs_qb_o_mux:process(b_o_mux, qb_o_reg2)
  begin
     case BREG is
       when 0   => qb_o_mux <= b_o_mux;
       when 1|2 => qb_o_mux <= qb_o_reg2;
       when others =>
            assert false
            report "Attribute Syntax Error: Legal values for BREG are 0 or 1 or 2 "
            severity Failure;
     end case;

  end process prcs_qb_o_mux;
------------------------------------------------------------------
  prcs_qbcout_o_mux:process(qb_o_mux, qb_o_reg1)
  begin
     case BCASCREG is
       when 1 => case BREG is
                   when 2 => qbcout_o_mux <= qb_o_reg1;
                   when others =>  qbcout_o_mux <= qb_o_mux;
                 end case;
       when others =>  qbcout_o_mux <= qb_o_mux;
     end case;
  end process prcs_qbcout_o_mux;

  b_mult <= qb_o_reg1 when qinmode_o_mux(4)='1' else qb_o_mux;

--####################################################################
--#####    Input Register C with 0, 1, level of registers        #####
--####################################################################
  prcs_qc_1lvl:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         qc_o_reg <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTC_dly = '1') then
               qc_o_reg <= ( others => '0');
            elsif ((RSTC_dly = '0') and (CEC_dly = '1')) then
               qc_o_reg <= C_dly;
            end if;
         end if;
      end if;
  end process prcs_qc_1lvl;
------------------------------------------------------------------
  prcs_qc_o_mux:process(C_dly, qc_o_reg)
  begin
     case CREG is
      when 0 => qc_o_mux <= C_dly;
      when 1 => qc_o_mux <= qc_o_reg;
      when others =>
           assert false
           report "Attribute Syntax Error: Legal values for CREG are 0 or 1"
           severity Failure;
      end case;
  end process prcs_qc_o_mux;
-- new
--####################################################################
--#####    Input Register D with 0, 1, level of registers        #####
--####################################################################
  prcs_qd_1lvl:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         qd_o_reg1 <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTD_dly = '1') then
               qd_o_reg1 <= ( others => '0');
            elsif ((RSTD_dly = '0') and (CED_dly = '1')) then
               qd_o_reg1 <= D_dly;
            end if;
         end if;
      end if;
  end process prcs_qd_1lvl;
------------------------------------------------------------------
  prcs_qd_o_mux:process(D_dly, qd_o_reg1)
  begin
     case DREG is
      when 0 => qd_o_mux <= D_dly;
      when 1 => qd_o_mux <= qd_o_reg1;
      when others =>
           assert false
           report "Attribute Syntax Error: Legal values for DREG are 0 or 1"
           severity Failure;
      end case;
  end process prcs_qd_o_mux;
--####################################################################
--#####    Preaddsub AD register with 1 level deep of register   #####
--####################################################################
  d_portion <= (others => '0') when (qinmode_o_mux(2) = '0') else
               qd_o_mux when  (qinmode_o_mux(2) = '1');
  ad_addsub <= (a_preaddsub + d_portion) when (qinmode_o_mux(3) = '0') else
               (d_portion - a_preaddsub) when (qinmode_o_mux(3) = '1');

  prcs_qad_1lvl:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         qad_o_reg1 <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTD_dly = '1') then
               qad_o_reg1 <= ( others => '0');
            elsif ((RSTD_dly = '0') and (CEAD_dly = '1')) then
               qad_o_reg1 <= ad_addsub;
            end if;
         end if;
      end if;
  end process prcs_qad_1lvl;
------------------------------------------------------------------
  prcs_qad_o_mux:process(ad_addsub, qad_o_reg1)
  begin
     case ADREG is
      when 0 => qad_o_mux <= ad_addsub;
      when 1 => qad_o_mux <= qad_o_reg1;
      when others =>
           assert false
           report "Attribute Syntax Error: Legal values for ADREG are 0 or 1"
           severity Failure;
      end case;
  end process prcs_qad_o_mux;

  ad_mult <= qad_o_mux when (USE_DPORT = TRUE) else
             a_preaddsub;

--####################################################################
--#####         INMODE  with 0, 1, level of registers            #####
--####################################################################
  prcs_qinmode_1lvl:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         qinmode_o_reg <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTINMODE_dly = '1') then
               qinmode_o_reg <= ( others => '0');
            elsif ((RSTINMODE_dly = '0') and (CEINMODE_dly = '1')) then
               qinmode_o_reg <= INMODE_dly;
            end if;
         end if;
      end if;
  end process prcs_qinmode_1lvl;
------------------------------------------------------------------
  prcs_qinmode_o_mux:process(INMODE_dly, qinmode_o_reg)
  begin
     case INMODEREG is
      when 0 => qinmode_o_mux <= INMODE_dly;
      when 1 => qinmode_o_mux <= qinmode_o_reg;
      when others =>
           assert false
           report "Attribute Syntax Error: Legal values for INMODEREG are 0 or 1"
           severity Failure;
      end case;
  end process prcs_qinmode_o_mux;

--####################################################################
--###################      25x18 Multiplier     ######################
--####################################################################
--
-- 05/26/05 -- FP -- Added warning for invalid mult when USE_MULT=NONE
-- SIMD=FOUR12 and SIMD=TWO24
-- Made mult_o to be "X"
--

 mult_o_int <= (others => '0') when ((USE_MULT = "NONE") OR (USE_SIMD = "TWO24") OR (USE_SIMD = "FOUR12")) else
               ad_mult * b_mult;
 
-- old
--  prcs_mult:process(qa_o_mux, qb_o_mux)
--  begin
--     if(USE_MULT /= "NONE") then
--        mult_o_int <=  qa_o_mux(MSB_A_MULT downto 0) * qb_o_mux (MSB_B_MULT downto 0);
--     end if;
--  end process prcs_mult;
------------------------------------------------------------------
  prcs_mult_reg:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         mult_o_reg <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTM_dly = '1') then
               mult_o_reg <= ( others => '0');
            elsif ((RSTM_dly = '0') and (CEM_dly = '1')) then
               mult_o_reg <= mult_o_int;
            end if;
         end if;
      end if;
  end process prcs_mult_reg;
------------------------------------------------------------------
  prcs_mult_mux:process(mult_o_reg, mult_o_int)
  begin
     case MREG is
      when 0 => mult_o_mux <= mult_o_int;
      when 1 => mult_o_mux <= mult_o_reg;
      when others =>
           assert false
           report "Attribute Syntax Error: Legal values for MREG are 0 or 1"
           severity Failure;
      end case;
  end process prcs_mult_mux;

--####################################################################
--#####                        OpMode                            #####
--####################################################################
  prcs_opmode_reg:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         opmode_o_reg <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTCTRL_dly = '1') then
               opmode_o_reg <= ( others => '0');
            elsif ((RSTCTRL_dly = '0') and (CECTRL_dly = '1')) then
               opmode_o_reg <= OPMODE_dly;
            end if;
         end if;
      end if;
  end process prcs_opmode_reg;
------------------------------------------------------------------
  prcs_opmode_mux:process(opmode_o_reg, OPMODE_dly)
  begin
     case OPMODEREG is
      when 0 => opmode_o_mux <= OPMODE_dly;
      when 1 => opmode_o_mux <= opmode_o_reg;
      when others =>
           assert false
           report "Attribute Syntax Error: Legal values for OPMODEREG are 0 or 1"
           severity Failure;
      end case;
  end process prcs_opmode_mux;

--####################################################################
--#####                        MUX_X                             #####
--####################################################################

  prcs_mux_x:process(qp_o_mux, qa_o_mux, qb_o_mux, mult_o_mux, opmode_o_mux(1 downto 0) , output_x_sig)
  begin
--    if(output_x_sig = '1') then
--       muxx_o_mux(MSB_P downto 0) <= ( others => 'X');
--    else 
       case opmode_o_mux(1 downto 0) is
          when "00" => muxx_o_mux <= (others => '0');
          when "01" => muxx_o_mux((MSB_A_MULT + MSB_B_MULT +1) downto 0) <= mult_o_mux;
                       muxx_o_mux(MSB_PCIN downto (MAX_A_MULT + MAX_B_MULT)) <= (others => mult_o_mux(MSB_A_MULT + MSB_B_MULT + 1));
          when "10" => muxx_o_mux <= qp_o_mux;
          when "11" => if((USE_MULT = "MULTIPLY") and (
                               (AREG=0 and BREG=0 and MREG=0) or
                               (AREG=0 and BREG=0 and PREG=0) or
                               (MREG=0 and PREG=0)))
                          then
-- CR 574337 added the following line 
                          muxx_o_mux(MSB_P downto 0) <= ( others => 'X');
                          assert false
                          report "OPMODE Input Warning : The OPMODE(1:0) to DSP48E1 is invalid when using attributes USE_MULT = MULTIPLY. Please set USE_MULT to either NONE or DYNAMIC."
                          severity Warning;
                       else
                          muxx_o_mux(MSB_P downto 0)  <= (qa_o_mux & qb_o_mux);
                       end if;

          when others => null;
       end case;
--    end if;
  end process prcs_mux_x;
         
--####################################################################
--#####                        MUX_Y                             #####
--####################################################################
-- 478378
  prcs_mac_cascd:process(opmode_o_mux(6 downto 4) , MULTSIGNIN_dly)
  begin
      case opmode_o_mux(6 downto 4) is
         when "100" => y_mac_cascd(MSB_P downto 0) <= ( others => MULTSIGNIN_dly);
         when others => y_mac_cascd(MSB_P downto 0) <= ( others => '1');
      end case;
  end process prcs_mac_cascd;

--------------------------------------------------------------------------    
  prcs_mux_y:process(qc_o_mux, opmode_o_mux(3 downto 2) , carryinsel_o_mux, y_mac_cascd, output_x_sig)
  begin
--    if(output_x_sig = '1') then
--       muxy_o_mux(MSB_P downto 0) <= ( others => 'X');
--    else
       case opmode_o_mux(3 downto 2) is
          when "00" | "01" => muxy_o_mux <= ( others => '0');
          when "10" => muxy_o_mux <= y_mac_cascd;
          when "11" => muxy_o_mux <= qc_o_mux;
          when others => null;
       end case;
--    end if;
  end process prcs_mux_y;
--####################################################################
--#####                        MUX_Z                             #####
--####################################################################
  prcs_mux_z:process(qp_o_mux, qc_o_mux, PCIN_dly, opmode_o_mux(6 downto 4) , carryinsel_o_mux, output_x_sig)
  begin
--    if(output_x_sig = '1') then
--       muxz_o_mux(MSB_P downto 0) <= ( others => 'X');
--    else
       case opmode_o_mux(6 downto 4) is
          when "000" => muxz_o_mux <= ( others => '0');
          when "001" => muxz_o_mux <= PCIN_dly;
          when "010" => muxz_o_mux <= qp_o_mux;
          when "011" => muxz_o_mux <= qc_o_mux;
          when "100" => muxz_o_mux <= qp_o_mux; -- Used for MACC extend -- multsignin
          when "101" => muxz_o_mux <= (others => PCIN_dly(MSB_PCIN));
                        muxz_o_mux ((MSB_PCIN - SHIFT_MUXZ) downto 0) <= PCIN_dly(MSB_PCIN downto SHIFT_MUXZ ); 
          when "110" | "111"
                     => muxz_o_mux <= (others => qp_o_mux(MSB_P));
                        muxz_o_mux ((MSB_P - SHIFT_MUXZ) downto 0) <= qp_o_mux(MSB_P downto SHIFT_MUXZ ); 
          when others => null;
       end case;
--    end if;
  end process prcs_mux_z;
--####################################################################
--#####                        Alumode                          #####
--####################################################################
  prcs_alumode_reg:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         alumode_o_reg <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTALUMODE_dly = '1') then
               alumode_o_reg <= ( others => '0');
            elsif ((RSTALUMODE_dly = '0') and (CEALUMODE_dly = '1'))then
               alumode_o_reg <= ALUMODE_dly;
            end if;
         end if;
      end if;
  end process prcs_alumode_reg;
------------------------------------------------------------------
  prcs_alumode_mux:process(alumode_o_reg, ALUMODE_dly)
  begin
     case ALUMODEREG is
      when 0 => alumode_o_mux <= ALUMODE_dly;
      when 1 => alumode_o_mux <= alumode_o_reg;
      when others =>
           assert false
           report "Attribute Syntax Error: Legal values for ALUMODEREG are 0 or 1"
           severity Failure;
      end case;
  end process prcs_alumode_mux;

--####################################################################
--#####                     CarryInSel                           #####
--####################################################################
  prcs_carryinsel_reg:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         carryinsel_o_reg <= ( others => '0');
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTCTRL_dly = '1') then
               carryinsel_o_reg <= ( others => '0');
            elsif ((RSTCTRL_dly = '0') and (CECTRL_dly = '1')) then
               carryinsel_o_reg <= CARRYINSEL_dly;
            end if;
         end if;
      end if;
  end process prcs_carryinsel_reg;
------------------------------------------------------------------
  prcs_carryinsel_mux:process(carryinsel_o_reg, CARRYINSEL_dly)
  begin
     case CARRYINSELREG is
       when 0 => carryinsel_o_mux <= CARRYINSEL_dly;
       when 1 => carryinsel_o_mux <= carryinsel_o_reg;
       when others =>
           assert false
           report "Attribute Syntax Error: Legal values for CARRYINSELREG are 0 or 1"
           severity Failure;
     end case;
  end process prcs_carryinsel_mux;

------------------------------------------------------------------
-- CR 219047 (3)
  prcs_carryinsel_drc:process(carryinsel_o_mux, MULTSIGNIN_dly, opmode_o_mux)
  begin
     if(carryinsel_o_mux = "010") then
        if(not((MULTSIGNIN_dly = 'X') or ((opmode_o_mux = "1001000") and (MULTSIGNIN_dly /= 'X')) 
                                 or ((MULTSIGNIN_dly = '0') and (CARRYCASCIN_dly = '0')))) then
           assert false
-- CR 619940 -- Enhanced DRC warning
-- CR 632559 fixed 619940 -- Enhanced DRC warning
           report "DRC warning : CARRYCASCIN can only be used in the current DSP48E1 instance if the previous DSP48E1  is performing a two input ADD operation, or the current DSP48E1 is configured in the MAC extend opmode(6:0) equals 1001000.\n DRC warning note : The simulation model does not know the placement of the DSP48E1 slices used, so it cannot fully confirm the above warning. It is necessary to view the placement of the DSP48E1 slices and ensure that these warnings are not being breached\n"
           severity Warning;
        end if;
     end if;
  end process prcs_carryinsel_drc;

-- CR 219047 (4)
--  prcs_carryinsel_mac_drc:process(carryinsel_o_mux)
--  begin
--     if((carryinsel_o_mux = "110")  and (MULTCARRYINREG /= MREG)) then
--        assert false
--        report "Attribute Syntax Warning : It is recommended that MREG and MULTCARRYINREG on DSP48E1 instance be set to the same value when using CARRYINSEL = 110 for multiply rounding. "
--        severity Warning;
--     end if;
--  end process prcs_carryinsel_mac_drc;


--####################################################################
--#####                       CarryIn                            #####
--####################################################################

-------  input 0

  prcs_carryin_reg0:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         qcarryin_o_reg0 <= '0';
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTALLCARRYIN_dly = '1') then
               qcarryin_o_reg0 <= '0';
            elsif((RSTALLCARRYIN_dly = '0') and (CECARRYIN_dly = '1')) then
               qcarryin_o_reg0 <= CARRYIN_dly;
            end if;
         end if;
      end if;
  end process prcs_carryin_reg0;

  prcs_carryin_mux0:process(qcarryin_o_reg0, CARRYIN_dly)
  begin
     case CARRYINREG is
       when 0 => carryin_o_mux0 <= CARRYIN_dly;
       when 1 => carryin_o_mux0 <= qcarryin_o_reg0;
       when others =>
            assert false
            report "Attribute Syntax Error: Legal values for CARRYINREG are 0 or 1"
            severity Failure;
     end case;
  end process prcs_carryin_mux0;

------------------------------------------------------------------
-------  input 7

  prcs_carryin_reg7:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         qcarryin_o_reg7 <= '0';
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTALLCARRYIN_dly = '1') then
               qcarryin_o_reg7 <= '0';
-- new
            elsif((RSTALLCARRYIN_dly = '0') and (CEM_dly = '1')) then
-- IR 478377
--               qcarryin_o_reg7 <= qa_o_mux(24) XNOR qb_o_mux(17);
               qcarryin_o_reg7 <= ad_mult(24) XNOR qb_o_mux(17);
            end if;
         end if;
      end if;
  end process prcs_carryin_reg7;

--  prcs_carryin_mux7:process(qa_o_mux(24), qb_o_mux(17), qcarryin_o_reg7)
  prcs_carryin_mux7:process(ad_mult(24), qb_o_mux(17), qcarryin_o_reg7)
  begin
-- new
     case MREG is
-- IR 478377
--       when 0 => carryin_o_mux7 <= qa_o_mux(24) XNOR qb_o_mux(17);
       when 0 => carryin_o_mux7 <= ad_mult(24) XNOR qb_o_mux(17);
       when 1 => carryin_o_mux7 <= qcarryin_o_reg7;
       when others =>
            assert false
            report "Attribute Syntax Error: Legal values for MREG are 0 or 1"
            severity Failure;
     end case;
  end process prcs_carryin_mux7;


  prcs_carryin_mux:process(carryin_o_mux0, PCIN_dly(47), CARRYCASCIN_dly, carrycascout_o_mux, qp_o_mux(47), carryin_o_mux7, carryinsel_o_mux)
  begin
     case carryinsel_o_mux is
       when "000" => carryin_o_mux_tmp  <= carryin_o_mux0;
       when "001" => carryin_o_mux_tmp  <= NOT PCIN_dly(47);
       when "010" => carryin_o_mux_tmp  <= CARRYCASCIN_dly;
       when "011" => carryin_o_mux_tmp  <= PCIN_dly(47);
       when "100" => carryin_o_mux_tmp  <= carrycascout_o_mux;
       when "101" => carryin_o_mux_tmp  <= NOT qp_o_mux(47);
       when "110" => carryin_o_mux_tmp  <= carryin_o_mux7;
       when "111" => carryin_o_mux_tmp  <= qp_o_mux(47);
       when others => null;
     end case;
  end process prcs_carryin_mux;

-- disable carryin when performic logic operations 

   carryin_o_mux <= '0' when (alumode_o_mux(3) = '1' OR alumode_o_mux(2) = '1') else
                    carryin_o_mux_tmp; 
--####################################################################
--#####                     NEW ALU                              #####
--####################################################################
  prcs_co_s:process(muxx_o_mux, muxy_o_mux, muxz_o_mux, alumode_o_mux)
  variable co : std_logic_vector(MSB_ALU_FULL downto 0) := (others => '0');
  variable s  : std_logic_vector(MSB_ALU_FULL downto 0) := (others => '0');
  begin
     if(alumode_o_mux(0) = '1') then
        co := ((muxx_o_mux and muxy_o_mux) or (not(muxz_o_mux) and muxy_o_mux) or (muxx_o_mux and (not muxz_o_mux))); 
        s  := ((not muxz_o_mux) xor muxx_o_mux xor muxy_o_mux);
     else
        co := ((muxx_o_mux and muxy_o_mux) or (muxz_o_mux and muxy_o_mux) or (muxx_o_mux and muxz_o_mux)); 
        s  := (muxz_o_mux xor muxx_o_mux xor muxy_o_mux);
     end if;
    
     if(alumode_o_mux(2) = '1') then
        comux <= (others => '0');
     else
        comux <= co;
     end if;

     if(alumode_o_mux(3) = '1') then
        smux <= co;
     else
        smux <= s;
     end if;

  end process prcs_co_s;

-- FINAL ADDER
 
   s0            <= ('0' & comux(10 downto 0) & carryin_o_mux) + ('0' & smux(11 downto 0)); 
--   cout0         <= comux(11) + s0(12);
   cout0_prt1    <= ('0' & comux(11));
   cout0_prt2    <= ('0' & s0(12));
   cout0         <= cout0_prt1 + cout0_prt2;

   carryout_o_hw(0) <= not cout0(0) when (alumode_o_mux(0) and alumode_o_mux(1)) = '1' else cout0(0);

   C1            <= '0' when (USE_SIMD = "FOUR12") else s0(12); 
   co11_lsb      <= '0' when (USE_SIMD = "FOUR12") else comux(11); 
   s1            <= ('0' & comux(22 downto 12) & co11_lsb) + ('0'&smux(23 downto 12)) + C1; 
--   cout1         <= comux(23) + s1(12);
   cout1_prt1    <= ('0' & comux(23));
   cout1_prt2    <= ('0' & s1(12));
   cout1         <= cout1_prt1 + cout1_prt2;
   carryout_o_hw(1) <= not cout1(0) when (alumode_o_mux(0) and alumode_o_mux(1)) = '1' else cout1(0);

   C2            <= '0' when ((USE_SIMD = "TWO24") or (USE_SIMD = "FOUR12")) else s1(12); 
   co23_lsb      <= '0' when ((USE_SIMD = "TWO24") or (USE_SIMD = "FOUR12")) else comux(23); 
   s2            <= ('0' & comux(34 downto 24) & co23_lsb) + ('0'&smux(35 downto 24)) + C2; 
--   cout2         <= comux(35) + s2(12);
   cout2_prt1    <= ('0' & comux(35));
   cout2_prt2    <= ('0' & s2(12));
   cout2         <= cout2_prt1 + cout2_prt2;
   carryout_o_hw(2) <= not cout2(0) when (alumode_o_mux(0) and alumode_o_mux(1)) = '1' else cout2(0);

   C3            <= '0' when (USE_SIMD = "FOUR12") else s2(12); 
   co35_lsb      <= '0' when (USE_SIMD = "FOUR12") else comux(35); 
   s3            <= ('0'&comux(47 downto 36) & co35_lsb) + ('0'&smux(47 downto 36)) + C3; 
   cout3(0)         <= s3(12);
   carryout_o_hw(3) <= not cout3(0) when (alumode_o_mux(0) and alumode_o_mux(1)) = '1' else cout3(0);
   
   carrycascout_o <= cout3(0);
   cout4(0)         <= s3(13); 
--   carryout_o_hw(4) <= not cout4(0) when (alumode_o_mux(0) and alumode_o_mux(1)) = '1' else cout4(0);

   alu_o         <= not (s3(11 downto 0) & s2(11 downto 0) & s1(11 downto 0) & s0(11 downto 0)) when  alumode_o_mux(1) = '1' else
                         (s3(11 downto 0) & s2(11 downto 0) & s1(11 downto 0) & s0(11 downto 0));
--
  
--   CR 523600 -- "X" carryout for multiply and logic operations 
     carryout_o(3) <= 'X' when ((opmode_o_mux(3 downto 0) = "0101") or (alumode_o_mux(3 downto 2) /= "00" ))  else carryout_o_hw(3);
     carryout_o(2) <= 'X' when ((opmode_o_mux(3 downto 0) = "0101") or (alumode_o_mux(3 downto 2) /= "00" ))  else 
                      carryout_o_hw(2) when (USE_SIMD = "FOUR12") else 
                      'X';
     carryout_o(1) <= 'X' when ((opmode_o_mux(3 downto 0) = "0101") or (alumode_o_mux(3 downto 2) /= "00" ))  else 
                      carryout_o_hw(1) when ((USE_SIMD = "TWO24") or (USE_SIMD = "FOUR12")) else 
                      'X';
     carryout_o(0) <= 'X' when ((opmode_o_mux(3 downto 0) = "0101") or (alumode_o_mux(3 downto 2) /= "00" ))  else 
                      carryout_o_hw(0) when (USE_SIMD = "FOUR12") else 
                      'X';


--####################################################################
--#####                         ALU                              #####
--####################################################################
--  prcs_alu:process(muxx_o_mux, muxy_o_mux, muxz_o_mux, alumode_o_mux, opmode_o_mux, carryin_o_mux, output_x_sig)

--  end process prcs_alu;
--####################################################################
--#####                     AUTORESET_PATDET                     #####
--####################################################################
  the_auto_reset_patdet <= ((AUTORESET_PATDET = "RESET_MATCH") and pdet_o_reg1 = '1')
                                                  OR
                                   ((AUTORESET_PATDET = "RESET_NOT_MATCH") and  (pdet_o_reg2 = '1' and pdet_o_reg1 = '0'));
--####################################################################
--#####                CARRYOUT and CARRYCASCOUT                 #####
--####################################################################
  prcs_carry_reg:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         carryout_o_reg     <=  ( others => '0');
         carrycascout_o_reg <=  '0';
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTP_dly = '1' or the_auto_reset_patdet) then 
               carryout_o_reg     <= ( others => '0');
               carrycascout_o_reg <=  '0';
            elsif ((RSTP_dly = '0') and (CEP_dly = '1')) then
               carryout_o_reg <= carryout_o;
               carrycascout_o_reg <= carrycascout_o;
            end if;
         end if;
      end if;
  end process prcs_carry_reg;
------------------------------------------------------------------
  prcs_carryout_mux:process(carryout_o, carryout_o_reg)
  begin
     case PREG is
       when 0 => carryout_o_mux <= carryout_o;
       when 1 => carryout_o_mux <= carryout_o_reg;
       when others =>
           assert false
           report "Attribute Syntax Error: Legal values for PREG are 0 or 1"
           severity Failure;
     end case;
   
  end process prcs_carryout_mux;

------------------------------------------------------------------
-- CR 523917
--  prcs_carryout_x_o:process(carryout_o_mux, opmode_o_mux(3 downto 0))
--  begin
-- -- CR 510304 output X during mulltiply operation
--     if(opmode_o_mux(3 downto 0) = "0101") then
--        carryout_x_o <= (others => 'X');
--     elsif(USE_SIMD = "ONE48") then 
--        carryout_x_o(3) <= carryout_o_mux(3);
 --    elsif(USE_SIMD = "TWO24") then
--        carryout_x_o(3) <= carryout_o_mux(3);
--        carryout_x_o(1) <= carryout_o_mux(1);
--     elsif(USE_SIMD = "FOUR12") then
--        carryout_x_o(3) <= carryout_o_mux(3);
--        carryout_x_o(2) <= carryout_o_mux(2);
--        carryout_x_o(1) <= carryout_o_mux(1);
--        carryout_x_o(0) <= carryout_o_mux(0);
--     end if;
--  end process prcs_carryout_x_o;

------------------------------------------------------------------

-- CR 574213
   prcs_carryout_x_o:process(carryout_o_mux)
   begin
        carryout_x_o(3) <= carryout_o_mux(3);

        if(USE_SIMD = "FOUR12") then
           carryout_x_o(2) <= carryout_o_mux(2);
        else
           carryout_x_o(2) <= 'X';
        end if;

        if((USE_SIMD = "FOUR12") or (USE_SIMD = "TWO24")) then
           carryout_x_o(1) <= carryout_o_mux(1);
        else
           carryout_x_o(1) <= 'X';
        end if;

        if(USE_SIMD = "FOUR12") then
           carryout_x_o(0) <= carryout_o_mux(0);
        else
           carryout_x_o(0) <= 'X';
        end if;

   end process prcs_carryout_x_o;

------------------------------------------------------------------

  prcs_carrycascout_mux:process(carrycascout_o, carrycascout_o_reg)
  begin
     case PREG is
       when 0 => carrycascout_o_mux <= carrycascout_o;
       when 1 => carrycascout_o_mux <= carrycascout_o_reg;
       when others =>
           assert false
           report "Attribute Syntax Error: Legal values for PREG are 0 or 1"
           severity Failure;
     end case;
   
  end process prcs_carrycascout_mux;
------------------------------------------------------------------
-- CR 219047 (2)
  prcs_multsignout_o_opmode:process(mult_o_mux(MSB_A_MULT+MSB_B_MULT+1), opmode_o_mux(6 downto 4), MULTSIGNIN_dly)
  begin
--  IR 478378
    if(opmode_o_mux(6 downto 4) = "100") then
       multsignout_o_opmode <= MULTSIGNIN_dly;
    else
       multsignout_o_opmode <= mult_o_mux(MSB_A_MULT+MSB_B_MULT+1);
    end if;
  end process prcs_multsignout_o_opmode;

  prcs_multsignout_o_mux:process(multsignout_o_opmode, multsignout_o_reg)
  begin
     case PREG is
       when 0 => multsignout_o_mux <= multsignout_o_opmode;
-- CR 232275
       when 1 => multsignout_o_mux <= multsignout_o_reg;
       when others => null;
--           assert false
--           report "Attribute Syntax Error: Legal values for PREG are 0 or 1"
--           severity Failure;
     end case;
   
  end process prcs_multsignout_o_mux;
--####################################################################
--####################################################################
--####################################################################
--#####                 PCOUT and MULTSIGNOUT                    #####
--####################################################################
  prcs_qp_reg:process(CLK_dly, GSR_dly)
  begin
      if(GSR_dly = '1') then
         qp_o_reg <=  ( others => '0');
         multsignout_o_reg <= '0';
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTP_dly = '1' or the_auto_reset_patdet) then 
               qp_o_reg <= ( others => '0');
               multsignout_o_reg <= '0';
            elsif ((RSTP_dly = '0') and (CEP_dly = '1')) then
               qp_o_reg <= alu_o;
               multsignout_o_reg <= mult_o_reg((MSB_A_MULT+MSB_B_MULT+1));
            end if;
         end if;
      end if;
  end process prcs_qp_reg;
------------------------------------------------------------------
  prcs_qp_mux:process(alu_o, qp_o_reg)
  begin
     case PREG is
       when 0 => qp_o_mux <= alu_o;
       when 1 => qp_o_mux <= qp_o_reg;
       when others =>
           assert false
           report "Attribute Syntax Error: Legal values for PREG are 0 or 1"
           severity Failure;
     end case;
   
  end process prcs_qp_mux;
--####################################################################
--#####                    Pattern Detector                      #####
--####################################################################

-- new  
   the_pattern <= To_StdLogicVector(PATTERN) when (SEL_PATTERN = "PATTERN") else
                  qc_o_mux; 

   the_mask    <= To_StdLogicVector(MASK) when (SEL_MASK = "MASK") else
                  qc_o_mux  when (SEL_MASK = "C") else 
                  To_StdLogicVector((To_bitvector( not qc_o_mux)) sla 1)  when (SEL_MASK = "ROUNDING_MODE1") else 
                  To_StdLogicVector((To_bitvector( not qc_o_mux)) sla 2)  when (SEL_MASK = "ROUNDING_MODE2");

  prcs_pdet:process(alu_o, the_mask, the_pattern, GSR_dly )
  variable x_found : boolean := false;
  variable lhs     : std_logic_vector(MSB_P downto 0) := (others => '0');
  variable rhs     : std_logic_vector(MSB_P downto 0) := (others => '0');

  begin
  --   CR 501854

       lhs := (alu_o or mask_qp);
       rhs := (pattern_qp or mask_qp);

       x_found := find_x(lhs, rhs);

       if(((alu_o or the_mask) = (the_pattern or the_mask)) and (GSR_dly = '0') and (not x_found))then 
          pdet_o <= '1';
       else
          pdet_o <= '0';
       end if;

       if(((alu_o or the_mask) = ((NOT the_pattern) or the_mask)) and (GSR_dly = '0') and (not x_found)) then 
          pdetb_o <= '1';
       else
          pdetb_o <= '0';
       end if;

  end process prcs_pdet;

---------------------------------------------------------------

  prcs_pdet_reg:process(CLK_dly, GSR_dly)
  variable pdetb_reg1_var, pdetb_reg2_var, pdet_reg1_var, pdet_reg2_var : std_ulogic := '0';  
  begin
      if(GSR_dly = '1') then
         pdetb_o_reg1 <= '0';
         pdetb_o_reg2 <= '0';
         pdet_o_reg1  <= '0';
         pdet_o_reg2  <= '0';

         pdetb_reg1_var := '0';
         pdetb_reg2_var := '0';
         pdet_reg1_var  := '0';
         pdet_reg2_var  := '0';
      elsif (GSR_dly = '0') then
         if(rising_edge(CLK_dly)) then
            if(RSTP_dly = '1' or the_auto_reset_patdet) then 
               pdetb_o_reg1 <= '0';
               pdetb_o_reg2 <= '0';
               pdet_o_reg1  <= '0';
               pdet_o_reg2  <= '0';

               pdetb_reg1_var := '0';
               pdetb_reg2_var := '0';
               pdet_reg1_var  := '0';
               pdet_reg2_var  := '0';
            elsif ((RSTP_dly = '0') and (CEP_dly = '1')) then
               pdetb_reg2_var := pdetb_reg1_var;
               pdetb_reg1_var := pdetb_o;

               pdet_reg2_var := pdet_reg1_var;
               pdet_reg1_var := pdet_o;

               pdetb_o_reg1 <= pdetb_reg1_var;
               pdetb_o_reg2 <= pdetb_reg2_var;
               pdet_o_reg1  <= pdet_reg1_var;
               pdet_o_reg2  <= pdet_reg2_var;

            end if;
         end if;
      end if;
  end process prcs_pdet_reg;

-- old  prcs_sel_pattern_detect:process(alu_o, qc_o_mux)
-- old  begin

--     -- Select the pattern
--     if((SEL_PATTERN = "PATTERN") or (SEL_PATTERN = "pattern")) then
--         pattern_qp <= To_StdLogicVector(PATTERN);
--     elsif((SEL_PATTERN = "C") or (SEL_PATTERN = "c")) then
--         pattern_qp <= qc_o_mux;
--     else 
--         assert false
--         report "Attribute Syntax Error: The attribute SEL_PATTERN on DSP48_ALU is incorrect. Legal values for this attribute are PATTERN or C"
--         severity Failure;
--     end if;
--
--     -- Select the mask  -- if ROUNDING MASK set, use rounding mode, else use SEL_MASK
--     if((SEL_ROUNDING_MASK = "SEL_MASK") or (SEL_ROUNDING_MASK = "sel_mask")) then
--         if((SEL_MASK = "MASK") or (SEL_MASK = "mask")) then
--             mask_qp <= To_StdLogicVector(MASK);
--         elsif((SEL_MASK = "C") or (SEL_MASK = "c")) then
--             mask_qp <= qc_o_mux;
--         else
--           assert false
--           report "Attribute Syntax Error: The attribute SEL_MASK on DSP48_ALU is incorrect. Legal values for this attribute are MASK or C"
--           severity Failure;
--         end if;
--     elsif((SEL_ROUNDING_MASK = "MODE1") or (SEL_ROUNDING_MASK = "mode1")) then
--         mask_qp <=   To_StdLogicVector((To_bitvector( not qc_o_mux)) sla 1) ;
--         mask_qp (0) <= '0';
--     elsif((SEL_ROUNDING_MASK = "MODE2") or (SEL_ROUNDING_MASK = "mode2")) then
--         mask_qp <=   To_StdLogicVector((To_bitvector( not qc_o_mux)) sla 2) ;
--         mask_qp (1 downto 0) <= (others => '0');
--     else
--         assert false
--         report "Attribute Syntax Error: The attribute SEL_ROUNDING_MASK on DSP48_ALU is incorrect. Legal values for this attribute are SEL_MASK or MODE1 or MODE2."
--         severity Failure;
--     end if;
--     
--  end process prcs_sel_pattern_detect;


---------------------------------------------------------------

--  prcs_pdet:process(alu_o, mask_qp, pattern_qp, GSR_dly )
--  begin
--       if(((alu_o or mask_qp) = (pattern_qp or mask_qp)) and (GSR_dly = '0'))then 
--          pdet_o <= '1';
--       else
--          pdet_o <= '0';
--       end if;
--
--       if(((alu_o or mask_qp) = ((NOT pattern_qp) or mask_qp)) and (GSR_dly = '0')) then 
--          pdetb_o <= '1';
--       else
--          pdetb_o <= '0';
--       end if;
--
--  end process prcs_pdet;

---------------------------------------------------------------

--  prcs_pdet_reg:process(CLK_dly, GSR_dly)
--  variable pdetb_reg1_var, pdetb_reg2_var, pdet_reg1_var, pdet_reg2_var : std_ulogic := '0';  
--  begin
--      if(GSR_dly = '1') then
--         pdetb_o_reg1 <= '0';
--         pdetb_o_reg2 <= '0';
--         pdet_o_reg1  <= '0';
--         pdet_o_reg2  <= '0';
--
--         pdetb_reg1_var := '0';
--         pdetb_reg2_var := '0';
--         pdet_reg1_var  := '0';
--         pdet_reg2_var  := '0';
--      elsif (GSR_dly = '0') then
--         if(rising_edge(CLK_dly)) then
--            if(RSTP_dly = '1' or the_auto_reset_patdet) then 
--               pdetb_o_reg1 <= '0';
--               pdetb_o_reg2 <= '0';
--               pdet_o_reg1  <= '0';
--               pdet_o_reg2  <= '0';
--
--               pdetb_reg1_var := '0';
--               pdetb_reg2_var := '0';
--               pdet_reg1_var  := '0';
--               pdet_reg2_var  := '0';
--            elsif ((RSTP_dly = '0') and (CEP_dly = '1')) then
--               pdetb_reg2_var := pdetb_reg1_var;
--               pdetb_reg1_var := pdetb_o;
--
--               pdet_reg2_var := pdet_reg1_var;
--               pdet_reg1_var := pdet_o;
--
--               pdetb_o_reg1 <= pdetb_reg1_var;
--               pdetb_o_reg2 <= pdetb_reg2_var;
--               pdet_o_reg1  <= pdet_reg1_var;
--               pdet_o_reg2  <= pdet_reg2_var;
--
--            end if;
--         end if;
--      end if;
--  end process prcs_pdet_reg;

--####################################################################
--#####                 Underflow / Overflow                     #####
--####################################################################
  prcs_uflow_oflow:process(pdet_o_reg1 , pdet_o_reg2 , pdetb_o_reg1 , pdetb_o_reg2)
  begin
    if(GSR_dly = '1') then
        overflow_o  <= '0';
        underflow_o <= '0';
    elsif((USE_PATTERN_DETECT = "PATDET") or (PREG = 1))then
        overflow_o  <= pdet_o_reg2   AND  (NOT pdet_o_reg1)  AND  (NOT pdetb_o_reg1);
        underflow_o <= pdetb_o_reg2  AND  (NOT pdet_o_reg1)  AND (NOT pdetb_o_reg1);
    else
        overflow_o  <= 'X';
        underflow_o <= 'X';
    end if;

  end process prcs_uflow_oflow;
-- skip for fast_model 
--####################################################################
--#####                 OPMODE DRC                               #####
--####################################################################

-- end skip for fast_model 
--####################################################################
--#####                   ZERO_DELAY_OUTPUTS                     #####
--####################################################################
  prcs_zero_delay_outputs:process(qacout_o_mux, qbcout_o_mux, carryout_x_o, carrycascout_o_mux,
                                  overflow_o, qp_o_mux, pdet_o, pdetb_o,
                                  pdet_o_reg1, pdetb_o_reg1,
                                  pdet_o_reg2, pdetb_o_reg2,
                                  underflow_o, multsignout_o_mux, opmode_valid_flg, alumode_valid_flg)
  begin
    ACOUT_zd          <= qacout_o_mux;
    BCOUT_zd          <= qbcout_o_mux;
    OVERFLOW_zd       <= overflow_o;
    UNDERFLOW_zd      <= underflow_o;
    P_zd              <= qp_o_mux;
    PCOUT_zd          <= qp_o_mux;
    MULTSIGNOUT_zd    <= multsignout_o_mux;

    if(the_auto_reset_patdet) then
      CARRYCASCOUT_zd   <= '0';
      CARRYOUT_zd       <= (others => '0');
    else
      CARRYCASCOUT_zd   <= carrycascout_o_mux;   
      CARRYOUT_zd       <= carryout_x_o; 
    end if;

--    if((USE_PATTERN_DETECT = "NO_PATDET") or (not opmode_valid_flg) or (not alumode_valid_flg)) then
--  IR 491951
    if((not opmode_valid_flg) or (not alumode_valid_flg)) then
       PATTERNBDETECT_zd <= 'X';
       PATTERNDETECT_zd  <= 'X';
    elsif (PREG = 0) then
          PATTERNBDETECT_zd <= pdetb_o;
          PATTERNDETECT_zd  <= pdet_o;
    elsif(PREG = 1) then
          PATTERNBDETECT_zd <= pdetb_o_reg1;
          PATTERNDETECT_zd  <= pdet_o_reg1;
    end if;

  end process prcs_zero_delay_outputs;

--####################################################################
--#####                         OUTPUT                           #####
--####################################################################
  prcs_output:process(ACOUT_zd, BCOUT_zd, CARRYCASCOUT_zd, CARRYOUT_zd,
                      OVERFLOW_zd, P_zd, PATTERNBDETECT_zd, PATTERNDETECT_zd,
                      PCOUT_zd, UNDERFLOW_zd, MULTSIGNOUT_zd)
  begin
      ACOUT             <= ACOUT_zd after SYNC_PATH_DELAY;
      BCOUT             <= BCOUT_zd after SYNC_PATH_DELAY;
      CARRYCASCOUT      <= CARRYCASCOUT_zd after SYNC_PATH_DELAY;
      CARRYOUT          <= CARRYOUT_zd after SYNC_PATH_DELAY;
      OVERFLOW          <= OVERFLOW_zd after SYNC_PATH_DELAY;
      P                 <= P_zd after SYNC_PATH_DELAY;
      PATTERNBDETECT    <= PATTERNBDETECT_zd after SYNC_PATH_DELAY;
      PATTERNDETECT     <= PATTERNDETECT_zd after SYNC_PATH_DELAY;
      PCOUT             <= PCOUT_zd after SYNC_PATH_DELAY;
      UNDERFLOW         <= UNDERFLOW_zd after SYNC_PATH_DELAY;

      MULTSIGNOUT       <= MULTSIGNOUT_zd after SYNC_PATH_DELAY;
  end process prcs_output;



end DSP48E1_V;

