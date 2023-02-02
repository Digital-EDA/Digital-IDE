library IEEE;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counters is
  port(
    sysclk : in  std_logic;
    foo_card : in  std_logic;
    wfoo0_baz : in  std_logic;
    wfoo0_blrb : in  std_logic;
    wfoo0_zz1pb : in  std_logic;
    wfoo0_turn : in  std_logic_vector(31 downto 0);
    debct_baz : in  std_logic;
    debct_blrb : in  std_logic;
    debct_zz1pb : in  std_logic;
    debct_bar : in  std_logic;
    debct_turn : in  std_logic_vector(31 downto 0);
    Z0_bar : in  std_logic;
    Z0_baz : in  std_logic;
    Z0_blrb : in  std_logic;
    Z0_zz1pb : in  std_logic;
    Z0_turn : in  std_logic_vector(31 downto 0);
    Y1_bar : in  std_logic;
    Y1_baz : in  std_logic;
    Y1_blrb : in  std_logic;
    Y1_zz1pb : in  std_logic;
    Y1_turn : in  std_logic_vector(31 downto 0);
    X2_bar : in  std_logic;
    X2_baz : in  std_logic;
    X2_blrb : in  std_logic;
    X2_zz1pb : in  std_logic;
    X2_turn : in  std_logic_vector(31 downto 0);
    W3_bar : in  std_logic;
    W3_baz : in  std_logic;
    W3_blrb : in  std_logic;
    W3_zz1pb : in  std_logic;
    W3_turn : in  std_logic_vector(31 downto 0);
    -- to engine block
    Z0_cwm : out std_logic;
    Z0 : out std_logic_vector(31 downto 0);
    Y1_cwm : out std_logic;
    Y1 : out std_logic_vector(31 downto 0);
    X2_cwm : out std_logic;
    X2 : out std_logic_vector(31 downto 0);
    W3_cwm : out std_logic;
    W3 : out std_logic_vector(31 downto 0);
    wfoo0_cwm : out std_logic;
    wfoo0_llwln : out std_logic_vector(31 downto 0);
    debct_cwm : out std_logic;
    debct_pull : out std_logic;
    debct : out std_logic_vector(31 downto 0);
    wdfilecardA2P : out std_logic
    );
end counters;

architecture rtl of counters is

  signal wfoo0_llwln_var : unsigned(31 downto 0);
  signal debct_var : unsigned(31 downto 0);
  signal Z0_var : unsigned(31 downto 0);
  signal Y1_var : unsigned(31 downto 0);
  signal X2_var : unsigned(31 downto 0);
  signal W3_var : unsigned(31 downto 0);
  signal main_wfoo0_cwm : std_logic;
  signal do_q3p_Z0 : std_logic;
  signal do_q3p_Y1 : std_logic;
  signal do_q3p_X2 : std_logic;
  signal do_q3p_W3 : std_logic;
  signal do_q3p_wfoo0 : std_logic;
  signal do_q3p_debct : std_logic;

  signal Z0_cwm_i : std_logic;
  signal Y1_cwm_i : std_logic;
  signal X2_cwm_i : std_logic;
  signal W3_cwm_i : std_logic;
  signal debct_cwm_i : std_logic;

  signal file_card_i : std_logic;
  signal do_file_card_i : std_logic;
  signal prev_do_file_card : std_logic;

