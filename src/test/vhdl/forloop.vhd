library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forloop is port(
  reset, sysclk : in std_logic
);
end forloop;

architecture rtl of forloop is
  signal selection : std_logic;
  signal egg_timer : std_logic_vector(6 downto 0);
begin
  TIMERS :
  process(reset, sysclk)
    variable timer_var : integer;
    variable a, i, j, k : integer;
    variable zz5 : std_logic_vector(31 downto 0);
    variable zz : std_logic_vector(511 downto 0);
  begin
    if reset = '1' then
      selection <= '1';
      timer_var := 2;
      egg_timer <= (others => '0');
    elsif sysclk'event and sysclk = '1' then
      --  pulse only lasts for once cycle
      selection <= '0';
      egg_timer <= (others => '1');
      for i in 0 to j*k loop
        a := a + i;
        for k in a-9 downto -14 loop
          zz5 := zz(31+k downto k);
        end loop;  -- k
      end loop;  -- i
    end if;
  end process;
end rtl;
