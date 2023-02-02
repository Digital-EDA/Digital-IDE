library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity ADC_CFG is
    Port (
        clk                             : in  std_logic;
        rstn                            : in  std_logic;
        sclk                            : out std_logic;
        sdata                           : out std_logic;
        sen                             : out std_logic;
        adc_rst                         : out std_logic;
        cfg_done                        : out std_logic
    );
end ADC_CFG;

architecture Behavioral of ADC_CFG iimage.pngsimage.png
    image.png
    component CFG_INT
    Port ( 
        CLK                             : in STD_LOGIC;--100mhz
        RSTn                            : in STD_LOGIC;
        TRIG                            : in STD_LOGIC;
        ADDR                            : in STD_LOGIC_VECTOR (7 downto 0);
        DATA                            : in STD_LOGIC_VECTOR (7 downto 0);
        SCLK                            : out STD_LOGIC;
        SDATA                           : out STD_LOGIC;
        SEN                             : out STD_LOGIC;
        BUSY                            : out STD_LOGIC
    );
    end component;

    type   array_reg is array (0 to 25) of std_logic_vector(7 downto 0);
    signal addr_reg                     : array_reg :=( x"42", --
                                                        x"00", --bit0 readout ; --bit1 reset
                                                        x"01",
                                                        x"03",
                                                        x"25",
                                                        x"29",
                                                        x"2b",
                                                        x"3d",
                                                        x"3f",
                                                        x"40",
                                                        x"41",
                                                        x"42",
                                                        x"45",
                                                        x"4a",
                                                        x"58",
                                                        x"bf",
                                                        x"c1",
                                                        x"cf",
                                                        x"ef",
                                                        x"f1",
                                                        x"f2",
                                                        x"02",
                                                        x"d5",
                                                        x"d7",
                                                        x"db",
                                                        x"00" --the last byte no meaning
                                                        );
    constant data_reg                   : array_reg :=( x"08", --
                                                        x"00", --bit0 readout ; --bit1 reset
                                                        x"00",
                                                        x"03",
                                                        x"00",
                                                        x"00",
                                                        x"00",
                                                        x"00",
                                                        x"00",
                                                        x"00",
                                                        x"03",
                                                        x"08",
                                                        x"00",
                                                        x"01",
                                                        x"01",
                                                        x"00",
                                                        x"00",
                                                        x"00",
                                                        x"00",
                                                        x"03",
                                                        x"00",
                                                        x"40",
                                                        x"18",
                                                        x"0c",
                                                        x"20",
                                                        x"00" --the last byte no meaning
                                                        );
    signal trig                         : std_logic;
    signal busy                         : std_logic;
    signal busy_r                       : std_logic;
    signal busy_rr                      : std_logic;
    signal busy_rrr                     : std_logic;
    signal resetn                       : std_logic;
    signal busy_pulse                   : std_logic;
    signal cfg_done_i                   : std_logic;
    signal byte_count                   : std_logic_vector(7 downto 0);
    signal addr                         : std_logic_vector(7 downto 0);
    signal data                         : std_logic_vector(7 downto 0);
    signal rst_count                    : std_logic_vector(11 downto 0);
    signal clkIbuf                      : std_logic;
    signal clkIbufG                     : std_logic;

begin

    clkIbufG <= clk;
    
    CFG_INT_inst : CFG_INT
    Port map( 
        CLK                             => clkIbufG                             ,--: in STD_LOGIC;--100mhz
        RSTn                            => rstn                                 ,--: in STD_LOGIC;
        TRIG                            => trig                                 ,--: in STD_LOGIC;
        ADDR                            => addr                                 ,--: in STD_LOGIC_VECTOR (7 downto 0);
        DATA                            => data                                 ,--: in STD_LOGIC_VECTOR (7 downto 0);
        SCLK                            => sclk                                 ,--: out STD_LOGIC;
        SDATA                           => sdata                                ,--: out STD_LOGIC;
        SEN                             => sen                                  ,--: out STD_LOGIC;
        BUSY                            => busy                                  --: out STD_LOGIC
    );
    
    process(clkIbufG,rstn)
    begin
        if rstn='0' then
            rst_count<=(others=>'0');
        elsif rising_edge(clkIbufG) then
            if rst_count=x"2ff" then
                rst_count<=rst_count;
            else 
                rst_count<=rst_count+1;
            end if;
        end if;
    end process;
    
    adc_rst<=not rst_count(9);
    
    resetn<='1' when rstn='1' and rst_count(9)='1' else '0';
    
    process(clkIbufG,resetn)
    begin
        if resetn='0' then busy_r<='0';
            busy_rr<='0';
            busy_rrr<='0';
        elsif rising_edge(clkIbufG) then
            busy_r<=busy;
            busy_rr<=busy_r;
            busy_rrr<=busy_rr;
        end if;
    end process;
    
    busy_pulse<='1' when busy_r='0' and busy_rr='1' else '0';
    
    process(clkIbufG,resetn)
    begin
        if resetn='0' then  byte_count<=(others=>'0');
            cfg_done_i<='0';
        elsif rising_edge(clkIbufG) then
            cfg_done_i<='0';
            if byte_count=x"10" then
                byte_count<=byte_count;
                cfg_done_i<='1';
            elsif  busy_pulse='1' then 
                byte_count<=byte_count+1;
            else
                byte_count<=byte_count;
            end if;
        end if;
    end process;
    
    cfg_done<=cfg_done_i;
    
    addr<=addr_reg(conv_integer(byte_count));
    data<=data_reg(conv_integer(byte_count));
    
    process(clkIbufG,resetn)
    begin
        if resetn='0' then
            trig<='0';
        elsif rising_edge(clkIbufG) then
            if byte_count/=x"10" and busy_rrr='0' then
                trig<='1';
            else  
                trig<='0';
            end if;
        end if;
    end process;

end Behavioral;
