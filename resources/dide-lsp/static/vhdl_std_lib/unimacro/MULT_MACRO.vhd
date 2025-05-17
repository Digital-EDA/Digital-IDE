-------------------------------------------------------------------------------
-- Copyright (c) 1995/2008 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 14.1
--  \   \         Description : Xilinx Functional Simulation Library Component
--  /   /                  Macro for DSP48
-- /___/   /\     Filename : MULT_MACRO.vhd
-- \   \  /  \    Timestamp : Fri June 06 2008 10:43:59 PST 2008
--  \___\/\___\
--
-- Revision:
--    06/06/08 - Initial version.
--    05/22/12 - 660408 - fix for latency 3 and 4
-- End Revision

----- CELL MULT_MACRO -----

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

library STD;
use STD.TEXTIO.ALL;


entity MULT_MACRO is
  generic ( 
    DEVICE : string := "VIRTEX5";
            LATENCY : integer := 3;
            STYLE : string := "DSP";
            WIDTH_A : integer := 18;
            WIDTH_B : integer := 18
       );

  port (
      P : out std_logic_vector((WIDTH_A+WIDTH_B)-1 downto 0);
      A : in std_logic_vector(WIDTH_A-1 downto 0);   
      B : in std_logic_vector(WIDTH_B-1 downto 0);   
      CE : in std_logic;
      CLK : in std_logic;   
      RST : in std_logic
     );   
end entity MULT_MACRO;

