-- Project: VHDL to Verilog RTL translation
-- Revision: 1.0
-- Date of last Revision: February 27 2001
-- Designer: Vincenzo Liguori
-- vhd2vl test file
-- This VHDL file exercises vhd2vl

LIBRARY IEEE;

USE IEEE.std_logic_1164.all, IEEE.numeric_std.all;

entity test is port(
  -- Inputs
  clk, rstn : in std_logic;
  en, start_dec : in std_logic;
  addr : in std_logic_vector(2 downto 0);
  din : in std_logic_vector(25 downto 0);
  we : in std_logic;
  pixel_in : in std_logic_vector(7 downto 0);
  pix_req : in std_logic;
  config1, bip : in std_logic;
  a, b : in std_logic_vector(7 downto 0);
  c, load : in std_logic_vector(7 downto 0);
  pack : in std_logic_vector(6 downto 0);
  base : in std_logic_vector(2 downto 0);
  qtd : in std_logic_vector(21 downto 0);
  -- Outputs
  dout : out std_logic_vector(23 downto 0);
  pixel_out : out std_logic_vector(7 downto 0);
  pixel_valid : out std_logic;
  code : out std_logic_vector(9 downto 0);
  code1 : out std_logic_vector(9 downto 0);
  complex : out std_logic_vector(23 downto 0);
  eno : out std_logic
);
end test;

architecture rtl of test is

-- Components declarations are ignored by vhd2vl
-- but they are still parsed

component dsp port(
  -- Inputs
  clk, rstn : in std_logic;
  en, start : in std_logic;
  param : in std_logic_vector(7 downto 0);
  addr : in std_logic_vector(2 downto 0);
  din : in std_logic_vector(23 downto 0);
  we : in std_logic;
  memdin : out std_logic_vector(13 downto 0);
    -- Outputs
  dout : out std_logic_vector(23 downto 0);
  memaddr : out std_logic_vector(5 downto 0);
  memdout : out std_logic_vector(13 downto 0)
);
end component;

component mem port(
  -- Inputs
  clk, rstn : in std_logic;
  en : in std_logic;
  cs : in std_logic;
  addr : in std_logic_vector(5 downto 0);
  din : in std_logic_vector(13 downto 0);
  -- Outputs
  dout : out std_logic_vector(13 downto 0)
);
end component;

  type state is (red, green, blue, yellow);
  signal status : state;
  constant PARAM1 : std_logic_vector(7 downto 0):="01101101";
  constant PARAM2 : std_logic_vector(7 downto 0):="11001101";
  constant PARAM3 : std_logic_vector(7 downto 0):="00010111";
  signal param : std_logic_vector(7 downto 0);
  signal selection : std_logic := '0';
  signal start, enf : std_logic; -- Start and enable signals
  signal memdin : std_logic_vector(13 downto 0);
  signal memaddr : std_logic_vector(5 downto 0);
  signal memdout : std_logic_vector(13 downto 0);
  signal colour : std_logic_vector(1 downto 0);
begin

  param <= PARAM1 when config1 = '1' else PARAM2 when status = green else PARAM3;

  -- Synchronously process
  process(clk) begin
    if clk'event and clk = '1' then
      pixel_out <= pixel_in xor "11001100";
    end if;
  end process;

  -- Synchronous process
  process(clk) begin
    if rising_edge(clk) then
      case status is
        when red => colour <= "00";
        when green => colour <= B"01";
        when blue => colour <= "10";
        when others => colour <= "11";
      end case;
    end if;
  end process;

  -- Synchronous process with asynch reset
  process(clk,rstn) begin
    if rstn = '0' then
      status <= red;
    elsif rising_edge(clk) then
      case status is
        when red =>
          if pix_req = '1' then
            status <= green;
          end if;
        when green =>
          if a(3) = '1' then
            start <= start_dec;
            status <= blue;
          elsif (b(5) & a(3 downto 2)) = "001" then
            status <= yellow;
          end if;
        when blue =>
          status <= yellow;
        when others =>
          start <= '0';
          status <= red;
      end case;
    end if;
  end process;

  -- Example of with statement
  with memaddr(2 downto 0) select
    code(9 downto 2) <= "110" & pack(6 downto 2) when "000" | "110",
                        "11100010" when "101",
                        (others => '1') when "010",
                        (others => '0') when "011",
                        std_logic_vector(unsigned(a) + unsigned(b)) when others;
  code1(1 downto 0) <= a(6 downto 5) xor (a(4) & b(6));

  -- Asynch process
  decode : process(we, addr, config1, bip) begin
    if we = '1' then
      if addr(2 downto 0) = "100" then
        selection <= '1';
      elsif (b & a) = a & b and bip = '0' then
        selection <= config1;
      else
        selection <= '1';
      end if;
    else
      selection <= '0';
    end if;
  end process decode;

  -- Components instantiation
  dsp_inst : dsp port map(
    -- Inputs
    clk => clk,
    rstn => rstn,
    en => en,
    start => start,
    param => param,
    addr => addr,
    din => din(23 downto 0),
    we => we,
    memdin => memdin,
    -- Outputs
    dout => dout,
    memaddr => memaddr,
    memdout => memdout
  );

  dsp_mem : mem port map(
    -- Inputs
    clk => clk,
    rstn => rstn,
    en => en,
    cs => selection,
    addr => memaddr,
    din => memdout,
    -- Outputs
    dout => memdin
  );

  complex <= enf & (std_logic_vector("110" * unsigned(load))) & qtd(3 downto 0) & base & "11001";

  enf <= '1' when c < "1000111" else '0';
  eno <= enf;

end rtl;
