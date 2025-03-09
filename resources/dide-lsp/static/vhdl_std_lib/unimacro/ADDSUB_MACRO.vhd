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
-- /___/   /\     Filename : ADDSUB_MACRO.vhd
-- \   \  /  \
--  \___\/\___\
--
-- Revision:
--    06/06/08 - Initial version.
--    04/18/11 - 652098 - Fix for latency 0
--    10/27/14 - Added missing ALUMODEREG (CR 827820).
--    04/09/15 - 852167 - align with verilog
-- End Revision

----- CELL ADDSUB_MACRO -----

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

library STD;
use STD.TEXTIO.ALL;


entity ADDSUB_MACRO is
  generic ( 
    DEVICE : string := "VIRTEX5";
            LATENCY : integer := 2;
            STYLE : string := "DSP";
            WIDTH : integer := 48;
            WIDTH_B : integer := 48;
            WIDTH_RESULT : integer := 48;
            MODEL_TYPE : integer := 0;
            VERBOSITY : integer := 0
       );

  port (
      CARRYOUT : out std_logic;
      RESULT : out std_logic_vector(WIDTH-1 downto 0);
      A : in std_logic_vector(WIDTH-1 downto 0);   
      ADD_SUB : in std_logic;   
      B : in std_logic_vector(WIDTH-1 downto 0);   
      CARRYIN : in std_logic;  
      CE : in std_logic;
      CLK : in std_logic;   
      RST : in std_logic
     );   
end entity ADDSUB_MACRO;

