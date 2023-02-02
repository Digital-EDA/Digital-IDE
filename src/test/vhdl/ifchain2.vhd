LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

entity ifchain2 is port(
  clk, rstn : in std_logic;
  enable: in std_logic;
  result: out std_logic
);
end ifchain2;

architecture rtl of ifchain2 is
  signal counter : unsigned(3 downto 0);
  constant CLK_DIV_VAL : unsigned(3 downto 0) := to_unsigned(11,4);
begin

clk_src : process(clk, rstn) is
begin
    if (rstn = '0') then
        counter <= (others => '0');
        result <= '0';
    elsif (rising_edge(clk)) then -- Divide by 2 by default
        if (enable = '1') then
            if (counter = 0) then
                counter <= CLK_DIV_VAL;
                result <= '1';
            else
                counter <= counter - 1;
                result <= '0';
            end if; -- counter
        end if; -- enable
    end if; -- clk, rst_n
end process clk_src;
assert (counter < CLK_DIV_VAL) report "test case" severity error;

end rtl;
