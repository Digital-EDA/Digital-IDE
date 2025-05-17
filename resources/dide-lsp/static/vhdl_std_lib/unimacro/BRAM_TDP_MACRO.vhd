-------------------------------------------------------------------------------
-- Copyright (c) 1995/2007 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 14.1
--  \   \         Description : Xilinx Functional Simulation Library Component
--  /   /                  Macro for True Dual Port Block RAM
-- /___/   /\     Filename : BRAM_TDP_MACRO.vhd
-- \   \  /  \    Timestamp : Wed April 11 10:43:59 PST 2008
--  \___\/\___\
--
-- Revision:
--    04/11/08 - Initial version.
--    05/25/11 - 607722 - Reset output latch for DO_REG=1
--    10/26/11 - 624543 - Fix DO for assymetric widths, drc to check for read,write widths equal or ratio of 2.
--    11/30/11 - 636062 - Fix drc and do
--    01/11/12 - 639772, 604428 -Constrain DI, DO, add width checking.
--    04/24/12 - 657517 - fix for write_width = 2* read_width
--    11/01/12 - 679413 - pass INIT_FILE to Spartan6 BRAM
--    09/29/14 - Update DI and DO for parity intersperse every byte (CR 773917).
-- End Revision

----- CELL BRAM_TDP_MACRO -----

library IEEE;
use IEEE.STD_LOGIC_1164.all;
library unisim;
use unisim.VCOMPONENTS.all;
library STD;
use STD.TEXTIO.ALL;


entity BRAM_TDP_MACRO is
generic (
    BRAM_SIZE : string := "18Kb";
    DEVICE : string := "VIRTEX5";
    DOA_REG : integer := 0;
    DOB_REG : integer := 0;
    INITP_00 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_01 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_02 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_03 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_04 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_05 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_06 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_07 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_08 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_09 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INITP_0F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_00 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_01 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_02 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_03 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_04 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_05 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_06 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_07 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_08 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_09 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_0F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_10 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_11 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_12 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_13 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_14 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_15 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_16 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_17 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_18 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_19 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_1F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_20 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_21 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_22 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_23 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_24 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_25 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_26 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_27 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_28 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_29 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_2F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_30 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_31 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_32 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_33 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_34 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_35 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_36 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_37 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_38 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_39 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_3F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_40 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_41 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_42 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_43 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_44 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_45 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_46 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_47 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_48 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_49 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_4F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_50 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_51 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_52 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_53 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_54 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_55 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_56 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_57 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_58 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_59 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_5F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_60 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_61 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_62 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_63 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_64 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_65 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_66 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_67 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_68 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_69 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_6F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_70 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_71 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_72 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_73 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_74 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_75 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_76 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_77 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_78 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_79 : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7A : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7B : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7C : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7D : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7E : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_7F : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
    INIT_A : bit_vector := X"000000000";
    INIT_B : bit_vector := X"000000000";
    INIT_FILE : string := "NONE";
    READ_WIDTH_A : integer := 1;
    READ_WIDTH_B : integer := 1;
    SIM_COLLISION_CHECK : string := "ALL";
    SIM_MODE : string := "SAFE";  -- This parameter is valid only for Virtex5
    SRVAL_A : bit_vector := X"000000000";
    SRVAL_B : bit_vector := X"000000000";
    WRITE_MODE_A : string := "WRITE_FIRST";
    WRITE_MODE_B : string := "WRITE_FIRST";
    WRITE_WIDTH_A : integer := 1;
    WRITE_WIDTH_B : integer := 1
    
  );
port (
  
    DOA : out std_logic_vector(READ_WIDTH_A-1 downto 0);
    DOB : out std_logic_vector(READ_WIDTH_B-1 downto 0);
    
    ADDRA : in std_logic_vector;
    ADDRB : in std_logic_vector;
    CLKA : in std_ulogic;
    CLKB : in std_ulogic;
    DIA : in std_logic_vector(WRITE_WIDTH_A-1 downto 0);
    DIB : in std_logic_vector(WRITE_WIDTH_B-1 downto 0);
    ENA : in std_ulogic;
    ENB : in std_ulogic;
    REGCEA : in std_ulogic;
    REGCEB : in std_ulogic;
    RSTA : in std_ulogic;
    RSTB : in std_ulogic;
    WEA : in std_logic_vector;
    WEB : in std_logic_vector

  );
end BRAM_TDP_MACRO;
                                                                        
