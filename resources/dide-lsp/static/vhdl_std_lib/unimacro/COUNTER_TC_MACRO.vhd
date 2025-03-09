-------------------------------------------------------------------------------
-- Copyright (c) 1995/2007 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 13.1
--  \   \         Description : Xilinx Functional Simulation Library Component
--  /   /                  Macro for DSP48
-- /___/   /\     Filename : COUNTER_TC_MACRO.vhd
-- \   \  /  \    Timestamp : Fri April 18 2008 10:43:59 PST 2008
--  \___\/\___\
--
-- Revision:
--    06/08/08 - Initial version.
--    01/04/12 - Fix for CR 639887
-- End Revision

----- CELL COUNTER_TC_MACRO -----

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

library STD;
use STD.TEXTIO.ALL;

entity COUNTER_TC_MACRO is
  generic ( 
            COUNT_BY : std_logic_vector := X"000000000001";
    DEVICE : string := "VIRTEX5";
            DIRECTION : string := "UP";
            RESET_UPON_TC : string := "FALSE";
            STYLE : string := "AUTO";
            TC_VALUE : std_logic_vector := X"000000000000";
            WIDTH_DATA : integer := 48
       );

  port (
      Q : out std_logic_vector(WIDTH_DATA-1 downto 0);   
      TC : out std_logic;   
      CE : in std_logic;
      CLK : in std_logic;   
      RST : in std_logic   
     );   
end entity COUNTER_TC_MACRO;

architecture count of COUNTER_TC_MACRO is

  function CheckDevice (
    device : in string
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;

  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES" ) then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute DEVICE : ") );
      write ( Message, DEVICE);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" VIRTEX5, VIRTEX6, 7SERIES. ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;
  function CheckStyle (
    style : in string
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (style = "AUTO" or style = "DSP" ) then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute STYLE : ") );
      write ( Message, STYLE);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" AUTO, DSP ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;
  function CheckWidth (
    width : in integer
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (width > 0 and width <= 48 ) then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute WIDTH_DATA : ") );
      write ( Message, WIDTH_DATA);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 48 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;

   function CheckReset (
    reset : in string
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (reset = "TRUE" or reset = "FALSE" ) then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute RESET_UPON_TC : ") );
      write ( Message, STYLE);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" TRUE or FALSE ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;

  function GetDirection (
    dir : in string
    ) return std_logic is
    variable func_val : std_logic;
    variable Message : LINE;
  begin
    if (DIRECTION = "UP") then
      func_val := '0';
    elsif (DIRECTION = "DOWN") then
      func_val := '1';
    else
      write( Message, STRING'("Illegal value of Attribute DIRECTION : ") );
      write ( Message, DIRECTION);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" UP or DOWN ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;


--Signal Declarations:   

   signal ALUMODE_IN :  std_logic_vector(3 downto 0);	
   signal OPMODE_IN :  std_logic_vector(6 downto 0);	
   signal CNTR_OUT :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal COUNT_BY_INP :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal Q_IN :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal TC_INT :  std_logic;

   constant ChkDevice : boolean := CheckDevice(DEVICE);
   constant ChkStyle : boolean := CheckStyle(STYLE);
   constant ChkWidth : boolean := CheckWidth(WIDTH_DATA);
   constant ChkReset : boolean := CheckReset(RESET_UPON_TC);
   constant ADD_SUB : std_logic := GetDirection(DIRECTION);

-- Architecture Section: instantiation  
begin
 
  t1 : TC_INT <=  '1' when ( CNTR_OUT = (TC_VALUE -1) and RST = '0') else '0';
  t2 : TC <=  '1' when ( CNTR_OUT = TC_VALUE and RST = '0') else '0';
  op : OPMODE_IN <=  ('0' & (not TC_INT) & "000" & (not TC_INT) & (not TC_INT) ) when (RESET_UPON_TC = "TRUE") else "0100011";
  Q <=  Q_IN(WIDTH_DATA-1 downto 0) when (RST = '1' or (RESET_UPON_TC = "TRUE" and CNTR_OUT = (TC_VALUE+1))) else CNTR_OUT(WIDTH_DATA-1 downto 0);

  ALUMODE_IN <= "00" & ADD_SUB & ADD_SUB;
  COUNT_BY_INP <= COUNT_BY;

  -- begin generate virtex5
  v5 : if DEVICE = "VIRTEX5" generate
    begin
      DSP48E_1: DSP48E 
        generic map (
          USE_MULT => "NONE") 
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => open, 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => CNTR_OUT,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => open, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => COUNT_BY_INP(47 downto 18),          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => COUNT_BY_INP(17 downto 0),          
          BCIN => "000000000000000000",    
          C => "000000000000000000000000000000000000000000000000",           
          CARRYCASCIN => '0', 
          CARRYIN => '0', 
          CARRYINSEL => "000", 
          CEA1 => '0',      
          CEA2 => CE,      
          CEALUMODE => CE, 
          CEB1 => '0',      
          CEB2 => CE,      
          CEC => CE,      
          CECARRYIN => CE, 
          CECTRL => CE, 
          CEM => '0',       
          CEMULTCARRYIN => '0',
          CEP => CE,       
          CLK => CLK,       
          MULTSIGNIN => '0', 
          OPMODE => OPMODE_IN, 
          PCIN => "000000000000000000000000000000000000000000000000",      
          RSTA => RST,     
          RSTALLCARRYIN => RST, 
          RSTALUMODE => RST, 
          RSTB => RST,     
          RSTC => RST,     
          RSTCTRL => RST, 
          RSTM => RST, 
          RSTP => RST 
       );
end generate v5;
  -- end generate virtex5
  -- begin generate virtex6
bl : if (DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
    begin
      DSP48E_2: DSP48E1 
        generic map (
          DREG => 0,
          ADREG => 0,
          MREG => 0,
          USE_MULT => "NONE") 
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => open, 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => CNTR_OUT,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => open, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => COUNT_BY_INP(47 downto 18),          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => COUNT_BY_INP(17 downto 0),          
          BCIN => "000000000000000000",    
          C => "000000000000000000000000000000000000000000000000",           
          CARRYCASCIN => '0', 
          CARRYIN => '0', 
          CARRYINSEL => "000", 
          CEA1 => '0',      
          CEA2 => CE,      
          CEAD => '0',
          CEALUMODE => CE, 
          CEB1 => '0',      
          CEB2 => CE,      
          CEC => CE,      
          CECARRYIN => CE, 
          CECTRL => CE,
          CED => '0',
          CEINMODE => '0', 
          CEM => '0',       
          CEP => CE,       
          CLK => CLK,       
          D => "0000000000000000000000000",
          INMODE => "00000", 
          MULTSIGNIN => '0', 
          OPMODE => OPMODE_IN, 
          PCIN => "000000000000000000000000000000000000000000000000",      
          RSTA => RST,     
          RSTALLCARRYIN => RST, 
          RSTALUMODE => RST, 
          RSTB => RST,     
          RSTC => RST,     
          RSTCTRL => RST, 
          RSTD => RST,
          RSTINMODE => RST,
          RSTM => RST, 
          RSTP => RST 
       );
end generate bl;
  -- end generate virtex6
end count;



