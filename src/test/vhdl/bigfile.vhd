library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- CONNECTIVITY DEFINITION
entity bigfile is
  port (
    -- from external pins
    sysclk : in  std_logic;
    g_zaq_in : in  std_logic_vector(31 downto 0);
    g_aux : in  std_logic_vector(31 downto 0);
    scanb : in  std_logic;
    g_wrb : in  std_logic;
    g_rdb : in  std_logic;
    g_noop_clr : in  std_logic_vector(31 downto 0);
    swe_ed : in  std_logic;
    swe_lv : in  std_logic;
    din : in  std_logic_vector(63 downto 0);
    g_dout_w0x0f : in  std_logic_vector(4 downto 0);
    n9_bit_write : in  std_logic;
    -- from reset_gen block
    reset : in  std_logic;
    alu_u : in  std_logic_vector(31 downto 0);
    debct_ping : in  std_logic;
    g_sys_in : out std_logic_vector(31 downto 0);
    g_zaq_in_rst_hold : out std_logic_vector(31 downto 0);
    g_zaq_hhh_enb : out std_logic_vector(31 downto 0);
    g_zaq_out : out std_logic_vector(31 downto 0);
    g_dout : out std_logic_vector(31 downto 0);
    g_zaq_ctl : out std_logic_vector(31 downto 0);
    g_zaq_qaz_hb : out std_logic_vector(31 downto 0);
    g_zaq_qaz_lb : out std_logic_vector(31 downto 0);
    gwerth : out std_logic_vector(31 downto 0);
    g_noop : out std_logic_vector(31 downto 0);
    g_vector : out std_logic_vector(8*32-1 downto 0);
    swe_qaz1 : out std_logic_vector(31 downto 0)
    );
end bigfile;


