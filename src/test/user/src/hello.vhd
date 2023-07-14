-- VHDL code for a 2-to-1 multiplexer
library IEEE;
use IEEE.std_logic_1164.all;

entity mux2to1 is
  port(a, b : in std_logic;
       sel : in std_logic;
       outp : out std_logic);
end mux2to1;

architecture behavioral of mux2to1 is
begin
  outp <= a when sel = '0' else b;
end behavioral;