architecture mult of MULT_MACRO is

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
  function CheckWidthA (
    widtha : in integer
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if (widtha > 0 and widtha <= 25) then
      func_val := true;
      else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute WIDTH_A : ") );
      write ( Message, WIDTH_A);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 25 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      end if;
    -- begin s1
    else
      if (DEVICE = "SPARTAN6" and widtha > 0 and widtha <= 18) then
      func_val := true;
      else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute WIDTH_A : ") );
      write ( Message, WIDTH_A);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 18 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      end if;
    -- end s1
    end if;
    return func_val;
  end;
  function CheckWidthB (
    widthb : in integer
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (widthb > 0 and widthb <= 18 ) then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute WIDTH_B : ") );
      write ( Message, WIDTH_B);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 18 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;
  function GetWidthA (
    device : in string
    ) return integer is
    variable func_val : integer;
    variable Message : LINE;

  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      func_val := 25;
    else
      func_val := 18;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;
  function GetABREG_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
  begin
    if (LATENCY = 2 or LATENCY = 3) then
      func_width := 1;
    elsif (LATENCY = 4 ) then
      func_width := 2;
    else
      func_width := 0;
    end if;
    return func_width;
  end;
  function GetABREG1_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
  begin
    if (LATENCY = 2 or LATENCY = 3 or LATENCY = 4) then
      func_width := 1;
    else
      func_width := 0;
    end if;
    return func_width;
  end;
  function GetABREG0_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
  begin
    if (LATENCY = 4) then
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
  begin
    if (LATENCY = 3 or LATENCY = 4 ) then
      func_width := 1;
    else
      func_width := 0;
    end if;
    return func_width;
  end;
  function GetMREG_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if (LATENCY = 1 or LATENCY = 2 or LATENCY = 3 or LATENCY = 4 ) then
      func_width := 1;
    elsif (LATENCY = 0) then
      func_width := 0;
    else
      func_width := 0;
      write( Message, STRING'("Illegal value of Attribute LATENCY : ") );
      write ( Message, LATENCY);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 0 to 4 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_width;
  end;



--Signal Declarations:   

   signal A_IN :  std_logic_vector(24 downto 0) := "0000000000000000000000000";
   signal A_INP :  std_logic_vector(29 downto 0) := "000000000000000000000000000000";
   signal A_INST :  std_logic_vector(17 downto 0) := "000000000000000000";
   signal B_IN :  std_logic_vector(17 downto 0) := "000000000000000000";
   signal RESULT_OUT :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal RESULT_OUTST :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal CEA1_IN :  std_logic;
   signal CEA2_IN :  std_logic;
   signal CEB1_IN :  std_logic;
   signal CEB2_IN :  std_logic;

   constant ChkDevice : boolean := CheckDevice(DEVICE);
   constant ChkStyle : boolean := CheckStyle(STYLE);
   constant ChkWidthA : boolean := CheckWidthA(WIDTH_A);
   constant ChkWidthB : boolean := CheckWidthB(WIDTH_B);
   constant MaxWidthA : integer := GetWidthA(DEVICE);
   constant AREG_IN : integer := GetABREG_IN(LATENCY);
   constant BREG_IN : integer := GetABREG_IN(LATENCY);
   constant A0REG_IN : integer := GetABREG0_IN(LATENCY);
   constant B0REG_IN : integer := GetABREG0_IN(LATENCY);
   constant A1REG_IN : integer := GetABREG1_IN(LATENCY);
   constant B1REG_IN : integer := GetABREG1_IN(LATENCY);
   constant MREG_IN : integer := GetMREG_IN(LATENCY);
   constant PREG_IN : integer := GetPREG_IN(LATENCY);

-- Architecture Section: instantiation  
begin

   CEA1_IN <=  CE when (AREG_IN = 2) else '0';
   CEA2_IN <=  CE when (AREG_IN = 1 or AREG_IN = 2) else '0';
   CEB1_IN <=  CE when (BREG_IN = 2) else '0';
   CEB2_IN <=  CE when (BREG_IN = 1 or BREG_IN = 2) else '0';

  multa : if (WIDTH_A = MaxWidthA) generate
    begin 
      
    ga1 : if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
      A_IN(MaxWidthA-1 downto 0) <= A;
    end generate ga1;
    ga2 : if (DEVICE = "SPARTAN6") generate
      A_INST(MaxWidthA-1 downto 0) <= A;
    end generate ga2;
    end generate multa;
  multb : if (WIDTH_B = 18) generate
    begin 
      B_IN <= B;
    end generate multb;
  multas : if (WIDTH_A < MaxWidthA) generate
    begin 
          g1 : if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
             A_IN((MaxWidthA-1) downto (MaxWidthA-WIDTH_A)) <= A;
          g3 : for i in ((MaxWidthA-1)-WIDTH_A) downto 0 generate
             A_IN(i) <= '0';
              end generate g3;
          end generate g1;
          -- begin s2
          g2 : if (DEVICE = "SPARTAN6") generate
            A_INST((MaxWidthA-1) downto (MaxWidthA-WIDTH_A)) <= A;
          g4 : for i in ((MaxWidthA-1)-WIDTH_A) downto 0 generate
            A_INST(i) <= '0';
          end generate g4;
          end generate g2;
          -- end s2
    end generate multas;
  multbs : if (WIDTH_B < 18) generate
    begin 
      sb: for i in (17-WIDTH_B) downto 0 generate
            B_IN(i) <= '0';
          end generate;
            B_IN(17 downto (18-(WIDTH_B))) <= B;
    end generate multbs;
 
  A_INP  <= "00000" & A_IN ;
 
   p1: if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
     P <= RESULT_OUT(42 downto (42- ((WIDTH_A+WIDTH_B)-1)));
   end generate p1;
   -- begin s2
   p2: if (DEVICE = "SPARTAN6") generate
     P <= RESULT_OUTST(35 downto (35- ((WIDTH_A+WIDTH_B)-1)));
   end generate p2;
   -- end s2

  -- begin generate virtex5
  v5 : if DEVICE = "VIRTEX5" generate
    v5_1 : if LATENCY = 0 generate
    begin
      DSP48E_1: DSP48E 
        generic map (
          ACASCREG => AREG_IN,       
          AREG => AREG_IN,           
          BCASCREG => BREG_IN,       
          BREG => BREG_IN,           
          MREG => MREG_IN,           
          PREG => PREG_IN,
          USE_MULT => "MULT"           
          )
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => open, 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => RESULT_OUT,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => open, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => A_INP,          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => "0000", 
          B => B_IN,          
          BCIN => "000000000000000000",    
          C => "000000000000000000000000000000000000000000000000",           
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
          CEM => CE,       
          CEMULTCARRYIN => '0',
          CEP => CE,       
          CLK => CLK,       
          MULTSIGNIN => '0', 
          OPMODE => "0000101", 
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
    end generate v5_1;
    v5_2 : if LATENCY > 0 generate
    begin
      DSP48E_1: DSP48E 
        generic map (
          ACASCREG => AREG_IN,       
          AREG => AREG_IN,           
          BCASCREG => BREG_IN,       
          BREG => BREG_IN,           
          MREG => MREG_IN,           
          PREG => PREG_IN,
          USE_MULT => "MULT_S"           
          )
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => open, 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => RESULT_OUT,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => open, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => A_INP,          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => "0000", 
          B => B_IN,          
          BCIN => "000000000000000000",    
          C => "000000000000000000000000000000000000000000000000",           
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
          CEM => CE,       
          CEMULTCARRYIN => '0',
          CEP => CE,       
          CLK => CLK,       
          MULTSIGNIN => '0', 
          OPMODE => "0000101", 
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
    end generate v5_2;
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
          DREG => 0,
          MREG => MREG_IN,      
          PREG => PREG_IN           
          )
       port map (
          ACOUT => open,   
          BCOUT => open,  
          CARRYCASCOUT => open, 
          CARRYOUT => open, 
          MULTSIGNOUT => open, 
          OVERFLOW => open, 
          P => RESULT_OUT,          
          PATTERNBDETECT => open, 
          PATTERNDETECT => open, 
          PCOUT => open,  
          UNDERFLOW => open, 
          A => A_INP,          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => "0000", 
          B => B_IN,          
          BCIN => "000000000000000000",    
          C => "000000000000000000000000000000000000000000000000",           
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
          CEM => CE,       
          CEP => CE,       
          CLK => CLK,       
          D => "0000000000000000000000000",
          INMODE => "00000", 
          MULTSIGNIN => '0', 
          OPMODE => "0000101", 
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
        generic map (
            A0REG => A0REG_IN,   
            A1REG => A1REG_IN,   
            B0REG => B0REG_IN,           
            B1REG => B1REG_IN,           
            MREG => MREG_IN,      
            PREG => PREG_IN           
          )
         port map ( 
            BCOUT => open,  
            CARRYOUT => open, 
            CARRYOUTF => open, 
            --M => RESULT_OUTST, 
            M => open, 
            P => RESULT_OUTST,          
            PCOUT => open,  
            A => A_INST,          
            B => B_IN,          
            C => "000000000000000000000000000000000000000000000000",           
            CARRYIN => '0', 
            CEA => CE,      
            CEB => CE,      
            CEC => CE,      
            CECARRYIN => CE, 
            CED => CE,
            CEM => CE,       
            CEOPMODE => CE, 
            CEP => CE,       
            CLK => CLK,       
            D => "000000000000000000",
            OPMODE => "00000001", 
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

end mult;



