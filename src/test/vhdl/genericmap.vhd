LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
entity genericmap is
generic(
  rst_val   : std_logic := '0';
  thing_size: integer := 201 rem 2;
  bus_width : integer := 201 mod 32);
port(
  clk, rstn : in std_logic;
  en, start_dec : in std_logic;
  addr : in std_logic_vector(2 downto 0);
  din : in std_logic_vector(25 downto 0);
  we : in std_logic;
  pixel_in : in std_logic_vector(7 downto 0);
  pix_req : in std_logic;
  bip : in std_logic;
  a, b : in std_logic_vector(7 downto 0);
  c, load : in std_logic_vector(7 downto 0);
  pack : in std_logic_vector(6 downto 0);
  base : in std_logic_vector(2 downto 0);
  qtd : in std_logic_vector(21 downto 0);
  -- Outputs
  dout : out std_logic_vector(25 downto 0);
  pixel_out : out std_logic_vector(7 downto 0);
  pixel_valid : out std_logic;
  code : out std_logic_vector(9 downto 0);
  complex : out std_logic_vector(23 downto 0);
  eno : out std_logic
);
end genericmap;
architecture rtl of genericmap is

  component dsp
    generic(
      rst_val   : std_logic := '0';
      thing_size: integer := 201;
      bus_width : integer := 24);
    port(
      -- Inputs
      clk, rstn : in std_logic;
      en, start : in std_logic;
      param : in std_logic_vector(7 downto 0);
      addr : in std_logic_vector(2 downto 0);
      din : in std_logic_vector(bus_width-1 downto 0);
      we : in std_logic;
      memdin : out std_logic_vector(13 downto 0);
      -- Outputs
      dout : out std_logic_vector(bus_width-1 downto 0);
      memaddr : out std_logic_vector(5 downto 0);
      memdout : out std_logic_vector(13 downto 0)
      );
  end component;
  signal param : std_logic_vector(7 downto 0);
  signal selection : std_logic;
  signal start, enf : std_logic; -- Start and enable signals
  signal memdin : std_logic_vector(13 downto 0);
  signal memaddr : std_logic_vector(5 downto 0);
  signal memdout : std_logic_vector(13 downto 0);
  signal colour : std_logic_vector(1 downto 0);
begin
  dsp_inst0 : dsp
    -- default bus_width is 24
    port map(
    -- Inputs
    clk => clk,
    rstn => rstn,
    en => '1',
    start => '0',
    param => X"42",
    addr => "101",
    din => "000100010001000100010001",
    we => '0',
    -- Outputs
    dout => dout(23 downto 0),
    memaddr => memaddr,
    memdout => memdout
  );

  dsp_inst1 : dsp
    generic map(
      rst_val   => '1',
      bus_width => 16)
    port map(
    -- Inputs
    clk => clk,
    rstn => rstn,
    en => '1',
    start => '0',
    param => X"42",
    addr => "101",
    din => "0001000100010001",
    we => '0',
    -- Outputs
    dout => dout(15 downto 0),
    memaddr => memaddr,
    memdout => memdout
  );

  signextend_inst2 : entity work.signextend
   port map (
      i => "0000000000000000",
      o => open
   );

end rtl;
