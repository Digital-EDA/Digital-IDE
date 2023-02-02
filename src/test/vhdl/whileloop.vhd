library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity whileloop is port(
  A : in integer;
  Z : out std_logic_vector(3 downto 0)
);
end whileloop;

architecture rtl of whileloop is
begin

process (A)
    variable I : integer range 0 to 4;
begin
    Z <= "0000";
    I := 0;
    while (I <= 3) loop
      if (A = I) then
        Z(I) <= '1';
      end if;
      I := I + 1;
    end loop;
end process;

end rtl;
