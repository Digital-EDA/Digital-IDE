LIBRARY IEEE;
USE IEEE.std_logic_1164.all, IEEE.numeric_std.all;

entity withselect is
  generic(
    dog_width : std_logic_vector(7 downto 0) := "10101100";
    bus_width : integer := 32
    );
    port( reset, sysclk : in std_logic;
          a, b, enf, load, qtd, base: in std_logic_vector(bus_width downto 0)
          );
end withselect;

architecture rtl of withselect is
  signal foo : std_logic_vector(1+1 downto 0);
  signal code,code1: std_logic_vector(9 downto 0);
  signal egg : std_logic_vector(324 to 401);
  signal baz : std_logic_vector(bus_width*3-1 to bus_width*4);
  signal complex : std_logic_vector(31 downto 0);
begin
  -- Example of with statement
  with foo(2 downto 0) select
    code(9 downto 2) <= "110" & egg(325 to 329) when "000" | "110",
                        "11100010" when "101",
                        (others => '1') when "010",
                        (others => '0') when "011",
                        std_logic_vector(unsigned(a) + unsigned(b)) when others;
  code1(1 downto 0) <= a(6 downto 5) xor (a(4) & b(6));

  foo <= (others => '0');
  egg <= (others => '0');
  baz <= (others => '1');
  complex <= enf & (std_logic_vector("110" * unsigned(load))) & qtd(3 downto 0) & base & "11001";
end rtl;
