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
-- /___/   /\     Filename : ADDMACC_MACRO.vhd
-- \   \  /  \
--  \___\/\___\
--
-- Revision:
--    04/18/08 - Initial version.
--    04/09/15 - 852167 - align with verilog
-- End Revision

----- CELL ADDMACC_MACRO -----

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.vcomponents.all;

library STD;
use STD.TEXTIO.ALL;


entity ADDMACC_MACRO is
  generic ( 
            DEVICE : string := "VIRTEX6";
            LATENCY : integer := 4;
            WIDTH_PREADD : integer := 25;
            WIDTH_MULTIPLIER : integer := 18;
            WIDTH_PRODUCT : integer := 48
       );

  port (
      PRODUCT : out std_logic_vector(WIDTH_PRODUCT-1 downto 0);
      CARRYIN : in std_logic;  
      CE : in std_logic;
      CLK : in std_logic;   
      MULTIPLIER : in std_logic_vector(WIDTH_MULTIPLIER-1 downto 0);   
      LOAD : in std_logic;   
      LOAD_DATA : in std_logic_vector(WIDTH_PRODUCT-1 downto 0);
      PREADD1 : in std_logic_vector(WIDTH_PREADD-1 downto 0);
      PREADD2 : in std_logic_vector(WIDTH_PREADD-1 downto 0);
      RST : in std_logic
     );   
end entity ADDMACC_MACRO;

