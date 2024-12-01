-------------------------------------------------------------------------------
-- Copyright (c) 1995/2008 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 13.1
--  \   \         Description : Xilinx Functional Simulation Library Component
--  /   /                  Macro for DSP48
-- /___/   /\     Filename : COUNTER_LOAD_MACRO.vhd
-- \   \  /  \    Timestamp : Fri April 18 2008 10:43:59 PST 2008
--  \___\/\___\
--
-- Revision:
--    04/18/08 - Initial version.
-- End Revision

----- CELL COUNTER_LOAD_MACRO -----

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

library STD;
use STD.TEXTIO.ALL;

entity COUNTER_LOAD_MACRO is
  generic ( 
            COUNT_BY : std_logic_vector := X"000000000001";
    DEVICE : string := "VIRTEX5";
            STYLE : string := "AUTO";
            WIDTH_DATA : integer := 48
       );

  port (
      Q : out std_logic_vector(WIDTH_DATA-1 downto 0);   
      CE : in std_logic;
      CLK : in std_logic;   
      DIRECTION : in std_logic;
      LOAD : in std_logic;
      LOAD_DATA : in std_logic_vector(WIDTH_DATA-1 downto 0);
      RST : in std_logic   
     );   
end entity COUNTER_LOAD_MACRO;

architecture counter of COUNTER_LOAD_MACRO is

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
      write ( Message, DEVICE);
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

  function GetOPMODE_IN (
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      func_width := 7;
    elsif (DEVICE = "SPARTAN6") then
      func_width := 8;
    else
      func_width := 8;
    end if;
    return func_width;
  end;

   constant OPMODE_WIDTH : integer := GetOPMODE_IN(DEVICE);
   constant ChkDevice : boolean := CheckDevice(DEVICE);
   constant ChkStyle : boolean := CheckStyle(STYLE);
   constant ChkWidth : boolean := CheckWidth(WIDTH_DATA);

--Signal Declarations:   
   signal OPMODE_IN :  std_logic_vector((OPMODE_WIDTH-1) downto 0);
   signal ALUMODE_IN :  std_logic_vector(3 downto 0);	
   signal CNTR_OUT :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal COUNT_BY_IN :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal LOAD_DATA_IN :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal D_INST :  std_logic_vector(17 downto 0) := "000000000000000000";


-- Architecture Section: instantiation  
begin
   
  v : if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
         OPMODE_IN <=  ("01" & LOAD & "00" & (not LOAD) & (not LOAD) );
  end generate v;

  s : if (DEVICE = "SPARTAN6") generate
         OPMODE_IN <= (not DIRECTION) & (not DIRECTION) & "001" & LOAD & "11";
  end generate s;

  Q <=  CNTR_OUT(WIDTH_DATA-1 downto 0);

    load1 : if (WIDTH_DATA = 48) generate
     begin
       LOAD_DATA_IN <= LOAD_DATA;
     end generate load1;
    load2 : if (WIDTH_DATA < 48) generate
     begin
       l1: for i in 47 downto WIDTH_DATA generate
             LOAD_DATA_IN(i) <= '0';
           end generate;
             LOAD_DATA_IN(WIDTH_DATA-1 downto 0) <= LOAD_DATA;
     end generate load2;

  ALUMODE_IN <= "00" & (not DIRECTION) & (not DIRECTION);
  COUNT_BY_IN <= COUNT_BY;

  D_INST <= "000000" & COUNT_BY_IN(47 downto 36);

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
          A => COUNT_BY_IN(47 downto 18),          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => COUNT_BY_IN(17 downto 0),          
          BCIN => "000000000000000000",    
          C => LOAD_DATA_IN,           
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
          A => COUNT_BY_IN(47 downto 18),          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => COUNT_BY_IN(17 downto 0),          
          BCIN => "000000000000000000",    
          C => LOAD_DATA_IN,           
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
  -- begin generate spartan6
  st : if DEVICE = "SPARTAN6" generate
      begin
        DSP48E_3: DSP48A1 
       port map ( 
            BCOUT => open,  
            CARRYOUT => open, 
            CARRYOUTF => open, 
            M => open, 
            P => CNTR_OUT,          
            PCOUT => open,  
            A => COUNT_BY_IN(35 downto 18),          
            B => COUNT_BY_IN(17 downto 0),          
            C => LOAD_DATA_IN,           
            CARRYIN => '0', 
            CEA => CE,      
            CEB => CE,      
            CEC => CE,      
            CECARRYIN => CE, 
            CED => CE,
            CEM => '0',       
            CEOPMODE => CE, 
            CEP => CE,       
            CLK => CLK,       
            D => D_INST,
            OPMODE => OPMODE_IN, 
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

end counter;



