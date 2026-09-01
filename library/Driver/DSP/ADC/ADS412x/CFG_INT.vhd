----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2016/04/06 13:55:20
-- Design Name: 
-- Module Name: CFG_INT - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CFG_INT is
    Port ( 
        CLK                             : in  STD_LOGIC;--100mhz
        RSTn                            : in  STD_LOGIC;
        TRIG                            : in  STD_LOGIC;
        ADDR                            : in  STD_LOGIC_VECTOR(7 downto 0);
        DATA                            : in  STD_LOGIC_VECTOR(7 downto 0);
        SCLK                            : out STD_LOGIC;
        SDATA                           : out STD_LOGIC;
        SEN                             : out STD_LOGIC;
        BUSY                            : out STD_LOGIC
    );
end CFG_INT;

architecture Behavioral of CFG_INT is

    type state_type                     is (idle,start,wr_addr,wr_data,done);
    signal state                        : state_type;
    signal freq_div                     : std_logic_vector(3 downto 0);
    signal trig_r                       : std_logic;
    signal trig_rr                      : std_logic;
    signal trigger                      : std_logic;
    signal addr_i                       : std_logic_vector(7 downto 0);
    signal addr_r                       : std_logic_vector(7 downto 0);
    signal data_i                       : std_logic_vector(7 downto 0);
    signal data_r                       : std_logic_vector(7 downto 0);
    signal sen_i                        : std_logic;
    signal bit_count                    : std_logic_vector(3 downto 0);
    signal sclk_r                       : std_logic;
    signal sclk_f                       : std_logic;
    signal sclk_flag                    : std_logic;
    signal sclk_i                       : std_logic;
    signal sdata_i                      : std_logic;
    signal busy_i                       : std_logic;

begin

    process(clk,rstn)
    begin
        if rstn='0' then
            trig_r<='0';
            trig_rr<='0';
        elsif rising_edge(clk) then
            trig_r<=trig;
            trig_rr<=trig_r;
        end if;
    end process;
    
    trigger<='1' when trig_r='1' and trig_rr='0' else '0';
    
    process(clk,rstn)
    begin
        if rstn='0' then  addr_i<=(others=>'0');
            data_i<=(others=>'0');
        elsif rising_edge(clk) then
            if trigger='1' then
                addr_i<=addr;
                data_i<=data;
            end if;
        end if;
    end process;
    
    process(clk,rstn)
    begin
        if rstn='0' then state<=idle;
            sen_i<='1';
            busy_i<='0';
            sclk_flag<='0';
        elsif rising_edge(clk) then 
            case state is 
                when idle => 
                    if trigger='1' then
                        state<=start;
                        busy_i<='1';
                    else 
                        state<=idle;
                    end if;
                when start =>
                    state<=wr_addr;
                when wr_addr =>
                    sclk_flag<='1';
                    sen_i<='0';
                    if  bit_count=x"8" then 
                        state<=wr_data;
                    else 
                        state<=wr_addr;
                    end if;
                when wr_data =>
                    if bit_count=x"8" then 
                        state<=done;
                    else 
                        state<=wr_data;
                    end if;
                when done =>
                    if sclk_r='1' then state<=idle;
                       sen_i<='1';
                       sclk_flag<='0';
                       busy_i<='0';
                    else 
                        state<=done;
                    end if;
                when others=> state<=idle;
            end case;
        end if;
    end process;
    
    sen<=sen_i;
    busy<=busy_i;
    
    process(clk,rstn)
    begin
        if rstn='0' then 
            freq_div<=(others=>'0');
        elsif rising_edge(clk) then
            if sclk_flag='1' then
                if freq_div=x"9" then
                    freq_div<=(others=>'0');
                else
                    freq_div<=freq_div+'1';
                end if;
            else
                freq_div<=(others=>'0');
            end if;
        end if;
    end process;
    
    process(clk,rstn)
    begin
        if rstn='0' then
            sclk_r<='0';
            sclk_f<='0';
        elsif rising_edge(clk) then
            sclk_r<='0';
            sclk_f<='0';
            if sclk_flag='1' then
                if freq_div=x"0" then
                    sclk_r<='1';
                elsif freq_div=x"5" then 
                    sclk_f<='1';
                end if;
            end if;
        end if;
    end process;
    
    process(clk,rstn)
    begin 
        if rstn='0' then
            sclk_i<='1';
        elsif rising_edge(clk) then
            if sclk_flag='1' then
                if sclk_r='1' then
                    sclk_i<='1';
                elsif sclk_f='1' then
                    sclk_i<='0';
                else
                    sclk_i<=sclk_i;
                end if;
            else
                sclk_i<='1';
            end if;
        end if;
    end process;
    
    sclk<=sclk_i;
    
    process(clk,rstn)
    begin
        if rstn='0' then
            bit_count<=(others=>'0');
        elsif rising_edge(clk) then
            if bit_count=8 then
                bit_count<=(others=>'0');
            elsif sclk_f='1' then 
                bit_count<=bit_count+1;
            else
                bit_count<=bit_count;
            end if;
        end if;
    end process;
    
    process(clk,rstn)
    begin
        if rstn='0' then  
            addr_r<=(others=>'0');
            data_r<=(others=>'0');
            sdata_i<='0';
        elsif rising_edge(clk) then
            if state=start then 
                addr_r<=addr_i;
                data_r<=data_i;
            elsif state=wr_addr then
                if sclk_r='1' then
                    sdata_i<=addr_r(7);
                    addr_r<=addr_r(6 downto 0) & '0';
                else 
                    sdata_i<=sdata_i;
                    addr_r<=addr_r;
                end if;
            elsif state=wr_data then
                if sclk_r='1' then
                    sdata_i<=data_r(7);
                   data_r<=data_r(6 downto 0) & '0';
                else 
                    sdata_i<=sdata_i;
                    data_r<=data_r;
                end if;
            elsif state=done then 
                sdata_i<=sdata_i;
            else 
                sdata_i<='0';
            end if;
        end if;
    end process;
    
    sdata<=sdata_i;
end Behavioral;
