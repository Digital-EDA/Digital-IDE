-------------------------------------------------------------------------------
-- Copyright (c) 1995/2007 Xilinx, Inc.
-- All Right Reserved.
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor : Xilinx
-- \   \   \/     Version : 13.1
--  \   \         Description : Xilinx Functional Simulation Library Component
--  /   /                  Macro for FIFO
-- /___/   /\     Filename : FIFO_DUALCLOCK_MACRO.vhd
-- \   \  /  \    Timestamp : Fri April 18 2008 10:43:59 PST 2006
--  \___\/\___\
--
-- Revision:
--    04/04/08 - Initial version.
--    08/09/11 - Fixed CR 620349
--    01/11/12 - 639772, 604428 -Constrain DI, DO, add width checking.
-- End Revision

----- CELL FIFO_DUALCLOCK_MACRO -----

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.VCOMPONENTS.all;

library unimacro;
use unimacro.VCOMPONENTS.all;

library STD;
use STD.TEXTIO.ALL;

entity FIFO_DUALCLOCK_MACRO is

  generic (
    ALMOST_FULL_OFFSET      : bit_vector := X"0080";
    ALMOST_EMPTY_OFFSET     : bit_vector := X"0080"; 
    DATA_WIDTH              : integer    := 4; 
    DEVICE : string := "VIRTEX5";
    FIFO_SIZE : string := "18Kb";  
    FIRST_WORD_FALL_THROUGH : boolean    := FALSE;
    INIT                    : bit_vector := X"000000000000000000"; -- This parameter is valid only for Virtex6
    SRVAL                   : bit_vector := X"000000000000000000"; -- This parameter is valid only for Virtex6
    SIM_MODE                  : string     := "SAFE" -- This parameter is valid only for Virtex5
    );
  port(
    ALMOSTEMPTY : out std_logic;
    ALMOSTFULL  : out std_logic;
    DO          : out std_logic_vector(DATA_WIDTH-1 downto 0);
    EMPTY       : out std_logic;
    FULL        : out std_logic;
    RDCOUNT     : out std_logic_vector(xil_UNM_GCW(DATA_WIDTH, FIFO_SIZE, DEVICE)-1 downto 0);
    RDERR       : out std_logic;
    WRCOUNT     : out std_logic_vector(xil_UNM_GCW(DATA_WIDTH, FIFO_SIZE, DEVICE)-1 downto 0);
    WRERR       : out std_logic;

    DI          : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    RDCLK       : in  std_logic;
    RDEN        : in  std_logic;
    RST         : in  std_logic;
    WRCLK       : in  std_logic;
    WREN        : in  std_logic
    );

  end entity FIFO_DUALCLOCK_MACRO;

  architecture fifo_V of FIFO_DUALCLOCK_MACRO is
 
  function GetDWidth (
    d_width : in integer;
    func_fifo_size : in string;
    device  : in string
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      case d_width is
        when 0|1|2|3|4 => func_width := 4;
                         if(d_width = 0) then
                         write( Message, STRING'("Illegal value of Attribute DATA_WIDTH : ") );
                         write( Message, STRING'(". This attribute must atleast be equal to 1 . ") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                         end if;
        when 5|6|7|8|9 => func_width := 8;
        when 10 to 18 => func_width := 16;
        when 19 to 36 => func_width := 32;
        when 37 to 72 => if(func_fifo_size = "18Kb") then
                         write( Message, STRING'("Illegal value of Attribute DATA_WIDTH : ") );
                         write( Message, STRING'(". Legal values of this attribute for FIFO_SIZE 18Kb are ") );
                         write( Message, STRING'(" 1 to 36 ") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                         else
                         func_width := 64;
                         end if;
        when others =>   write( Message, STRING'("Illegal value of Attribute DATA_WIDTH : ") );
                         write( Message, STRING'(". Legal values of this attribute are ") );
                         write( Message, STRING'(" 1 to 36 for FIFO_SIZE of 18Kb and ") );
                         write( Message, STRING'(" 1 to 72 for FIFO_SIZE of 36Kb .") );
                         ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
                         DEALLOCATE (Message);
                         func_width := 64;
      end case;
    else
      func_width := 64;
    end if;
    return func_width;
  end;
  function GetD_Size (
    d_size : in integer;
    device  : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      case d_size is
        when 0|1|2|3|4 => func_width := 4;
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

  function GetDIPWidth (
    d_width : in integer;
    func_fifo_size : in string;
    device  : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      case d_width is
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
  function GetDOPWidth (
    d_width : in integer;
    func_fifo_size : in string;
    device  : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      case d_width is
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
        when others => func_width := 1;
      end case;
    else
      func_width := 1;
    end if;
  return func_width;
  end;

  function GetCOUNTWidth (
    d_width : in integer;
    fifo_size : in string;
    device  : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if(fifo_size = "18Kb") then
        case d_width is
          when 0|1|2|3|4 => func_width := 12;
          when 5|6|7|8|9 => func_width := 11;
          when 10 to 18 => func_width := 10;
          when 19 to 36 => func_width := 9;
          when others => func_width := 12;
        end case;
      elsif(fifo_size = "36Kb") then
        case d_width is
          when 0|1|2|3|4 => func_width := 13;
          when 5|6|7|8|9 => func_width := 12;
          when 10 to 18 => func_width := 11;
          when 19 to 36 => func_width := 10;
          when 37 to 72 => func_width := 9;
          when others => func_width := 13;
        end case;
      end if;
    else
      func_width := 13;
    end if;
    return func_width;
  end;

  function GetMaxDWidth (
    d_width : in integer;
    fifo_size : in string; 
    device  : in string
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5") then
      if (fifo_size = "18Kb" and d_width <= 18 ) then
        func_width := 16;
      elsif (fifo_size = "18Kb" and d_width > 18 and d_width <= 36 ) then
        func_width := 32;
      elsif (fifo_size = "36Kb" and d_width <= 36 ) then
        func_width := 32;
      elsif (fifo_size = "36Kb" and d_width > 36 and d_width <= 72 ) then
        func_width := 64;
      else
        func_width := 64;
      end if;
    elsif(DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if (fifo_size = "18Kb" and d_width <= 36 ) then
        func_width := 32;
      elsif (fifo_size = "36Kb" and d_width <= 72 ) then
        func_width := 64;
      else
        func_width := 64;
      end if; -- end b1
    else
      func_width := 64;
    end if;
    return func_width;
  end;
  function GetMaxDPWidth (
    d_width : in integer;
    fifo_size : in string; 
    device  : in string
    ) return integer is
    variable func_width : integer;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5") then
      if (fifo_size = "18Kb" and d_width <= 18 ) then
        func_width := 2;
      elsif (fifo_size = "18Kb" and d_width > 18 and d_width <= 36 ) then
        func_width := 4;
      elsif (fifo_size = "36Kb" and d_width <= 36 ) then
        func_width := 4;
      elsif (fifo_size = "36Kb" and d_width > 36 and d_width <= 72 ) then
        func_width := 8;
      else
        func_width := 8;
      end if;
     elsif(DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if (fifo_size = "18Kb" and d_width <= 36 ) then
        func_width := 4;
      elsif (fifo_size = "36Kb" and d_width <= 72 ) then
        func_width := 8;
      else
        func_width := 8;
      end if; -- end b2

    else
      func_width := 8;
    end if;
    return func_width;
  end;
  function GetFinalWidth (
    d_width : in integer
    ) return integer is
    variable func_least_width : integer;
  begin
    if (d_width = 0) then
      func_least_width := 1;
    else
      func_least_width := d_width;
    end if;
    return func_least_width;
  end;
  function GetMaxCOUNTWidth (
    d_width : in integer;
    fifo_size : in string; 
    device  : in string
    ) return integer is
    variable func_width : integer;
  begin
    if(DEVICE = "VIRTEX5") then
      if (fifo_size = "18Kb" and d_width <= 18 ) then
        func_width := 12;
      elsif (fifo_size = "18Kb" and d_width > 18 and d_width <= 36 ) then
        func_width := 9;
      elsif (fifo_size = "36Kb" and d_width <= 36 ) then
        func_width := 13;
      elsif (fifo_size = "36Kb" and d_width > 36 and d_width <= 72 ) then
        func_width := 9;
      else
        func_width := 13;
      end if;
    elsif(DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if (fifo_size = "18Kb" and d_width <= 36 ) then
        func_width := 12;
      elsif (fifo_size = "36Kb" and d_width <= 72 ) then
        func_width := 13;
      else
        func_width := 13;
      end if; -- end b3
    else
      func_width := 13;
    end if;
    return func_width;
  end;

  function GetFIFOSize (
    fifo_size : in string; 
    device  : in string
    ) return boolean is
    variable fifo_val : boolean;
    variable Message : LINE;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if fifo_size = "18Kb" or fifo_size = "36Kb" then
      fifo_val := TRUE;
      else
          fifo_val := FALSE;
          write( Message, STRING'("Illegal value of Attribute FIFO_SIZE : ") );
          write ( Message, FIFO_SIZE);
          write( Message, STRING'(". Legal values of this attribute are ") );
          write( Message, STRING'(" 18Kb or 36Kb ") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
      end if;
    else
      fifo_val := FALSE;
      write( Message, STRING'("Illegal value of Attribute DEVICE : ") );
      write ( Message, DEVICE);
      write( Message, STRING'(". Allowed values of this attribute are ") );
      write( Message, STRING'(" VIRTEX5, VIRTEX6, 7SERIES. ") );
      ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
      DEALLOCATE (Message);
    end if;
    return fifo_val;
  end;

  function GetD_P (
    dw : in integer;
    device  : in string
    ) return boolean is
    variable dp : boolean;
  begin
    if(DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") then
      if dw = 9 or dw = 17 or dw = 18 or dw = 33 or dw = 34 or dw = 35 or dw = 36 or dw = 65 or dw = 66 or dw = 67 or dw = 68 or dw = 69 or dw = 70 or dw = 71 or dw = 72 then
      dp := TRUE;
       else
          dp := FALSE;
      end if;
    else
      dp := FALSE;
    end if;
    return dp;
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

 function CheckRDCOUNT (
    d_width : in integer;
    fifo_size : in string;
    device  : in string;
    rd_vec : in integer
    ) return boolean is
    variable Message : LINE;
  begin
    if(fifo_size = "18Kb") then
        if ((d_width > 0 and d_width <= 4) and rd_vec /= 12) then
          write( Message, STRING'("RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 12 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >4 and d_width <= 9) and rd_vec /= 11) then
          write( Message, STRING'("RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 11 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >=10 and d_width <=18) and rd_vec /= 10) then
          write( Message, STRING'("RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 10 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >19 and d_width <=36) and rd_vec /= 9) then
          write( Message, STRING'(" .RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 9 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
	else
	  return true;
        end if;
    elsif(fifo_size = "36Kb") then
        if ((d_width > 0 and d_width <= 4) and rd_vec /= 13) then
          write( Message, STRING'("RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 13 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width > 4 and d_width <= 9) and rd_vec /= 12) then
          write( Message, STRING'("RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 12 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >=10 and d_width <=18) and rd_vec /= 11) then
          write( Message, STRING'("RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 11 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >18 and d_width <=36) and rd_vec /= 10) then
          write( Message, STRING'("RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 10 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >36 and d_width <=72) and rd_vec /= 9) then
          write( Message, STRING'("RDCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .RDCOUNT must be of width 9 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
	else
	  return true;
	end if;
      else
        return true;
      end if;
  end;

  function CheckWRCOUNT (
    d_width : in integer;
    fifo_size : in string;
    device  : in string;
    wr_vec : in integer
    ) return boolean is
    variable Message : LINE;
  begin
    if(fifo_size = "18Kb") then
        if ((d_width > 0 and d_width <= 4) and wr_vec /= 12) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 12 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >4 and d_width <= 9) and wr_vec /= 11) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 11 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >=10 and d_width <=18) and wr_vec /= 10) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 10 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >19 and d_width <=36) and wr_vec /= 9) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 9 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
	else
	  return true;
	end if;
      elsif(fifo_size = "36Kb") then
        if ((d_width > 0 and d_width <= 4) and wr_vec /= 13) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 13 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width > 4 and d_width <= 9) and wr_vec /= 12) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 12 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >=10 and d_width <=18) and wr_vec /= 11) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 11 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >18 and d_width <=36) and wr_vec /= 10) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 10 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
        elsif ((d_width >36 and d_width <=72) and wr_vec /= 9) then
          write( Message, STRING'("WRCOUNT port width incorrectly set for DATA_WIDTH : ") );
          write( Message, DATA_WIDTH);
          write( Message, STRING'(" .WRCOUNT must be of width 9 .") );
          ASSERT FALSE REPORT Message.ALL SEVERITY Failure;
          DEALLOCATE (Message);
          return false;
	else
	  return true;
	end if;
      else
        return true;
      end if;
  end;

  constant fifo_size_val : boolean := GetFIFOSize(FIFO_SIZE, DEVICE);
  constant data_p : boolean := GetD_P(DATA_WIDTH, DEVICE); 
  constant count_width : integer := GetCOUNTWidth(DATA_WIDTH, FIFO_SIZE, DEVICE);
  constant d_width : integer  := GetDWidth(DATA_WIDTH, FIFO_SIZE, DEVICE);
  constant d_size : integer := GetD_Size(DATA_WIDTH, DEVICE);
  constant dip_width : integer := GetDIPWidth(DATA_WIDTH, FIFO_SIZE, DEVICE);
  constant dop_width : integer := GetDOPWidth(DATA_WIDTH, FIFO_SIZE, DEVICE);
  constant fin_width : integer := GetFinalWidth(DATA_WIDTH);
  constant sim_device_dp : string := GetSIMDev(DEVICE);
  constant rdctleng : integer := RDCOUNT'length;
  constant wrctleng : integer := WRCOUNT'length;
  constant checkrdct : boolean := CheckRDCount(DATA_WIDTH, FIFO_SIZE, DEVICE, rdctleng);
  constant checkwrct : boolean := CheckWRCount(DATA_WIDTH, FIFO_SIZE, DEVICE, wrctleng);

  constant max_data_width : integer := GetMaxDWidth(DATA_WIDTH, FIFO_SIZE, DEVICE);
  constant max_datap_width : integer := GetMaxDPWidth(DATA_WIDTH, FIFO_SIZE, DEVICE);
  constant max_count_width : integer := GetMaxCOUNTWidth(DATA_WIDTH, FIFO_SIZE, DEVICE);

  signal di_pattern : std_logic_vector(max_data_width-1 downto 0) := (others=>'0');  
  signal do_pattern : std_logic_vector(max_data_width-1 downto 0) := (others=>'0');  
  signal dip_pattern : std_logic_vector(max_datap_width-1 downto 0) := (others=>'0');  
  signal dop_pattern : std_logic_vector(max_datap_width-1 downto 0) := (others=>'0');  
  signal rdcount_pattern : std_logic_vector(max_count_width-1 downto 0) := (others =>'0');
  signal wrcount_pattern : std_logic_vector(max_count_width-1 downto 0) := (others =>'0');

  
  begin
    di1v5 : if  (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate 
      digen1 : if (data_p = TRUE  and ((FIFO_SIZE = "18Kb" and DATA_WIDTH <= 36) or (FIFO_SIZE = "36Kb" and DATA_WIDTH <= 72) ) ) generate
      begin 
        dip_pattern(dip_width-1 downto 0) <= DI(fin_width-1 downto d_width) ;
        di_pattern (d_width-1 downto 0) <= DI(d_width-1 downto 0);
      end generate digen1;
    end generate di1v5;

    di2v5 : if  (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate 
      digen2 : if (data_p = FALSE and ((FIFO_SIZE = "18Kb" and DATA_WIDTH <= 36) or (FIFO_SIZE = "36Kb" and DATA_WIDTH <= 72) ) ) generate
      begin 
        di_pattern(fin_width-1 downto 0) <= DI(fin_width-1 downto 0);
      end generate digen2;
    end generate di2v5;

    do1v5 : if  (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate 
      dogen1 : if (data_p= TRUE and ((FIFO_SIZE = "18Kb" and DATA_WIDTH <= 36) or (FIFO_SIZE = "36Kb" and DATA_WIDTH <= 72) ) ) generate
      begin
        DO <= (dop_pattern(dop_width-1 downto 0) & do_pattern(d_width-1 downto 0));
      end generate dogen1;
    end generate do1v5;

    do2v5 : if  (DEVICE = "VIRTEX5" or DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate 
      dogen2 : if (data_p= FALSE and ((FIFO_SIZE = "18Kb" and DATA_WIDTH <= 36) or (FIFO_SIZE = "36Kb" and DATA_WIDTH <= 72) ) ) generate
      begin
        DO <= do_pattern(fin_width-1 downto 0);
      end generate dogen2;
    end generate do2v5;
 
    RDCOUNT <= rdcount_pattern(count_width-1 downto 0); 
    WRCOUNT <= wrcount_pattern(count_width-1 downto 0); 

  -- begin generate virtex5
  v5 : if (DEVICE = "VIRTEX5") generate
    fifo_18_inst : if ( FIFO_SIZE = "18Kb" and DATA_WIDTH <=18 ) generate 
    begin
    fifo_18_inst : FIFO18 
    generic map (
      ALMOST_FULL_OFFSET => ALMOST_FULL_OFFSET,
      ALMOST_EMPTY_OFFSET => ALMOST_EMPTY_OFFSET, 
      DATA_WIDTH => d_size,
      DO_REG => 1,
      EN_SYN => FALSE,
      FIRST_WORD_FALL_THROUGH => FIRST_WORD_FALL_THROUGH,
      SIM_MODE => SIM_MODE
      )
    port map (
      ALMOSTEMPTY => ALMOSTEMPTY,
      ALMOSTFULL => ALMOSTFULL,
      DO => do_pattern,
      DOP => dop_pattern,
      EMPTY => EMPTY,
      FULL => FULL,
      RDCOUNT => rdcount_pattern,
      RDERR => RDERR,
      WRCOUNT => wrcount_pattern,
      WRERR => WRERR,
      DI => di_pattern,
      DIP => dip_pattern,
      RDCLK => RDCLK,
      RDEN => RDEN,
      RST => RST,
      WRCLK => WRCLK,
      WREN => WREN
      );
    end generate fifo_18_inst;
   
  fifo_18_36_inst : if ( FIFO_SIZE = "18Kb" and DATA_WIDTH > 18 and DATA_WIDTH <= 36 ) generate 
    begin
    fifo_18_36_inst : fifo18_36
    generic map (
      ALMOST_FULL_OFFSET => ALMOST_FULL_OFFSET,
      ALMOST_EMPTY_OFFSET => ALMOST_EMPTY_OFFSET, 
      DO_REG => 1,
      EN_SYN => FALSE,
      FIRST_WORD_FALL_THROUGH => FIRST_WORD_FALL_THROUGH,
      SIM_MODE => SIM_MODE
      )
   port map (
      ALMOSTEMPTY => ALMOSTEMPTY,
      ALMOSTFULL => ALMOSTFULL,
      DO => do_pattern,
      DOP => dop_pattern,
      EMPTY => EMPTY,
      FULL => FULL,
      RDCOUNT => rdcount_pattern,
      RDERR => RDERR,
      WRCOUNT => wrcount_pattern,
      WRERR => WRERR,
      DI => di_pattern,
      DIP => dip_pattern,
      RDCLK => RDCLK,
      RDEN => RDEN,
      RST => RST,
      WRCLK => WRCLK,
      WREN => WREN
      );
   end generate fifo_18_36_inst; 

  fifo_36_inst : if ( FIFO_SIZE = "36Kb" and DATA_WIDTH <= 36 ) generate 
    begin
    fifo_36_inst : FIFO36 
    generic map (
      ALMOST_FULL_OFFSET => ALMOST_FULL_OFFSET,
      ALMOST_EMPTY_OFFSET => ALMOST_EMPTY_OFFSET, 
      DATA_WIDTH => d_size,
      DO_REG => 1,
      EN_SYN => FALSE,
      FIRST_WORD_FALL_THROUGH => FIRST_WORD_FALL_THROUGH,
      SIM_MODE => SIM_MODE
      )
    port map (
      ALMOSTEMPTY => ALMOSTEMPTY,
      ALMOSTFULL => ALMOSTFULL,
      DO => do_pattern,
      DOP => dop_pattern,
      EMPTY => EMPTY,
      FULL => FULL,
      RDCOUNT => rdcount_pattern,
      RDERR => RDERR,
      WRCOUNT => wrcount_pattern,
      WRERR => WRERR,
      DI => di_pattern,
      DIP => dip_pattern,
      RDCLK => RDCLK,
      RDEN => RDEN,
      RST => RST,
      WRCLK => WRCLK,
      WREN => WREN
      );
   end generate fifo_36_inst;

  fifo_36_72_inst : if ( FIFO_SIZE = "36Kb" and DATA_WIDTH > 36 and DATA_WIDTH <= 72 ) generate 
    begin
    fifo_36_72_inst : fifo36_72
    generic map (
      ALMOST_FULL_OFFSET => ALMOST_FULL_OFFSET,
      ALMOST_EMPTY_OFFSET => ALMOST_EMPTY_OFFSET, 
      DO_REG => 1,
      EN_SYN => FALSE,
      FIRST_WORD_FALL_THROUGH => FIRST_WORD_FALL_THROUGH,
      SIM_MODE => SIM_MODE
      )
    port map (
      ALMOSTEMPTY => ALMOSTEMPTY,
      ALMOSTFULL => ALMOSTFULL,
      DBITERR => OPEN,
      DO => do_pattern,
      DOP => dop_pattern,
      ECCPARITY => OPEN,
      EMPTY => EMPTY,
      FULL => FULL,
      RDCOUNT => rdcount_pattern,
      RDERR => RDERR,
      SBITERR => OPEN,
      WRCOUNT => wrcount_pattern,
      WRERR => WRERR,
      DI => di_pattern,
      DIP => dip_pattern,
      RDCLK => RDCLK,
      RDEN => RDEN,
      RST => RST,
      WRCLK => WRCLK,
      WREN => WREN
      );
   end generate fifo_36_72_inst; 
  end generate v5;
  -- end generate virtex5
  -- begin generate virtex6
  bl : if (DEVICE = "VIRTEX6" or DEVICE = "7SERIES") generate
    fifo_18_inst_bl : if ( FIFO_SIZE = "18Kb" and DATA_WIDTH <= 18 ) generate 
    begin
    fifo_18_bl : FIFO18E1 
    generic map (
      ALMOST_FULL_OFFSET => ALMOST_FULL_OFFSET,
      ALMOST_EMPTY_OFFSET => ALMOST_EMPTY_OFFSET, 
      DATA_WIDTH => d_size,
      DO_REG => 1,
      EN_SYN => FALSE,
      FIFO_MODE => "FIFO18",
      FIRST_WORD_FALL_THROUGH => FIRST_WORD_FALL_THROUGH,
      INIT => INIT(0 to 35),
      SIM_DEVICE => sim_device_dp,
      SRVAL => SRVAL(0 to 35)
      )
    port map (
      ALMOSTEMPTY => ALMOSTEMPTY,
      ALMOSTFULL => ALMOSTFULL,
      DO => do_pattern,
      DOP => dop_pattern,
      EMPTY => EMPTY,
      FULL => FULL,
      RDCOUNT => rdcount_pattern,
      RDERR => RDERR,
      WRCOUNT => wrcount_pattern,
      WRERR => WRERR,
      DI => di_pattern,
      DIP => dip_pattern,
      RDCLK => RDCLK,
      RDEN => RDEN,
      REGCE => '1',
      RST => RST,
      RSTREG => '1',
      WRCLK => WRCLK,
      WREN => WREN
      );
    end generate fifo_18_inst_bl;
    fifo_18_inst_bl_1 : if ( FIFO_SIZE = "18Kb" and DATA_WIDTH > 18 and DATA_WIDTH <= 36 ) generate 
    begin
    fifo_18_bl_1 : FIFO18E1 
    generic map (
      ALMOST_FULL_OFFSET => ALMOST_FULL_OFFSET,
      ALMOST_EMPTY_OFFSET => ALMOST_EMPTY_OFFSET, 
      DATA_WIDTH => d_size,
      DO_REG => 1,
      EN_SYN => FALSE,
      FIFO_MODE => "FIFO18_36",
      FIRST_WORD_FALL_THROUGH => FIRST_WORD_FALL_THROUGH,
      INIT => INIT(0 to 35),
      SIM_DEVICE => sim_device_dp,
      SRVAL => SRVAL(0 to 35)
      )
    port map (
      ALMOSTEMPTY => ALMOSTEMPTY,
      ALMOSTFULL => ALMOSTFULL,
      DO => do_pattern,
      DOP => dop_pattern,
      EMPTY => EMPTY,
      FULL => FULL,
      RDCOUNT => rdcount_pattern,
      RDERR => RDERR,
      WRCOUNT => wrcount_pattern,
      WRERR => WRERR,
      DI => di_pattern,
      DIP => dip_pattern,
      RDCLK => RDCLK,
      RDEN => RDEN,
      REGCE => '1',
      RST => RST,
      RSTREG => '1',
      WRCLK => WRCLK,
      WREN => WREN
      );
    end generate fifo_18_inst_bl_1;   
  fifo_36_inst_bl : if ( FIFO_SIZE = "36Kb" and DATA_WIDTH <= 36 ) generate 
    begin
    fifo_36_bl : FIFO36E1 
    generic map (
      ALMOST_FULL_OFFSET => ALMOST_FULL_OFFSET,
      ALMOST_EMPTY_OFFSET => ALMOST_EMPTY_OFFSET, 
      DATA_WIDTH => d_size,
      DO_REG => 1,
      EN_SYN => FALSE,
      FIFO_MODE => "FIFO36",
      FIRST_WORD_FALL_THROUGH => FIRST_WORD_FALL_THROUGH,
      INIT => INIT,
      SIM_DEVICE => sim_device_dp,
      SRVAL => SRVAL
      )
    port map (
      ALMOSTEMPTY => ALMOSTEMPTY,
      ALMOSTFULL => ALMOSTFULL,
      DBITERR => OPEN,
      DO => do_pattern,
      DOP => dop_pattern,
      ECCPARITY => OPEN,
      EMPTY => EMPTY,
      FULL => FULL,
      RDCOUNT => rdcount_pattern,
      RDERR => RDERR,
      SBITERR => OPEN,
      WRCOUNT => wrcount_pattern,
      WRERR => WRERR,
      DI => di_pattern,
      DIP => dip_pattern,
      INJECTDBITERR => '0',
      INJECTSBITERR => '0',
      RDCLK => RDCLK,
      RDEN => RDEN,
      REGCE => '1',
      RST => RST,
      RSTREG => '1',
      WRCLK => WRCLK,
      WREN => WREN
      );
   end generate fifo_36_inst_bl;
   fifo_36_inst_bl_1 : if ( FIFO_SIZE = "36Kb" and DATA_WIDTH > 36 and DATA_WIDTH <= 72 ) generate 
    begin
    fifo_36_bl_1 : FIFO36E1 
    generic map (
      ALMOST_FULL_OFFSET => ALMOST_FULL_OFFSET,
      ALMOST_EMPTY_OFFSET => ALMOST_EMPTY_OFFSET, 
      DATA_WIDTH => d_size,
      DO_REG => 1,
      EN_SYN => FALSE,
      FIFO_MODE => "FIFO36_72",
      FIRST_WORD_FALL_THROUGH => FIRST_WORD_FALL_THROUGH,
      INIT => INIT,
      SIM_DEVICE => sim_device_dp,
      SRVAL => SRVAL
      )
    port map (
      ALMOSTEMPTY => ALMOSTEMPTY,
      ALMOSTFULL => ALMOSTFULL,
      DBITERR => OPEN,
      DO => do_pattern,
      DOP => dop_pattern,
      ECCPARITY => OPEN,
      EMPTY => EMPTY,
      FULL => FULL,
      RDCOUNT => rdcount_pattern,
      RDERR => RDERR,
      SBITERR => OPEN,
      WRCOUNT => wrcount_pattern,
      WRERR => WRERR,
      DI => di_pattern,
      DIP => dip_pattern,
      INJECTDBITERR => '0',
      INJECTSBITERR => '0',
      RDCLK => RDCLK,
      RDEN => RDEN,
      REGCE => '1',
      RST => RST,
      RSTREG => '1',
      WRCLK => WRCLK,
      WREN => WREN
      );
   end generate fifo_36_inst_bl_1;

  end generate bl;
  -- end generate virtex6
  
 end fifo_V;