architecture bram_V of BRAM_TDP_MACRO is

  function GetDIAWidth (
    wr_widtha : in integer;
    func_bram_size : in string;
    device : in string
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case wr_widtha is
        when 0 => func_width := 1;
                  write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_A : ") );
                  write ( Message, WRITE_WIDTH_A);
                  write( Message, STRING'(". This attribute must atleast be equal to 1. ") );
                  ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                  DEALLOCATE (Message);
        when 1 => func_width := 1;
        when 2 => func_width := 2;
        when 3|4 => func_width := 4;
        when 5|6|7|8|9 => func_width := 8;
        when 10 to 18 => func_width := 16;
        when 19 to 36 => if (func_bram_size /= "36Kb" and (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") ) then
                         write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_A : ") );
                         write ( Message, WRITE_WIDTH_A);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 18Kb are ") );
                         write( Message, STRING'(" 1 to 18 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                         -- begin s1
                         elsif (func_bram_size /= "18Kb" and (DEVICE = "SPARTAN6") ) then
                         write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_A : ") );
                         write ( Message, WRITE_WIDTH_A);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 9Kb are ") );
                         write( Message, STRING'(" 1 to 18 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message); -- end s1
                        else 
                         func_width := 32;
                        end if;
        when others => if(func_bram_size = "18Kb" or func_bram_size = "9Kb") then
                       func_width := 16;
                       else
                       func_width := 32;
                       end if;
                       if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
                       write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_A : ") );
                       write ( Message, WRITE_WIDTH_A);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 18 for BRAM_SIZE of 18Kb and ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 36Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message);
                       -- begin s2
                       elsif(DEVICE = "SPARTAN6") then
                       write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_A : ") );
                       write ( Message, WRITE_WIDTH_A);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 18 for BRAM_SIZE of 9Kb and ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 18Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message); -- end s2
                       end if;
      end case;
    else 
      func_width := 32;
    end if;
    return func_width;
  end;

 function GetDIBWidth (
    wr_widthb : in integer;
    func_bram_size : in string;
    device : in string
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case wr_widthb is
        when 0 => func_width := 1;
                  write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_B : ") );
                  write ( Message, WRITE_WIDTH_B);
                  write( Message, STRING'(". This attribute must atleast be equal to 1 .") );
                  ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                  DEALLOCATE (Message);
        when 1 => func_width := 1;
        when 2 => func_width := 2;
        when 3|4 => func_width := 4;
        when 5|6|7|8|9 => func_width := 8;
        when 10 to 18 => func_width := 16;
        when 19 to 36 => if (func_bram_size /= "36Kb" and (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") ) then
                         write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_B : ") );
                         write ( Message, WRITE_WIDTH_B);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 18Kb are ") );
                         write( Message, STRING'(" 1 to 18 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                         -- begin s3
                         elsif (func_bram_size /= "18Kb" and (DEVICE = "SPARTAN6") ) then
                         write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_B : ") );
                         write ( Message, WRITE_WIDTH_B);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 9Kb are ") );
                         write( Message, STRING'(" 1 to 18 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message); -- end s3
                        else
                        func_width := 32;
                      end if;
        when others => if(func_bram_size = "18Kb" or func_bram_size = "9Kb") then
                       func_width := 16;
                       else
                         func_width := 32;
                       end if;
                       if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
                       write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_A : ") );
                       write ( Message, WRITE_WIDTH_B);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 18 for BRAM_SIZE of 18Kb and ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 36Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message); 
                       -- begin s4
                       elsif(DEVICE = "SPARTAN6") then
                       write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH_A : ") );
                       write ( Message, WRITE_WIDTH_B);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 18 for BRAM_SIZE of 9Kb and ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 18Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message); -- end s4
                       end if;

      end case;
    else 
      func_width := 32;
    end if;
    return func_width;
  end;

  function GetDOAWidth (
    rd_widtha : in integer;
    func_bram_size : in string;
    device : in string;
    wr_widtha : in integer
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      -- begin s26
      if(DEVICE = "SPARTAN6") then
        if(rd_widtha /= wr_widtha) then
          write( Message, STRING'("WRITE_WIDTH_A and READ_WIDTH_A must be equal. ") );
          write ( Message, WRITE_WIDTH_A);
          write ( Message, READ_WIDTH_A);
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message); 
        end if;
      end if; -- end s26
      if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
        if((rd_widtha /= wr_widtha) and (rd_widtha/wr_widtha /=2) and (wr_widtha/rd_widtha /=2) and ( (rd_widtha /= 1 and rd_widtha /= 2 and rd_widtha /= 4 and rd_widtha /= 8 and rd_widtha /= 9 and rd_widtha /= 16 and rd_widtha /= 18 and rd_widtha /= 32 and rd_widtha /= 36) or (wr_widtha /= 1 and wr_widtha /= 2 and wr_widtha /= 4 and wr_widtha /= 8 and wr_widtha /= 9 and wr_widtha /= 16 and wr_widtha /= 18 and wr_widtha /= 32 and wr_widtha /= 36)) ) then
	  write( Message, STRING'("Illegal values of Attributes  READ_WIDTH_A, WRITE_WIDTH_A : ") );
          write ( Message, READ_WIDTH_A);
          write ( Message, STRING'(" and "));
          write ( Message, WRITE_WIDTH_A);
          write( Message, STRING'(". To use BRAM_TDP_MACRO. One of the following conditions must be true- 1. READ_WIDTH must be equal to WRITE_WIDTH  2. If assymetric, READ_WIDTH and WRITE_WIDTH must have a ratio of 2. 3. If assymetric, READ_WIDTH and WRITE_WIDTH should have values 1, 2, 4, 8, 9, 16, 18, 32, 36."));
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message); 
        end if;
      end if;
      case rd_widtha is
        when 0 => func_width := 1;
                   write( Message, STRING'("Illegal value of Attribute READ_WIDTH_A : ") );
                   write ( Message, READ_WIDTH_A);
                   write( Message, STRING'(". This attribute must atleast be equal to 1 . ") );
                   ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                   DEALLOCATE (Message);
        when 1 => func_width := 1;
        when 2 => func_width := 2;
        when 3|4 => func_width := 4;
        when 5|6|7|8|9 => func_width := 8;
        when 10 to 18 => func_width := 16;
        when 19 to 36 => if (func_bram_size /= "36Kb" and (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES")) then
                         write( Message, STRING'("Illegal value of Attribute READ_WIDTH_A : ") );
                         write ( Message, READ_WIDTH_A);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 18Kb are ") );
                         write( Message, STRING'(" 1 to 18 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                         -- begin s5
                         elsif (func_bram_size /= "18Kb" and (DEVICE = "SPARTAN6") ) then
                         write( Message, STRING'("Illegal value of Attribute READ_WIDTH_A : ") );
                         write ( Message, READ_WIDTH_A);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 9Kb are ") );
                         write( Message, STRING'(" 1 to 18 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);  -- end s5                
                         else
                         func_width := 32;
                      end if;
        when others => if(func_bram_size = "18Kb" or func_bram_size = "9Kb") then
                         func_width := 16;
                       else
                         func_width := 32;
                       end if;
                       if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
                       write( Message, STRING'("Illegal value of Attribute READ_WIDTH_A : ") );
                       write ( Message, READ_WIDTH_A);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 18 for BRAM_SIZE of 18Kb and ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 36Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message);
                       -- begin s6
                       elsif(DEVICE = "SPARTAN6") then
                       write( Message, STRING'("Illegal value of Attribute READ_WIDTH_A : ") );
                       write ( Message, READ_WIDTH_A);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 18 for BRAM_SIZE of 9Kb and ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 18Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message); -- end s6
                       end if;
      end case;
    else 
      func_width := 32;
    end if;
    return func_width;
  end;

 function GetDOBWidth (
    rd_widthb : in integer;
    func_bram_size : in string;
    device : in string;
    wr_widthb : in integer
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      -- begin s27
      if(DEVICE = "SPARTAN6") then
        if(rd_widthb /= wr_widthb) then
          write( Message, STRING'("WRITE_WIDTH_B and READ_WIDTH_B must be equal. ") );
          write ( Message, WRITE_WIDTH_B);
          write ( Message, READ_WIDTH_B);
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message); 
        end if;
      end if; -- end s27
      if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
        if((rd_widthb /= wr_widthb) and (rd_widthb/wr_widthb /= 2) and (wr_widthb/rd_widthb /= 2) and ((rd_widthb /= 1 and rd_widthb /= 2 and rd_widthb /= 4 and rd_widthb /= 8 and rd_widthb /= 9 and rd_widthb /= 16 and rd_widthb /= 18 and rd_widthb /= 32 and rd_widthb /= 36 ) or (wr_widthb /= 1 and wr_widthb /= 2 and wr_widthb /= 4 and wr_widthb /= 8 and wr_widthb /= 9 and wr_widthb /= 16 and wr_widthb /= 18 and wr_widthb /= 32 and wr_widthb /= 36)) ) then
	  write( Message, STRING'("Illegal values of Attributes  READ_WIDTH_B, WRITE_WIDTH_B : ") );
          write ( Message, READ_WIDTH_B);
          write ( Message, STRING'(" and "));
          write ( Message, WRITE_WIDTH_B);
          write( Message, STRING'(". To use BRAM_TDP_MACRO. One of the following conditions must be true- 1. READ_WIDTH must be equal to WRITE_WIDTH  2. If assymetric, READ_WIDTH and WRITE_WIDTH must have a ratio of 2. 3. If assymetric, READ_WIDTH and WRITE_WIDTH should have values 1, 2, 4, 8, 9, 16, 18, 32, 36.") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message); 
        end if;
      end if;
      case rd_widthb is
        when 0 => func_width := 1;
                  write( Message, STRING'("Illegal value of Attribute READ_WIDTH_B : ") );
                  write ( Message, READ_WIDTH_B);
                  write( Message, STRING'(". This attribute must atleast be equal to 1 .") );
                  ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                  DEALLOCATE (Message);
        when 1 => func_width := 1;
        when 2 => func_width := 2;
        when 3|4 => func_width := 4;
        when 5|6|7|8|9 => func_width := 8;
        when 10 to 18 => func_width := 16;
        when 19 to 36 => if (func_bram_size /= "36Kb" and (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES")) then
                         write( Message, STRING'("Illegal value of Attribute READ_WIDTH_B : ") );
                         write ( Message, READ_WIDTH_B);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 18Kb are ") );
                         write( Message, STRING'(" 1 to 18 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                        -- begin s7
                         elsif (func_bram_size /= "18Kb" and (DEVICE = "SPARTAN6") ) then
                         write( Message, STRING'("Illegal value of Attribute READ_WIDTH_B : ") );
                         write ( Message, READ_WIDTH_B);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 9Kb are ") );
                         write( Message, STRING'(" 1 to 18 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message); -- end s7
                         else
                          func_width := 32;
                        end if;
        when others => if(func_bram_size = "18Kb" or func_bram_size = "9Kb") then
                         func_width := 16;
                       else
                         func_width := 32;
                       end if;
                       if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
                       write( Message, STRING'("Illegal value of Attribute READ_WIDTH_B : ") );
                       write ( Message, READ_WIDTH_B);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 18 for BRAM_SIZE of 18Kb and ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 36Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message);
                       -- begin s8
                       elsif(DEVICE = "SPARTAN6") then
                       write( Message, STRING'("Illegal value of Attribute READ_WIDTH_B : ") );
                       write ( Message, READ_WIDTH_B);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 18 for BRAM_SIZE of 9Kb and ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 18Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message); -- end s8
                       end if;
      end case;
    else 
      func_width := 32;
    end if;
    return func_width;
  end;
 function GetD_Width (
    width : in integer;
    device : in string
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case width is
        when 0 => func_width := 0;
        when 1 => func_width := 1;
        when 2 => func_width := 2;
        when 3|4 => func_width := 4;
        when 5|6|7|8|9 => func_width := 9;
        when 10 to 18 => func_width := 18;
        when 19 to 36 => func_width := 36;
        when others => func_width := 1;
      end case;
    else 
      func_width := 1;
    end if;
    return func_width;
  end;

  function GetDPWidth (
    width : in integer;
    func_bram_size : in string;
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case width is
        when 9 => func_width := 1;
        when 17 => func_width := 1;
        when 18 => func_width := 2;
        when 33 => func_width := 1;
        when 34 => func_width := 2;
        when 35 => func_width := 3;
        when 36 => func_width := 4;
        when others => func_width := 0;
      end case;
    else 
      func_width := 0;
    end if;
  return func_width;
  end;
  function GetLeastWidthA (
    wr_width_a : in integer;
    rd_width_a : in integer
    ) return integer is
    variable func_least_width : integer;
  begin
    if (wr_width_a <= rd_width_a) then
      func_least_width := wr_width_a;
    else
      func_least_width := rd_width_a;
    end if;
    return func_least_width;
  end;

 function GetLeastWidthB (
    wr_width_b : in integer;
    rd_width_b : in integer
    ) return integer is
    variable func_least_width : integer;
  begin
    if (wr_width_b <= rd_width_b) then
      func_least_width := wr_width_b;
    else
      func_least_width := rd_width_b;
    end if;
    return func_least_width;
  end;

 function GetADDRWidth (
    least_width : in integer;
    func_bram_size : in string;
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case least_width is
        when 1 => if (func_bram_size = "9Kb") then
                    func_width := 13;
                  elsif (func_bram_size = "18Kb") then
                    func_width := 14;
                  else
                    func_width := 15;
                  end if;
        when 2 => if (func_bram_size = "9Kb") then
                    func_width := 12;
                  elsif (func_bram_size = "18Kb") then
                    func_width := 13;
                  else
                    func_width := 14;
                  end if;
        when 3|4 => if (func_bram_size = "9Kb") then
                    func_width := 11;
                    elsif (func_bram_size = "18Kb") then
                      func_width := 12;
                    else
                      func_width := 13;
                    end if;
        when 5|6|7|8|9 => if (func_bram_size = "9Kb") then
                    func_width := 10;
                    elsif (func_bram_size = "18Kb") then
                      func_width := 11;
                    else
                      func_width := 12;
                    end if;
        when 10 to 18 => if (func_bram_size = "9Kb") then
                    func_width := 9;
                   elsif (func_bram_size = "18Kb") then
                     func_width := 10;
                   else
                     func_width := 11;
                   end if;
        when 19 to 36 => if (func_bram_size = "36Kb") then
                     func_width := 10;
                   elsif (func_bram_size = "18Kb") then
                     func_width := 9;
                   else
                     func_width := 9;
                   end if;
        when others => func_width := 15;
      end case;
    else 
      func_width := 15;
    end if;
    return func_width;
  end;

  function GetWEWidth (
    bram_size : in string;
    device : in string;
    wr_width : in integer
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if bram_size= "18Kb"then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        else
          func_width := 2;
        end if;
      elsif bram_size = "36Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        else
          func_width := 4;
        end if;
      end if;
    -- begin s9
    elsif(DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        else
          func_width := 2;
        end if;
      elsif bram_size = "18Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        else
          func_width := 4;
        end if; 
      end if; -- end s9
    else 
      func_width := 4;
    end if;
    return func_width;
  end;
   
  function GetMaxADDRSize (
    bram_size : in string; 
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      if bram_size = "9Kb" then
        func_width := 13;
      elsif bram_size = "18Kb" then
        func_width := 14;
      elsif bram_size = "36Kb" then
        func_width := 16;
      else
        func_width := 16;
      end if;
    else 
      func_width := 16;
    end if;
    return func_width;
  end;

  function GetMaxDataSize (
    bram_size : in string; 
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if (bram_size = "18Kb" or bram_size = "9Kb") then
        func_width := 16;
      elsif bram_size = "36Kb" then
        func_width := 32;
      else
        func_width := 32;
      end if;
    -- begin s11
    elsif (DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" then
        func_width := 16;
      elsif bram_size = "18Kb" then
        func_width := 32;
      else
        func_width := 32;
      end if; -- end s11
    else 
      func_width := 32;
    end if;
    return func_width;
  end;

   function GetMaxDataPSize (
    bram_size : in string; 
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if (bram_size = "18Kb" or bram_size = "9Kb") then
        func_width := 2;
      elsif bram_size = "36Kb" then
        func_width := 4;
      else
        func_width := 4;
      end if;
    -- begin s12
    elsif (DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" then
        func_width := 2;
      elsif bram_size = "18Kb" then
        func_width := 4;
      else
        func_width := 4;
      end if; -- end s12
    else 
      func_width := 4;
    end if;
    return func_width;
  end;

  function GetMaxWESize (
    bram_size : in string; 
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if (bram_size = "18Kb" or bram_size = "9Kb") then
        func_width := 2;
      elsif bram_size = "36Kb" then
        func_width := 4;
      else
        func_width := 4;
      end if;
    -- begin s13
    elsif (DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" then
        func_width := 2;
      elsif bram_size = "18Kb" then
        func_width := 4;
      else
        func_width := 4;
      end if; -- end s13
    else 
      func_width := 4;
    end if;
    return func_width;
  end;

 function GetMaxWESize_bl (
    bram_size : in string; 
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
      if bram_size = "18Kb" then
        func_width := 4;
      elsif bram_size = "36Kb" then
        func_width := 8;
      else
        func_width := 8;
      end if;
    return func_width;
  end;
  function GetFinalWidth (
    width : in integer
    ) return integer is
    variable func_least_width : integer;
  begin
    if (width = 0) then
      func_least_width := 1;
    else
      func_least_width := width;
    end if;
    return func_least_width;
  end;

  function GetBRAMSize (
    bram_size : in string; 
    device : in string
    ) return boolean is
    variable bram_val : boolean;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
        bram_val := TRUE;
    else 
        bram_val := FALSE;
        write( Message, STRING'("Illegal value of Attribute DEVICE : ") );
        write ( Message, DEVICE);
        write( Message, STRING'(". Legal values of this attribute are ") );
        write( Message, STRING'(" VIRTEX5, VIRTEX6, SPARTAN6, 7SERIES. ") );
        ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
        DEALLOCATE (Message);
    end if;

    if ( DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then 
       if (bram_size = "18Kb" or bram_size = "36Kb") then
        bram_val := TRUE;
       else
        bram_val := FALSE;
        write( Message, STRING'("Illegal value of Attribute BRAM_SIZE : ") );
        write ( Message, BRAM_SIZE);
        write( Message, STRING'(". Legal values of this attribute are ") );
        write( Message, STRING'(" 18Kb, 36Kb ") );
        ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
        DEALLOCATE (Message);
      end if;
   end if;
   -- begin s14
   if (DEVICE = "SPARTAN6") then
       if(bram_size = "9Kb" or bram_size = "18Kb") then
        bram_val := TRUE;
       else
        bram_val := FALSE;
        write( Message, STRING'("Illegal value of Attribute BRAM_SIZE : ") );
        write ( Message, BRAM_SIZE);
        write( Message, STRING'(". Legal values of this attribute are ") );
        write( Message, STRING'(" 9Kb, 18Kb ") );
        ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
        DEALLOCATE (Message); 
      end if; 
  end if; -- end s14
    return bram_val;
  end;

  function Get_P (
    wd : in integer;
    device : in string
    ) return boolean is
    variable wp : boolean;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      if wd = 9 or wd = 17 or wd = 18 or wd = 33 or wd = 34 or wd = 35 or wd = 36 then
        wp := TRUE;
      else
        wp := FALSE;
      end if;
    else
        wp := FALSE;
    end if;
    return wp;
  end;
   
  function CheckParity (
  wp_a, wp_b, rp_a, rp_b : in boolean;
    device : in string
  ) return boolean is
  variable Message : LINE;
  variable check : boolean;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      if ( (wp_a = FALSE and wp_b = FALSE and rp_a = FALSE and rp_b = FALSE) or  (wp_a = FALSE and wp_b = TRUE and rp_a = TRUE and rp_b = FALSE)  or (wp_a = TRUE and wp_b = FALSE and rp_a = TRUE and rp_b = FALSE) or (wp_a = FALSE and wp_b = TRUE and rp_a = FALSE and rp_b = TRUE) or (wp_a = TRUE and wp_b = FALSE and rp_a = FALSE and rp_b = TRUE) or (wp_a = TRUE and wp_b = TRUE and rp_a = FALSE and rp_b = TRUE) or (wp_a = TRUE and wp_b = TRUE and rp_a = TRUE and rp_b = FALSE) or (wp_a = TRUE and wp_b = FALSE and rp_a = TRUE and rp_b = TRUE) or (wp_a = FALSE and wp_b = TRUE and rp_a = TRUE and rp_b = TRUE) or (wp_a = TRUE and wp_b = TRUE and rp_a = TRUE and rp_b = TRUE) ) then 
        check := FALSE;
        elsif(wp_a = FALSE and wp_b = TRUE and rp_a = FALSE and rp_b = FALSE) then
          write( Message, STRING'("Port Width Mismatch : ") );
          write( Message, STRING'("The attribute ") );
          write( Message, STRING'("WRITE_WIDTH_B on BRAM_TDP_MACRO is set to ") );
          write( Message, WRITE_WIDTH_B);
          write( Message, STRING'(". The parity bit(s) cannot be read") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Warning;
          DEALLOCATE (Message);
        elsif(wp_a = TRUE and wp_b = FALSE and rp_a = FALSE and rp_b = FALSE) then
          write( Message, STRING'("Port Width Mismatch : ") );
          write( Message, STRING'("The attribute ") );
          write( Message, STRING'("WRITE_WIDTH_A on BRAM_TDP_MACRO is set to ") );
          write( Message, WRITE_WIDTH_A);
          write( Message, STRING'(". The parity bit(s) cannot be read") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Warning;
          DEALLOCATE (Message);
         elsif(wp_a = TRUE and wp_b = TRUE and rp_a = FALSE and rp_b = FALSE) then
          write( Message, STRING'("Port Width Mismatch : ") );
          write( Message, STRING'("The attribute ") );
          write( Message, STRING'("WRITE_WIDTH_A on BRAM_TDP_MACRO is set to ") );
          write( Message, WRITE_WIDTH_A);
          write( Message, STRING'(" and WRITE_WIDTH_B on BRAM_TDP_MACRO is set to ") );
          write( Message, WRITE_WIDTH_B);
          write( Message, STRING'(". The parity bit(s) cannot be read") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Warning;
          DEALLOCATE (Message);
         elsif(wp_a = FALSE and wp_b = FALSE and rp_a = TRUE and rp_b = FALSE) then
          write( Message, STRING'("Port Width Mismatch : ") );
          write( Message, STRING'("The attribute ") );
          write( Message, STRING'("READ_WIDTH_A on BRAM_TDP_MACRO is set to ") );
          write( Message, READ_WIDTH_A);
          write( Message, STRING'(". The parity bit(s) have not been written and hence cannot be read") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Warning;
          DEALLOCATE (Message);
        elsif(wp_a = FALSE and wp_b = FALSE and rp_a = FALSE and rp_b = TRUE) then
          write( Message, STRING'("Port Width Mismatch : ") );
          write( Message, STRING'("The attribute ") );
          write( Message, STRING'("READ_WIDTH_B on BRAM_TDP_MACRO is set to ") );
          write( Message, READ_WIDTH_B);
          write( Message, STRING'(". The parity bit(s) have not been written and hence cannot be read") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Warning;
          DEALLOCATE (Message);
      elsif(wp_a = FALSE and wp_b = FALSE and rp_a = TRUE and rp_b = TRUE) then
          write( Message, STRING'("Port Width Mismatch : ") );
          write( Message, STRING'("The attribute ") );
          write( Message, STRING'("READ_WIDTH_A on BRAM_TDP_MACRO is set to ") );
          write( Message, READ_WIDTH_A);
          write( Message, STRING'(" and READ_WIDTH_B on BRAM_TDP_MACRO is set to ") );
          write( Message, READ_WIDTH_B);
          write( Message, STRING'(". The parity bit(s) cannot be read") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Warning;
          DEALLOCATE (Message);
        end if;
      end if;
    return check;
  end;

   function GetSIMDev (
    device  : in string
    ) return string is
  begin
    if(DEVICE = "VIRTEX6") then
      return "VIRTEX6";
    else
      return "7SERIES";
      end if;
  end;

  function GetValWidth_A (
  rd_widtha : in integer;
  wr_widtha : in integer
    ) return boolean is
  begin
   if ((rd_widtha = 1 or rd_widtha = 2 or rd_widtha = 4 or rd_widtha = 8 or rd_widtha = 9 or rd_widtha = 16 or rd_widtha = 18 or rd_widtha = 32 or rd_widtha = 36 ) and (wr_widtha = 1 or wr_widtha = 2 or wr_widtha = 4 or wr_widtha = 8 or wr_widtha = 9 or wr_widtha = 16 or wr_widtha = 18 or wr_widtha = 32 or wr_widtha = 36 )) then
    return TRUE;
    else
    return FALSE;
   end if; 
  end;

  function GetValWidth_B (
  rd_widthb : in integer;
  wr_widthb : in integer
    ) return boolean is
  begin
   if ((rd_widthb = 1 or rd_widthb = 2 or rd_widthb = 4 or rd_widthb = 8 or rd_widthb = 9 or rd_widthb = 16 or rd_widthb = 18 or rd_widthb = 32 or rd_widthb = 36) and (wr_widthb = 1 or wr_widthb = 2 or wr_widthb = 4 or wr_widthb = 8 or wr_widthb = 9 or wr_widthb = 16 or wr_widthb = 18 or wr_widthb = 32 or wr_widthb = 36)) then
    return TRUE;
    else
    return FALSE;
   end if; 
  end;

  function CheckWEAWidth (
  wr_width : in integer;
  wea_vec : in integer
  ) return boolean is
  variable Message : LINE;
  begin
    if ( wr_width <= 9 and wea_vec /= 1) then
      write( Message, STRING'("WEA port width incorrectly set for WRITE_WIDTH_A : ") );
      write( Message, WRITE_WIDTH_A);
      write( Message, STRING'(". WEA port width  must be of width 1 (0 downto 0) . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
    elsif ( (wr_width > 9 and wr_width <= 18) and wea_vec /= 2) then  
      write( Message, STRING'("WEA port width incorrectly set for WRITE_WIDTH_A : ") );
      write( Message, WRITE_WIDTH_A);
      write( Message, STRING'(". WEA port width  must be of width 2 . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
    elsif ( (wr_width > 18 and wr_width <= 36) and wea_vec /= 4) then  
      write( Message, STRING'("WEA port width incorrectly set for WRITE_WIDTH_A : ") );
      write( Message, WRITE_WIDTH_A);
      write( Message, STRING'(". WEA port width  must be of width 4 . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
     else
       return TRUE;
     end if;
   end;
function CheckWEBWidth (
  wr_width : in integer;
  web_vec : in integer
  ) return boolean is
  variable Message : LINE;
  begin
    if ( wr_width <= 9 and web_vec /= 1) then
      write( Message, STRING'("WEB port width incorrectly set for WRITE_WIDTH_B : ") );
      write( Message, WRITE_WIDTH_B);
      write( Message, STRING'(". WEB port width  must be of width 1 (0 downto 0) . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
    elsif ( (wr_width > 9 and wr_width <= 18) and web_vec /= 2) then  
      write( Message, STRING'("WEB port width incorrectly set for WRITE_WIDTH_B : ") );
      write( Message, WRITE_WIDTH_B);
      write( Message, STRING'(". WEB port width  must be of width 2 . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
    elsif ( (wr_width > 18 and wr_width <= 36) and web_vec /= 4) then  
      write( Message, STRING'("WEB port width incorrectly set for WRITE_WIDTH_B : ") );
      write( Message, WRITE_WIDTH_B);
      write( Message, STRING'(". WEB port width  must be of width 4 . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
     else
       return TRUE;
     end if;
   end;

function CheckADDRAWidth (
    least_width : in integer;
    func_bram_size : in string;
    device : in string;
    addra_vec : in integer
    ) return boolean is
    variable Message : LINE;
  begin
      if (func_bram_size  = "9Kb") then
        if (least_width = 1 and addra_vec /= 13) then
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_width = 2 and addra_vec /= 12) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 2 and least_width <= 4) and addra_vec /= 11) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 4 and least_width <= 9) and addra_vec /= 10) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 9 and least_width <= 18) and addra_vec /= 9) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 9 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
	else
	  return TRUE;
        end if;
      elsif (func_bram_size = "18Kb") then 	
        if (least_width = 1 and addra_vec /= 14) then
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 14 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_width = 2 and addra_vec /= 13) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 2 and least_width <= 4) and addra_vec /= 12) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 4 and least_width <= 9) and addra_vec /= 11) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 9 and least_width <= 18) and addra_vec /= 10) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 18 and least_width <= 36) and addra_vec /= 9) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 9 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
	else
	  return TRUE;
	end if;
      elsif (func_bram_size = "36Kb") then 	
        if (least_width = 1 and addra_vec /= 15) then
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 15 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_width = 2 and addra_vec /= 14) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 14 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 2 and least_width <= 4) and addra_vec /= 13) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 4 and least_width <= 9) and addra_vec /= 12) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 9 and least_width <= 18) and addra_vec /= 11) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 18 and least_width <= 36) and addra_vec /= 10) then	    
	  write( Message, STRING'("ADDRA port width incorrectly set. ") );
          write( Message, STRING'(". ADDRA port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
	else
	  return TRUE;
	end if;  
      else
      return TRUE;
    end if;
  end;

  function CheckADDRBWidth (
    least_width : in integer;
    func_bram_size : in string;
    device : in string;
    addrb_vec : in integer
    ) return boolean is
    variable Message : LINE;
  begin
      if (func_bram_size  = "9Kb") then
        if (least_width = 1 and addrb_vec /= 13) then
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_width = 2 and addrb_vec /= 12) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 2 and least_width <= 4) and addrb_vec /= 11) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 4 and least_width <= 9) and addrb_vec /= 10) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 9 and least_width <= 18) and addrb_vec /= 9) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 9 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
	else
	  return TRUE;
        end if;
      elsif (func_bram_size = "18Kb") then 	
        if (least_width = 1 and addrb_vec /= 14) then
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 14 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_width = 2 and addrb_vec /= 13) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 2 and least_width <= 4) and addrb_vec /= 12) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 4 and least_width <= 9) and addrb_vec /= 11) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 9 and least_width <= 18) and addrb_vec /= 10) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 18 and least_width <= 36) and addrb_vec /= 9) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 9 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
	else
	  return TRUE;
	end if;
      elsif (func_bram_size = "36Kb") then 	
        if (least_width = 1 and addrb_vec /= 15) then
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 15 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_width = 2 and addrb_vec /= 14) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 14 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 2 and least_width <= 4) and addrb_vec /= 13) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 4 and least_width <= 9) and addrb_vec /= 12) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 9 and least_width <= 18) and addrb_vec /= 11) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_width > 18 and least_width <= 36) and addrb_vec /= 10) then	    
	  write( Message, STRING'("ADDRB port width incorrectly set. ") );
          write( Message, STRING'(". ADDRB port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
	else
	  return TRUE;
	end if;  
      else
      return TRUE;
    end if;
  end;


  function Get_Parity_Width (
    wd : in integer
    ) return integer is
    variable wp : integer;
  begin
    if (wd = 9 or wd = 17 or wd = 33) then
        wp := 1;
    elsif (wd = 18 or wd = 34) then
      wp := 2;
    elsif (wd = 35) then
      wp := 3;
    elsif (wd = 36) then
      wp := 4;
    else
      wp := 4;
    end if;
    return wp;
  end;

    
  function Pad_INIT_SRVAL (
    func_in_init_srval : in bit_vector;
    func_init_srval_width_size : in integer)
    return bit_vector is variable func_paded_init_srval : bit_vector(0 to func_init_srval_width_size-1) := (others=>'0');
                         variable func_padded_width : integer;
  begin

    if (func_in_init_srval'length > func_init_srval_width_size) then
      func_padded_width := func_init_srval_width_size;
    else
      func_padded_width := func_in_init_srval'length;
    end if;

    for i in 0 to func_padded_width-1 loop 
      func_paded_init_srval(((func_init_srval_width_size-1) - (func_padded_width-1)) + i) := func_in_init_srval(i);
    end loop;
      
    return func_paded_init_srval;
  end;

    
  function Get_INIT_SRVAL_Width (
    func_bram_size : in string;
    func_device : in string)
    return integer is variable init_srval_width : integer;
  begin
      if(bram_size = "36Kb") then
         init_srval_width := 36;
      elsif(bram_size = "18Kb") then
        if (func_device = "SPARTAN6") then
          init_srval_width := 36;
        else
          init_srval_width := 20;
        end if;
      elsif (bram_size = "9Kb") then
         init_srval_width := 20;
      else
         init_srval_width := 36;
      end if;

      return init_srval_width;
  end;


  function INIT_SRVAL_parity_byte (
    in_init_srval : in bit_vector;
    readp : in boolean;
    writep : in boolean;
    read_widthp : in integer;
    init_srval_width : in integer)
    return bit_vector is variable out_init_srval : bit_vector(0 to in_init_srval'length-1);
  begin

    if (readp = TRUE and writep = TRUE) then
        
      if (read_widthp = 9) then
        if (init_srval_width = 20) then
          out_init_srval := "00000000000" & in_init_srval(11) & in_init_srval(12 to 19);
        else
          out_init_srval := "000000000000000000000000000" & in_init_srval(27) & in_init_srval(28 to 35);
        end if;
      elsif (read_widthp = 17) then
        if (init_srval_width = 20) then
          out_init_srval := "000" & in_init_srval(11) & in_init_srval(3 to 10) & in_init_srval(12 to 19);
        else
          out_init_srval := "0000000000000000000" & in_init_srval(27) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
        end if;
      elsif (read_widthp = 18) then
        if (init_srval_width = 20) then
          out_init_srval := "00" & in_init_srval(2) & in_init_srval(11) & in_init_srval(3 to 10) & in_init_srval(12 to 19);
        else
          out_init_srval := "000000000000000000" & in_init_srval(18) & in_init_srval(27) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
        end if;
      elsif (read_widthp = 33) then
        out_init_srval := "000" & in_init_srval(27) & in_init_srval(3 to 26) & in_init_srval(28 to 35);
      elsif (read_widthp = 34) then
        out_init_srval := "00" & in_init_srval(18) & in_init_srval(27) & in_init_srval(2 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
      elsif (read_widthp = 35) then
        out_init_srval := '0' & in_init_srval(9) & in_init_srval(18) & in_init_srval(27) & in_init_srval(1 to 8) & in_init_srval(10 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
      elsif (read_widthp = 36) then
        out_init_srval := in_init_srval(0) & in_init_srval(9) & in_init_srval(18) & in_init_srval(27) & in_init_srval(1 to 8) & in_init_srval(10 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
      else
        out_init_srval := in_init_srval;
      end if;

    else
      out_init_srval := in_init_srval;
    end if;
    
    return out_init_srval;  
                         
  end;

    
  constant bram_size_val : boolean := GetBRAMSize(BRAM_SIZE, DEVICE);
  constant write_a_p : boolean := Get_P(WRITE_WIDTH_A, DEVICE);
  constant write_b_p : boolean := Get_P(WRITE_WIDTH_B, DEVICE);
  constant read_a_p : boolean := Get_P(READ_WIDTH_A, DEVICE);
  constant read_b_p : boolean := Get_P(READ_WIDTH_B, DEVICE);
  constant dia_width : integer := GetDIAWidth(WRITE_WIDTH_A, BRAM_SIZE, DEVICE);
  constant dib_width : integer := GetDIBWidth(WRITE_WIDTH_B, BRAM_SIZE, DEVICE);
  constant dipa_width : integer := GetDPWidth(WRITE_WIDTH_A, BRAM_SIZE, DEVICE);
  constant dipb_width : integer := GetDPWidth(WRITE_WIDTH_B, BRAM_SIZE, DEVICE);
  constant doa_width : integer := GetDOAWidth(READ_WIDTH_A, BRAM_SIZE, DEVICE, WRITE_WIDTH_A);
  constant dob_width : integer := GetDOBWidth(READ_WIDTH_B, BRAM_SIZE, DEVICE, WRITE_WIDTH_B);
  constant dopa_width : integer := GetDPWidth(READ_WIDTH_A, BRAM_SIZE, DEVICE);
  constant dopb_width : integer := GetDPWidth(READ_WIDTH_B, BRAM_SIZE, DEVICE);
  constant wr_a_width : integer := GetD_Width (WRITE_WIDTH_A, DEVICE);
  constant wr_b_width : integer := GetD_Width (WRITE_WIDTH_B, DEVICE);
  constant rd_a_width : integer := GetD_Width (READ_WIDTH_A, DEVICE);
  constant rd_b_width : integer := GetD_Width (READ_WIDTH_B, DEVICE);
  constant check_p : boolean := CheckParity(write_a_p, write_b_p, read_a_p, read_b_p, DEVICE);
  constant least_width_A : integer := GetLeastWidthA(dia_width, doa_width);
  constant least_width_B : integer := GetLeastWidthB(dib_width, dob_width);
  constant addra_width : integer := GetADDRWidth(least_width_A, BRAM_SIZE, DEVICE);
  constant addrb_width : integer := GetADDRWidth(least_width_B, BRAM_SIZE, DEVICE);
  constant wea_width : integer := GetWEWidth(BRAM_SIZE, DEVICE, WRITE_WIDTH_A);
  constant web_width : integer := GetWEWidth(BRAM_SIZE, DEVICE, WRITE_WIDTH_B);
  constant rda_byte_width : integer := GetWEWidth(BRAM_SIZE, DEVICE, READ_WIDTH_A);
  constant rdb_byte_width : integer := GetWEWidth(BRAM_SIZE, DEVICE, READ_WIDTH_B);
  constant fin_rda_width : integer := GetFinalWidth(READ_WIDTH_A);
  constant fin_rdb_width : integer := GetFinalWidth(READ_WIDTH_B);
  constant fin_wra_width : integer := GetFinalWidth(WRITE_WIDTH_A);
  constant fin_wrb_width : integer := GetFinalWidth(WRITE_WIDTH_B);
  constant sim_device_dp : string := GetSIMDev(DEVICE);
  constant valid_width_a : boolean := GetValWidth_A(READ_WIDTH_A,WRITE_WIDTH_A);
  constant valid_width_b : boolean := GetValWidth_B(READ_WIDTH_B,WRITE_WIDTH_B);
  constant wealeng : integer := WEA'length;
  constant webleng : integer := WEB'length;
  constant addraleng : integer := ADDRA'length;
  constant addrbleng : integer := ADDRB'length;
  constant checkwea : boolean := CheckWEAWidth(WRITE_WIDTH_A, wealeng);
  constant checkweb : boolean := CheckWEBWidth(WRITE_WIDTH_B, webleng);
  constant checkaddra : boolean :=  CheckADDRAWidth(least_width_A, BRAM_SIZE, DEVICE, addraleng);
  constant checkaddrb : boolean :=  CheckADDRBWidth(least_width_B, BRAM_SIZE, DEVICE, addrbleng);

  constant max_addr_width : integer := GetMaxADDRSize(BRAM_SIZE, DEVICE);
  constant max_data_width : integer := GetMaxDataSize(BRAM_SIZE, DEVICE);
  constant max_datap_width : integer := GetMaxDataPSize(BRAM_SIZE, DEVICE);
  constant max_we_width : integer := GetMaxWESize(BRAM_SIZE, DEVICE);
  constant max_web_width_bl : integer := GetMaxWESize_bl(BRAM_SIZE, DEVICE);

  constant reada_double : integer := (2*READ_WIDTH_A);
  constant readb_double : integer := (2*READ_WIDTH_B);

  constant init_srval_width_size : integer := Get_INIT_SRVAL_Width(BRAM_SIZE, DEVICE);
  constant padded_init_a : bit_vector(0 to init_srval_width_size-1) := Pad_INIT_SRVAL(INIT_A, init_srval_width_size);
  constant padded_init_b : bit_vector(0 to init_srval_width_size-1) := Pad_INIT_SRVAL(INIT_B, init_srval_width_size);
  constant padded_srval_a : bit_vector(0 to init_srval_width_size-1) := Pad_INIT_SRVAL(SRVAL_A, init_srval_width_size);
  constant padded_srval_b : bit_vector(0 to init_srval_width_size-1) := Pad_INIT_SRVAL(SRVAL_B, init_srval_width_size);
  constant wra_widthp : integer := Get_Parity_Width(WRITE_WIDTH_A);
  constant wrb_widthp : integer := Get_Parity_Width(WRITE_WIDTH_B);
  constant rda_widthp : integer := Get_Parity_Width(READ_WIDTH_A);
  constant rdb_widthp : integer := Get_Parity_Width(READ_WIDTH_B);
    
  signal addra_pattern : std_logic_vector(max_addr_width-1 downto 0) := (others=> '0');
  signal addrb_pattern : std_logic_vector(max_addr_width-1 downto 0) := (others=> '0');

  signal dia_pattern : std_logic_vector(max_data_width-1 downto 0) := (others=>'0');  
  signal dib_pattern : std_logic_vector(max_data_width-1 downto 0) := (others=>'0');  
  signal dipa_pattern : std_logic_vector(max_datap_width-1 downto 0) := (others=>'0');  
  signal dipb_pattern : std_logic_vector(max_datap_width-1 downto 0) := (others=>'0');  
  signal doa_pattern : std_logic_vector(max_data_width-1 downto 0);  
  signal dob_pattern : std_logic_vector(max_data_width-1 downto 0);  
  signal dopa_pattern : std_logic_vector(max_datap_width-1 downto 0) := (others=>'0');  
  signal dopb_pattern : std_logic_vector(max_datap_width-1 downto 0) := (others=>'0');  
  signal wea_pattern : std_logic_vector(max_we_width-1 downto 0) := (others=>'0');  
  signal web_pattern : std_logic_vector(max_we_width-1 downto 0) := (others=>'0');  
  signal web_pattern_bl : std_logic_vector(max_web_width_bl-1 downto 0) := (others=>'0');  

  signal rstrama_pattern : std_logic := '0';
  signal rstramb_pattern : std_logic := '0';
  signal rstrega_pattern : std_logic := '0';
  signal rstregb_pattern : std_logic := '0';

begin

  a1 : addra_pattern <= 
                   -- begin s15 
                   ADDRA when (BRAM_SIZE = "9Kb" and addra_width = 13 ) else
                   (ADDRA & '1') when (BRAM_SIZE = "9Kb" and addra_width = 12 ) else
                   (ADDRA & "11") when (BRAM_SIZE = "9Kb" and addra_width = 11 ) else
                   (ADDRA & "111") when (BRAM_SIZE = "9Kb" and addra_width = 10 ) else
                   (ADDRA & "1111") when (BRAM_SIZE = "9Kb" and addra_width = 9) else -- end s15
                   ADDRA when (BRAM_SIZE = "18Kb" and addra_width = 14  ) else
                   (ADDRA & '1') when (BRAM_SIZE = "18Kb" and addra_width = 13  ) else
                   (ADDRA & "11") when (BRAM_SIZE = "18Kb" and addra_width = 12  ) else
                   (ADDRA & "111") when (BRAM_SIZE = "18Kb" and addra_width = 11  ) else
                   (ADDRA & "1111") when (BRAM_SIZE = "18Kb" and addra_width = 10  ) else
                   (ADDRA & "11111") when (BRAM_SIZE = "18Kb" and addra_width = 9  ) else
                   ADDRA when (BRAM_SIZE = "36Kb" and addra_width = 16  ) else
                   ('1' & ADDRA) when (BRAM_SIZE = "36Kb" and addra_width = 15 ) else
                   ('1' & ADDRA & '1') when (BRAM_SIZE = "36Kb" and addra_width = 14  ) else
                   ('1' & ADDRA & "11") when (BRAM_SIZE = "36Kb" and addra_width = 13) else
                   ('1' & ADDRA & "111") when (BRAM_SIZE = "36Kb" and addra_width = 12 ) else
                   ('1' & ADDRA & "1111") when (BRAM_SIZE = "36Kb" and addra_width = 11 ) else
                   ('1' & ADDRA & "11111") when (BRAM_SIZE = "36Kb" and addra_width = 10  ) else
                   ADDRA;
  a2 : addrb_pattern <= 
                   -- begin s16
                   ADDRB when (BRAM_SIZE = "9Kb" and addrb_width = 13 ) else
                   (ADDRB & '1') when (BRAM_SIZE = "9Kb" and addrb_width = 12 ) else
                   (ADDRB & "11") when (BRAM_SIZE = "9Kb" and addrb_width = 11 ) else
                   (ADDRB & "111") when (BRAM_SIZE = "9Kb" and addrb_width = 10 ) else
                   (ADDRB & "1111") when (BRAM_SIZE = "9Kb" and addrb_width = 9 ) else -- end s16
                   ADDRB when (BRAM_SIZE = "18Kb" and addrb_width = 14 ) else
                   (ADDRB & '1') when (BRAM_SIZE = "18Kb" and addrb_width = 13 ) else
                   (ADDRB & "11") when (BRAM_SIZE = "18Kb" and addrb_width = 12 ) else
                   (ADDRB & "111") when (BRAM_SIZE = "18Kb" and addrb_width = 11 ) else
                   (ADDRB & "1111") when (BRAM_SIZE = "18Kb" and addrb_width = 10 ) else
                   (ADDRB & "11111") when (BRAM_SIZE = "18Kb" and addrb_width = 9 ) else
                   ADDRB when (BRAM_SIZE = "36Kb" and addrb_width = 16 ) else
                   ('1' & ADDRB) when (BRAM_SIZE = "36Kb" and addrb_width = 15 ) else
                   ('1' & ADDRB & '1') when (BRAM_SIZE = "36Kb" and addrb_width = 14 ) else
                   ('1' & ADDRB & "11") when (BRAM_SIZE = "36Kb" and addrb_width = 13  ) else
                   ('1' & ADDRB & "111") when (BRAM_SIZE = "36Kb" and addrb_width = 12 ) else
                   ('1' & ADDRB & "1111") when (BRAM_SIZE = "36Kb" and addrb_width = 11 ) else
                   ('1' & ADDRB & "11111") when (BRAM_SIZE = "36Kb" and addrb_width = 10 ) else
                   ADDRB;


  dia1_v5 : if ( ((DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") and ((BRAM_SIZE = "18Kb" and WRITE_WIDTH_A <= 18) or (BRAM_SIZE = "36Kb" and WRITE_WIDTH_A <= 36))) or ( (DEVICE = "SPARTAN6") and ((BRAM_SIZE = "9Kb" and WRITE_WIDTH_A <= 18) or (BRAM_SIZE = "18Kb" and WRITE_WIDTH_A <= 36) ) )  ) generate
    begin
      dia1 : if (write_a_p = TRUE  and read_a_p = TRUE) generate

                dia11 : if (WRITE_WIDTH_A = 33) generate
                  dia_pattern <= DIA(32 downto 9) & DIA(7 downto 0);
                end generate dia11;
        
                dia12 : if (WRITE_WIDTH_A = 34) generate
                  dia_pattern <= DIA(33 downto 18) & DIA(16 downto 9) & DIA(7 downto 0);
                end generate dia12;

                dia13 : if (WRITE_WIDTH_A = 35 or WRITE_WIDTH_A = 36 or WRITE_WIDTH_A <= 32) generate
                  ia1 : for i in 0 to wea_width-1 generate
                    dia_pattern((i*8)+7 downto (i*8)) <= DIA(((i*8)+i)+7 downto ((i*8)+i));
                  end generate ia1;
                end generate dia13;
                
                ia1p : for j in 1 to wra_widthp generate
                  dipa_pattern(j-1) <= DIA((j*8)+j-1);
                end generate ia1p;

      end generate dia1;
      dia2 : if ( (read_a_p = FALSE and write_a_p = FALSE) and ((READ_WIDTH_A = WRITE_WIDTH_A) or (READ_WIDTH_A/WRITE_WIDTH_A = 2) or (valid_width_a = TRUE)) ) generate
                 dia_pattern(fin_wra_width-1 downto 0) <= DIA(fin_wra_width-1 downto 0);
      end generate dia2;
      dia3 : if  ((READ_WIDTH_A = 1 and WRITE_WIDTH_A = 2) or (READ_WIDTH_A = 2 and WRITE_WIDTH_A = 4) or (READ_WIDTH_A = 4 and WRITE_WIDTH_A = 8) or (READ_WIDTH_A = 8 and WRITE_WIDTH_A = 16) or (READ_WIDTH_A = 16 and WRITE_WIDTH_A = 32) or (READ_WIDTH_A = 32 and WRITE_WIDTH_A = 64 )) generate
                 dia_pattern(fin_wra_width-1 downto 0) <= DIA(fin_wra_width-1 downto 0);
      end generate dia3;
      dia4 : if ( (read_a_p = FALSE and write_a_p = FALSE) and (WRITE_WIDTH_A/READ_WIDTH_A = 2)) generate
                 dia_pattern(READ_WIDTH_A-1 downto 0) <= DIA(READ_WIDTH_A-1 downto 0);
                 dia_pattern (reada_double-1 downto READ_WIDTH_A) <= DIA(reada_double-1 downto READ_WIDTH_A);
      end generate dia4;			 
  end generate dia1_v5;
  -- begin s17

  dib1_v5 : if ( ((DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") and ((BRAM_SIZE = "18Kb" and WRITE_WIDTH_B <= 18) or (BRAM_SIZE = "36Kb" and WRITE_WIDTH_B <= 36))) or ( (DEVICE = "SPARTAN6") and ((BRAM_SIZE = "9Kb" and WRITE_WIDTH_B <= 18) or (BRAM_SIZE = "18Kb" and WRITE_WIDTH_B <= 36) ) )  ) generate
    begin
      dib1 : if (write_b_p = TRUE  and read_b_p = TRUE) generate

                dib11 : if (WRITE_WIDTH_B = 33) generate
                  dib_pattern <= DIB(32 downto 9) & DIB(7 downto 0);
                end generate dib11;
        
                dib12 : if (WRITE_WIDTH_B = 34) generate
                  dib_pattern <= DIB(33 downto 18) & DIB(16 downto 9) & DIB(7 downto 0);
                end generate dib12;

                dib13 : if (WRITE_WIDTH_B = 35 or WRITE_WIDTH_B = 36 or WRITE_WIDTH_B <= 32) generate
                  ib1 : for i in 0 to web_width-1 generate
                    dib_pattern((i*8)+7 downto (i*8)) <= DIB(((i*8)+i)+7 downto ((i*8)+i));
                  end generate ib1;
                end generate dib13;

                ib1p : for j in 1 to wrb_widthp generate
                  dipb_pattern(j-1) <= DIB((j*8)+j-1);
                end generate ib1p;

      end generate dib1;
      dib2 : if ( (read_b_p = FALSE and write_b_p = FALSE) and ((READ_WIDTH_B = WRITE_WIDTH_B) or (READ_WIDTH_B/WRITE_WIDTH_B = 2) or (valid_width_b = TRUE)) ) generate
                 dib_pattern(fin_wrb_width-1 downto 0) <= DIB(fin_wrb_width-1 downto 0);
      end generate dib2;
      dib3 : if  ((READ_WIDTH_B = 1 and WRITE_WIDTH_B = 2) or (READ_WIDTH_B = 2 and WRITE_WIDTH_B = 4) or (READ_WIDTH_B = 4 and WRITE_WIDTH_B = 8) or (READ_WIDTH_B = 8 and WRITE_WIDTH_B = 16) or (READ_WIDTH_B = 16 and WRITE_WIDTH_B = 32) or (READ_WIDTH_B = 32 and WRITE_WIDTH_A = 64 )) generate
                 dib_pattern(fin_wrb_width-1 downto 0) <= DIB(fin_wrb_width-1 downto 0);
      end generate dib3;
      dib4 : if ( (read_b_p = FALSE and write_b_p = FALSE) and (WRITE_WIDTH_B/READ_WIDTH_B = 2)) generate
                 dib_pattern(READ_WIDTH_B-1 downto 0) <= DIB(READ_WIDTH_B-1 downto 0);
                 dib_pattern (readb_double-1 downto READ_WIDTH_B) <= DIB(readb_double-1 downto READ_WIDTH_B);
      end generate dib4;			 
  end generate dib1_v5;


   doagen : if ( ((DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") and ((BRAM_SIZE = "18Kb" and READ_WIDTH_A <= 18) or (BRAM_SIZE = "36Kb" and READ_WIDTH_A <= 36)) ) or ((DEVICE ="SPARTAN6") and ((BRAM_SIZE = "9Kb" and READ_WIDTH_A <= 18) or (BRAM_SIZE = "18Kb" and READ_WIDTH_A <= 36)) ) ) generate 
          doa11 : if (read_a_p = TRUE and write_a_p = TRUE) generate

                doa111 : if (READ_WIDTH_A = 33) generate
                  DOA(32 downto 9) <= doa_pattern(31 downto 8);
                  DOA(7 downto 0) <= doa_pattern(7 downto 0);
                end generate doa111;
        
                doa112 : if (READ_WIDTH_A = 34) generate
                  DOA(33 downto 18) <= doa_pattern(31 downto 16);
                  DOA(16 downto 9) <= doa_pattern(15 downto 8);
                  DOA(7 downto 0) <= doa_pattern(7 downto 0);
                end generate doa112;

                doa113 : if (READ_WIDTH_A = 35 or READ_WIDTH_A = 36 or READ_WIDTH_A <= 32) generate
                  oa1 : for i1 in 0 to rda_byte_width-1 generate
                    DOA(((i1*8)+i1)+7 downto ((i1*8)+i1)) <= doa_pattern((i1*8)+7 downto (i1*8));
                  end generate oa1;
                end generate doa113;
            
            oa1p : for j1 in 1 to rda_widthp generate
              DOA((j1*8)+j1-1) <= dopa_pattern(j1-1);
            end generate oa1p;

          end generate doa11;
          doa121 : if  ( (read_a_p = FALSE and write_a_p = FALSE) and ( (READ_WIDTH_A = WRITE_WIDTH_A) or (WRITE_WIDTH_A/READ_WIDTH_A = 2) or (valid_width_a = TRUE) )) generate   
               DOA <= ( doa_pattern(fin_rda_width-1 downto 0) );     
	  end generate doa121;
          doa12 : if  ((READ_WIDTH_A = 2 and WRITE_WIDTH_A = 1) or (READ_WIDTH_A = 4 and WRITE_WIDTH_A = 2) or (READ_WIDTH_A = 8 and WRITE_WIDTH_A = 4) or (READ_WIDTH_A = 16 and WRITE_WIDTH_A = 8) or (READ_WIDTH_A = 32 and WRITE_WIDTH_A = 16) or (READ_WIDTH_A = 64 and WRITE_WIDTH_A = 32 )) generate   
               DOA <= ( doa_pattern(fin_rda_width-1 downto 0) );   
	  end generate doa12;     
	  doa3 : if ((read_a_p = FALSE and write_a_p = FALSE) and (READ_WIDTH_A/WRITE_WIDTH_A = 2) and (WRITE_WIDTH_A = 3)) generate
	    -- write width 3
	       DOA <= ( doa_pattern((4+(WRITE_WIDTH_A-1)) downto 4) & doa_pattern((WRITE_WIDTH_A-1) downto 0) );
	  end generate doa3;   
	  doa47 : if ((read_a_p = FALSE and write_a_p = FALSE) and (READ_WIDTH_A/WRITE_WIDTH_A = 2) and (WRITE_WIDTH_A > 4 and WRITE_WIDTH_A < 8)) generate
	    -- write width between 4 and 7
	      DOA <=  ( doa_pattern((8+(WRITE_WIDTH_A-1)) downto 8) & doa_pattern((WRITE_WIDTH_A-1) downto 0) );
	  end generate doa47;     
          doa815 : if ((read_a_p = FALSE and write_a_p = FALSE) and (READ_WIDTH_A/WRITE_WIDTH_A = 2) and (WRITE_WIDTH_A > 8 and WRITE_WIDTH_A < 16) ) generate
	      -- write width between 8 and 15
	      DOA <= ( doa_pattern((16+(WRITE_WIDTH_A-1)) downto 16) & doa_pattern((WRITE_WIDTH_A-1) downto 0) ); 
	  end generate doa815;     

   end generate doagen; 

   dobgen : if ( ((DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") and ((BRAM_SIZE = "18Kb" and READ_WIDTH_B <= 18) or (BRAM_SIZE = "36Kb" and READ_WIDTH_B <= 36)) ) or ((DEVICE ="SPARTAN6") and ((BRAM_SIZE = "9Kb" and READ_WIDTH_B <= 18) or (BRAM_SIZE = "18Kb" and READ_WIDTH_B <= 36)) ) ) generate 
          dob11 : if (read_b_p = TRUE and write_b_p = TRUE) generate

                dob111 : if (READ_WIDTH_B = 33) generate
                  DOB(32 downto 9) <= dob_pattern(31 downto 8);
                  DOB(7 downto 0) <= dob_pattern(7 downto 0);
                end generate dob111;
        
                dob112 : if (READ_WIDTH_B = 34) generate
                  DOB(33 downto 18) <= dob_pattern(31 downto 16);
                  DOB(16 downto 9) <= dob_pattern(15 downto 8);
                  DOB(7 downto 0) <= dob_pattern(7 downto 0);
                end generate dob112;

                dob113 : if (READ_WIDTH_B = 35 or READ_WIDTH_B = 36 or READ_WIDTH_B <= 32) generate
                  ob1 : for i1 in 0 to rdb_byte_width-1 generate
                    DOB(((i1*8)+i1)+7 downto ((i1*8)+i1)) <= dob_pattern((i1*8)+7 downto (i1*8));
                  end generate ob1;
                end generate dob113;

            ob1p : for j1 in 1 to rdb_widthp generate
              DOB((j1*8)+j1-1) <= dopb_pattern(j1-1);
            end generate ob1p;

          end generate dob11;
          dob121 : if  ( (read_b_p = FALSE and write_b_p = FALSE ) and ((READ_WIDTH_B = WRITE_WIDTH_B)  or (WRITE_WIDTH_B/READ_WIDTH_B = 2) or (valid_width_b = TRUE) )) generate   
               DOB <= ( dob_pattern(fin_rdb_width-1 downto 0) );     
	  end generate dob121;
          dob12 : if  ((READ_WIDTH_B = 2 and WRITE_WIDTH_B = 1) or (READ_WIDTH_B = 4 and WRITE_WIDTH_B = 2) or (READ_WIDTH_B = 8 and WRITE_WIDTH_B = 4) or (READ_WIDTH_B = 16 and WRITE_WIDTH_B = 8) or (READ_WIDTH_B = 32 and WRITE_WIDTH_B = 16) or (READ_WIDTH_B = 64 and WRITE_WIDTH_A = 32 )) generate   
               DOB <= ( dob_pattern(fin_rdb_width-1 downto 0) );   
	  end generate dob12;     
	  dob3 : if ( (read_b_p = FALSE and write_b_p = FALSE ) and (READ_WIDTH_B/WRITE_WIDTH_B = 2) and (WRITE_WIDTH_B = 3)) generate
	    -- write width 3
	       DOB <= ( dob_pattern((4+(WRITE_WIDTH_B-1)) downto 4) & dob_pattern((WRITE_WIDTH_B-1) downto 0) );
	  end generate dob3;   
	  dob47 : if ( (read_b_p = FALSE and write_b_p = FALSE ) and (READ_WIDTH_B/WRITE_WIDTH_B = 2) and (WRITE_WIDTH_B > 4 and WRITE_WIDTH_B < 8)) generate
	       DOB <=  ( dob_pattern((8+(WRITE_WIDTH_B-1)) downto 8) & dob_pattern((WRITE_WIDTH_B-1) downto 0) );
	  end generate dob47;     
          dob815 : if ( (read_b_p = FALSE and write_b_p = FALSE ) and (WRITE_WIDTH_B > 8 and WRITE_WIDTH_B < 16) and (READ_WIDTH_B/WRITE_WIDTH_B =2) ) generate
	      -- write width between 8 and 15
	       DOB <= ( dob_pattern((16+(WRITE_WIDTH_B-1)) downto 16) & dob_pattern((WRITE_WIDTH_B-1) downto 0) ); 
	  end generate dob815;     

   end generate dobgen;

  

  wea1 : if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
  w1 : wea_pattern <= (WEA & WEA) when (BRAM_SIZE = "18Kb" and wea_width = 1 ) else
                   WEA when (BRAM_SIZE = "18Kb" and wea_width = 2  ) else
                   (WEA & WEA & WEA & WEA) when (BRAM_SIZE = "36Kb" and wea_width = 1 ) else
                   (WEA & WEA) when (BRAM_SIZE = "36Kb" and wea_width = 2 ) else
                   WEA when (BRAM_SIZE = "36Kb" and wea_width = 4 ) else
                   WEA;
  end generate wea1;
  -- begin s26
  wea2 : if (DEVICE = "SPARTAN6") generate
  w2 : wea_pattern <= (WEA & WEA) when (BRAM_SIZE = "9Kb" and wea_width = 1 ) else
                   WEA when (BRAM_SIZE = "9Kb" and wea_width = 2 ) else
                   (WEA & WEA & WEA & WEA) when (BRAM_SIZE = "18Kb" and wea_width = 1 ) else
                   (WEA & WEA) when (BRAM_SIZE = "18Kb" and wea_width = 2 ) else
                   WEA when (BRAM_SIZE = "18Kb" and wea_width = 4 ) else
                   WEA;
  end generate wea2;
  -- end s26
 web1 : if (DEVICE = "VIRTEX5") generate  
   web1 : web_pattern <= (WEB & WEB) when (BRAM_SIZE = "18Kb" and web_width = 1 ) else
                   WEB when (BRAM_SIZE = "18Kb" and web_width = 2 ) else
                   (WEB & WEB & WEB & WEB) when (BRAM_SIZE = "36Kb" and web_width = 1  ) else
                   (WEB & WEB) when (BRAM_SIZE = "36Kb" and web_width = 2  ) else
                   WEB when (BRAM_SIZE = "36Kb" and web_width = 4 ) else
                   WEB;
      end generate web1;
 -- begin s27
 web2 : if (DEVICE = "SPARTAN6") generate  
   web2 : web_pattern <= (WEB & WEB) when (BRAM_SIZE = "9Kb" and web_width = 1 ) else
                   WEB when (BRAM_SIZE = "9Kb" and web_width = 2 ) else
                   (WEB & WEB & WEB & WEB) when (BRAM_SIZE = "18Kb" and web_width = 1  ) else
                   (WEB & WEB) when (BRAM_SIZE = "18Kb" and web_width = 2  ) else
                   WEB when (BRAM_SIZE = "18Kb" and web_width = 4 ) else
                   WEB;
      end generate web2;
 -- end s27
 web_bl : if (DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate  
 web1 : web_pattern_bl <= ("00" & WEB & WEB) when (BRAM_SIZE = "18Kb" and web_width = 1  ) else
                   ("00" & WEB) when (BRAM_SIZE = "18Kb" and web_width = 2 ) else
                   ("0000" & WEB & WEB & WEB & WEB) when (BRAM_SIZE = "36Kb" and web_width = 1) else
                   ("0000" & WEB & WEB) when (BRAM_SIZE = "36Kb" and web_width = 2  ) else
                   ("0000" & WEB) when (BRAM_SIZE = "36Kb" and web_width = 4 ) else
                   ("0000"& WEB);
      end generate web_bl;

 r1 : rstrama_pattern <= RSTA; 
 r2 : rstramb_pattern <= RSTB; 
 r3 : rstrega_pattern <= RSTA when (DOA_REG = 1) else '0'; 
 r4 : rstregb_pattern <= RSTB when (DOB_REG = 1) else '0'; 


  -- begin generate virtex5
  ramb_v5 : if DEVICE = "VIRTEX5" generate 
    ramb18_dp : if BRAM_SIZE = "18Kb" generate 
      begin

        ram18 : RAMB18 
          generic map(
                DOA_REG => DOA_REG,
                DOB_REG => DOB_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                INIT_B => INIT_SRVAL_parity_byte(padded_init_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                INIT_FILE => INIT_FILE,
                INIT_00 => INIT_00,
                INIT_01 => INIT_01,
                INIT_02 => INIT_02,
                INIT_03 => INIT_03,
                INIT_04 => INIT_04,
                INIT_05 => INIT_05,
                INIT_06 => INIT_06,
                INIT_07 => INIT_07,
                INIT_08 => INIT_08,
                INIT_09 => INIT_09,
                INIT_0A => INIT_0A,
                INIT_0B => INIT_0B,
                INIT_0C => INIT_0C,
                INIT_0D => INIT_0D,
                INIT_0E => INIT_0E,
                INIT_0F => INIT_0F,
                INIT_10 => INIT_10,
                INIT_11 => INIT_11,
                INIT_12 => INIT_12,
                INIT_13 => INIT_13,
                INIT_14 => INIT_14,
                INIT_15 => INIT_15,
                INIT_16 => INIT_16,
                INIT_17 => INIT_17,
                INIT_18 => INIT_18,
                INIT_19 => INIT_19,
                INIT_1A => INIT_1A,
                INIT_1B => INIT_1B,
                INIT_1C => INIT_1C,
                INIT_1D => INIT_1D,
                INIT_1E => INIT_1E,
                INIT_1F => INIT_1F,
                INIT_20 => INIT_20,
                INIT_21 => INIT_21,
                INIT_22 => INIT_22,
                INIT_23 => INIT_23,
                INIT_24 => INIT_24,
                INIT_25 => INIT_25,
                INIT_26 => INIT_26,
                INIT_27 => INIT_27,
                INIT_28 => INIT_28,
                INIT_29 => INIT_29,
                INIT_2A => INIT_2A,
                INIT_2B => INIT_2B,
                INIT_2C => INIT_2C,
                INIT_2D => INIT_2D,
                INIT_2E => INIT_2E,
                INIT_2F => INIT_2F,
                INIT_30 => INIT_30,
                INIT_31 => INIT_31,
                INIT_32 => INIT_32,
                INIT_33 => INIT_33,
                INIT_34 => INIT_34,
                INIT_35 => INIT_35,
                INIT_36 => INIT_36,
                INIT_37 => INIT_37,
                INIT_38 => INIT_38,
                INIT_39 => INIT_39,
                INIT_3A => INIT_3A,
                INIT_3B => INIT_3B,
                INIT_3C => INIT_3C,
                INIT_3D => INIT_3D,
                INIT_3E => INIT_3E,
                INIT_3F => INIT_3F,
                INITP_00 => INITP_00,
                INITP_01 => INITP_01,
                INITP_02 => INITP_02,
                INITP_03 => INITP_03,
                INITP_04 => INITP_04,
                INITP_05 => INITP_05,
                INITP_06 => INITP_06,
                INITP_07 => INITP_07,
                READ_WIDTH_A => rd_a_width,
                READ_WIDTH_B => rd_b_width,
                SIM_COLLISION_CHECK => SIM_COLLISION_CHECK,
                SIM_MODE => SIM_MODE,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                SRVAL_B => INIT_SRVAL_parity_byte(padded_srval_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                WRITE_MODE_A => WRITE_MODE_A,
                WRITE_MODE_B => WRITE_MODE_B,
                WRITE_WIDTH_A => wr_a_width,
                WRITE_WIDTH_B => wr_b_width
              )
          port map (
                ADDRA => addra_pattern,
                ADDRB => addrb_pattern,
                CLKA => CLKA,
                CLKB => CLKB,
                DIA  => dia_pattern,
                DIB => dib_pattern,
                DIPA => dipa_pattern,
                DIPB => dipb_pattern,
                ENA => ENA,
                ENB => ENB,
                SSRA => RSTA,
                SSRB => RSTB,
                WEA => wea_pattern,
                WEB => web_pattern,
                DOA => doa_pattern,
                DOB => dob_pattern,
                DOPA => dopa_pattern,
                DOPB => dopb_pattern,
                REGCEA => REGCEA,
                REGCEB => REGCEB
        );

    end generate ramb18_dp;
  
    ramb36_dp : if BRAM_SIZE = "36Kb" generate 
      begin
        ram36 : RAMB36
          generic map (

                DOA_REG => DOA_REG,
                DOB_REG => DOB_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                INIT_B => INIT_SRVAL_parity_byte(padded_init_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                INIT_FILE => INIT_FILE,
		INIT_00 => INIT_00,
		INIT_01 => INIT_01,
		INIT_02 => INIT_02,
		INIT_03 => INIT_03,
		INIT_04 => INIT_04,
		INIT_05 => INIT_05,
		INIT_06 => INIT_06,
		INIT_07 => INIT_07,
		INIT_08 => INIT_08,
		INIT_09 => INIT_09,
		INIT_0A => INIT_0A,
		INIT_0B => INIT_0B,
		INIT_0C => INIT_0C,
		INIT_0D => INIT_0D,
		INIT_0E => INIT_0E,
		INIT_0F => INIT_0F,
		INIT_10 => INIT_10,
		INIT_11 => INIT_11,
		INIT_12 => INIT_12,
		INIT_13 => INIT_13,
		INIT_14 => INIT_14,
		INIT_15 => INIT_15,
		INIT_16 => INIT_16,
		INIT_17 => INIT_17,
		INIT_18 => INIT_18,
		INIT_19 => INIT_19,
		INIT_1A => INIT_1A,
		INIT_1B => INIT_1B,
		INIT_1C => INIT_1C,
		INIT_1D => INIT_1D,
		INIT_1E => INIT_1E,
		INIT_1F => INIT_1F,
		INIT_20 => INIT_20,
		INIT_21 => INIT_21,
		INIT_22 => INIT_22,
		INIT_23 => INIT_23,
		INIT_24 => INIT_24,
		INIT_25 => INIT_25,
		INIT_26 => INIT_26,
		INIT_27 => INIT_27,
		INIT_28 => INIT_28,
		INIT_29 => INIT_29,
		INIT_2A => INIT_2A,
		INIT_2B => INIT_2B,
		INIT_2C => INIT_2C,
		INIT_2D => INIT_2D,
		INIT_2E => INIT_2E,
		INIT_2F => INIT_2F,
		INIT_30 => INIT_30,
		INIT_31 => INIT_31,
		INIT_32 => INIT_32,
		INIT_33 => INIT_33,
		INIT_34 => INIT_34,
		INIT_35 => INIT_35,
		INIT_36 => INIT_36,
		INIT_37 => INIT_37,
		INIT_38 => INIT_38,
		INIT_39 => INIT_39,
		INIT_3A => INIT_3A,
		INIT_3B => INIT_3B,
		INIT_3C => INIT_3C,
		INIT_3D => INIT_3D,
		INIT_3E => INIT_3E,
		INIT_3F => INIT_3F,
		INIT_40 => INIT_40,
		INIT_41 => INIT_41,
		INIT_42 => INIT_42,
		INIT_43 => INIT_43,
		INIT_44 => INIT_44,
		INIT_45 => INIT_45,
		INIT_46 => INIT_46,
		INIT_47 => INIT_47,
		INIT_48 => INIT_48,
		INIT_49 => INIT_49,
		INIT_4A => INIT_4A,
		INIT_4B => INIT_4B,
		INIT_4C => INIT_4C,
		INIT_4D => INIT_4D,
		INIT_4E => INIT_4E,
		INIT_4F => INIT_4F,
		INIT_50 => INIT_50,
		INIT_51 => INIT_51,
		INIT_52 => INIT_52,
		INIT_53 => INIT_53,
		INIT_54 => INIT_54,
		INIT_55 => INIT_55,
		INIT_56 => INIT_56,
		INIT_57 => INIT_57,
		INIT_58 => INIT_58,
		INIT_59 => INIT_59,
		INIT_5A => INIT_5A,
		INIT_5B => INIT_5B,
		INIT_5C => INIT_5C,
		INIT_5D => INIT_5D,
		INIT_5E => INIT_5E,
		INIT_5F => INIT_5F,
		INIT_60 => INIT_60,
		INIT_61 => INIT_61,
		INIT_62 => INIT_62,
		INIT_63 => INIT_63,
		INIT_64 => INIT_64,
		INIT_65 => INIT_65,
		INIT_66 => INIT_66,
		INIT_67 => INIT_67,
		INIT_68 => INIT_68,
		INIT_69 => INIT_69,
		INIT_6A => INIT_6A,
		INIT_6B => INIT_6B,
		INIT_6C => INIT_6C,
		INIT_6D => INIT_6D,
		INIT_6E => INIT_6E,
		INIT_6F => INIT_6F,
		INIT_70 => INIT_70,
		INIT_71 => INIT_71,
		INIT_72 => INIT_72,
		INIT_73 => INIT_73,
		INIT_74 => INIT_74,
		INIT_75 => INIT_75,
		INIT_76 => INIT_76,
		INIT_77 => INIT_77,
		INIT_78 => INIT_78,
		INIT_79 => INIT_79,
		INIT_7A => INIT_7A,
		INIT_7B => INIT_7B,
		INIT_7C => INIT_7C,
		INIT_7D => INIT_7D,
		INIT_7E => INIT_7E,
		INIT_7F => INIT_7F,
		INITP_00 => INITP_00,
		INITP_01 => INITP_01,
		INITP_02 => INITP_02,
		INITP_03 => INITP_03,
		INITP_04 => INITP_04,
		INITP_05 => INITP_05,
		INITP_06 => INITP_06,
		INITP_07 => INITP_07,
		INITP_08 => INITP_08,
		INITP_09 => INITP_09,
		INITP_0A => INITP_0A,
		INITP_0B => INITP_0B,
		INITP_0C => INITP_0C,
		INITP_0D => INITP_0D,
		INITP_0E => INITP_0E,
		INITP_0F => INITP_0F,
		SIM_COLLISION_CHECK => SIM_COLLISION_CHECK,
                SIM_MODE => SIM_MODE,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                SRVAL_B => INIT_SRVAL_parity_byte(padded_srval_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                READ_WIDTH_A => rd_a_width,
                READ_WIDTH_B => rd_b_width,                
		WRITE_MODE_A => WRITE_MODE_A,
		WRITE_MODE_B => WRITE_MODE_B,                
                WRITE_WIDTH_A => wr_a_width,
                WRITE_WIDTH_B => wr_b_width         

                )
           port map (
                ADDRA => addra_pattern,
                ADDRB => addrb_pattern,
                CLKA => CLKA,
                CLKB => CLKB,
                DIA  => dia_pattern,
                DIB  => dib_pattern,
                DIPA => dipa_pattern,
                DIPB => dipb_pattern,
                ENA => ENA,
                ENB => ENB,
                SSRA => RSTA,
                SSRB => RSTB,
                WEA => wea_pattern,
                WEB => web_pattern,
                DOA => doa_pattern,
                DOB => dob_pattern,
                DOPA => dopa_pattern,
                DOPB => dopb_pattern,
                CASCADEOUTLATA => OPEN,
                CASCADEOUTLATB => OPEN,
                CASCADEOUTREGA => OPEN,
                CASCADEOUTREGB => OPEN,
                CASCADEINLATA => '0',
                CASCADEINLATB => '0',
                CASCADEINREGA => '0',
                CASCADEINREGB => '0',
                REGCEA => REGCEA,
                REGCEB => REGCEB
          );
    end generate ramb36_dp;
   
  end generate ramb_v5;
  -- end generate virtex5
  -- begin generate virtex6
  ramb_bl : if (DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate 
    ramb18_dp_bl : if BRAM_SIZE = "18Kb" generate 
      begin

        ram18_bl : RAMB18E1 
          generic map(
                DOA_REG => DOA_REG,
                DOB_REG => DOB_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                INIT_B => INIT_SRVAL_parity_byte(padded_init_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                INIT_FILE => INIT_FILE,
                INIT_00 => INIT_00,
                INIT_01 => INIT_01,
                INIT_02 => INIT_02,
                INIT_03 => INIT_03,
                INIT_04 => INIT_04,
                INIT_05 => INIT_05,
                INIT_06 => INIT_06,
                INIT_07 => INIT_07,
                INIT_08 => INIT_08,
                INIT_09 => INIT_09,
                INIT_0A => INIT_0A,
                INIT_0B => INIT_0B,
                INIT_0C => INIT_0C,
                INIT_0D => INIT_0D,
                INIT_0E => INIT_0E,
                INIT_0F => INIT_0F,
                INIT_10 => INIT_10,
                INIT_11 => INIT_11,
                INIT_12 => INIT_12,
                INIT_13 => INIT_13,
                INIT_14 => INIT_14,
                INIT_15 => INIT_15,
                INIT_16 => INIT_16,
                INIT_17 => INIT_17,
                INIT_18 => INIT_18,
                INIT_19 => INIT_19,
                INIT_1A => INIT_1A,
                INIT_1B => INIT_1B,
                INIT_1C => INIT_1C,
                INIT_1D => INIT_1D,
                INIT_1E => INIT_1E,
                INIT_1F => INIT_1F,
                INIT_20 => INIT_20,
                INIT_21 => INIT_21,
                INIT_22 => INIT_22,
                INIT_23 => INIT_23,
                INIT_24 => INIT_24,
                INIT_25 => INIT_25,
                INIT_26 => INIT_26,
                INIT_27 => INIT_27,
                INIT_28 => INIT_28,
                INIT_29 => INIT_29,
                INIT_2A => INIT_2A,
                INIT_2B => INIT_2B,
                INIT_2C => INIT_2C,
                INIT_2D => INIT_2D,
                INIT_2E => INIT_2E,
                INIT_2F => INIT_2F,
                INIT_30 => INIT_30,
                INIT_31 => INIT_31,
                INIT_32 => INIT_32,
                INIT_33 => INIT_33,
                INIT_34 => INIT_34,
                INIT_35 => INIT_35,
                INIT_36 => INIT_36,
                INIT_37 => INIT_37,
                INIT_38 => INIT_38,
                INIT_39 => INIT_39,
                INIT_3A => INIT_3A,
                INIT_3B => INIT_3B,
                INIT_3C => INIT_3C,
                INIT_3D => INIT_3D,
                INIT_3E => INIT_3E,
                INIT_3F => INIT_3F,
                INITP_00 => INITP_00,
                INITP_01 => INITP_01,
                INITP_02 => INITP_02,
                INITP_03 => INITP_03,
                INITP_04 => INITP_04,
                INITP_05 => INITP_05,
                INITP_06 => INITP_06,
                INITP_07 => INITP_07,
                RAM_MODE => "TDP",
                READ_WIDTH_A => rd_a_width,
                READ_WIDTH_B => rd_b_width,
                SIM_COLLISION_CHECK => SIM_COLLISION_CHECK,
                SIM_DEVICE => sim_device_dp,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                SRVAL_B => INIT_SRVAL_parity_byte(padded_srval_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                WRITE_MODE_A => WRITE_MODE_A,
                WRITE_MODE_B => WRITE_MODE_B,
                WRITE_WIDTH_A => wr_a_width,
                WRITE_WIDTH_B => wr_b_width
              )
          port map (
                ADDRARDADDR => addra_pattern,
                ADDRBWRADDR => addrb_pattern,
                CLKARDCLK => CLKA,
                CLKBWRCLK => CLKB,
                DIADI  => dia_pattern,
                DIBDI => dib_pattern,
                DIPADIP => dipa_pattern,
                DIPBDIP => dipb_pattern,
                ENARDEN => ENA,
                ENBWREN => ENB,
                REGCEAREGCE => REGCEA,
                REGCEB => REGCEB,
                RSTRAMARSTRAM => rstrama_pattern,
                RSTREGARSTREG => rstrega_pattern,
                RSTRAMB => rstramb_pattern,
                RSTREGB => rstregb_pattern,
                WEA => wea_pattern,
                WEBWE => web_pattern_bl ,
                DOADO => doa_pattern,
                DOBDO => dob_pattern,
                DOPADOP => dopa_pattern,
                DOPBDOP => dopb_pattern
        );

    end generate ramb18_dp_bl;
  
    ramb36_dp_bl : if BRAM_SIZE = "36Kb" generate 
      begin
        ram36_bl : RAMB36E1
          generic map (

                DOA_REG => DOA_REG,
                DOB_REG => DOB_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                INIT_B => INIT_SRVAL_parity_byte(padded_init_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                INIT_FILE => INIT_FILE,
		INIT_00 => INIT_00,
		INIT_01 => INIT_01,
		INIT_02 => INIT_02,
		INIT_03 => INIT_03,
		INIT_04 => INIT_04,
		INIT_05 => INIT_05,
		INIT_06 => INIT_06,
		INIT_07 => INIT_07,
		INIT_08 => INIT_08,
		INIT_09 => INIT_09,
		INIT_0A => INIT_0A,
		INIT_0B => INIT_0B,
		INIT_0C => INIT_0C,
		INIT_0D => INIT_0D,
		INIT_0E => INIT_0E,
		INIT_0F => INIT_0F,
		INIT_10 => INIT_10,
		INIT_11 => INIT_11,
		INIT_12 => INIT_12,
		INIT_13 => INIT_13,
		INIT_14 => INIT_14,
		INIT_15 => INIT_15,
		INIT_16 => INIT_16,
		INIT_17 => INIT_17,
		INIT_18 => INIT_18,
		INIT_19 => INIT_19,
		INIT_1A => INIT_1A,
		INIT_1B => INIT_1B,
		INIT_1C => INIT_1C,
		INIT_1D => INIT_1D,
		INIT_1E => INIT_1E,
		INIT_1F => INIT_1F,
		INIT_20 => INIT_20,
		INIT_21 => INIT_21,
		INIT_22 => INIT_22,
		INIT_23 => INIT_23,
		INIT_24 => INIT_24,
		INIT_25 => INIT_25,
		INIT_26 => INIT_26,
		INIT_27 => INIT_27,
		INIT_28 => INIT_28,
		INIT_29 => INIT_29,
		INIT_2A => INIT_2A,
		INIT_2B => INIT_2B,
		INIT_2C => INIT_2C,
		INIT_2D => INIT_2D,
		INIT_2E => INIT_2E,
		INIT_2F => INIT_2F,
		INIT_30 => INIT_30,
		INIT_31 => INIT_31,
		INIT_32 => INIT_32,
		INIT_33 => INIT_33,
		INIT_34 => INIT_34,
		INIT_35 => INIT_35,
		INIT_36 => INIT_36,
		INIT_37 => INIT_37,
		INIT_38 => INIT_38,
		INIT_39 => INIT_39,
		INIT_3A => INIT_3A,
		INIT_3B => INIT_3B,
		INIT_3C => INIT_3C,
		INIT_3D => INIT_3D,
		INIT_3E => INIT_3E,
		INIT_3F => INIT_3F,
		INIT_40 => INIT_40,
		INIT_41 => INIT_41,
		INIT_42 => INIT_42,
		INIT_43 => INIT_43,
		INIT_44 => INIT_44,
		INIT_45 => INIT_45,
		INIT_46 => INIT_46,
		INIT_47 => INIT_47,
		INIT_48 => INIT_48,
		INIT_49 => INIT_49,
		INIT_4A => INIT_4A,
		INIT_4B => INIT_4B,
		INIT_4C => INIT_4C,
		INIT_4D => INIT_4D,
		INIT_4E => INIT_4E,
		INIT_4F => INIT_4F,
		INIT_50 => INIT_50,
		INIT_51 => INIT_51,
		INIT_52 => INIT_52,
		INIT_53 => INIT_53,
		INIT_54 => INIT_54,
		INIT_55 => INIT_55,
		INIT_56 => INIT_56,
		INIT_57 => INIT_57,
		INIT_58 => INIT_58,
		INIT_59 => INIT_59,
		INIT_5A => INIT_5A,
		INIT_5B => INIT_5B,
		INIT_5C => INIT_5C,
		INIT_5D => INIT_5D,
		INIT_5E => INIT_5E,
		INIT_5F => INIT_5F,
		INIT_60 => INIT_60,
		INIT_61 => INIT_61,
		INIT_62 => INIT_62,
		INIT_63 => INIT_63,
		INIT_64 => INIT_64,
		INIT_65 => INIT_65,
		INIT_66 => INIT_66,
		INIT_67 => INIT_67,
		INIT_68 => INIT_68,
		INIT_69 => INIT_69,
		INIT_6A => INIT_6A,
		INIT_6B => INIT_6B,
		INIT_6C => INIT_6C,
		INIT_6D => INIT_6D,
		INIT_6E => INIT_6E,
		INIT_6F => INIT_6F,
		INIT_70 => INIT_70,
		INIT_71 => INIT_71,
		INIT_72 => INIT_72,
		INIT_73 => INIT_73,
		INIT_74 => INIT_74,
		INIT_75 => INIT_75,
		INIT_76 => INIT_76,
		INIT_77 => INIT_77,
		INIT_78 => INIT_78,
		INIT_79 => INIT_79,
		INIT_7A => INIT_7A,
		INIT_7B => INIT_7B,
		INIT_7C => INIT_7C,
		INIT_7D => INIT_7D,
		INIT_7E => INIT_7E,
		INIT_7F => INIT_7F,
		INITP_00 => INITP_00,
		INITP_01 => INITP_01,
		INITP_02 => INITP_02,
		INITP_03 => INITP_03,
		INITP_04 => INITP_04,
		INITP_05 => INITP_05,
		INITP_06 => INITP_06,
		INITP_07 => INITP_07,
		INITP_08 => INITP_08,
		INITP_09 => INITP_09,
		INITP_0A => INITP_0A,
		INITP_0B => INITP_0B,
		INITP_0C => INITP_0C,
		INITP_0D => INITP_0D,
		INITP_0E => INITP_0E,
		INITP_0F => INITP_0F,
                RAM_MODE => "TDP",
		SIM_COLLISION_CHECK => SIM_COLLISION_CHECK,
                SIM_DEVICE => sim_device_dp,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                SRVAL_B => INIT_SRVAL_parity_byte(padded_srval_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                READ_WIDTH_A => rd_a_width,
                READ_WIDTH_B => rd_b_width,                
		WRITE_MODE_A => WRITE_MODE_A,
		WRITE_MODE_B => WRITE_MODE_B,                
                WRITE_WIDTH_A => wr_a_width,
                WRITE_WIDTH_B => wr_b_width         

                )
           port map (
                ADDRARDADDR => addra_pattern,
                ADDRBWRADDR => addrb_pattern,
                CASCADEINA => '0',
                CASCADEINB => '0',
                CLKARDCLK => CLKA,
                CLKBWRCLK => CLKB,
                DIADI  => dia_pattern,
                DIBDI  => dib_pattern,
                DIPADIP => dipa_pattern,
                DIPBDIP => dipb_pattern,
                ENARDEN => ENA,
                ENBWREN => ENB,
                INJECTDBITERR => '0',
                INJECTSBITERR => '0',
                REGCEAREGCE => REGCEA,
                REGCEB => REGCEB,
                RSTRAMARSTRAM => rstrama_pattern,
                RSTREGARSTREG => rstrega_pattern,
                RSTRAMB => rstramb_pattern,
                RSTREGB => rstregb_pattern,
                WEA => wea_pattern,
                WEBWE => web_pattern_bl,
                CASCADEOUTA => OPEN,
                CASCADEOUTB => OPEN,
                DBITERR => OPEN,
                DOADO => doa_pattern,
                DOBDO => dob_pattern,
                DOPADOP => dopa_pattern,
                DOPBDOP => dopb_pattern,
                ECCPARITY => OPEN,
                RDADDRECC => OPEN,
                SBITERR => OPEN
          );
    end generate ramb36_dp_bl;
   
  end generate ramb_bl;
  -- end generate virtex6
  -- begin generate spartan6

ramb_st : if DEVICE = "SPARTAN6" generate 
    ramb9_dp_st : if BRAM_SIZE = "9Kb" generate 
      begin

        ram9_st : RAMB8BWER 
          generic map(
                DOA_REG => DOA_REG,
                DOB_REG => DOB_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                INIT_B => INIT_SRVAL_parity_byte(padded_init_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                INIT_00 => INIT_00,
                INIT_01 => INIT_01,
                INIT_02 => INIT_02,
                INIT_03 => INIT_03,
                INIT_04 => INIT_04,
                INIT_05 => INIT_05,
                INIT_06 => INIT_06,
                INIT_07 => INIT_07,
                INIT_08 => INIT_08,
                INIT_09 => INIT_09,
                INIT_0A => INIT_0A,
                INIT_0B => INIT_0B,
                INIT_0C => INIT_0C,
                INIT_0D => INIT_0D,
                INIT_0E => INIT_0E,
                INIT_0F => INIT_0F,
                INIT_10 => INIT_10,
                INIT_11 => INIT_11,
                INIT_12 => INIT_12,
                INIT_13 => INIT_13,
                INIT_14 => INIT_14,
                INIT_15 => INIT_15,
                INIT_16 => INIT_16,
                INIT_17 => INIT_17,
                INIT_18 => INIT_18,
                INIT_19 => INIT_19,
                INIT_1A => INIT_1A,
                INIT_1B => INIT_1B,
                INIT_1C => INIT_1C,
                INIT_1D => INIT_1D,
                INIT_1E => INIT_1E,
                INIT_1F => INIT_1F,
                INITP_00 => INITP_00,
                INITP_01 => INITP_01,
                INITP_02 => INITP_02,
                INITP_03 => INITP_03,
		INIT_FILE => INIT_FILE,
                DATA_WIDTH_A => rd_a_width,
                DATA_WIDTH_B => rd_b_width,
                RAM_MODE => "TDP",
                SIM_COLLISION_CHECK => SIM_COLLISION_CHECK,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                SRVAL_B => INIT_SRVAL_parity_byte(padded_srval_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                WRITE_MODE_A => WRITE_MODE_A,
                WRITE_MODE_B => WRITE_MODE_B
              )
          port map (
                ADDRAWRADDR => addra_pattern,
                ADDRBRDADDR => addrb_pattern,
                CLKAWRCLK => CLKA,
                CLKBRDCLK => CLKB,
                DIADI  => dia_pattern,
                DIBDI => dib_pattern,
                DIPADIP => dipa_pattern,
                DIPBDIP => dipb_pattern,
                ENAWREN => ENA,
                ENBRDEN => ENB,
                REGCEA => REGCEA,
                REGCEBREGCE => REGCEB,
                RSTA => RSTA,
                RSTBRST => RSTB,
                WEAWEL => wea_pattern,
                WEBWEU => web_pattern ,
                DOADO => doa_pattern,
                DOBDO => dob_pattern,
                DOPADOP => dopa_pattern,
                DOPBDOP => dopb_pattern
        );

    end generate ramb9_dp_st;
  
    ramb18_dp_st : if BRAM_SIZE = "18Kb" generate 
      begin
        ram18_st : RAMB16BWER
          generic map (

                DOA_REG => DOA_REG,
                DOB_REG => DOB_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                INIT_B => INIT_SRVAL_parity_byte(padded_init_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
		INIT_00 => INIT_00,
		INIT_01 => INIT_01,
		INIT_02 => INIT_02,
		INIT_03 => INIT_03,
		INIT_04 => INIT_04,
		INIT_05 => INIT_05,
		INIT_06 => INIT_06,
		INIT_07 => INIT_07,
		INIT_08 => INIT_08,
		INIT_09 => INIT_09,
		INIT_0A => INIT_0A,
		INIT_0B => INIT_0B,
		INIT_0C => INIT_0C,
		INIT_0D => INIT_0D,
		INIT_0E => INIT_0E,
		INIT_0F => INIT_0F,
		INIT_10 => INIT_10,
		INIT_11 => INIT_11,
		INIT_12 => INIT_12,
		INIT_13 => INIT_13,
		INIT_14 => INIT_14,
		INIT_15 => INIT_15,
		INIT_16 => INIT_16,
		INIT_17 => INIT_17,
		INIT_18 => INIT_18,
		INIT_19 => INIT_19,
		INIT_1A => INIT_1A,
		INIT_1B => INIT_1B,
		INIT_1C => INIT_1C,
		INIT_1D => INIT_1D,
		INIT_1E => INIT_1E,
		INIT_1F => INIT_1F,
		INIT_20 => INIT_20,
		INIT_21 => INIT_21,
		INIT_22 => INIT_22,
		INIT_23 => INIT_23,
		INIT_24 => INIT_24,
		INIT_25 => INIT_25,
		INIT_26 => INIT_26,
		INIT_27 => INIT_27,
		INIT_28 => INIT_28,
		INIT_29 => INIT_29,
		INIT_2A => INIT_2A,
		INIT_2B => INIT_2B,
		INIT_2C => INIT_2C,
		INIT_2D => INIT_2D,
		INIT_2E => INIT_2E,
		INIT_2F => INIT_2F,
		INIT_30 => INIT_30,
		INIT_31 => INIT_31,
		INIT_32 => INIT_32,
		INIT_33 => INIT_33,
		INIT_34 => INIT_34,
		INIT_35 => INIT_35,
		INIT_36 => INIT_36,
		INIT_37 => INIT_37,
		INIT_38 => INIT_38,
		INIT_39 => INIT_39,
		INIT_3A => INIT_3A,
		INIT_3B => INIT_3B,
		INIT_3C => INIT_3C,
		INIT_3D => INIT_3D,
		INIT_3E => INIT_3E,
		INIT_3F => INIT_3F,
		INITP_00 => INITP_00,
		INITP_01 => INITP_01,
		INITP_02 => INITP_02,
		INITP_03 => INITP_03,
		INITP_04 => INITP_04,
		INITP_05 => INITP_05,
		INITP_06 => INITP_06,
		INITP_07 => INITP_07,
		INIT_FILE => INIT_FILE,
		SIM_COLLISION_CHECK => SIM_COLLISION_CHECK,
                SIM_DEVICE => "SPARTAN6",
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval_a, read_a_p, write_a_p, READ_WIDTH_A, init_srval_width_size),
                SRVAL_B => INIT_SRVAL_parity_byte(padded_srval_b, read_b_p, write_b_p, READ_WIDTH_B, init_srval_width_size),
                DATA_WIDTH_A => rd_a_width,
                DATA_WIDTH_B => rd_b_width,                
		WRITE_MODE_A => WRITE_MODE_A,
		WRITE_MODE_B => WRITE_MODE_B                

                )
           port map (
                ADDRA => addra_pattern,
                ADDRB => addrb_pattern,
                CLKA => CLKA,
                CLKB => CLKB,
                DIA  => dia_pattern,
                DIB  => dib_pattern,
                DIPA => dipa_pattern,
                DIPB => dipb_pattern,
                ENA => ENA,
                ENB => ENB,
                REGCEA => REGCEA,
                REGCEB => REGCEB,
                RSTA => RSTA,
                RSTB => RSTB,
                WEA => wea_pattern,
                WEB => web_pattern,
                DOA => doa_pattern,
                DOB => dob_pattern,
                DOPA => dopa_pattern,
                DOPB => dopb_pattern
          );
    end generate ramb18_dp_st;
   
  end generate ramb_st;
  -- end generate spartan6

end bram_V;
