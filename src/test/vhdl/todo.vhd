library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity todo is
   generic(
      INBYLEVEL : boolean:=FALSE
   );
   port (
      clk_i  : in  std_logic;
      data_i : in  std_logic_vector(7 downto 0);
      data_o : out std_logic_vector(7 downto 0)
   );
end todo;

architecture rtl of todo is
   type mem_type is array (0 to 255) of integer;
   signal mem : mem_type;

   signal int : integer;
   signal uns : unsigned(7 downto 0);

   constant BYTES  : positive:=4;
   constant WIDTH  : positive:=BYTES*8;
   signal index    : natural range 0 to BYTES-1;
   signal comma    : std_logic_vector(BYTES*3-1 downto 0);

   -- (others => (others => '0')) must be replaced by an initial block with a for
   -- or something similar.
   --type ff_array is array (0 to 255) of std_logic_vector(7 downto 0);
   --signal data_r : ff_array :=(others => (others => '0'));
begin
   --**************************************************************************
   -- Wrong translations
   --**************************************************************************
   --
   test_i: process(clk_i)
      -- iverilog: variable declaration assignments are only allowed at the module level.
      variable i : integer:=8;
   begin
      for i in 0 to 7 loop
          if i=4 then
             exit; -- iverilog: error: malformed statement
          end if;
      end loop;
   end process test_i;
   -- indexed part-select not applied
   do_boundary: process (clk_i)
   begin
      if rising_edge(clk_i) then
         for i in 0 to BYTES-1 loop
             if comma(BYTES*2+i-1 downto BYTES+i)=comma(3 downto 0) then
                index <= i;
             end if;
         end loop;
      end if;
   end process;
   comma <= comma(BYTES+index-1 downto index);
   --**************************************************************************
   -- Translations which abort with syntax error (uncomment to test)
   --**************************************************************************
   -- Concatenation in port assignament fail
--   uns <= "0000" & X"1"; -- It is supported
--   dut1_i: entity work.signextend
--      port map (
--        i => "00000000" & X"11", -- But here fail
--        o => open
--      );
   -- Unsupported generate with boolean?
--   in_by_level:
--   if INBYLEVEL generate
--      int <= 9;
--   end generate in_by_level;
end rtl;
