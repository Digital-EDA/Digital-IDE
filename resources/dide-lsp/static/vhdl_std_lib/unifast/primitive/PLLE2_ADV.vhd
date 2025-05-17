-- Copyright (c) 1995/2010 Xilinx, Inc.
-- All Right Reserved.
------------------------------------------------------------------------------/
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 13.i (O.xx)
--  \   \         Description : Xilinx Function Simulation Library Component
--  /   /                  Phase Lock Loop Clock 
-- /___/   /\     Filename : PLLE2_ADV.vhd
-- \   \  /  \    Timestamp : 
--  \___\/\___\
--
-- Revision:
--    10/17/11 - Initial version.
-- End Revision

----- CELL PLLE2_ADV -----

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_SIGNED.all;
use IEEE.NUMERIC_STD.all;
library STD;
use STD.TEXTIO.all;


library unisim;
use unisim.VPKG.all;
use unisim.VCOMPONENTS.all;

entity PLLE2_ADV is
generic (
      BANDWIDTH : string := "OPTIMIZED";
      CLKFBOUT_MULT : integer := 5;
      CLKFBOUT_PHASE : real := 0.0;
      CLKIN1_PERIOD : real := 0.0;
      CLKIN2_PERIOD : real := 0.0;
      CLKOUT0_DIVIDE : integer := 1;
      CLKOUT0_DUTY_CYCLE : real := 0.5;
      CLKOUT0_PHASE : real := 0.0;
      CLKOUT1_DIVIDE : integer := 1;
      CLKOUT1_DUTY_CYCLE : real := 0.5;
      CLKOUT1_PHASE : real := 0.0;
      CLKOUT2_DIVIDE : integer := 1;
      CLKOUT2_DUTY_CYCLE : real := 0.5;
      CLKOUT2_PHASE : real := 0.0;
      CLKOUT3_DIVIDE : integer := 1;
      CLKOUT3_DUTY_CYCLE : real := 0.5;
      CLKOUT3_PHASE : real := 0.0;
      CLKOUT4_DIVIDE : integer := 1;
      CLKOUT4_DUTY_CYCLE : real := 0.5;
      CLKOUT4_PHASE : real := 0.0;
      CLKOUT5_DIVIDE : integer := 1;
      CLKOUT5_DUTY_CYCLE : real := 0.5;
      CLKOUT5_PHASE : real := 0.0;
      COMPENSATION : string := "ZHOLD";
      DIVCLK_DIVIDE : integer := 1;
      IS_CLKINSEL_INVERTED : bit := '0';
      IS_PWRDWN_INVERTED : bit := '0';
      IS_RST_INVERTED : bit := '0';
      REF_JITTER1 : real := 0.0;
      REF_JITTER2 : real := 0.0;
      STARTUP_WAIT : string := "FALSE"
  );
port (
      CLKFBOUT             : out std_ulogic := '0';
      CLKOUT0              : out std_ulogic := '0';
      CLKOUT1              : out std_ulogic := '0';
      CLKOUT2              : out std_ulogic := '0';
      CLKOUT3              : out std_ulogic := '0';
      CLKOUT4              : out std_ulogic := '0';
      CLKOUT5              : out std_ulogic := '0';
      DO                   : out std_logic_vector (15 downto 0);
      DRDY                 : out std_ulogic := '0';
      LOCKED               : out std_ulogic := '0';
      CLKFBIN              : in std_ulogic;
      CLKIN1               : in std_ulogic;
      CLKIN2               : in std_ulogic;
      CLKINSEL             : in std_ulogic;
      DADDR                : in std_logic_vector(6 downto 0);
      DCLK                 : in std_ulogic;
      DEN                  : in std_ulogic;
      DI                   : in std_logic_vector(15 downto 0);
      DWE                  : in std_ulogic;
      PWRDWN               : in std_ulogic;
      RST                  : in std_ulogic
     );
end PLLE2_ADV;


-- Architecture body --

