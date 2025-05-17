-------------------------------------------------------------------------------
-- Copyright (c) 1995/2015 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 2015.3
--  \   \         Description : Xilinx Functional Simulation Library Component
--  /   /                  Macro for DSP48
-- /___/   /\     Filename : EQ_COMPARE_MACRO.vhd
-- \   \  /  \
--  \___\/\___\
--
-- Revision:
--    04/04/08 - Initial version.
--    04/09/15 - 852167 - align with verilog
-- End Revision

----- CELL EQ_COMPARE_MACRO -----

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

library STD;
use STD.TEXTIO.ALL;

entity EQ_COMPARE_MACRO is
  generic ( 
            DEVICE : string := "VIRTEX6";
            LATENCY : integer := 2;
            MASK : bit_vector := X"000000000000";
            SEL_MASK : string := "MASK";
            SEL_PATTERN : string := "DYNAMIC_PATTERN";
            STATIC_PATTERN : bit_vector := X"000000000000";
            WIDTH : integer := 48
       );

  port (
      Q : out std_logic;   
      CE : in std_logic;
      CLK : in std_logic;   
      DATA_IN : in std_logic_vector(WIDTH-1 downto 0);
      DYNAMIC_PATTERN : in std_logic_vector(WIDTH-1 downto 0);
      RST : in std_logic   
     );   
end entity EQ_COMPARE_MACRO;