-- IMPLEMENTATION
architecture rtl of bigfile is

  -- constants 
  constant g_t_klim_w0x0f : std_logic_vector(4 downto 0) := "00000";
  constant g_t_u_w0x0f : std_logic_vector(4 downto 0) := "00001";
  constant g_t_l_w0x0f : std_logic_vector(4 downto 0) := "00010";  
  constant g_t_hhh_l_w0x0f : std_logic_vector(4 downto 0) := "00011";
  constant g_t_jkl_sink_l_w0x0f : std_logic_vector(4 downto 0) := "00100";  
  constant g_secondary_t_l_w0x0f : std_logic_vector(4 downto 0) := "00101";
  constant g_style_c_l_w0x0f : std_logic_vector(4 downto 0) := "00110";
  constant g_e_z_w0x0f : std_logic_vector(4 downto 0) := "00111";
  constant g_n_both_qbars_l_w0x0f : std_logic_vector(4 downto 0) := "01000";
  constant g_style_vfr_w0x0f : std_logic_vector(4 downto 0) := "01001";
  constant g_style_klim_w0x0f : std_logic_vector(4 downto 0) := "01010";
  constant g_unklimed_style_vfr_w0x0f : std_logic_vector(4 downto 0) := "01011";
  constant g_style_t_y_w0x0f : std_logic_vector(4 downto 0) := "01100";
  constant g_n_l_w0x0f : std_logic_vector(4 downto 0) := "01101";
  constant g_n_vfr_w0x0f : std_logic_vector(4 downto 0) := "01110";
  constant g_e_n_r_w0x0f : std_logic_vector(4 downto 0) := "01111";
  constant g_n_r_bne_w0x0f : std_logic_vector(4 downto 0) := "10000";
  constant g_n_div_rebeq_w0x0f : std_logic_vector(4 downto 0) := "10001";
  constant g_alu_l_w0x0f : std_logic_vector(4 downto 0) := "10010";
  constant g_t_qaz_mult_low_w0x0f : std_logic_vector(4 downto 0) := "10011";
  constant g_t_qaz_mult_high_w0x0f : std_logic_vector(4 downto 0) := "10100";
  constant gwerthernal_style_u_w0x0f : std_logic_vector(4 downto 0) := "10101";
  constant gwerthernal_style_l_w0x0f : std_logic_vector(4 downto 0) := "10110";
  constant g_style_main_reset_hold_w0x0f : std_logic_vector(4 downto 0) := "10111";

                                                                               -- comment
  signal g_t_klim_dout : std_logic_vector(31 downto 0);
  signal g_t_u_dout : std_logic_vector(31 downto 0);
  signal g_t_l_dout : std_logic_vector(31 downto 0);
  signal g_t_hhh_l_dout : std_logic_vector(31 downto 0);
  signal g_t_jkl_sink_l_dout : std_logic_vector(31 downto 0);
  signal g_secondary_t_l_dout : std_logic_vector(31 downto 0);
  signal g_style_c_l_dout : std_logic_vector(3 downto 0);  -- not used
  signal g_e_z_dout : std_logic_vector(31 downto 0);
  signal g_n_both_qbars_l_dout : std_logic_vector(31 downto 0);
  signal g_style_vfr_dout : std_logic_vector(31 downto 0);
  signal g_style_klim_dout : std_logic_vector(31 downto 0);
  signal g_unklimed_style_vfr_dout : std_logic_vector(31 downto 0);
  signal g_style_t_y_dout : std_logic_vector(31 downto 0);
  signal g_n_l_dout : std_logic_vector(31 downto 0);
  signal g_n_vfr_dout : std_logic_vector(31 downto 0);
  signal g_e_n_r_dout : std_logic_vector(31 downto 0);
  signal g_n_r_bne_dout : std_logic;
  signal g_n_div_rebeq_dout : std_logic_vector(31 downto 0);
  signal g_alu_l_dout : std_logic_vector(31 downto 0);
  signal g_t_qaz_mult_low_dout : std_logic_vector(31 downto 0);
  signal g_t_qaz_mult_high_dout : std_logic_vector(31 downto 0);
  signal gwerthernal_style_u_dout : std_logic_vector(31 downto 0);
  signal gwerthernal_style_l_dout : std_logic_vector(31 downto 0);
  signal g_style_main_reset_hold_dout : std_logic_vector(31 downto 0);
  
  -- other
  signal q_g_zaq_in : std_logic_vector(31 downto 0);
  signal q2_g_zaq_in : std_logic_vector(31 downto 0);
  signal q3_g_zaq_in : std_logic_vector(31 downto 0);
  signal q_g_zaq_in_cd : std_logic_vector(3 downto 0);
  signal q_g_style_vfr_dout : std_logic_vector(31 downto 0);
  signal q_g_unzq : std_logic_vector(3 downto 0);
  signal g_n_active : std_logic_vector(31 downto 0);

  -- inter
  signal g_zaq_in_y : std_logic_vector(31 downto 0);
  signal g_zaq_in_y_no_dout : std_logic_vector(31 downto 0);
  signal g_zaq_out_i : std_logic_vector(31 downto 0);
  signal g_zaq_ctl_i : std_logic_vector(31 downto 0);
  signal g_sys_in_i : std_logic_vector(31 downto 0);
  signal g_sys_in_ii : std_logic_vector(31 downto 0);
  signal g_dout_i : std_logic_vector(31 downto 0);

