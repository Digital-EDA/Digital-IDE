library IEEE;
use IEEE.std_logic_1164.all;

entity partselect is
   port(
      clk_i : in std_logic
   );
end entity partselect;

architecture rtl of partselect is
   signal big_sig : std_logic_vector(31 downto 0);
   signal lit_sig : std_logic_vector(0 to 31);
   signal i       : integer:=8;
begin

   test_i: process(clk_i)
      variable big_var : std_logic_vector(31 downto 0);
      variable lit_var : std_logic_vector(0 to 31);
      variable j       : integer;
   begin
      if rising_edge(clk_i) then
         big_sig(31 downto 24) <= big_sig(7 downto 0);
         big_var(31 downto 24) := big_var(7 downto 0);
         lit_sig(i*3 to i*3+7) <= lit_sig(0 to 7);
         lit_var(j*3 to j*3+8) := lit_var(j*0 to 8+j*0);
         --
         big_sig(i*3+8 downto i*3) <= big_sig(8 downto 0);
         big_var(j*3+8 downto j*3) := big_var(j*0+8 downto j*0);
      end if;
   end process test_i;

end architecture rtl;