architecture compare of EQ_COMPARE_MACRO is

  function CheckDevice (
    device : in string
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;

  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
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
  function GetSelPattern (
    sel_pat : in string
    ) return string is
    variable Message : LINE;
  begin
    if (sel_pat = "STATIC_PATTERN") then
      return "PATTERN";
    elsif (sel_pat = "DYNAMIC_PATTERN") then
      return "C";
    else
      write( Message, STRING'("Illegal value of Attribute SEL_PATTERN : ") );
      write ( Message, SEL_PATTERN);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" STATIC_PATTERN, DYNAMIC_PATTERN ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return "PATTERN";
    end if;
  end;
  function GetSelMask (
    sel_mas : in string
    ) return string is
    variable Message : LINE;
  begin
    if (sel_mas = "MASK" ) then
      return "MASK";
    elsif (sel_mas = "DYNAMIC_PATTERN") then
      return "C"; 
    else
      write( Message, STRING'("Illegal value of Attribute SEL_MASK : ") );
      write ( Message, SEL_MASK);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" MASK, DYNAMIC_PATTERN ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return "MASK";
    end if;
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
      write( Message, STRING'("Illegal value of Attribute WIDTH : ") );
      write ( Message, WIDTH);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 48 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;
  function GetABREG_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
  begin
    if (LATENCY = 2 ) then
      func_width := 1;
    elsif (LATENCY = 3 ) then
      func_width := 2;
    else
      func_width := 0;
    end if;
    return func_width;
  end;
  function GetCREG_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if (LATENCY = 2 or LATENCY = 3 ) then
      func_width := 1;
    else
      func_width := 0;
    end if;
    return func_width;
  end;
  function GetQREG_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if (LATENCY = 1 or LATENCY = 2 or LATENCY = 3) then
      func_width := 1;
    elsif (LATENCY = 0) then
      func_width := 0;
    else
      func_width := 0;
      write( Message, STRING'("Illegal value of Attribute LATENCY : ") );
      write ( Message, LATENCY);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 0 to 3 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_width;
  end;

  
--Signal Declarations:   

   signal DYNAMIC_PATTERN_INP :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal DATA_INP :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal CEA1_IN :  std_logic;
   signal CEA2_IN :  std_logic;
   signal CEB1_IN :  std_logic;
   signal CEB2_IN :  std_logic;
 
   constant AREG_IN : integer := GetABREG_IN(LATENCY);
   constant BREG_IN : integer := GetABREG_IN(LATENCY);
   constant CREG_IN : integer := GetCREG_IN(LATENCY);
   constant QREG : integer := GetQREG_IN(LATENCY);
   constant ChkDevice : boolean := CheckDevice(DEVICE);
   constant SEL_PATTERN_IN : string := GetSelPattern(SEL_PATTERN);
   constant SEL_MASK_IN : string := GetSelMask(SEL_MASK);
   constant ChkWidth : boolean := CheckWidth(WIDTH);

-- Architecture Section: instantiation  
begin
 
   CEA1_IN <=  CE when (AREG_IN = 2) else '0';
   CEA2_IN <=  CE when (AREG_IN = 1 or AREG_IN = 2) else '0';
   CEB1_IN <=  CE when (BREG_IN = 2) else '0';
   CEB2_IN <=  CE when (BREG_IN = 1 or BREG_IN = 2) else '0';

    inps1 : if (WIDTH = 48) generate
     begin
       DATA_INP  <= DATA_IN;
       DYNAMIC_PATTERN_INP  <= DYNAMIC_PATTERN;
     end generate inps1;
    inps2 : if (WIDTH < 48) generate
     begin
        i1: for i in 47 downto WIDTH generate
              DATA_INP(i) <= '0';
              DYNAMIC_PATTERN_INP(i) <= '0';
        end generate;
        DATA_INP(WIDTH-1 downto 0)  <= DATA_IN(WIDTH-1 downto 0);
        DYNAMIC_PATTERN_INP(WIDTH-1 downto 0)  <= DYNAMIC_PATTERN(WIDTH-1 downto 0);
     end generate inps2;

  -- begin generate virtex5
  v5 : if DEVICE = "VIRTEX5" generate
    begin
      DSP48E_1: DSP48E 
        generic map (
          ACASCREG => AREG_IN,       
          AREG => AREG_IN,           
          BCASCREG => BREG_IN,       
          BREG => BREG_IN,           
          CREG => CREG_IN,           
          MASK => MASK, 
          PATTERN => STATIC_PATTERN, 
          PREG => QREG,           
          SEL_MASK => SEL_MASK_IN,  
          SEL_PATTERN => SEL_PATTERN_IN, 
          USE_MULT => "NONE", 
          USE_PATTERN_DETECT => "PATDET" 
          ) 
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => open, 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => open,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => Q, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => DATA_INP(47 downto 18),          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => "0000", 
          B => DATA_INP(17 downto 0),          
          BCIN => "000000000000000000",    
          C => DYNAMIC_PATTERN_INP,           
          CARRYCASCIN => '0', 
          CARRYIN => '0', 
          CARRYINSEL => "000", 
          CEA1 => CEA1_IN,      
          CEA2 => CEA2_IN,      
          CEALUMODE => CE, 
          CEB1 => CEB1_IN,      
          CEB2 => CEB2_IN,      
          CEC => CE,      
          CECARRYIN => CE, 
          CECTRL => CE, 
          CEM => '0',       
          CEMULTCARRYIN => '0',
          CEP => CE,       
          CLK => CLK,       
          MULTSIGNIN => '0', 
          OPMODE => "0000011", 
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
          ACASCREG => AREG_IN,       
          AREG => AREG_IN,           
          ADREG => 0,           
          BCASCREG => BREG_IN,       
          BREG => BREG_IN,           
          CREG => CREG_IN,           
          DREG => 0,           
          MREG => 0,           
          MASK => MASK, 
          PATTERN => STATIC_PATTERN, 
          PREG => QREG,           
          SEL_MASK => SEL_MASK_IN,  
          SEL_PATTERN => SEL_PATTERN_IN, 
          USE_MULT => "NONE", 
          USE_PATTERN_DETECT => "PATDET" 
          ) 
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => open, 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => open,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => Q, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => DATA_INP(47 downto 18),          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => "0000", 
          B => DATA_INP(17 downto 0),          
          BCIN => "000000000000000000",    
          C => DYNAMIC_PATTERN_INP,           
          CARRYCASCIN => '0', 
          CARRYIN => '0', 
          CARRYINSEL => "000", 
          CEA1 => CEA1_IN,      
          CEA2 => CEA2_IN,      
          CEAD => '0',
          CEALUMODE => CE, 
          CEB1 => CEB1_IN,      
          CEB2 => CEB2_IN,      
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
          OPMODE => "0000011", 
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

end compare;



