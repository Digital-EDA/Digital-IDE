library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem is
generic(
  addr_width : integer := 6;
  bus_width : integer := 14
);
  port (
    clk : in std_logic;
    rstn : in std_logic;  -- not implemented
    en : in std_logic;
    cs : in std_logic;  -- not implemented
    addr : in unsigned(addr_width-1 downto 0);
    din : in unsigned(bus_width-1 downto 0);
    dout : out unsigned(bus_width-1 downto 0)
  );
end entity;

architecture rtl of mem is
  signal al : unsigned(addr_width-1 downto 0) := X"00";
  type mem_Type is array (255 downto 0) of unsigned(bus_width-1 downto 0);
  signal mem : mem_Type;
begin
  dout <= mem(to_integer(al));
  process (clk) is
  begin
    if rising_edge(clk) then
      al <= addr;
      if en = '1' then
        mem(to_integer(addr)) <= din;
      end if;
    end if;
  end process;
end architecture;
