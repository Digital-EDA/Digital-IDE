library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity expr is
generic(SIZE: positive:=2**8-1);
port(reset, sysclk, ival : in std_logic);
end expr;

architecture rtl of expr is
  constant SIZE_OF : positive:=2**8-1;
  signal foo : std_logic_vector(13 downto 0);
  signal baz : std_logic_vector(2 downto 0);
  signal bam : std_logic_vector(22 downto 0);
  signal out_i : std_logic_vector(5 downto 3);
  signal input_status : std_logic_vector(8 downto 0);
  signal enable, debug, aux, outy, dv, value : std_logic;
  signal expo : std_logic_vector(2**3-1 downto 0);
begin
  -- drive input status
  input_status <=    -- top bits
                           (foo(9 downto 4) &
                            (( (baz(2 downto 0) and foo(3 downto 0)) or
                             (not baz(2 downto 0) and bam(3 downto 0)))));
  -- drive based on foo
  out_i(4) <=
    -- if secondary enabl is set then drive aux out
    (enable and (aux xor outy)) or
    -- if debug is enabled
    (debug and dv and not enable) or
    -- otherwise we drive reg
    (not debug and not enable and value);
  -- not drive

  pfoo: process(reset, sysclk)
  begin
    if( reset /= '0' ) then
      foo <= (others => '0');
    elsif( sysclk'event and sysclk = '0' ) then
      foo(3*(2-1)) <= baz(1*(1+2)-2);
      bam(foo'range) <= foo;
    end if;
  end process;

  expo <= std_logic_vector(to_unsigned(2**4, 2**8));
end rtl;
