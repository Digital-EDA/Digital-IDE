LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
entity clk is port( reset, preset, qreset, sysclk, dsysclk, esysclk : in std_logic;
                     ival : in std_logic_vector(31 downto 0)
                     );
end clk;
architecture rtl of clk is
  signal foo : std_logic_vector(10+3 downto 0);
  signal baz : std_logic_vector(2 downto 0);
  signal egg : std_logic_vector(4 to 7-1);
begin
  pfoo: process(reset, sysclk)
  begin
    if( reset /= '0' ) then
      foo <= (others => '1');
    elsif( sysclk'event and sysclk = '1' ) then
      foo <= ival(31 downto 31-(10+3));
    end if;
  end process;
  pbaz: process(preset, dsysclk)
  begin
    if( preset /= '1' ) then
      baz <= (others => '0');
    elsif( dsysclk'event and dsysclk = '0' ) then
      baz <= ival(2 downto 0);
    end if;
  end process;
  pegg: process(qreset, esysclk)
  begin
    if( qreset /= '1' ) then
      egg <= (others => '0');
    elsif( esysclk'event and esysclk = '0' ) then
      egg <= ival(6 downto 4);
    end if;
  end process;
end rtl;
