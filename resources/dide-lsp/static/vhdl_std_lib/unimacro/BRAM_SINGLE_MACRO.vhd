-------------------------------------------------------------------------------
-- Copyright (c) 1995/2007 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 14.1
--  \   \         Description : Xilinx Functional Simulation Library Component
--  /   /                  Macro for Single Port Block RAM
-- /___/   /\     Filename : BRAM_SINGLE_MACRO.vhd
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

----- CELL BRAM_SINGLE_MACRO -----


library IEEE;
use IEEE.STD_LOGIC_1164.all;

library unisim;
use unisim.VCOMPONENTS.all;
library STD;
use STD.TEXTIO.ALL;


entity BRAM_SINGLE_MACRO is
generic (
    BRAM_SIZE : string := "18Kb";
    DEVICE : string := "VIRTEX5";
    DO_REG : integer := 0;
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
    INIT : bit_vector := X"000000000000000000";
    INIT_FILE : string := "NONE";
    READ_WIDTH : integer := 1;
    SIM_MODE : string := "SAFE"; -- This parameter is valid only for Virtex5
    SRVAL : bit_vector := X"000000000000000000";
    WRITE_MODE : string := "WRITE_FIRST";
    WRITE_WIDTH : integer := 1
  );
-- ports are unconstrained arrays
port (
  
    DO : out std_logic_vector(READ_WIDTH-1 downto 0);
    
    ADDR : in std_logic_vector;
    CLK : in std_ulogic;
    DI : in std_logic_vector(WRITE_WIDTH-1 downto 0);
    EN : in std_ulogic;
    REGCE : in std_ulogic;
    RST : in std_ulogic;
    WE : in std_logic_vector

  );
end BRAM_SINGLE_MACRO;
                                                                        