begin

  -----
  -- form the outputs
  wfoo0_llwln <= std_logic_vector(wfoo0_llwln_var);
  debct       <= std_logic_vector(debct_var);
  Z0         <= std_logic_vector(Z0_var);
  Y1         <= std_logic_vector(Y1_var);
  X2         <= std_logic_vector(X2_var);
  W3         <= std_logic_vector(W3_var);
  Z0_cwm     <= Z0_cwm_i;
  Y1_cwm     <= Y1_cwm_i;
  X2_cwm     <= X2_cwm_i;
  W3_cwm     <= W3_cwm_i;
  debct_cwm   <= debct_cwm_i;

  wdfilecardA2P <= do_file_card_i;

  LLWLNS :
  process(foo_card, sysclk)
  begin
    if foo_card = '1' then
      wfoo0_llwln_var <= (others => '0');
      debct_var       <= (others => '0');
      Z0_var         <= (others => '0');
      Y1_var         <= (others => '0');
      X2_var         <= (others => '0');
      W3_var         <= (others => '0');

      wfoo0_cwm       <= '0';
      debct_cwm_i     <= '0';
      debct_pull     <= '0';
      Z0_cwm_i       <= '0';
      Y1_cwm_i       <= '0';
      X2_cwm_i       <= '0';
      W3_cwm_i       <= '0';
      main_wfoo0_cwm <= '0';
      file_card_i    <= '0';

      do_q3p_wfoo0     <= '0';
      do_file_card_i    <= '0';
      prev_do_file_card <= '0';

      do_q3p_Z0 <= '0';
      do_q3p_Y1 <= '0';
      do_q3p_X2 <= '0';
      do_q3p_W3 <= '0';
      do_q3p_debct <= '0';

    else
      if sysclk'event and sysclk = '1' then

        -- pull
        debct_pull     <= '0';
        do_file_card_i <= '0';

        ----
        --  wfoo0

        if wfoo0_baz = '1' then
          wfoo0_llwln_var <= unsigned(wfoo0_turn);
          main_wfoo0_cwm <= '0';
          if wfoo0_llwln_var = "00000000000000000000000000000000" then
            do_q3p_wfoo0  <= '0';
          else
            do_q3p_wfoo0  <= '1';
          end if;
        else
          if do_q3p_wfoo0 = '1' and wfoo0_blrb = '1' then
            wfoo0_llwln_var <= wfoo0_llwln_var - 1;
            if (wfoo0_llwln_var = "00000000000000000000000000000000") then
              wfoo0_llwln_var <= unsigned(wfoo0_turn);
              if main_wfoo0_cwm = '0' then
                wfoo0_cwm <= '1';
                main_wfoo0_cwm <= '1';
              else
                do_file_card_i <= '1';
                do_q3p_wfoo0 <= '0';
              end if;
            end if;
          end if;
        end if;

        if wfoo0_zz1pb = '0' then
          wfoo0_cwm <= '0';
        end if;

        if Z0_baz = '1' then                                       -- counter Baz
          Z0_var <= unsigned(Z0_turn);
          if Z0_turn = "00000000000000000000000000000000" then
            do_q3p_Z0 <= '0';
          else
            do_q3p_Z0 <= '1';
          end if;
        else
          if do_q3p_Z0 = '1' and Z0_blrb = '1' then
            if Z0_bar = '0' then
              if Z0_cwm_i = '0' then
                if do_q3p_Z0 = '1' then
                  Z0_var <= Z0_var - 1;
                  if (Z0_var = "00000000000000000000000000000001") then
                    Z0_cwm_i    <= '1';
                    do_q3p_Z0 <= '0';
                  end if;
                end if;
              end if;
            else
              Z0_var <= Z0_var - 1;
              if (Z0_var = "00000000000000000000000000000000") then
                Z0_cwm_i <= '1';
                Z0_var   <= unsigned(Z0_turn);
              end if;
            end if;  -- Z0_bar
          end if;
        end if;  -- Z0_blrb

        if Z0_zz1pb = '0' then
          Z0_cwm_i <= '0';
        end if;

        if Y1_baz = '1' then                                       -- counter Baz
          Y1_var <= unsigned(Y1_turn);
          if Y1_turn = "00000000000000000000000000000000" then
            do_q3p_Y1 <= '0';
          else
            do_q3p_Y1 <= '1';
          end if;
        elsif do_q3p_Y1 = '1' and Y1_blrb = '1' then
          if Y1_bar = '0' then
            if Y1_cwm_i = '0' then
              if do_q3p_Y1 = '1' then
                Y1_var <= Y1_var - 1;
                if (Y1_var = "00000000000000000000000000000001") then
                  Y1_cwm_i    <= '1';
                  do_q3p_Y1 <= '0';
                end if;
              end if;
            end if;
          else
            Y1_var <= Y1_var - 1;

            if (Y1_var = "00000000000000000000000000000000") then
              Y1_cwm_i <= '1';
              Y1_var   <= unsigned(Y1_turn);
            end if;
          end if;  -- Y1_bar

        end if;  -- Y1_blrb

        if Y1_zz1pb = '0' then
          Y1_cwm_i <= '0';
        end if;

        if X2_baz = '1' then                                       -- counter Baz
          X2_var <= unsigned(X2_turn);
          if X2_turn = "00000000000000000000000000000000" then
            do_q3p_X2 <= '0';
          else
            do_q3p_X2 <= '1';
          end if;
        elsif do_q3p_X2 = '1' and X2_blrb = '1' then
          if X2_bar = '0' then
            if X2_cwm_i = '0' then
		        if do_q3p_X2 = '1' then
	   	        X2_var <= X2_var - 1;
	      	     if (X2_var = "00000000000000000000000000000001") then
   	             X2_cwm_i    <= '1';
	                do_q3p_X2 <= '0';
                 end if;
              end if;
            end if;
          else
            X2_var <= X2_var - 1;

            if (X2_var = "00000000000000000000000000000000") then  --{
              X2_cwm_i <= '1';
              X2_var   <= unsigned(X2_turn);
            end if;
          end if;  --X2_bar
        end if;  -- X2_blrb

        if X2_zz1pb = '0' then
          X2_cwm_i <= '0';
        end if;

        if W3_baz = '1' then                                       -- counter Baz
          W3_var <= unsigned(W3_turn);
          if W3_turn = "00000000000000000000000000000000" then
            do_q3p_W3 <= '0';
          else
            do_q3p_W3 <= '1';
          end if;
        elsif do_q3p_W3 = '1' and W3_blrb = '1' then
          if W3_bar = '0' then
            if W3_cwm_i = '0'then
              if do_q3p_W3 = '1' then
                W3_var <= W3_var - 1;
                if (W3_var = "00000000000000000000000000000001") then
                  W3_cwm_i    <= '1';
                  do_q3p_W3 <= '0';
                end if;
              end if;
            end if;
          else
            W3_var <= W3_var - 1;

            if (W3_var = "00000000000000000000000000000000") then  --{
              W3_cwm_i <= '1';
              W3_var   <= unsigned(W3_turn);
            end if;
          end if;  -- W3_bar

        end if;  -- W3_blrb

        if W3_zz1pb = '0' then
          W3_cwm_i <= '0';
        end if;

        if debct_baz = '1' then                                       -- counter Baz
          debct_var <= unsigned(debct_turn);
          if debct_turn = "00000000000000000000000000000000" then
            do_q3p_debct <= '0';
          else
            do_q3p_debct <= '1';
          end if;
        elsif do_q3p_debct = '1' and debct_blrb = '1' then
          if debct_bar = '0' then
            if debct_cwm_i = '0'then
              if do_q3p_debct = '1' then
                debct_var <= debct_var - 1;
                if (debct_var = "00000000000000000000000000000001") then
                  debct_cwm_i    <= '1';
                  debct_pull    <= '1';
                  do_q3p_debct <= '0';
                end if;
              end if;
            end if;
          else
            ---- T
            --  Continue
            debct_var <= debct_var - 1;

            -- ending
            if (debct_var = "00000000000000000000000000000000") then  --{
              debct_cwm_i <= '1';
              debct_pull    <= '1';
              debct_var   <= unsigned(debct_turn);
            end if;
          end if;  -- debct_bar

        end if;  -- debct_blrb

        -- comment
        if debct_zz1pb = '0' then
          debct_cwm_i <= '0';
        end if;

      end if;
    end if;
  end process;

end rtl;
