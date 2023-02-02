library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity signextend is
    port(
        i : in std_logic_vector(15 downto 0);
        o : out std_logic_vector(31 downto 0)
    );
end entity signextend;

architecture behavior of signextend is
begin
    o(31 downto 24) <= (others => '0');
    o(23 downto 16) <= (others => i(15));
    o(15 downto 0) <= i;
end architecture behavior;