architecture bram_V of BRAM_SINGLE_MACRO is
 
  function GetDIWidth (
    wr_width : in integer;
    func_bram_size : in string;
    device : in string
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case wr_width is
        when 0 => func_width := 1;
                  write ( Message, WRITE_WIDTH);
                  write( Message, STRING'(". This attribute must atleast be equal to 1 . ") );
                  ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                  DEALLOCATE (Message);
        when 1 => func_width := 1;
        when 2 => func_width := 2;
        when 3|4 => func_width := 4;
        when 5|6|7|8|9 => func_width := 8;
        when 10 to 18 => func_width := 16;
        when 19 to 36 => func_width := 32;
        when 37 to 72 => if (func_bram_size /= "36Kb" and (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") ) then
                         write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH : ") );
                         write ( Message, WRITE_WIDTH);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 18Kb are ") );
                         write( Message, STRING'(" 1 to 36 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                         -- begin s1
                         elsif (func_bram_size /= "18Kb" and (DEVICE = "SPARTAN6") ) then
                         write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH : ") );
                         write ( Message, WRITE_WIDTH);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 9Kb are ") );
                         write( Message, STRING'(" 1 to 36 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message); -- end s1
                       else 
                         func_width := 64;
                       end if;
        when others => if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
                       write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH : ") );
                       write ( Message, WRITE_WIDTH);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 18Kb and ") );
                       write( Message, STRING'(" 1 to 72 for BRAM_SIZE of 36Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message);
                       -- begin s2
                       elsif(DEVICE = "SPARTAN6") then
                       write( Message, STRING'("Illegal value of Attribute WRITE_WIDTH : ") );
                       write ( Message, WRITE_WIDTH);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 9Kb and ") );
                       write( Message, STRING'(" 1 to 72 for BRAM_SIZE of 18Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message); -- end s2
                       end if;
      end case;
    else
      func_width := 1;
    end if;
    return func_width;
  end;
  function GetDOWidth (
    rd_width : in integer;
    func_bram_size : in string;
    device : in string;
    wr_width : in integer
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    -- begin s15
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      if(DEVICE = "SPARTAN6") then
        if(rd_width /= wr_width) then
          write( Message, STRING'("WRITE_WIDTH and READ_WIDTH must be equal. ") );
          write ( Message, WRITE_WIDTH);
          write ( Message, READ_WIDTH);
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
        end if;
      end if;	
      if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
        if((rd_width /= wr_width) and (rd_width/wr_width /=2) and (wr_width/rd_width /=2) and (wr_width/rd_width /=2) and ((rd_width /= 1 and rd_width /= 2 and rd_width /= 4 and rd_width /= 8 and rd_width /= 9 and rd_width /= 16 and rd_width /= 18 and rd_width /= 32 and rd_width /= 36 and rd_width /= 64 and rd_width /= 72) or (wr_width /= 1 and wr_width /= 2 and wr_width /= 4 and wr_width /= 8 and wr_width /= 9 and wr_width /= 16 and wr_width /= 18 and wr_width /= 32 and wr_width /= 36 and wr_width /= 64 and wr_width /= 72)) ) then
	 write( Message, STRING'("Illegal values of Attributes  READ_WIDTH, WRITE_WIDTH : ") );
         write ( Message, READ_WIDTH);
         write ( Message, STRING'(" and "));
         write ( Message, WRITE_WIDTH);
         write( Message, STRING'(" To use BRAM_SINGLE_MACRO. One of the following conditions must be true- 1. READ_WIDTH must be equal to WRITE_WIDTH  2. If assymetric, READ_WIDTH and WRITE_WIDTH must have a ratio of 2. 3. If assymetric, READ_WIDTH and WRITE_WIDTH should have values 1, 2, 4, 8, 9, 16, 18, 32, 36, 64, 72.") );
         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
         DEALLOCATE (Message);
        end if;
      end if;	
      case rd_width is
        when 0 => func_width := 1;
                  write( Message, STRING'("Illegal value of Attribute READ_WIDTH : ") );
                  write ( Message, READ_WIDTH);
                  write( Message, STRING'(". This attribute must atleast be equal to 1 . ") );
                  ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                  DEALLOCATE (Message);
        when 1 => func_width := 1;
        when 2 => func_width := 2;
        when 3|4 => func_width := 4;
        when 5|6|7|8|9 => func_width := 8;
        when 10 to 18 => func_width := 16;
        when 19 to 36 => func_width := 32;
        when 37 to 72 => if (func_bram_size /= "36Kb" and (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") ) then
                         write( Message, STRING'("Illegal value of Attribute READ_WIDTH : ") );
                         write ( Message, READ_WIDTH);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 18Kb are ") );
                         write( Message, STRING'(" 1 to 36 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                         -- begin s3 
                         elsif (func_bram_size /= "18Kb" and (DEVICE = "SPARTAN6") ) then
                         write( Message, STRING'("Illegal value of Attribute READ_WIDTH : ") );
                         write ( Message, READ_WIDTH);
                         write( Message, STRING'(". Legal values of this attribute for BRAM_SIZE 9Kb are ") );
                         write( Message, STRING'(" 1 to 36 .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message); -- end s3
                       else
                        func_width := 64;
                      end if;
        when others => if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
                       write( Message, STRING'("Illegal value of Attribute READ_WIDTH : ") );
                       write ( Message, READ_WIDTH);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 18Kb and ") );
                       write( Message, STRING'(" 1 to 72 for BRAM_SIZE of 36Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message);
                       -- begin s4
                       elsif(DEVICE = "SPARTAN6") then
                       write( Message, STRING'("Illegal value of Attribute READ_WIDTH : ") );
                       write ( Message, READ_WIDTH);
                       write( Message, STRING'(". Legal values of this attribute are ") );
                       write( Message, STRING'(" 1 to 36 for BRAM_SIZE of 9Kb and ") );
                       write( Message, STRING'(" 1 to 72 for BRAM_SIZE of 18Kb .") );
                       ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                       DEALLOCATE (Message); -- end s4
                       end if;
                     func_width := 1;
      end case;
    else
      func_width := 1;
    end if;
    return func_width;
  end;
  function GetD_Width (
    d_width : in integer;
    device : in string
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case d_width is
        when 0 => func_width := 0;
        when 1 => func_width := 1;
        when 2 => func_width := 2;
        when 3|4 => func_width := 4;
        when 5|6|7|8|9 => func_width := 9;
        when 10 to 18 => func_width := 18;
        when 19 to 36 => func_width := 36;
        when 37 to 72 => func_width := 72;
        when others => func_width := 1;
      end case;
    else
      func_width := 1;
    end if;
    return func_width;
  end;
  function GetDPWidth (
    wr_width : in integer;
    func_bram_size : in string;
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case wr_width is
        when 9 => func_width := 1;
        when 17 => func_width := 1;
        when 18 => func_width := 2;
        when 33 => func_width := 1;
        when 34 => func_width := 2;
        when 35 => func_width := 3;
        when 36 => func_width := 4;
        when 65 => func_width := 1;
        when 66 => func_width := 2;
        when 67 => func_width := 3;
        when 68 => func_width := 4;
        when 69 => func_width := 5;
        when 70 => func_width := 6;
        when 71 => func_width := 7;
        when 72 => func_width := 8;
        when others => func_width := 0;
      end case;
    else
      func_width := 0;
    end if;
  return func_width;
  end;
  function GetLeastWidth (
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
  function GetADDRWidth (
    least_widthA : in integer;
    func_bram_size : in string;
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      case least_widthA is
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
        when 19 to 36 => if (func_bram_size = "9Kb") then
                     func_width := 8;
                   elsif (func_bram_size = "18Kb") then
                    func_width := 9;
                   else
                     func_width := 10;
                   end if;
        when 37 to 72 => if (func_bram_size = "36Kb") then
                     func_width := 9;
                   else
                     func_width := 14;
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
      if bram_size= "18Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        end if;
      elsif bram_size = "36Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        elsif wr_width > 36 and wr_width <= 72 then
          func_width := 8;
        end if;
      else
        func_width := 8;
      end if;
   -- begin s1
    elsif(DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        else
          func_width := 4;
        end if;
      elsif bram_size = "18Kb" then
        if wr_width <= 9 then
          func_width := 1;
        elsif wr_width > 9 and wr_width <= 18 then
          func_width := 2;
        elsif wr_width > 18 and wr_width <= 36 then
          func_width := 4;
        elsif wr_width > 36 and wr_width <= 72 then
          func_width := 8;
        else
          func_width := 4;
        end if;
     end if; -- end s1
    else 
      func_width := 8;
    end if;
    return func_width;
  end;
  function GetMaxADDRSize (
    bram_size : in string; 
    device : in string
    ) return integer is
    variable func_width : integer;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
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
    d_width : in integer;
    bram_size : in string; 
    device : in string 
    ) return integer is
    variable func_width : integer;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if bram_size = "18Kb" and d_width <= 18 then
        func_width := 16;
      elsif bram_size = "18Kb" and d_width > 18 and d_width <= 36 then
        func_width := 32;
      elsif bram_size = "36Kb" and d_width <= 36 then
        func_width := 32;
      elsif bram_size = "36Kb" and d_width > 36 and d_width <= 72 then
        func_width := 64;
      else
        func_width := 64;
      end if;
    -- begin s5 
    elsif (DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" and d_width <= 18 then
        func_width := 16;
      elsif bram_size = "9Kb" and d_width > 18 and d_width <= 36 then
        func_width := 32;
      elsif bram_size = "18Kb" and d_width <= 36 then
        func_width := 32;
      elsif bram_size = "18Kb" and d_width <= 72 then
        func_width := 64;
      else
        func_width := 32;
      end if; -- end s5
    else
      func_width := 64;
    end if;
    return func_width;
  end;
  
  function GetMaxDataPSize (
    d_width : in integer;
    bram_size : in string; 
    device : in string 
    ) return integer is
    variable func_width : integer;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if bram_size = "18Kb" and d_width <= 18 then
        func_width := 2;
      elsif bram_size = "18Kb" and d_width > 18 and d_width <= 36 then
        func_width := 4;
      elsif bram_size = "36Kb" and d_width <= 36 then
        func_width := 4;
      elsif bram_size = "36Kb" and d_width > 36 and d_width <= 72 then
        func_width := 8;
      else
        func_width := 8;
      end if;
    -- begin s6
    elsif (DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" and d_width <= 18 then
        func_width := 2;
      elsif bram_size = "9Kb" and d_width > 18 and d_width <= 36 then
        func_width := 4;
      elsif bram_size = "18Kb" and d_width <= 36 then
        func_width := 4;
      elsif bram_size = "18Kb" and d_width <= 72 then
        func_width := 8;
      else
        func_width := 4;
      end if; -- end s6
    else
      func_width := 8;
    end if;
    return func_width;
  end;
  function GetMaxWESize (
    d_width : in integer;
    bram_size : in string; 
    device : in string 
    ) return integer is
    variable func_width : integer;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if bram_size = "18Kb" and d_width <= 18 then
        func_width := 2;
      elsif bram_size = "18Kb" and d_width > 18 and d_width <= 36 then
        func_width := 4;
      elsif bram_size = "36Kb" and d_width <= 36 then
        func_width := 4;
      elsif bram_size = "36Kb" and d_width > 36 and d_width <= 72 then
        func_width := 8;
      else
        func_width := 8;
      end if;
    -- begin s7
    elsif (DEVICE = "SPARTAN6") then
      if bram_size = "9Kb" and d_width <= 18 then
        func_width := 2;
      elsif bram_size = "9Kb" and d_width > 18 and d_width <= 36 then
        func_width := 4;
      elsif bram_size = "18Kb" and d_width <= 36 then
        func_width := 4;
      elsif bram_size = "18Kb" and d_width > 36 and d_width <= 72 then
        func_width := 8;
      else
        func_width := 4;
      end if; -- end s7
    else
      func_width := 8;
    end if;
    return func_width;
  end;
  function GetFinalWidthRD (
    rd_width_a : in integer
    ) return integer is
    variable func_least_width : integer;
  begin
    if (rd_width_a = 0) then
      func_least_width := 1;
    else
      func_least_width := rd_width_a;
    end if;
    return func_least_width;
  end;
  function GetFinalWidthWRA (
    wr_width_a : in integer
    ) return integer is
    variable func_least_width : integer;
  begin
    if (wr_width_a = 0) then
      func_least_width := 1;
    else
      func_least_width := wr_width_a;
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
   -- begin s9
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
    end if; -- end s9
    return bram_val;
  end;
  function GetD_P (
    dw : in integer;
    device : in string 
    ) return boolean is
    variable wp : boolean;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      if dw = 9 or dw = 17 or dw = 18 or dw = 33 or dw = 34 or dw = 35 or dw = 36 or dw = 65 or dw = 66 or dw = 67 or dw = 68 or dw = 69 or dw = 70 or dw = 71 or dw = 72 then
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
  wp_a, rp_a : in boolean;
    device : in string
  ) return boolean is
  variable Message : LINE;
  variable check : boolean;
  begin
    if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "SPARTAN6" or DEVICE = "7SERIES") then
      if ( (wp_a = FALSE and rp_a = FALSE ) or  (wp_a = TRUE and rp_a = TRUE) ) then 
        check := FALSE;
        elsif(wp_a = TRUE and rp_a = FALSE) then
          write( Message, STRING'("Port Width Mismatch : ") );
          write( Message, STRING'("The attribute ") );
          write( Message, STRING'("WRITE_WIDTH on BRAM_SINGLE_MACRO is set to ") );
          write( Message, WRITE_WIDTH);
          write( Message, STRING'(". The parity bit(s) cannot be read") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Warning;
          DEALLOCATE (Message);
        elsif(wp_a = FALSE and rp_a = TRUE) then
          write( Message, STRING'("Port Width Mismatch : ") );
          write( Message, STRING'("The attribute ") );
          write( Message, STRING'("READ_WIDTH on BRAM_SINGLE_MACRO is set to ") );
          write( Message, READ_WIDTH);
          write( Message, STRING'(". The parity bit(s) have not been written and hence cannot be read") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Warning;
          DEALLOCATE (Message);
      end if;
    end if;
  return check;
  end;

  function GetINITSRVALWidth (
  bram_size : in string;
  device : in string
  ) return integer is
    variable init_srval : integer;
  begin
     if ( DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
       if(bram_size = "18Kb") then
         init_srval := 20; 
       elsif (bram_size = "36Kb") then
         init_srval := 36; 
       end if;
     end if;
     -- begin s20
     if (DEVICE = "SPARTAN6") then
       if(bram_size = "9Kb") then
         init_srval := 20; 
       elsif (bram_size = "18Kb") then
         init_srval := 36; 
       end if;
     end if; -- end s20
 return init_srval;
 end; 
  function init_a_size (
  inputvec : in bit_vector;
  init_width : in integer;
  rd_width : in integer;
  wr_width : in integer;
  device : in string
  ) return bit_vector is
    variable init_a_resize : bit_vector(0 to (init_width-1));
  begin
     if ( DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then 
       if(bram_size = "18Kb" and ((rd_width > 18) and (wr_width > 18))) then
         init_a_resize := "00" & inputvec(0 to 1) & inputvec(4 to 19); 
       elsif (bram_size = "36Kb" and ((rd_width > 36) and (wr_width > 36))) then
         init_a_resize := inputvec(0 to 3) & inputvec(8 to 39); 
       end if;
     end if;
    -- begin s16
     if (DEVICE = "SPARTAN6") then
       if(bram_size = "9Kb" and ((rd_width > 18) and (wr_width > 18))) then
         init_a_resize := "00" & inputvec(0 to 1) & inputvec(4 to 19); 
       elsif(bram_size = "18Kb" and ((rd_width > 36) and (wr_width > 36))) then
         init_a_resize := inputvec(0 to 3) & inputvec(8 to 39); 
       end if;
     end if; -- end s16
 return init_a_resize;
 end;

 function init_b_size (
  inputvec : in bit_vector;
  init_width : in integer;
  rd_width : in integer;
  wr_width : in integer;
  device : in string
  ) return bit_vector is
    variable init_b_resize : bit_vector(0 to (init_width-1));
  begin
    if ( DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then 
       if(BRAM_SIZE = "18Kb" and ((rd_width > 18) and (wr_width > 18))) then
         init_b_resize := "00" & inputvec(2 to 3) & inputvec(20 to 35); 
       elsif (bram_size = "36Kb" and ((rd_width > 36) and (wr_width > 36))) then
         init_b_resize := inputvec(4 to 7) & inputvec(40 to 71); 
       end if;
     end if;
    -- begin s17
     if (DEVICE = "SPARTAN6") then
       if(bram_size = "9Kb" and ((rd_width > 18) and (wr_width > 18))) then
         init_b_resize := "00" & inputvec(2 to 3) & inputvec(20 to 35); 
       elsif(bram_size = "18Kb" and ((rd_width > 36) and (wr_width > 36))) then
         init_b_resize := inputvec(4 to 7) & inputvec(40 to 71); 
       end if;
     end if; -- end s17
 return init_b_resize;
 end;
 function srval_a_size (
  inputvec : in bit_vector;
  srval_width : in integer;
  rd_width : in integer;
  wr_width : in integer;
  device : in string
  ) return bit_vector is
    variable srval_a_resize : bit_vector(0 to (srval_width-1));
  begin
    if ( DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then 
       if(bram_size = "18Kb" and ((rd_width > 18) and (wr_width > 18))) then
         srval_a_resize := "00" & inputvec(0 to 1) & inputvec(4 to 19); 
       elsif (bram_size = "36Kb" and ((rd_width > 36) and (wr_width > 36))) then
         srval_a_resize := inputvec(0 to 3) & inputvec(8 to 39); 
       end if;
     end if;
    -- begin s18
     if (DEVICE = "SPARTAN6") then
       if(bram_size = "9Kb" and ((rd_width > 18) and (wr_width > 18))) then
         srval_a_resize := "00" & inputvec(0 to 1) & inputvec(4 to 19); 
       elsif(bram_size = "18Kb" and ((rd_width > 36) and (wr_width > 36))) then
         srval_a_resize := inputvec(0 to 3) & inputvec(8 to 39); 
       end if;
     end if; -- end s18
 return srval_a_resize;
 end;
 function srval_b_size (
  inputvec : in bit_vector;
  srval_width : in integer;
  rd_width : in integer;
  wr_width : in integer;
  device : in string
  ) return bit_vector is
    variable srval_b_resize : bit_vector(0 to (srval_width-1));
  begin
      if ( DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then 
       if(bram_size = "18Kb" and ((rd_width > 18) and (wr_width > 18))) then
         srval_b_resize := "00" & inputvec(2 to 3) & inputvec(20 to 35); 
       elsif (BRAM_SIZE = "36Kb" and ((rd_width > 36) and (wr_width > 36))) then
         srval_b_resize := inputvec(4 to 7) & inputvec(40 to 71); 
       end if;
     end if;
    -- begin s19
     if (DEVICE = "SPARTAN6") then
       if(bram_size = "9Kb" and ((rd_width > 18) and (wr_width > 18))) then
         srval_b_resize := "00" & inputvec(2 to 3) & inputvec(20 to 35); 
       elsif(bram_size = "18Kb" and ((rd_width > 36) and (wr_width > 36))) then
         srval_b_resize := inputvec(4 to 7) & inputvec(40 to 71); 
       end if;
     end if; -- end s19
 return srval_b_resize;
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

  function GetValWidth (
  rd_width : in integer;
  wr_width : in integer
    ) return boolean is
  begin
   if ((rd_width = 1 or rd_width = 2 or rd_width = 4 or rd_width = 8 or rd_width = 9 or rd_width = 16 or rd_width = 18 or rd_width = 32 or rd_width = 36 or rd_width = 64 or rd_width = 72) and (wr_width = 1 or wr_width = 2 or wr_width = 4 or wr_width = 8 or wr_width = 9 or wr_width = 16 or wr_width = 18 or wr_width = 32 or wr_width = 36 or wr_width = 64 or wr_width = 72)) then
    return TRUE;
    else
    return FALSE;
   end if; 
  end;

  function CheckWEWidth (
  wr_width : in integer;
  we_vec : in integer
  ) return boolean is
  variable Message : LINE;
  begin
    if ( wr_width <= 9 and we_vec /= 1) then
      write( Message, STRING'("WE port width incorrectly set for WRITE_WIDTH : ") );
      write( Message, WRITE_WIDTH);
      write( Message, STRING'(". WE port width  must be of width 1 (0 downto 0) . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
    elsif ( (wr_width > 9 and wr_width <= 18) and we_vec /= 2) then  
      write( Message, STRING'("WE port width incorrectly set for WRITE_WIDTH : ") );
      write( Message, WRITE_WIDTH);
      write( Message, STRING'(". WE port width  must be of width 2 . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
    elsif ( (wr_width > 18 and wr_width <= 36) and we_vec /= 4) then  
      write( Message, STRING'("WE port width incorrectly set for WRITE_WIDTH : ") );
      write( Message, WRITE_WIDTH);
      write( Message, STRING'(". WE port width  must be of width 4 . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
      return FALSE;
     elsif ( (wr_width > 36 and wr_width <= 72) and we_vec /= 8) then  
      write( Message, STRING'("WE port width incorrectly set for WRITE_WIDTH : ") );
      write( Message, WRITE_WIDTH);
      write( Message, STRING'(". WE port width  must be of width 8 . ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);  
      return FALSE;
     else
       return TRUE;
     end if;
   end;  

  function CheckADDRWidth (
    least_widthA : in integer;
    func_bram_size : in string;
    device : in string;
    addr_vec : in integer
    ) return boolean is
    variable Message : LINE;
  begin
      if (func_bram_size  = "9Kb") then
        if (least_widthA = 1 and addr_vec /= 13) then
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_widthA = 2 and addr_vec /= 12) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 2 and least_widthA <= 4) and addr_vec /= 11) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 4 and least_widthA <= 9) and addr_vec /= 10) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 9 and least_widthA <= 18) and addr_vec /= 9) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 9 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 18 and least_widthA <= 36) and addr_vec /= 8) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 8 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
	else
	  return TRUE;
        end if;
      elsif (func_bram_size = "18Kb") then 	
        if (least_widthA = 1 and addr_vec /= 14) then
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 14 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_widthA = 2 and addr_vec /= 13) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 2 and least_widthA <= 4) and addr_vec /= 12) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 4 and least_widthA <= 9) and addr_vec /= 11) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 9 and least_widthA <= 18) and addr_vec /= 10) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 18 and least_widthA <= 36) and addr_vec /= 9) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 9 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
	else
          return TRUE;
	end if;
      elsif (func_bram_size = "36Kb") then 	
        if (least_widthA = 1 and addr_vec /= 15) then
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 15 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif (least_widthA = 2 and addr_vec /= 14) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 14 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 2 and least_widthA <= 4) and addr_vec /= 13) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 13 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 4 and least_widthA <= 9) and addr_vec /= 12) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 12 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 9 and least_widthA <= 18) and addr_vec /= 11) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 11 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 18 and least_widthA <= 36) and addr_vec /= 10) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 10 . ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return FALSE;
       	elsif ((least_widthA > 36 and least_widthA <= 72) and addr_vec /= 9) then	    
	  write( Message, STRING'("ADDR port width incorrectly set. ") );
          write( Message, STRING'(". ADDR port width  must be of width 9 . ") );
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
    if (wd = 9 or wd = 17 or wd = 33 or wd = 65) then
        wp := 1;
    elsif (wd = 18 or wd = 34 or wd = 66) then
      wp := 2;
    elsif (wd = 35 or wd = 67) then
      wp := 3;
    elsif (wd = 36 or wd = 68) then
      wp := 4;
    elsif (wd = 69) then
      wp := 5;
    elsif (wd = 70) then
      wp := 6; 
    elsif (wd = 71) then
      wp := 7;
    elsif (wd = 72) then
      wp := 8;
    else
      wp := 8;
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
        if (READ_WIDTH > 36 or WRITE_WIDTH > 36) then
          init_srval_width := 72;
        else
          init_srval_width := 36;
        end if;

      elsif(bram_size = "18Kb") then
        if (func_device = "SPARTAN6" or (READ_WIDTH > 18 or WRITE_WIDTH > 18)) then
          init_srval_width := 36;
        else
          init_srval_width := 20;
        end if;
      elsif (bram_size = "9Kb") then
        if (WRITE_WIDTH > 18) then
          init_srval_width := 36;
        else
          init_srval_width := 20;
        end if;
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
        elsif (init_srval_width = 36) then
          out_init_srval := "000000000000000000000000000" & in_init_srval(27) & in_init_srval(28 to 35);
        else
          out_init_srval := "000" & X"000000000000000" & in_init_srval(63) & in_init_srval(64 to 71);
        end if;
      elsif (read_widthp = 17) then
        if (init_srval_width = 20) then
          out_init_srval := "000" & in_init_srval(11) & in_init_srval(3 to 10) & in_init_srval(12 to 19);
        elsif (init_srval_width = 36) then
          out_init_srval := "0000000000000000000" & in_init_srval(27) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
        else
          out_init_srval := "000" & X"0000000000000" & in_init_srval(63) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
        end if;
      elsif (read_widthp = 18) then
        if (init_srval_width = 20) then
          out_init_srval := "00" & in_init_srval(2) & in_init_srval(11) & in_init_srval(3 to 10) & in_init_srval(12 to 19);
        elsif (init_srval_width = 36) then
          out_init_srval := "000000000000000000" & in_init_srval(18) & in_init_srval(27) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
        else
          out_init_srval := "00" & X"0000000000000" & in_init_srval(54) & in_init_srval(63) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
        end if;
      elsif (read_widthp = 33) then
        if (init_srval_width = 36) then
          out_init_srval := "000" & in_init_srval(27) & in_init_srval(3 to 26) & in_init_srval(28 to 35);
        else
          out_init_srval := "000" & X"000000000" & in_init_srval(63) & in_init_srval(39 to 62) & in_init_srval(64 to 71);
        end if;
      elsif (read_widthp = 34) then
        if (init_srval_width = 36) then
          out_init_srval := "00" & in_init_srval(18) & in_init_srval(27) & in_init_srval(2 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
        else
          out_init_srval := "00" & X"000000000" & in_init_srval(54) & in_init_srval(63) & in_init_srval(38 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
        end if;
      elsif (read_widthp = 35) then
        if (init_srval_width = 36) then
          out_init_srval := '0' & in_init_srval(9) & in_init_srval(18) & in_init_srval(27) & in_init_srval(1 to 8) & in_init_srval(10 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
        else
          out_init_srval := '0' & X"000000000" & in_init_srval(45) & in_init_srval(54) & in_init_srval(63) & in_init_srval(37 to 44) & in_init_srval(46 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
        end if;
      elsif (read_widthp = 36) then
        if (init_srval_width = 36) then
          out_init_srval := in_init_srval(0) & in_init_srval(9) & in_init_srval(18) & in_init_srval(27) & in_init_srval(1 to 8) & in_init_srval(10 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35);
        else
          out_init_srval := X"000000000" & in_init_srval(36) & in_init_srval(45) & in_init_srval(54) & in_init_srval(63) & in_init_srval(37 to 44) & in_init_srval(46 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
        end if;
      elsif (read_widthp = 65) then
        out_init_srval := "0000000" & in_init_srval(63) & in_init_srval(7 to 62) & in_init_srval(64 to 71);
      elsif (read_widthp = 66) then
        out_init_srval := "000000" & in_init_srval(54) & in_init_srval(63) & in_init_srval(6 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
      elsif (read_widthp = 67) then
        out_init_srval := "00000" & in_init_srval(45) & in_init_srval(54) & in_init_srval(63) & in_init_srval(5 to 44) & in_init_srval(46 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
      elsif (read_widthp = 68) then
        out_init_srval := "0000" & in_init_srval(36) & in_init_srval(45) & in_init_srval(54) & in_init_srval(63) & in_init_srval(4 to 35) & in_init_srval(37 to 44) & in_init_srval(46 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
      elsif (read_widthp = 69) then
        out_init_srval := "000" & in_init_srval(27) & in_init_srval(36) & in_init_srval(45) & in_init_srval(54) & in_init_srval(63) & in_init_srval(3 to 26) & in_init_srval(28 to 35) & in_init_srval(37 to 44) & in_init_srval(46 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
      elsif (read_widthp = 70) then
        out_init_srval := "00" & in_init_srval(18) & in_init_srval(27) & in_init_srval(36) & in_init_srval(45) & in_init_srval(54) & in_init_srval(63) & in_init_srval(2 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35) & in_init_srval(37 to 44) & in_init_srval(46 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
      elsif (read_widthp = 71) then
        out_init_srval := '0' & in_init_srval(9) & in_init_srval(18) & in_init_srval(27) & in_init_srval(36) & in_init_srval(45) & in_init_srval(54) & in_init_srval(63) & in_init_srval(1 to 8) & in_init_srval(10 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35) & in_init_srval(37 to 44) & in_init_srval(46 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
      elsif (read_widthp = 72) then
        out_init_srval := in_init_srval(0) & in_init_srval(9) & in_init_srval(18) & in_init_srval(27) & in_init_srval(36) & in_init_srval(45) & in_init_srval(54) & in_init_srval(63) & in_init_srval(1 to 8) & in_init_srval(10 to 17) & in_init_srval(19 to 26) & in_init_srval(28 to 35) & in_init_srval(37 to 44) & in_init_srval(46 to 53) & in_init_srval(55 to 62) & in_init_srval(64 to 71);
      else
        out_init_srval := in_init_srval;
      end if;

    else
      out_init_srval := in_init_srval;
    end if;
    
    return out_init_srval;  
                         
  end;      

    
  constant bram_size_val : boolean := GetBRAMSize(BRAM_SIZE, DEVICE);
  constant write_p : boolean := GetD_P(WRITE_WIDTH, DEVICE);
  constant read_p : boolean := GetD_P(READ_WIDTH, DEVICE);
  constant di_width : integer := GetDIWidth(WRITE_WIDTH, BRAM_SIZE, DEVICE);
  constant dip_width : integer := GetDPWidth(WRITE_WIDTH, BRAM_SIZE, DEVICE);
  constant do_width : integer := GetDOWidth(READ_WIDTH, BRAM_SIZE, DEVICE, WRITE_WIDTH);
  constant dop_width : integer := GetDPWidth(READ_WIDTH, BRAM_SIZE, DEVICE);
  constant wr_width : integer := GetD_Width (WRITE_WIDTH, DEVICE);
  constant rd_width : integer := GetD_Width (READ_WIDTH, DEVICE);
  constant check_p : boolean := CheckParity(write_p, read_p, DEVICE);
  constant least_width : integer := GetLeastWidth(di_width, do_width);
  constant addr_width : integer := GetADDRWidth(least_width, BRAM_SIZE, DEVICE);
  constant we_width : integer := GetWEWidth(BRAM_SIZE, DEVICE, WRITE_WIDTH);
  constant rd_byte_width : integer := GetWEWidth(BRAM_SIZE, DEVICE, READ_WIDTH);
  constant fin_rd_width : integer := GetFinalWidthRD(READ_WIDTH);
  constant fin_wr_width : integer := GetFinalWidthWRA(WRITE_WIDTH);
  constant sim_device_dp : string := GetSIMDev(DEVICE);
  constant valid_width : boolean := GetValWidth(READ_WIDTH,WRITE_WIDTH);
  constant weleng : integer := WE'length;
  constant addrleng : integer := ADDR'length;
  constant checkwe : boolean := CheckWEWidth(WRITE_WIDTH, weleng);
  constant checkaddr : boolean :=  CheckADDRWidth(least_width, BRAM_SIZE, DEVICE, addrleng);

  constant max_addr_width : integer := GetMaxADDRSize(BRAM_SIZE, DEVICE);
  constant max_read_width : integer := GetMaxDataSize(READ_WIDTH,BRAM_SIZE, DEVICE);
  constant max_write_width : integer := GetMaxDataSize(WRITE_WIDTH,BRAM_SIZE, DEVICE);
  constant max_readp_width : integer := GetMaxDataPSize(READ_WIDTH,BRAM_SIZE, DEVICE);
  constant max_writep_width : integer := GetMaxDataPSize(WRITE_WIDTH,BRAM_SIZE, DEVICE);
  constant max_we_width : integer := GetMaxWESize(WRITE_WIDTH,BRAM_SIZE, DEVICE);
  
  signal addr_pattern : std_logic_vector(max_addr_width-1 downto 0) := (others=> '0');
  signal addra_pattern : std_logic_vector(max_addr_width-1 downto 0) := (others=> '0');
  signal addrb_pattern : std_logic_vector(max_addr_width-1 downto 0) := (others=> '0');

--  signal di_pattern : std_logic_vector(max_read_width-1 downto 0) := (others=>'0');
  signal di_pattern : std_logic_vector(max_write_width-1 downto 0) := (others=>'0');  
  signal dip_pattern : std_logic_vector(max_writep_width-1 downto 0) := (others=>'0');  
--  signal do_pattern : std_logic_vector(max_write_width-1 downto 0);
  signal do_pattern : std_logic_vector(max_read_width-1 downto 0);  
  signal dop_pattern : std_logic_vector(max_readp_width-1 downto 0) := (others=>'0');  
  signal we_pattern : std_logic_vector(max_we_width-1 downto 0) := (others=>'0');  
  signal rstram_pattern : std_logic := '0';
  signal rstreg_pattern : std_logic := '0';

  constant init_srval_width_size : integer := Get_INIT_SRVAL_Width(BRAM_SIZE, DEVICE);
  constant padded_init : bit_vector(0 to init_srval_width_size-1) := Pad_INIT_SRVAL(INIT, init_srval_width_size);
  constant padded_srval : bit_vector(0 to init_srval_width_size-1) := Pad_INIT_SRVAL(SRVAL, init_srval_width_size);
  constant wr_widthp : integer := Get_Parity_Width(WRITE_WIDTH);
  constant rd_widthp : integer := Get_Parity_Width(READ_WIDTH);

  constant init_srval_width : integer := GetINITSRVALWidth(BRAM_SIZE, DEVICE);
  constant init_a_pattern : bit_vector := init_a_size(INIT_SRVAL_parity_byte(padded_init, read_p, write_p, READ_WIDTH, init_srval_width_size), init_srval_width, READ_WIDTH, WRITE_WIDTH, DEVICE);
  constant init_b_pattern : bit_vector := init_b_size(INIT_SRVAL_parity_byte(padded_init, read_p, write_p, READ_WIDTH, init_srval_width_size), init_srval_width, READ_WIDTH, WRITE_WIDTH, DEVICE);
  constant srval_a_pattern : bit_vector := srval_a_size(INIT_SRVAL_parity_byte(padded_srval, read_p, write_p, READ_WIDTH, init_srval_width_size), init_srval_width, READ_WIDTH, WRITE_WIDTH, DEVICE);
  constant srval_b_pattern : bit_vector := srval_b_size(INIT_SRVAL_parity_byte(padded_srval, read_p, write_p, READ_WIDTH, init_srval_width_size), init_srval_width, READ_WIDTH, WRITE_WIDTH, DEVICE);

  constant read_double :integer:= READ_WIDTH * 2;

begin

  
adr_vir : if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
    adgen1 : if ( (BRAM_SIZE = "18Kb" and READ_WIDTH <= 18 and WRITE_WIDTH <= 18) or (BRAM_SIZE = "36Kb" and READ_WIDTH <= 36 and WRITE_WIDTH <= 36) ) generate
      begin
                   a1 : addr_pattern <=  
                   ADDR when (BRAM_SIZE = "18Kb" and addr_width = 14 ) else
                   (ADDR & '1') when (BRAM_SIZE = "18Kb" and addr_width = 13 ) else
                   (ADDR & "11") when (BRAM_SIZE = "18Kb" and addr_width = 12) else
                   (ADDR & "111") when (BRAM_SIZE = "18Kb" and addr_width = 11 ) else
                   (ADDR & "1111") when (BRAM_SIZE = "18Kb" and addr_width = 10 ) else
                   ADDR when (BRAM_SIZE = "36Kb" and addr_width = 16 ) else
                   ('1' & ADDR) when (BRAM_SIZE = "36Kb" and addr_width = 15 ) else
                   ('1' & ADDR & '1') when (BRAM_SIZE = "36Kb" and addr_width = 14 ) else
                   ('1' & ADDR & "11") when (BRAM_SIZE = "36Kb" and addr_width = 13 ) else
                   ('1' & ADDR & "111") when (BRAM_SIZE = "36Kb" and addr_width = 12 ) else
                   ('1' & ADDR & "1111") when (BRAM_SIZE = "36Kb" and addr_width = 11 ) else
                   ('1' & ADDR & "11111") when (BRAM_SIZE = "36Kb" and addr_width = 10 ) else
                   (others => '1');
      end generate adgen1;
     adgen2 : if ( (BRAM_SIZE = "18Kb" and (WRITE_WIDTH > 18 and WRITE_WIDTH <= 36) and (READ_WIDTH > 18 and READ_WIDTH <= 36)) or 
                   (BRAM_SIZE = "36Kb" and (WRITE_WIDTH > 36 and WRITE_WIDTH <= 72) and (READ_WIDTH > 36 and READ_WIDTH <= 72)) ) generate
              aa : addra_pattern <= (ADDR & '0' & "1111") when (BRAM_SIZE = "18Kb") else 
                        ('1' & ADDR & '0' & "11111") when (BRAM_SIZE = "36Kb") else
                        (others => '1');

              ab : addrb_pattern <= (ADDR & '1' & "1111") when (BRAM_SIZE = "18Kb") else 
                        ('1' & ADDR & '1' & "11111") when (BRAM_SIZE = "36Kb") else
                        (others => '1');
     end generate adgen2;
   end generate adr_vir;
  -- begin s14
  adr_st : if (DEVICE = "SPARTAN6") generate
    adgen3 : if ( (BRAM_SIZE = "9Kb" and READ_WIDTH <= 18 and WRITE_WIDTH <= 18) or (BRAM_SIZE = "18Kb" and READ_WIDTH <= 36 and WRITE_WIDTH <= 36) ) generate
      begin
                   a1 : addr_pattern <=  
                   ADDR when (BRAM_SIZE = "9Kb" and addr_width = 13) else
                   (ADDR & '1') when (BRAM_SIZE = "9Kb" and addr_width = 12 ) else
                   (ADDR & "11") when (BRAM_SIZE = "9Kb" and addr_width = 11) else
                   (ADDR & "111") when (BRAM_SIZE = "9Kb" and addr_width = 10)  else
                   (ADDR & "1111") when (BRAM_SIZE = "9Kb" and addr_width = 9 ) else 
                   ADDR when (BRAM_SIZE = "18Kb" and addr_width = 14 ) else
                   (ADDR & '1') when (BRAM_SIZE = "18Kb" and addr_width = 13 ) else
                   (ADDR & "11") when (BRAM_SIZE = "18Kb" and addr_width = 12) else
                   (ADDR & "111") when (BRAM_SIZE = "18Kb" and addr_width = 11 ) else
                   (ADDR & "1111") when (BRAM_SIZE = "18Kb" and addr_width = 10 ) else
                   (ADDR & "11111") when (BRAM_SIZE = "18Kb" and addr_width = 9 ) else
                   (others => '1');
      end generate adgen3;
     adgen4 : if ( (BRAM_SIZE = "9Kb" and (WRITE_WIDTH > 18 and WRITE_WIDTH <= 36) and (READ_WIDTH > 18 and READ_WIDTH <= 36)) or 
                   (BRAM_SIZE = "18Kb" and (WRITE_WIDTH > 36 and WRITE_WIDTH <= 72) and (READ_WIDTH > 36 and READ_WIDTH <= 72)) ) generate
              aa : addra_pattern <= (ADDR & '0' & "1111") when (BRAM_SIZE = "9Kb") else
                        (ADDR & '0' & "11111") when (BRAM_SIZE = "18Kb") else 
                        (others => '1');

              ab : addrb_pattern <= (ADDR & '1' & "1111") when (BRAM_SIZE = "9Kb") else
                        (ADDR & '1' & "11111") when (BRAM_SIZE = "18Kb") else 
                        (others => '1');
     end generate adgen4;
   end generate adr_st; -- end s14

  di1_v5: if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
    begin
    di_m1 : if ((BRAM_SIZE = "18Kb" and WRITE_WIDTH <= 36) or (BRAM_SIZE = "36Kb" and WRITE_WIDTH <= 72)) generate
      begin 
        di1 : if (write_p = TRUE  and read_p = true) generate

            di11 : if (WRITE_WIDTH >= 71 or WRITE_WIDTH = 35 or WRITE_WIDTH = 36 or WRITE_WIDTH <= 32) generate
              i1 : for i in 0 to we_width-1 generate
                di_pattern((i*8)+7 downto (i*8)) <= DI(((i*8)+i)+7 downto ((i*8)+i));
              end generate i1;
            end generate di11;

            di12 : if (WRITE_WIDTH = 33) generate
              di_pattern <= DI(32 downto 9) & DI(7 downto 0);
            end generate di12;
        
            di13 : if (WRITE_WIDTH = 34) generate
              di_pattern <= DI(33 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di13;

            di14 : if (WRITE_WIDTH = 65) generate
              di_pattern <= DI(64 downto 9) & DI(7 downto 0);
            end generate di14;

            di15 : if (WRITE_WIDTH = 66) generate
              di_pattern <= DI(65 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di15;

            di16 : if (WRITE_WIDTH = 67) generate
              di_pattern <= DI(66 downto 27) & DI(25 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di16;

            di17 : if (WRITE_WIDTH = 68) generate
              di_pattern <= DI(67 downto 36) & DI(34 downto 27) & DI(25 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di17;

            di18 : if (WRITE_WIDTH = 69) generate
              di_pattern <= DI(68 downto 45) & DI(43 downto 36) & DI(34 downto 27) & DI(25 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di18;

            di19 : if (WRITE_WIDTH = 70) generate
              di_pattern <= DI(69 downto 54) & DI(52 downto 45) & DI(43 downto 36) & DI(34 downto 27) & DI(25 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di19;
            
            
            i1p : for j in 1 to wr_widthp generate
              dip_pattern(j-1) <= DI((j*8)+j-1);
            end generate i1p;

        end generate di1;
        di2 : if ((write_p = FALSE and read_p = FALSE) and ( ((READ_WIDTH = WRITE_WIDTH) or (READ_WIDTH/WRITE_WIDTH = 2) or (valid_width = TRUE))) ) generate
                 di_pattern(fin_wr_width-1 downto 0) <= DI(fin_wr_width-1 downto 0);
        end generate di2;
        di3 : if  ((READ_WIDTH = 1 and WRITE_WIDTH = 2) or (READ_WIDTH = 2 and WRITE_WIDTH = 4) or (READ_WIDTH = 4 and WRITE_WIDTH = 8) or (READ_WIDTH = 8 and WRITE_WIDTH = 16) or (READ_WIDTH = 16 and WRITE_WIDTH = 32) or (READ_WIDTH = 32 and WRITE_WIDTH = 64 )) generate   
                  di_pattern(fin_wr_width-1 downto 0) <= DI(fin_wr_width-1 downto 0);
	  end generate di3;
        di4 : if ( (read_p = FALSE and write_p = FALSE) and (WRITE_WIDTH/READ_WIDTH = 2)) generate
                di_pattern(READ_WIDTH-1 downto 0) <= DI(READ_WIDTH-1 downto 0);
                di_pattern (read_double-1 downto READ_WIDTH) <= DI(read_double-1 downto READ_WIDTH);
        end generate di4;
    end generate di_m1;   
  end generate di1_v5;
 -- begin s10
 di1_st : if (DEVICE = "SPARTAN6") generate
   begin
    di_m2 : if ((BRAM_SIZE = "9Kb" and WRITE_WIDTH <= 36) or (BRAM_SIZE = "18Kb" and WRITE_WIDTH <= 72)) generate
      begin 
        di110 : if (write_p = TRUE and read_p = TRUE ) generate

            di111 : if (WRITE_WIDTH >= 71 or WRITE_WIDTH = 35 or WRITE_WIDTH = 36 or WRITE_WIDTH <= 32) generate
              i11 : for i in 0 to we_width-1 generate
                di_pattern((i*8)+7 downto (i*8)) <= DI(((i*8)+i)+7 downto ((i*8)+i));
              end generate i11;
            end generate di111;

            di121 : if (WRITE_WIDTH = 33) generate
              di_pattern <= DI(32 downto 9) & DI(7 downto 0);
            end generate di121;
        
            di131 : if (WRITE_WIDTH = 34) generate
              di_pattern <= DI(33 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di131;

            di141 : if (WRITE_WIDTH = 65) generate
              di_pattern <= DI(64 downto 9) & DI(7 downto 0);
            end generate di141;

            di151 : if (WRITE_WIDTH = 66) generate
              di_pattern <= DI(65 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di151;

            di161 : if (WRITE_WIDTH = 67) generate
              di_pattern <= DI(66 downto 27) & DI(25 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di161;

            di171 : if (WRITE_WIDTH = 68) generate
              di_pattern <= DI(67 downto 36) & DI(34 downto 27) & DI(25 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di171;

            di181 : if (WRITE_WIDTH = 69) generate
              di_pattern <= DI(68 downto 45) & DI(43 downto 36) & DI(34 downto 27) & DI(25 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di181;

            di191 : if (WRITE_WIDTH = 70) generate
              di_pattern <= DI(69 downto 54) & DI(52 downto 45) & DI(43 downto 36) & DI(34 downto 27) & DI(25 downto 18) & DI(16 downto 9) & DI(7 downto 0);
            end generate di191;
            
            
            i1p1 : for j in 1 to wr_widthp generate
              dip_pattern(j-1) <= DI((j*8)+j-1);
            end generate i1p1;
            
        end generate di110;
        di12 : if ((write_p = FALSE and read_p = FALSE) and ( ((READ_WIDTH = WRITE_WIDTH) or (READ_WIDTH/WRITE_WIDTH = 2) or (valid_width = TRUE))) ) generate
                 di_pattern(fin_wr_width-1 downto 0) <= DI(fin_wr_width-1 downto 0);
        end generate di12;
        di13 : if  ((READ_WIDTH = 1 and WRITE_WIDTH = 2) or (READ_WIDTH = 2 and WRITE_WIDTH = 4) or (READ_WIDTH = 4 and WRITE_WIDTH = 8) or (READ_WIDTH = 8 and WRITE_WIDTH = 16) or (READ_WIDTH = 16 and WRITE_WIDTH = 32) or (READ_WIDTH = 32 and WRITE_WIDTH = 64 )) generate   
                 di_pattern(fin_wr_width-1 downto 0) <= DI(fin_wr_width-1 downto 0);
	  end generate di13;
        di14 : if ( (read_p = FALSE and write_p = FALSE) and (WRITE_WIDTH/READ_WIDTH = 2)) generate
                di_pattern(READ_WIDTH-1 downto 0) <= DI(READ_WIDTH-1 downto 0);
                di_pattern (read_double-1 downto READ_WIDTH) <= DI(read_double-1 downto READ_WIDTH);
        end generate di14;
      end generate di_m2; 	
  end generate di1_st; -- end s10

 dogen : if ( ((DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") and ((BRAM_SIZE = "18Kb" and READ_WIDTH <= 36) or (BRAM_SIZE = "36Kb" and READ_WIDTH <= 72)) ) or ((DEVICE ="SPARTAN6") and ((BRAM_SIZE = "9Kb" and READ_WIDTH <= 36) or (BRAM_SIZE = "18Kb" and READ_WIDTH <= 72)) ) ) generate 
          do11 : if (read_p = TRUE and write_p = TRUE) generate

            do110 : if (READ_WIDTH >= 71 or READ_WIDTH = 35 or READ_WIDTH = 36 or READ_WIDTH <= 32) generate
              o1 : for i1 in 0 to rd_byte_width-1 generate
                DO(((i1*8)+i1)+7 downto ((i1*8)+i1)) <= do_pattern((i1*8)+7 downto (i1*8));
              end generate o1;
            end generate do110;

            do111 : if (READ_WIDTH = 33) generate
              DO(32 downto 9) <= do_pattern(31 downto 8);
              DO(7 downto 0) <= do_pattern(7 downto 0);
            end generate do111;
              
            do112 : if (READ_WIDTH = 34) generate
              DO(33 downto 18) <= do_pattern(31 downto 16);
              DO(16 downto 9) <= do_pattern(15 downto 8);
              DO(7 downto 0) <= do_pattern(7 downto 0);
            end generate do112;

            do113 : if (READ_WIDTH = 65) generate
              DO(64 downto 9) <= do_pattern(63 downto 8);
              DO(7 downto 0) <= do_pattern(7 downto 0);
            end generate do113;
            
            do114 : if (READ_WIDTH = 66) generate
              DO(65 downto 18) <= do_pattern(63 downto 16);
              DO(16 downto 9) <= do_pattern(15 downto 8);              
              DO(7 downto 0) <= do_pattern(7 downto 0);
            end generate do114;

            do115 : if (READ_WIDTH = 67) generate
              DO(66 downto 27) <= do_pattern(63 downto 24);
              DO(25 downto 18) <= do_pattern(23 downto 16);              
              DO(16 downto 9) <= do_pattern(15 downto 8);              
              DO(7 downto 0) <= do_pattern(7 downto 0);
            end generate do115;

            do116 : if (READ_WIDTH = 68) generate
              DO(67 downto 36) <= do_pattern(63 downto 32);
              DO(34 downto 27) <= do_pattern(31 downto 24);
              DO(25 downto 18) <= do_pattern(23 downto 16);              
              DO(16 downto 9) <= do_pattern(15 downto 8);              
              DO(7 downto 0) <= do_pattern(7 downto 0);
            end generate do116;

            do117 : if (READ_WIDTH = 69) generate
              DO(68 downto 45) <= do_pattern(63 downto 40);
              DO(43 downto 36) <= do_pattern(39 downto 32);              
              DO(34 downto 27) <= do_pattern(31 downto 24);
              DO(25 downto 18) <= do_pattern(23 downto 16);              
              DO(16 downto 9) <= do_pattern(15 downto 8);              
              DO(7 downto 0) <= do_pattern(7 downto 0);
            end generate do117;

            do118 : if (READ_WIDTH = 70) generate
              DO(69 downto 54) <= do_pattern(63 downto 48);
              DO(52 downto 45) <= do_pattern(47 downto 40);
              DO(43 downto 36) <= do_pattern(39 downto 32);              
              DO(34 downto 27) <= do_pattern(31 downto 24);
              DO(25 downto 18) <= do_pattern(23 downto 16);              
              DO(16 downto 9) <= do_pattern(15 downto 8);              
              DO(7 downto 0) <= do_pattern(7 downto 0);
            end generate do118;

            o1p : for j1 in 1 to rd_widthp generate
              DO((j1*8)+j1-1) <= dop_pattern(j1-1);
            end generate o1p;
            
          end generate do11;
          do121 : if  ( (read_p = FALSE and write_p = FALSE) and ( (READ_WIDTH = WRITE_WIDTH) or (WRITE_WIDTH/READ_WIDTH =2) or (valid_width = TRUE) ) ) generate   
               DO <= ( do_pattern(fin_rd_width-1 downto 0) );     
	  end generate do121;
          do12 : if ((READ_WIDTH = 2 and WRITE_WIDTH = 1) or (READ_WIDTH = 4 and WRITE_WIDTH = 2) or (READ_WIDTH = 8 and WRITE_WIDTH = 4) or (READ_WIDTH = 16 and WRITE_WIDTH = 8) or (READ_WIDTH = 32 and WRITE_WIDTH = 16) or (READ_WIDTH = 64 and WRITE_WIDTH = 32 )) generate   
               DO <= ( do_pattern(fin_rd_width-1 downto 0) );   
	  end generate do12;     
	  do3 : if ((read_p = FALSE and write_p = FALSE) and (READ_WIDTH/WRITE_WIDTH = 2) and (WRITE_WIDTH = 3)) generate
	    -- write width 3
	       DO <= ( do_pattern((4+(WRITE_WIDTH-1)) downto 4) & do_pattern((WRITE_WIDTH-1) downto 0) );
	  end generate do3;   
	  do47 : if ((read_p = FALSE and write_p = FALSE) and (READ_WIDTH/WRITE_WIDTH = 2) and (WRITE_WIDTH > 4 and WRITE_WIDTH <= 7)) generate
	    -- write width between 4 and 7
	      DO <=  ( do_pattern((8+(WRITE_WIDTH-1)) downto 8) & do_pattern((WRITE_WIDTH-1) downto 0) );
	  end generate do47;     
          do815 : if ((read_p = FALSE and write_p = FALSE) and (READ_WIDTH/WRITE_WIDTH = 2) and(WRITE_WIDTH > 9 and WRITE_WIDTH <= 15)) generate
	      -- write width between 8 and 15
	         DO <= ( do_pattern((16+(WRITE_WIDTH-1)) downto 16) & do_pattern((WRITE_WIDTH-1) downto 0) ); 
	  end generate do815;     
	  do1831 : if ((read_p = FALSE and write_p = FALSE) and (READ_WIDTH/WRITE_WIDTH = 2) and (WRITE_WIDTH > 18 and WRITE_WIDTH <= 31)) generate
	      -- write width between 18 and 31
	         DO <= ( do_pattern((32+(WRITE_WIDTH-1)) downto 32) & do_pattern((WRITE_WIDTH-1) downto 0) ); 
	  end generate do1831;    

   end generate dogen; 

  we1 : if (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
  w1 : we_pattern <= (WE & WE) when (BRAM_SIZE = "18Kb" and we_width = 1 ) else
                   WE when (BRAM_SIZE = "18Kb" and  we_width = 2 ) else
                   (WE & WE & WE & WE) when (BRAM_SIZE = "36Kb" and we_width = 1 ) else
                   (WE & WE) when (BRAM_SIZE = "36Kb" and we_width = 2 ) else
                   WE when (BRAM_SIZE = "36Kb" and we_width = 4 ) else
                   WE;
  end generate we1;
  -- begin s14
  we2 : if (DEVICE = "SPARTAN6") generate
  w1 : we_pattern <= (WE & WE) when (BRAM_SIZE = "9Kb" and we_width = 1 ) else
                   WE when (BRAM_SIZE = "9Kb" and we_width = 2 ) else
                   (WE & WE & WE & WE) when (BRAM_SIZE = "18Kb" and we_width = 1 ) else
                   (WE & WE) when (BRAM_SIZE = "18Kb" and we_width = 2 ) else
                   WE when (BRAM_SIZE = "18Kb" and we_width = 4 ) else
                   WE;
  end generate we2;
 -- end s14
 r1 : rstram_pattern <= RST; 
 r2 : rstreg_pattern <= RST when (DO_REG = 1) else '0';

  -- begin generate virtex5
  ramb_v5   : if DEVICE ="VIRTEX5" generate 
    ramb18_sin : if (BRAM_SIZE = "18Kb" and READ_WIDTH <= 18 and WRITE_WIDTH <= 18) generate 
    begin

    ram18 : RAMB18 
      generic map(
                DOA_REG => DO_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init, read_p, write_p, READ_WIDTH, init_srval_width_size),
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
                READ_WIDTH_A => rd_width,
                SIM_COLLISION_CHECK => "NONE",
                SIM_MODE => SIM_MODE,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval, read_p, write_p, READ_WIDTH, init_srval_width_size),
                WRITE_MODE_A => WRITE_MODE,
                WRITE_WIDTH_A => wr_width
              )
      port map (
                ADDRA => addr_pattern,
                ADDRB => "00000000000000",
                CLKA => CLK,
                CLKB => '0',
                DIA  => di_pattern,
                DIB => X"0000",
                DIPA => dip_pattern,
                DIPB => "00",
                ENA => EN,
                ENB => '0',
                SSRA => RST,
                SSRB => '0',
                WEA => we_pattern,
                WEB => "00",
                DOA => do_pattern,
                DOB => OPEN,
                DOPA => dop_pattern,
                DOPB => OPEN,
                REGCEA => REGCE,
                REGCEB => '0'
        );

    end generate ramb18_sin;
    ramb18_sin_1 : if (BRAM_SIZE = "18Kb" and (READ_WIDTH > 18 and READ_WIDTH <= 36) and (WRITE_WIDTH > 18 and WRITE_WIDTH <= 36)) generate 
    begin

    ram18_1 : RAMB18 
      generic map(
                DOA_REG => DO_REG,
                DOB_REG => DO_REG,
                INIT_A => init_a_pattern,
                INIT_B => init_b_pattern,
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
                READ_WIDTH_A => 18,
                READ_WIDTH_B => 18,
                SIM_COLLISION_CHECK => "NONE",
                SIM_MODE => SIM_MODE,
                SRVAL_A => srval_a_pattern ,
                SRVAL_B => srval_b_pattern ,
                WRITE_MODE_A => WRITE_MODE,
                WRITE_MODE_B => WRITE_MODE,
                WRITE_WIDTH_A => 18,
                WRITE_WIDTH_B => 18
              )
      port map (
                ADDRA => addra_pattern,
                ADDRB => addrb_pattern,
                CLKA => CLK,
                CLKB => CLK,
                DIA  => di_pattern(31 downto 16),
                DIB => di_pattern(15 downto 0),
                DIPA => dip_pattern(3 downto 2),
                DIPB => dip_pattern(1 downto 0),
                ENA => EN,
                ENB => EN,
                SSRA => RST,
                SSRB => RST,
                WEA => we_pattern(3 downto 2) ,
                WEB => we_pattern(1 downto 0),
                DOA => do_pattern(31 downto 16),
                DOB => do_pattern(15 downto 0),
                DOPA => dop_pattern(3 downto 2),
                DOPB => dop_pattern(1 downto 0),
                REGCEA => REGCE,
                REGCEB => REGCE
        );

    end generate ramb18_sin_1;
    ramb36_sin : if (BRAM_SIZE = "36Kb" and READ_WIDTH <= 36 and WRITE_WIDTH <= 36) generate 
    begin
      ram36 : RAMB36
        generic map (

                DOA_REG => DO_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init, read_p, write_p, READ_WIDTH, init_srval_width_size),
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
                READ_WIDTH_A => rd_width,
		SIM_COLLISION_CHECK => "NONE",
                SIM_MODE => SIM_MODE,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval, read_p, write_p, READ_WIDTH, init_srval_width_size),
		WRITE_MODE_A => WRITE_MODE,
                WRITE_WIDTH_A => wr_width

                )
          port map (
                ADDRA => addr_pattern,
                ADDRB => X"0000",
                CLKA => CLK,
                CLKB => '0',
                DIA  => di_pattern,
                DIB  => X"00000000",
                DIPA => dip_pattern,
                DIPB => "0000",
                ENA => EN,
                ENB => '0',
                SSRA => RST,
                SSRB => '0',
                WEA => we_pattern,
                WEB => "0000",
                DOA => do_pattern,
                DOB => OPEN,
                DOPA => dop_pattern,
                DOPB => OPEN,
                CASCADEOUTLATA => OPEN,
                CASCADEOUTLATB => OPEN,
                CASCADEOUTREGA => OPEN,
                CASCADEOUTREGB => OPEN,
                CASCADEINLATA => '0',
                CASCADEINLATB => '0',
                CASCADEINREGA => '0',
                CASCADEINREGB => '0',
                REGCEA => REGCE,
                REGCEB => '0'
          );
        end generate ramb36_sin;
    ramb36_sin_1 : if (BRAM_SIZE = "36Kb" and (READ_WIDTH > 36 and READ_WIDTH <= 72) and (WRITE_WIDTH > 36 and WRITE_WIDTH <= 72)) generate 
    begin
      ram36_1 : RAMB36
        generic map (

                DOA_REG => DO_REG,
                DOB_REG => DO_REG,
		INIT_A  => init_a_pattern,
		INIT_B  => init_b_pattern,
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
                READ_WIDTH_A => 36,
                READ_WIDTH_B => 36,
		SIM_COLLISION_CHECK => "NONE",
                SIM_MODE => SIM_MODE,
		SRVAL_A => srval_a_pattern,
		SRVAL_B => srval_b_pattern,
		WRITE_MODE_A => WRITE_MODE,
		WRITE_MODE_B => WRITE_MODE,
                WRITE_WIDTH_A => 36,
                WRITE_WIDTH_B => 36

                )
          port map (
                ADDRA => addra_pattern,
                ADDRB => addrb_pattern,
                CLKA => CLK,
                CLKB => CLK,
                DIA  => di_pattern(63 downto 32),
                DIB  => di_pattern(31 downto 0),
                DIPA => dip_pattern(7 downto 4),
                DIPB => dip_pattern(3 downto 0),
                ENA => EN,
                ENB => EN,
                SSRA => RST,
                SSRB => RST,
                WEA => we_pattern(7 downto 4),
                WEB => we_pattern(3 downto 0),
                DOA => do_pattern(63 downto 32),
                DOB => do_pattern(31 downto 0),
                DOPA => dop_pattern(7 downto 4),
                DOPB => dop_pattern(3 downto 0),
                CASCADEOUTLATA => OPEN,
                CASCADEOUTLATB => OPEN,
                CASCADEOUTREGA => OPEN,
                CASCADEOUTREGB => OPEN,
                CASCADEINLATA => '0',
                CASCADEINLATB => '0',
                CASCADEINREGA => '0',
                CASCADEINREGB => '0',
                REGCEA => REGCE,
                REGCEB => REGCE
          );
        end generate ramb36_sin_1;
      end generate ramb_v5;
  -- end generate virtex5
  -- begin generate virtex6
ramb_bl   : if (DEVICE ="VIRTEX6" or DEVICE = "7SERIES") generate 
    ramb18_sin_bl : if (BRAM_SIZE = "18Kb" and READ_WIDTH <= 18 and WRITE_WIDTH <= 18) generate 
    begin

    ram18_bl : RAMB18E1 
      generic map(
                DOA_REG => DO_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init, read_p, write_p, READ_WIDTH, init_srval_width_size),
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
                RDADDR_COLLISION_HWCONFIG => "PERFORMANCE",
                READ_WIDTH_A => rd_width,
                SIM_COLLISION_CHECK => "NONE",
                SIM_DEVICE => sim_device_dp,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval, read_p, write_p, READ_WIDTH, init_srval_width_size),
                WRITE_MODE_A => WRITE_MODE,
                WRITE_WIDTH_A => wr_width
              )
      port map (
                ADDRARDADDR => addr_pattern,
                ADDRBWRADDR => "00000000000000",
                CLKARDCLK => CLK,
                CLKBWRCLK => '0',
                DIADI  => di_pattern,
                DIBDI => X"0000",
                DIPADIP => dip_pattern,
                DIPBDIP => "00",
                ENARDEN => EN,
                ENBWREN => '0',
                RSTRAMARSTRAM => rstram_pattern,
                RSTREGARSTREG => rstreg_pattern,
                RSTRAMB => '0',
                RSTREGB => '0',
                WEA => we_pattern,
                WEBWE => "0000",
                DOADO => do_pattern,
                DOBDO => OPEN,
                DOPADOP => dop_pattern,
                DOPBDOP => OPEN,
                REGCEAREGCE => REGCE,
                REGCEB => '0'
        );

    end generate ramb18_sin_bl;
    ramb18_sin_bl_1 : if (BRAM_SIZE = "18Kb" and (READ_WIDTH > 18 and READ_WIDTH <= 36) and (WRITE_WIDTH > 18 and WRITE_WIDTH <= 36)) generate 
    begin

    ram18_bl_1 : RAMB18E1 
      generic map(
                DOA_REG => DO_REG,
                DOB_REG => DO_REG,
                INIT_A => init_a_pattern,
                INIT_B => init_b_pattern,
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
                RDADDR_COLLISION_HWCONFIG => "PERFORMANCE",
                READ_WIDTH_A => 18,
                READ_WIDTH_B => 18,
                SIM_COLLISION_CHECK => "NONE",
                SIM_DEVICE => sim_device_dp,
                SRVAL_A => srval_a_pattern ,
                SRVAL_B => srval_b_pattern ,
                WRITE_MODE_A => WRITE_MODE,
                WRITE_MODE_B => WRITE_MODE,
                WRITE_WIDTH_A => 18,
                WRITE_WIDTH_B => 18
              )
      port map (
                ADDRARDADDR => addra_pattern,
                ADDRBWRADDR => addrb_pattern,
                CLKARDCLK => CLK,
                CLKBWRCLK => CLK,
                DIADI  => di_pattern(31 downto 16),
                DIBDI => di_pattern(15 downto 0),
                DIPADIP => dip_pattern(3 downto 2),
                DIPBDIP => dip_pattern(1 downto 0),
                ENARDEN => EN,
                ENBWREN => EN,
                RSTRAMARSTRAM => rstram_pattern,
                RSTREGARSTREG => rstreg_pattern,
                RSTRAMB => rstram_pattern,
                RSTREGB => rstreg_pattern,
                WEA => we_pattern(3 downto 2),
                WEBWE => we_pattern,
                DOADO => do_pattern(31 downto 16),
                DOBDO => do_pattern(15 downto 0),
                DOPADOP => dop_pattern(3 downto 2),
                DOPBDOP => dop_pattern(1 downto 0),
                REGCEAREGCE => REGCE,
                REGCEB => REGCE
        );

    end generate ramb18_sin_bl_1;
  
    ramb36_sin_bl : if (BRAM_SIZE = "36Kb" and READ_WIDTH <= 36 and WRITE_WIDTH <= 36) generate 
    begin
      ram36_bl : RAMB36E1
        generic map (

                DOA_REG => DO_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init, read_p, write_p, READ_WIDTH, init_srval_width_size),
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
                RDADDR_COLLISION_HWCONFIG => "PERFORMANCE",
                READ_WIDTH_A => rd_width,
		SIM_COLLISION_CHECK => "NONE",
                SIM_DEVICE => sim_device_dp,
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval, read_p, write_p, READ_WIDTH, init_srval_width_size),
		WRITE_MODE_A => WRITE_MODE,
                WRITE_WIDTH_A => wr_width

                )
          port map (
                ADDRARDADDR => addr_pattern,
                ADDRBWRADDR => X"0000",
                CLKARDCLK => CLK,
                CLKBWRCLK => '0',
                DIADI  => di_pattern,
                DIBDI  => X"00000000",
                DIPADIP => dip_pattern,
                DIPBDIP => "0000",
                ENARDEN => EN,
                ENBWREN => '0',
                INJECTDBITERR => '0',
                INJECTSBITERR => '0',
                RSTRAMARSTRAM => rstram_pattern,
                RSTREGARSTREG => rstreg_pattern,
                RSTRAMB => '0',
                RSTREGB => '0',
                WEA => we_pattern,
                WEBWE => "00000000",
                DOADO => do_pattern,
                DOBDO => OPEN,
                DOPADOP => dop_pattern,
                DOPBDOP => OPEN,
                CASCADEOUTA => OPEN,
                CASCADEOUTB => OPEN,
                CASCADEINA => '0',
                CASCADEINB => '0',
                DBITERR => OPEN,
                ECCPARITY => OPEN,
                RDADDRECC => OPEN,
                SBITERR => OPEN,
                REGCEAREGCE => REGCE,
                REGCEB => '0'
          );
        end generate ramb36_sin_bl;
    ramb36_sin_bl_1 : if (BRAM_SIZE = "36Kb" and (READ_WIDTH > 36 and READ_WIDTH <= 72) and (WRITE_WIDTH > 36 and WRITE_WIDTH <= 72)) generate 
    begin
      ram36_bl_1 : RAMB36E1
        generic map (

                DOA_REG => DO_REG,
                DOB_REG => DO_REG,
		INIT_A  => init_a_pattern,
		INIT_B  => init_b_pattern,
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
                RDADDR_COLLISION_HWCONFIG => "PERFORMANCE",
                READ_WIDTH_A => 36,
                READ_WIDTH_B => 36,
		SIM_COLLISION_CHECK => "NONE",
                SIM_DEVICE => sim_device_dp,
		SRVAL_A => srval_a_pattern,
		SRVAL_B => srval_b_pattern,
		WRITE_MODE_A => WRITE_MODE,
		WRITE_MODE_B => WRITE_MODE,
                WRITE_WIDTH_A => 36,
                WRITE_WIDTH_B => 36

                )
          port map (
                ADDRARDADDR => addra_pattern,
                ADDRBWRADDR => addrb_pattern,
                CLKARDCLK => CLK,
                CLKBWRCLK => CLK,
                DIADI  => di_pattern(63 downto 32),
                DIBDI  => di_pattern(31 downto 0),
                DIPADIP => dip_pattern(7 downto 4),
                DIPBDIP => dip_pattern(3 downto 0),
                ENARDEN => EN,
                ENBWREN => EN,
                INJECTDBITERR => '0',
                INJECTSBITERR => '0',
                RSTRAMARSTRAM => rstram_pattern,
                RSTREGARSTREG => rstreg_pattern,
                RSTRAMB => rstram_pattern,
                RSTREGB => rstreg_pattern,
                WEA => we_pattern(7 downto 4),
                WEBWE => we_pattern,
                DOADO => do_pattern(63 downto 32),
                DOBDO => do_pattern(31 downto 0),
                DOPADOP => dop_pattern(7 downto 4),
                DOPBDOP => dop_pattern(3 downto 0),
                CASCADEOUTA => OPEN,
                CASCADEOUTB => OPEN,
                CASCADEINA => '0',
                CASCADEINB => '0',
                DBITERR => OPEN,
                ECCPARITY => OPEN,
                RDADDRECC => OPEN,
                SBITERR => OPEN,
                REGCEAREGCE => REGCE,
                REGCEB => REGCE
          );
        end generate ramb36_sin_bl_1;

      end generate ramb_bl;
  -- end generate virtex6
  -- begin generate spartan6
     ramb_st : if DEVICE = "SPARTAN6" generate 
    ramb9_sin_st : if (BRAM_SIZE = "9Kb" and (READ_WIDTH = WRITE_WIDTH) and (READ_WIDTH <= 18)) generate 
      begin

        ram9_st : RAMB8BWER 
          generic map(
                DOA_REG => DO_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init, read_p, write_p, READ_WIDTH, init_srval_width_size),
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
                DATA_WIDTH_A => wr_width,
                RAM_MODE => "TDP",
                SIM_COLLISION_CHECK => "NONE",
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval, read_p, write_p, READ_WIDTH, init_srval_width_size),
                WRITE_MODE_A => WRITE_MODE
              )
          port map (
                ADDRAWRADDR => addr_pattern,
                ADDRBRDADDR => "0000000000000",
                CLKAWRCLK => CLK,
                CLKBRDCLK => '0',
                DIADI => di_pattern,
                DIBDI  => X"0000",
                DIPADIP => dip_pattern,
                DIPBDIP => "00",
                ENAWREN => EN,
                ENBRDEN => '0',
                REGCEA => REGCE,
                REGCEBREGCE => '0',
                RSTA => RST,
                RSTBRST => '0',
                WEAWEL => we_pattern,
                WEBWEU => "00",
                DOADO => do_pattern,
                DOBDO => OPEN,
                DOPADOP => dop_pattern,
                DOPBDOP => OPEN
        );

    end generate ramb9_sin_st;
    ramb9_sin_st_1 : if (BRAM_SIZE = "9Kb" and (READ_WIDTH = WRITE_WIDTH) and (READ_WIDTH > 18 and READ_WIDTH <= 36)) generate 
      begin

        ram9_st : RAMB8BWER 
          generic map(
                DOA_REG => DO_REG,
                DOB_REG => DO_REG,
                INIT_A => init_a_pattern,
                INIT_B => init_b_pattern,
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
                DATA_WIDTH_A => 18,
                DATA_WIDTH_B => 18,
                RAM_MODE => "TDP",
                SIM_COLLISION_CHECK => "NONE",
                SRVAL_A => srval_a_pattern ,
		SRVAL_B => srval_b_pattern ,
                WRITE_MODE_A => WRITE_MODE,
                WRITE_MODE_B => WRITE_MODE
              )
          port map (
                ADDRAWRADDR => addra_pattern,
                ADDRBRDADDR => addrb_pattern,
                CLKAWRCLK => CLK,
                CLKBRDCLK => CLK,
                DIADI  => di_pattern(31 downto 16),
                DIBDI => di_pattern(15 downto 0),
                DIPADIP => dip_pattern(3 downto 2),
                DIPBDIP => dip_pattern(1 downto 0),
                ENAWREN => EN,
                ENBRDEN => EN,
                REGCEA => REGCE,
                REGCEBREGCE => REGCE,
                RSTA => RST,
                RSTBRST => RST,
                WEAWEL => we_pattern(3 downto 2),
                WEBWEU => we_pattern(1 downto 0),
                DOADO => do_pattern(31 downto 16),
                DOBDO => do_pattern(15 downto 0),
                DOPADOP => dop_pattern(3 downto 2),
                DOPBDOP => dop_pattern(1 downto 0)
        );

    end generate ramb9_sin_st_1;
    ramb18_sin_st : if (BRAM_SIZE = "18Kb" and (READ_WIDTH = WRITE_WIDTH) and (READ_WIDTH <= 36)) generate 
      begin
        ram18_st : RAMB16BWER
          generic map (

                DOA_REG => DO_REG,
                INIT_A => INIT_SRVAL_parity_byte(padded_init, read_p, write_p, READ_WIDTH, init_srval_width_size),
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
                SIM_COLLISION_CHECK => "NONE",
                SIM_DEVICE => "SPARTAN6",
                SRVAL_A => INIT_SRVAL_parity_byte(padded_srval, read_p, write_p, READ_WIDTH, init_srval_width_size),
                DATA_WIDTH_A => rd_width,
		WRITE_MODE_A => WRITE_MODE

                )
           port map (
                ADDRA => addr_pattern,
                ADDRB => "00000000000000",
                CLKA => CLK,
                CLKB => '0',
                DIA  => di_pattern,
                DIB  => X"00000000",
                DIPA => dip_pattern,
                DIPB => "0000",
                ENA => EN,
                ENB => '0',
                REGCEA => REGCE,
                REGCEB => '0',
                RSTA => RST,
                RSTB => '0',
                WEA => we_pattern,
                WEB => "0000",
                DOA => do_pattern,
                DOB => OPEN,
                DOPA => dop_pattern,
                DOPB => OPEN
          );
    end generate ramb18_sin_st;
     ramb18_sin_st_1 : if (BRAM_SIZE = "18Kb" and (READ_WIDTH = WRITE_WIDTH) and (READ_WIDTH > 36 and READ_WIDTH <= 72)) generate 
      begin
        ram18_st_1 : RAMB16BWER
          generic map (

                DOA_REG => DO_REG,
                DOB_REG => DO_REG,
		INIT_A  => init_a_pattern,
		INIT_B  => init_b_pattern,
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
                SIM_COLLISION_CHECK => "NONE",
                SIM_DEVICE => "SPARTAN6",
		SRVAL_A => srval_a_pattern,
		SRVAL_B => srval_b_pattern,
                DATA_WIDTH_A => 36,
                DATA_WIDTH_B => 36,
		WRITE_MODE_A => WRITE_MODE,
		WRITE_MODE_B => WRITE_MODE

                )
           port map (
                ADDRA => addra_pattern,
                ADDRB => addrb_pattern,
                CLKA => CLK,
                CLKB => CLK,
                DIA  => di_pattern(63 downto 32),
                DIB  => di_pattern(31 downto 0),
                DIPA => dip_pattern(7 downto 4),
                DIPB => dip_pattern(3 downto 0),
                ENA => EN,
                ENB => EN,
                REGCEA => REGCE,
                REGCEB => REGCE,
                RSTA => RST,
                RSTB => RST,
                WEA => we_pattern(7 downto 4),
                WEB => we_pattern(3 downto 0),
                DOA => do_pattern(63 downto 32),
                DOB => do_pattern(31 downto 0),
                DOPA => dop_pattern(7 downto 4),
                DOPB => dop_pattern(3 downto 0)
          );
    end generate ramb18_sin_st_1;
  end generate ramb_st;
  -- end generate spartan6
end bram_V;
