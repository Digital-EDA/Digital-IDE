-- Nearly useless stub, it's here to support generate.vhd
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

entity wbit1 is
    port(
      clk   : in  std_logic;
      wrb   : in  std_logic;
      reset : in  std_logic;
      enb   : in  std_logic;
      din   : in  std_logic;
      dout  : out std_logic);
end;

architecture rtl of wbit1 is
    signal foo : std_logic;
begin
    process(clk) begin
       dout <= '1';
    end process;
end rtl;
