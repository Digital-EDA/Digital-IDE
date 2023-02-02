library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity operators is
   generic (
      g_and  : std_logic_vector(1 downto 0) := "11" and  "10";
      g_or   : std_logic_vector(1 downto 0) := "11" or   "10";
      g_nand : std_logic_vector(1 downto 0) := "11" nand "10";
      g_nor  : std_logic_vector(1 downto 0) := "11" nor  "10";
      g_xor  : std_logic_vector(1 downto 0) := "11" xor  "10";
      g_xnor : std_logic_vector(1 downto 0) := "11" xnor "10";
      g_not  : std_logic_vector(1 downto 0) := not "10"
   );
   port (
      clk_i : in std_logic
   );
end entity operators;

architecture rtl of operators is
   constant c_and  : std_logic_vector(1 downto 0) := "11" and  "10";
   constant c_or   : std_logic_vector(1 downto 0) := "11" or   "10";
   constant c_nand : std_logic_vector(1 downto 0) := "11" nand "10";
   constant c_nor  : std_logic_vector(1 downto 0) := "11" nor  "10";
   constant c_xor  : std_logic_vector(1 downto 0) := "11" xor  "10";
   constant c_xnor : std_logic_vector(1 downto 0) := "11" xnor "10";
   constant c_not  : std_logic_vector(1 downto 0) := not "10";
   signal   s_op1  : std_logic_vector(1 downto 0);
   signal   s_op2  : std_logic_vector(1 downto 0);
   signal   s_res  : std_logic_vector(1 downto 0);
   signal   s_int  : integer;
   signal   s_sig  : signed(7 downto 0);
   signal   s_uns  : unsigned(7 downto 0);
begin

   test_i: process(clk_i)
      variable v_op1  : std_logic_vector(1 downto 0);
      variable v_op2  : std_logic_vector(1 downto 0);
      variable v_res  : std_logic_vector(1 downto 0);
   begin
      if rising_edge(clk_i) then
         if
            (s_op1="11" and  s_op2="00") or
            (s_op1="11" or   s_op2="00") or
            (s_op1="11" nand s_op2="00") or
            (s_op1="11" nor  s_op2="00") or
            (not (s_op1="11"))
         then
            s_res <= s_op1 and  s_op2;
            s_res <= s_op1 or   s_op2;
            v_res := v_op1 nand v_op2;
            v_res := v_op1 nor  v_op2;
            s_res <= s_op1 xor  s_op2;
            v_res := v_op1 xnor v_op2;
            s_res <= not s_op1;
            s_int <= abs(s_int);
            s_sig <= abs(s_sig);
            s_sig <= s_sig sll 2;
            s_sig <= s_sig srl to_integer(s_sig);
            s_uns <= s_uns sll to_integer(s_uns);
            s_uns <= s_uns srl 9;
            s_sig <= shift_left(s_sig,2);
            s_sig <= shift_right(s_sig,to_integer(s_sig));
            -- s_uns <= s_uns ror 3;                          -- Not yet implemented
            -- s_uns <= s_uns rol to_integer(s_uns);          -- Not yet implemented
            -- s_uns <= rotate_right(s_uns,3);                -- Not yet implemented
            -- s_uns <= rotate_left(s_uns,to_integer(s_uns)); -- Not yet implemented
            s_sig <= s_sig rem s_int;
            s_sig <= s_sig mod s_int;
         end if;
         if
            s_sig = signed(s_uns) or unsigned(s_sig) /= s_uns or s_sig < "101010101" or
            s_sig <= signed(s_uns) or unsigned(s_sig) > s_uns or s_sig >= "00000101"
         then
            s_sig <= s_sig + s_sig;
            s_sig <= s_sig - s_sig;
            s_sig <= s_sig * s_sig;
            s_sig <= s_sig / s_sig;
            s_sig <= s_sig(7 downto 4) & "10" & signed(s_uns(1 downto 0));
            s_int <= 2 ** 3;
         end if;
      end if;
   end process test_i;

end architecture rtl;
