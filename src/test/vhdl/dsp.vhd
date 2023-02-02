-- Nearly useless stub, it's here to support genericmap.vhd
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

entity dsp is generic(
  rst_val   : std_logic := '0';
  thing_size: integer   := 51;
  bus_width : integer   := 24);
    port(
      -- Inputs
      clk, rstn : in std_logic;
      en, start : in std_logic;
      param     : in std_logic_vector(7 downto 0);
      addr      : in std_logic_vector(2 downto 0);
      din       : in std_logic_vector(bus_width-1 downto 0);
      we        : in std_logic;
      memdin    : out std_logic_vector(13 downto 0);
      -- Outputs
      dout      : out std_logic_vector(bus_width-1 downto 0);
      memaddr   : out std_logic_vector(5 downto 0);
      memdout   : out std_logic_vector(13 downto 0)
      );
end;

architecture rtl of dsp is
    signal foo : std_logic;
    signal sr  : std_logic_vector(63 downto 0);
    signal iparam : integer;
begin
    iparam <= to_integer(unsigned(param));
    process(clk) begin
       -- dout <= std_logic_vector(to_unsigned(1,bus_width));
       if rising_edge(clk) then
           if we = '1' then
              sr <= sr(thing_size-bus_width-1 downto 0) & din;
           end if;
           dout <= sr(iparam*bus_width+bus_width-1 downto iparam*bus_width);
       end if;
    end process;
end rtl;