architecture addsub of ADDSUB_MACRO is
  function CheckDevice (
    device : in string
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;

  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute DEVICE : ") );
      write( Message, DEVICE);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" VIRTEX5, VIRTEX6, SPARTAN6, 7SERIES. ") );
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
 function CheckLatency (
    lat : in integer
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (LATENCY = 0 or LATENCY = 1 or LATENCY = 2) then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute LATENCY : ") );
      write ( Message, LATENCY);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 0, 1, 2. ") );
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
    else
      func_width := 0;
    end if;
    return func_width;
  end;
  function GetPREG_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if (LATENCY = 1 or LATENCY = 2 ) then
      func_width := 1;
    else
      func_width := 0;
    end if;
    return func_width;
  end;


--Signal Declarations:   

   signal ALUMODE_IN :  std_logic_vector(3 downto 0);	
   signal OPMODEST_IN :  std_logic_vector(7 downto 0);	
   signal A_IN :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal B_IN :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal A_INST :  std_logic_vector(17 downto 0) := "000000000000000000";
   signal RESULT_OUT :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal CARRYOUT_OUT : std_logic_vector(3 downto 0);
   signal CARRYOUTST : std_logic;
   signal CARRYIN_IN : std_logic;  
 
   constant ChkDevice : boolean := CheckDevice(DEVICE);
   constant ChkStyle : boolean := CheckStyle(STYLE);
   constant ChkWidth : boolean := CheckWidth(WIDTH);
   constant ChkLatency : boolean := CheckLatency(LATENCY);
   constant AREG_IN : integer := GetABREG_IN(LATENCY);
   constant ALUMODEREG_IN : integer := GetABREG_IN(LATENCY);
   constant BREG_IN : integer := GetABREG_IN(LATENCY);
   constant CREG_IN : integer := GetABREG_IN(LATENCY);
   constant PREG_IN : integer := GetPREG_IN(LATENCY);

-- Architecture Section: instantiation  
begin
  
  ALUMODE_IN <= "00" & (not ADD_SUB) & (not ADD_SUB);
  CARRYIN_IN <= CARRYIN when (WIDTH = 48) else '0';

  OPMODEST_IN <= (not ADD_SUB) & (not ADD_SUB) & "001111";

  add48 : if (WIDTH = 48) generate
    begin 
      A_IN <= A;
      B_IN <= B;
    end generate add48;
  add : if (WIDTH < 48) generate
    begin 
      A_IN(47 downto (47-(WIDTH-1))) <= A;
      A_IN((47-WIDTH)) <= ADD_SUB;
      sa: for i in (47-(WIDTH+1)) downto 0 generate
            A_IN(i) <= '0';
          end generate;
      B_IN(47 downto (47-(WIDTH-1))) <= B;
      B_IN((47-WIDTH)) <= CARRYIN;
      sb: for i in (47-(WIDTH+1)) downto 0 generate
            B_IN(i) <= '0';
          end generate;
    end generate add;
  
  A_INST <= "000000" & A_IN(47 downto 36);
  RESULT <= RESULT_OUT(47 downto (47-(WIDTH-1)));
 
  c1: if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
        CARRYOUT <= CARRYOUT_OUT(3);
   end generate c1;
   -- begin s1
  c2: if (DEVICE = "SPARTAN6") generate
        CARRYOUT <= CARRYOUTST;
   end generate c2;
   -- end s1

 -- begin generate virtex5
  v5 : if DEVICE = "VIRTEX5" generate
    begin
      DSP48_1: DSP48E 
        generic map (
          ACASCREG => AREG_IN,       
          ALUMODEREG => ALUMODEREG_IN,   
          AREG => AREG_IN,           
          BCASCREG => BREG_IN,       
          BREG => BREG_IN,           
          CREG => CREG_IN,           
          PREG => PREG_IN,           
          USE_MULT => "NONE") 
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => CARRYOUT_OUT(3 downto 0), 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => RESULT_OUT,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => open, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => B_IN(47 downto 18),          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => B_IN(17 downto 0),          
          BCIN => "000000000000000000",    
          C => A_IN,           
          CARRYCASCIN => '0', 
          CARRYIN => CARRYIN_IN, 
          CARRYINSEL => "000", 
          CEA1 => CE,      
          CEA2 => CE,      
          CEALUMODE => CE, 
          CEB1 => CE,      
          CEB2 => CE,      
          CEC => CE,      
          CECARRYIN => CE, 
          CECTRL => CE, 
          CEM => '0',       
          CEMULTCARRYIN => '0',
          CEP => CE,       
          CLK => CLK,       
          MULTSIGNIN => '0', 
          OPMODE => "0110011", 
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
      DSP48_2: DSP48E1 
        generic map (
          ACASCREG => AREG_IN,       
          AREG => AREG_IN,   
          ADREG => 0,
          ALUMODEREG => ALUMODEREG_IN,   
          BCASCREG => BREG_IN,       
          BREG => BREG_IN,           
          CREG => CREG_IN,      
          DREG => 0,
          MREG => 0,
          PREG => PREG_IN,           
          USE_MULT => "NONE") 
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => CARRYOUT_OUT, 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => RESULT_OUT,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => open, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => B_IN(47 downto 18),          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => B_IN(17 downto 0),          
          BCIN => "000000000000000000",    
          C => A_IN,           
          CARRYCASCIN => '0', 
          CARRYIN => CARRYIN_IN, 
          CARRYINSEL => "000", 
          CEA1 => CE,      
          CEA2 => CE,      
          CEAD => '0',
          CEALUMODE => CE, 
          CEB1 => CE,      
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
          OPMODE => "0110011", 
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
  -- begin generate spartan6
  st : if DEVICE = "SPARTAN6" generate
      begin
        DSP48_3: DSP48A1 
        generic map (
            A1REG => AREG_IN,   
            B1REG => BREG_IN,           
            CREG => CREG_IN,      
            PREG => PREG_IN )           
       port map ( 
            BCOUT => open,  
            CARRYOUT => CARRYOUTST, 
            CARRYOUTF => open, 
            M => open, 
            P => RESULT_OUT,          
            PCOUT => open,  
            A => A_IN(35 downto 18),          
            B => A_IN(17 downto 0),          
            C => B_IN,           
            CARRYIN => CARRYIN_IN, 
            CEA => CE,      
            CEB => CE,      
            CEC => CE,      
            CECARRYIN => CE, 
            CED => CE,
            CEM => '0',       
            CEOPMODE => CE, 
            CEP => CE,       
            CLK => CLK,       
            D => A_INST,
            OPMODE => OPMODEST_IN, 
            PCIN => "000000000000000000000000000000000000000000000000",      
            RSTA => RST,     
            RSTB => RST,     
            RSTC => RST,     
            RSTCARRYIN => RST,     
            RSTD => RST,
            RSTM => RST, 
            RSTOPMODE => RST,
            RSTP => RST 
         );
  end generate st;
  -- end generate spartan6
end addsub;



