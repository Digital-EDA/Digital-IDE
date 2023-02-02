---------------------------------------------------------------------
--	Filename:	gh_fifo_async16_sr.vhd
--
--	Description:
--		an Asynchronous FIFO 
--
--	Copyright (c) 2006 by George Huber 
--		an OpenCores.org Project
--		free to use, but see documentation for conditions
--
--	Revision	History:
--	Revision	Date      	Author   	Comment
--	--------	----------	---------	-----------
--	1.0     	12/17/06  	h lefevre	Initial revision
--
--------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
USE ieee.numeric_std.all;

entity fifo is
	GENERIC (data_width: INTEGER :=8 ); -- size of data bus
	port (
		clk_WR : in STD_LOGIC; -- write clock
		clk_RD : in STD_LOGIC; -- read clock
		rst    : in STD_LOGIC; -- resets counters
		srst   : in STD_LOGIC:='0'; -- resets counters (sync with clk_WR)
		WR     : in STD_LOGIC; -- write control 
		RD     : in STD_LOGIC; -- read control
		D      : in STD_LOGIC_VECTOR (data_width-1 downto 0);
		Q      : out STD_LOGIC_VECTOR (data_width-1 downto 0);
		empty  : out STD_LOGIC; 
		full   : out STD_LOGIC);
end entity;

architecture rtl of fifo is

	type ram_mem_type is array (15 downto 0) 
	        of STD_LOGIC_VECTOR (data_width-1 downto 0);
	signal ram_mem : ram_mem_type; 
	signal iempty      : STD_LOGIC;
	signal ifull       : STD_LOGIC;
	signal add_WR_CE   : std_logic;
	signal add_WR      : std_logic_vector(4 downto 0); -- 4 bits are used to address MEM
	signal add_WR_GC   : std_logic_vector(4 downto 0); -- 5 bits are used to compare
	signal n_add_WR    : std_logic_vector(4 downto 0); --   for empty, full flags
	signal add_WR_RS   : std_logic_vector(4 downto 0); -- synced to read clk
	signal add_RD_CE   : std_logic;
	signal add_RD      : std_logic_vector(4 downto 0);
	signal add_RD_GC   : std_logic_vector(4 downto 0);
	signal add_RD_GCwc : std_logic_vector(4 downto 0);
	signal n_add_RD    : std_logic_vector(4 downto 0);
	signal add_RD_WS   : std_logic_vector(4 downto 0); -- synced to write clk
	signal srst_w      : STD_LOGIC;
	signal isrst_w     : STD_LOGIC;
	signal srst_r      : STD_LOGIC;
	signal isrst_r     : STD_LOGIC;

begin

--------------------------------------------
------- memory -----------------------------
--------------------------------------------

process (clk_WR)
begin
	if (rising_edge(clk_WR)) then
		if ((WR = '1') and (ifull = '0')) then
			--ram_mem(to_integer(unsigned(add_WR(3 downto 0)))) <= D;
		end if;
	end if;
end process;

	--Q <= ram_mem(to_integer(unsigned(add_RD(3 downto 0))));

-----------------------------------------
----- Write address counter -------------
-----------------------------------------

	add_WR_CE <= '0' when (ifull = '1') else
	             '0' when (WR = '0') else
	             '1';

	n_add_WR <= std_logic_vector(unsigned(add_WR) + x"1");

process (clk_WR,rst)
begin 
	if (rst = '1') then
		add_WR <= (others => '0');
		add_RD_WS <= "11000"; 
		add_WR_GC <= (others => '0');
	elsif (rising_edge(clk_WR)) then
		add_RD_WS <= add_RD_GCwc;
		if (srst_w = '1') then
			add_WR <= (others => '0');
			add_WR_GC <= (others => '0');
		elsif (add_WR_CE = '1') then
			add_WR <= n_add_WR;
			add_WR_GC(0) <= n_add_WR(0) xor n_add_WR(1);
			add_WR_GC(1) <= n_add_WR(1) xor n_add_WR(2);
			add_WR_GC(2) <= n_add_WR(2) xor n_add_WR(3);
			add_WR_GC(3) <= n_add_WR(3) xor n_add_WR(4);
			add_WR_GC(4) <= n_add_WR(4);
		else
			add_WR <= add_WR;
			add_WR_GC <= add_WR_GC;
		end if;
	end if;
end process;

	full <= ifull;

	ifull <= '0' when (iempty = '1') else -- just in case add_RD_WS is reset to "00000"
	         '0' when (add_RD_WS /= add_WR_GC) else ---- instend of "11000"
	         '1';

-----------------------------------------
----- Read address counter --------------
-----------------------------------------

	add_RD_CE <= '0' when (iempty = '1') else
	             '0' when (RD = '0') else
	             '1';

	n_add_RD <= std_logic_vector(unsigned(add_RD) + x"1");

process (clk_RD,rst)
begin 
	if (rst = '1') then
		add_RD <= (others => '0');
		add_WR_RS <= (others => '0');
		add_RD_GC <= (others => '0');
		add_RD_GCwc <= "11000";
	elsif (rising_edge(clk_RD)) then
		add_WR_RS <= add_WR_GC;
		if (srst_r = '1') then
			add_RD <= (others => '0');
			add_RD_GC <= (others => '0');
			add_RD_GCwc <= "11000";
		elsif (add_RD_CE = '1') then
			add_RD <= n_add_RD;
			add_RD_GC(0) <= n_add_RD(0) xor n_add_RD(1);
			add_RD_GC(1) <= n_add_RD(1) xor n_add_RD(2);
			add_RD_GC(2) <= n_add_RD(2) xor n_add_RD(3);
			add_RD_GC(3) <= n_add_RD(3) xor n_add_RD(4);
			add_RD_GC(4) <= n_add_RD(4);
			add_RD_GCwc(0) <= n_add_RD(0) xor n_add_RD(1);
			add_RD_GCwc(1) <= n_add_RD(1) xor n_add_RD(2);
			add_RD_GCwc(2) <= n_add_RD(2) xor n_add_RD(3);
			add_RD_GCwc(3) <= n_add_RD(3) xor (not n_add_RD(4));
			add_RD_GCwc(4) <= (not n_add_RD(4));
		else
			add_RD <= add_RD; 
			add_RD_GC <= add_RD_GC;
			add_RD_GCwc <= add_RD_GCwc;
		end if;
	end if;
end process;

	empty <= iempty;
 
	iempty <= '1' when (add_WR_RS = add_RD_GC) else
	          '0';
 
----------------------------------
---	sync rest stuff --------------
--- srst is sync with clk_WR -----
--- srst_r is sync with clk_RD ---
----------------------------------

process (clk_WR,rst)
begin 
	if (rst = '1') then
		srst_w <= '0';
		isrst_r <= '0';
	elsif (rising_edge(clk_WR)) then
		isrst_r <= srst_r;
		if (srst = '1') then
			srst_w <= '1';
		elsif (isrst_r = '1') then
			srst_w <= '0';
		end if;
	end if;
end process;

process (clk_RD,rst)
begin 
	if (rst = '1') then
		srst_r <= '0';	
		isrst_w <= '0';	
	elsif (rising_edge(clk_RD)) then
		isrst_w <= srst_w;
		if (isrst_w = '1') then
			srst_r <= '1';
		else
			srst_r <= '0';
		end if;
	end if;
end process;

end architecture;
