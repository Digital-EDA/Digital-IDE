library IEEE;
use IEEE.std_logic_1164.all;

entity Scientific is
   generic (
      exp1: integer := 25e6;
      exp2: integer := 25E6;
      exp3: real    := 25.0e6;
      exp4: real    := 50.0e+3;
      exp5: real    := 50.0e-3
   );
   port(
      clk : in std_logic
   );
end Scientific;