architecture addmacc of ADDMACC_MACRO is
  function CheckDevice (
    device : in string
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;

  begin
    if (DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute DEVICE : ") );
      write ( Message, DEVICE);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" VIRTEX6, SPARTAN6, 7SERIES. ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;
  function CheckWidthPreadd (
    width : in integer;
    device : in string
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if (width > 0 and width <= 25) then
      func_val := true;
      else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute WIDTH_PREADD : ") );
      write ( Message, WIDTH_PREADD);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 25 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      end if;
    -- begin s1
    else
      if (DEVICE = "SPARTAN6" and width > 0 and width <= 18) then
      func_val := true;
      else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute WIDTH_PREADD : ") );
      write ( Message, WIDTH_PREADD);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 18 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      end if;
    -- end s1
    end if;
    return func_val;
  end;
  function GetWidthPreadd (
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

  function CheckWidthMult (
    width : in integer
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (width > 0 and width <= 18 ) then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute WIDTH_MULTPLIER : ") );
      write ( Message, WIDTH_MULTIPLIER);
      write( Message, STRING'(". Legal values of this attribute are ") );
      write( Message, STRING'(" 1 to 18 ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return func_val;
  end;
  function CheckWidthProd (
    width : in integer
    ) return boolean is
    variable func_val : boolean;
    variable Message : LINE;
  begin
    if (width > 0 and width <= 48 ) then
      func_val := true;
    else
      func_val := false;
      write( Message, STRING'("Illegal value of Attribute WIDTH_PRODUCT : ") );
      write ( Message, WIDTH_PRODUCT);
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
   constant ChkWidthPreAdd : boolean := CheckWidthPreAdd(WIDTH_PREADD, DEVICE);
   constant MaxWidthPreAdd : integer := GetWidthPreAdd(DEVICE);
   constant ChkWidthMult : boolean := CheckWidthMult(WIDTH_MULTIPLIER);
   constant ChkWidthProd : boolean := CheckWidthProd(WIDTH_PRODUCT);
   constant AREG_IN : integer := GetABREG_IN(LATENCY);
   constant BREG_IN : integer := GetABREG_IN(LATENCY);
   constant A0REG_IN : integer := GetABREG0_IN(LATENCY);
   constant B0REG_IN : integer := GetABREG0_IN(LATENCY);
   constant A1REG_IN : integer := GetABREG1_IN(LATENCY);
   constant B1REG_IN : integer := GetABREG1_IN(LATENCY);
   constant MREG_IN : integer := GetMREG_IN(LATENCY);
   constant PREG_IN : integer := GetPREG_IN(LATENCY);

   signal OPMODE_IN :  std_logic_vector((OPMODE_WIDTH-1) downto 0);
   signal PREADD1_IN :  std_logic_vector(29 downto 0) := "000000000000000000000000000000";
   signal PREADD2_IN :  std_logic_vector(24 downto 0) := "0000000000000000000000000";
   signal MULTIPLIER_IN :  std_logic_vector(17 downto 0) := "000000000000000000";
   signal LOAD_DATA_IN :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
   signal RESULT_OUT :  std_logic_vector(47 downto 0) := "000000000000000000000000000000000000000000000000";
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

   v : if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
         OPMODE_IN <= "01" & LOAD & "0101";
   end generate v;

   s : if (DEVICE = "SPARTAN6") generate
          OPMODE_IN <= "00011" & LOAD & "01";
   end generate s;

    load1 : if (WIDTH_PRODUCT = 48) generate
     begin
       LOAD_DATA_IN <= LOAD_DATA;
     end generate load1;
   load2 : if (WIDTH_PRODUCT < 48) generate
     begin
       l1: for i in 47 downto WIDTH_PRODUCT generate
             LOAD_DATA_IN(i) <= '0';
           end generate;
             LOAD_DATA_IN(WIDTH_PRODUCT-1 downto 0) <= LOAD_DATA;
     end generate load2;

  pa1 : if (WIDTH_PREADD = MaxWidthPreAdd) generate
    begin 
      PREADD1_IN(MaxWidthPreAdd-1 downto 0) <= PREADD1;
      PREADD2_IN(MaxWidthPreAdd-1 downto 0) <= PREADD2;
    end generate pa1;
  mult1 : if (WIDTH_MULTIPLIER = 18) generate
    begin 
      MULTIPLIER_IN <= MULTIPLIER;
    end generate mult1;
  pa2 : if (WIDTH_PREADD < MaxWidthPreAdd) generate
    begin 
      pa: for i in MaxWidthPreAdd-1 downto WIDTH_PREADD generate
            PREADD1_IN(i) <= PREADD1((WIDTH_PREADD-1));
            PREADD2_IN(i) <= PREADD2((WIDTH_PREADD-1));
          end generate;
            PREADD1_IN(WIDTH_PREADD-1 downto 0) <= PREADD1;
            PREADD2_IN(WIDTH_PREADD-1 downto 0) <= PREADD2;
    end generate pa2;
  mult2 : if (WIDTH_MULTIPLIER < 18) generate
    begin 
      m1: for i in 17 downto WIDTH_MULTIPLIER generate
            MULTIPLIER_IN(i) <= MULTIPLIER((WIDTH_MULTIPLIER-1));
          end generate;
            MULTIPLIER_IN(WIDTH_MULTIPLIER-1 downto 0) <= MULTIPLIER;
    end generate mult2;

  PRODUCT <= RESULT_OUT(WIDTH_PRODUCT-1 downto 0);

  -- begin generate virtex6
  bl : if (DEVICE = "VIRTEX6"  or DEVICE = "7SERIES") generate
    begin
      DSP48E_1: DSP48E1 
        generic map (
          ACASCREG => AREG_IN,       
          AREG => AREG_IN,   
          BCASCREG => BREG_IN,       
          BREG => BREG_IN,           
          MREG => MREG_IN,      
          PREG => PREG_IN,           
          USE_DPORT => TRUE) 
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
          A => PREADD1_IN,          
          ACIN => "000000000000000000000000000000",    
          ALUMODE => "0000", 
          B => MULTIPLIER_IN,          
          BCIN => "000000000000000000",    
          C => LOAD_DATA_IN,           
          CARRYCASCIN => '0', 
          CARRYIN => CARRYIN, 
          CARRYINSEL => "000", 
          CEA1 => CEA1_IN,      
          CEA2 => CEA2_IN,      
          CEAD => CE,
          CEALUMODE => CE, 
          CEB1 => CEB1_IN,      
          CEB2 => CEB2_IN,      
          CEC => CE,      
          CECARRYIN => CE, 
          CECTRL => CE,
          CED => CE,
          CEINMODE => CE, 
          CEM => CE,       
          CEP => CE,       
          CLK => CLK,       
          D => PREADD2_IN,
          INMODE => "00100", 
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
        DSP48E_2: DSP48A1 
        generic map (
          A0REG => A0REG_IN,   
          A1REG => A1REG_IN,   
          B0REG => B0REG_IN,           
          B1REG => B1REG_IN,           
          MREG => MREG_IN,      
          PREG => PREG_IN )           
       port map ( 
          BCOUT => open,  
          CARRYOUT => open, 
          CARRYOUTF => open, 
          M => open, 
          P => RESULT_OUT,          
          PCOUT => open,  
          A => MULTIPLIER_IN,          
          B => PREADD1_IN(17 downto 0),          
          C => LOAD_DATA_IN,           
          CARRYIN => CARRYIN, 
          CEA => CE,      
          CEB => CE,      
          CEC => CE,      
          CECARRYIN => '0', 
          CED => CE,
          CEM => CE,       
          CEOPMODE => CE, 
          CEP => CE,       
          CLK => CLK,       
          D => PREADD2_IN(17 downto 0),
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


end addmacc;