begin

  -- qaz out
  g_zaq_out_i <=
    -- if secondary
    (g_secondary_t_l_dout and (g_aux xor g_style_t_y_dout)) or
    -- if alu
    (g_alu_l_dout and alu_u and not g_secondary_t_l_dout) or
    -- otherwise
    (not g_alu_l_dout and not g_secondary_t_l_dout and g_t_u_dout);
  -- Changed
  g_zaq_out <= g_zaq_out_i and not g_t_jkl_sink_l_dout;
  
  -- qaz 
  -- JLB
  g_zaq_ctl_i <= not((g_t_l_dout and not g_t_jkl_sink_l_dout) or
                    (g_t_l_dout and g_t_jkl_sink_l_dout and not g_zaq_out_i));
  -- mux
  --vnavigatoroff
  g_zaq_ctl <= g_zaq_ctl_i when scanb = '1' else "00000000000000000000000000000000";
  --vnavigatoron
  
  g_zaq_hhh_enb <= not(g_t_hhh_l_dout);

  g_zaq_qaz_hb <= g_t_qaz_mult_high_dout;
  g_zaq_qaz_lb <= g_t_qaz_mult_low_dout;


  -- Dout
  g_dout_i <= g_t_klim_dout and g_style_klim_dout when g_dout_w0x0f = g_t_klim_w0x0f else
                 g_t_u_dout and g_style_klim_dout                                             when g_dout_w0x0f = g_t_u_w0x0f                else
                 g_t_l_dout and g_style_klim_dout                                            when g_dout_w0x0f = g_t_l_w0x0f               else
                 g_t_hhh_l_dout and g_style_klim_dout                                    when g_dout_w0x0f = g_t_hhh_l_w0x0f       else
                 g_t_jkl_sink_l_dout and g_style_klim_dout                                 when g_dout_w0x0f = g_t_jkl_sink_l_w0x0f    else
                 g_secondary_t_l_dout and g_style_klim_dout                                  when g_dout_w0x0f = g_secondary_t_l_w0x0f     else
                 ("0000000000000000000000000000" & g_style_c_l_dout) and g_style_klim_dout when g_dout_w0x0f = g_style_c_l_w0x0f       else
                 g_e_z_dout                                                                 when g_dout_w0x0f = g_e_z_w0x0f            else
                 g_n_both_qbars_l_dout                                                      when g_dout_w0x0f = g_n_both_qbars_l_w0x0f else
                 g_style_vfr_dout and g_style_klim_dout                                             when g_dout_w0x0f = g_style_vfr_w0x0f                else
                 g_style_klim_dout                                                                       when g_dout_w0x0f = g_style_klim_w0x0f                  else
                 g_unklimed_style_vfr_dout                                                            when g_dout_w0x0f = g_unklimed_style_vfr_w0x0f       else
                 g_style_t_y_dout and g_style_klim_dout                                    when g_dout_w0x0f = g_style_t_y_w0x0f       else
                 g_n_l_dout                                                                 when g_dout_w0x0f = g_n_l_w0x0f            else
                 g_n_vfr_dout                                                                 when g_dout_w0x0f = g_n_vfr_w0x0f            else
                 g_e_n_r_dout                                                            when g_dout_w0x0f = g_e_n_r_w0x0f       else
                 ("0000000000000000000000000000000" & g_n_r_bne_dout)                      when g_dout_w0x0f = g_n_r_bne_w0x0f       else
                 g_n_div_rebeq_dout                                                         when g_dout_w0x0f = g_n_div_rebeq_w0x0f    else
                 g_alu_l_dout and g_style_klim_dout                                             when g_dout_w0x0f = g_alu_l_w0x0f                else
                 g_t_qaz_mult_low_dout and g_style_klim_dout                                  when g_dout_w0x0f = g_t_qaz_mult_low_w0x0f     else
                 g_t_qaz_mult_high_dout and g_style_klim_dout                                 when g_dout_w0x0f = g_t_qaz_mult_high_w0x0f    else
                 gwerthernal_style_u_dout and g_style_klim_dout                                     when g_dout_w0x0f = gwerthernal_style_u_w0x0f        else
                 g_style_main_reset_hold_dout and g_style_klim_dout                                    when g_dout_w0x0f = g_style_main_reset_hold_w0x0f       else
                 gwerthernal_style_l_dout and g_style_klim_dout                                    when g_dout_w0x0f = gwerthernal_style_l_w0x0f       else
                 "00000000000000000000000000000000";
  g_dout <= g_dout_i when g_rdb = '0' else (others => '1');


  -- this  can be used to use zzz1
  g_style_main_reset_hold_dout_proc :
  process(sysclk)
  begin
    if( sysclk'event and sysclk = '1' ) then
      if( scanb = '1' ) then
        if( reset = '1' ) then
          g_style_main_reset_hold_dout <= g_zaq_in;
        end if;
      --vnavigatoroff
      else 
        g_style_main_reset_hold_dout <= q2_g_zaq_in;
      end if;
      --vnavigatoron
    end if;
  end process;
  -- qaz
  g_zaq_in_rst_hold <= g_style_main_reset_hold_dout;

  -- Din 
  g_doutister_proc :
  process(reset, sysclk)
    variable g_dout_w0x0f_v : std_logic_vector(4 downto 0);
    variable i : integer;
    variable j : integer;
  begin
    if( reset /= '0' ) then
      g_t_klim_dout                  <= (others => '0');
      g_t_u_dout                 <= (others => '0');
      g_t_l_dout                <= (others => '0');
      g_t_hhh_l_dout        <= (others => '0');
      g_t_jkl_sink_l_dout     <= (others => '0');
      g_secondary_t_l_dout      <= (others => '0');
      g_style_c_l_dout        <= (others => '0');
      g_e_z_dout             <= (others => '0');
      g_n_both_qbars_l_dout  <= (others => '0');
      g_style_klim_dout                   <= (others => '0');
      g_style_t_y_dout        <= (others => '0');
      g_n_l_dout             <= (others => '0');
      g_e_n_r_dout        <= (others => '0');
      g_n_r_bne_dout        <= '0';
      g_n_div_rebeq_dout     <= (others => '1');
      g_alu_l_dout                 <= (others => '0');
      g_t_qaz_mult_low_dout      <= (others => '1');  -- NOTE Low
      g_t_qaz_mult_high_dout     <= (others => '0');
      gwerthernal_style_u_dout         <= (others => '0');      
      gwerthernal_style_l_dout        <= (others => '0');
    elsif( sysclk'event and sysclk = '1' ) then
      -- clear
      g_n_div_rebeq_dout <= g_n_div_rebeq_dout and not g_noop_clr;
      if( g_wrb = '0' ) then
        -- because we now...
        for i in 0 to 1 loop
          if( i = 0 ) then
            g_dout_w0x0f_v := g_dout_w0x0f;
          elsif( i = 1 ) then
            if( n9_bit_write = '1' ) then
              -- set
              g_dout_w0x0f_v := g_dout_w0x0f(4 downto 1) & '1';
            end if;
          --vnavigatoroff
          else
            -- not possible but added for code coverage's sake
          end if;
          --vnavigatoron
          case g_dout_w0x0f_v is
            when g_t_klim_w0x0f  => g_t_klim_dout <= din(i*32+31 downto i*32);
            when g_t_u_w0x0f =>
              -- output klim
              for j in 0 to 31 loop
                if( (g_t_klim_dout(j) = '0' and n9_bit_write = '0') or ( din(j) = '0' and n9_bit_write = '1')) then
                  g_t_u_dout(j) <= din(32*i+j);
                end if;
              end loop;
            when g_t_l_w0x0f               => g_t_l_dout                     <= din(i*32+31 downto i*32);
            when g_t_hhh_l_w0x0f       => g_t_hhh_l_dout             <= din(i*32+31 downto i*32);
            when g_t_jkl_sink_l_w0x0f    => g_t_jkl_sink_l_dout          <= din(i*32+31 downto i*32);
            when g_secondary_t_l_w0x0f     => g_secondary_t_l_dout           <= din(i*32+31 downto i*32);
            when g_style_c_l_w0x0f       => g_style_c_l_dout(3 downto 0) <= din(3+i*32 downto i*32);
            when g_e_z_w0x0f            => g_e_z_dout                  <= din(i*32+31 downto i*32);
            when g_n_both_qbars_l_w0x0f => g_n_both_qbars_l_dout       <= din(i*32+31 downto i*32);
            when g_style_vfr_w0x0f                => null;  -- read-only register
            when g_style_klim_w0x0f                  => g_style_klim_dout                        <= din(i*32+31 downto i*32);
            when g_unklimed_style_vfr_w0x0f       => null;  -- read-only register
            when g_style_t_y_w0x0f       => g_style_t_y_dout             <= din(i*32+31 downto i*32);
            when g_n_l_w0x0f            => g_n_l_dout                  <= din(i*32+31 downto i*32);
            when g_n_vfr_w0x0f            => null;  -- writes
            when g_e_n_r_w0x0f       => g_e_n_r_dout             <= din(i*32+31 downto i*32);
            when g_n_r_bne_w0x0f       => g_n_r_bne_dout             <= din(i*32);
            when g_n_div_rebeq_w0x0f    => g_n_div_rebeq_dout          <= din(i*32+31 downto i*32) or
                                                                                                        g_n_div_rebeq_dout;  -- a '1' writes
            when g_alu_l_w0x0f                => g_alu_l_dout                      <= din(i*32+31 downto i*32);
            when g_t_qaz_mult_low_w0x0f     => g_t_qaz_mult_low_dout           <= din(i*32+31 downto i*32);
            when g_t_qaz_mult_high_w0x0f    => g_t_qaz_mult_high_dout          <= din(i*32+31 downto i*32);
            when gwerthernal_style_u_w0x0f        => gwerthernal_style_u_dout              <= din(i*32+31 downto i*32);
            when gwerthernal_style_l_w0x0f       => gwerthernal_style_l_dout             <= din(i*32+31 downto i*32);
            --vnavigatoroff                                                          
            when others                                => null;
            --vnavigatoron                                                        
          end case;
        end loop;

      end if;
    end if;
  end process;

  -- sample
  g_zaq_in_sample_proc :
  process(reset, sysclk)
  begin
    if( reset /= '0' ) then
      q_g_zaq_in  <= (others => '0');
      q2_g_zaq_in <= (others => '0');
      q3_g_zaq_in <= (others => '0');
    elsif( sysclk'event and sysclk = '1' ) then
      q_g_zaq_in  <= g_zaq_in;
      q2_g_zaq_in <= q_g_zaq_in;
      q3_g_zaq_in <= g_zaq_in_y;
    end if;
  end process;

  --  vfr register
  g_unklimed_style_vfr_dout <= q2_g_zaq_in;

  -- switch
  g_zaq_in_y <= g_style_t_y_dout xor q2_g_zaq_in;

  -- qaz
  g_style_vfr_dout <=              -- top 2
                           (g_zaq_in_y(31 downto 4) &
                            --  FSM
                            (( g_style_c_l_dout(3 downto 0) and q_g_zaq_in_cd) or
                             -- otherwise just use
                             (not g_style_c_l_dout(3 downto 0) and g_zaq_in_y(3 downto 0))));
  
  -- in scan mode
  g_zaq_in_y_no_dout <= (g_style_t_y_dout xor g_zaq_in) when scanb = '1' 
  --vnavigatoroff
                                 else g_style_t_y_dout;
  --vnavigatoron

  g_sys_in_i                 <= (-- top 28
                                 (g_zaq_in_y_no_dout(31 downto 4) &
                                  --  is enabled
                                  (( g_style_c_l_dout(3 downto 0) and q_g_zaq_in_cd) or
                                   -- otherwise just use
                                   (not g_style_c_l_dout(3 downto 0) and g_zaq_in_y_no_dout(3 downto 0)))));

  g_sys_in_ii <= (g_sys_in_i and not gwerthernal_style_l_dout) or (gwerthernal_style_u_dout and gwerthernal_style_l_dout );

  g_sys_in <= g_sys_in_ii;
 
  lpq_proc :
  process(reset, sysclk)
    variable i : integer;
  begin
    if( reset /= '0' ) then
      q_g_zaq_in_cd      <= (others => '0');
      q_g_unzq          <= (others => '1');
    elsif( sysclk'event and sysclk = '1' ) then
      --  sample
      if( debct_ping = '1') then
        --  taken
        for i in 0 to 3 loop
          if( g_zaq_in_y(i) /= q3_g_zaq_in(i) ) then
            q_g_unzq(i) <= '1';
          else
            if( q_g_unzq(i) = '0' ) then
              q_g_zaq_in_cd(i) <= g_zaq_in_y(i);
            else
              q_g_unzq(i) <= '0';
            end if;
          end if;
        end loop;
      else
        for i in 0 to 3 loop
          if( g_zaq_in_y(i) /= q3_g_zaq_in(i) ) then
            q_g_unzq(i) <= '1';
          end if;
        end loop;
      end if;
    end if;
  end process;

  -- generate lqqs 
  sample_forwerth_proc :
  process(reset, sysclk)
  begin
    if( reset /= '0' ) then
      q_g_style_vfr_dout <= (others => '0');
    elsif( sysclk'event and sysclk = '1' ) then
      if( scanb = '1' ) then
        q_g_style_vfr_dout <= g_style_vfr_dout;
      --vnavigatoroff
      else
        -- in scan 
        q_g_style_vfr_dout <= g_style_vfr_dout or (g_zaq_out_i(31 downto 17) & "0" & g_zaq_out_i(15 downto 1) & "0") or g_zaq_ctl_i or g_sys_in_ii;
      end if;
      --vnavigatoron
    end if;
  end process;

  -- generate
  g_n_active <=  -- 1 to 0
                            (((q_g_style_vfr_dout and not g_style_vfr_dout) or
                             --  get this
                             (not q_g_style_vfr_dout and g_style_vfr_dout and
                              g_n_both_qbars_l_dout))) and
                            -- must be 
                             g_n_l_dout;
  
  -- check for lqq active and set lqq vfr register
  -- also clear
  n_proc :
  process(reset, sysclk)
    variable i : integer;
  begin
    if( reset /= '0' ) then
      g_n_vfr_dout <= (others => '0');
      gwerth                  <= (others => '0');
    elsif( sysclk'event and sysclk = '1' ) then
      for i in 0 to 31 loop
        --  lqq
        --  vfr  matches
        if( g_n_active(i) = '1' ) then
          gwerth(i) <= '1';
          if( g_e_z_dout(i) = '1' ) then
            --  lqq          
            g_n_vfr_dout(i) <= '1';
          else
            g_n_vfr_dout(i) <= q_g_style_vfr_dout(i);
          end if;
        else
          --  clear
          if( g_e_z_dout(i) = '0' ) then
	         g_n_vfr_dout(i) <= q_g_style_vfr_dout(i);  -- default always assign
            -- in both
            if( g_n_both_qbars_l_dout(i) = '1' or g_style_vfr_dout(i) = '1') then
              gwerth(i) <= '0';
            end if;
          else            
            -- write
            if( g_wrb = '0' and g_dout_w0x0f = g_n_vfr_w0x0f and din(i) = '1' ) then
              gwerth(i) <= '0';
              g_n_vfr_dout(i) <= '0';
            end if;
          end if;
        end if;
      end loop;
    end if;
  end process;

  ----
  -- Create the Lqq
  createwerth_vec_proc :
  process( g_n_r_bne_dout, g_e_n_r_dout)
    variable imod8, idiv8 : integer;
    variable i : integer;
  begin
    for i in 0 to 31 loop
      imod8 := i mod 8;
      idiv8 := i / 8;

      if( g_n_r_bne_dout = '0' ) then
        -- non-unique
        g_vector(8*i+7 downto 8*i) <= g_e_n_r_dout(8*idiv8+7 downto 8*idiv8);
      else
        -- unique
        if( imod8 = 0 ) then
          g_vector(8*i+7 downto 8*i) <= g_e_n_r_dout(8*idiv8+7 downto 8*idiv8);
        else
          g_vector(8*i+7 downto 8*i) <= std_logic_vector( unsigned(g_e_n_r_dout(8*idiv8+7 downto 8*idiv8)) +
                                                             to_unsigned(imod8, 8));
        end if;
      end if;
    end loop;
  end process;

  ----
  -- Qaz
  g_noop <= g_n_div_rebeq_dout;

  
  create_g_ack_bne_proc :
  process( swe_ed,swe_lv,g_e_z_dout)
    variable i : integer;
  begin
    for i in 0 to 31 loop
      if( g_e_z_dout(i) = '1') then
        swe_qaz1(i) <= swe_ed;
      else
        swe_qaz1(i) <= swe_lv;
      end if;
    end loop;
  end process;

end rtl;
