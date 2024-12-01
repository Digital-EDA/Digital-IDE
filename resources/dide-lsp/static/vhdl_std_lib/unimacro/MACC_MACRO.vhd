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
-- /___/   /\     Filename : MACC_MACRO.vhd
-- \   \  /  \
--  \___\/\___\
--
-- Revision:
--    06/06/08 - Initial version.
--    04/09/15 - 852167 - align with verilog
-- End Revision

----- CELL MACC_MACRO -----

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

library STD;
use STD.TEXTIO.ALL;


entity MACC_MACRO is
  generic ( 
    DEVICE : string := "VIRTEX5";
            LATENCY : integer := 3;
            WIDTH_A : integer := 25;
            WIDTH_B : integer := 18;
            WIDTH_P : integer := 48
       );

  port (
      P : out std_logic_vector(WIDTH_P-1 downto 0);
      A : in std_logic_vector(WIDTH_A-1 downto 0);   
      ADDSUB : in std_logic;
      B : in std_logic_vector(WIDTH_B-1 downto 0);  
      CARRYIN : in std_logic; 
      CE : in std_logic;
      CLK : in std_logic;
      LOAD : in std_logic;
      LOAD_DATA : in std_logic_vector(WIDTH_P-1 downto 0);   
      RST : in std_logic
     );   
end entity MACC_MACRO;

architecture macc of MACC_MACRO is

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
  function CheckWidthA (
    widtha : in integer;
    device : in string
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
      if (DEVICE = "SPARTAN6" and (widtha > 0 and widtha <= 18)) then
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

  function GetMREG_IN (
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
  function GetPREG_IN (
    latency : in integer
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if (LATENCY = 1 or LATENCY = 2 or LATENCY = 3 or LATENCY = 4 ) then
      func_width := 1;
    else
      func_width := 0;
      write( Message, STRING'("Illegal value of Attribute LATENCY : ") );
      write ( Message, LATENCY);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 4 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_width;
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


--Signal Declarations:   


   constant OPMODE_WIDTH : integer := GetOPMODE_IN(DEVICE);
   constant ChkDevice : boolean := CheckDevice(DEVICE);
   constant ChkWidthA : boolean := CheckWidthA(WIDTH_A, DEVICE);
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

   signal A_INP :  std_logic_vector(24 downto 0) := "0000000000000000000000000";
   signal A_IN :  std_logic_vector(29 downto 0) := "000000000000000000000000000000";
   signal B_IN :  std_logic_vector(17 downto 0) := "000000000000000000";
   signal RESULT_OUT :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal LOAD_DATA_IN :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal OPMODE_IN :  std_logic_vector((OPMODE_WIDTH-1) downto 0);
   signal ALUMODE_IN :  std_logic_vector(3 downto 0);
   
   signal CEA1_IN :  std_logic;
   signal CEA2_IN :  std_logic;
   signal CEB1_IN :  std_logic;
   signal CEB2_IN :  std_logic;

  

-- Architecture Section: instantiation  
begin

   CEA1_IN <=  CE when (AREG_IN = 2) else '0';
   CEA2_IN <=  CE when (AREG_IN = 1 or AREG_IN = 2) else '0';
   CEB1_IN <=  CE when (BREG_IN = 2) else '0';
   CEB2_IN <=  CE when (BREG_IN = 1 or BREG_IN = 2) else '0';

   ALUMODE_IN <= "00" & (not (ADDSUB)) & (not (ADDSUB));
 
   v : if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
   OPMODE_IN <= "01" & LOAD & "0101";
   end generate v;

   s : if (DEVICE = "SPARTAN6") generate
   OPMODE_IN <= (not (ADDSUB)) & (not (ADDSUB)) & "001" & LOAD & "01";
   end generate s;

  load1 : if (WIDTH_P = 48) generate
    begin
      LOAD_DATA_IN <= LOAD_DATA;
    end generate load1;
  load2 : if (WIDTH_P < 48) generate
    begin
      l1: for i in 47 downto WIDTH_P generate
            LOAD_DATA_IN(i) <= '0';
          end generate;
            LOAD_DATA_IN(WIDTH_P-1 downto 0) <= LOAD_DATA;
   end generate load2;

  multa : if (WIDTH_A = MaxWidthA) generate
    begin 
      A_INP((MaxWidthA-1) downto 0) <= A;
      A_IN <= "00000" & A_INP;
    end generate multa;
  multb : if (WIDTH_B = 18) generate
    begin 
      B_IN <= B;
    end generate multb;
  multas : if (WIDTH_A < MaxWidthA) generate
    begin 
      sa: for i in (MaxWidthA-1) downto WIDTH_A generate
            A_INP(i) <= A((WIDTH_A-1));
          end generate;
            A_INP(WIDTH_A-1 downto 0) <= A;
            A_IN <= "00000" & A_INP;
    end generate multas;
  multbs : if (WIDTH_B < 18) generate
    begin 
      sb: for i in 17 downto WIDTH_B generate
            B_IN(i) <= B((WIDTH_B-1));
          end generate;
            B_IN(WIDTH_B-1 downto 0) <= B;
    end generate multbs;

  P <= RESULT_OUT(WIDTH_P-1 downto 0);

  -- begin generate virtex5
  v5 : if DEVICE = "VIRTEX5" generate
    v5_1 : if ((LATENCY >= 0) and (LATENCY <= 2)) generate
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
          A => A_IN,          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => B_IN,          
          BCIN => "000000000000000000",    
          C => LOAD_DATA_IN,           
          CARRYCASCIN => '0', 
          CARRYIN => CARRYIN, 
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
          CEMULTCARRYIN => CE,
          CEP => CE,       
          CLK => CLK,       
          MULTSIGNIN => '0', 
          OPMODE => OPMODE_IN(6 downto 0), 
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
    v5_2 : if ((LATENCY =3) or (LATENCY = 4)) generate
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
          A => A_IN,          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => B_IN,          
          BCIN => "000000000000000000",    
          C => LOAD_DATA_IN,           
          CARRYCASCIN => '0', 
          CARRYIN => CARRYIN, 
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
          CEMULTCARRYIN => CE,
          CEP => CE,       
          CLK => CLK,       
          MULTSIGNIN => '0', 
          OPMODE => OPMODE_IN(6 downto 0), 
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
          BCASCREG => BREG_IN,       
          BREG => BREG_IN,           
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
          A => A_IN,          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => ALUMODE_IN, 
          B => B_IN,          
          BCIN => "000000000000000000",    
          C => LOAD_DATA_IN,           
          CARRYCASCIN => '0', 
          CARRYIN => CARRYIN, 
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
          OPMODE => OPMODE_IN(6 downto 0), 
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
            M => open, 
            P => RESULT_OUT,          
            PCOUT => open,  
            A => A_IN(17 downto 0),          
            B => B_IN,          
            C => LOAD_DATA_IN,           
            CARRYIN => CARRYIN, 
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
end macc;



