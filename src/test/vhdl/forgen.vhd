LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

entity forgen is
  generic(
    bus_width : integer := 15;
    TOP_GP2 : integer:= 0
  );
  port(
    sysclk, reset, wrb : in std_logic;
    din : in std_logic_vector(bus_width downto 0);
    rdout: out std_logic_vector(bus_width downto 0)
  );
end forgen;

architecture rtl of forgen is
  component wbit1                       -- register bit default 1
    port(
      clk   : in  std_logic;
      wrb   : in  std_logic;
      reset : in  std_logic;
      enb   : in  std_logic;
      din   : in  std_logic;
      dout  : out std_logic);
  end component;

  signal regSelect : std_logic_vector(bus_width * 2 downto 0);
begin
  -----------------------------------------------------
  -- Reg    : GP 2
  -- Active : 32
  -- Type   : RW
  -----------------------------------------------------
  reg_gp2 : for bitnum in 0 to bus_width generate
    wbit1_inst : wbit1
      PORT MAP(
      clk   => sysclk,
      wrb   => wrb,
      reset => reset,
      enb   => regSelect(TOP_GP2),
      din   => din(bitnum),
      dout  => rdout(bitnum)
      );
  end generate;

  process(sysclk) begin
    if sysclk'event and sysclk = '1' then
      regSelect(1) <= '1';
    end if;
  end process;

end rtl;