architecture PLLE2_ADV_V of PLLE2_ADV is

  function real2int( real_in : in real) return integer is
    variable int_value : integer;
    variable int_value1 : integer;
    variable tmps : time := 1 ps;
    variable tmps1 : real;

  begin
    if (real_in < 1.00000 and real_in > -1.00000) then
        int_value1 := 0;
    else
      tmps := real_in * 1 ns;
      int_value := tmps / 1 ns;
      tmps1 := real (int_value);
      if ( tmps1 > real_in) then
        int_value1 := int_value - 1 ;
      else
        int_value1 := int_value;
      end if;
    end if;
    return int_value1;
  end real2int;

  function clkout_duty_chk (CLKOUT_DIVIDE : in integer;
                            CLKOUT_DUTY_CYCLE : in real;
                            CLKOUT_DUTY_CYCLE_N : in string)
                          return std_ulogic is
    constant O_MAX_HT_LT_real : real := 64.0;
    variable CLKOUT_DIVIDE_real : real;
    variable CLK_DUTY_CYCLE_MIN : real;
    variable CLK_DUTY_CYCLE_MIN_rnd : real;
    variable CLK_DUTY_CYCLE_MAX : real;
    variable CLK_DUTY_CYCLE_STEP : real;
    variable clk_duty_tmp_int : integer;
    variable  duty_cycle_valid : std_ulogic;
    variable tmp_duty_value : real;
    variable  tmp_j : real;
    variable Message : line;
    variable step_round_tmp : integer;
    variable step_round_tmp1 : real;

  begin
    CLKOUT_DIVIDE_real := real(CLKOUT_DIVIDE);
    step_round_tmp := 1000 /CLKOUT_DIVIDE;
    step_round_tmp1 := real(step_round_tmp);
    if (CLKOUT_DIVIDE_real > O_MAX_HT_LT_real) then
      CLK_DUTY_CYCLE_MIN := (CLKOUT_DIVIDE_real - O_MAX_HT_LT_real)/CLKOUT_DIVIDE_real;
      CLK_DUTY_CYCLE_MAX := (O_MAX_HT_LT_real + 0.5)/CLKOUT_DIVIDE_real;
      CLK_DUTY_CYCLE_MIN_rnd := CLK_DUTY_CYCLE_MIN;
    else
      if (CLKOUT_DIVIDE = 1) then
          CLK_DUTY_CYCLE_MIN_rnd := 0.0;
          CLK_DUTY_CYCLE_MIN := 0.0;
      else
          CLK_DUTY_CYCLE_MIN_rnd := step_round_tmp1 / 1000.00;
          CLK_DUTY_CYCLE_MIN := 1.0 / CLKOUT_DIVIDE_real;
      end if;
      CLK_DUTY_CYCLE_MAX := 1.0;
    end if;

    if ((CLKOUT_DUTY_CYCLE > CLK_DUTY_CYCLE_MAX) or (CLKOUT_DUTY_CYCLE < CLK_DUTY_CYCLE_MIN_rnd)) then
      Write ( Message, string'(" Attribute Syntax Warning : "));
      Write ( Message, CLKOUT_DUTY_CYCLE_N);
      Write ( Message, string'(" is set to "));
      Write ( Message, CLKOUT_DUTY_CYCLE);
      Write ( Message, string'(" and is not in the allowed range "));
      Write ( Message, CLK_DUTY_CYCLE_MIN);
      Write ( Message, string'("  to "));
      Write ( Message, CLK_DUTY_CYCLE_MAX);
      Write ( Message, '.' & LF );
     assert false report Message.all severity warning;
      DEALLOCATE (Message);
    end if;

    CLK_DUTY_CYCLE_STEP := 0.5 / CLKOUT_DIVIDE_real;
    tmp_j := 0.0;
    duty_cycle_valid := '0';
    clk_duty_tmp_int := 0;
    for j in 0 to  (2 * CLKOUT_DIVIDE ) loop
      tmp_duty_value := CLK_DUTY_CYCLE_MIN + CLK_DUTY_CYCLE_STEP * tmp_j;
      if (abs(tmp_duty_value - CLKOUT_DUTY_CYCLE) < 0.001 and (tmp_duty_value <= CLK_DUTY_CYCLE_MAX)) then
          duty_cycle_valid := '1';
      end if;
      tmp_j := tmp_j + 1.0;
    end loop;

    if (duty_cycle_valid /= '1') then
      Write ( Message, string'(" Attribute Syntax Warning : "));
      Write ( Message, CLKOUT_DUTY_CYCLE_N);
      Write ( Message, string'(" =  "));
      Write ( Message, CLKOUT_DUTY_CYCLE);
      Write ( Message, string'(" which is  not an allowed value. Allowed value s are: "));
      Write ( Message,  LF );
      tmp_j := 0.0;
      for j in 0 to  (2 * CLKOUT_DIVIDE ) loop
        tmp_duty_value := CLK_DUTY_CYCLE_MIN + CLK_DUTY_CYCLE_STEP * tmp_j;
        if ( (tmp_duty_value <= CLK_DUTY_CYCLE_MAX) and (tmp_duty_value < 1.0)) then
           Write ( Message,  tmp_duty_value);
           Write ( Message,  LF );
        end if;
        tmp_j := tmp_j + 1.0;
     end loop;
      assert false report Message.all severity warning;
      DEALLOCATE (Message);
    end if;
    return duty_cycle_valid;
  end function clkout_duty_chk;

  constant VCOCLK_FREQ_MAX : real := 2133.0;
  constant VCOCLK_FREQ_MIN : real := 800.0;
  constant CLKIN_FREQ_MAX : real := 1066.0;
  constant CLKIN_FREQ_MIN : real := 19.0;
  constant CLKPFD_FREQ_MAX : real := 550.0;
  constant CLKPFD_FREQ_MIN : real := 19.0;
  constant VCOCLK_FREQ_TARGET : real := 1200.0;
  constant O_MAX_HT_LT : integer := 64;
  constant REF_CLK_JITTER_MAX : time := 1000 ps;
  constant REF_CLK_JITTER_SCALE : real := 0.1;
  constant MAX_FEEDBACK_DELAY : time := 10 ns;
  constant MAX_FEEDBACK_DELAY_SCALE : real := 1.0;
  constant M_MAX : real := 64.000;
  constant M_MIN : real := 2.000;
  constant D_MAX : integer := 80;
  constant D_MIN : integer := 1;

  signal pwrdwn_in1 : std_ulogic :=  '0';
  signal rst_input : std_ulogic :=  '0';
  signal init_done : std_ulogic :=  '0';
  signal clkpll_r : std_ulogic :=  '0';
  signal locked_out_tmp  : std_ulogic :=  '0';
  signal clkfb_div_fint : integer := 0;
  signal clkfb_val : integer := 0;
  signal clkfb_val1 : integer := 0;
  signal clkfb_val11 : integer := 0;
  signal clkfb_val2 : integer := 0;
  signal clk0_val : integer := 0;
  signal clk0_val1 : integer := 0;
  signal clk0_val11 : integer := 0;
  signal clk1_val11 : integer := 0;
  signal clk2_val11 : integer := 0;
  signal clk3_val11 : integer := 0;
  signal clk4_val11 : integer := 0;
  signal clk5_val11 : integer := 0;
  signal clk0_val2 : integer := 0;
  signal clk1_val2 : integer := 0;
  signal clk2_val2 : integer := 0;
  signal clk3_val2 : integer := 0;
  signal clk4_val2 : integer := 0;
  signal clk5_val2 : integer := 0;
  signal clk1_val : integer := 0;
  signal clk1_val1 : integer := 0;
  signal clk2_val : integer := 0;
  signal clk2_val1 : integer := 0;
  signal clk3_val : integer := 0;
  signal clk3_val1 : integer := 0;
  signal clk4_val : integer := 0;
  signal clk4_val1 : integer := 0;
  signal clk5_val : integer := 0;
  signal clk5_val1 : integer := 0;
  signal chk_ok : std_ulogic :=  '0';
  constant period_vco_target : time :=   1000 ps / VCOCLK_FREQ_TARGET;
  constant fb_delay_max : time := MAX_FEEDBACK_DELAY * MAX_FEEDBACK_DELAY_SCALE;
  signal pll_lock_time : integer := 0;
  signal clkfb_out  : std_ulogic :=  '0';
  signal clkout0_out  : std_ulogic :=  '0';
  signal clkout1_out  : std_ulogic :=  '0';
  signal clkout2_out  : std_ulogic :=  '0';
  signal clkout3_out  : std_ulogic :=  '0';
  signal clkout4_out  : std_ulogic :=  '0';
  signal clkout5_out  : std_ulogic :=  '0';
  signal p_fb : time := 0 ps;
  signal p_fb_h : time := 0 ps;
  signal p_fb_r : time := 0 ps;
  signal p_fb_r1 : time := 0 ps;
  signal p_fb_d : time := 0 ps;
  signal p_c0_dr : time := 0 ps;
  signal p_c1_dr : time := 0 ps;
  signal p_c2_dr : time := 0 ps;
  signal p_c3_dr : time := 0 ps;
  signal p_c4_dr : time := 0 ps;
  signal p_c5_dr : time := 0 ps;
  signal p_c6_dr : time := 0 ps;
  signal p_c0_h : time := 0 ps;
  signal p_c0_r : time := 0 ps;
  signal p_c0_d : time := 0 ps;
  signal p_c0_r1 : time := 0 ps;
  signal p_c1_r1 : time := 0 ps;
  signal p_c2_r1 : time := 0 ps;
  signal p_c3_r1 : time := 0 ps;
  signal p_c4_r1 : time := 0 ps;
  signal p_c5_r1 : time := 0 ps;
  signal p_c6_r1 : time := 0 ps;
  signal p_c1_h : time := 0 ps;
  signal p_c1_r : time := 0 ps;
  signal p_c1_d : time := 0 ps;
  signal p_c2_h : time := 0 ps;
  signal p_c2_r : time := 0 ps;
  signal p_c2_d : time := 0 ps;
  signal p_c3_h : time := 0 ps;
  signal p_c3_r : time := 0 ps;
  signal p_c3_d : time := 0 ps;
  signal p_c4_h : time := 0 ps;
  signal p_c4_r : time := 0 ps;
  signal p_c4_d : time := 0 ps;
  signal p_c5_h : time := 0 ps;
  signal p_c5_r : time := 0 ps;
  signal p_c5_d : time := 0 ps;
  signal period_fb : time := 0 ps;
  signal clk0_gen : std_ulogic := '0';
  signal clk1_gen : std_ulogic := '0';
  signal clk2_gen : std_ulogic := '0';
  signal clk3_gen : std_ulogic := '0';
  signal clk4_gen : std_ulogic := '0';
  signal clk5_gen : std_ulogic := '0';
  signal clkfb_gen : std_ulogic := '0';
  signal clk0_gen_f : std_ulogic := '0';
  signal clk1_gen_f : std_ulogic := '0';
  signal clk2_gen_f : std_ulogic := '0';
  signal clk3_gen_f : std_ulogic := '0';
  signal clk4_gen_f : std_ulogic := '0';
  signal clk5_gen_f : std_ulogic := '0';
  signal clkfb_gen_f : std_ulogic := '0';
  signal sample_en : std_ulogic := '1';
  signal clk0_out : std_ulogic := '0';
  signal clk1_out : std_ulogic := '0';
  signal clk2_out : std_ulogic := '0';
  signal clk3_out : std_ulogic := '0';
  signal clk4_out : std_ulogic := '0';
  signal clk5_out : std_ulogic := '0';
  signal clkfbm1_out : std_ulogic := '0';
  signal fb_delay_found_tmp : std_ulogic := '0';
  signal fb_delay_found : std_ulogic := '0';
  type   real_array_usr is array (4 downto 0) of time;
  signal clkin_period : real_array_usr := (others => 0 ps);
  signal clkout_mux  : std_logic_vector (7 downto 0) ; 
  signal lock_period_time : integer := 0;
  signal clkout_en_time : integer := 0;
  signal locked_en_time : integer := 0;
  signal lock_cnt_max : integer := 0;
  signal pwron_int : std_ulogic :=  '0';
  signal rst_in : std_ulogic :=  '0';
  signal pll_locked_tmp1 : std_ulogic :=  '0';
  signal pll_locked_tmp2 : std_ulogic :=  '0';
  signal lock_period : std_ulogic :=  '0';
  signal pll_locked_tm : std_ulogic :=  '0';
  signal clkin_edge : time := 0 ps;
  signal fb_delay : time := 0 ps;
  signal clkvco_delay : time := 0 ps;
  signal clkin_lock_cnt : integer := 0;
  signal  clkfbm1_dly : time := 0 ps;
  signal clkout_en0_tmp : std_ulogic := '0';
  signal clkout_en : std_ulogic := '0';
  signal clkout_en1 : std_ulogic := '0';
  signal locked_out : std_ulogic := '0';
  signal period_avg : time := 0 ps;
  signal delay_edge : time := 0 ps;
  signal clkin_period_tmp_t : integer := 0;
  signal period_vco : time := 0 ps;
  signal clk0ps_en : std_ulogic := '0';
  signal clk1ps_en : std_ulogic := '0';
  signal clk2ps_en : std_ulogic := '0';
  signal clk3ps_en : std_ulogic := '0';
  signal clk4ps_en : std_ulogic := '0';
  signal clk5ps_en : std_ulogic := '0';
  signal clkfbm1ps_en : std_ulogic := '0';
  signal clk0_cnt : integer := 0;
  signal clk1_cnt : integer := 0;
  signal clk2_cnt : integer := 0;
  signal clk3_cnt : integer := 0;
  signal clk4_cnt : integer := 0;
  signal clk5_cnt : integer := 0;
  signal clkfb_cnt : integer := 0;
  signal clkfb_tst : std_ulogic := '0';
  signal clkfb_in : std_ulogic := '0';
  signal clkin1_in : std_ulogic := '0';
  signal clkin1_in_dly : std_ulogic := '0';
  signal clkin2_in : std_ulogic := '0';
  signal clkinsel_in : std_ulogic := '0';
  signal clkinsel_tmp : std_ulogic := '0';
  signal rst_input_r : std_ulogic := '0';
  signal pwrdwn_in : std_ulogic := '0';
  signal IS_CLKINSEL_INVERTED_BIN : std_ulogic := TO_X01(IS_CLKINSEL_INVERTED);
  signal IS_PWRDWN_INVERTED_BIN : std_ulogic := TO_X01(IS_PWRDWN_INVERTED);
  signal IS_RST_INVERTED_BIN : std_ulogic := TO_X01(IS_RST_INVERTED);

  begin 
  
   clkin1_in <= CLKIN1;
   clkin2_in <= CLKIN2;
   clkfb_in <= CLKFBIN;
   clkinsel_in <= '1' when (CLKINSEL xor IS_CLKINSEL_INVERTED_BIN) /= '0' else '0';
   rst_input_r <= RST xor IS_RST_INVERTED_BIN;
   pwrdwn_in <= PWRDWN xor IS_PWRDWN_INVERTED_BIN;
   LOCKED <= locked_out_tmp;
   CLKOUT0 <=  clkout0_out;
   CLKOUT1 <=  clkout1_out;
   CLKOUT2 <=  clkout2_out;
   CLKOUT3 <=   clkout3_out;
   CLKOUT4 <=   clkout4_out;
   CLKOUT5 <=   clkout5_out;
   CLKFBOUT <=   clkfb_out;
   DO <= "0000000000000000";

   INIPROC : process
            variable Message : line;
            variable con_line : line;
            variable tmpvalue : real;
            variable chk_ok : std_ulogic;
            variable tmp_string : string(1 to 18);
            variable skipspace : character;
            variable CLK_DUTY_CYCLE_MIN : real;
            variable CLK_DUTY_CYCLE_MAX : real;
            variable  CLK_DUTY_CYCLE_STEP : real;
            variable O_MAX_HT_LT_real : real;
            variable duty_cycle_valid : std_ulogic;
            variable CLKOUT0_DIVIDE_real : real;
            variable CLKOUT1_DIVIDE_real : real;
            variable CLKOUT2_DIVIDE_real : real;
            variable CLKOUT3_DIVIDE_real : real;
            variable CLKOUT4_DIVIDE_real : real;
            variable CLKOUT5_DIVIDE_real : real;
            variable tmp_j : real;
            variable tmp_duty_value : real;
            variable clk_nocnt_i : std_ulogic;
            variable clk_edge_i : std_ulogic;
            variable clkfbm1_f_div_v : real := 1.0;
            variable clkfb_div_fint_v : integer := 1;
            variable clkfb_div_fint_v_tmp : integer := 1;
            variable clkfb_div_fint_v1 : real := 1.0;
            variable clkout_en_time_i : integer;
            variable clkout_en_time_i1 : integer := 0;
            variable clk0_val1_tmp : integer := 0;
            variable clk1_val1_tmp : integer := 0;
            variable clk2_val1_tmp : integer := 0;
            variable clk3_val1_tmp : integer := 0;
            variable clk4_val1_tmp : integer := 0;
            variable clk5_val1_tmp : integer := 0;
        begin
           if((COMPENSATION /= "ZHOLD") and (COMPENSATION /= "zhold") and
                 (COMPENSATION /= "BUF_IN") and (COMPENSATION /= "buf_in") and
                 (COMPENSATION /= "EXTERNAL") and (COMPENSATION /= "external") and
                 (COMPENSATION /= "INTERNAL") and (COMPENSATION /= "internal"))
then
             assert FALSE report " Attribute Syntax Error : The Attribute COMPENSATION must be set to ZHOLD or BUF_IN or  EXTERNAL or INTERNAL." severity error;            end if;

           if((BANDWIDTH /= "HIGH") and (BANDWIDTH /= "high") and
                 (BANDWIDTH /= "LOW") and (BANDWIDTH /= "low") and
                 (BANDWIDTH /= "OPTIMIZED") and (BANDWIDTH /= "optimized")) then             assert FALSE report "Attribute Syntax Error : BANDWIDTH  is not HIGH, LOW, OPTIMIZED." severity error;
            end if;

      if((STARTUP_WAIT /= "FALSE") and (STARTUP_WAIT /= "false") and
          (STARTUP_WAIT /= "TRUE") and  (STARTUP_WAIT /= "true")) then
        assert FALSE report "Error : STARTUP_WAIT must be set to string FALSE or TRUE." severity error;
      end if;

       clkfb_div_fint_v := CLKFBOUT_MULT;
       clkfb_div_fint <= clkfb_div_fint_v;
       clkfb_val <= DIVCLK_DIVIDE * 8;
       clkfb_val2 <= DIVCLK_DIVIDE * 8 * 2 - 1;
       clkfb_val1 <= 8;
       clkfb_val11 <= 7;

      clk0_val <= DIVCLK_DIVIDE * CLKOUT0_DIVIDE;
      clk0_val2 <= DIVCLK_DIVIDE * CLKOUT0_DIVIDE * 2 - 1;
      clk0_val1_tmp := clkfb_div_fint_v;
      clk0_val1 <= clkfb_div_fint_v;
      if ( clk0_val1_tmp > 1) then
        clk0_val11 <= clk0_val1_tmp - 1;
      end if;
      clk1_val <= DIVCLK_DIVIDE * CLKOUT1_DIVIDE;
      clk1_val2 <= DIVCLK_DIVIDE * CLKOUT1_DIVIDE * 2 - 1;
      clk1_val1_tmp := clkfb_div_fint_v;
      clk1_val1 <= clk1_val1_tmp;
      if ( clk1_val1_tmp > 1) then
        clk1_val11 <= clk1_val1_tmp - 1;
      end if;
      clk2_val <= DIVCLK_DIVIDE * CLKOUT2_DIVIDE;
      clk2_val2 <= DIVCLK_DIVIDE * CLKOUT2_DIVIDE * 2 - 1;
      clk2_val1_tmp := clkfb_div_fint_v;
      clk2_val1 <= clk2_val1_tmp;
      if ( clk2_val1_tmp > 1) then
        clk2_val11 <= clk2_val1_tmp - 1;
      end if;
      clk3_val <= DIVCLK_DIVIDE * CLKOUT3_DIVIDE;
      clk3_val2 <= DIVCLK_DIVIDE * CLKOUT3_DIVIDE * 2 - 1;
      clk3_val1_tmp := clkfb_div_fint_v;
      clk3_val1 <= clk3_val1_tmp;
      if ( clk3_val1_tmp > 1) then
        clk3_val11 <= clk3_val1_tmp - 1;
      end if;
      clk4_val <= DIVCLK_DIVIDE * CLKOUT4_DIVIDE;
      clk4_val2 <= DIVCLK_DIVIDE * CLKOUT4_DIVIDE * 2 - 1;
      clk4_val1_tmp := clkfb_div_fint_v;
      clk4_val1 <= clk4_val1_tmp;
      if ( clk4_val1_tmp > 1) then
        clk4_val11 <= clk4_val1_tmp - 1;
      end if;
      clk5_val <= DIVCLK_DIVIDE * CLKOUT5_DIVIDE;
      clk5_val2 <= DIVCLK_DIVIDE * CLKOUT5_DIVIDE * 2 - 1;
      clk5_val1_tmp := clkfb_div_fint_v;
      clk5_val1 <= clk5_val1_tmp;
      if ( clk5_val1_tmp > 1) then
        clk5_val11 <= clk5_val1_tmp - 1;
      end if;
      if (CLKOUT0_DIVIDE < 0 or CLKOUT0_DIVIDE > 128) then
          assert FALSE report "Attribute Syntax Error : CLKOUT0_DIVIDE is not in range 1.000 to 128.000." severity error;
       end if;

        if ((CLKOUT0_PHASE < -360.0) or (CLKOUT0_PHASE > 360.0)) then
            assert FALSE report "Attribute Syntax Error : CLKOUT0_PHASE is not in range -360.0 to 360.0" severity error;
        end if;

        if ((CLKOUT0_DUTY_CYCLE < 0.001) or (CLKOUT0_DUTY_CYCLE > 0.999)) then
           assert FALSE report "Attribute Syntax Error : CLKOUT0_DUTY_CYCLE is not real in range 0.001 to 0.999 pecentage."severity error;
        end if;

        case CLKOUT1_DIVIDE is
           when   1 to 128 => NULL ;
           when others  =>  assert FALSE report "Attribute Syntax Error : CLKOUT1_DIVIDE is not in range 1 to 128." severity error;
        end case;

         if ((CLKOUT1_PHASE < -360.0) or (CLKOUT1_PHASE > 360.0)) then
            assert FALSE report "Attribute Syntax Error : CLKOUT1_PHASE is not in range -360.0 to 360.0" severity error;
         end if;

         if ((CLKOUT1_DUTY_CYCLE < 0.001) or (CLKOUT1_DUTY_CYCLE > 0.999)) then
             assert FALSE report "Attribute Syntax Error : CLKOUT1_DUTY_CYCLE is not real in range 0.001 to 0.999 pecentage."severity error;
         end if;

         case CLKOUT2_DIVIDE is
           when   1 to 128 => NULL ;
           when others  =>  assert FALSE report "Attribute Syntax Error : CLKOUT2_DIVIDE is not in range 1 to 128." severity error;
         end case;

         if ((CLKOUT2_PHASE < -360.0) or (CLKOUT2_PHASE > 360.0)) then
            assert FALSE report "Attribute Syntax Error : CLKOUT2_PHASE is not in range -360.0 to 360.0" severity error;
         end if;
         if ((CLKOUT2_DUTY_CYCLE < 0.001) or (CLKOUT2_DUTY_CYCLE > 0.999)) then
             assert FALSE report "Attribute Syntax Error : CLKOUT2_DUTY_CYCLE is not real in range 0.001 to 0.999 pecentage."severity error;
         end if;

         case CLKOUT3_DIVIDE is
           when   1 to 128 => NULL ;
           when others  =>  assert FALSE report "Attribute Syntax Error : CLKOUT3_DIVIDE is not in range 1...128." severity error;
         end case;

         if ((CLKOUT3_PHASE < -360.0) or (CLKOUT3_PHASE > 360.0)) then
            assert FALSE report "Attribute Syntax Error : CLKOUT3_PHASE is not in range -360.0 to 360.0" severity error;
         end if;

         if ((CLKOUT3_DUTY_CYCLE < 0.001) or (CLKOUT3_DUTY_CYCLE > 0.999)) then
             assert FALSE report "Attribute Syntax Error : CLKOUT3_DUTY_CYCLE is not real in range 0.001 to 0.999 pecentage."severity error;
         end if;

         case CLKOUT4_DIVIDE is
           when   1 to 128 => NULL ;
           when others  =>  assert FALSE report "Attribute Syntax Error : CLKOUT4_DIVIDE is not in range 1 to 128." severity error;
         end case;

         if ((CLKOUT4_PHASE < -360.0) or (CLKOUT4_PHASE > 360.0)) then
            assert FALSE report "Attribute Syntax Error : CLKOUT4_PHASE is not in range -360.0 to 360.0" severity error;
         end if;

         if ((CLKOUT4_DUTY_CYCLE < 0.001) or (CLKOUT4_DUTY_CYCLE > 0.999)) then
             assert FALSE report "Attribute Syntax Error : CLKOUT4_DUTY_CYCLE is not real in range 0.001 to 0.999 pecentage."severity error;
         end if;

           case CLKOUT5_DIVIDE is
             when   1 to 128 => NULL ;
             when others  =>  assert FALSE report "Attribute Syntax Error : CLKOUT5_DIVIDE is not in range 1...128." severity error;
           end case;
           if ((CLKOUT5_PHASE < -360.0) or (CLKOUT5_PHASE > 360.0)) then
             assert FALSE report "Attribute Syntax Error : CLKOUT5_PHASE is not in range 360.0 to 360.0" severity error;
           end if;
           if ((CLKOUT5_DUTY_CYCLE < 0.001) or (CLKOUT5_DUTY_CYCLE > 0.999)) then
             assert FALSE report "Attribute Syntax Error : CLKOUT5_DUTY_CYCLE is not real in range 0.001 to 0.999 pecentage."severity error;
           end if;

         if (CLKFBOUT_MULT < 2 or CLKFBOUT_MULT > 64) then
          assert FALSE report "Attribute Syntax Error : CLKFBOUT_MULT is not in range 2 to 64." severity error;
         end if;

       if ( CLKFBOUT_PHASE < -360.0 or CLKFBOUT_PHASE > 360.0 ) then
             assert FALSE report "Attribute Syntax Error : CLKFBOUT_PHASE is not in range -360.0 to 360.0" severity error;
       end if;

       case DIVCLK_DIVIDE is
         when    1  to 56 => NULL;
         when others  =>  assert FALSE report "Attribute Syntax Error : DIVCLK_DIVIDE is not in range 1 to 56." severity error;
       end case;

       if ((REF_JITTER1 < 0.0) or (REF_JITTER1 > 0.999)) then
         assert FALSE report "Attribute Syntax Error : REF_JITTER1 is not in range 0.0 ... 1.0." severity error;
       end if;

       if ((REF_JITTER2 < 0.0) or (REF_JITTER2 > 0.999)) then
         assert FALSE report "Attribute Syntax Error : REF_JITTER2 is not in range 0.0 ... 1.0." severity error;
       end if;

       O_MAX_HT_LT_real := real(O_MAX_HT_LT);
       CLKOUT0_DIVIDE_real := real(CLKOUT0_DIVIDE);
       CLKOUT1_DIVIDE_real := real(CLKOUT1_DIVIDE);
       CLKOUT2_DIVIDE_real := real(CLKOUT2_DIVIDE);
       CLKOUT3_DIVIDE_real := real(CLKOUT3_DIVIDE);
       CLKOUT4_DIVIDE_real := real(CLKOUT4_DIVIDE);
       CLKOUT5_DIVIDE_real := real(CLKOUT5_DIVIDE);

       if (CLKOUT0_DIVIDE /= 0) then
         chk_ok := clkout_duty_chk (CLKOUT0_DIVIDE, CLKOUT0_DUTY_CYCLE, "CLKOUT0_DUTY_CYCLE");
       end if;
       if (CLKOUT5_DIVIDE /= 0) then
         chk_ok := clkout_duty_chk (CLKOUT5_DIVIDE, CLKOUT5_DUTY_CYCLE, "CLKOUT5_DUTY_CYCLE");
       end if;
       if (CLKOUT1_DIVIDE /= 0) then
       chk_ok := clkout_duty_chk (CLKOUT1_DIVIDE, CLKOUT1_DUTY_CYCLE, "CLKOUT1_DUTY_CYCLE");
       end if;
       if (CLKOUT2_DIVIDE /= 0) then
       chk_ok := clkout_duty_chk (CLKOUT2_DIVIDE, CLKOUT2_DUTY_CYCLE, "CLKOUT2_DUTY_CYCLE");
       end if;
       if (CLKOUT3_DIVIDE /= 0) then
       chk_ok := clkout_duty_chk (CLKOUT3_DIVIDE, CLKOUT3_DUTY_CYCLE, "CLKOUT3_DUTY_CYCLE");
       end if;
       if (CLKOUT4_DIVIDE /= 0) then
       chk_ok := clkout_duty_chk (CLKOUT4_DIVIDE, CLKOUT4_DUTY_CYCLE, "CLKOUT4_DUTY_CYCLE");
       end if;
       pll_lock_time <= 12;
       lock_period_time <= 16;
       clkout_en_time_i1 := 10 + 12;
       clkout_en_time <= clkout_en_time_i1;
       locked_en_time <= clkout_en_time_i1 + 20;
       lock_cnt_max <=   clkout_en_time_i1 + 20 + 16;
       init_done <= '1';
       wait;
    end process INIPROC;
 
    clkinsel_p : process
          variable period_clkin : real;
          variable clkvco_freq_init_chk : real := 0.0;
          variable Message : line;
          variable tmpreal1 : real;
          variable tmpreal2 : real;
          variable first_check : boolean := true;
          variable clkin_chk_t1 : real;
          variable clkin_chk_t1_tmp1 : real;
          variable clkin_chk_t1_tmp2 : real;
          variable clkin_chk_t1_tmpi : time;
          variable clkin_chk_t1_tmpi1 : integer;
          variable clkin_chk_t2 : real;
          variable clkin_chk_t2_tmp1 : real;
          variable clkin_chk_t2_tmp2 : real;
          variable clkin_chk_t2_tmpi : time;
          variable clkin_chk_t2_tmpi1 : integer;
    begin

      if (first_check = true or rising_edge(clkinsel_in) or falling_edge(clkinsel_in)) then

      if (NOW > 1 ps  and  rst_in = '0' and (clkinsel_tmp = '0' or clkinsel_tmp
= '1')) then
          assert false report
            "Input Error : PLLE2_ADV input clock can only be switched when RST=1.  CLKINSEL is changed when RST low, which should be changed at RST high."
          severity error;
      end if;
        if (NOW = 0 ps) then
           wait for 1 ps;
        end if;

           clkin_chk_t1_tmp1 := 1000.0 / CLKIN_FREQ_MIN;
           clkin_chk_t1_tmp2 := 1000.0 * clkin_chk_t1_tmp1;
           clkin_chk_t1_tmpi := clkin_chk_t1_tmp2 * 1 ps;
           clkin_chk_t1_tmpi1 := clkin_chk_t1_tmpi / 1 ps;
           clkin_chk_t1 := real(clkin_chk_t1_tmpi1) / 1000.0;

           clkin_chk_t2_tmp1 := 1000.0 / CLKIN_FREQ_MAX;
           clkin_chk_t2_tmp2 := 1000.0 * clkin_chk_t2_tmp1;
           clkin_chk_t2_tmpi := clkin_chk_t2_tmp2 * 1 ps;
           clkin_chk_t2_tmpi1 := clkin_chk_t2_tmpi / 1 ps;
           clkin_chk_t2 := real(clkin_chk_t2_tmpi1) / 1000.0;

          if (((CLKIN1_PERIOD < clkin_chk_t2) or (CLKIN1_PERIOD > clkin_chk_t1)) and  (CLKINSEL /= '0')) then
        Write ( Message, string'(" Attribute Syntax Error : The attribute CLKIN1_PERIOD is set to "));
        Write ( Message, CLKIN1_PERIOD);
        Write ( Message, string'(" ns and out the allowed range "));
        Write ( Message, clkin_chk_t2);
        Write ( Message, string'(" ns to "));
        Write ( Message, clkin_chk_t1);
        Write ( Message, string'(" ns" ));
        Write ( Message, '.' & LF );
        assert false report Message.all severity error;
        DEALLOCATE (Message);
          end if;

          if (((CLKIN2_PERIOD < clkin_chk_t2) or (CLKIN2_PERIOD > clkin_chk_t1)) and  (CLKINSEL = '0')) then
        Write ( Message, string'(" Attribute Syntax Error : The attribute CLKIN2_PERIOD is set to "));
        Write ( Message, CLKIN2_PERIOD);
        Write ( Message, string'(" ns and out the allowed range "));
        Write ( Message, clkin_chk_t2);
        Write ( Message, string'(" ns to "));
        Write ( Message, clkin_chk_t1);
        Write ( Message, string'(" ns"));
        Write ( Message, '.' & LF );
        assert false report Message.all severity error;
        DEALLOCATE (Message);
          end if;

        if ( clkinsel_in /= '0') then
           period_clkin :=  CLKIN1_PERIOD;
        else
           period_clkin := CLKIN2_PERIOD;
        end if;

        tmpreal1 := real(CLKFBOUT_MULT);
        tmpreal2 := real(DIVCLK_DIVIDE);
        if (period_clkin > 0.000) then
          clkvco_freq_init_chk :=  (1000.0 * tmpreal1) / ( period_clkin * tmpreal2);

          if ((clkvco_freq_init_chk > VCOCLK_FREQ_MAX) or (clkvco_freq_init_chk
< VCOCLK_FREQ_MIN)) then
           Write ( Message, string'(" Attribute Syntax Error : The calculation of VCO frequency="));
           Write ( Message, clkvco_freq_init_chk);
           Write ( Message, string'(" Mhz. This exceeds the permitted VCO frequency range of "));
           Write ( Message, VCOCLK_FREQ_MIN);
           Write ( Message, string'(" MHz to "));
           Write ( Message, VCOCLK_FREQ_MAX);
           if (clkinsel_in /= '0') then
             Write ( Message, string'(" MHz. The VCO frequency is calculated with formula: VCO frequency =  CLKFBOUT_MULT / (DIVCLK_DIVIDE * CLKIN1_PERIOD)."));           else
             Write ( Message, string'(" MHz. The VCO frequency is calculated with formula: VCO frequency =  CLKFBOUT_MULT / (DIVCLK_DIVIDE * CLKIN2_PERIOD)."));           end if;
           Write ( Message, string'(" Please adjust the attributes to the permitted VCO frequency range."));
           assert false report Message.all severity error;
              DEALLOCATE (Message);
          end if;
        end if;
        first_check := false;
    end if;
      wait on clkinsel_in, clkpll_r;
    end process;

    clkpll_r <= clkin1_in when clkinsel_in = '1' else clkin2_in;
    pwrdwn_in1 <= '1' when (pwrdwn_in = '1'  or pwron_int = '1') else '0';
    rst_input <= '1' when (rst_input_r = '1' or pwrdwn_in1 = '1') else '0';


    RST_SYNC_P : process (clkpll_r, rst_input)
    begin
      if (rst_input = '1') then
        rst_in <= '1';
      elsif (rising_edge (clkpll_r)) then
        rst_in <= rst_input;
      end if;
    end process;

    pwron_int_p : process
    begin
      pwron_int <= '1';
      wait for 100 ns;
      pwron_int <= '0';
      wait;
    end process;

    CLOCK_PERIOD_P : process (clkpll_r, rst_in)
      variable  clkin_edge_previous : time := 0 ps;
      variable  clkin_edge_current : time := 0 ps;
    begin
      if (rst_in = '1' ) then
        clkin_period(0) <= period_vco_target;
        clkin_period(1) <= period_vco_target;
        clkin_period(2) <= period_vco_target;
        clkin_period(3) <= period_vco_target;
        clkin_period(4) <= period_vco_target;
        clkin_lock_cnt <= 0;
        pll_locked_tm <= '0';
        lock_period <= '0';
        pll_locked_tmp1 <= '0';
        clkout_en0_tmp <= '0';
        clkin_edge_previous := 0 ps;
        sample_en <=  '1';
      elsif (rising_edge(clkpll_r)) then
       if (sample_en = '1') then
        clkin_edge_current := NOW;
        if (clkin_edge_previous /= 0 ps ) then
          clkin_period(4) <= clkin_period(3);
          clkin_period(3) <= clkin_period(2);
          clkin_period(2) <= clkin_period(1);
          clkin_period(1) <= clkin_period(0);
          clkin_period(0) <= clkin_edge_current - clkin_edge_previous;
        end if;

        clkin_edge_previous := clkin_edge_current;

        if (  (clkin_lock_cnt < lock_cnt_max) and fb_delay_found = '1' ) then
            clkin_lock_cnt <= clkin_lock_cnt + 1;
        end if;
        if ( clkin_lock_cnt >= pll_lock_time) then
            pll_locked_tm <= '1';
        end if;
        if ( clkin_lock_cnt = lock_period_time ) then
            lock_period <= '1';
        end if;

        if (clkin_lock_cnt >= clkout_en_time and pll_locked_tm = '1') then
            clkout_en0_tmp <= '1';
        end if;
 
        if (clkin_lock_cnt >= locked_en_time and  clkout_en = '1') then
           pll_locked_tmp1 <= '1';
        end if;

        if (pll_locked_tmp2 = '1' and  pll_locked_tmp1 = '1') then
           sample_en <= '0';
        end if;
      end if;
    end if;
    end process;

   locked_out <= '1' when (pll_locked_tmp1 = '1' and pll_locked_tmp2 = '1') else '0';
   pll_locked_tmp2 <= (clk0ps_en  and  clk1ps_en  and  clk2ps_en  and  clk3ps_en
                  and  clk4ps_en  and  clk5ps_en and  clkfbm1ps_en);

  pchk_p : process(pll_locked_tmp1)
    variable pchk_tmp1 : time;
    variable pchk_tmp2 : time;
  begin
  if (rising_edge(pll_locked_tmp1)) then
    if (clkinsel_in = '0') then
       pchk_tmp1 := CLKIN2_PERIOD * 1100 ps;
       pchk_tmp2 := CLKIN2_PERIOD * 900 ps;
       if (period_avg > pchk_tmp1 or  period_avg < pchk_tmp2) then
         assert false report "Error : input CLKIN2 period and attribute CLKIN2_PERIOD are not same." severity error ;
       end if;
    else
       pchk_tmp1 := CLKIN1_PERIOD * 1100 ps;
       pchk_tmp2 := CLKIN1_PERIOD * 900 ps;
       if (period_avg > pchk_tmp1 or  period_avg < pchk_tmp2) then
         assert false report "Error : input CLKIN1 period and attribute CLKIN1_PERIOD are not same." severity error ;
       end if;
    end if;
  end if;
  end process;

   locked_out_tmp_p : process
    begin
      if (rising_edge(rst_in)) then
           wait for 1 ns;   
           locked_out_tmp <= '0';
      else
         if (rst_in = '0') then
           locked_out_tmp <= locked_out;
         else
           locked_out_tmp <= '0';
         end if;
      end if;
      wait on rst_in, locked_out;
    end process;


    clkout_en1_p : process (clkout_en0_tmp , rst_in) 
    begin
       if (rst_in  =  '1') then
         clkout_en1  <= '0';
       else
         clkout_en1 <= transport clkout_en0_tmp after clkvco_delay;
       end if;
    end process;

    clkout_en_p : process (clkout_en1, rst_in)
    begin
      if (rst_in = '1') then
        clkout_en <= '0';
      else
          clkout_en <= clkout_en1;
      end if;
    end process;

    CLK_PERIOD_AVG_P : process (clkin_period(0), clkin_period(1), clkin_period(2),
                                 clkin_period(3), clkin_period(4), period_avg)
      variable period_avg_tmp : time := 0 ps;
      variable clkin_period_tmp0 : time := 0 ps;
      variable clkin_period_tmp1 : time := 0 ps;
      variable clkin_period_tmp_t : time := 0 ps;
    begin
      clkin_period_tmp0 := clkin_period(0);
      clkin_period_tmp1 := clkin_period(1);
      if (clkin_period_tmp0 > clkin_period_tmp1) then
          clkin_period_tmp_t := clkin_period_tmp0 - clkin_period_tmp1;
      else
          clkin_period_tmp_t := clkin_period_tmp1 - clkin_period_tmp0;
      end if;

      if (clkin_period_tmp0 /= period_avg and (clkin_period_tmp0 < 1.5 * period_avg or clkin_period_tmp_t <= 300 ps)) then
         period_avg_tmp := (clkin_period(0) + clkin_period(1) + clkin_period(2)
                       + clkin_period(3) + clkin_period(4))/5.0;
         period_avg <= period_avg_tmp;
      end if;
    end process;

  process (period_avg, lock_period, rst_in) 
     variable p_c0 : time;
     variable p_c0i : integer;
     variable p_c0_dr : integer;
     variable p_c0_dri : time;
     variable p_c0_dri1 : integer;
     variable p_c0_dri2 : integer;
     variable p_c1 : time;
     variable p_c1i : integer;
     variable p_c1_dr : integer;
     variable p_c1_dri : time;
     variable p_c1_dri1 : integer;
     variable p_c1_dri2 : integer;
     variable p_c2 : time;
     variable p_c2i : integer;
     variable p_c2_dr : integer;
     variable p_c2_dri : time;
     variable p_c2_dri1 : integer;
     variable p_c2_dri2 : integer;
     variable p_c3 : time;
     variable p_c3i : integer;
     variable p_c3_dr : integer;
     variable p_c3_dri : time;
     variable p_c3_dri1 : integer;
     variable p_c3_dri2 : integer;
     variable p_c4 : time;
     variable p_c4i : integer;
     variable p_c4_dr : integer;
     variable p_c4_dri : time;
     variable p_c4_dri1 : integer;
     variable p_c4_dri2 : integer;
     variable p_c5 : time;
     variable p_c5i : integer;
     variable p_c5_dr : integer;
     variable p_c5_dri : time;
     variable p_c5_dri1 : integer;
     variable p_c5_dri2 : integer;
     variable period_fbi : integer;
     variable period_fb_tmp : time;
     variable fb_delayi : integer;
     variable clkvco_delay_tmp : time;
     variable clkvco_delayi : integer;
     variable fb_delaym : integer;
     variable dly_tmp : time;
     variable dly_tmpi : integer;
     variable clkfbm1_dly_tmp : time;
     variable period_vco_tmp : time;
  begin
  if (rst_in  =  '1') then
    p_fb <= 0 ps;
    p_fb_h <= 0 ps;
    p_fb_r <= 0 ps;
    p_fb_r1 <= 0 ps;
    p_fb_d <= 0 ps;
    p_c0 := 0 ps;
    p_c0_h <= 0 ps;
    p_c0_r <= 0 ps;
    p_c0_r1 <= 0 ps;
    p_c0_d <= 0 ps;
    p_c1 := 0 ps;
    p_c1_h <= 0 ps;
    p_c1_r <= 0 ps;
    p_c1_r1 <= 0 ps;
    p_c1_d <= 0 ps;
    p_c2 := 0 ps;
    p_c2_h <= 0 ps;
    p_c2_r <= 0 ps;
    p_c2_r1 <= 0 ps;
    p_c2_d <= 0 ps;
    p_c3 := 0 ps;
    p_c3_h <= 0 ps;
    p_c3_r <= 0 ps;
    p_c3_r1 <= 0 ps;
    p_c3_d <= 0 ps;
    p_c4 := 0 ps;
    p_c4_h <= 0 ps;
    p_c4_r <= 0 ps;
    p_c4_r1 <= 0 ps;
    p_c4_d <= 0 ps;
    p_c5 := 0 ps;
    p_c5_h <= 0 ps;
    p_c5_r <= 0 ps;
    p_c5_r1 <= 0 ps;
    p_c5_d <= 0 ps;
    clkvco_delay <= 0 ps;
    dly_tmp := 0 ps;
    period_fb <= 0 ps;
    period_vco <= 0 ps;
    clkfbm1_dly <= 0 ps;
    p_c0_dr := 0;
    p_c1_dr := 0 ;
    p_c2_dr := 0;
    p_c3_dr := 0;
    p_c4_dr := 0;
    p_c5_dr := 0;
  else
   if (period_avg > 0  ps  and  lock_period  =  '1') then
    fb_delayi := fb_delay / 1 ps;
    period_fb_tmp := period_avg * DIVCLK_DIVIDE;
    period_fbi := period_fb_tmp / 1 ps;
    period_fb <= period_fb_tmp;
    period_vco_tmp := period_fb_tmp / CLKFBOUT_MULT;
    period_vco <= period_vco_tmp;
    clkfbm1_dly_tmp := ((CLKFBOUT_PHASE * period_fb_tmp) / 360.0);
    clkfbm1_dly <= clkfbm1_dly_tmp;
    dly_tmp := fb_delay + clkfbm1_dly_tmp;
    dly_tmpi := dly_tmp / 1 ps; 
    if (dly_tmp  =  0 ps) then
          clkvco_delay_tmp := 0 ps;
    elsif ( dly_tmp <= period_fb_tmp ) then
          clkvco_delay_tmp := period_fb_tmp - dly_tmp;
    else
          clkvco_delay_tmp := period_fb_tmp - ((dly_tmpi mod( period_fbi)) * 1 ps) ;
    end if;
    clkvco_delay <= clkvco_delay_tmp;
    clkvco_delayi := clkvco_delay_tmp / 1 ps;
    p_fb <= period_fb_tmp;
    p_fb_h <= period_fb_tmp / 2;
    p_fb_r <= period_fb_tmp - period_fb_tmp / 2;
    p_fb_r1 <= period_fb_tmp - period_fb_tmp / 2 - 1 ps;
    fb_delaym := fb_delayi mod (period_fbi); 
    if ( fb_delay <= period_fb_tmp) then
          p_fb_d <= period_fb_tmp - fb_delay;
    else
          p_fb_d <= period_fb_tmp - fb_delaym * 1 ps;
    end if;
    p_c0 := (period_fb_tmp * CLKOUT0_DIVIDE) / CLKFBOUT_MULT;
    p_c0i := p_c0 / 1 ps;
    p_c0_h <= p_c0  * CLKOUT0_DUTY_CYCLE;
    p_c0_r <=  p_c0 - p_c0  * CLKOUT0_DUTY_CYCLE;
    p_c0_r1 <=  p_c0 - p_c0  * CLKOUT0_DUTY_CYCLE - 1 ps;
    p_c0_dri := ((CLKOUT0_PHASE * p_c0) / 360.0);
    p_c0_dri1 := (p_c0_dri / 1 ps);
    p_c0_dri2 := (clkvco_delayi mod p_c0i);
    p_c0_dr := p_c0_dri1 + p_c0_dri2;
    if (p_c0_dr < 0 ) then
      p_c0_d <= p_c0 + (p_c0_dr mod p_c0i) * 1 ps;
    else
      p_c0_d <= (p_c0_dr mod p_c0i ) * 1 ps;
    end if;


    p_c1 := (period_fb_tmp * CLKOUT1_DIVIDE) / CLKFBOUT_MULT;
    p_c1i := p_c1 / 1 ps;
    p_c1_h <= p_c1  * CLKOUT1_DUTY_CYCLE;
    p_c1_r <=  p_c1 - p_c1  * CLKOUT1_DUTY_CYCLE;
    p_c1_r1 <=  p_c1 - p_c1  * CLKOUT1_DUTY_CYCLE - 1 ps;
    p_c1_dri := ((CLKOUT1_PHASE * p_c1) / 360.0);
    p_c1_dri1 := (p_c1_dri / 1 ps);
    p_c1_dri2 := (clkvco_delayi mod p_c1i);
    p_c1_dr := p_c1_dri1 + p_c1_dri2;
    if (p_c1_dr < 0 ) then
      p_c1_d <= p_c1 + (p_c1_dr mod p_c1i) * 1 ps;
    else
      p_c1_d <= (p_c1_dr mod p_c1i ) * 1 ps;
    end if;

    p_c2 := (period_fb_tmp * CLKOUT2_DIVIDE) / CLKFBOUT_MULT;
    p_c2i := p_c2 / 1 ps;
    p_c2_h <= p_c2  * CLKOUT2_DUTY_CYCLE;
    p_c2_r <=  p_c2 - p_c2  * CLKOUT2_DUTY_CYCLE;
    p_c2_r1 <=  p_c2 - p_c2  * CLKOUT2_DUTY_CYCLE - 1 ps;
    p_c2_dri := ((CLKOUT2_PHASE * p_c2) / 360.0);
    p_c2_dri1 := (p_c2_dri / 1 ps);
    p_c2_dri2 := (clkvco_delayi mod p_c2i);
    p_c2_dr := p_c2_dri1 + p_c2_dri2;
    if (p_c2_dr < 0 ) then
      p_c2_d <= p_c2 + (p_c2_dr mod p_c2i) * 1 ps;
    else
      p_c2_d <= (p_c2_dr mod p_c2i ) * 1 ps;
    end if;

    p_c3 := (period_fb_tmp * CLKOUT3_DIVIDE) / CLKFBOUT_MULT;
    p_c3i := p_c3 / 1 ps;
    p_c3_h <= p_c3  * CLKOUT3_DUTY_CYCLE;
    p_c3_r <=  p_c3 - p_c3  * CLKOUT3_DUTY_CYCLE;
    p_c3_r1 <=  p_c3 - p_c3  * CLKOUT3_DUTY_CYCLE - 1 ps;
    p_c3_dri := ((CLKOUT3_PHASE * p_c3) / 360.0);
    p_c3_dri1 := (p_c3_dri / 1 ps);
    p_c3_dri2 := (clkvco_delayi mod p_c3i);
    p_c3_dr := p_c3_dri1 + p_c3_dri2;
    if (p_c3_dr < 0 ) then
      p_c3_d <= p_c3 + (p_c3_dr mod p_c3i) * 1 ps;
    else
      p_c3_d <= (p_c3_dr mod p_c3i ) * 1 ps;
    end if;

    p_c4 := (period_fb_tmp * CLKOUT4_DIVIDE) / CLKFBOUT_MULT;
    p_c4i := p_c4 / 1 ps;
    p_c4_h <= p_c4  * CLKOUT4_DUTY_CYCLE;
    p_c4_r <=  p_c4 - p_c4  * CLKOUT4_DUTY_CYCLE;
    p_c4_r1 <=  p_c4 - p_c4  * CLKOUT4_DUTY_CYCLE - 1 ps;
    p_c4_dri := ((CLKOUT4_PHASE * p_c4) / 360.0);
    p_c4_dri1 := (p_c4_dri / 1 ps);
    p_c4_dri2 := (clkvco_delayi mod p_c4i);
    p_c4_dr := p_c4_dri1 + p_c4_dri2;
    if (p_c4_dr < 0 ) then
      p_c4_d <= p_c4 + (p_c4_dr mod p_c4i) * 1 ps;
    else
      p_c4_d <= (p_c4_dr mod p_c4i ) * 1 ps;
    end if;

    p_c5 := (period_fb_tmp * CLKOUT5_DIVIDE) / CLKFBOUT_MULT;
    p_c5i := p_c5 / 1 ps;
    p_c5_h <= p_c5  * CLKOUT5_DUTY_CYCLE;
    p_c5_r <=  p_c5 - p_c5  * CLKOUT5_DUTY_CYCLE;
    p_c5_r1 <=  p_c5 - p_c5  * CLKOUT5_DUTY_CYCLE - 1 ps;
    p_c5_dri := ((CLKOUT5_PHASE * p_c5) / 360.0);
    p_c5_dri1 := (p_c5_dri / 1 ps);
    p_c5_dri2 := (clkvco_delayi mod p_c5i);
    p_c5_dr := p_c5_dri1 + p_c5_dri2;
    if (p_c5_dr < 0 ) then
      p_c5_d <= p_c5 + (p_c5_dr mod p_c5i) * 1 ps;
    else
      p_c5_d <= (p_c5_dr mod p_c5i ) * 1 ps;
    end if;

   end if;
  end if;
  end process;

    process (clkout_en,  rst_in) begin
    if (rst_in  =  '1') then
      clk0ps_en <= '0';
      clk1ps_en <= '0';
      clk2ps_en <= '0';
      clk3ps_en <= '0';
      clk4ps_en <= '0';
      clk5ps_en <= '0';
      clkfbm1ps_en <= '0';
    elsif (rising_edge(clkout_en)) then 
      clk0ps_en <=  '1' after p_c0_d;
      clk1ps_en <= '1' after p_c1_d;
      clk2ps_en <= '1' after p_c2_d;
      clk3ps_en <= '1' after p_c3_d;
      clk4ps_en <= '1' after p_c4_d;
      clk5ps_en <= '1' after p_c5_d;
      clkfbm1ps_en <=  '1' after p_fb_d;
    end if;
    end process;

    process (clkpll_r, rst_in) begin
    if (rst_in = '1') then
        clk0_cnt <= 0;
        clk1_cnt <= 0;
        clk2_cnt <= 0;
        clk3_cnt <= 0;
        clk4_cnt <= 0;
        clk5_cnt <= 0;
        clkfb_cnt <= 0;
        clk0_gen <= '0';
        clk1_gen <= '0';
        clk2_gen <= '0';
        clk3_gen <= '0';
        clk4_gen <= '0';
        clk5_gen <= '0';
        clkfb_gen <= '0';
    elsif (rising_edge (clkpll_r)) then
      if (clkout_en0_tmp  =  '1' ) then
        if (clk0_cnt < clk0_val2 ) then
           clk0_cnt <= clk0_cnt + 1;
        else 
           clk0_cnt <= 0; 
        end if;
    
        if (clk0_cnt >= clk0_val ) then
           clk0_gen <= '0';
        else
           clk0_gen <= '1';
        end if;
      else 
         clk0_cnt <= 0;
         clk0_gen <= '0';
      end if;

      if (clkout_en0_tmp  =  '1' ) then
        if (clk1_cnt < clk1_val2 ) then
           clk1_cnt <= clk1_cnt + 1;
        else
           clk1_cnt <= 0;
        end if;

        if (clk1_cnt >= clk1_val ) then
           clk1_gen <= '0';
        else
           clk1_gen <= '1';
        end if;
      else 
         clk1_cnt <= 0;
         clk1_gen <= '0';
      end if;

      if (clkout_en0_tmp  =  '1' ) then
        if (clk2_cnt < clk2_val2 ) then
           clk2_cnt <= clk2_cnt + 1;
        else
           clk2_cnt <= 0;
        end if;

        if (clk2_cnt >= clk2_val ) then
           clk2_gen <= '0';
        else
           clk2_gen <= '1';
        end if;
      else 
         clk2_cnt <= 0;
         clk2_gen <= '0';
      end if;

      if (clkout_en0_tmp  =  '1' ) then
        if (clk3_cnt < clk3_val2) then
           clk3_cnt <= clk3_cnt + 1;
        else
           clk3_cnt <= 0;
        end if;

        if (clk3_cnt >= clk3_val ) then
           clk3_gen <= '0';
        else
           clk3_gen <= '1';
        end if;
      else 
         clk3_cnt <= 0;
         clk3_gen <= '0';
      end if;

      if (clkout_en0_tmp  =  '1' ) then
        if (clk4_cnt < clk4_val2 ) then
           clk4_cnt <= clk4_cnt + 1;
        else
           clk4_cnt <= 0;
        end if;

        if (clk4_cnt >= clk4_val ) then
           clk4_gen <= '0';
        else
           clk4_gen <= '1';
        end if;
      else 
         clk4_cnt <= 0;
         clk4_gen <= '0';
      end if;

      if (clkout_en0_tmp  =  '1' ) then
        if (clk5_cnt < clk5_val2) then
           clk5_cnt <= clk5_cnt + 1;
        else
           clk5_cnt <= 0;
        end if;

        if (clk5_cnt >= clk5_val ) then
           clk5_gen <= '0';
        else
           clk5_gen <= '1';
        end if;
      else 
         clk5_cnt <= 0;
         clk5_gen <= '0';
      end if;

      if (clkout_en0_tmp  =  '1' ) then
        if (clkfb_cnt < clkfb_val2 ) then
           clkfb_cnt <= clkfb_cnt + 1;
        else
           clkfb_cnt <= 0;
        end if;

        if (clkfb_cnt >= clkfb_val) then
           clkfb_gen <= '0';
        else
           clkfb_gen <= '1';
        end if;
      else 
         clkfb_cnt <= 0;
         clkfb_gen <= '0';
      end if;
    end if;
    end process;
   
    process (clk0_gen,  rst_in) begin
    if (rst_in  =  '1') then
      clk0_gen_f <= '0';
    else
      clk0_gen_f <=  clk0_gen after p_c0_d;
    end if;
    end process;

    process (clk1_gen,  rst_in) begin
    if (rst_in  =  '1') then
      clk1_gen_f <= '0';
    else
      clk1_gen_f <=  clk1_gen after p_c1_d;
    end if;
    end process;

    process (clk2_gen,  rst_in) begin
    if (rst_in  =  '1') then
      clk2_gen_f <= '0';
    else
      clk2_gen_f <=  clk2_gen after p_c2_d;
    end  if;
    end process;

    process (clk3_gen,  rst_in) begin
    if (rst_in  =  '1') then
      clk3_gen_f <= '0';
    else
      clk3_gen_f <= clk3_gen after p_c3_d;
    end if;
    end process;

    process (clk4_gen,  rst_in) begin
    if (rst_in  =  '1') then
      clk4_gen_f <= '0';
    else
      clk4_gen_f <=  clk4_gen after p_c4_d;
    end if;
    end process;

    process (clk5_gen,  rst_in) begin
    if (rst_in  =  '1') then
      clk5_gen_f <= '0';
    else
      clk5_gen_f <=  clk5_gen after p_c5_d;
    end if;
    end process;

    process (clkfb_gen,  rst_in) begin
    if (rst_in  =  '1') then
      clkfb_gen_f  <= '0';
    else
      clkfb_gen_f <=  clkfb_gen after p_fb_d;
    end if;
    end process;

    process  begin
    if (rst_in  =  '1') then
       clk0_out <= '0';
    elsif (rising_edge(clk0_gen_f) or falling_edge(clk0_gen_f)) then
      if (clk0ps_en  =  '1' ) then
        if ( clk0_val1 = 1) then
            clk0_out <= '1';
            wait for p_c0_h;
            clk0_out <= '0';
            wait for p_c0_r1;
        else
         for i0 in 1 to  clk0_val11 loop
            clk0_out <= '1';
            wait for p_c0_h;
            clk0_out <= '0';
            wait for p_c0_r;
         end loop;
            clk0_out <= '1';
            wait for p_c0_h;
            clk0_out <= '0';
            wait for p_c0_r1;
         end if;
      else
        clk0_out <= '0';
      end if;
    end if;
      wait on clk0_gen_f, rst_in;
    end process;

    process  begin
    if (rst_in  =  '1') then
       clk1_out <= '0';
    elsif (rising_edge(clk1_gen_f) or falling_edge(clk1_gen_f)) then
      if (clk1ps_en  =  '1' ) then
        if ( clk1_val1 = 1) then
            clk1_out <= '1';
            wait for p_c1_h;
            clk1_out <= '0';
            wait for p_c1_r1;
        else
         for i1 in 1 to  clk1_val11 loop
            clk1_out <= '1';
            wait for p_c1_h;
            clk1_out <= '0';
            wait for p_c1_r;
         end loop;
            clk1_out <= '1';
            wait for p_c1_h;
            clk1_out <= '0';
            wait for p_c1_r1;
         end if;
      else
        clk1_out <= '0';
      end if;
    end if;
      wait on clk1_gen_f, rst_in;
    end process;

    process  begin
    if (rst_in  =  '1') then
       clk2_out <= '0';
    elsif (rising_edge(clk2_gen_f) or falling_edge(clk2_gen_f)) then
      if (clk2ps_en  =  '1' ) then
        if ( clk2_val1 = 1) then
            clk2_out <= '1';
            wait for p_c2_h;
            clk2_out <= '0';
            wait for p_c2_r1;
        else
         for i2 in 1 to  clk2_val11 loop
            clk2_out <= '1';
            wait for p_c2_h;
            clk2_out <= '0';
            wait for p_c2_r;
         end loop;
            clk2_out <= '1';
            wait for p_c2_h;
            clk2_out <= '0';
            wait for p_c2_r1;
         end if;
      else
        clk2_out <= '0';
      end if;
    end if;
      wait on clk2_gen_f, rst_in;
    end process;

    process  begin
    if (rst_in  =  '1') then
       clk3_out <= '0';
    elsif (rising_edge(clk3_gen_f) or falling_edge(clk3_gen_f)) then
      if (clk3ps_en  =  '1' ) then
        if ( clk3_val1 = 1) then
            clk3_out <= '1';
            wait for p_c3_h;
            clk3_out <= '0';
            wait for p_c3_r1;
        else
         for i3 in 1 to  clk3_val11 loop
            clk3_out <= '1';
            wait for p_c3_h;
            clk3_out <= '0';
            wait for p_c3_r;
         end loop;
            clk3_out <= '1';
            wait for p_c3_h;
            clk3_out <= '0';
            wait for p_c3_r1;
         end if;
      else
        clk3_out <= '0';
      end if;
    end if;
      wait on clk3_gen_f, rst_in;
    end process;

    process  begin
    if (rst_in  =  '1') then
       clk4_out <= '0';
    elsif (rising_edge(clk4_gen_f) or falling_edge(clk4_gen_f)) then
      if (clk4ps_en  =  '1' ) then
        if ( clk4_val1 = 1) then
            clk4_out <= '1';
            wait for p_c4_h;
            clk4_out <= '0';
            wait for p_c4_r1;
        else
         for i4 in 1 to  clk4_val11 loop
            clk4_out <= '1';
            wait for p_c4_h;
            clk4_out <= '0';
            wait for p_c4_r;
         end loop;
            clk4_out <= '1';
            wait for p_c4_h;
            clk4_out <= '0';
            wait for p_c4_r1;
         end if;
      else
        clk4_out <= '0';
      end if;
    end if;
      wait on clk4_gen_f, rst_in;
    end process;

    process  begin
    if (rst_in  =  '1') then
       clk5_out <= '0';
    elsif (rising_edge(clk5_gen_f) or falling_edge(clk5_gen_f)) then
      if (clk5ps_en  =  '1' ) then
        if ( clk5_val1 = 1) then
            clk5_out <= '1';
            wait for p_c5_h;
            clk5_out <= '0';
            wait for p_c5_r1;
        else
         for i5 in 1 to  clk5_val11 loop
            clk5_out <= '1';
            wait for p_c5_h;
            clk5_out <= '0';
            wait for p_c5_r;
         end loop;
            clk5_out <= '1';
            wait for p_c5_h;
            clk5_out <= '0';
            wait for p_c5_r1;
         end if;
      else
        clk5_out <= '0';
      end if;
    end if;
      wait on clk5_gen_f, rst_in;
    end process;

    process  begin
    if (rst_in  =  '1') then
       clkfbm1_out <= '0';
    elsif (rising_edge(clkfb_gen_f) or falling_edge(clkfb_gen_f)) then
      if (clkfbm1ps_en  =  '1' ) then
        if (clkfb_val1 = 1) then
            clkfbm1_out <= '1';
            wait for p_fb_h;
            clkfbm1_out <= '0';
            wait for p_fb_r1;
        else
         for ib in 1 to clkfb_val11 loop
            clkfbm1_out <= '1';
            wait for p_fb_h;
            clkfbm1_out <= '0';
            wait for p_fb_r;
         end loop;
            clkfbm1_out <= '1';
            wait for p_fb_h;
            clkfbm1_out <= '0';
            wait for p_fb_r1;
         end if;
      else
        clkfbm1_out <= '0';
      end if;
    end if;
      wait on clkfb_gen_f, rst_in;
    end process;

    clkout0_out <= transport clk0_out  when fb_delay_found = '1' else clkfb_tst;
    clkout1_out <= transport clk1_out  when fb_delay_found = '1' else clkfb_tst;
    clkout2_out <= transport clk2_out  when fb_delay_found = '1' else clkfb_tst;
    clkout3_out <= transport clk3_out  when fb_delay_found = '1' else clkfb_tst;
    clkout4_out <= transport clk4_out  when fb_delay_found = '1' else clkfb_tst;
    clkout5_out <= transport clk5_out  when fb_delay_found = '1' else clkfb_tst;
    clkfb_out <= transport clkfbm1_out  when fb_delay_found = '1' else clkfb_tst;

    CLKFB_TST_P : process (clkpll_r, rst_in)
    begin
      if (rst_in = '1') then
         clkfb_tst <= '0';
      elsif (rising_edge(clkpll_r)) then
        if (fb_delay_found_tmp = '0' and pwron_int = '0') then
           clkfb_tst <=   '1';
        else
           clkfb_tst <=   '0';
        end if;
      end if;
    end process;

    FB_DELAY_CAL_P0 : process (clkfb_tst, rst_in)
    begin
      if (rst_in = '1')  then
         delay_edge <= 0 ps;
      elsif (rising_edge(clkfb_tst)) then
        delay_edge <= NOW;
      end if;
    end process;

    FB_DELAY_CAL_P : process (clkfb_in, rst_in)
      variable delay_edge1 : time := 0 ps;
      variable fb_delay_tmp : time := 0 ps;
      variable Message : line;
    begin
      if (rst_in = '1')  then
        fb_delay  <= 0 ps;
        fb_delay_found_tmp <= '0';
        delay_edge1 := 0 ps;
        fb_delay_tmp := 0 ps;
      elsif (clkfb_in'event and clkfb_in = '1') then
        if (fb_delay_found_tmp = '0') then
          if (delay_edge /= 0 ps) then
            delay_edge1 := NOW;
            fb_delay_tmp := delay_edge1 - delay_edge;
          else
            fb_delay_tmp := 0 ps;
          end if;
          fb_delay <= fb_delay_tmp;
          fb_delay_found_tmp <= '1';
          if (rst_in = '0' and (fb_delay_tmp > fb_delay_max)) then
            Write ( Message, string'(" Warning : The feedback delay is "));
            Write ( Message, fb_delay_tmp);
            Write ( Message, string'(". It is over the maximun value "));
            Write ( Message, fb_delay_max);
            Write ( Message, '.' & LF );
            assert false report Message.all severity warning;
            DEALLOCATE (Message);
          end if;
        end if;
      end if;
    end process;

    fb_delay_found_P : process(fb_delay_found_tmp, clkvco_delay, rst_in)
    begin
      if (rst_in = '1') then
        fb_delay_found <= '0';
      elsif (clkvco_delay = 0 ps) then
        fb_delay_found <= fb_delay_found_tmp after 1 ns;
      else
        fb_delay_found <= fb_delay_found_tmp after clkvco_delay;
      end if;
    end process;

end PLLE2_ADV_V;
