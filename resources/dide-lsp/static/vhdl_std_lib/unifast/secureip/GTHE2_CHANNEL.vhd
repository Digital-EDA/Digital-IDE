-------------------------------------------------------
--  Copyright (c) 2011 Xilinx Inc.
--  All Right Reserved.
-------------------------------------------------------
--
--   ____  ____
--  /   /\/   / 
-- /___/  \  /     Vendor      : Xilinx 
-- \   \   \/      Version     : 13.4
--  \   \          Description : 
--  /   /                      
-- /___/   /\      Filename    : GTHE2_CHANNEL.vhd
-- \   \  /  \      
--  \__ \/\__ \                   
--                                 
--  Revision: 1.0
--  04/13/11 - 605801 - Initial version 
--  05/24/11 - 610034 - Secureip model added
--  09/22/11 - 624065 - YML update
--  10/17/12 - 682802 - convert GSR H/L to 1/0
--  11/08/12 - 686590 - YML default attribute changes
--  01/23/13 - Added DRP monitor (CR 695630).
--  06/19/14 - PR785721 - IS_*INVERTED update from std_ulogic to bit
-------------------------------------------------------


----- CELL GTHE2_CHANNEL -----

library IEEE;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_1164.all;

library unisim;
use unisim.VCOMPONENTS.all;
use unisim.vpkg.all;

library secureip;
use secureip.all;

  entity GTHE2_CHANNEL is
    generic (
      ACJTAG_DEBUG_MODE : bit := '0';
      ACJTAG_MODE : bit := '0';
      ACJTAG_RESET : bit := '0';
      ADAPT_CFG0 : bit_vector := X"00C10";
      ALIGN_COMMA_DOUBLE : string := "FALSE";
      ALIGN_COMMA_ENABLE : bit_vector := "0001111111";
      ALIGN_COMMA_WORD : integer := 1;
      ALIGN_MCOMMA_DET : string := "TRUE";
      ALIGN_MCOMMA_VALUE : bit_vector := "1010000011";
      ALIGN_PCOMMA_DET : string := "TRUE";
      ALIGN_PCOMMA_VALUE : bit_vector := "0101111100";
      A_RXOSCALRESET : bit := '0';
      CBCC_DATA_SOURCE_SEL : string := "DECODED";
      CFOK_CFG : bit_vector := X"24800040E80";
      CFOK_CFG2 : bit_vector := "100000";
      CFOK_CFG3 : bit_vector := "100000";
      CHAN_BOND_KEEP_ALIGN : string := "FALSE";
      CHAN_BOND_MAX_SKEW : integer := 7;
      CHAN_BOND_SEQ_1_1 : bit_vector := "0101111100";
      CHAN_BOND_SEQ_1_2 : bit_vector := "0000000000";
      CHAN_BOND_SEQ_1_3 : bit_vector := "0000000000";
      CHAN_BOND_SEQ_1_4 : bit_vector := "0000000000";
      CHAN_BOND_SEQ_1_ENABLE : bit_vector := "1111";
      CHAN_BOND_SEQ_2_1 : bit_vector := "0100000000";
      CHAN_BOND_SEQ_2_2 : bit_vector := "0100000000";
      CHAN_BOND_SEQ_2_3 : bit_vector := "0100000000";
      CHAN_BOND_SEQ_2_4 : bit_vector := "0100000000";
      CHAN_BOND_SEQ_2_ENABLE : bit_vector := "1111";
      CHAN_BOND_SEQ_2_USE : string := "FALSE";
      CHAN_BOND_SEQ_LEN : integer := 1;
      CLK_CORRECT_USE : string := "TRUE";
      CLK_COR_KEEP_IDLE : string := "FALSE";
      CLK_COR_MAX_LAT : integer := 20;
      CLK_COR_MIN_LAT : integer := 18;
      CLK_COR_PRECEDENCE : string := "TRUE";
      CLK_COR_REPEAT_WAIT : integer := 0;
      CLK_COR_SEQ_1_1 : bit_vector := "0100011100";
      CLK_COR_SEQ_1_2 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_3 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_4 : bit_vector := "0000000000";
      CLK_COR_SEQ_1_ENABLE : bit_vector := "1111";
      CLK_COR_SEQ_2_1 : bit_vector := "0100000000";
      CLK_COR_SEQ_2_2 : bit_vector := "0100000000";
      CLK_COR_SEQ_2_3 : bit_vector := "0100000000";
      CLK_COR_SEQ_2_4 : bit_vector := "0100000000";
      CLK_COR_SEQ_2_ENABLE : bit_vector := "1111";
      CLK_COR_SEQ_2_USE : string := "FALSE";
      CLK_COR_SEQ_LEN : integer := 1;
      CPLL_CFG : bit_vector := X"00BC07DC";
      CPLL_FBDIV : integer := 4;
      CPLL_FBDIV_45 : integer := 5;
      CPLL_INIT_CFG : bit_vector := X"00001E";
      CPLL_LOCK_CFG : bit_vector := X"01E8";
      CPLL_REFCLK_DIV : integer := 1;
      DEC_MCOMMA_DETECT : string := "TRUE";
      DEC_PCOMMA_DETECT : string := "TRUE";
      DEC_VALID_COMMA_ONLY : string := "TRUE";
      DMONITOR_CFG : bit_vector := X"000A00";
      ES_CLK_PHASE_SEL : bit := '0';
      ES_CONTROL : bit_vector := "000000";
      ES_ERRDET_EN : string := "FALSE";
      ES_EYE_SCAN_EN : string := "TRUE";
      ES_HORZ_OFFSET : bit_vector := X"000";
      ES_PMA_CFG : bit_vector := "0000000000";
      ES_PRESCALE : bit_vector := "00000";
      ES_QUALIFIER : bit_vector := X"00000000000000000000";
      ES_QUAL_MASK : bit_vector := X"00000000000000000000";
      ES_SDATA_MASK : bit_vector := X"00000000000000000000";
      ES_VERT_OFFSET : bit_vector := "000000000";
      FTS_DESKEW_SEQ_ENABLE : bit_vector := "1111";
      FTS_LANE_DESKEW_CFG : bit_vector := "1111";
      FTS_LANE_DESKEW_EN : string := "FALSE";
      GEARBOX_MODE : bit_vector := "000";
      IS_CLKRSVD0_INVERTED : bit := '0';
      IS_CLKRSVD1_INVERTED : bit := '0';
      IS_CPLLLOCKDETCLK_INVERTED : bit := '0';
      IS_DMONITORCLK_INVERTED : bit := '0';
      IS_DRPCLK_INVERTED : bit := '0';
      IS_GTGREFCLK_INVERTED : bit := '0';
      IS_RXUSRCLK2_INVERTED : bit := '0';
      IS_RXUSRCLK_INVERTED : bit := '0';
      IS_SIGVALIDCLK_INVERTED : bit := '0';
      IS_TXPHDLYTSTCLK_INVERTED : bit := '0';
      IS_TXUSRCLK2_INVERTED : bit := '0';
      IS_TXUSRCLK_INVERTED : bit := '0';
      LOOPBACK_CFG : bit := '0';
      OUTREFCLK_SEL_INV : bit_vector := "11";
      PCS_PCIE_EN : string := "FALSE";
      PCS_RSVD_ATTR : bit_vector := X"000000000000";
      PD_TRANS_TIME_FROM_P2 : bit_vector := X"03C";
      PD_TRANS_TIME_NONE_P2 : bit_vector := X"19";
      PD_TRANS_TIME_TO_P2 : bit_vector := X"64";
      PMA_RSV : bit_vector := "00000000000000000000000010000000";
      PMA_RSV2 : bit_vector := "00011100000000000000000000001010";
      PMA_RSV3 : bit_vector := "00";
      PMA_RSV4 : bit_vector := "000000000001000";
      PMA_RSV5 : bit_vector := "0000";
      RESET_POWERSAVE_DISABLE : bit := '0';
      RXBUFRESET_TIME : bit_vector := "00001";
      RXBUF_ADDR_MODE : string := "FULL";
      RXBUF_EIDLE_HI_CNT : bit_vector := "1000";
      RXBUF_EIDLE_LO_CNT : bit_vector := "0000";
      RXBUF_EN : string := "TRUE";
      RXBUF_RESET_ON_CB_CHANGE : string := "TRUE";
      RXBUF_RESET_ON_COMMAALIGN : string := "FALSE";
      RXBUF_RESET_ON_EIDLE : string := "FALSE";
      RXBUF_RESET_ON_RATE_CHANGE : string := "TRUE";
      RXBUF_THRESH_OVFLW : integer := 61;
      RXBUF_THRESH_OVRD : string := "FALSE";
      RXBUF_THRESH_UNDFLW : integer := 4;
      RXCDRFREQRESET_TIME : bit_vector := "00001";
      RXCDRPHRESET_TIME : bit_vector := "00001";
      RXCDR_CFG : bit_vector := X"0002007FE2000C208001A";
      RXCDR_FR_RESET_ON_EIDLE : bit := '0';
      RXCDR_HOLD_DURING_EIDLE : bit := '0';
      RXCDR_LOCK_CFG : bit_vector := "001001";
      RXCDR_PH_RESET_ON_EIDLE : bit := '0';
      RXDFELPMRESET_TIME : bit_vector := "0001111";
      RXDLY_CFG : bit_vector := X"001F";
      RXDLY_LCFG : bit_vector := X"030";
      RXDLY_TAP_CFG : bit_vector := X"0000";
      RXGEARBOX_EN : string := "FALSE";
      RXISCANRESET_TIME : bit_vector := "00001";
      RXLPM_HF_CFG : bit_vector := "00001000000000";
      RXLPM_LF_CFG : bit_vector := "001001000000000000";
      RXOOB_CFG : bit_vector := "0000110";
      RXOOB_CLK_CFG : string := "PMA";
      RXOSCALRESET_TIME : bit_vector := "00011";
      RXOSCALRESET_TIMEOUT : bit_vector := "00000";
      RXOUT_DIV : integer := 2;
      RXPCSRESET_TIME : bit_vector := "00001";
      RXPHDLY_CFG : bit_vector := X"084020";
      RXPH_CFG : bit_vector := X"C00002";
      RXPH_MONITOR_SEL : bit_vector := "00000";
      RXPI_CFG0 : bit_vector := "00";
      RXPI_CFG1 : bit_vector := "00";
      RXPI_CFG2 : bit_vector := "00";
      RXPI_CFG3 : bit_vector := "00";
      RXPI_CFG4 : bit := '0';
      RXPI_CFG5 : bit := '0';
      RXPI_CFG6 : bit_vector := "100";
      RXPMARESET_TIME : bit_vector := "00011";
      RXPRBS_ERR_LOOPBACK : bit := '0';
      RXSLIDE_AUTO_WAIT : integer := 7;
      RXSLIDE_MODE : string := "OFF";
      RXSYNC_MULTILANE : bit := '0';
      RXSYNC_OVRD : bit := '0';
      RXSYNC_SKIP_DA : bit := '0';
      RX_BIAS_CFG : bit_vector := "000011000000000000010000";
      RX_BUFFER_CFG : bit_vector := "000000";
      RX_CLK25_DIV : integer := 7;
      RX_CLKMUX_PD : bit := '1';
      RX_CM_SEL : bit_vector := "11";
      RX_CM_TRIM : bit_vector := "0100";
      RX_DATA_WIDTH : integer := 20;
      RX_DDI_SEL : bit_vector := "000000";
      RX_DEBUG_CFG : bit_vector := "00000000000000";
      RX_DEFER_RESET_BUF_EN : string := "TRUE";
      RX_DFELPM_CFG0 : bit_vector := "0110";
      RX_DFELPM_CFG1 : bit := '0';
      RX_DFELPM_KLKH_AGC_STUP_EN : bit := '1';
      RX_DFE_AGC_CFG0 : bit_vector := "00";
      RX_DFE_AGC_CFG1 : bit_vector := "010";
      RX_DFE_AGC_CFG2 : bit_vector := "0000";
      RX_DFE_AGC_OVRDEN : bit := '1';
      RX_DFE_GAIN_CFG : bit_vector := X"0020C0";
      RX_DFE_H2_CFG : bit_vector := "000000000000";
      RX_DFE_H3_CFG : bit_vector := "000001000000";
      RX_DFE_H4_CFG : bit_vector := "00011100000";
      RX_DFE_H5_CFG : bit_vector := "00011100000";
      RX_DFE_H6_CFG : bit_vector := "00000100000";
      RX_DFE_H7_CFG : bit_vector := "00000100000";
      RX_DFE_KL_CFG : bit_vector := "000000000000000000000001100010000";
      RX_DFE_KL_LPM_KH_CFG0 : bit_vector := "01";
      RX_DFE_KL_LPM_KH_CFG1 : bit_vector := "010";
      RX_DFE_KL_LPM_KH_CFG2 : bit_vector := "0010";
      RX_DFE_KL_LPM_KH_OVRDEN : bit := '1';
      RX_DFE_KL_LPM_KL_CFG0 : bit_vector := "10";
      RX_DFE_KL_LPM_KL_CFG1 : bit_vector := "010";
      RX_DFE_KL_LPM_KL_CFG2 : bit_vector := "0010";
      RX_DFE_KL_LPM_KL_OVRDEN : bit := '1';
      RX_DFE_LPM_CFG : bit_vector := X"0080";
      RX_DFE_LPM_HOLD_DURING_EIDLE : bit := '0';
      RX_DFE_ST_CFG : bit_vector := X"00E100000C003F";
      RX_DFE_UT_CFG : bit_vector := "00011100000000000";
      RX_DFE_VP_CFG : bit_vector := "00011101010100011";
      RX_DISPERR_SEQ_MATCH : string := "TRUE";
      RX_INT_DATAWIDTH : integer := 0;
      RX_OS_CFG : bit_vector := "0000010000000";
      RX_SIG_VALID_DLY : integer := 10;
      RX_XCLK_SEL : string := "RXREC";
      SAS_MAX_COM : integer := 64;
      SAS_MIN_COM : integer := 36;
      SATA_BURST_SEQ_LEN : bit_vector := "1111";
      SATA_BURST_VAL : bit_vector := "100";
      SATA_CPLL_CFG : string := "VCO_3000MHZ";
      SATA_EIDLE_VAL : bit_vector := "100";
      SATA_MAX_BURST : integer := 8;
      SATA_MAX_INIT : integer := 21;
      SATA_MAX_WAKE : integer := 7;
      SATA_MIN_BURST : integer := 4;
      SATA_MIN_INIT : integer := 12;
      SATA_MIN_WAKE : integer := 4;
      SHOW_REALIGN_COMMA : string := "TRUE";
      SIM_CPLLREFCLK_SEL : bit_vector := "001";
      SIM_RECEIVER_DETECT_PASS : string := "TRUE";
      SIM_RESET_SPEEDUP : string := "TRUE";
      SIM_TX_EIDLE_DRIVE_LEVEL : string := "X";
      SIM_VERSION : string := "1.1";
      TERM_RCAL_CFG : bit_vector := "100001000010000";
      TERM_RCAL_OVRD : bit_vector := "000";
      TRANS_TIME_RATE : bit_vector := X"0E";
      TST_RSV : bit_vector := X"00000000";
      TXBUF_EN : string := "TRUE";
      TXBUF_RESET_ON_RATE_CHANGE : string := "FALSE";
      TXDLY_CFG : bit_vector := X"001F";
      TXDLY_LCFG : bit_vector := X"030";
      TXDLY_TAP_CFG : bit_vector := X"0000";
      TXGEARBOX_EN : string := "FALSE";
      TXOOB_CFG : bit := '0';
      TXOUT_DIV : integer := 2;
      TXPCSRESET_TIME : bit_vector := "00001";
      TXPHDLY_CFG : bit_vector := X"084020";
      TXPH_CFG : bit_vector := X"0780";
      TXPH_MONITOR_SEL : bit_vector := "00000";
      TXPI_CFG0 : bit_vector := "00";
      TXPI_CFG1 : bit_vector := "00";
      TXPI_CFG2 : bit_vector := "00";
      TXPI_CFG3 : bit := '0';
      TXPI_CFG4 : bit := '0';
      TXPI_CFG5 : bit_vector := "100";
      TXPI_GREY_SEL : bit := '0';
      TXPI_INVSTROBE_SEL : bit := '0';
      TXPI_PPMCLK_SEL : string := "TXUSRCLK2";
      TXPI_PPM_CFG : bit_vector := "00000000";
      TXPI_SYNFREQ_PPM : bit_vector := "000";
      TXPMARESET_TIME : bit_vector := "00001";
      TXSYNC_MULTILANE : bit := '0';
      TXSYNC_OVRD : bit := '0';
      TXSYNC_SKIP_DA : bit := '0';
      TX_CLK25_DIV : integer := 7;
      TX_CLKMUX_PD : bit := '1';
      TX_DATA_WIDTH : integer := 20;
      TX_DEEMPH0 : bit_vector := "000000";
      TX_DEEMPH1 : bit_vector := "000000";
      TX_DRIVE_MODE : string := "DIRECT";
      TX_EIDLE_ASSERT_DELAY : bit_vector := "110";
      TX_EIDLE_DEASSERT_DELAY : bit_vector := "100";
      TX_INT_DATAWIDTH : integer := 0;
      TX_LOOPBACK_DRIVE_HIZ : string := "FALSE";
      TX_MAINCURSOR_SEL : bit := '0';
      TX_MARGIN_FULL_0 : bit_vector := "1001110";
      TX_MARGIN_FULL_1 : bit_vector := "1001001";
      TX_MARGIN_FULL_2 : bit_vector := "1000101";
      TX_MARGIN_FULL_3 : bit_vector := "1000010";
      TX_MARGIN_FULL_4 : bit_vector := "1000000";
      TX_MARGIN_LOW_0 : bit_vector := "1000110";
      TX_MARGIN_LOW_1 : bit_vector := "1000100";
      TX_MARGIN_LOW_2 : bit_vector := "1000010";
      TX_MARGIN_LOW_3 : bit_vector := "1000000";
      TX_MARGIN_LOW_4 : bit_vector := "1000000";
      TX_QPI_STATUS_EN : bit := '0';
      TX_RXDETECT_CFG : bit_vector := X"1832";
      TX_RXDETECT_PRECHARGE_TIME : bit_vector := X"00000";
      TX_RXDETECT_REF : bit_vector := "100";
      TX_XCLK_SEL : string := "TXUSR";
      UCODEER_CLR : bit := '0';
      USE_PCS_CLK_PHASE_SEL : bit := '0'
      );

    port (
      CPLLFBCLKLOST        : out std_ulogic;
      CPLLLOCK             : out std_ulogic;
      CPLLREFCLKLOST       : out std_ulogic;
      DMONITOROUT          : out std_logic_vector(14 downto 0);
      DRPDO                : out std_logic_vector(15 downto 0);
      DRPRDY               : out std_ulogic;
      EYESCANDATAERROR     : out std_ulogic;
      GTHTXN               : out std_ulogic;
      GTHTXP               : out std_ulogic;
      GTREFCLKMONITOR      : out std_ulogic;
      PCSRSVDOUT           : out std_logic_vector(15 downto 0);
      PHYSTATUS            : out std_ulogic;
      RSOSINTDONE          : out std_ulogic;
      RXBUFSTATUS          : out std_logic_vector(2 downto 0);
      RXBYTEISALIGNED      : out std_ulogic;
      RXBYTEREALIGN        : out std_ulogic;
      RXCDRLOCK            : out std_ulogic;
      RXCHANBONDSEQ        : out std_ulogic;
      RXCHANISALIGNED      : out std_ulogic;
      RXCHANREALIGN        : out std_ulogic;
      RXCHARISCOMMA        : out std_logic_vector(7 downto 0);
      RXCHARISK            : out std_logic_vector(7 downto 0);
      RXCHBONDO            : out std_logic_vector(4 downto 0);
      RXCLKCORCNT          : out std_logic_vector(1 downto 0);
      RXCOMINITDET         : out std_ulogic;
      RXCOMMADET           : out std_ulogic;
      RXCOMSASDET          : out std_ulogic;
      RXCOMWAKEDET         : out std_ulogic;
      RXDATA               : out std_logic_vector(63 downto 0);
      RXDATAVALID          : out std_logic_vector(1 downto 0);
      RXDFESLIDETAPSTARTED : out std_ulogic;
      RXDFESLIDETAPSTROBEDONE : out std_ulogic;
      RXDFESLIDETAPSTROBESTARTED : out std_ulogic;
      RXDFESTADAPTDONE     : out std_ulogic;
      RXDISPERR            : out std_logic_vector(7 downto 0);
      RXDLYSRESETDONE      : out std_ulogic;
      RXELECIDLE           : out std_ulogic;
      RXHEADER             : out std_logic_vector(5 downto 0);
      RXHEADERVALID        : out std_logic_vector(1 downto 0);
      RXMONITOROUT         : out std_logic_vector(6 downto 0);
      RXNOTINTABLE         : out std_logic_vector(7 downto 0);
      RXOSINTSTARTED       : out std_ulogic;
      RXOSINTSTROBEDONE    : out std_ulogic;
      RXOSINTSTROBESTARTED : out std_ulogic;
      RXOUTCLK             : out std_ulogic;
      RXOUTCLKFABRIC       : out std_ulogic;
      RXOUTCLKPCS          : out std_ulogic;
      RXPHALIGNDONE        : out std_ulogic;
      RXPHMONITOR          : out std_logic_vector(4 downto 0);
      RXPHSLIPMONITOR      : out std_logic_vector(4 downto 0);
      RXPMARESETDONE       : out std_ulogic;
      RXPRBSERR            : out std_ulogic;
      RXQPISENN            : out std_ulogic;
      RXQPISENP            : out std_ulogic;
      RXRATEDONE           : out std_ulogic;
      RXRESETDONE          : out std_ulogic;
      RXSTARTOFSEQ         : out std_logic_vector(1 downto 0);
      RXSTATUS             : out std_logic_vector(2 downto 0);
      RXSYNCDONE           : out std_ulogic;
      RXSYNCOUT            : out std_ulogic;
      RXVALID              : out std_ulogic;
      TXBUFSTATUS          : out std_logic_vector(1 downto 0);
      TXCOMFINISH          : out std_ulogic;
      TXDLYSRESETDONE      : out std_ulogic;
      TXGEARBOXREADY       : out std_ulogic;
      TXOUTCLK             : out std_ulogic;
      TXOUTCLKFABRIC       : out std_ulogic;
      TXOUTCLKPCS          : out std_ulogic;
      TXPHALIGNDONE        : out std_ulogic;
      TXPHINITDONE         : out std_ulogic;
      TXPMARESETDONE       : out std_ulogic;
      TXQPISENN            : out std_ulogic;
      TXQPISENP            : out std_ulogic;
      TXRATEDONE           : out std_ulogic;
      TXRESETDONE          : out std_ulogic;
      TXSYNCDONE           : out std_ulogic;
      TXSYNCOUT            : out std_ulogic;
      CFGRESET             : in std_ulogic;
      CLKRSVD0             : in std_ulogic;
      CLKRSVD1             : in std_ulogic;
      CPLLLOCKDETCLK       : in std_ulogic;
      CPLLLOCKEN           : in std_ulogic;
      CPLLPD               : in std_ulogic;
      CPLLREFCLKSEL        : in std_logic_vector(2 downto 0);
      CPLLRESET            : in std_ulogic;
      DMONFIFORESET        : in std_ulogic;
      DMONITORCLK          : in std_ulogic;
      DRPADDR              : in std_logic_vector(8 downto 0);
      DRPCLK               : in std_ulogic;
      DRPDI                : in std_logic_vector(15 downto 0);
      DRPEN                : in std_ulogic;
      DRPWE                : in std_ulogic;
      EYESCANMODE          : in std_ulogic;
      EYESCANRESET         : in std_ulogic;
      EYESCANTRIGGER       : in std_ulogic;
      GTGREFCLK            : in std_ulogic;
      GTHRXN               : in std_ulogic;
      GTHRXP               : in std_ulogic;
      GTNORTHREFCLK0       : in std_ulogic;
      GTNORTHREFCLK1       : in std_ulogic;
      GTREFCLK0            : in std_ulogic;
      GTREFCLK1            : in std_ulogic;
      GTRESETSEL           : in std_ulogic;
      GTRSVD               : in std_logic_vector(15 downto 0);
      GTRXRESET            : in std_ulogic;
      GTSOUTHREFCLK0       : in std_ulogic;
      GTSOUTHREFCLK1       : in std_ulogic;
      GTTXRESET            : in std_ulogic;
      LOOPBACK             : in std_logic_vector(2 downto 0);
      PCSRSVDIN            : in std_logic_vector(15 downto 0);
      PCSRSVDIN2           : in std_logic_vector(4 downto 0);
      PMARSVDIN            : in std_logic_vector(4 downto 0);
      QPLLCLK              : in std_ulogic;
      QPLLREFCLK           : in std_ulogic;
      RESETOVRD            : in std_ulogic;
      RX8B10BEN            : in std_ulogic;
      RXADAPTSELTEST       : in std_logic_vector(13 downto 0);
      RXBUFRESET           : in std_ulogic;
      RXCDRFREQRESET       : in std_ulogic;
      RXCDRHOLD            : in std_ulogic;
      RXCDROVRDEN          : in std_ulogic;
      RXCDRRESET           : in std_ulogic;
      RXCDRRESETRSV        : in std_ulogic;
      RXCHBONDEN           : in std_ulogic;
      RXCHBONDI            : in std_logic_vector(4 downto 0);
      RXCHBONDLEVEL        : in std_logic_vector(2 downto 0);
      RXCHBONDMASTER       : in std_ulogic;
      RXCHBONDSLAVE        : in std_ulogic;
      RXCOMMADETEN         : in std_ulogic;
      RXDDIEN              : in std_ulogic;
      RXDFEAGCHOLD         : in std_ulogic;
      RXDFEAGCOVRDEN       : in std_ulogic;
      RXDFEAGCTRL          : in std_logic_vector(4 downto 0);
      RXDFECM1EN           : in std_ulogic;
      RXDFELFHOLD          : in std_ulogic;
      RXDFELFOVRDEN        : in std_ulogic;
      RXDFELPMRESET        : in std_ulogic;
      RXDFESLIDETAP        : in std_logic_vector(4 downto 0);
      RXDFESLIDETAPADAPTEN : in std_ulogic;
      RXDFESLIDETAPHOLD    : in std_ulogic;
      RXDFESLIDETAPID      : in std_logic_vector(5 downto 0);
      RXDFESLIDETAPINITOVRDEN : in std_ulogic;
      RXDFESLIDETAPONLYADAPTEN : in std_ulogic;
      RXDFESLIDETAPOVRDEN  : in std_ulogic;
      RXDFESLIDETAPSTROBE  : in std_ulogic;
      RXDFETAP2HOLD        : in std_ulogic;
      RXDFETAP2OVRDEN      : in std_ulogic;
      RXDFETAP3HOLD        : in std_ulogic;
      RXDFETAP3OVRDEN      : in std_ulogic;
      RXDFETAP4HOLD        : in std_ulogic;
      RXDFETAP4OVRDEN      : in std_ulogic;
      RXDFETAP5HOLD        : in std_ulogic;
      RXDFETAP5OVRDEN      : in std_ulogic;
      RXDFETAP6HOLD        : in std_ulogic;
      RXDFETAP6OVRDEN      : in std_ulogic;
      RXDFETAP7HOLD        : in std_ulogic;
      RXDFETAP7OVRDEN      : in std_ulogic;
      RXDFEUTHOLD          : in std_ulogic;
      RXDFEUTOVRDEN        : in std_ulogic;
      RXDFEVPHOLD          : in std_ulogic;
      RXDFEVPOVRDEN        : in std_ulogic;
      RXDFEVSEN            : in std_ulogic;
      RXDFEXYDEN           : in std_ulogic;
      RXDLYBYPASS          : in std_ulogic;
      RXDLYEN              : in std_ulogic;
      RXDLYOVRDEN          : in std_ulogic;
      RXDLYSRESET          : in std_ulogic;
      RXELECIDLEMODE       : in std_logic_vector(1 downto 0);
      RXGEARBOXSLIP        : in std_ulogic;
      RXLPMEN              : in std_ulogic;
      RXLPMHFHOLD          : in std_ulogic;
      RXLPMHFOVRDEN        : in std_ulogic;
      RXLPMLFHOLD          : in std_ulogic;
      RXLPMLFKLOVRDEN      : in std_ulogic;
      RXMCOMMAALIGNEN      : in std_ulogic;
      RXMONITORSEL         : in std_logic_vector(1 downto 0);
      RXOOBRESET           : in std_ulogic;
      RXOSCALRESET         : in std_ulogic;
      RXOSHOLD             : in std_ulogic;
      RXOSINTCFG           : in std_logic_vector(3 downto 0);
      RXOSINTEN            : in std_ulogic;
      RXOSINTHOLD          : in std_ulogic;
      RXOSINTID0           : in std_logic_vector(3 downto 0);
      RXOSINTNTRLEN        : in std_ulogic;
      RXOSINTOVRDEN        : in std_ulogic;
      RXOSINTSTROBE        : in std_ulogic;
      RXOSINTTESTOVRDEN    : in std_ulogic;
      RXOSOVRDEN           : in std_ulogic;
      RXOUTCLKSEL          : in std_logic_vector(2 downto 0);
      RXPCOMMAALIGNEN      : in std_ulogic;
      RXPCSRESET           : in std_ulogic;
      RXPD                 : in std_logic_vector(1 downto 0);
      RXPHALIGN            : in std_ulogic;
      RXPHALIGNEN          : in std_ulogic;
      RXPHDLYPD            : in std_ulogic;
      RXPHDLYRESET         : in std_ulogic;
      RXPHOVRDEN           : in std_ulogic;
      RXPMARESET           : in std_ulogic;
      RXPOLARITY           : in std_ulogic;
      RXPRBSCNTRESET       : in std_ulogic;
      RXPRBSSEL            : in std_logic_vector(2 downto 0);
      RXQPIEN              : in std_ulogic;
      RXRATE               : in std_logic_vector(2 downto 0);
      RXRATEMODE           : in std_ulogic;
      RXSLIDE              : in std_ulogic;
      RXSYNCALLIN          : in std_ulogic;
      RXSYNCIN             : in std_ulogic;
      RXSYNCMODE           : in std_ulogic;
      RXSYSCLKSEL          : in std_logic_vector(1 downto 0);
      RXUSERRDY            : in std_ulogic;
      RXUSRCLK             : in std_ulogic;
      RXUSRCLK2            : in std_ulogic;
      SETERRSTATUS         : in std_ulogic;
      SIGVALIDCLK          : in std_ulogic;
      TSTIN                : in std_logic_vector(19 downto 0);
      TX8B10BBYPASS        : in std_logic_vector(7 downto 0);
      TX8B10BEN            : in std_ulogic;
      TXBUFDIFFCTRL        : in std_logic_vector(2 downto 0);
      TXCHARDISPMODE       : in std_logic_vector(7 downto 0);
      TXCHARDISPVAL        : in std_logic_vector(7 downto 0);
      TXCHARISK            : in std_logic_vector(7 downto 0);
      TXCOMINIT            : in std_ulogic;
      TXCOMSAS             : in std_ulogic;
      TXCOMWAKE            : in std_ulogic;
      TXDATA               : in std_logic_vector(63 downto 0);
      TXDEEMPH             : in std_ulogic;
      TXDETECTRX           : in std_ulogic;
      TXDIFFCTRL           : in std_logic_vector(3 downto 0);
      TXDIFFPD             : in std_ulogic;
      TXDLYBYPASS          : in std_ulogic;
      TXDLYEN              : in std_ulogic;
      TXDLYHOLD            : in std_ulogic;
      TXDLYOVRDEN          : in std_ulogic;
      TXDLYSRESET          : in std_ulogic;
      TXDLYUPDOWN          : in std_ulogic;
      TXELECIDLE           : in std_ulogic;
      TXHEADER             : in std_logic_vector(2 downto 0);
      TXINHIBIT            : in std_ulogic;
      TXMAINCURSOR         : in std_logic_vector(6 downto 0);
      TXMARGIN             : in std_logic_vector(2 downto 0);
      TXOUTCLKSEL          : in std_logic_vector(2 downto 0);
      TXPCSRESET           : in std_ulogic;
      TXPD                 : in std_logic_vector(1 downto 0);
      TXPDELECIDLEMODE     : in std_ulogic;
      TXPHALIGN            : in std_ulogic;
      TXPHALIGNEN          : in std_ulogic;
      TXPHDLYPD            : in std_ulogic;
      TXPHDLYRESET         : in std_ulogic;
      TXPHDLYTSTCLK        : in std_ulogic;
      TXPHINIT             : in std_ulogic;
      TXPHOVRDEN           : in std_ulogic;
      TXPIPPMEN            : in std_ulogic;
      TXPIPPMOVRDEN        : in std_ulogic;
      TXPIPPMPD            : in std_ulogic;
      TXPIPPMSEL           : in std_ulogic;
      TXPIPPMSTEPSIZE      : in std_logic_vector(4 downto 0);
      TXPISOPD             : in std_ulogic;
      TXPMARESET           : in std_ulogic;
      TXPOLARITY           : in std_ulogic;
      TXPOSTCURSOR         : in std_logic_vector(4 downto 0);
      TXPOSTCURSORINV      : in std_ulogic;
      TXPRBSFORCEERR       : in std_ulogic;
      TXPRBSSEL            : in std_logic_vector(2 downto 0);
      TXPRECURSOR          : in std_logic_vector(4 downto 0);
      TXPRECURSORINV       : in std_ulogic;
      TXQPIBIASEN          : in std_ulogic;
      TXQPISTRONGPDOWN     : in std_ulogic;
      TXQPIWEAKPUP         : in std_ulogic;
      TXRATE               : in std_logic_vector(2 downto 0);
      TXRATEMODE           : in std_ulogic;
      TXSEQUENCE           : in std_logic_vector(6 downto 0);
      TXSTARTSEQ           : in std_ulogic;
      TXSWING              : in std_ulogic;
      TXSYNCALLIN          : in std_ulogic;
      TXSYNCIN             : in std_ulogic;
      TXSYNCMODE           : in std_ulogic;
      TXSYSCLKSEL          : in std_logic_vector(1 downto 0);
      TXUSERRDY            : in std_ulogic;
      TXUSRCLK             : in std_ulogic;
      TXUSRCLK2            : in std_ulogic      
    );
  end GTHE2_CHANNEL;

  architecture GTHE2_CHANNEL_FAST_V of GTHE2_CHANNEL is
    component GTHE2_CHANNEL_FAST_WRAP
      generic (
        ACJTAG_DEBUG_MODE : string;
        ACJTAG_MODE : string;
        ACJTAG_RESET : string;
        ADAPT_CFG0 : string;
        ALIGN_COMMA_DOUBLE : string;
        ALIGN_COMMA_ENABLE : string;
        ALIGN_COMMA_WORD : integer;
        ALIGN_MCOMMA_DET : string;
        ALIGN_MCOMMA_VALUE : string;
        ALIGN_PCOMMA_DET : string;
        ALIGN_PCOMMA_VALUE : string;
        A_RXOSCALRESET : string;
        CBCC_DATA_SOURCE_SEL : string;
        CFOK_CFG : string;
        CFOK_CFG2 : string;
        CFOK_CFG3 : string;
        CHAN_BOND_KEEP_ALIGN : string;
        CHAN_BOND_MAX_SKEW : integer;
        CHAN_BOND_SEQ_1_1 : string;
        CHAN_BOND_SEQ_1_2 : string;
        CHAN_BOND_SEQ_1_3 : string;
        CHAN_BOND_SEQ_1_4 : string;
        CHAN_BOND_SEQ_1_ENABLE : string;
        CHAN_BOND_SEQ_2_1 : string;
        CHAN_BOND_SEQ_2_2 : string;
        CHAN_BOND_SEQ_2_3 : string;
        CHAN_BOND_SEQ_2_4 : string;
        CHAN_BOND_SEQ_2_ENABLE : string;
        CHAN_BOND_SEQ_2_USE : string;
        CHAN_BOND_SEQ_LEN : integer;
        CLK_CORRECT_USE : string;
        CLK_COR_KEEP_IDLE : string;
        CLK_COR_MAX_LAT : integer;
        CLK_COR_MIN_LAT : integer;
        CLK_COR_PRECEDENCE : string;
        CLK_COR_REPEAT_WAIT : integer;
        CLK_COR_SEQ_1_1 : string;
        CLK_COR_SEQ_1_2 : string;
        CLK_COR_SEQ_1_3 : string;
        CLK_COR_SEQ_1_4 : string;
        CLK_COR_SEQ_1_ENABLE : string;
        CLK_COR_SEQ_2_1 : string;
        CLK_COR_SEQ_2_2 : string;
        CLK_COR_SEQ_2_3 : string;
        CLK_COR_SEQ_2_4 : string;
        CLK_COR_SEQ_2_ENABLE : string;
        CLK_COR_SEQ_2_USE : string;
        CLK_COR_SEQ_LEN : integer;
        CPLL_CFG : string;
        CPLL_FBDIV : integer;
        CPLL_FBDIV_45 : integer;
        CPLL_INIT_CFG : string;
        CPLL_LOCK_CFG : string;
        CPLL_REFCLK_DIV : integer;
        DEC_MCOMMA_DETECT : string;
        DEC_PCOMMA_DETECT : string;
        DEC_VALID_COMMA_ONLY : string;
        DMONITOR_CFG : string;
        ES_CLK_PHASE_SEL : string;
        ES_CONTROL : string;
        ES_ERRDET_EN : string;
        ES_EYE_SCAN_EN : string;
        ES_HORZ_OFFSET : string;
        ES_PMA_CFG : string;
        ES_PRESCALE : string;
        ES_QUALIFIER : string;
        ES_QUAL_MASK : string;
        ES_SDATA_MASK : string;
        ES_VERT_OFFSET : string;
        FTS_DESKEW_SEQ_ENABLE : string;
        FTS_LANE_DESKEW_CFG : string;
        FTS_LANE_DESKEW_EN : string;
        GEARBOX_MODE : string;
        LOOPBACK_CFG : string;
        OUTREFCLK_SEL_INV : string;
        PCS_PCIE_EN : string;
        PCS_RSVD_ATTR : string;
        PD_TRANS_TIME_FROM_P2 : string;
        PD_TRANS_TIME_NONE_P2 : string;
        PD_TRANS_TIME_TO_P2 : string;
        PMA_RSV : string;
        PMA_RSV2 : string;
        PMA_RSV3 : string;
        PMA_RSV4 : string;
        PMA_RSV5 : string;
        RESET_POWERSAVE_DISABLE : string;
        RXBUFRESET_TIME : string;
        RXBUF_ADDR_MODE : string;
        RXBUF_EIDLE_HI_CNT : string;
        RXBUF_EIDLE_LO_CNT : string;
        RXBUF_EN : string;
        RXBUF_RESET_ON_CB_CHANGE : string;
        RXBUF_RESET_ON_COMMAALIGN : string;
        RXBUF_RESET_ON_EIDLE : string;
        RXBUF_RESET_ON_RATE_CHANGE : string;
        RXBUF_THRESH_OVFLW : integer;
        RXBUF_THRESH_OVRD : string;
        RXBUF_THRESH_UNDFLW : integer;
        RXCDRFREQRESET_TIME : string;
        RXCDRPHRESET_TIME : string;
        RXCDR_CFG : string;
        RXCDR_FR_RESET_ON_EIDLE : string;
        RXCDR_HOLD_DURING_EIDLE : string;
        RXCDR_LOCK_CFG : string;
        RXCDR_PH_RESET_ON_EIDLE : string;
        RXDFELPMRESET_TIME : string;
        RXDLY_CFG : string;
        RXDLY_LCFG : string;
        RXDLY_TAP_CFG : string;
        RXGEARBOX_EN : string;
        RXISCANRESET_TIME : string;
        RXLPM_HF_CFG : string;
        RXLPM_LF_CFG : string;
        RXOOB_CFG : string;
        RXOOB_CLK_CFG : string;
        RXOSCALRESET_TIME : string;
        RXOSCALRESET_TIMEOUT : string;
        RXOUT_DIV : integer;
        RXPCSRESET_TIME : string;
        RXPHDLY_CFG : string;
        RXPH_CFG : string;
        RXPH_MONITOR_SEL : string;
        RXPI_CFG0 : string;
        RXPI_CFG1 : string;
        RXPI_CFG2 : string;
        RXPI_CFG3 : string;
        RXPI_CFG4 : string;
        RXPI_CFG5 : string;
        RXPI_CFG6 : string;
        RXPMARESET_TIME : string;
        RXPRBS_ERR_LOOPBACK : string;
        RXSLIDE_AUTO_WAIT : integer;
        RXSLIDE_MODE : string;
        RXSYNC_MULTILANE : string;
        RXSYNC_OVRD : string;
        RXSYNC_SKIP_DA : string;
        RX_BIAS_CFG : string;
        RX_BUFFER_CFG : string;
        RX_CLK25_DIV : integer;
        RX_CLKMUX_PD : string;
        RX_CM_SEL : string;
        RX_CM_TRIM : string;
        RX_DATA_WIDTH : integer;
        RX_DDI_SEL : string;
        RX_DEBUG_CFG : string;
        RX_DEFER_RESET_BUF_EN : string;
        RX_DFELPM_CFG0 : string;
        RX_DFELPM_CFG1 : string;
        RX_DFELPM_KLKH_AGC_STUP_EN : string;
        RX_DFE_AGC_CFG0 : string;
        RX_DFE_AGC_CFG1 : string;
        RX_DFE_AGC_CFG2 : string;
        RX_DFE_AGC_OVRDEN : string;
        RX_DFE_GAIN_CFG : string;
        RX_DFE_H2_CFG : string;
        RX_DFE_H3_CFG : string;
        RX_DFE_H4_CFG : string;
        RX_DFE_H5_CFG : string;
        RX_DFE_H6_CFG : string;
        RX_DFE_H7_CFG : string;
        RX_DFE_KL_CFG : string;
        RX_DFE_KL_LPM_KH_CFG0 : string;
        RX_DFE_KL_LPM_KH_CFG1 : string;
        RX_DFE_KL_LPM_KH_CFG2 : string;
        RX_DFE_KL_LPM_KH_OVRDEN : string;
        RX_DFE_KL_LPM_KL_CFG0 : string;
        RX_DFE_KL_LPM_KL_CFG1 : string;
        RX_DFE_KL_LPM_KL_CFG2 : string;
        RX_DFE_KL_LPM_KL_OVRDEN : string;
        RX_DFE_LPM_CFG : string;
        RX_DFE_LPM_HOLD_DURING_EIDLE : string;
        RX_DFE_ST_CFG : string;
        RX_DFE_UT_CFG : string;
        RX_DFE_VP_CFG : string;
        RX_DISPERR_SEQ_MATCH : string;
        RX_INT_DATAWIDTH : integer;
        RX_OS_CFG : string;
        RX_SIG_VALID_DLY : integer;
        RX_XCLK_SEL : string;
        SAS_MAX_COM : integer;
        SAS_MIN_COM : integer;
        SATA_BURST_SEQ_LEN : string;
        SATA_BURST_VAL : string;
        SATA_CPLL_CFG : string;
        SATA_EIDLE_VAL : string;
        SATA_MAX_BURST : integer;
        SATA_MAX_INIT : integer;
        SATA_MAX_WAKE : integer;
        SATA_MIN_BURST : integer;
        SATA_MIN_INIT : integer;
        SATA_MIN_WAKE : integer;
        SHOW_REALIGN_COMMA : string;
        SIM_CPLLREFCLK_SEL : string;
        SIM_RECEIVER_DETECT_PASS : string;
        SIM_RESET_SPEEDUP : string;
        SIM_TX_EIDLE_DRIVE_LEVEL : string;
        SIM_VERSION : string;
        TERM_RCAL_CFG : string;
        TERM_RCAL_OVRD : string;
        TRANS_TIME_RATE : string;
        TST_RSV : string;
        TXBUF_EN : string;
        TXBUF_RESET_ON_RATE_CHANGE : string;
        TXDLY_CFG : string;
        TXDLY_LCFG : string;
        TXDLY_TAP_CFG : string;
        TXGEARBOX_EN : string;
        TXOOB_CFG : string;
        TXOUT_DIV : integer;
        TXPCSRESET_TIME : string;
        TXPHDLY_CFG : string;
        TXPH_CFG : string;
        TXPH_MONITOR_SEL : string;
        TXPI_CFG0 : string;
        TXPI_CFG1 : string;
        TXPI_CFG2 : string;
        TXPI_CFG3 : string;
        TXPI_CFG4 : string;
        TXPI_CFG5 : string;
        TXPI_GREY_SEL : string;
        TXPI_INVSTROBE_SEL : string;
        TXPI_PPMCLK_SEL : string;
        TXPI_PPM_CFG : string;
        TXPI_SYNFREQ_PPM : string;
        TXPMARESET_TIME : string;
        TXSYNC_MULTILANE : string;
        TXSYNC_OVRD : string;
        TXSYNC_SKIP_DA : string;
        TX_CLK25_DIV : integer;
        TX_CLKMUX_PD : string;
        TX_DATA_WIDTH : integer;
        TX_DEEMPH0 : string;
        TX_DEEMPH1 : string;
        TX_DRIVE_MODE : string;
        TX_EIDLE_ASSERT_DELAY : string;
        TX_EIDLE_DEASSERT_DELAY : string;
        TX_INT_DATAWIDTH : integer;
        TX_LOOPBACK_DRIVE_HIZ : string;
        TX_MAINCURSOR_SEL : string;
        TX_MARGIN_FULL_0 : string;
        TX_MARGIN_FULL_1 : string;
        TX_MARGIN_FULL_2 : string;
        TX_MARGIN_FULL_3 : string;
        TX_MARGIN_FULL_4 : string;
        TX_MARGIN_LOW_0 : string;
        TX_MARGIN_LOW_1 : string;
        TX_MARGIN_LOW_2 : string;
        TX_MARGIN_LOW_3 : string;
        TX_MARGIN_LOW_4 : string;
        TX_QPI_STATUS_EN : string;
        TX_RXDETECT_CFG : string;
        TX_RXDETECT_PRECHARGE_TIME : string;
        TX_RXDETECT_REF : string;
        TX_XCLK_SEL : string;
        UCODEER_CLR : string;
        USE_PCS_CLK_PHASE_SEL : string        
      );
      
      port (
        CPLLFBCLKLOST        : out std_ulogic;
        CPLLLOCK             : out std_ulogic;
        CPLLREFCLKLOST       : out std_ulogic;
        DMONITOROUT          : out std_logic_vector(14 downto 0);
        DRPDO                : out std_logic_vector(15 downto 0);
        DRPRDY               : out std_ulogic;
        EYESCANDATAERROR     : out std_ulogic;
        GTHTXN               : out std_ulogic;
        GTHTXP               : out std_ulogic;
        GTREFCLKMONITOR      : out std_ulogic;
        PCSRSVDOUT           : out std_logic_vector(15 downto 0);
        PHYSTATUS            : out std_ulogic;
        RSOSINTDONE          : out std_ulogic;
        RXBUFSTATUS          : out std_logic_vector(2 downto 0);
        RXBYTEISALIGNED      : out std_ulogic;
        RXBYTEREALIGN        : out std_ulogic;
        RXCDRLOCK            : out std_ulogic;
        RXCHANBONDSEQ        : out std_ulogic;
        RXCHANISALIGNED      : out std_ulogic;
        RXCHANREALIGN        : out std_ulogic;
        RXCHARISCOMMA        : out std_logic_vector(7 downto 0);
        RXCHARISK            : out std_logic_vector(7 downto 0);
        RXCHBONDO            : out std_logic_vector(4 downto 0);
        RXCLKCORCNT          : out std_logic_vector(1 downto 0);
        RXCOMINITDET         : out std_ulogic;
        RXCOMMADET           : out std_ulogic;
        RXCOMSASDET          : out std_ulogic;
        RXCOMWAKEDET         : out std_ulogic;
        RXDATA               : out std_logic_vector(63 downto 0);
        RXDATAVALID          : out std_logic_vector(1 downto 0);
        RXDFESLIDETAPSTARTED : out std_ulogic;
        RXDFESLIDETAPSTROBEDONE : out std_ulogic;
        RXDFESLIDETAPSTROBESTARTED : out std_ulogic;
        RXDFESTADAPTDONE     : out std_ulogic;
        RXDISPERR            : out std_logic_vector(7 downto 0);
        RXDLYSRESETDONE      : out std_ulogic;
        RXELECIDLE           : out std_ulogic;
        RXHEADER             : out std_logic_vector(5 downto 0);
        RXHEADERVALID        : out std_logic_vector(1 downto 0);
        RXMONITOROUT         : out std_logic_vector(6 downto 0);
        RXNOTINTABLE         : out std_logic_vector(7 downto 0);
        RXOSINTSTARTED       : out std_ulogic;
        RXOSINTSTROBEDONE    : out std_ulogic;
        RXOSINTSTROBESTARTED : out std_ulogic;
        RXOUTCLK             : out std_ulogic;
        RXOUTCLKFABRIC       : out std_ulogic;
        RXOUTCLKPCS          : out std_ulogic;
        RXPHALIGNDONE        : out std_ulogic;
        RXPHMONITOR          : out std_logic_vector(4 downto 0);
        RXPHSLIPMONITOR      : out std_logic_vector(4 downto 0);
        RXPMARESETDONE       : out std_ulogic;
        RXPRBSERR            : out std_ulogic;
        RXQPISENN            : out std_ulogic;
        RXQPISENP            : out std_ulogic;
        RXRATEDONE           : out std_ulogic;
        RXRESETDONE          : out std_ulogic;
        RXSTARTOFSEQ         : out std_logic_vector(1 downto 0);
        RXSTATUS             : out std_logic_vector(2 downto 0);
        RXSYNCDONE           : out std_ulogic;
        RXSYNCOUT            : out std_ulogic;
        RXVALID              : out std_ulogic;
        TXBUFSTATUS          : out std_logic_vector(1 downto 0);
        TXCOMFINISH          : out std_ulogic;
        TXDLYSRESETDONE      : out std_ulogic;
        TXGEARBOXREADY       : out std_ulogic;
        TXOUTCLK             : out std_ulogic;
        TXOUTCLKFABRIC       : out std_ulogic;
        TXOUTCLKPCS          : out std_ulogic;
        TXPHALIGNDONE        : out std_ulogic;
        TXPHINITDONE         : out std_ulogic;
        TXPMARESETDONE       : out std_ulogic;
        TXQPISENN            : out std_ulogic;
        TXQPISENP            : out std_ulogic;
        TXRATEDONE           : out std_ulogic;
        TXRESETDONE          : out std_ulogic;
        TXSYNCDONE           : out std_ulogic;
        TXSYNCOUT            : out std_ulogic;

        GSR                  : in std_ulogic;
        CFGRESET             : in std_ulogic;
        CLKRSVD0             : in std_ulogic;
        CLKRSVD1             : in std_ulogic;
        CPLLLOCKDETCLK       : in std_ulogic;
        CPLLLOCKEN           : in std_ulogic;
        CPLLPD               : in std_ulogic;
        CPLLREFCLKSEL        : in std_logic_vector(2 downto 0);
        CPLLRESET            : in std_ulogic;
        DMONFIFORESET        : in std_ulogic;
        DMONITORCLK          : in std_ulogic;
        DRPADDR              : in std_logic_vector(8 downto 0);
        DRPCLK               : in std_ulogic;
        DRPDI                : in std_logic_vector(15 downto 0);
        DRPEN                : in std_ulogic;
        DRPWE                : in std_ulogic;
        EYESCANMODE          : in std_ulogic;
        EYESCANRESET         : in std_ulogic;
        EYESCANTRIGGER       : in std_ulogic;
        GTGREFCLK            : in std_ulogic;
        GTHRXN               : in std_ulogic;
        GTHRXP               : in std_ulogic;
        GTNORTHREFCLK0       : in std_ulogic;
        GTNORTHREFCLK1       : in std_ulogic;
        GTREFCLK0            : in std_ulogic;
        GTREFCLK1            : in std_ulogic;
        GTRESETSEL           : in std_ulogic;
        GTRSVD               : in std_logic_vector(15 downto 0);
        GTRXRESET            : in std_ulogic;
        GTSOUTHREFCLK0       : in std_ulogic;
        GTSOUTHREFCLK1       : in std_ulogic;
        GTTXRESET            : in std_ulogic;
        LOOPBACK             : in std_logic_vector(2 downto 0);
        PCSRSVDIN            : in std_logic_vector(15 downto 0);
        PCSRSVDIN2           : in std_logic_vector(4 downto 0);
        PMARSVDIN            : in std_logic_vector(4 downto 0);
        QPLLCLK              : in std_ulogic;
        QPLLREFCLK           : in std_ulogic;
        RESETOVRD            : in std_ulogic;
        RX8B10BEN            : in std_ulogic;
        RXADAPTSELTEST       : in std_logic_vector(13 downto 0);
        RXBUFRESET           : in std_ulogic;
        RXCDRFREQRESET       : in std_ulogic;
        RXCDRHOLD            : in std_ulogic;
        RXCDROVRDEN          : in std_ulogic;
        RXCDRRESET           : in std_ulogic;
        RXCDRRESETRSV        : in std_ulogic;
        RXCHBONDEN           : in std_ulogic;
        RXCHBONDI            : in std_logic_vector(4 downto 0);
        RXCHBONDLEVEL        : in std_logic_vector(2 downto 0);
        RXCHBONDMASTER       : in std_ulogic;
        RXCHBONDSLAVE        : in std_ulogic;
        RXCOMMADETEN         : in std_ulogic;
        RXDDIEN              : in std_ulogic;
        RXDFEAGCHOLD         : in std_ulogic;
        RXDFEAGCOVRDEN       : in std_ulogic;
        RXDFEAGCTRL          : in std_logic_vector(4 downto 0);
        RXDFECM1EN           : in std_ulogic;
        RXDFELFHOLD          : in std_ulogic;
        RXDFELFOVRDEN        : in std_ulogic;
        RXDFELPMRESET        : in std_ulogic;
        RXDFESLIDETAP        : in std_logic_vector(4 downto 0);
        RXDFESLIDETAPADAPTEN : in std_ulogic;
        RXDFESLIDETAPHOLD    : in std_ulogic;
        RXDFESLIDETAPID      : in std_logic_vector(5 downto 0);
        RXDFESLIDETAPINITOVRDEN : in std_ulogic;
        RXDFESLIDETAPONLYADAPTEN : in std_ulogic;
        RXDFESLIDETAPOVRDEN  : in std_ulogic;
        RXDFESLIDETAPSTROBE  : in std_ulogic;
        RXDFETAP2HOLD        : in std_ulogic;
        RXDFETAP2OVRDEN      : in std_ulogic;
        RXDFETAP3HOLD        : in std_ulogic;
        RXDFETAP3OVRDEN      : in std_ulogic;
        RXDFETAP4HOLD        : in std_ulogic;
        RXDFETAP4OVRDEN      : in std_ulogic;
        RXDFETAP5HOLD        : in std_ulogic;
        RXDFETAP5OVRDEN      : in std_ulogic;
        RXDFETAP6HOLD        : in std_ulogic;
        RXDFETAP6OVRDEN      : in std_ulogic;
        RXDFETAP7HOLD        : in std_ulogic;
        RXDFETAP7OVRDEN      : in std_ulogic;
        RXDFEUTHOLD          : in std_ulogic;
        RXDFEUTOVRDEN        : in std_ulogic;
        RXDFEVPHOLD          : in std_ulogic;
        RXDFEVPOVRDEN        : in std_ulogic;
        RXDFEVSEN            : in std_ulogic;
        RXDFEXYDEN           : in std_ulogic;
        RXDLYBYPASS          : in std_ulogic;
        RXDLYEN              : in std_ulogic;
        RXDLYOVRDEN          : in std_ulogic;
        RXDLYSRESET          : in std_ulogic;
        RXELECIDLEMODE       : in std_logic_vector(1 downto 0);
        RXGEARBOXSLIP        : in std_ulogic;
        RXLPMEN              : in std_ulogic;
        RXLPMHFHOLD          : in std_ulogic;
        RXLPMHFOVRDEN        : in std_ulogic;
        RXLPMLFHOLD          : in std_ulogic;
        RXLPMLFKLOVRDEN      : in std_ulogic;
        RXMCOMMAALIGNEN      : in std_ulogic;
        RXMONITORSEL         : in std_logic_vector(1 downto 0);
        RXOOBRESET           : in std_ulogic;
        RXOSCALRESET         : in std_ulogic;
        RXOSHOLD             : in std_ulogic;
        RXOSINTCFG           : in std_logic_vector(3 downto 0);
        RXOSINTEN            : in std_ulogic;
        RXOSINTHOLD          : in std_ulogic;
        RXOSINTID0           : in std_logic_vector(3 downto 0);
        RXOSINTNTRLEN        : in std_ulogic;
        RXOSINTOVRDEN        : in std_ulogic;
        RXOSINTSTROBE        : in std_ulogic;
        RXOSINTTESTOVRDEN    : in std_ulogic;
        RXOSOVRDEN           : in std_ulogic;
        RXOUTCLKSEL          : in std_logic_vector(2 downto 0);
        RXPCOMMAALIGNEN      : in std_ulogic;
        RXPCSRESET           : in std_ulogic;
        RXPD                 : in std_logic_vector(1 downto 0);
        RXPHALIGN            : in std_ulogic;
        RXPHALIGNEN          : in std_ulogic;
        RXPHDLYPD            : in std_ulogic;
        RXPHDLYRESET         : in std_ulogic;
        RXPHOVRDEN           : in std_ulogic;
        RXPMARESET           : in std_ulogic;
        RXPOLARITY           : in std_ulogic;
        RXPRBSCNTRESET       : in std_ulogic;
        RXPRBSSEL            : in std_logic_vector(2 downto 0);
        RXQPIEN              : in std_ulogic;
        RXRATE               : in std_logic_vector(2 downto 0);
        RXRATEMODE           : in std_ulogic;
        RXSLIDE              : in std_ulogic;
        RXSYNCALLIN          : in std_ulogic;
        RXSYNCIN             : in std_ulogic;
        RXSYNCMODE           : in std_ulogic;
        RXSYSCLKSEL          : in std_logic_vector(1 downto 0);
        RXUSERRDY            : in std_ulogic;
        RXUSRCLK             : in std_ulogic;
        RXUSRCLK2            : in std_ulogic;
        SETERRSTATUS         : in std_ulogic;
        SIGVALIDCLK          : in std_ulogic;
        TSTIN                : in std_logic_vector(19 downto 0);
        TX8B10BBYPASS        : in std_logic_vector(7 downto 0);
        TX8B10BEN            : in std_ulogic;
        TXBUFDIFFCTRL        : in std_logic_vector(2 downto 0);
        TXCHARDISPMODE       : in std_logic_vector(7 downto 0);
        TXCHARDISPVAL        : in std_logic_vector(7 downto 0);
        TXCHARISK            : in std_logic_vector(7 downto 0);
        TXCOMINIT            : in std_ulogic;
        TXCOMSAS             : in std_ulogic;
        TXCOMWAKE            : in std_ulogic;
        TXDATA               : in std_logic_vector(63 downto 0);
        TXDEEMPH             : in std_ulogic;
        TXDETECTRX           : in std_ulogic;
        TXDIFFCTRL           : in std_logic_vector(3 downto 0);
        TXDIFFPD             : in std_ulogic;
        TXDLYBYPASS          : in std_ulogic;
        TXDLYEN              : in std_ulogic;
        TXDLYHOLD            : in std_ulogic;
        TXDLYOVRDEN          : in std_ulogic;
        TXDLYSRESET          : in std_ulogic;
        TXDLYUPDOWN          : in std_ulogic;
        TXELECIDLE           : in std_ulogic;
        TXHEADER             : in std_logic_vector(2 downto 0);
        TXINHIBIT            : in std_ulogic;
        TXMAINCURSOR         : in std_logic_vector(6 downto 0);
        TXMARGIN             : in std_logic_vector(2 downto 0);
        TXOUTCLKSEL          : in std_logic_vector(2 downto 0);
        TXPCSRESET           : in std_ulogic;
        TXPD                 : in std_logic_vector(1 downto 0);
        TXPDELECIDLEMODE     : in std_ulogic;
        TXPHALIGN            : in std_ulogic;
        TXPHALIGNEN          : in std_ulogic;
        TXPHDLYPD            : in std_ulogic;
        TXPHDLYRESET         : in std_ulogic;
        TXPHDLYTSTCLK        : in std_ulogic;
        TXPHINIT             : in std_ulogic;
        TXPHOVRDEN           : in std_ulogic;
        TXPIPPMEN            : in std_ulogic;
        TXPIPPMOVRDEN        : in std_ulogic;
        TXPIPPMPD            : in std_ulogic;
        TXPIPPMSEL           : in std_ulogic;
        TXPIPPMSTEPSIZE      : in std_logic_vector(4 downto 0);
        TXPISOPD             : in std_ulogic;
        TXPMARESET           : in std_ulogic;
        TXPOLARITY           : in std_ulogic;
        TXPOSTCURSOR         : in std_logic_vector(4 downto 0);
        TXPOSTCURSORINV      : in std_ulogic;
        TXPRBSFORCEERR       : in std_ulogic;
        TXPRBSSEL            : in std_logic_vector(2 downto 0);
        TXPRECURSOR          : in std_logic_vector(4 downto 0);
        TXPRECURSORINV       : in std_ulogic;
        TXQPIBIASEN          : in std_ulogic;
        TXQPISTRONGPDOWN     : in std_ulogic;
        TXQPIWEAKPUP         : in std_ulogic;
        TXRATE               : in std_logic_vector(2 downto 0);
        TXRATEMODE           : in std_ulogic;
        TXSEQUENCE           : in std_logic_vector(6 downto 0);
        TXSTARTSEQ           : in std_ulogic;
        TXSWING              : in std_ulogic;
        TXSYNCALLIN          : in std_ulogic;
        TXSYNCIN             : in std_ulogic;
        TXSYNCMODE           : in std_ulogic;
        TXSYSCLKSEL          : in std_logic_vector(1 downto 0);
        TXUSERRDY            : in std_ulogic;
        TXUSRCLK             : in std_ulogic;
        TXUSRCLK2            : in std_ulogic        
      );
    end component;
    
    constant IN_DELAY : time := 0 ps;
    constant OUT_DELAY : time := 0 ps;
    constant INCLK_DELAY : time := 0 ps;
    constant OUTCLK_DELAY : time := 0 ps;

    function SUL_TO_STR (sul : std_ulogic)
    return string is
    begin
      if sul = '0' then
        return "0";
      else
        return "1";
      end if;
    end SUL_TO_STR;

    function boolean_to_string(bool: boolean)
    return string is
    begin
      if bool then
        return "TRUE";
      else
        return "FALSE";
      end if;
    end boolean_to_string;

    function getstrlength(in_vec : std_logic_vector)
    return integer is
      variable string_length : integer;
    begin
      if ((in_vec'length mod 4) = 0) then
        string_length := in_vec'length/4;
      elsif ((in_vec'length mod 4) > 0) then
        string_length := in_vec'length/4 + 1;
      end if;
      return string_length;
    end getstrlength;

    -- Convert bit_vector to std_logic_vector
    constant ACJTAG_DEBUG_MODE_BINARY : std_ulogic := To_StduLogic(ACJTAG_DEBUG_MODE);
    constant ACJTAG_MODE_BINARY : std_ulogic := To_StduLogic(ACJTAG_MODE);
    constant ACJTAG_RESET_BINARY : std_ulogic := To_StduLogic(ACJTAG_RESET);
    constant ADAPT_CFG0_BINARY : std_logic_vector(19 downto 0) := To_StdLogicVector(ADAPT_CFG0)(19 downto 0);
    constant ALIGN_COMMA_ENABLE_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(ALIGN_COMMA_ENABLE)(9 downto 0);
    constant ALIGN_MCOMMA_VALUE_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(ALIGN_MCOMMA_VALUE)(9 downto 0);
    constant ALIGN_PCOMMA_VALUE_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(ALIGN_PCOMMA_VALUE)(9 downto 0);
    constant A_RXOSCALRESET_BINARY : std_ulogic := To_StduLogic(A_RXOSCALRESET);
    constant CFOK_CFG2_BINARY : std_logic_vector(5 downto 0) := To_StdLogicVector(CFOK_CFG2)(5 downto 0);
    constant CFOK_CFG3_BINARY : std_logic_vector(5 downto 0) := To_StdLogicVector(CFOK_CFG3)(5 downto 0);
    constant CFOK_CFG_BINARY : std_logic_vector(41 downto 0) := To_StdLogicVector(CFOK_CFG)(41 downto 0);
    constant CHAN_BOND_SEQ_1_1_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_1_1)(9 downto 0);
    constant CHAN_BOND_SEQ_1_2_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_1_2)(9 downto 0);
    constant CHAN_BOND_SEQ_1_3_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_1_3)(9 downto 0);
    constant CHAN_BOND_SEQ_1_4_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_1_4)(9 downto 0);
    constant CHAN_BOND_SEQ_1_ENABLE_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_1_ENABLE)(3 downto 0);
    constant CHAN_BOND_SEQ_2_1_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_2_1)(9 downto 0);
    constant CHAN_BOND_SEQ_2_2_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_2_2)(9 downto 0);
    constant CHAN_BOND_SEQ_2_3_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_2_3)(9 downto 0);
    constant CHAN_BOND_SEQ_2_4_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_2_4)(9 downto 0);
    constant CHAN_BOND_SEQ_2_ENABLE_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(CHAN_BOND_SEQ_2_ENABLE)(3 downto 0);
    constant CLK_COR_SEQ_1_1_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CLK_COR_SEQ_1_1)(9 downto 0);
    constant CLK_COR_SEQ_1_2_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CLK_COR_SEQ_1_2)(9 downto 0);
    constant CLK_COR_SEQ_1_3_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CLK_COR_SEQ_1_3)(9 downto 0);
    constant CLK_COR_SEQ_1_4_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CLK_COR_SEQ_1_4)(9 downto 0);
    constant CLK_COR_SEQ_1_ENABLE_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(CLK_COR_SEQ_1_ENABLE)(3 downto 0);
    constant CLK_COR_SEQ_2_1_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CLK_COR_SEQ_2_1)(9 downto 0);
    constant CLK_COR_SEQ_2_2_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CLK_COR_SEQ_2_2)(9 downto 0);
    constant CLK_COR_SEQ_2_3_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CLK_COR_SEQ_2_3)(9 downto 0);
    constant CLK_COR_SEQ_2_4_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(CLK_COR_SEQ_2_4)(9 downto 0);
    constant CLK_COR_SEQ_2_ENABLE_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(CLK_COR_SEQ_2_ENABLE)(3 downto 0);
    constant CPLL_CFG_BINARY : std_logic_vector(28 downto 0) := To_StdLogicVector(CPLL_CFG)(28 downto 0);
    constant CPLL_INIT_CFG_BINARY : std_logic_vector(23 downto 0) := To_StdLogicVector(CPLL_INIT_CFG)(23 downto 0);
    constant CPLL_LOCK_CFG_BINARY : std_logic_vector(15 downto 0) := To_StdLogicVector(CPLL_LOCK_CFG)(15 downto 0);
    constant DMONITOR_CFG_BINARY : std_logic_vector(23 downto 0) := To_StdLogicVector(DMONITOR_CFG)(23 downto 0);
    constant ES_CLK_PHASE_SEL_BINARY : std_ulogic := To_StduLogic(ES_CLK_PHASE_SEL);
    constant ES_CONTROL_BINARY : std_logic_vector(5 downto 0) := To_StdLogicVector(ES_CONTROL)(5 downto 0);
    constant ES_HORZ_OFFSET_BINARY : std_logic_vector(11 downto 0) := To_StdLogicVector(ES_HORZ_OFFSET)(11 downto 0);
    constant ES_PMA_CFG_BINARY : std_logic_vector(9 downto 0) := To_StdLogicVector(ES_PMA_CFG)(9 downto 0);
    constant ES_PRESCALE_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(ES_PRESCALE)(4 downto 0);
    constant ES_QUALIFIER_BINARY : std_logic_vector(79 downto 0) := To_StdLogicVector(ES_QUALIFIER)(79 downto 0);
    constant ES_QUAL_MASK_BINARY : std_logic_vector(79 downto 0) := To_StdLogicVector(ES_QUAL_MASK)(79 downto 0);
    constant ES_SDATA_MASK_BINARY : std_logic_vector(79 downto 0) := To_StdLogicVector(ES_SDATA_MASK)(79 downto 0);
    constant ES_VERT_OFFSET_BINARY : std_logic_vector(8 downto 0) := To_StdLogicVector(ES_VERT_OFFSET)(8 downto 0);
    constant FTS_DESKEW_SEQ_ENABLE_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(FTS_DESKEW_SEQ_ENABLE)(3 downto 0);
    constant FTS_LANE_DESKEW_CFG_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(FTS_LANE_DESKEW_CFG)(3 downto 0);
    constant GEARBOX_MODE_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(GEARBOX_MODE)(2 downto 0);
    constant LOOPBACK_CFG_BINARY : std_ulogic := To_StduLogic(LOOPBACK_CFG);
    constant OUTREFCLK_SEL_INV_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(OUTREFCLK_SEL_INV)(1 downto 0);
    constant PCS_RSVD_ATTR_BINARY : std_logic_vector(47 downto 0) := To_StdLogicVector(PCS_RSVD_ATTR)(47 downto 0);
    constant PD_TRANS_TIME_FROM_P2_BINARY : std_logic_vector(11 downto 0) := To_StdLogicVector(PD_TRANS_TIME_FROM_P2)(11 downto 0);
    constant PD_TRANS_TIME_NONE_P2_BINARY : std_logic_vector(7 downto 0) := To_StdLogicVector(PD_TRANS_TIME_NONE_P2)(7 downto 0);
    constant PD_TRANS_TIME_TO_P2_BINARY : std_logic_vector(7 downto 0) := To_StdLogicVector(PD_TRANS_TIME_TO_P2)(7 downto 0);
    constant PMA_RSV2_BINARY : std_logic_vector(31 downto 0) := To_StdLogicVector(PMA_RSV2)(31 downto 0);
    constant PMA_RSV3_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(PMA_RSV3)(1 downto 0);
    constant PMA_RSV4_BINARY : std_logic_vector(14 downto 0) := To_StdLogicVector(PMA_RSV4)(14 downto 0);
    constant PMA_RSV5_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(PMA_RSV5)(3 downto 0);
    constant PMA_RSV_BINARY : std_logic_vector(31 downto 0) := To_StdLogicVector(PMA_RSV)(31 downto 0);
    constant RESET_POWERSAVE_DISABLE_BINARY : std_ulogic := To_StduLogic(RESET_POWERSAVE_DISABLE);
    constant RXBUFRESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXBUFRESET_TIME)(4 downto 0);
    constant RXBUF_EIDLE_HI_CNT_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(RXBUF_EIDLE_HI_CNT)(3 downto 0);
    constant RXBUF_EIDLE_LO_CNT_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(RXBUF_EIDLE_LO_CNT)(3 downto 0);
    constant RXCDRFREQRESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXCDRFREQRESET_TIME)(4 downto 0);
    constant RXCDRPHRESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXCDRPHRESET_TIME)(4 downto 0);
    constant RXCDR_CFG_BINARY : std_logic_vector(82 downto 0) := To_StdLogicVector(RXCDR_CFG)(82 downto 0);
    constant RXCDR_FR_RESET_ON_EIDLE_BINARY : std_ulogic := To_StduLogic(RXCDR_FR_RESET_ON_EIDLE);
    constant RXCDR_HOLD_DURING_EIDLE_BINARY : std_ulogic := To_StduLogic(RXCDR_HOLD_DURING_EIDLE);
    constant RXCDR_LOCK_CFG_BINARY : std_logic_vector(5 downto 0) := To_StdLogicVector(RXCDR_LOCK_CFG)(5 downto 0);
    constant RXCDR_PH_RESET_ON_EIDLE_BINARY : std_ulogic := To_StduLogic(RXCDR_PH_RESET_ON_EIDLE);
    constant RXDFELPMRESET_TIME_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(RXDFELPMRESET_TIME)(6 downto 0);
    constant RXDLY_CFG_BINARY : std_logic_vector(15 downto 0) := To_StdLogicVector(RXDLY_CFG)(15 downto 0);
    constant RXDLY_LCFG_BINARY : std_logic_vector(8 downto 0) := To_StdLogicVector(RXDLY_LCFG)(8 downto 0);
    constant RXDLY_TAP_CFG_BINARY : std_logic_vector(15 downto 0) := To_StdLogicVector(RXDLY_TAP_CFG)(15 downto 0);
    constant RXISCANRESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXISCANRESET_TIME)(4 downto 0);
    constant RXLPM_HF_CFG_BINARY : std_logic_vector(13 downto 0) := To_StdLogicVector(RXLPM_HF_CFG)(13 downto 0);
    constant RXLPM_LF_CFG_BINARY : std_logic_vector(17 downto 0) := To_StdLogicVector(RXLPM_LF_CFG)(17 downto 0);
    constant RXOOB_CFG_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(RXOOB_CFG)(6 downto 0);
    constant RXOSCALRESET_TIMEOUT_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXOSCALRESET_TIMEOUT)(4 downto 0);
    constant RXOSCALRESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXOSCALRESET_TIME)(4 downto 0);
    constant RXPCSRESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXPCSRESET_TIME)(4 downto 0);
    constant RXPHDLY_CFG_BINARY : std_logic_vector(23 downto 0) := To_StdLogicVector(RXPHDLY_CFG)(23 downto 0);
    constant RXPH_CFG_BINARY : std_logic_vector(23 downto 0) := To_StdLogicVector(RXPH_CFG)(23 downto 0);
    constant RXPH_MONITOR_SEL_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXPH_MONITOR_SEL)(4 downto 0);
    constant RXPI_CFG0_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(RXPI_CFG0)(1 downto 0);
    constant RXPI_CFG1_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(RXPI_CFG1)(1 downto 0);
    constant RXPI_CFG2_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(RXPI_CFG2)(1 downto 0);
    constant RXPI_CFG3_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(RXPI_CFG3)(1 downto 0);
    constant RXPI_CFG4_BINARY : std_ulogic := To_StduLogic(RXPI_CFG4);
    constant RXPI_CFG5_BINARY : std_ulogic := To_StduLogic(RXPI_CFG5);
    constant RXPI_CFG6_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(RXPI_CFG6)(2 downto 0);
    constant RXPMARESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(RXPMARESET_TIME)(4 downto 0);
    constant RXPRBS_ERR_LOOPBACK_BINARY : std_ulogic := To_StduLogic(RXPRBS_ERR_LOOPBACK);
    constant RXSYNC_MULTILANE_BINARY : std_ulogic := To_StduLogic(RXSYNC_MULTILANE);
    constant RXSYNC_OVRD_BINARY : std_ulogic := To_StduLogic(RXSYNC_OVRD);
    constant RXSYNC_SKIP_DA_BINARY : std_ulogic := To_StduLogic(RXSYNC_SKIP_DA);
    constant RX_BIAS_CFG_BINARY : std_logic_vector(23 downto 0) := To_StdLogicVector(RX_BIAS_CFG)(23 downto 0);
    constant RX_BUFFER_CFG_BINARY : std_logic_vector(5 downto 0) := To_StdLogicVector(RX_BUFFER_CFG)(5 downto 0);
    constant RX_CLKMUX_PD_BINARY : std_ulogic := To_StduLogic(RX_CLKMUX_PD);
    constant RX_CM_SEL_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(RX_CM_SEL)(1 downto 0);
    constant RX_CM_TRIM_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(RX_CM_TRIM)(3 downto 0);
    constant RX_DDI_SEL_BINARY : std_logic_vector(5 downto 0) := To_StdLogicVector(RX_DDI_SEL)(5 downto 0);
    constant RX_DEBUG_CFG_BINARY : std_logic_vector(13 downto 0) := To_StdLogicVector(RX_DEBUG_CFG)(13 downto 0);
    constant RX_DFELPM_CFG0_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(RX_DFELPM_CFG0)(3 downto 0);
    constant RX_DFELPM_CFG1_BINARY : std_ulogic := To_StduLogic(RX_DFELPM_CFG1);
    constant RX_DFELPM_KLKH_AGC_STUP_EN_BINARY : std_ulogic := To_StduLogic(RX_DFELPM_KLKH_AGC_STUP_EN);
    constant RX_DFE_AGC_CFG0_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(RX_DFE_AGC_CFG0)(1 downto 0);
    constant RX_DFE_AGC_CFG1_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(RX_DFE_AGC_CFG1)(2 downto 0);
    constant RX_DFE_AGC_CFG2_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(RX_DFE_AGC_CFG2)(3 downto 0);
    constant RX_DFE_AGC_OVRDEN_BINARY : std_ulogic := To_StduLogic(RX_DFE_AGC_OVRDEN);
    constant RX_DFE_GAIN_CFG_BINARY : std_logic_vector(22 downto 0) := To_StdLogicVector(RX_DFE_GAIN_CFG)(22 downto 0);
    constant RX_DFE_H2_CFG_BINARY : std_logic_vector(11 downto 0) := To_StdLogicVector(RX_DFE_H2_CFG)(11 downto 0);
    constant RX_DFE_H3_CFG_BINARY : std_logic_vector(11 downto 0) := To_StdLogicVector(RX_DFE_H3_CFG)(11 downto 0);
    constant RX_DFE_H4_CFG_BINARY : std_logic_vector(10 downto 0) := To_StdLogicVector(RX_DFE_H4_CFG)(10 downto 0);
    constant RX_DFE_H5_CFG_BINARY : std_logic_vector(10 downto 0) := To_StdLogicVector(RX_DFE_H5_CFG)(10 downto 0);
    constant RX_DFE_H6_CFG_BINARY : std_logic_vector(10 downto 0) := To_StdLogicVector(RX_DFE_H6_CFG)(10 downto 0);
    constant RX_DFE_H7_CFG_BINARY : std_logic_vector(10 downto 0) := To_StdLogicVector(RX_DFE_H7_CFG)(10 downto 0);
    constant RX_DFE_KL_CFG_BINARY : std_logic_vector(32 downto 0) := To_StdLogicVector(RX_DFE_KL_CFG)(32 downto 0);
    constant RX_DFE_KL_LPM_KH_CFG0_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(RX_DFE_KL_LPM_KH_CFG0)(1 downto 0);
    constant RX_DFE_KL_LPM_KH_CFG1_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(RX_DFE_KL_LPM_KH_CFG1)(2 downto 0);
    constant RX_DFE_KL_LPM_KH_CFG2_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(RX_DFE_KL_LPM_KH_CFG2)(3 downto 0);
    constant RX_DFE_KL_LPM_KH_OVRDEN_BINARY : std_ulogic := To_StduLogic(RX_DFE_KL_LPM_KH_OVRDEN);
    constant RX_DFE_KL_LPM_KL_CFG0_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(RX_DFE_KL_LPM_KL_CFG0)(1 downto 0);
    constant RX_DFE_KL_LPM_KL_CFG1_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(RX_DFE_KL_LPM_KL_CFG1)(2 downto 0);
    constant RX_DFE_KL_LPM_KL_CFG2_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(RX_DFE_KL_LPM_KL_CFG2)(3 downto 0);
    constant RX_DFE_KL_LPM_KL_OVRDEN_BINARY : std_ulogic := To_StduLogic(RX_DFE_KL_LPM_KL_OVRDEN);
    constant RX_DFE_LPM_CFG_BINARY : std_logic_vector(15 downto 0) := To_StdLogicVector(RX_DFE_LPM_CFG)(15 downto 0);
    constant RX_DFE_LPM_HOLD_DURING_EIDLE_BINARY : std_ulogic := To_StduLogic(RX_DFE_LPM_HOLD_DURING_EIDLE);
    constant RX_DFE_ST_CFG_BINARY : std_logic_vector(53 downto 0) := To_StdLogicVector(RX_DFE_ST_CFG)(53 downto 0);
    constant RX_DFE_UT_CFG_BINARY : std_logic_vector(16 downto 0) := To_StdLogicVector(RX_DFE_UT_CFG)(16 downto 0);
    constant RX_DFE_VP_CFG_BINARY : std_logic_vector(16 downto 0) := To_StdLogicVector(RX_DFE_VP_CFG)(16 downto 0);
    constant RX_OS_CFG_BINARY : std_logic_vector(12 downto 0) := To_StdLogicVector(RX_OS_CFG)(12 downto 0);
    constant SATA_BURST_SEQ_LEN_BINARY : std_logic_vector(3 downto 0) := To_StdLogicVector(SATA_BURST_SEQ_LEN)(3 downto 0);
    constant SATA_BURST_VAL_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(SATA_BURST_VAL)(2 downto 0);
    constant SATA_EIDLE_VAL_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(SATA_EIDLE_VAL)(2 downto 0);
    constant SIM_CPLLREFCLK_SEL_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(SIM_CPLLREFCLK_SEL)(2 downto 0);
    constant TERM_RCAL_CFG_BINARY : std_logic_vector(14 downto 0) := To_StdLogicVector(TERM_RCAL_CFG)(14 downto 0);
    constant TERM_RCAL_OVRD_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(TERM_RCAL_OVRD)(2 downto 0);
    constant TRANS_TIME_RATE_BINARY : std_logic_vector(7 downto 0) := To_StdLogicVector(TRANS_TIME_RATE)(7 downto 0);
    constant TST_RSV_BINARY : std_logic_vector(31 downto 0) := To_StdLogicVector(TST_RSV)(31 downto 0);
    constant TXDLY_CFG_BINARY : std_logic_vector(15 downto 0) := To_StdLogicVector(TXDLY_CFG)(15 downto 0);
    constant TXDLY_LCFG_BINARY : std_logic_vector(8 downto 0) := To_StdLogicVector(TXDLY_LCFG)(8 downto 0);
    constant TXDLY_TAP_CFG_BINARY : std_logic_vector(15 downto 0) := To_StdLogicVector(TXDLY_TAP_CFG)(15 downto 0);
    constant TXOOB_CFG_BINARY : std_ulogic := To_StduLogic(TXOOB_CFG);
    constant TXPCSRESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(TXPCSRESET_TIME)(4 downto 0);
    constant TXPHDLY_CFG_BINARY : std_logic_vector(23 downto 0) := To_StdLogicVector(TXPHDLY_CFG)(23 downto 0);
    constant TXPH_CFG_BINARY : std_logic_vector(15 downto 0) := To_StdLogicVector(TXPH_CFG)(15 downto 0);
    constant TXPH_MONITOR_SEL_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(TXPH_MONITOR_SEL)(4 downto 0);
    constant TXPI_CFG0_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(TXPI_CFG0)(1 downto 0);
    constant TXPI_CFG1_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(TXPI_CFG1)(1 downto 0);
    constant TXPI_CFG2_BINARY : std_logic_vector(1 downto 0) := To_StdLogicVector(TXPI_CFG2)(1 downto 0);
    constant TXPI_CFG3_BINARY : std_ulogic := To_StduLogic(TXPI_CFG3);
    constant TXPI_CFG4_BINARY : std_ulogic := To_StduLogic(TXPI_CFG4);
    constant TXPI_CFG5_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(TXPI_CFG5)(2 downto 0);
    constant TXPI_GREY_SEL_BINARY : std_ulogic := To_StduLogic(TXPI_GREY_SEL);
    constant TXPI_INVSTROBE_SEL_BINARY : std_ulogic := To_StduLogic(TXPI_INVSTROBE_SEL);
    constant TXPI_PPM_CFG_BINARY : std_logic_vector(7 downto 0) := To_StdLogicVector(TXPI_PPM_CFG)(7 downto 0);
    constant TXPI_SYNFREQ_PPM_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(TXPI_SYNFREQ_PPM)(2 downto 0);
    constant TXPMARESET_TIME_BINARY : std_logic_vector(4 downto 0) := To_StdLogicVector(TXPMARESET_TIME)(4 downto 0);
    constant TXSYNC_MULTILANE_BINARY : std_ulogic := To_StduLogic(TXSYNC_MULTILANE);
    constant TXSYNC_OVRD_BINARY : std_ulogic := To_StduLogic(TXSYNC_OVRD);
    constant TXSYNC_SKIP_DA_BINARY : std_ulogic := To_StduLogic(TXSYNC_SKIP_DA);
    constant TX_CLKMUX_PD_BINARY : std_ulogic := To_StduLogic(TX_CLKMUX_PD);
    constant TX_DEEMPH0_BINARY : std_logic_vector(5 downto 0) := To_StdLogicVector(TX_DEEMPH0)(5 downto 0);
    constant TX_DEEMPH1_BINARY : std_logic_vector(5 downto 0) := To_StdLogicVector(TX_DEEMPH1)(5 downto 0);
    constant TX_EIDLE_ASSERT_DELAY_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(TX_EIDLE_ASSERT_DELAY)(2 downto 0);
    constant TX_EIDLE_DEASSERT_DELAY_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(TX_EIDLE_DEASSERT_DELAY)(2 downto 0);
    constant TX_MAINCURSOR_SEL_BINARY : std_ulogic := To_StduLogic(TX_MAINCURSOR_SEL);
    constant TX_MARGIN_FULL_0_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_FULL_0)(6 downto 0);
    constant TX_MARGIN_FULL_1_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_FULL_1)(6 downto 0);
    constant TX_MARGIN_FULL_2_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_FULL_2)(6 downto 0);
    constant TX_MARGIN_FULL_3_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_FULL_3)(6 downto 0);
    constant TX_MARGIN_FULL_4_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_FULL_4)(6 downto 0);
    constant TX_MARGIN_LOW_0_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_LOW_0)(6 downto 0);
    constant TX_MARGIN_LOW_1_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_LOW_1)(6 downto 0);
    constant TX_MARGIN_LOW_2_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_LOW_2)(6 downto 0);
    constant TX_MARGIN_LOW_3_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_LOW_3)(6 downto 0);
    constant TX_MARGIN_LOW_4_BINARY : std_logic_vector(6 downto 0) := To_StdLogicVector(TX_MARGIN_LOW_4)(6 downto 0);
    constant TX_QPI_STATUS_EN_BINARY : std_ulogic := To_StduLogic(TX_QPI_STATUS_EN);
    constant TX_RXDETECT_CFG_BINARY : std_logic_vector(13 downto 0) := To_StdLogicVector(TX_RXDETECT_CFG)(13 downto 0);
    constant TX_RXDETECT_PRECHARGE_TIME_BINARY : std_logic_vector(16 downto 0) := To_StdLogicVector(TX_RXDETECT_PRECHARGE_TIME)(16 downto 0);
    constant TX_RXDETECT_REF_BINARY : std_logic_vector(2 downto 0) := To_StdLogicVector(TX_RXDETECT_REF)(2 downto 0);
    constant UCODEER_CLR_BINARY : std_ulogic := To_StduLogic(UCODEER_CLR);
    constant USE_PCS_CLK_PHASE_SEL_BINARY : std_ulogic := To_StduLogic(USE_PCS_CLK_PHASE_SEL);
    
    -- Get String Length
    constant ADAPT_CFG0_STRLEN : integer := getstrlength(ADAPT_CFG0_BINARY);
    constant CFOK_CFG_STRLEN : integer := getstrlength(CFOK_CFG_BINARY);
    constant CPLL_CFG_STRLEN : integer := getstrlength(CPLL_CFG_BINARY);
    constant CPLL_INIT_CFG_STRLEN : integer := getstrlength(CPLL_INIT_CFG_BINARY);
    constant CPLL_LOCK_CFG_STRLEN : integer := getstrlength(CPLL_LOCK_CFG_BINARY);
    constant DMONITOR_CFG_STRLEN : integer := getstrlength(DMONITOR_CFG_BINARY);
    constant ES_HORZ_OFFSET_STRLEN : integer := getstrlength(ES_HORZ_OFFSET_BINARY);
    constant ES_QUALIFIER_STRLEN : integer := getstrlength(ES_QUALIFIER_BINARY);
    constant ES_QUAL_MASK_STRLEN : integer := getstrlength(ES_QUAL_MASK_BINARY);
    constant ES_SDATA_MASK_STRLEN : integer := getstrlength(ES_SDATA_MASK_BINARY);
    constant PCS_RSVD_ATTR_STRLEN : integer := getstrlength(PCS_RSVD_ATTR_BINARY);
    constant PD_TRANS_TIME_FROM_P2_STRLEN : integer := getstrlength(PD_TRANS_TIME_FROM_P2_BINARY);
    constant PD_TRANS_TIME_NONE_P2_STRLEN : integer := getstrlength(PD_TRANS_TIME_NONE_P2_BINARY);
    constant PD_TRANS_TIME_TO_P2_STRLEN : integer := getstrlength(PD_TRANS_TIME_TO_P2_BINARY);
    constant RXCDR_CFG_STRLEN : integer := getstrlength(RXCDR_CFG_BINARY);
    constant RXDLY_CFG_STRLEN : integer := getstrlength(RXDLY_CFG_BINARY);
    constant RXDLY_LCFG_STRLEN : integer := getstrlength(RXDLY_LCFG_BINARY);
    constant RXDLY_TAP_CFG_STRLEN : integer := getstrlength(RXDLY_TAP_CFG_BINARY);
    constant RXPHDLY_CFG_STRLEN : integer := getstrlength(RXPHDLY_CFG_BINARY);
    constant RXPH_CFG_STRLEN : integer := getstrlength(RXPH_CFG_BINARY);
    constant RX_DFE_GAIN_CFG_STRLEN : integer := getstrlength(RX_DFE_GAIN_CFG_BINARY);
    constant RX_DFE_LPM_CFG_STRLEN : integer := getstrlength(RX_DFE_LPM_CFG_BINARY);
    constant RX_DFE_ST_CFG_STRLEN : integer := getstrlength(RX_DFE_ST_CFG_BINARY);
    constant TRANS_TIME_RATE_STRLEN : integer := getstrlength(TRANS_TIME_RATE_BINARY);
    constant TST_RSV_STRLEN : integer := getstrlength(TST_RSV_BINARY);
    constant TXDLY_CFG_STRLEN : integer := getstrlength(TXDLY_CFG_BINARY);
    constant TXDLY_LCFG_STRLEN : integer := getstrlength(TXDLY_LCFG_BINARY);
    constant TXDLY_TAP_CFG_STRLEN : integer := getstrlength(TXDLY_TAP_CFG_BINARY);
    constant TXPHDLY_CFG_STRLEN : integer := getstrlength(TXPHDLY_CFG_BINARY);
    constant TXPH_CFG_STRLEN : integer := getstrlength(TXPH_CFG_BINARY);
    constant TX_RXDETECT_CFG_STRLEN : integer := getstrlength(TX_RXDETECT_CFG_BINARY);
    constant TX_RXDETECT_PRECHARGE_TIME_STRLEN : integer := getstrlength(TX_RXDETECT_PRECHARGE_TIME_BINARY);
    
    -- Convert std_logic_vector to string
    constant ACJTAG_DEBUG_MODE_STRING : string := SUL_TO_STR(ACJTAG_DEBUG_MODE_BINARY);
    constant ACJTAG_MODE_STRING : string := SUL_TO_STR(ACJTAG_MODE_BINARY);
    constant ACJTAG_RESET_STRING : string := SUL_TO_STR(ACJTAG_RESET_BINARY);
    constant ADAPT_CFG0_STRING : string := SLV_TO_HEX(ADAPT_CFG0_BINARY, ADAPT_CFG0_STRLEN);
    constant ALIGN_COMMA_ENABLE_STRING : string := SLV_TO_STR(ALIGN_COMMA_ENABLE_BINARY);
    constant ALIGN_MCOMMA_VALUE_STRING : string := SLV_TO_STR(ALIGN_MCOMMA_VALUE_BINARY);
    constant ALIGN_PCOMMA_VALUE_STRING : string := SLV_TO_STR(ALIGN_PCOMMA_VALUE_BINARY);
    constant A_RXOSCALRESET_STRING : string := SUL_TO_STR(A_RXOSCALRESET_BINARY);
    constant CFOK_CFG2_STRING : string := SLV_TO_STR(CFOK_CFG2_BINARY);
    constant CFOK_CFG3_STRING : string := SLV_TO_STR(CFOK_CFG3_BINARY);
    constant CFOK_CFG_STRING : string := SLV_TO_HEX(CFOK_CFG_BINARY, CFOK_CFG_STRLEN);
    constant CHAN_BOND_SEQ_1_1_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_1_1_BINARY);
    constant CHAN_BOND_SEQ_1_2_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_1_2_BINARY);
    constant CHAN_BOND_SEQ_1_3_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_1_3_BINARY);
    constant CHAN_BOND_SEQ_1_4_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_1_4_BINARY);
    constant CHAN_BOND_SEQ_1_ENABLE_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_1_ENABLE_BINARY);
    constant CHAN_BOND_SEQ_2_1_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_2_1_BINARY);
    constant CHAN_BOND_SEQ_2_2_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_2_2_BINARY);
    constant CHAN_BOND_SEQ_2_3_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_2_3_BINARY);
    constant CHAN_BOND_SEQ_2_4_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_2_4_BINARY);
    constant CHAN_BOND_SEQ_2_ENABLE_STRING : string := SLV_TO_STR(CHAN_BOND_SEQ_2_ENABLE_BINARY);
    constant CLK_COR_SEQ_1_1_STRING : string := SLV_TO_STR(CLK_COR_SEQ_1_1_BINARY);
    constant CLK_COR_SEQ_1_2_STRING : string := SLV_TO_STR(CLK_COR_SEQ_1_2_BINARY);
    constant CLK_COR_SEQ_1_3_STRING : string := SLV_TO_STR(CLK_COR_SEQ_1_3_BINARY);
    constant CLK_COR_SEQ_1_4_STRING : string := SLV_TO_STR(CLK_COR_SEQ_1_4_BINARY);
    constant CLK_COR_SEQ_1_ENABLE_STRING : string := SLV_TO_STR(CLK_COR_SEQ_1_ENABLE_BINARY);
    constant CLK_COR_SEQ_2_1_STRING : string := SLV_TO_STR(CLK_COR_SEQ_2_1_BINARY);
    constant CLK_COR_SEQ_2_2_STRING : string := SLV_TO_STR(CLK_COR_SEQ_2_2_BINARY);
    constant CLK_COR_SEQ_2_3_STRING : string := SLV_TO_STR(CLK_COR_SEQ_2_3_BINARY);
    constant CLK_COR_SEQ_2_4_STRING : string := SLV_TO_STR(CLK_COR_SEQ_2_4_BINARY);
    constant CLK_COR_SEQ_2_ENABLE_STRING : string := SLV_TO_STR(CLK_COR_SEQ_2_ENABLE_BINARY);
    constant CPLL_CFG_STRING : string := SLV_TO_HEX(CPLL_CFG_BINARY, CPLL_CFG_STRLEN);
    constant CPLL_INIT_CFG_STRING : string := SLV_TO_HEX(CPLL_INIT_CFG_BINARY, CPLL_INIT_CFG_STRLEN);
    constant CPLL_LOCK_CFG_STRING : string := SLV_TO_HEX(CPLL_LOCK_CFG_BINARY, CPLL_LOCK_CFG_STRLEN);
    constant DMONITOR_CFG_STRING : string := SLV_TO_HEX(DMONITOR_CFG_BINARY, DMONITOR_CFG_STRLEN);
    constant ES_CLK_PHASE_SEL_STRING : string := SUL_TO_STR(ES_CLK_PHASE_SEL_BINARY);
    constant ES_CONTROL_STRING : string := SLV_TO_STR(ES_CONTROL_BINARY);
    constant ES_HORZ_OFFSET_STRING : string := SLV_TO_HEX(ES_HORZ_OFFSET_BINARY, ES_HORZ_OFFSET_STRLEN);
    constant ES_PMA_CFG_STRING : string := SLV_TO_STR(ES_PMA_CFG_BINARY);
    constant ES_PRESCALE_STRING : string := SLV_TO_STR(ES_PRESCALE_BINARY);
    constant ES_QUALIFIER_STRING : string := SLV_TO_HEX(ES_QUALIFIER_BINARY, ES_QUALIFIER_STRLEN);
    constant ES_QUAL_MASK_STRING : string := SLV_TO_HEX(ES_QUAL_MASK_BINARY, ES_QUAL_MASK_STRLEN);
    constant ES_SDATA_MASK_STRING : string := SLV_TO_HEX(ES_SDATA_MASK_BINARY, ES_SDATA_MASK_STRLEN);
    constant ES_VERT_OFFSET_STRING : string := SLV_TO_STR(ES_VERT_OFFSET_BINARY);
    constant FTS_DESKEW_SEQ_ENABLE_STRING : string := SLV_TO_STR(FTS_DESKEW_SEQ_ENABLE_BINARY);
    constant FTS_LANE_DESKEW_CFG_STRING : string := SLV_TO_STR(FTS_LANE_DESKEW_CFG_BINARY);
    constant GEARBOX_MODE_STRING : string := SLV_TO_STR(GEARBOX_MODE_BINARY);
    constant LOOPBACK_CFG_STRING : string := SUL_TO_STR(LOOPBACK_CFG_BINARY);
    constant OUTREFCLK_SEL_INV_STRING : string := SLV_TO_STR(OUTREFCLK_SEL_INV_BINARY);
    constant PCS_RSVD_ATTR_STRING : string := SLV_TO_HEX(PCS_RSVD_ATTR_BINARY, PCS_RSVD_ATTR_STRLEN);
    constant PD_TRANS_TIME_FROM_P2_STRING : string := SLV_TO_HEX(PD_TRANS_TIME_FROM_P2_BINARY, PD_TRANS_TIME_FROM_P2_STRLEN);
    constant PD_TRANS_TIME_NONE_P2_STRING : string := SLV_TO_HEX(PD_TRANS_TIME_NONE_P2_BINARY, PD_TRANS_TIME_NONE_P2_STRLEN);
    constant PD_TRANS_TIME_TO_P2_STRING : string := SLV_TO_HEX(PD_TRANS_TIME_TO_P2_BINARY, PD_TRANS_TIME_TO_P2_STRLEN);
    constant PMA_RSV2_STRING : string := SLV_TO_STR(PMA_RSV2_BINARY);
    constant PMA_RSV3_STRING : string := SLV_TO_STR(PMA_RSV3_BINARY);
    constant PMA_RSV4_STRING : string := SLV_TO_STR(PMA_RSV4_BINARY);
    constant PMA_RSV5_STRING : string := SLV_TO_STR(PMA_RSV5_BINARY);
    constant PMA_RSV_STRING : string := SLV_TO_STR(PMA_RSV_BINARY);
    constant RESET_POWERSAVE_DISABLE_STRING : string := SUL_TO_STR(RESET_POWERSAVE_DISABLE_BINARY);
    constant RXBUFRESET_TIME_STRING : string := SLV_TO_STR(RXBUFRESET_TIME_BINARY);
    constant RXBUF_EIDLE_HI_CNT_STRING : string := SLV_TO_STR(RXBUF_EIDLE_HI_CNT_BINARY);
    constant RXBUF_EIDLE_LO_CNT_STRING : string := SLV_TO_STR(RXBUF_EIDLE_LO_CNT_BINARY);
    constant RXCDRFREQRESET_TIME_STRING : string := SLV_TO_STR(RXCDRFREQRESET_TIME_BINARY);
    constant RXCDRPHRESET_TIME_STRING : string := SLV_TO_STR(RXCDRPHRESET_TIME_BINARY);
    constant RXCDR_CFG_STRING : string := SLV_TO_HEX(RXCDR_CFG_BINARY, RXCDR_CFG_STRLEN);
    constant RXCDR_FR_RESET_ON_EIDLE_STRING : string := SUL_TO_STR(RXCDR_FR_RESET_ON_EIDLE_BINARY);
    constant RXCDR_HOLD_DURING_EIDLE_STRING : string := SUL_TO_STR(RXCDR_HOLD_DURING_EIDLE_BINARY);
    constant RXCDR_LOCK_CFG_STRING : string := SLV_TO_STR(RXCDR_LOCK_CFG_BINARY);
    constant RXCDR_PH_RESET_ON_EIDLE_STRING : string := SUL_TO_STR(RXCDR_PH_RESET_ON_EIDLE_BINARY);
    constant RXDFELPMRESET_TIME_STRING : string := SLV_TO_STR(RXDFELPMRESET_TIME_BINARY);
    constant RXDLY_CFG_STRING : string := SLV_TO_HEX(RXDLY_CFG_BINARY, RXDLY_CFG_STRLEN);
    constant RXDLY_LCFG_STRING : string := SLV_TO_HEX(RXDLY_LCFG_BINARY, RXDLY_LCFG_STRLEN);
    constant RXDLY_TAP_CFG_STRING : string := SLV_TO_HEX(RXDLY_TAP_CFG_BINARY, RXDLY_TAP_CFG_STRLEN);
    constant RXISCANRESET_TIME_STRING : string := SLV_TO_STR(RXISCANRESET_TIME_BINARY);
    constant RXLPM_HF_CFG_STRING : string := SLV_TO_STR(RXLPM_HF_CFG_BINARY);
    constant RXLPM_LF_CFG_STRING : string := SLV_TO_STR(RXLPM_LF_CFG_BINARY);
    constant RXOOB_CFG_STRING : string := SLV_TO_STR(RXOOB_CFG_BINARY);
    constant RXOSCALRESET_TIMEOUT_STRING : string := SLV_TO_STR(RXOSCALRESET_TIMEOUT_BINARY);
    constant RXOSCALRESET_TIME_STRING : string := SLV_TO_STR(RXOSCALRESET_TIME_BINARY);
    constant RXPCSRESET_TIME_STRING : string := SLV_TO_STR(RXPCSRESET_TIME_BINARY);
    constant RXPHDLY_CFG_STRING : string := SLV_TO_HEX(RXPHDLY_CFG_BINARY, RXPHDLY_CFG_STRLEN);
    constant RXPH_CFG_STRING : string := SLV_TO_HEX(RXPH_CFG_BINARY, RXPH_CFG_STRLEN);
    constant RXPH_MONITOR_SEL_STRING : string := SLV_TO_STR(RXPH_MONITOR_SEL_BINARY);
    constant RXPI_CFG0_STRING : string := SLV_TO_STR(RXPI_CFG0_BINARY);
    constant RXPI_CFG1_STRING : string := SLV_TO_STR(RXPI_CFG1_BINARY);
    constant RXPI_CFG2_STRING : string := SLV_TO_STR(RXPI_CFG2_BINARY);
    constant RXPI_CFG3_STRING : string := SLV_TO_STR(RXPI_CFG3_BINARY);
    constant RXPI_CFG4_STRING : string := SUL_TO_STR(RXPI_CFG4_BINARY);
    constant RXPI_CFG5_STRING : string := SUL_TO_STR(RXPI_CFG5_BINARY);
    constant RXPI_CFG6_STRING : string := SLV_TO_STR(RXPI_CFG6_BINARY);
    constant RXPMARESET_TIME_STRING : string := SLV_TO_STR(RXPMARESET_TIME_BINARY);
    constant RXPRBS_ERR_LOOPBACK_STRING : string := SUL_TO_STR(RXPRBS_ERR_LOOPBACK_BINARY);
    constant RXSYNC_MULTILANE_STRING : string := SUL_TO_STR(RXSYNC_MULTILANE_BINARY);
    constant RXSYNC_OVRD_STRING : string := SUL_TO_STR(RXSYNC_OVRD_BINARY);
    constant RXSYNC_SKIP_DA_STRING : string := SUL_TO_STR(RXSYNC_SKIP_DA_BINARY);
    constant RX_BIAS_CFG_STRING : string := SLV_TO_STR(RX_BIAS_CFG_BINARY);
    constant RX_BUFFER_CFG_STRING : string := SLV_TO_STR(RX_BUFFER_CFG_BINARY);
    constant RX_CLKMUX_PD_STRING : string := SUL_TO_STR(RX_CLKMUX_PD_BINARY);
    constant RX_CM_SEL_STRING : string := SLV_TO_STR(RX_CM_SEL_BINARY);
    constant RX_CM_TRIM_STRING : string := SLV_TO_STR(RX_CM_TRIM_BINARY);
    constant RX_DDI_SEL_STRING : string := SLV_TO_STR(RX_DDI_SEL_BINARY);
    constant RX_DEBUG_CFG_STRING : string := SLV_TO_STR(RX_DEBUG_CFG_BINARY);
    constant RX_DFELPM_CFG0_STRING : string := SLV_TO_STR(RX_DFELPM_CFG0_BINARY);
    constant RX_DFELPM_CFG1_STRING : string := SUL_TO_STR(RX_DFELPM_CFG1_BINARY);
    constant RX_DFELPM_KLKH_AGC_STUP_EN_STRING : string := SUL_TO_STR(RX_DFELPM_KLKH_AGC_STUP_EN_BINARY);
    constant RX_DFE_AGC_CFG0_STRING : string := SLV_TO_STR(RX_DFE_AGC_CFG0_BINARY);
    constant RX_DFE_AGC_CFG1_STRING : string := SLV_TO_STR(RX_DFE_AGC_CFG1_BINARY);
    constant RX_DFE_AGC_CFG2_STRING : string := SLV_TO_STR(RX_DFE_AGC_CFG2_BINARY);
    constant RX_DFE_AGC_OVRDEN_STRING : string := SUL_TO_STR(RX_DFE_AGC_OVRDEN_BINARY);
    constant RX_DFE_GAIN_CFG_STRING : string := SLV_TO_HEX(RX_DFE_GAIN_CFG_BINARY, RX_DFE_GAIN_CFG_STRLEN);
    constant RX_DFE_H2_CFG_STRING : string := SLV_TO_STR(RX_DFE_H2_CFG_BINARY);
    constant RX_DFE_H3_CFG_STRING : string := SLV_TO_STR(RX_DFE_H3_CFG_BINARY);
    constant RX_DFE_H4_CFG_STRING : string := SLV_TO_STR(RX_DFE_H4_CFG_BINARY);
    constant RX_DFE_H5_CFG_STRING : string := SLV_TO_STR(RX_DFE_H5_CFG_BINARY);
    constant RX_DFE_H6_CFG_STRING : string := SLV_TO_STR(RX_DFE_H6_CFG_BINARY);
    constant RX_DFE_H7_CFG_STRING : string := SLV_TO_STR(RX_DFE_H7_CFG_BINARY);
    constant RX_DFE_KL_CFG_STRING : string := SLV_TO_STR(RX_DFE_KL_CFG_BINARY);
    constant RX_DFE_KL_LPM_KH_CFG0_STRING : string := SLV_TO_STR(RX_DFE_KL_LPM_KH_CFG0_BINARY);
    constant RX_DFE_KL_LPM_KH_CFG1_STRING : string := SLV_TO_STR(RX_DFE_KL_LPM_KH_CFG1_BINARY);
    constant RX_DFE_KL_LPM_KH_CFG2_STRING : string := SLV_TO_STR(RX_DFE_KL_LPM_KH_CFG2_BINARY);
    constant RX_DFE_KL_LPM_KH_OVRDEN_STRING : string := SUL_TO_STR(RX_DFE_KL_LPM_KH_OVRDEN_BINARY);
    constant RX_DFE_KL_LPM_KL_CFG0_STRING : string := SLV_TO_STR(RX_DFE_KL_LPM_KL_CFG0_BINARY);
    constant RX_DFE_KL_LPM_KL_CFG1_STRING : string := SLV_TO_STR(RX_DFE_KL_LPM_KL_CFG1_BINARY);
    constant RX_DFE_KL_LPM_KL_CFG2_STRING : string := SLV_TO_STR(RX_DFE_KL_LPM_KL_CFG2_BINARY);
    constant RX_DFE_KL_LPM_KL_OVRDEN_STRING : string := SUL_TO_STR(RX_DFE_KL_LPM_KL_OVRDEN_BINARY);
    constant RX_DFE_LPM_CFG_STRING : string := SLV_TO_HEX(RX_DFE_LPM_CFG_BINARY, RX_DFE_LPM_CFG_STRLEN);
    constant RX_DFE_LPM_HOLD_DURING_EIDLE_STRING : string := SUL_TO_STR(RX_DFE_LPM_HOLD_DURING_EIDLE_BINARY);
    constant RX_DFE_ST_CFG_STRING : string := SLV_TO_HEX(RX_DFE_ST_CFG_BINARY, RX_DFE_ST_CFG_STRLEN);
    constant RX_DFE_UT_CFG_STRING : string := SLV_TO_STR(RX_DFE_UT_CFG_BINARY);
    constant RX_DFE_VP_CFG_STRING : string := SLV_TO_STR(RX_DFE_VP_CFG_BINARY);
    constant RX_OS_CFG_STRING : string := SLV_TO_STR(RX_OS_CFG_BINARY);
    constant SATA_BURST_SEQ_LEN_STRING : string := SLV_TO_STR(SATA_BURST_SEQ_LEN_BINARY);
    constant SATA_BURST_VAL_STRING : string := SLV_TO_STR(SATA_BURST_VAL_BINARY);
    constant SATA_EIDLE_VAL_STRING : string := SLV_TO_STR(SATA_EIDLE_VAL_BINARY);
    constant SIM_CPLLREFCLK_SEL_STRING : string := SLV_TO_STR(SIM_CPLLREFCLK_SEL_BINARY);
    constant TERM_RCAL_CFG_STRING : string := SLV_TO_STR(TERM_RCAL_CFG_BINARY);
    constant TERM_RCAL_OVRD_STRING : string := SLV_TO_STR(TERM_RCAL_OVRD_BINARY);
    constant TRANS_TIME_RATE_STRING : string := SLV_TO_HEX(TRANS_TIME_RATE_BINARY, TRANS_TIME_RATE_STRLEN);
    constant TST_RSV_STRING : string := SLV_TO_HEX(TST_RSV_BINARY, TST_RSV_STRLEN);
    constant TXDLY_CFG_STRING : string := SLV_TO_HEX(TXDLY_CFG_BINARY, TXDLY_CFG_STRLEN);
    constant TXDLY_LCFG_STRING : string := SLV_TO_HEX(TXDLY_LCFG_BINARY, TXDLY_LCFG_STRLEN);
    constant TXDLY_TAP_CFG_STRING : string := SLV_TO_HEX(TXDLY_TAP_CFG_BINARY, TXDLY_TAP_CFG_STRLEN);
    constant TXOOB_CFG_STRING : string := SUL_TO_STR(TXOOB_CFG_BINARY);
    constant TXPCSRESET_TIME_STRING : string := SLV_TO_STR(TXPCSRESET_TIME_BINARY);
    constant TXPHDLY_CFG_STRING : string := SLV_TO_HEX(TXPHDLY_CFG_BINARY, TXPHDLY_CFG_STRLEN);
    constant TXPH_CFG_STRING : string := SLV_TO_HEX(TXPH_CFG_BINARY, TXPH_CFG_STRLEN);
    constant TXPH_MONITOR_SEL_STRING : string := SLV_TO_STR(TXPH_MONITOR_SEL_BINARY);
    constant TXPI_CFG0_STRING : string := SLV_TO_STR(TXPI_CFG0_BINARY);
    constant TXPI_CFG1_STRING : string := SLV_TO_STR(TXPI_CFG1_BINARY);
    constant TXPI_CFG2_STRING : string := SLV_TO_STR(TXPI_CFG2_BINARY);
    constant TXPI_CFG3_STRING : string := SUL_TO_STR(TXPI_CFG3_BINARY);
    constant TXPI_CFG4_STRING : string := SUL_TO_STR(TXPI_CFG4_BINARY);
    constant TXPI_CFG5_STRING : string := SLV_TO_STR(TXPI_CFG5_BINARY);
    constant TXPI_GREY_SEL_STRING : string := SUL_TO_STR(TXPI_GREY_SEL_BINARY);
    constant TXPI_INVSTROBE_SEL_STRING : string := SUL_TO_STR(TXPI_INVSTROBE_SEL_BINARY);
    constant TXPI_PPM_CFG_STRING : string := SLV_TO_STR(TXPI_PPM_CFG_BINARY);
    constant TXPI_SYNFREQ_PPM_STRING : string := SLV_TO_STR(TXPI_SYNFREQ_PPM_BINARY);
    constant TXPMARESET_TIME_STRING : string := SLV_TO_STR(TXPMARESET_TIME_BINARY);
    constant TXSYNC_MULTILANE_STRING : string := SUL_TO_STR(TXSYNC_MULTILANE_BINARY);
    constant TXSYNC_OVRD_STRING : string := SUL_TO_STR(TXSYNC_OVRD_BINARY);
    constant TXSYNC_SKIP_DA_STRING : string := SUL_TO_STR(TXSYNC_SKIP_DA_BINARY);
    constant TX_CLKMUX_PD_STRING : string := SUL_TO_STR(TX_CLKMUX_PD_BINARY);
    constant TX_DEEMPH0_STRING : string := SLV_TO_STR(TX_DEEMPH0_BINARY);
    constant TX_DEEMPH1_STRING : string := SLV_TO_STR(TX_DEEMPH1_BINARY);
    constant TX_EIDLE_ASSERT_DELAY_STRING : string := SLV_TO_STR(TX_EIDLE_ASSERT_DELAY_BINARY);
    constant TX_EIDLE_DEASSERT_DELAY_STRING : string := SLV_TO_STR(TX_EIDLE_DEASSERT_DELAY_BINARY);
    constant TX_MAINCURSOR_SEL_STRING : string := SUL_TO_STR(TX_MAINCURSOR_SEL_BINARY);
    constant TX_MARGIN_FULL_0_STRING : string := SLV_TO_STR(TX_MARGIN_FULL_0_BINARY);
    constant TX_MARGIN_FULL_1_STRING : string := SLV_TO_STR(TX_MARGIN_FULL_1_BINARY);
    constant TX_MARGIN_FULL_2_STRING : string := SLV_TO_STR(TX_MARGIN_FULL_2_BINARY);
    constant TX_MARGIN_FULL_3_STRING : string := SLV_TO_STR(TX_MARGIN_FULL_3_BINARY);
    constant TX_MARGIN_FULL_4_STRING : string := SLV_TO_STR(TX_MARGIN_FULL_4_BINARY);
    constant TX_MARGIN_LOW_0_STRING : string := SLV_TO_STR(TX_MARGIN_LOW_0_BINARY);
    constant TX_MARGIN_LOW_1_STRING : string := SLV_TO_STR(TX_MARGIN_LOW_1_BINARY);
    constant TX_MARGIN_LOW_2_STRING : string := SLV_TO_STR(TX_MARGIN_LOW_2_BINARY);
    constant TX_MARGIN_LOW_3_STRING : string := SLV_TO_STR(TX_MARGIN_LOW_3_BINARY);
    constant TX_MARGIN_LOW_4_STRING : string := SLV_TO_STR(TX_MARGIN_LOW_4_BINARY);
    constant TX_QPI_STATUS_EN_STRING : string := SUL_TO_STR(TX_QPI_STATUS_EN_BINARY);
    constant TX_RXDETECT_CFG_STRING : string := SLV_TO_HEX(TX_RXDETECT_CFG_BINARY, TX_RXDETECT_CFG_STRLEN);
    constant TX_RXDETECT_PRECHARGE_TIME_STRING : string := SLV_TO_HEX(TX_RXDETECT_PRECHARGE_TIME_BINARY, TX_RXDETECT_PRECHARGE_TIME_STRLEN);
    constant TX_RXDETECT_REF_STRING : string := SLV_TO_STR(TX_RXDETECT_REF_BINARY);
    constant UCODEER_CLR_STRING : string := SUL_TO_STR(UCODEER_CLR_BINARY);
    constant USE_PCS_CLK_PHASE_SEL_STRING : string := SUL_TO_STR(USE_PCS_CLK_PHASE_SEL_BINARY);

    signal IS_CLKRSVD0_INVERTED_BIN : std_ulogic;
    signal IS_CLKRSVD1_INVERTED_BIN : std_ulogic;
    signal IS_CPLLLOCKDETCLK_INVERTED_BIN : std_ulogic;
    signal IS_DMONITORCLK_INVERTED_BIN : std_ulogic;
    signal IS_DRPCLK_INVERTED_BIN : std_ulogic;
    signal IS_GTGREFCLK_INVERTED_BIN : std_ulogic;
    signal IS_RXUSRCLK2_INVERTED_BIN : std_ulogic;
    signal IS_RXUSRCLK_INVERTED_BIN : std_ulogic;
    signal IS_SIGVALIDCLK_INVERTED_BIN : std_ulogic;
    signal IS_TXPHDLYTSTCLK_INVERTED_BIN : std_ulogic;
    signal IS_TXUSRCLK2_INVERTED_BIN : std_ulogic;
    signal IS_TXUSRCLK_INVERTED_BIN : std_ulogic;
                                             
    signal ALIGN_COMMA_DOUBLE_BINARY : std_ulogic;
    signal ALIGN_COMMA_WORD_BINARY : std_logic_vector(2 downto 0);
    signal ALIGN_MCOMMA_DET_BINARY : std_ulogic;
    signal ALIGN_PCOMMA_DET_BINARY : std_ulogic;
    signal CBCC_DATA_SOURCE_SEL_BINARY : std_ulogic;
    signal CHAN_BOND_KEEP_ALIGN_BINARY : std_ulogic;
    signal CHAN_BOND_MAX_SKEW_BINARY : std_logic_vector(3 downto 0);
    signal CHAN_BOND_SEQ_2_USE_BINARY : std_ulogic;
    signal CHAN_BOND_SEQ_LEN_BINARY : std_logic_vector(1 downto 0);
    signal CLK_CORRECT_USE_BINARY : std_ulogic;
    signal CLK_COR_KEEP_IDLE_BINARY : std_ulogic;
    signal CLK_COR_MAX_LAT_BINARY : std_logic_vector(5 downto 0);
    signal CLK_COR_MIN_LAT_BINARY : std_logic_vector(5 downto 0);
    signal CLK_COR_PRECEDENCE_BINARY : std_ulogic;
    signal CLK_COR_REPEAT_WAIT_BINARY : std_logic_vector(4 downto 0);
    signal CLK_COR_SEQ_2_USE_BINARY : std_ulogic;
    signal CLK_COR_SEQ_LEN_BINARY : std_logic_vector(1 downto 0);
    signal CPLL_FBDIV_45_BINARY : std_ulogic;
    signal CPLL_FBDIV_BINARY : std_logic_vector(6 downto 0);
    signal CPLL_REFCLK_DIV_BINARY : std_logic_vector(4 downto 0);
    signal DEC_MCOMMA_DETECT_BINARY : std_ulogic;
    signal DEC_PCOMMA_DETECT_BINARY : std_ulogic;
    signal DEC_VALID_COMMA_ONLY_BINARY : std_ulogic;
    signal ES_ERRDET_EN_BINARY : std_ulogic;
    signal ES_EYE_SCAN_EN_BINARY : std_ulogic;
    signal FTS_LANE_DESKEW_EN_BINARY : std_ulogic;
    signal PCS_PCIE_EN_BINARY : std_ulogic;
    signal RXBUF_ADDR_MODE_BINARY : std_ulogic;
    signal RXBUF_EN_BINARY : std_ulogic;
    signal RXBUF_RESET_ON_CB_CHANGE_BINARY : std_ulogic;
    signal RXBUF_RESET_ON_COMMAALIGN_BINARY : std_ulogic;
    signal RXBUF_RESET_ON_EIDLE_BINARY : std_ulogic;
    signal RXBUF_RESET_ON_RATE_CHANGE_BINARY : std_ulogic;
    signal RXBUF_THRESH_OVFLW_BINARY : std_logic_vector(5 downto 0);
    signal RXBUF_THRESH_OVRD_BINARY : std_ulogic;
    signal RXBUF_THRESH_UNDFLW_BINARY : std_logic_vector(5 downto 0);
    signal RXGEARBOX_EN_BINARY : std_ulogic;
    signal RXOOB_CLK_CFG_BINARY : std_ulogic;
    signal RXOUT_DIV_BINARY : std_logic_vector(2 downto 0);
    signal RXSLIDE_AUTO_WAIT_BINARY : std_logic_vector(3 downto 0);
    signal RXSLIDE_MODE_BINARY : std_logic_vector(1 downto 0);
    signal RX_CLK25_DIV_BINARY : std_logic_vector(4 downto 0);
    signal RX_DATA_WIDTH_BINARY : std_logic_vector(2 downto 0);
    signal RX_DEFER_RESET_BUF_EN_BINARY : std_ulogic;
    signal RX_DISPERR_SEQ_MATCH_BINARY : std_ulogic;
    signal RX_INT_DATAWIDTH_BINARY : std_ulogic;
    signal RX_SIG_VALID_DLY_BINARY : std_logic_vector(4 downto 0);
    signal RX_XCLK_SEL_BINARY : std_ulogic;
    signal SAS_MAX_COM_BINARY : std_logic_vector(6 downto 0);
    signal SAS_MIN_COM_BINARY : std_logic_vector(5 downto 0);
    signal SATA_CPLL_CFG_BINARY : std_logic_vector(1 downto 0);
    signal SATA_MAX_BURST_BINARY : std_logic_vector(5 downto 0);
    signal SATA_MAX_INIT_BINARY : std_logic_vector(5 downto 0);
    signal SATA_MAX_WAKE_BINARY : std_logic_vector(5 downto 0);
    signal SATA_MIN_BURST_BINARY : std_logic_vector(5 downto 0);
    signal SATA_MIN_INIT_BINARY : std_logic_vector(5 downto 0);
    signal SATA_MIN_WAKE_BINARY : std_logic_vector(5 downto 0);
    signal SHOW_REALIGN_COMMA_BINARY : std_ulogic;
    signal SIM_RECEIVER_DETECT_PASS_BINARY : std_ulogic;
    signal SIM_RESET_SPEEDUP_BINARY : std_ulogic;
    signal SIM_TX_EIDLE_DRIVE_LEVEL_BINARY : std_ulogic;
    signal SIM_VERSION_BINARY : std_ulogic;
    signal TXBUF_EN_BINARY : std_ulogic;
    signal TXBUF_RESET_ON_RATE_CHANGE_BINARY : std_ulogic;
    signal TXGEARBOX_EN_BINARY : std_ulogic;
    signal TXOUT_DIV_BINARY : std_logic_vector(2 downto 0);
    signal TXPI_PPMCLK_SEL_BINARY : std_ulogic;
    signal TX_CLK25_DIV_BINARY : std_logic_vector(4 downto 0);
    signal TX_DATA_WIDTH_BINARY : std_logic_vector(2 downto 0);
    signal TX_DRIVE_MODE_BINARY : std_logic_vector(4 downto 0);
    signal TX_INT_DATAWIDTH_BINARY : std_ulogic;
    signal TX_LOOPBACK_DRIVE_HIZ_BINARY : std_ulogic;
    signal TX_XCLK_SEL_BINARY : std_ulogic;
    
    signal CPLLFBCLKLOST_out : std_ulogic;
    signal CPLLLOCK_out : std_ulogic;
    signal CPLLREFCLKLOST_out : std_ulogic;
    signal DMONITOROUT_out : std_logic_vector(14 downto 0);
    signal DRPDO_out : std_logic_vector(15 downto 0);
    signal DRPRDY_out : std_ulogic;
    signal EYESCANDATAERROR_out : std_ulogic;
    signal GTHTXN_out : std_ulogic;
    signal GTHTXP_out : std_ulogic;
    signal GTREFCLKMONITOR_out : std_ulogic;
    signal PCSRSVDOUT_out : std_logic_vector(15 downto 0);
    signal PHYSTATUS_out : std_ulogic;
    signal RSOSINTDONE_out : std_ulogic;
    signal RXBUFSTATUS_out : std_logic_vector(2 downto 0);
    signal RXBYTEISALIGNED_out : std_ulogic;
    signal RXBYTEREALIGN_out : std_ulogic;
    signal RXCDRLOCK_out : std_ulogic;
    signal RXCHANBONDSEQ_out : std_ulogic;
    signal RXCHANISALIGNED_out : std_ulogic;
    signal RXCHANREALIGN_out : std_ulogic;
    signal RXCHARISCOMMA_out : std_logic_vector(7 downto 0);
    signal RXCHARISK_out : std_logic_vector(7 downto 0);
    signal RXCHBONDO_out : std_logic_vector(4 downto 0);
    signal RXCLKCORCNT_out : std_logic_vector(1 downto 0);
    signal RXCOMINITDET_out : std_ulogic;
    signal RXCOMMADET_out : std_ulogic;
    signal RXCOMSASDET_out : std_ulogic;
    signal RXCOMWAKEDET_out : std_ulogic;
    signal RXDATAVALID_out : std_logic_vector(1 downto 0);
    signal RXDATA_out : std_logic_vector(63 downto 0);
    signal RXDFESLIDETAPSTARTED_out : std_ulogic;
    signal RXDFESLIDETAPSTROBEDONE_out : std_ulogic;
    signal RXDFESLIDETAPSTROBESTARTED_out : std_ulogic;
    signal RXDFESTADAPTDONE_out : std_ulogic;
    signal RXDISPERR_out : std_logic_vector(7 downto 0);
    signal RXDLYSRESETDONE_out : std_ulogic;
    signal RXELECIDLE_out : std_ulogic;
    signal RXHEADERVALID_out : std_logic_vector(1 downto 0);
    signal RXHEADER_out : std_logic_vector(5 downto 0);
    signal RXMONITOROUT_out : std_logic_vector(6 downto 0);
    signal RXNOTINTABLE_out : std_logic_vector(7 downto 0);
    signal RXOSINTSTARTED_out : std_ulogic;
    signal RXOSINTSTROBEDONE_out : std_ulogic;
    signal RXOSINTSTROBESTARTED_out : std_ulogic;
    signal RXOUTCLKFABRIC_out : std_ulogic;
    signal RXOUTCLKPCS_out : std_ulogic;
    signal RXOUTCLK_out : std_ulogic;
    signal RXPHALIGNDONE_out : std_ulogic;
    signal RXPHMONITOR_out : std_logic_vector(4 downto 0);
    signal RXPHSLIPMONITOR_out : std_logic_vector(4 downto 0);
    signal RXPMARESETDONE_out : std_ulogic;
    signal RXPRBSERR_out : std_ulogic;
    signal RXQPISENN_out : std_ulogic;
    signal RXQPISENP_out : std_ulogic;
    signal RXRATEDONE_out : std_ulogic;
    signal RXRESETDONE_out : std_ulogic;
    signal RXSTARTOFSEQ_out : std_logic_vector(1 downto 0);
    signal RXSTATUS_out : std_logic_vector(2 downto 0);
    signal RXSYNCDONE_out : std_ulogic;
    signal RXSYNCOUT_out : std_ulogic;
    signal RXVALID_out : std_ulogic;
    signal TXBUFSTATUS_out : std_logic_vector(1 downto 0);
    signal TXCOMFINISH_out : std_ulogic;
    signal TXDLYSRESETDONE_out : std_ulogic;
    signal TXGEARBOXREADY_out : std_ulogic;
    signal TXOUTCLKFABRIC_out : std_ulogic;
    signal TXOUTCLKPCS_out : std_ulogic;
    signal TXOUTCLK_out : std_ulogic;
    signal TXPHALIGNDONE_out : std_ulogic;
    signal TXPHINITDONE_out : std_ulogic;
    signal TXPMARESETDONE_out : std_ulogic;
    signal TXQPISENN_out : std_ulogic;
    signal TXQPISENP_out : std_ulogic;
    signal TXRATEDONE_out : std_ulogic;
    signal TXRESETDONE_out : std_ulogic;
    signal TXSYNCDONE_out : std_ulogic;
    signal TXSYNCOUT_out : std_ulogic;
    
    signal CPLLFBCLKLOST_outdelay : std_ulogic;
    signal CPLLLOCK_outdelay : std_ulogic;
    signal CPLLREFCLKLOST_outdelay : std_ulogic;
    signal DMONITOROUT_outdelay : std_logic_vector(14 downto 0);
    signal DRPDO_outdelay : std_logic_vector(15 downto 0);
    signal DRPRDY_outdelay : std_ulogic;
    signal EYESCANDATAERROR_outdelay : std_ulogic;
    signal GTHTXN_outdelay : std_ulogic;
    signal GTHTXP_outdelay : std_ulogic;
    signal GTREFCLKMONITOR_outdelay : std_ulogic;
    signal PCSRSVDOUT_outdelay : std_logic_vector(15 downto 0);
    signal PHYSTATUS_outdelay : std_ulogic;
    signal RSOSINTDONE_outdelay : std_ulogic;
    signal RXBUFSTATUS_outdelay : std_logic_vector(2 downto 0);
    signal RXBYTEISALIGNED_outdelay : std_ulogic;
    signal RXBYTEREALIGN_outdelay : std_ulogic;
    signal RXCDRLOCK_outdelay : std_ulogic;
    signal RXCHANBONDSEQ_outdelay : std_ulogic;
    signal RXCHANISALIGNED_outdelay : std_ulogic;
    signal RXCHANREALIGN_outdelay : std_ulogic;
    signal RXCHARISCOMMA_outdelay : std_logic_vector(7 downto 0);
    signal RXCHARISK_outdelay : std_logic_vector(7 downto 0);
    signal RXCHBONDO_outdelay : std_logic_vector(4 downto 0);
    signal RXCLKCORCNT_outdelay : std_logic_vector(1 downto 0);
    signal RXCOMINITDET_outdelay : std_ulogic;
    signal RXCOMMADET_outdelay : std_ulogic;
    signal RXCOMSASDET_outdelay : std_ulogic;
    signal RXCOMWAKEDET_outdelay : std_ulogic;
    signal RXDATAVALID_outdelay : std_logic_vector(1 downto 0);
    signal RXDATA_outdelay : std_logic_vector(63 downto 0);
    signal RXDFESLIDETAPSTARTED_outdelay : std_ulogic;
    signal RXDFESLIDETAPSTROBEDONE_outdelay : std_ulogic;
    signal RXDFESLIDETAPSTROBESTARTED_outdelay : std_ulogic;
    signal RXDFESTADAPTDONE_outdelay : std_ulogic;
    signal RXDISPERR_outdelay : std_logic_vector(7 downto 0);
    signal RXDLYSRESETDONE_outdelay : std_ulogic;
    signal RXELECIDLE_outdelay : std_ulogic;
    signal RXHEADERVALID_outdelay : std_logic_vector(1 downto 0);
    signal RXHEADER_outdelay : std_logic_vector(5 downto 0);
    signal RXMONITOROUT_outdelay : std_logic_vector(6 downto 0);
    signal RXNOTINTABLE_outdelay : std_logic_vector(7 downto 0);
    signal RXOSINTSTARTED_outdelay : std_ulogic;
    signal RXOSINTSTROBEDONE_outdelay : std_ulogic;
    signal RXOSINTSTROBESTARTED_outdelay : std_ulogic;
    signal RXOUTCLKFABRIC_outdelay : std_ulogic;
    signal RXOUTCLKPCS_outdelay : std_ulogic;
    signal RXOUTCLK_outdelay : std_ulogic;
    signal RXPHALIGNDONE_outdelay : std_ulogic;
    signal RXPHMONITOR_outdelay : std_logic_vector(4 downto 0);
    signal RXPHSLIPMONITOR_outdelay : std_logic_vector(4 downto 0);
    signal RXPMARESETDONE_outdelay : std_ulogic;
    signal RXPRBSERR_outdelay : std_ulogic;
    signal RXQPISENN_outdelay : std_ulogic;
    signal RXQPISENP_outdelay : std_ulogic;
    signal RXRATEDONE_outdelay : std_ulogic;
    signal RXRESETDONE_outdelay : std_ulogic;
    signal RXSTARTOFSEQ_outdelay : std_logic_vector(1 downto 0);
    signal RXSTATUS_outdelay : std_logic_vector(2 downto 0);
    signal RXSYNCDONE_outdelay : std_ulogic;
    signal RXSYNCOUT_outdelay : std_ulogic;
    signal RXVALID_outdelay : std_ulogic;
    signal TXBUFSTATUS_outdelay : std_logic_vector(1 downto 0);
    signal TXCOMFINISH_outdelay : std_ulogic;
    signal TXDLYSRESETDONE_outdelay : std_ulogic;
    signal TXGEARBOXREADY_outdelay : std_ulogic;
    signal TXOUTCLKFABRIC_outdelay : std_ulogic;
    signal TXOUTCLKPCS_outdelay : std_ulogic;
    signal TXOUTCLK_outdelay : std_ulogic;
    signal TXPHALIGNDONE_outdelay : std_ulogic;
    signal TXPHINITDONE_outdelay : std_ulogic;
    signal TXPMARESETDONE_outdelay : std_ulogic;
    signal TXQPISENN_outdelay : std_ulogic;
    signal TXQPISENP_outdelay : std_ulogic;
    signal TXRATEDONE_outdelay : std_ulogic;
    signal TXRESETDONE_outdelay : std_ulogic;
    signal TXSYNCDONE_outdelay : std_ulogic;
    signal TXSYNCOUT_outdelay : std_ulogic;
    
    signal CFGRESET_ipd : std_ulogic;
    signal CLKRSVD0_ipd : std_ulogic;
    signal CLKRSVD1_ipd : std_ulogic;
    signal CPLLLOCKDETCLK_ipd : std_ulogic;
    signal CPLLLOCKEN_ipd : std_ulogic;
    signal CPLLPD_ipd : std_ulogic;
    signal CPLLREFCLKSEL_ipd : std_logic_vector(2 downto 0);
    signal CPLLRESET_ipd : std_ulogic;
    signal DMONFIFORESET_ipd : std_ulogic;
    signal DMONITORCLK_ipd : std_ulogic;
    signal DRPADDR_ipd : std_logic_vector(8 downto 0);
    signal DRPCLK_ipd : std_ulogic;
    signal DRPDI_ipd : std_logic_vector(15 downto 0);
    signal DRPEN_ipd : std_ulogic;
    signal DRPWE_ipd : std_ulogic;
    signal EYESCANMODE_ipd : std_ulogic;
    signal EYESCANRESET_ipd : std_ulogic;
    signal EYESCANTRIGGER_ipd : std_ulogic;
    signal GTGREFCLK_ipd : std_ulogic;
    signal GTHRXN_ipd : std_ulogic;
    signal GTHRXP_ipd : std_ulogic;
    signal GTNORTHREFCLK0_ipd : std_ulogic;
    signal GTNORTHREFCLK1_ipd : std_ulogic;
    signal GTREFCLK0_ipd : std_ulogic;
    signal GTREFCLK1_ipd : std_ulogic;
    signal GTRESETSEL_ipd : std_ulogic;
    signal GTRSVD_ipd : std_logic_vector(15 downto 0);
    signal GTRXRESET_ipd : std_ulogic;
    signal GTSOUTHREFCLK0_ipd : std_ulogic;
    signal GTSOUTHREFCLK1_ipd : std_ulogic;
    signal GTTXRESET_ipd : std_ulogic;
    signal LOOPBACK_ipd : std_logic_vector(2 downto 0);
    signal PCSRSVDIN2_ipd : std_logic_vector(4 downto 0);
    signal PCSRSVDIN_ipd : std_logic_vector(15 downto 0);
    signal PMARSVDIN_ipd : std_logic_vector(4 downto 0);
    signal QPLLCLK_ipd : std_ulogic;
    signal QPLLREFCLK_ipd : std_ulogic;
    signal RESETOVRD_ipd : std_ulogic;
    signal RX8B10BEN_ipd : std_ulogic;
    signal RXADAPTSELTEST_ipd : std_logic_vector(13 downto 0);
    signal RXBUFRESET_ipd : std_ulogic;
    signal RXCDRFREQRESET_ipd : std_ulogic;
    signal RXCDRHOLD_ipd : std_ulogic;
    signal RXCDROVRDEN_ipd : std_ulogic;
    signal RXCDRRESETRSV_ipd : std_ulogic;
    signal RXCDRRESET_ipd : std_ulogic;
    signal RXCHBONDEN_ipd : std_ulogic;
    signal RXCHBONDI_ipd : std_logic_vector(4 downto 0);
    signal RXCHBONDLEVEL_ipd : std_logic_vector(2 downto 0);
    signal RXCHBONDMASTER_ipd : std_ulogic;
    signal RXCHBONDSLAVE_ipd : std_ulogic;
    signal RXCOMMADETEN_ipd : std_ulogic;
    signal RXDDIEN_ipd : std_ulogic;
    signal RXDFEAGCHOLD_ipd : std_ulogic;
    signal RXDFEAGCOVRDEN_ipd : std_ulogic;
    signal RXDFEAGCTRL_ipd : std_logic_vector(4 downto 0);
    signal RXDFECM1EN_ipd : std_ulogic;
    signal RXDFELFHOLD_ipd : std_ulogic;
    signal RXDFELFOVRDEN_ipd : std_ulogic;
    signal RXDFELPMRESET_ipd : std_ulogic;
    signal RXDFESLIDETAPADAPTEN_ipd : std_ulogic;
    signal RXDFESLIDETAPHOLD_ipd : std_ulogic;
    signal RXDFESLIDETAPID_ipd : std_logic_vector(5 downto 0);
    signal RXDFESLIDETAPINITOVRDEN_ipd : std_ulogic;
    signal RXDFESLIDETAPONLYADAPTEN_ipd : std_ulogic;
    signal RXDFESLIDETAPOVRDEN_ipd : std_ulogic;
    signal RXDFESLIDETAPSTROBE_ipd : std_ulogic;
    signal RXDFESLIDETAP_ipd : std_logic_vector(4 downto 0);
    signal RXDFETAP2HOLD_ipd : std_ulogic;
    signal RXDFETAP2OVRDEN_ipd : std_ulogic;
    signal RXDFETAP3HOLD_ipd : std_ulogic;
    signal RXDFETAP3OVRDEN_ipd : std_ulogic;
    signal RXDFETAP4HOLD_ipd : std_ulogic;
    signal RXDFETAP4OVRDEN_ipd : std_ulogic;
    signal RXDFETAP5HOLD_ipd : std_ulogic;
    signal RXDFETAP5OVRDEN_ipd : std_ulogic;
    signal RXDFETAP6HOLD_ipd : std_ulogic;
    signal RXDFETAP6OVRDEN_ipd : std_ulogic;
    signal RXDFETAP7HOLD_ipd : std_ulogic;
    signal RXDFETAP7OVRDEN_ipd : std_ulogic;
    signal RXDFEUTHOLD_ipd : std_ulogic;
    signal RXDFEUTOVRDEN_ipd : std_ulogic;
    signal RXDFEVPHOLD_ipd : std_ulogic;
    signal RXDFEVPOVRDEN_ipd : std_ulogic;
    signal RXDFEVSEN_ipd : std_ulogic;
    signal RXDFEXYDEN_ipd : std_ulogic;
    signal RXDLYBYPASS_ipd : std_ulogic;
    signal RXDLYEN_ipd : std_ulogic;
    signal RXDLYOVRDEN_ipd : std_ulogic;
    signal RXDLYSRESET_ipd : std_ulogic;
    signal RXELECIDLEMODE_ipd : std_logic_vector(1 downto 0);
    signal RXGEARBOXSLIP_ipd : std_ulogic;
    signal RXLPMEN_ipd : std_ulogic;
    signal RXLPMHFHOLD_ipd : std_ulogic;
    signal RXLPMHFOVRDEN_ipd : std_ulogic;
    signal RXLPMLFHOLD_ipd : std_ulogic;
    signal RXLPMLFKLOVRDEN_ipd : std_ulogic;
    signal RXMCOMMAALIGNEN_ipd : std_ulogic;
    signal RXMONITORSEL_ipd : std_logic_vector(1 downto 0);
    signal RXOOBRESET_ipd : std_ulogic;
    signal RXOSCALRESET_ipd : std_ulogic;
    signal RXOSHOLD_ipd : std_ulogic;
    signal RXOSINTCFG_ipd : std_logic_vector(3 downto 0);
    signal RXOSINTEN_ipd : std_ulogic;
    signal RXOSINTHOLD_ipd : std_ulogic;
    signal RXOSINTID0_ipd : std_logic_vector(3 downto 0);
    signal RXOSINTNTRLEN_ipd : std_ulogic;
    signal RXOSINTOVRDEN_ipd : std_ulogic;
    signal RXOSINTSTROBE_ipd : std_ulogic;
    signal RXOSINTTESTOVRDEN_ipd : std_ulogic;
    signal RXOSOVRDEN_ipd : std_ulogic;
    signal RXOUTCLKSEL_ipd : std_logic_vector(2 downto 0);
    signal RXPCOMMAALIGNEN_ipd : std_ulogic;
    signal RXPCSRESET_ipd : std_ulogic;
    signal RXPD_ipd : std_logic_vector(1 downto 0);
    signal RXPHALIGNEN_ipd : std_ulogic;
    signal RXPHALIGN_ipd : std_ulogic;
    signal RXPHDLYPD_ipd : std_ulogic;
    signal RXPHDLYRESET_ipd : std_ulogic;
    signal RXPHOVRDEN_ipd : std_ulogic;
    signal RXPMARESET_ipd : std_ulogic;
    signal RXPOLARITY_ipd : std_ulogic;
    signal RXPRBSCNTRESET_ipd : std_ulogic;
    signal RXPRBSSEL_ipd : std_logic_vector(2 downto 0);
    signal RXQPIEN_ipd : std_ulogic;
    signal RXRATEMODE_ipd : std_ulogic;
    signal RXRATE_ipd : std_logic_vector(2 downto 0);
    signal RXSLIDE_ipd : std_ulogic;
    signal RXSYNCALLIN_ipd : std_ulogic;
    signal RXSYNCIN_ipd : std_ulogic;
    signal RXSYNCMODE_ipd : std_ulogic;
    signal RXSYSCLKSEL_ipd : std_logic_vector(1 downto 0);
    signal RXUSERRDY_ipd : std_ulogic;
    signal RXUSRCLK2_ipd : std_ulogic;
    signal RXUSRCLK_ipd : std_ulogic;
    signal SETERRSTATUS_ipd : std_ulogic;
    signal SIGVALIDCLK_ipd : std_ulogic;
    signal TSTIN_ipd : std_logic_vector(19 downto 0);
    signal TX8B10BBYPASS_ipd : std_logic_vector(7 downto 0);
    signal TX8B10BEN_ipd : std_ulogic;
    signal TXBUFDIFFCTRL_ipd : std_logic_vector(2 downto 0);
    signal TXCHARDISPMODE_ipd : std_logic_vector(7 downto 0);
    signal TXCHARDISPVAL_ipd : std_logic_vector(7 downto 0);
    signal TXCHARISK_ipd : std_logic_vector(7 downto 0);
    signal TXCOMINIT_ipd : std_ulogic;
    signal TXCOMSAS_ipd : std_ulogic;
    signal TXCOMWAKE_ipd : std_ulogic;
    signal TXDATA_ipd : std_logic_vector(63 downto 0);
    signal TXDEEMPH_ipd : std_ulogic;
    signal TXDETECTRX_ipd : std_ulogic;
    signal TXDIFFCTRL_ipd : std_logic_vector(3 downto 0);
    signal TXDIFFPD_ipd : std_ulogic;
    signal TXDLYBYPASS_ipd : std_ulogic;
    signal TXDLYEN_ipd : std_ulogic;
    signal TXDLYHOLD_ipd : std_ulogic;
    signal TXDLYOVRDEN_ipd : std_ulogic;
    signal TXDLYSRESET_ipd : std_ulogic;
    signal TXDLYUPDOWN_ipd : std_ulogic;
    signal TXELECIDLE_ipd : std_ulogic;
    signal TXHEADER_ipd : std_logic_vector(2 downto 0);
    signal TXINHIBIT_ipd : std_ulogic;
    signal TXMAINCURSOR_ipd : std_logic_vector(6 downto 0);
    signal TXMARGIN_ipd : std_logic_vector(2 downto 0);
    signal TXOUTCLKSEL_ipd : std_logic_vector(2 downto 0);
    signal TXPCSRESET_ipd : std_ulogic;
    signal TXPDELECIDLEMODE_ipd : std_ulogic;
    signal TXPD_ipd : std_logic_vector(1 downto 0);
    signal TXPHALIGNEN_ipd : std_ulogic;
    signal TXPHALIGN_ipd : std_ulogic;
    signal TXPHDLYPD_ipd : std_ulogic;
    signal TXPHDLYRESET_ipd : std_ulogic;
    signal TXPHDLYTSTCLK_ipd : std_ulogic;
    signal TXPHINIT_ipd : std_ulogic;
    signal TXPHOVRDEN_ipd : std_ulogic;
    signal TXPIPPMEN_ipd : std_ulogic;
    signal TXPIPPMOVRDEN_ipd : std_ulogic;
    signal TXPIPPMPD_ipd : std_ulogic;
    signal TXPIPPMSEL_ipd : std_ulogic;
    signal TXPIPPMSTEPSIZE_ipd : std_logic_vector(4 downto 0);
    signal TXPISOPD_ipd : std_ulogic;
    signal TXPMARESET_ipd : std_ulogic;
    signal TXPOLARITY_ipd : std_ulogic;
    signal TXPOSTCURSORINV_ipd : std_ulogic;
    signal TXPOSTCURSOR_ipd : std_logic_vector(4 downto 0);
    signal TXPRBSFORCEERR_ipd : std_ulogic;
    signal TXPRBSSEL_ipd : std_logic_vector(2 downto 0);
    signal TXPRECURSORINV_ipd : std_ulogic;
    signal TXPRECURSOR_ipd : std_logic_vector(4 downto 0);
    signal TXQPIBIASEN_ipd : std_ulogic;
    signal TXQPISTRONGPDOWN_ipd : std_ulogic;
    signal TXQPIWEAKPUP_ipd : std_ulogic;
    signal TXRATEMODE_ipd : std_ulogic;
    signal TXRATE_ipd : std_logic_vector(2 downto 0);
    signal TXSEQUENCE_ipd : std_logic_vector(6 downto 0);
    signal TXSTARTSEQ_ipd : std_ulogic;
    signal TXSWING_ipd : std_ulogic;
    signal TXSYNCALLIN_ipd : std_ulogic;
    signal TXSYNCIN_ipd : std_ulogic;
    signal TXSYNCMODE_ipd : std_ulogic;
    signal TXSYSCLKSEL_ipd : std_logic_vector(1 downto 0);
    signal TXUSERRDY_ipd : std_ulogic;
    signal TXUSRCLK2_ipd : std_ulogic;
    signal TXUSRCLK_ipd : std_ulogic;
    
    signal CFGRESET_indelay : std_ulogic;
    signal CLKRSVD0_indelay : std_ulogic;
    signal CLKRSVD1_indelay : std_ulogic;
    signal CPLLLOCKDETCLK_indelay : std_ulogic;
    signal CPLLLOCKEN_indelay : std_ulogic;
    signal CPLLPD_indelay : std_ulogic;
    signal CPLLREFCLKSEL_indelay : std_logic_vector(2 downto 0);
    signal CPLLRESET_indelay : std_ulogic;
    signal DMONFIFORESET_indelay : std_ulogic;
    signal DMONITORCLK_indelay : std_ulogic;
    signal DRPADDR_indelay : std_logic_vector(8 downto 0);
    signal DRPCLK_indelay : std_ulogic;
    signal DRPDI_indelay : std_logic_vector(15 downto 0);
    signal DRPEN_indelay : std_ulogic;
    signal DRPWE_indelay : std_ulogic;
    signal EYESCANMODE_indelay : std_ulogic;
    signal EYESCANRESET_indelay : std_ulogic;
    signal EYESCANTRIGGER_indelay : std_ulogic;
    signal GTGREFCLK_indelay : std_ulogic;
    signal GTHRXN_indelay : std_ulogic;
    signal GTHRXP_indelay : std_ulogic;
    signal GTNORTHREFCLK0_indelay : std_ulogic;
    signal GTNORTHREFCLK1_indelay : std_ulogic;
    signal GTREFCLK0_indelay : std_ulogic;
    signal GTREFCLK1_indelay : std_ulogic;
    signal GTRESETSEL_indelay : std_ulogic;
    signal GTRSVD_indelay : std_logic_vector(15 downto 0);
    signal GTRXRESET_indelay : std_ulogic;
    signal GTSOUTHREFCLK0_indelay : std_ulogic;
    signal GTSOUTHREFCLK1_indelay : std_ulogic;
    signal GTTXRESET_indelay : std_ulogic;
    signal LOOPBACK_indelay : std_logic_vector(2 downto 0);
    signal PCSRSVDIN2_indelay : std_logic_vector(4 downto 0);
    signal PCSRSVDIN_indelay : std_logic_vector(15 downto 0);
    signal PMARSVDIN_indelay : std_logic_vector(4 downto 0);
    signal QPLLCLK_indelay : std_ulogic;
    signal QPLLREFCLK_indelay : std_ulogic;
    signal RESETOVRD_indelay : std_ulogic;
    signal RX8B10BEN_indelay : std_ulogic;
    signal RXADAPTSELTEST_indelay : std_logic_vector(13 downto 0);
    signal RXBUFRESET_indelay : std_ulogic;
    signal RXCDRFREQRESET_indelay : std_ulogic;
    signal RXCDRHOLD_indelay : std_ulogic;
    signal RXCDROVRDEN_indelay : std_ulogic;
    signal RXCDRRESETRSV_indelay : std_ulogic;
    signal RXCDRRESET_indelay : std_ulogic;
    signal RXCHBONDEN_indelay : std_ulogic;
    signal RXCHBONDI_indelay : std_logic_vector(4 downto 0);
    signal RXCHBONDLEVEL_indelay : std_logic_vector(2 downto 0);
    signal RXCHBONDMASTER_indelay : std_ulogic;
    signal RXCHBONDSLAVE_indelay : std_ulogic;
    signal RXCOMMADETEN_indelay : std_ulogic;
    signal RXDDIEN_indelay : std_ulogic;
    signal RXDFEAGCHOLD_indelay : std_ulogic;
    signal RXDFEAGCOVRDEN_indelay : std_ulogic;
    signal RXDFEAGCTRL_indelay : std_logic_vector(4 downto 0);
    signal RXDFECM1EN_indelay : std_ulogic;
    signal RXDFELFHOLD_indelay : std_ulogic;
    signal RXDFELFOVRDEN_indelay : std_ulogic;
    signal RXDFELPMRESET_indelay : std_ulogic;
    signal RXDFESLIDETAPADAPTEN_indelay : std_ulogic;
    signal RXDFESLIDETAPHOLD_indelay : std_ulogic;
    signal RXDFESLIDETAPID_indelay : std_logic_vector(5 downto 0);
    signal RXDFESLIDETAPINITOVRDEN_indelay : std_ulogic;
    signal RXDFESLIDETAPONLYADAPTEN_indelay : std_ulogic;
    signal RXDFESLIDETAPOVRDEN_indelay : std_ulogic;
    signal RXDFESLIDETAPSTROBE_indelay : std_ulogic;
    signal RXDFESLIDETAP_indelay : std_logic_vector(4 downto 0);
    signal RXDFETAP2HOLD_indelay : std_ulogic;
    signal RXDFETAP2OVRDEN_indelay : std_ulogic;
    signal RXDFETAP3HOLD_indelay : std_ulogic;
    signal RXDFETAP3OVRDEN_indelay : std_ulogic;
    signal RXDFETAP4HOLD_indelay : std_ulogic;
    signal RXDFETAP4OVRDEN_indelay : std_ulogic;
    signal RXDFETAP5HOLD_indelay : std_ulogic;
    signal RXDFETAP5OVRDEN_indelay : std_ulogic;
    signal RXDFETAP6HOLD_indelay : std_ulogic;
    signal RXDFETAP6OVRDEN_indelay : std_ulogic;
    signal RXDFETAP7HOLD_indelay : std_ulogic;
    signal RXDFETAP7OVRDEN_indelay : std_ulogic;
    signal RXDFEUTHOLD_indelay : std_ulogic;
    signal RXDFEUTOVRDEN_indelay : std_ulogic;
    signal RXDFEVPHOLD_indelay : std_ulogic;
    signal RXDFEVPOVRDEN_indelay : std_ulogic;
    signal RXDFEVSEN_indelay : std_ulogic;
    signal RXDFEXYDEN_indelay : std_ulogic;
    signal RXDLYBYPASS_indelay : std_ulogic;
    signal RXDLYEN_indelay : std_ulogic;
    signal RXDLYOVRDEN_indelay : std_ulogic;
    signal RXDLYSRESET_indelay : std_ulogic;
    signal RXELECIDLEMODE_indelay : std_logic_vector(1 downto 0);
    signal RXGEARBOXSLIP_indelay : std_ulogic;
    signal RXLPMEN_indelay : std_ulogic;
    signal RXLPMHFHOLD_indelay : std_ulogic;
    signal RXLPMHFOVRDEN_indelay : std_ulogic;
    signal RXLPMLFHOLD_indelay : std_ulogic;
    signal RXLPMLFKLOVRDEN_indelay : std_ulogic;
    signal RXMCOMMAALIGNEN_indelay : std_ulogic;
    signal RXMONITORSEL_indelay : std_logic_vector(1 downto 0);
    signal RXOOBRESET_indelay : std_ulogic;
    signal RXOSCALRESET_indelay : std_ulogic;
    signal RXOSHOLD_indelay : std_ulogic;
    signal RXOSINTCFG_indelay : std_logic_vector(3 downto 0);
    signal RXOSINTEN_indelay : std_ulogic;
    signal RXOSINTHOLD_indelay : std_ulogic;
    signal RXOSINTID0_indelay : std_logic_vector(3 downto 0);
    signal RXOSINTNTRLEN_indelay : std_ulogic;
    signal RXOSINTOVRDEN_indelay : std_ulogic;
    signal RXOSINTSTROBE_indelay : std_ulogic;
    signal RXOSINTTESTOVRDEN_indelay : std_ulogic;
    signal RXOSOVRDEN_indelay : std_ulogic;
    signal RXOUTCLKSEL_indelay : std_logic_vector(2 downto 0);
    signal RXPCOMMAALIGNEN_indelay : std_ulogic;
    signal RXPCSRESET_indelay : std_ulogic;
    signal RXPD_indelay : std_logic_vector(1 downto 0);
    signal RXPHALIGNEN_indelay : std_ulogic;
    signal RXPHALIGN_indelay : std_ulogic;
    signal RXPHDLYPD_indelay : std_ulogic;
    signal RXPHDLYRESET_indelay : std_ulogic;
    signal RXPHOVRDEN_indelay : std_ulogic;
    signal RXPMARESET_indelay : std_ulogic;
    signal RXPOLARITY_indelay : std_ulogic;
    signal RXPRBSCNTRESET_indelay : std_ulogic;
    signal RXPRBSSEL_indelay : std_logic_vector(2 downto 0);
    signal RXQPIEN_indelay : std_ulogic;
    signal RXRATEMODE_indelay : std_ulogic;
    signal RXRATE_indelay : std_logic_vector(2 downto 0);
    signal RXSLIDE_indelay : std_ulogic;
    signal RXSYNCALLIN_indelay : std_ulogic;
    signal RXSYNCIN_indelay : std_ulogic;
    signal RXSYNCMODE_indelay : std_ulogic;
    signal RXSYSCLKSEL_indelay : std_logic_vector(1 downto 0);
    signal RXUSERRDY_indelay : std_ulogic;
    signal RXUSRCLK2_indelay : std_ulogic;
    signal RXUSRCLK_indelay : std_ulogic;
    signal SETERRSTATUS_indelay : std_ulogic;
    signal SIGVALIDCLK_indelay : std_ulogic;
    signal TSTIN_indelay : std_logic_vector(19 downto 0);
    signal TX8B10BBYPASS_indelay : std_logic_vector(7 downto 0);
    signal TX8B10BEN_indelay : std_ulogic;
    signal TXBUFDIFFCTRL_indelay : std_logic_vector(2 downto 0);
    signal TXCHARDISPMODE_indelay : std_logic_vector(7 downto 0);
    signal TXCHARDISPVAL_indelay : std_logic_vector(7 downto 0);
    signal TXCHARISK_indelay : std_logic_vector(7 downto 0);
    signal TXCOMINIT_indelay : std_ulogic;
    signal TXCOMSAS_indelay : std_ulogic;
    signal TXCOMWAKE_indelay : std_ulogic;
    signal TXDATA_indelay : std_logic_vector(63 downto 0);
    signal TXDEEMPH_indelay : std_ulogic;
    signal TXDETECTRX_indelay : std_ulogic;
    signal TXDIFFCTRL_indelay : std_logic_vector(3 downto 0);
    signal TXDIFFPD_indelay : std_ulogic;
    signal TXDLYBYPASS_indelay : std_ulogic;
    signal TXDLYEN_indelay : std_ulogic;
    signal TXDLYHOLD_indelay : std_ulogic;
    signal TXDLYOVRDEN_indelay : std_ulogic;
    signal TXDLYSRESET_indelay : std_ulogic;
    signal TXDLYUPDOWN_indelay : std_ulogic;
    signal TXELECIDLE_indelay : std_ulogic;
    signal TXHEADER_indelay : std_logic_vector(2 downto 0);
    signal TXINHIBIT_indelay : std_ulogic;
    signal TXMAINCURSOR_indelay : std_logic_vector(6 downto 0);
    signal TXMARGIN_indelay : std_logic_vector(2 downto 0);
    signal TXOUTCLKSEL_indelay : std_logic_vector(2 downto 0);
    signal TXPCSRESET_indelay : std_ulogic;
    signal TXPDELECIDLEMODE_indelay : std_ulogic;
    signal TXPD_indelay : std_logic_vector(1 downto 0);
    signal TXPHALIGNEN_indelay : std_ulogic;
    signal TXPHALIGN_indelay : std_ulogic;
    signal TXPHDLYPD_indelay : std_ulogic;
    signal TXPHDLYRESET_indelay : std_ulogic;
    signal TXPHDLYTSTCLK_indelay : std_ulogic;
    signal TXPHINIT_indelay : std_ulogic;
    signal TXPHOVRDEN_indelay : std_ulogic;
    signal TXPIPPMEN_indelay : std_ulogic;
    signal TXPIPPMOVRDEN_indelay : std_ulogic;
    signal TXPIPPMPD_indelay : std_ulogic;
    signal TXPIPPMSEL_indelay : std_ulogic;
    signal TXPIPPMSTEPSIZE_indelay : std_logic_vector(4 downto 0);
    signal TXPISOPD_indelay : std_ulogic;
    signal TXPMARESET_indelay : std_ulogic;
    signal TXPOLARITY_indelay : std_ulogic;
    signal TXPOSTCURSORINV_indelay : std_ulogic;
    signal TXPOSTCURSOR_indelay : std_logic_vector(4 downto 0);
    signal TXPRBSFORCEERR_indelay : std_ulogic;
    signal TXPRBSSEL_indelay : std_logic_vector(2 downto 0);
    signal TXPRECURSORINV_indelay : std_ulogic;
    signal TXPRECURSOR_indelay : std_logic_vector(4 downto 0);
    signal TXQPIBIASEN_indelay : std_ulogic;
    signal TXQPISTRONGPDOWN_indelay : std_ulogic;
    signal TXQPIWEAKPUP_indelay : std_ulogic;
    signal TXRATEMODE_indelay : std_ulogic;
    signal TXRATE_indelay : std_logic_vector(2 downto 0);
    signal TXSEQUENCE_indelay : std_logic_vector(6 downto 0);
    signal TXSTARTSEQ_indelay : std_ulogic;
    signal TXSWING_indelay : std_ulogic;
    signal TXSYNCALLIN_indelay : std_ulogic;
    signal TXSYNCIN_indelay : std_ulogic;
    signal TXSYNCMODE_indelay : std_ulogic;
    signal TXSYSCLKSEL_indelay : std_logic_vector(1 downto 0);
    signal TXUSERRDY_indelay : std_ulogic;
    signal TXUSRCLK2_indelay : std_ulogic;
    signal TXUSRCLK_indelay : std_ulogic;
    
    begin
    GTREFCLKMONITOR_out <= GTREFCLKMONITOR_outdelay after OUTCLK_DELAY;
    RXOUTCLK_out <= RXOUTCLK_outdelay after OUTCLK_DELAY;
    TXOUTCLK_out <= TXOUTCLK_outdelay after OUTCLK_DELAY;
    
    CPLLFBCLKLOST_out <= CPLLFBCLKLOST_outdelay after OUT_DELAY;
    CPLLLOCK_out <= CPLLLOCK_outdelay after OUT_DELAY;
    CPLLREFCLKLOST_out <= CPLLREFCLKLOST_outdelay after OUT_DELAY;
    DMONITOROUT_out <= DMONITOROUT_outdelay after OUT_DELAY;
    DRPDO_out <= DRPDO_outdelay after OUT_DELAY;
    DRPRDY_out <= DRPRDY_outdelay after OUT_DELAY;
    EYESCANDATAERROR_out <= EYESCANDATAERROR_outdelay after OUT_DELAY;
    GTHTXN_out <= GTHTXN_outdelay after OUT_DELAY;
    GTHTXP_out <= GTHTXP_outdelay after OUT_DELAY;
    PCSRSVDOUT_out <= PCSRSVDOUT_outdelay after OUT_DELAY;
    PHYSTATUS_out <= PHYSTATUS_outdelay after OUT_DELAY;
    RSOSINTDONE_out <= RSOSINTDONE_outdelay after OUT_DELAY;
    RXBUFSTATUS_out <= RXBUFSTATUS_outdelay after OUT_DELAY;
    RXBYTEISALIGNED_out <= RXBYTEISALIGNED_outdelay after OUT_DELAY;
    RXBYTEREALIGN_out <= RXBYTEREALIGN_outdelay after OUT_DELAY;
    RXCDRLOCK_out <= RXCDRLOCK_outdelay after OUT_DELAY;
    RXCHANBONDSEQ_out <= RXCHANBONDSEQ_outdelay after OUT_DELAY;
    RXCHANISALIGNED_out <= RXCHANISALIGNED_outdelay after OUT_DELAY;
    RXCHANREALIGN_out <= RXCHANREALIGN_outdelay after OUT_DELAY;
    RXCHARISCOMMA_out <= RXCHARISCOMMA_outdelay after OUT_DELAY;
    RXCHARISK_out <= RXCHARISK_outdelay after OUT_DELAY;
    RXCHBONDO_out <= RXCHBONDO_outdelay after OUT_DELAY;
    RXCLKCORCNT_out <= RXCLKCORCNT_outdelay after OUT_DELAY;
    RXCOMINITDET_out <= RXCOMINITDET_outdelay after OUT_DELAY;
    RXCOMMADET_out <= RXCOMMADET_outdelay after OUT_DELAY;
    RXCOMSASDET_out <= RXCOMSASDET_outdelay after OUT_DELAY;
    RXCOMWAKEDET_out <= RXCOMWAKEDET_outdelay after OUT_DELAY;
    RXDATAVALID_out <= RXDATAVALID_outdelay after OUT_DELAY;
    RXDATA_out <= RXDATA_outdelay after OUT_DELAY;
    RXDFESLIDETAPSTARTED_out <= RXDFESLIDETAPSTARTED_outdelay after OUT_DELAY;
    RXDFESLIDETAPSTROBEDONE_out <= RXDFESLIDETAPSTROBEDONE_outdelay after OUT_DELAY;
    RXDFESLIDETAPSTROBESTARTED_out <= RXDFESLIDETAPSTROBESTARTED_outdelay after OUT_DELAY;
    RXDFESTADAPTDONE_out <= RXDFESTADAPTDONE_outdelay after OUT_DELAY;
    RXDISPERR_out <= RXDISPERR_outdelay after OUT_DELAY;
    RXDLYSRESETDONE_out <= RXDLYSRESETDONE_outdelay after OUT_DELAY;
    RXELECIDLE_out <= RXELECIDLE_outdelay after OUT_DELAY;
    RXHEADERVALID_out <= RXHEADERVALID_outdelay after OUT_DELAY;
    RXHEADER_out <= RXHEADER_outdelay after OUT_DELAY;
    RXMONITOROUT_out <= RXMONITOROUT_outdelay after OUT_DELAY;
    RXNOTINTABLE_out <= RXNOTINTABLE_outdelay after OUT_DELAY;
    RXOSINTSTARTED_out <= RXOSINTSTARTED_outdelay after OUT_DELAY;
    RXOSINTSTROBEDONE_out <= RXOSINTSTROBEDONE_outdelay after OUT_DELAY;
    RXOSINTSTROBESTARTED_out <= RXOSINTSTROBESTARTED_outdelay after OUT_DELAY;
    RXOUTCLKFABRIC_out <= RXOUTCLKFABRIC_outdelay after OUT_DELAY;
    RXOUTCLKPCS_out <= RXOUTCLKPCS_outdelay after OUT_DELAY;
    RXPHALIGNDONE_out <= RXPHALIGNDONE_outdelay after OUT_DELAY;
    RXPHMONITOR_out <= RXPHMONITOR_outdelay after OUT_DELAY;
    RXPHSLIPMONITOR_out <= RXPHSLIPMONITOR_outdelay after OUT_DELAY;
    RXPMARESETDONE_out <= RXPMARESETDONE_outdelay after OUT_DELAY;
    RXPRBSERR_out <= RXPRBSERR_outdelay after OUT_DELAY;
    RXQPISENN_out <= RXQPISENN_outdelay after OUT_DELAY;
    RXQPISENP_out <= RXQPISENP_outdelay after OUT_DELAY;
    RXRATEDONE_out <= RXRATEDONE_outdelay after OUT_DELAY;
    RXRESETDONE_out <= RXRESETDONE_outdelay after OUT_DELAY;
    RXSTARTOFSEQ_out <= RXSTARTOFSEQ_outdelay after OUT_DELAY;
    RXSTATUS_out <= RXSTATUS_outdelay after OUT_DELAY;
    RXSYNCDONE_out <= RXSYNCDONE_outdelay after OUT_DELAY;
    RXSYNCOUT_out <= RXSYNCOUT_outdelay after OUT_DELAY;
    RXVALID_out <= RXVALID_outdelay after OUT_DELAY;
    TXBUFSTATUS_out <= TXBUFSTATUS_outdelay after OUT_DELAY;
    TXCOMFINISH_out <= TXCOMFINISH_outdelay after OUT_DELAY;
    TXDLYSRESETDONE_out <= TXDLYSRESETDONE_outdelay after OUT_DELAY;
    TXGEARBOXREADY_out <= TXGEARBOXREADY_outdelay after OUT_DELAY;
    TXOUTCLKFABRIC_out <= TXOUTCLKFABRIC_outdelay after OUT_DELAY;
    TXOUTCLKPCS_out <= TXOUTCLKPCS_outdelay after OUT_DELAY;
    TXPHALIGNDONE_out <= TXPHALIGNDONE_outdelay after OUT_DELAY;
    TXPHINITDONE_out <= TXPHINITDONE_outdelay after OUT_DELAY;
    TXPMARESETDONE_out <= TXPMARESETDONE_outdelay after OUT_DELAY;
    TXQPISENN_out <= TXQPISENN_outdelay after OUT_DELAY;
    TXQPISENP_out <= TXQPISENP_outdelay after OUT_DELAY;
    TXRATEDONE_out <= TXRATEDONE_outdelay after OUT_DELAY;
    TXRESETDONE_out <= TXRESETDONE_outdelay after OUT_DELAY;
    TXSYNCDONE_out <= TXSYNCDONE_outdelay after OUT_DELAY;
    TXSYNCOUT_out <= TXSYNCOUT_outdelay after OUT_DELAY;
    
    CLKRSVD0_ipd <= CLKRSVD0;
    CLKRSVD1_ipd <= CLKRSVD1;
    CPLLLOCKDETCLK_ipd <= CPLLLOCKDETCLK;
    DMONITORCLK_ipd <= DMONITORCLK;
    DRPCLK_ipd <= DRPCLK;
    GTGREFCLK_ipd <= GTGREFCLK;
    GTNORTHREFCLK0_ipd <= GTNORTHREFCLK0;
    GTNORTHREFCLK1_ipd <= GTNORTHREFCLK1;
    GTREFCLK0_ipd <= GTREFCLK0;
    GTREFCLK1_ipd <= GTREFCLK1;
    GTSOUTHREFCLK0_ipd <= GTSOUTHREFCLK0;
    GTSOUTHREFCLK1_ipd <= GTSOUTHREFCLK1;
    QPLLCLK_ipd <= QPLLCLK;
    RXUSRCLK2_ipd <= RXUSRCLK2;
    RXUSRCLK_ipd <= RXUSRCLK;
    SIGVALIDCLK_ipd <= SIGVALIDCLK;
    TXPHDLYTSTCLK_ipd <= TXPHDLYTSTCLK;
    TXUSRCLK2_ipd <= TXUSRCLK2;
    TXUSRCLK_ipd <= TXUSRCLK;
    
    CFGRESET_ipd <= CFGRESET;
    CPLLLOCKEN_ipd <= CPLLLOCKEN;
    CPLLPD_ipd <= CPLLPD;
    CPLLREFCLKSEL_ipd <= CPLLREFCLKSEL;
    CPLLRESET_ipd <= CPLLRESET;
    DMONFIFORESET_ipd <= DMONFIFORESET;
    DRPADDR_ipd <= DRPADDR;
    DRPDI_ipd <= DRPDI;
    DRPEN_ipd <= DRPEN;
    DRPWE_ipd <= DRPWE;
    EYESCANMODE_ipd <= EYESCANMODE;
    EYESCANRESET_ipd <= EYESCANRESET;
    EYESCANTRIGGER_ipd <= EYESCANTRIGGER;
    GTHRXN_ipd <= GTHRXN;
    GTHRXP_ipd <= GTHRXP;
    GTRESETSEL_ipd <= GTRESETSEL;
    GTRSVD_ipd <= GTRSVD;
    GTRXRESET_ipd <= GTRXRESET;
    GTTXRESET_ipd <= GTTXRESET;
    LOOPBACK_ipd <= LOOPBACK;
    PCSRSVDIN2_ipd <= PCSRSVDIN2;
    PCSRSVDIN_ipd <= PCSRSVDIN;
    PMARSVDIN_ipd <= PMARSVDIN;
    QPLLREFCLK_ipd <= QPLLREFCLK;
    RESETOVRD_ipd <= RESETOVRD;
    RX8B10BEN_ipd <= RX8B10BEN;
    RXADAPTSELTEST_ipd <= RXADAPTSELTEST;
    RXBUFRESET_ipd <= RXBUFRESET;
    RXCDRFREQRESET_ipd <= RXCDRFREQRESET;
    RXCDRHOLD_ipd <= RXCDRHOLD;
    RXCDROVRDEN_ipd <= RXCDROVRDEN;
    RXCDRRESETRSV_ipd <= RXCDRRESETRSV;
    RXCDRRESET_ipd <= RXCDRRESET;
    RXCHBONDEN_ipd <= RXCHBONDEN;
    RXCHBONDI_ipd <= RXCHBONDI;
    RXCHBONDLEVEL_ipd <= RXCHBONDLEVEL;
    RXCHBONDMASTER_ipd <= RXCHBONDMASTER;
    RXCHBONDSLAVE_ipd <= RXCHBONDSLAVE;
    RXCOMMADETEN_ipd <= RXCOMMADETEN;
    RXDDIEN_ipd <= RXDDIEN;
    RXDFEAGCHOLD_ipd <= RXDFEAGCHOLD;
    RXDFEAGCOVRDEN_ipd <= RXDFEAGCOVRDEN;
    RXDFEAGCTRL_ipd <= RXDFEAGCTRL;
    RXDFECM1EN_ipd <= RXDFECM1EN;
    RXDFELFHOLD_ipd <= RXDFELFHOLD;
    RXDFELFOVRDEN_ipd <= RXDFELFOVRDEN;
    RXDFELPMRESET_ipd <= RXDFELPMRESET;
    RXDFESLIDETAPADAPTEN_ipd <= RXDFESLIDETAPADAPTEN;
    RXDFESLIDETAPHOLD_ipd <= RXDFESLIDETAPHOLD;
    RXDFESLIDETAPID_ipd <= RXDFESLIDETAPID;
    RXDFESLIDETAPINITOVRDEN_ipd <= RXDFESLIDETAPINITOVRDEN;
    RXDFESLIDETAPONLYADAPTEN_ipd <= RXDFESLIDETAPONLYADAPTEN;
    RXDFESLIDETAPOVRDEN_ipd <= RXDFESLIDETAPOVRDEN;
    RXDFESLIDETAPSTROBE_ipd <= RXDFESLIDETAPSTROBE;
    RXDFESLIDETAP_ipd <= RXDFESLIDETAP;
    RXDFETAP2HOLD_ipd <= RXDFETAP2HOLD;
    RXDFETAP2OVRDEN_ipd <= RXDFETAP2OVRDEN;
    RXDFETAP3HOLD_ipd <= RXDFETAP3HOLD;
    RXDFETAP3OVRDEN_ipd <= RXDFETAP3OVRDEN;
    RXDFETAP4HOLD_ipd <= RXDFETAP4HOLD;
    RXDFETAP4OVRDEN_ipd <= RXDFETAP4OVRDEN;
    RXDFETAP5HOLD_ipd <= RXDFETAP5HOLD;
    RXDFETAP5OVRDEN_ipd <= RXDFETAP5OVRDEN;
    RXDFETAP6HOLD_ipd <= RXDFETAP6HOLD;
    RXDFETAP6OVRDEN_ipd <= RXDFETAP6OVRDEN;
    RXDFETAP7HOLD_ipd <= RXDFETAP7HOLD;
    RXDFETAP7OVRDEN_ipd <= RXDFETAP7OVRDEN;
    RXDFEUTHOLD_ipd <= RXDFEUTHOLD;
    RXDFEUTOVRDEN_ipd <= RXDFEUTOVRDEN;
    RXDFEVPHOLD_ipd <= RXDFEVPHOLD;
    RXDFEVPOVRDEN_ipd <= RXDFEVPOVRDEN;
    RXDFEVSEN_ipd <= RXDFEVSEN;
    RXDFEXYDEN_ipd <= RXDFEXYDEN;
    RXDLYBYPASS_ipd <= RXDLYBYPASS;
    RXDLYEN_ipd <= RXDLYEN;
    RXDLYOVRDEN_ipd <= RXDLYOVRDEN;
    RXDLYSRESET_ipd <= RXDLYSRESET;
    RXELECIDLEMODE_ipd <= RXELECIDLEMODE;
    RXGEARBOXSLIP_ipd <= RXGEARBOXSLIP;
    RXLPMEN_ipd <= RXLPMEN;
    RXLPMHFHOLD_ipd <= RXLPMHFHOLD;
    RXLPMHFOVRDEN_ipd <= RXLPMHFOVRDEN;
    RXLPMLFHOLD_ipd <= RXLPMLFHOLD;
    RXLPMLFKLOVRDEN_ipd <= RXLPMLFKLOVRDEN;
    RXMCOMMAALIGNEN_ipd <= RXMCOMMAALIGNEN;
    RXMONITORSEL_ipd <= RXMONITORSEL;
    RXOOBRESET_ipd <= RXOOBRESET;
    RXOSCALRESET_ipd <= RXOSCALRESET;
    RXOSHOLD_ipd <= RXOSHOLD;
    RXOSINTCFG_ipd <= RXOSINTCFG;
    RXOSINTEN_ipd <= RXOSINTEN;
    RXOSINTHOLD_ipd <= RXOSINTHOLD;
    RXOSINTID0_ipd <= RXOSINTID0;
    RXOSINTNTRLEN_ipd <= RXOSINTNTRLEN;
    RXOSINTOVRDEN_ipd <= RXOSINTOVRDEN;
    RXOSINTSTROBE_ipd <= RXOSINTSTROBE;
    RXOSINTTESTOVRDEN_ipd <= RXOSINTTESTOVRDEN;
    RXOSOVRDEN_ipd <= RXOSOVRDEN;
    RXOUTCLKSEL_ipd <= RXOUTCLKSEL;
    RXPCOMMAALIGNEN_ipd <= RXPCOMMAALIGNEN;
    RXPCSRESET_ipd <= RXPCSRESET;
    RXPD_ipd <= RXPD;
    RXPHALIGNEN_ipd <= RXPHALIGNEN;
    RXPHALIGN_ipd <= RXPHALIGN;
    RXPHDLYPD_ipd <= RXPHDLYPD;
    RXPHDLYRESET_ipd <= RXPHDLYRESET;
    RXPHOVRDEN_ipd <= RXPHOVRDEN;
    RXPMARESET_ipd <= RXPMARESET;
    RXPOLARITY_ipd <= RXPOLARITY;
    RXPRBSCNTRESET_ipd <= RXPRBSCNTRESET;
    RXPRBSSEL_ipd <= RXPRBSSEL;
    RXQPIEN_ipd <= RXQPIEN;
    RXRATEMODE_ipd <= RXRATEMODE;
    RXRATE_ipd <= RXRATE;
    RXSLIDE_ipd <= RXSLIDE;
    RXSYNCALLIN_ipd <= RXSYNCALLIN;
    RXSYNCIN_ipd <= RXSYNCIN;
    RXSYNCMODE_ipd <= RXSYNCMODE;
    RXSYSCLKSEL_ipd <= RXSYSCLKSEL;
    RXUSERRDY_ipd <= RXUSERRDY;
    SETERRSTATUS_ipd <= SETERRSTATUS;
    TSTIN_ipd <= TSTIN;
    TX8B10BBYPASS_ipd <= TX8B10BBYPASS;
    TX8B10BEN_ipd <= TX8B10BEN;
    TXBUFDIFFCTRL_ipd <= TXBUFDIFFCTRL;
    TXCHARDISPMODE_ipd <= TXCHARDISPMODE;
    TXCHARDISPVAL_ipd <= TXCHARDISPVAL;
    TXCHARISK_ipd <= TXCHARISK;
    TXCOMINIT_ipd <= TXCOMINIT;
    TXCOMSAS_ipd <= TXCOMSAS;
    TXCOMWAKE_ipd <= TXCOMWAKE;
    TXDATA_ipd <= TXDATA;
    TXDEEMPH_ipd <= TXDEEMPH;
    TXDETECTRX_ipd <= TXDETECTRX;
    TXDIFFCTRL_ipd <= TXDIFFCTRL;
    TXDIFFPD_ipd <= TXDIFFPD;
    TXDLYBYPASS_ipd <= TXDLYBYPASS;
    TXDLYEN_ipd <= TXDLYEN;
    TXDLYHOLD_ipd <= TXDLYHOLD;
    TXDLYOVRDEN_ipd <= TXDLYOVRDEN;
    TXDLYSRESET_ipd <= TXDLYSRESET;
    TXDLYUPDOWN_ipd <= TXDLYUPDOWN;
    TXELECIDLE_ipd <= TXELECIDLE;
    TXHEADER_ipd <= TXHEADER;
    TXINHIBIT_ipd <= TXINHIBIT;
    TXMAINCURSOR_ipd <= TXMAINCURSOR;
    TXMARGIN_ipd <= TXMARGIN;
    TXOUTCLKSEL_ipd <= TXOUTCLKSEL;
    TXPCSRESET_ipd <= TXPCSRESET;
    TXPDELECIDLEMODE_ipd <= TXPDELECIDLEMODE;
    TXPD_ipd <= TXPD;
    TXPHALIGNEN_ipd <= TXPHALIGNEN;
    TXPHALIGN_ipd <= TXPHALIGN;
    TXPHDLYPD_ipd <= TXPHDLYPD;
    TXPHDLYRESET_ipd <= TXPHDLYRESET;
    TXPHINIT_ipd <= TXPHINIT;
    TXPHOVRDEN_ipd <= TXPHOVRDEN;
    TXPIPPMEN_ipd <= TXPIPPMEN;
    TXPIPPMOVRDEN_ipd <= TXPIPPMOVRDEN;
    TXPIPPMPD_ipd <= TXPIPPMPD;
    TXPIPPMSEL_ipd <= TXPIPPMSEL;
    TXPIPPMSTEPSIZE_ipd <= TXPIPPMSTEPSIZE;
    TXPISOPD_ipd <= TXPISOPD;
    TXPMARESET_ipd <= TXPMARESET;
    TXPOLARITY_ipd <= TXPOLARITY;
    TXPOSTCURSORINV_ipd <= TXPOSTCURSORINV;
    TXPOSTCURSOR_ipd <= TXPOSTCURSOR;
    TXPRBSFORCEERR_ipd <= TXPRBSFORCEERR;
    TXPRBSSEL_ipd <= TXPRBSSEL;
    TXPRECURSORINV_ipd <= TXPRECURSORINV;
    TXPRECURSOR_ipd <= TXPRECURSOR;
    TXQPIBIASEN_ipd <= TXQPIBIASEN;
    TXQPISTRONGPDOWN_ipd <= TXQPISTRONGPDOWN;
    TXQPIWEAKPUP_ipd <= TXQPIWEAKPUP;
    TXRATEMODE_ipd <= TXRATEMODE;
    TXRATE_ipd <= TXRATE;
    TXSEQUENCE_ipd <= TXSEQUENCE;
    TXSTARTSEQ_ipd <= TXSTARTSEQ;
    TXSWING_ipd <= TXSWING;
    TXSYNCALLIN_ipd <= TXSYNCALLIN;
    TXSYNCIN_ipd <= TXSYNCIN;
    TXSYNCMODE_ipd <= TXSYNCMODE;
    TXSYSCLKSEL_ipd <= TXSYSCLKSEL;
    TXUSERRDY_ipd <= TXUSERRDY;
    
    CLKRSVD0_indelay <= CLKRSVD0_ipd xor IS_CLKRSVD0_INVERTED_BIN;
    CLKRSVD1_indelay <= CLKRSVD1_ipd xor IS_CLKRSVD1_INVERTED_BIN;
    CPLLLOCKDETCLK_indelay <= CPLLLOCKDETCLK_ipd xor IS_CPLLLOCKDETCLK_INVERTED_BIN;
    DMONITORCLK_indelay <= DMONITORCLK_ipd xor IS_DMONITORCLK_INVERTED_BIN;
    DRPCLK_indelay <= DRPCLK_ipd xor IS_DRPCLK_INVERTED_BIN;
    GTGREFCLK_indelay <= GTGREFCLK_ipd xor IS_GTGREFCLK_INVERTED_BIN;
    GTNORTHREFCLK0_indelay <= GTNORTHREFCLK0_ipd after INCLK_DELAY;
    GTNORTHREFCLK1_indelay <= GTNORTHREFCLK1_ipd after INCLK_DELAY;
    GTREFCLK0_indelay <= GTREFCLK0_ipd after INCLK_DELAY;
    GTREFCLK1_indelay <= GTREFCLK1_ipd after INCLK_DELAY;
    GTSOUTHREFCLK0_indelay <= GTSOUTHREFCLK0_ipd after INCLK_DELAY;
    GTSOUTHREFCLK1_indelay <= GTSOUTHREFCLK1_ipd after INCLK_DELAY;
    QPLLCLK_indelay <= QPLLCLK_ipd after INCLK_DELAY;
    RXUSRCLK2_indelay <= RXUSRCLK2_ipd xor IS_RXUSRCLK2_INVERTED_BIN;
    RXUSRCLK_indelay <= RXUSRCLK_ipd xor IS_RXUSRCLK_INVERTED_BIN;
    SIGVALIDCLK_indelay <= SIGVALIDCLK_ipd xor IS_SIGVALIDCLK_INVERTED_BIN;
    TXPHDLYTSTCLK_indelay <= TXPHDLYTSTCLK_ipd xor IS_TXPHDLYTSTCLK_INVERTED_BIN;
    TXUSRCLK2_indelay <= TXUSRCLK2_ipd xor IS_TXUSRCLK2_INVERTED_BIN;
    TXUSRCLK_indelay <= TXUSRCLK_ipd xor IS_TXUSRCLK2_INVERTED_BIN;
    
    CFGRESET_indelay <= CFGRESET_ipd after IN_DELAY;
    CPLLLOCKEN_indelay <= CPLLLOCKEN_ipd after IN_DELAY;
    CPLLPD_indelay <= CPLLPD_ipd after IN_DELAY;
    CPLLREFCLKSEL_indelay <= CPLLREFCLKSEL_ipd after IN_DELAY;
    CPLLRESET_indelay <= CPLLRESET_ipd after IN_DELAY;
    DMONFIFORESET_indelay <= DMONFIFORESET_ipd after IN_DELAY;
    DRPADDR_indelay <= DRPADDR_ipd after IN_DELAY;
    DRPDI_indelay <= DRPDI_ipd after IN_DELAY;
    DRPEN_indelay <= DRPEN_ipd after IN_DELAY;
    DRPWE_indelay <= DRPWE_ipd after IN_DELAY;
    EYESCANMODE_indelay <= EYESCANMODE_ipd after IN_DELAY;
    EYESCANRESET_indelay <= EYESCANRESET_ipd after IN_DELAY;
    EYESCANTRIGGER_indelay <= EYESCANTRIGGER_ipd after IN_DELAY;
    GTHRXN_indelay <= GTHRXN_ipd after IN_DELAY;
    GTHRXP_indelay <= GTHRXP_ipd after IN_DELAY;
    GTRESETSEL_indelay <= GTRESETSEL_ipd after IN_DELAY;
    GTRSVD_indelay <= GTRSVD_ipd after IN_DELAY;
    GTRXRESET_indelay <= GTRXRESET_ipd after IN_DELAY;
    GTTXRESET_indelay <= GTTXRESET_ipd after IN_DELAY;
    LOOPBACK_indelay <= LOOPBACK_ipd after IN_DELAY;
    PCSRSVDIN2_indelay <= PCSRSVDIN2_ipd after IN_DELAY;
    PCSRSVDIN_indelay <= PCSRSVDIN_ipd after IN_DELAY;
    PMARSVDIN_indelay <= PMARSVDIN_ipd after IN_DELAY;
    QPLLREFCLK_indelay <= QPLLREFCLK_ipd after IN_DELAY;
    RESETOVRD_indelay <= RESETOVRD_ipd after IN_DELAY;
    RX8B10BEN_indelay <= RX8B10BEN_ipd after IN_DELAY;
    RXADAPTSELTEST_indelay <= RXADAPTSELTEST_ipd after IN_DELAY;
    RXBUFRESET_indelay <= RXBUFRESET_ipd after IN_DELAY;
    RXCDRFREQRESET_indelay <= RXCDRFREQRESET_ipd after IN_DELAY;
    RXCDRHOLD_indelay <= RXCDRHOLD_ipd after IN_DELAY;
    RXCDROVRDEN_indelay <= RXCDROVRDEN_ipd after IN_DELAY;
    RXCDRRESETRSV_indelay <= RXCDRRESETRSV_ipd after IN_DELAY;
    RXCDRRESET_indelay <= RXCDRRESET_ipd after IN_DELAY;
    RXCHBONDEN_indelay <= RXCHBONDEN_ipd after IN_DELAY;
    RXCHBONDI_indelay <= RXCHBONDI_ipd after IN_DELAY;
    RXCHBONDLEVEL_indelay <= RXCHBONDLEVEL_ipd after IN_DELAY;
    RXCHBONDMASTER_indelay <= RXCHBONDMASTER_ipd after IN_DELAY;
    RXCHBONDSLAVE_indelay <= RXCHBONDSLAVE_ipd after IN_DELAY;
    RXCOMMADETEN_indelay <= RXCOMMADETEN_ipd after IN_DELAY;
    RXDDIEN_indelay <= RXDDIEN_ipd after IN_DELAY;
    RXDFEAGCHOLD_indelay <= RXDFEAGCHOLD_ipd after IN_DELAY;
    RXDFEAGCOVRDEN_indelay <= RXDFEAGCOVRDEN_ipd after IN_DELAY;
    RXDFEAGCTRL_indelay <= RXDFEAGCTRL_ipd after IN_DELAY;
    RXDFECM1EN_indelay <= RXDFECM1EN_ipd after IN_DELAY;
    RXDFELFHOLD_indelay <= RXDFELFHOLD_ipd after IN_DELAY;
    RXDFELFOVRDEN_indelay <= RXDFELFOVRDEN_ipd after IN_DELAY;
    RXDFELPMRESET_indelay <= RXDFELPMRESET_ipd after IN_DELAY;
    RXDFESLIDETAPADAPTEN_indelay <= RXDFESLIDETAPADAPTEN_ipd after IN_DELAY;
    RXDFESLIDETAPHOLD_indelay <= RXDFESLIDETAPHOLD_ipd after IN_DELAY;
    RXDFESLIDETAPID_indelay <= RXDFESLIDETAPID_ipd after IN_DELAY;
    RXDFESLIDETAPINITOVRDEN_indelay <= RXDFESLIDETAPINITOVRDEN_ipd after IN_DELAY;
    RXDFESLIDETAPONLYADAPTEN_indelay <= RXDFESLIDETAPONLYADAPTEN_ipd after IN_DELAY;
    RXDFESLIDETAPOVRDEN_indelay <= RXDFESLIDETAPOVRDEN_ipd after IN_DELAY;
    RXDFESLIDETAPSTROBE_indelay <= RXDFESLIDETAPSTROBE_ipd after IN_DELAY;
    RXDFESLIDETAP_indelay <= RXDFESLIDETAP_ipd after IN_DELAY;
    RXDFETAP2HOLD_indelay <= RXDFETAP2HOLD_ipd after IN_DELAY;
    RXDFETAP2OVRDEN_indelay <= RXDFETAP2OVRDEN_ipd after IN_DELAY;
    RXDFETAP3HOLD_indelay <= RXDFETAP3HOLD_ipd after IN_DELAY;
    RXDFETAP3OVRDEN_indelay <= RXDFETAP3OVRDEN_ipd after IN_DELAY;
    RXDFETAP4HOLD_indelay <= RXDFETAP4HOLD_ipd after IN_DELAY;
    RXDFETAP4OVRDEN_indelay <= RXDFETAP4OVRDEN_ipd after IN_DELAY;
    RXDFETAP5HOLD_indelay <= RXDFETAP5HOLD_ipd after IN_DELAY;
    RXDFETAP5OVRDEN_indelay <= RXDFETAP5OVRDEN_ipd after IN_DELAY;
    RXDFETAP6HOLD_indelay <= RXDFETAP6HOLD_ipd after IN_DELAY;
    RXDFETAP6OVRDEN_indelay <= RXDFETAP6OVRDEN_ipd after IN_DELAY;
    RXDFETAP7HOLD_indelay <= RXDFETAP7HOLD_ipd after IN_DELAY;
    RXDFETAP7OVRDEN_indelay <= RXDFETAP7OVRDEN_ipd after IN_DELAY;
    RXDFEUTHOLD_indelay <= RXDFEUTHOLD_ipd after IN_DELAY;
    RXDFEUTOVRDEN_indelay <= RXDFEUTOVRDEN_ipd after IN_DELAY;
    RXDFEVPHOLD_indelay <= RXDFEVPHOLD_ipd after IN_DELAY;
    RXDFEVPOVRDEN_indelay <= RXDFEVPOVRDEN_ipd after IN_DELAY;
    RXDFEVSEN_indelay <= RXDFEVSEN_ipd after IN_DELAY;
    RXDFEXYDEN_indelay <= RXDFEXYDEN_ipd after IN_DELAY;
    RXDLYBYPASS_indelay <= RXDLYBYPASS_ipd after IN_DELAY;
    RXDLYEN_indelay <= RXDLYEN_ipd after IN_DELAY;
    RXDLYOVRDEN_indelay <= RXDLYOVRDEN_ipd after IN_DELAY;
    RXDLYSRESET_indelay <= RXDLYSRESET_ipd after IN_DELAY;
    RXELECIDLEMODE_indelay <= RXELECIDLEMODE_ipd after IN_DELAY;
    RXGEARBOXSLIP_indelay <= RXGEARBOXSLIP_ipd after IN_DELAY;
    RXLPMEN_indelay <= RXLPMEN_ipd after IN_DELAY;
    RXLPMHFHOLD_indelay <= RXLPMHFHOLD_ipd after IN_DELAY;
    RXLPMHFOVRDEN_indelay <= RXLPMHFOVRDEN_ipd after IN_DELAY;
    RXLPMLFHOLD_indelay <= RXLPMLFHOLD_ipd after IN_DELAY;
    RXLPMLFKLOVRDEN_indelay <= RXLPMLFKLOVRDEN_ipd after IN_DELAY;
    RXMCOMMAALIGNEN_indelay <= RXMCOMMAALIGNEN_ipd after IN_DELAY;
    RXMONITORSEL_indelay <= RXMONITORSEL_ipd after IN_DELAY;
    RXOOBRESET_indelay <= RXOOBRESET_ipd after IN_DELAY;
    RXOSCALRESET_indelay <= RXOSCALRESET_ipd after IN_DELAY;
    RXOSHOLD_indelay <= RXOSHOLD_ipd after IN_DELAY;
    RXOSINTCFG_indelay <= RXOSINTCFG_ipd after IN_DELAY;
    RXOSINTEN_indelay <= RXOSINTEN_ipd after IN_DELAY;
    RXOSINTHOLD_indelay <= RXOSINTHOLD_ipd after IN_DELAY;
    RXOSINTID0_indelay <= RXOSINTID0_ipd after IN_DELAY;
    RXOSINTNTRLEN_indelay <= RXOSINTNTRLEN_ipd after IN_DELAY;
    RXOSINTOVRDEN_indelay <= RXOSINTOVRDEN_ipd after IN_DELAY;
    RXOSINTSTROBE_indelay <= RXOSINTSTROBE_ipd after IN_DELAY;
    RXOSINTTESTOVRDEN_indelay <= RXOSINTTESTOVRDEN_ipd after IN_DELAY;
    RXOSOVRDEN_indelay <= RXOSOVRDEN_ipd after IN_DELAY;
    RXOUTCLKSEL_indelay <= RXOUTCLKSEL_ipd after IN_DELAY;
    RXPCOMMAALIGNEN_indelay <= RXPCOMMAALIGNEN_ipd after IN_DELAY;
    RXPCSRESET_indelay <= RXPCSRESET_ipd after IN_DELAY;
    RXPD_indelay <= RXPD_ipd after IN_DELAY;
    RXPHALIGNEN_indelay <= RXPHALIGNEN_ipd after IN_DELAY;
    RXPHALIGN_indelay <= RXPHALIGN_ipd after IN_DELAY;
    RXPHDLYPD_indelay <= RXPHDLYPD_ipd after IN_DELAY;
    RXPHDLYRESET_indelay <= RXPHDLYRESET_ipd after IN_DELAY;
    RXPHOVRDEN_indelay <= RXPHOVRDEN_ipd after IN_DELAY;
    RXPMARESET_indelay <= RXPMARESET_ipd after IN_DELAY;
    RXPOLARITY_indelay <= RXPOLARITY_ipd after IN_DELAY;
    RXPRBSCNTRESET_indelay <= RXPRBSCNTRESET_ipd after IN_DELAY;
    RXPRBSSEL_indelay <= RXPRBSSEL_ipd after IN_DELAY;
    RXQPIEN_indelay <= RXQPIEN_ipd after IN_DELAY;
    RXRATEMODE_indelay <= RXRATEMODE_ipd after IN_DELAY;
    RXRATE_indelay <= RXRATE_ipd after IN_DELAY;
    RXSLIDE_indelay <= RXSLIDE_ipd after IN_DELAY;
    RXSYNCALLIN_indelay <= RXSYNCALLIN_ipd after IN_DELAY;
    RXSYNCIN_indelay <= RXSYNCIN_ipd after IN_DELAY;
    RXSYNCMODE_indelay <= RXSYNCMODE_ipd after IN_DELAY;
    RXSYSCLKSEL_indelay <= RXSYSCLKSEL_ipd after IN_DELAY;
    RXUSERRDY_indelay <= RXUSERRDY_ipd after IN_DELAY;
    SETERRSTATUS_indelay <= SETERRSTATUS_ipd after IN_DELAY;
    TSTIN_indelay <= TSTIN_ipd after IN_DELAY;
    TX8B10BBYPASS_indelay <= TX8B10BBYPASS_ipd after IN_DELAY;
    TX8B10BEN_indelay <= TX8B10BEN_ipd after IN_DELAY;
    TXBUFDIFFCTRL_indelay <= TXBUFDIFFCTRL_ipd after IN_DELAY;
    TXCHARDISPMODE_indelay <= TXCHARDISPMODE_ipd after IN_DELAY;
    TXCHARDISPVAL_indelay <= TXCHARDISPVAL_ipd after IN_DELAY;
    TXCHARISK_indelay <= TXCHARISK_ipd after IN_DELAY;
    TXCOMINIT_indelay <= TXCOMINIT_ipd after IN_DELAY;
    TXCOMSAS_indelay <= TXCOMSAS_ipd after IN_DELAY;
    TXCOMWAKE_indelay <= TXCOMWAKE_ipd after IN_DELAY;
    TXDATA_indelay <= TXDATA_ipd after IN_DELAY;
    TXDEEMPH_indelay <= TXDEEMPH_ipd after IN_DELAY;
    TXDETECTRX_indelay <= TXDETECTRX_ipd after IN_DELAY;
    TXDIFFCTRL_indelay <= TXDIFFCTRL_ipd after IN_DELAY;
    TXDIFFPD_indelay <= TXDIFFPD_ipd after IN_DELAY;
    TXDLYBYPASS_indelay <= TXDLYBYPASS_ipd after IN_DELAY;
    TXDLYEN_indelay <= TXDLYEN_ipd after IN_DELAY;
    TXDLYHOLD_indelay <= TXDLYHOLD_ipd after IN_DELAY;
    TXDLYOVRDEN_indelay <= TXDLYOVRDEN_ipd after IN_DELAY;
    TXDLYSRESET_indelay <= TXDLYSRESET_ipd after IN_DELAY;
    TXDLYUPDOWN_indelay <= TXDLYUPDOWN_ipd after IN_DELAY;
    TXELECIDLE_indelay <= TXELECIDLE_ipd after IN_DELAY;
    TXHEADER_indelay <= TXHEADER_ipd after IN_DELAY;
    TXINHIBIT_indelay <= TXINHIBIT_ipd after IN_DELAY;
    TXMAINCURSOR_indelay <= TXMAINCURSOR_ipd after IN_DELAY;
    TXMARGIN_indelay <= TXMARGIN_ipd after IN_DELAY;
    TXOUTCLKSEL_indelay <= TXOUTCLKSEL_ipd after IN_DELAY;
    TXPCSRESET_indelay <= TXPCSRESET_ipd after IN_DELAY;
    TXPDELECIDLEMODE_indelay <= TXPDELECIDLEMODE_ipd after IN_DELAY;
    TXPD_indelay <= TXPD_ipd after IN_DELAY;
    TXPHALIGNEN_indelay <= TXPHALIGNEN_ipd after IN_DELAY;
    TXPHALIGN_indelay <= TXPHALIGN_ipd after IN_DELAY;
    TXPHDLYPD_indelay <= TXPHDLYPD_ipd after IN_DELAY;
    TXPHDLYRESET_indelay <= TXPHDLYRESET_ipd after IN_DELAY;
    TXPHINIT_indelay <= TXPHINIT_ipd after IN_DELAY;
    TXPHOVRDEN_indelay <= TXPHOVRDEN_ipd after IN_DELAY;
    TXPIPPMEN_indelay <= TXPIPPMEN_ipd after IN_DELAY;
    TXPIPPMOVRDEN_indelay <= TXPIPPMOVRDEN_ipd after IN_DELAY;
    TXPIPPMPD_indelay <= TXPIPPMPD_ipd after IN_DELAY;
    TXPIPPMSEL_indelay <= TXPIPPMSEL_ipd after IN_DELAY;
    TXPIPPMSTEPSIZE_indelay <= TXPIPPMSTEPSIZE_ipd after IN_DELAY;
    TXPISOPD_indelay <= TXPISOPD_ipd after IN_DELAY;
    TXPMARESET_indelay <= TXPMARESET_ipd after IN_DELAY;
    TXPOLARITY_indelay <= TXPOLARITY_ipd after IN_DELAY;
    TXPOSTCURSORINV_indelay <= TXPOSTCURSORINV_ipd after IN_DELAY;
    TXPOSTCURSOR_indelay <= TXPOSTCURSOR_ipd after IN_DELAY;
    TXPRBSFORCEERR_indelay <= TXPRBSFORCEERR_ipd after IN_DELAY;
    TXPRBSSEL_indelay <= TXPRBSSEL_ipd after IN_DELAY;
    TXPRECURSORINV_indelay <= TXPRECURSORINV_ipd after IN_DELAY;
    TXPRECURSOR_indelay <= TXPRECURSOR_ipd after IN_DELAY;
    TXQPIBIASEN_indelay <= TXQPIBIASEN_ipd after IN_DELAY;
    TXQPISTRONGPDOWN_indelay <= TXQPISTRONGPDOWN_ipd after IN_DELAY;
    TXQPIWEAKPUP_indelay <= TXQPIWEAKPUP_ipd after IN_DELAY;
    TXRATEMODE_indelay <= TXRATEMODE_ipd after IN_DELAY;
    TXRATE_indelay <= TXRATE_ipd after IN_DELAY;
    TXSEQUENCE_indelay <= TXSEQUENCE_ipd after IN_DELAY;
    TXSTARTSEQ_indelay <= TXSTARTSEQ_ipd after IN_DELAY;
    TXSWING_indelay <= TXSWING_ipd after IN_DELAY;
    TXSYNCALLIN_indelay <= TXSYNCALLIN_ipd after IN_DELAY;
    TXSYNCIN_indelay <= TXSYNCIN_ipd after IN_DELAY;
    TXSYNCMODE_indelay <= TXSYNCMODE_ipd after IN_DELAY;
    TXSYSCLKSEL_indelay <= TXSYSCLKSEL_ipd after IN_DELAY;
    TXUSERRDY_indelay <= TXUSERRDY_ipd after IN_DELAY;

    IS_CLKRSVD0_INVERTED_BIN <= TO_X01(IS_CLKRSVD0_INVERTED);
    IS_CLKRSVD1_INVERTED_BIN <= TO_X01(IS_CLKRSVD1_INVERTED);
    IS_CPLLLOCKDETCLK_INVERTED_BIN <= TO_X01(IS_CPLLLOCKDETCLK_INVERTED);
    IS_DMONITORCLK_INVERTED_BIN <= TO_X01(IS_DMONITORCLK_INVERTED);
    IS_DRPCLK_INVERTED_BIN  <= TO_X01(IS_DRPCLK_INVERTED);
    IS_GTGREFCLK_INVERTED_BIN <= TO_X01(IS_GTGREFCLK_INVERTED);
    IS_RXUSRCLK2_INVERTED_BIN <= TO_X01(IS_RXUSRCLK2_INVERTED);
    IS_RXUSRCLK_INVERTED_BIN <= TO_X01(IS_RXUSRCLK_INVERTED);
    IS_SIGVALIDCLK_INVERTED_BIN <= TO_X01(IS_SIGVALIDCLK_INVERTED);
    IS_TXPHDLYTSTCLK_INVERTED_BIN <= TO_X01(IS_TXPHDLYTSTCLK_INVERTED);
    IS_TXUSRCLK2_INVERTED_BIN <= TO_X01(IS_TXUSRCLK2_INVERTED);
    IS_TXUSRCLK_INVERTED_BIN <= TO_X01(IS_TXUSRCLK_INVERTED);
     
    
    GTHE2_CHANNEL_INST : GTHE2_CHANNEL_FAST_WRAP
      generic map (
        ACJTAG_DEBUG_MODE    => ACJTAG_DEBUG_MODE_STRING,
        ACJTAG_MODE          => ACJTAG_MODE_STRING,
        ACJTAG_RESET         => ACJTAG_RESET_STRING,
        ADAPT_CFG0           => ADAPT_CFG0_STRING,
        ALIGN_COMMA_DOUBLE   => ALIGN_COMMA_DOUBLE,
        ALIGN_COMMA_ENABLE   => ALIGN_COMMA_ENABLE_STRING,
        ALIGN_COMMA_WORD     => ALIGN_COMMA_WORD,
        ALIGN_MCOMMA_DET     => ALIGN_MCOMMA_DET,
        ALIGN_MCOMMA_VALUE   => ALIGN_MCOMMA_VALUE_STRING,
        ALIGN_PCOMMA_DET     => ALIGN_PCOMMA_DET,
        ALIGN_PCOMMA_VALUE   => ALIGN_PCOMMA_VALUE_STRING,
        A_RXOSCALRESET       => A_RXOSCALRESET_STRING,
        CBCC_DATA_SOURCE_SEL => CBCC_DATA_SOURCE_SEL,
        CFOK_CFG             => CFOK_CFG_STRING,
        CFOK_CFG2            => CFOK_CFG2_STRING,
        CFOK_CFG3            => CFOK_CFG3_STRING,
        CHAN_BOND_KEEP_ALIGN => CHAN_BOND_KEEP_ALIGN,
        CHAN_BOND_MAX_SKEW   => CHAN_BOND_MAX_SKEW,
        CHAN_BOND_SEQ_1_1    => CHAN_BOND_SEQ_1_1_STRING,
        CHAN_BOND_SEQ_1_2    => CHAN_BOND_SEQ_1_2_STRING,
        CHAN_BOND_SEQ_1_3    => CHAN_BOND_SEQ_1_3_STRING,
        CHAN_BOND_SEQ_1_4    => CHAN_BOND_SEQ_1_4_STRING,
        CHAN_BOND_SEQ_1_ENABLE => CHAN_BOND_SEQ_1_ENABLE_STRING,
        CHAN_BOND_SEQ_2_1    => CHAN_BOND_SEQ_2_1_STRING,
        CHAN_BOND_SEQ_2_2    => CHAN_BOND_SEQ_2_2_STRING,
        CHAN_BOND_SEQ_2_3    => CHAN_BOND_SEQ_2_3_STRING,
        CHAN_BOND_SEQ_2_4    => CHAN_BOND_SEQ_2_4_STRING,
        CHAN_BOND_SEQ_2_ENABLE => CHAN_BOND_SEQ_2_ENABLE_STRING,
        CHAN_BOND_SEQ_2_USE  => CHAN_BOND_SEQ_2_USE,
        CHAN_BOND_SEQ_LEN    => CHAN_BOND_SEQ_LEN,
        CLK_CORRECT_USE      => CLK_CORRECT_USE,
        CLK_COR_KEEP_IDLE    => CLK_COR_KEEP_IDLE,
        CLK_COR_MAX_LAT      => CLK_COR_MAX_LAT,
        CLK_COR_MIN_LAT      => CLK_COR_MIN_LAT,
        CLK_COR_PRECEDENCE   => CLK_COR_PRECEDENCE,
        CLK_COR_REPEAT_WAIT  => CLK_COR_REPEAT_WAIT,
        CLK_COR_SEQ_1_1      => CLK_COR_SEQ_1_1_STRING,
        CLK_COR_SEQ_1_2      => CLK_COR_SEQ_1_2_STRING,
        CLK_COR_SEQ_1_3      => CLK_COR_SEQ_1_3_STRING,
        CLK_COR_SEQ_1_4      => CLK_COR_SEQ_1_4_STRING,
        CLK_COR_SEQ_1_ENABLE => CLK_COR_SEQ_1_ENABLE_STRING,
        CLK_COR_SEQ_2_1      => CLK_COR_SEQ_2_1_STRING,
        CLK_COR_SEQ_2_2      => CLK_COR_SEQ_2_2_STRING,
        CLK_COR_SEQ_2_3      => CLK_COR_SEQ_2_3_STRING,
        CLK_COR_SEQ_2_4      => CLK_COR_SEQ_2_4_STRING,
        CLK_COR_SEQ_2_ENABLE => CLK_COR_SEQ_2_ENABLE_STRING,
        CLK_COR_SEQ_2_USE    => CLK_COR_SEQ_2_USE,
        CLK_COR_SEQ_LEN      => CLK_COR_SEQ_LEN,
        CPLL_CFG             => CPLL_CFG_STRING,
        CPLL_FBDIV           => CPLL_FBDIV,
        CPLL_FBDIV_45        => CPLL_FBDIV_45,
        CPLL_INIT_CFG        => CPLL_INIT_CFG_STRING,
        CPLL_LOCK_CFG        => CPLL_LOCK_CFG_STRING,
        CPLL_REFCLK_DIV      => CPLL_REFCLK_DIV,
        DEC_MCOMMA_DETECT    => DEC_MCOMMA_DETECT,
        DEC_PCOMMA_DETECT    => DEC_PCOMMA_DETECT,
        DEC_VALID_COMMA_ONLY => DEC_VALID_COMMA_ONLY,
        DMONITOR_CFG         => DMONITOR_CFG_STRING,
        ES_CLK_PHASE_SEL     => ES_CLK_PHASE_SEL_STRING,
        ES_CONTROL           => ES_CONTROL_STRING,
        ES_ERRDET_EN         => ES_ERRDET_EN,
        ES_EYE_SCAN_EN       => ES_EYE_SCAN_EN,
        ES_HORZ_OFFSET       => ES_HORZ_OFFSET_STRING,
        ES_PMA_CFG           => ES_PMA_CFG_STRING,
        ES_PRESCALE          => ES_PRESCALE_STRING,
        ES_QUALIFIER         => ES_QUALIFIER_STRING,
        ES_QUAL_MASK         => ES_QUAL_MASK_STRING,
        ES_SDATA_MASK        => ES_SDATA_MASK_STRING,
        ES_VERT_OFFSET       => ES_VERT_OFFSET_STRING,
        FTS_DESKEW_SEQ_ENABLE => FTS_DESKEW_SEQ_ENABLE_STRING,
        FTS_LANE_DESKEW_CFG  => FTS_LANE_DESKEW_CFG_STRING,
        FTS_LANE_DESKEW_EN   => FTS_LANE_DESKEW_EN,
        GEARBOX_MODE         => GEARBOX_MODE_STRING,
        LOOPBACK_CFG         => LOOPBACK_CFG_STRING,
        OUTREFCLK_SEL_INV    => OUTREFCLK_SEL_INV_STRING,
        PCS_PCIE_EN          => PCS_PCIE_EN,
        PCS_RSVD_ATTR        => PCS_RSVD_ATTR_STRING,
        PD_TRANS_TIME_FROM_P2 => PD_TRANS_TIME_FROM_P2_STRING,
        PD_TRANS_TIME_NONE_P2 => PD_TRANS_TIME_NONE_P2_STRING,
        PD_TRANS_TIME_TO_P2  => PD_TRANS_TIME_TO_P2_STRING,
        PMA_RSV              => PMA_RSV_STRING,
        PMA_RSV2             => PMA_RSV2_STRING,
        PMA_RSV3             => PMA_RSV3_STRING,
        PMA_RSV4             => PMA_RSV4_STRING,
        PMA_RSV5             => PMA_RSV5_STRING,
        RESET_POWERSAVE_DISABLE => RESET_POWERSAVE_DISABLE_STRING,
        RXBUFRESET_TIME      => RXBUFRESET_TIME_STRING,
        RXBUF_ADDR_MODE      => RXBUF_ADDR_MODE,
        RXBUF_EIDLE_HI_CNT   => RXBUF_EIDLE_HI_CNT_STRING,
        RXBUF_EIDLE_LO_CNT   => RXBUF_EIDLE_LO_CNT_STRING,
        RXBUF_EN             => RXBUF_EN,
        RXBUF_RESET_ON_CB_CHANGE => RXBUF_RESET_ON_CB_CHANGE,
        RXBUF_RESET_ON_COMMAALIGN => RXBUF_RESET_ON_COMMAALIGN,
        RXBUF_RESET_ON_EIDLE => RXBUF_RESET_ON_EIDLE,
        RXBUF_RESET_ON_RATE_CHANGE => RXBUF_RESET_ON_RATE_CHANGE,
        RXBUF_THRESH_OVFLW   => RXBUF_THRESH_OVFLW,
        RXBUF_THRESH_OVRD    => RXBUF_THRESH_OVRD,
        RXBUF_THRESH_UNDFLW  => RXBUF_THRESH_UNDFLW,
        RXCDRFREQRESET_TIME  => RXCDRFREQRESET_TIME_STRING,
        RXCDRPHRESET_TIME    => RXCDRPHRESET_TIME_STRING,
        RXCDR_CFG            => RXCDR_CFG_STRING,
        RXCDR_FR_RESET_ON_EIDLE => RXCDR_FR_RESET_ON_EIDLE_STRING,
        RXCDR_HOLD_DURING_EIDLE => RXCDR_HOLD_DURING_EIDLE_STRING,
        RXCDR_LOCK_CFG       => RXCDR_LOCK_CFG_STRING,
        RXCDR_PH_RESET_ON_EIDLE => RXCDR_PH_RESET_ON_EIDLE_STRING,
        RXDFELPMRESET_TIME   => RXDFELPMRESET_TIME_STRING,
        RXDLY_CFG            => RXDLY_CFG_STRING,
        RXDLY_LCFG           => RXDLY_LCFG_STRING,
        RXDLY_TAP_CFG        => RXDLY_TAP_CFG_STRING,
        RXGEARBOX_EN         => RXGEARBOX_EN,
        RXISCANRESET_TIME    => RXISCANRESET_TIME_STRING,
        RXLPM_HF_CFG         => RXLPM_HF_CFG_STRING,
        RXLPM_LF_CFG         => RXLPM_LF_CFG_STRING,
        RXOOB_CFG            => RXOOB_CFG_STRING,
        RXOOB_CLK_CFG        => RXOOB_CLK_CFG,
        RXOSCALRESET_TIME    => RXOSCALRESET_TIME_STRING,
        RXOSCALRESET_TIMEOUT => RXOSCALRESET_TIMEOUT_STRING,
        RXOUT_DIV            => RXOUT_DIV,
        RXPCSRESET_TIME      => RXPCSRESET_TIME_STRING,
        RXPHDLY_CFG          => RXPHDLY_CFG_STRING,
        RXPH_CFG             => RXPH_CFG_STRING,
        RXPH_MONITOR_SEL     => RXPH_MONITOR_SEL_STRING,
        RXPI_CFG0            => RXPI_CFG0_STRING,
        RXPI_CFG1            => RXPI_CFG1_STRING,
        RXPI_CFG2            => RXPI_CFG2_STRING,
        RXPI_CFG3            => RXPI_CFG3_STRING,
        RXPI_CFG4            => RXPI_CFG4_STRING,
        RXPI_CFG5            => RXPI_CFG5_STRING,
        RXPI_CFG6            => RXPI_CFG6_STRING,
        RXPMARESET_TIME      => RXPMARESET_TIME_STRING,
        RXPRBS_ERR_LOOPBACK  => RXPRBS_ERR_LOOPBACK_STRING,
        RXSLIDE_AUTO_WAIT    => RXSLIDE_AUTO_WAIT,
        RXSLIDE_MODE         => RXSLIDE_MODE,
        RXSYNC_MULTILANE     => RXSYNC_MULTILANE_STRING,
        RXSYNC_OVRD          => RXSYNC_OVRD_STRING,
        RXSYNC_SKIP_DA       => RXSYNC_SKIP_DA_STRING,
        RX_BIAS_CFG          => RX_BIAS_CFG_STRING,
        RX_BUFFER_CFG        => RX_BUFFER_CFG_STRING,
        RX_CLK25_DIV         => RX_CLK25_DIV,
        RX_CLKMUX_PD         => RX_CLKMUX_PD_STRING,
        RX_CM_SEL            => RX_CM_SEL_STRING,
        RX_CM_TRIM           => RX_CM_TRIM_STRING,
        RX_DATA_WIDTH        => RX_DATA_WIDTH,
        RX_DDI_SEL           => RX_DDI_SEL_STRING,
        RX_DEBUG_CFG         => RX_DEBUG_CFG_STRING,
        RX_DEFER_RESET_BUF_EN => RX_DEFER_RESET_BUF_EN,
        RX_DFELPM_CFG0       => RX_DFELPM_CFG0_STRING,
        RX_DFELPM_CFG1       => RX_DFELPM_CFG1_STRING,
        RX_DFELPM_KLKH_AGC_STUP_EN => RX_DFELPM_KLKH_AGC_STUP_EN_STRING,
        RX_DFE_AGC_CFG0      => RX_DFE_AGC_CFG0_STRING,
        RX_DFE_AGC_CFG1      => RX_DFE_AGC_CFG1_STRING,
        RX_DFE_AGC_CFG2      => RX_DFE_AGC_CFG2_STRING,
        RX_DFE_AGC_OVRDEN    => RX_DFE_AGC_OVRDEN_STRING,
        RX_DFE_GAIN_CFG      => RX_DFE_GAIN_CFG_STRING,
        RX_DFE_H2_CFG        => RX_DFE_H2_CFG_STRING,
        RX_DFE_H3_CFG        => RX_DFE_H3_CFG_STRING,
        RX_DFE_H4_CFG        => RX_DFE_H4_CFG_STRING,
        RX_DFE_H5_CFG        => RX_DFE_H5_CFG_STRING,
        RX_DFE_H6_CFG        => RX_DFE_H6_CFG_STRING,
        RX_DFE_H7_CFG        => RX_DFE_H7_CFG_STRING,
        RX_DFE_KL_CFG        => RX_DFE_KL_CFG_STRING,
        RX_DFE_KL_LPM_KH_CFG0 => RX_DFE_KL_LPM_KH_CFG0_STRING,
        RX_DFE_KL_LPM_KH_CFG1 => RX_DFE_KL_LPM_KH_CFG1_STRING,
        RX_DFE_KL_LPM_KH_CFG2 => RX_DFE_KL_LPM_KH_CFG2_STRING,
        RX_DFE_KL_LPM_KH_OVRDEN => RX_DFE_KL_LPM_KH_OVRDEN_STRING,
        RX_DFE_KL_LPM_KL_CFG0 => RX_DFE_KL_LPM_KL_CFG0_STRING,
        RX_DFE_KL_LPM_KL_CFG1 => RX_DFE_KL_LPM_KL_CFG1_STRING,
        RX_DFE_KL_LPM_KL_CFG2 => RX_DFE_KL_LPM_KL_CFG2_STRING,
        RX_DFE_KL_LPM_KL_OVRDEN => RX_DFE_KL_LPM_KL_OVRDEN_STRING,
        RX_DFE_LPM_CFG       => RX_DFE_LPM_CFG_STRING,
        RX_DFE_LPM_HOLD_DURING_EIDLE => RX_DFE_LPM_HOLD_DURING_EIDLE_STRING,
        RX_DFE_ST_CFG        => RX_DFE_ST_CFG_STRING,
        RX_DFE_UT_CFG        => RX_DFE_UT_CFG_STRING,
        RX_DFE_VP_CFG        => RX_DFE_VP_CFG_STRING,
        RX_DISPERR_SEQ_MATCH => RX_DISPERR_SEQ_MATCH,
        RX_INT_DATAWIDTH     => RX_INT_DATAWIDTH,
        RX_OS_CFG            => RX_OS_CFG_STRING,
        RX_SIG_VALID_DLY     => RX_SIG_VALID_DLY,
        RX_XCLK_SEL          => RX_XCLK_SEL,
        SAS_MAX_COM          => SAS_MAX_COM,
        SAS_MIN_COM          => SAS_MIN_COM,
        SATA_BURST_SEQ_LEN   => SATA_BURST_SEQ_LEN_STRING,
        SATA_BURST_VAL       => SATA_BURST_VAL_STRING,
        SATA_CPLL_CFG        => SATA_CPLL_CFG,
        SATA_EIDLE_VAL       => SATA_EIDLE_VAL_STRING,
        SATA_MAX_BURST       => SATA_MAX_BURST,
        SATA_MAX_INIT        => SATA_MAX_INIT,
        SATA_MAX_WAKE        => SATA_MAX_WAKE,
        SATA_MIN_BURST       => SATA_MIN_BURST,
        SATA_MIN_INIT        => SATA_MIN_INIT,
        SATA_MIN_WAKE        => SATA_MIN_WAKE,
        SHOW_REALIGN_COMMA   => SHOW_REALIGN_COMMA,
        SIM_CPLLREFCLK_SEL   => SIM_CPLLREFCLK_SEL_STRING,
        SIM_RECEIVER_DETECT_PASS => SIM_RECEIVER_DETECT_PASS,
        SIM_RESET_SPEEDUP    => SIM_RESET_SPEEDUP,
        SIM_TX_EIDLE_DRIVE_LEVEL => SIM_TX_EIDLE_DRIVE_LEVEL,
        SIM_VERSION          => SIM_VERSION,
        TERM_RCAL_CFG        => TERM_RCAL_CFG_STRING,
        TERM_RCAL_OVRD       => TERM_RCAL_OVRD_STRING,
        TRANS_TIME_RATE      => TRANS_TIME_RATE_STRING,
        TST_RSV              => TST_RSV_STRING,
        TXBUF_EN             => TXBUF_EN,
        TXBUF_RESET_ON_RATE_CHANGE => TXBUF_RESET_ON_RATE_CHANGE,
        TXDLY_CFG            => TXDLY_CFG_STRING,
        TXDLY_LCFG           => TXDLY_LCFG_STRING,
        TXDLY_TAP_CFG        => TXDLY_TAP_CFG_STRING,
        TXGEARBOX_EN         => TXGEARBOX_EN,
        TXOOB_CFG            => TXOOB_CFG_STRING,
        TXOUT_DIV            => TXOUT_DIV,
        TXPCSRESET_TIME      => TXPCSRESET_TIME_STRING,
        TXPHDLY_CFG          => TXPHDLY_CFG_STRING,
        TXPH_CFG             => TXPH_CFG_STRING,
        TXPH_MONITOR_SEL     => TXPH_MONITOR_SEL_STRING,
        TXPI_CFG0            => TXPI_CFG0_STRING,
        TXPI_CFG1            => TXPI_CFG1_STRING,
        TXPI_CFG2            => TXPI_CFG2_STRING,
        TXPI_CFG3            => TXPI_CFG3_STRING,
        TXPI_CFG4            => TXPI_CFG4_STRING,
        TXPI_CFG5            => TXPI_CFG5_STRING,
        TXPI_GREY_SEL        => TXPI_GREY_SEL_STRING,
        TXPI_INVSTROBE_SEL   => TXPI_INVSTROBE_SEL_STRING,
        TXPI_PPMCLK_SEL      => TXPI_PPMCLK_SEL,
        TXPI_PPM_CFG         => TXPI_PPM_CFG_STRING,
        TXPI_SYNFREQ_PPM     => TXPI_SYNFREQ_PPM_STRING,
        TXPMARESET_TIME      => TXPMARESET_TIME_STRING,
        TXSYNC_MULTILANE     => TXSYNC_MULTILANE_STRING,
        TXSYNC_OVRD          => TXSYNC_OVRD_STRING,
        TXSYNC_SKIP_DA       => TXSYNC_SKIP_DA_STRING,
        TX_CLK25_DIV         => TX_CLK25_DIV,
        TX_CLKMUX_PD         => TX_CLKMUX_PD_STRING,
        TX_DATA_WIDTH        => TX_DATA_WIDTH,
        TX_DEEMPH0           => TX_DEEMPH0_STRING,
        TX_DEEMPH1           => TX_DEEMPH1_STRING,
        TX_DRIVE_MODE        => TX_DRIVE_MODE,
        TX_EIDLE_ASSERT_DELAY => TX_EIDLE_ASSERT_DELAY_STRING,
        TX_EIDLE_DEASSERT_DELAY => TX_EIDLE_DEASSERT_DELAY_STRING,
        TX_INT_DATAWIDTH     => TX_INT_DATAWIDTH,
        TX_LOOPBACK_DRIVE_HIZ => TX_LOOPBACK_DRIVE_HIZ,
        TX_MAINCURSOR_SEL    => TX_MAINCURSOR_SEL_STRING,
        TX_MARGIN_FULL_0     => TX_MARGIN_FULL_0_STRING,
        TX_MARGIN_FULL_1     => TX_MARGIN_FULL_1_STRING,
        TX_MARGIN_FULL_2     => TX_MARGIN_FULL_2_STRING,
        TX_MARGIN_FULL_3     => TX_MARGIN_FULL_3_STRING,
        TX_MARGIN_FULL_4     => TX_MARGIN_FULL_4_STRING,
        TX_MARGIN_LOW_0      => TX_MARGIN_LOW_0_STRING,
        TX_MARGIN_LOW_1      => TX_MARGIN_LOW_1_STRING,
        TX_MARGIN_LOW_2      => TX_MARGIN_LOW_2_STRING,
        TX_MARGIN_LOW_3      => TX_MARGIN_LOW_3_STRING,
        TX_MARGIN_LOW_4      => TX_MARGIN_LOW_4_STRING,
        TX_QPI_STATUS_EN     => TX_QPI_STATUS_EN_STRING,
        TX_RXDETECT_CFG      => TX_RXDETECT_CFG_STRING,
        TX_RXDETECT_PRECHARGE_TIME => TX_RXDETECT_PRECHARGE_TIME_STRING,
        TX_RXDETECT_REF      => TX_RXDETECT_REF_STRING,
        TX_XCLK_SEL          => TX_XCLK_SEL,
        UCODEER_CLR          => UCODEER_CLR_STRING,
        USE_PCS_CLK_PHASE_SEL => USE_PCS_CLK_PHASE_SEL_STRING
      )
      
      port map (
        GSR                  => TO_X01(GSR),
        CPLLFBCLKLOST        => CPLLFBCLKLOST_outdelay,
        CPLLLOCK             => CPLLLOCK_outdelay,
        CPLLREFCLKLOST       => CPLLREFCLKLOST_outdelay,
        DMONITOROUT          => DMONITOROUT_outdelay,
        DRPDO                => DRPDO_outdelay,
        DRPRDY               => DRPRDY_outdelay,
        EYESCANDATAERROR     => EYESCANDATAERROR_outdelay,
        GTHTXN               => GTHTXN_outdelay,
        GTHTXP               => GTHTXP_outdelay,
        GTREFCLKMONITOR      => GTREFCLKMONITOR_outdelay,
        PCSRSVDOUT           => PCSRSVDOUT_outdelay,
        PHYSTATUS            => PHYSTATUS_outdelay,
        RSOSINTDONE          => RSOSINTDONE_outdelay,
        RXBUFSTATUS          => RXBUFSTATUS_outdelay,
        RXBYTEISALIGNED      => RXBYTEISALIGNED_outdelay,
        RXBYTEREALIGN        => RXBYTEREALIGN_outdelay,
        RXCDRLOCK            => RXCDRLOCK_outdelay,
        RXCHANBONDSEQ        => RXCHANBONDSEQ_outdelay,
        RXCHANISALIGNED      => RXCHANISALIGNED_outdelay,
        RXCHANREALIGN        => RXCHANREALIGN_outdelay,
        RXCHARISCOMMA        => RXCHARISCOMMA_outdelay,
        RXCHARISK            => RXCHARISK_outdelay,
        RXCHBONDO            => RXCHBONDO_outdelay,
        RXCLKCORCNT          => RXCLKCORCNT_outdelay,
        RXCOMINITDET         => RXCOMINITDET_outdelay,
        RXCOMMADET           => RXCOMMADET_outdelay,
        RXCOMSASDET          => RXCOMSASDET_outdelay,
        RXCOMWAKEDET         => RXCOMWAKEDET_outdelay,
        RXDATA               => RXDATA_outdelay,
        RXDATAVALID          => RXDATAVALID_outdelay,
        RXDFESLIDETAPSTARTED => RXDFESLIDETAPSTARTED_outdelay,
        RXDFESLIDETAPSTROBEDONE => RXDFESLIDETAPSTROBEDONE_outdelay,
        RXDFESLIDETAPSTROBESTARTED => RXDFESLIDETAPSTROBESTARTED_outdelay,
        RXDFESTADAPTDONE     => RXDFESTADAPTDONE_outdelay,
        RXDISPERR            => RXDISPERR_outdelay,
        RXDLYSRESETDONE      => RXDLYSRESETDONE_outdelay,
        RXELECIDLE           => RXELECIDLE_outdelay,
        RXHEADER             => RXHEADER_outdelay,
        RXHEADERVALID        => RXHEADERVALID_outdelay,
        RXMONITOROUT         => RXMONITOROUT_outdelay,
        RXNOTINTABLE         => RXNOTINTABLE_outdelay,
        RXOSINTSTARTED       => RXOSINTSTARTED_outdelay,
        RXOSINTSTROBEDONE    => RXOSINTSTROBEDONE_outdelay,
        RXOSINTSTROBESTARTED => RXOSINTSTROBESTARTED_outdelay,
        RXOUTCLK             => RXOUTCLK_outdelay,
        RXOUTCLKFABRIC       => RXOUTCLKFABRIC_outdelay,
        RXOUTCLKPCS          => RXOUTCLKPCS_outdelay,
        RXPHALIGNDONE        => RXPHALIGNDONE_outdelay,
        RXPHMONITOR          => RXPHMONITOR_outdelay,
        RXPHSLIPMONITOR      => RXPHSLIPMONITOR_outdelay,
        RXPMARESETDONE       => RXPMARESETDONE_outdelay,
        RXPRBSERR            => RXPRBSERR_outdelay,
        RXQPISENN            => RXQPISENN_outdelay,
        RXQPISENP            => RXQPISENP_outdelay,
        RXRATEDONE           => RXRATEDONE_outdelay,
        RXRESETDONE          => RXRESETDONE_outdelay,
        RXSTARTOFSEQ         => RXSTARTOFSEQ_outdelay,
        RXSTATUS             => RXSTATUS_outdelay,
        RXSYNCDONE           => RXSYNCDONE_outdelay,
        RXSYNCOUT            => RXSYNCOUT_outdelay,
        RXVALID              => RXVALID_outdelay,
        TXBUFSTATUS          => TXBUFSTATUS_outdelay,
        TXCOMFINISH          => TXCOMFINISH_outdelay,
        TXDLYSRESETDONE      => TXDLYSRESETDONE_outdelay,
        TXGEARBOXREADY       => TXGEARBOXREADY_outdelay,
        TXOUTCLK             => TXOUTCLK_outdelay,
        TXOUTCLKFABRIC       => TXOUTCLKFABRIC_outdelay,
        TXOUTCLKPCS          => TXOUTCLKPCS_outdelay,
        TXPHALIGNDONE        => TXPHALIGNDONE_outdelay,
        TXPHINITDONE         => TXPHINITDONE_outdelay,
        TXPMARESETDONE       => TXPMARESETDONE_outdelay,
        TXQPISENN            => TXQPISENN_outdelay,
        TXQPISENP            => TXQPISENP_outdelay,
        TXRATEDONE           => TXRATEDONE_outdelay,
        TXRESETDONE          => TXRESETDONE_outdelay,
        TXSYNCDONE           => TXSYNCDONE_outdelay,
        TXSYNCOUT            => TXSYNCOUT_outdelay,
        CFGRESET             => CFGRESET_indelay,
        CLKRSVD0             => CLKRSVD0_indelay,
        CLKRSVD1             => CLKRSVD1_indelay,
        CPLLLOCKDETCLK       => CPLLLOCKDETCLK_indelay,
        CPLLLOCKEN           => CPLLLOCKEN_indelay,
        CPLLPD               => CPLLPD_indelay,
        CPLLREFCLKSEL        => CPLLREFCLKSEL_indelay,
        CPLLRESET            => CPLLRESET_indelay,
        DMONFIFORESET        => DMONFIFORESET_indelay,
        DMONITORCLK          => DMONITORCLK_indelay,
        DRPADDR              => DRPADDR_indelay,
        DRPCLK               => DRPCLK_indelay,
        DRPDI                => DRPDI_indelay,
        DRPEN                => DRPEN_indelay,
        DRPWE                => DRPWE_indelay,
        EYESCANMODE          => EYESCANMODE_indelay,
        EYESCANRESET         => EYESCANRESET_indelay,
        EYESCANTRIGGER       => EYESCANTRIGGER_indelay,
        GTGREFCLK            => GTGREFCLK_indelay,
        GTHRXN               => GTHRXN_indelay,
        GTHRXP               => GTHRXP_indelay,
        GTNORTHREFCLK0       => GTNORTHREFCLK0_indelay,
        GTNORTHREFCLK1       => GTNORTHREFCLK1_indelay,
        GTREFCLK0            => GTREFCLK0_indelay,
        GTREFCLK1            => GTREFCLK1_indelay,
        GTRESETSEL           => GTRESETSEL_indelay,
        GTRSVD               => GTRSVD_indelay,
        GTRXRESET            => GTRXRESET_indelay,
        GTSOUTHREFCLK0       => GTSOUTHREFCLK0_indelay,
        GTSOUTHREFCLK1       => GTSOUTHREFCLK1_indelay,
        GTTXRESET            => GTTXRESET_indelay,
        LOOPBACK             => LOOPBACK_indelay,
        PCSRSVDIN            => PCSRSVDIN_indelay,
        PCSRSVDIN2           => PCSRSVDIN2_indelay,
        PMARSVDIN            => PMARSVDIN_indelay,
        QPLLCLK              => QPLLCLK_indelay,
        QPLLREFCLK           => QPLLREFCLK_indelay,
        RESETOVRD            => RESETOVRD_indelay,
        RX8B10BEN            => RX8B10BEN_indelay,
        RXADAPTSELTEST       => RXADAPTSELTEST_indelay,
        RXBUFRESET           => RXBUFRESET_indelay,
        RXCDRFREQRESET       => RXCDRFREQRESET_indelay,
        RXCDRHOLD            => RXCDRHOLD_indelay,
        RXCDROVRDEN          => RXCDROVRDEN_indelay,
        RXCDRRESET           => RXCDRRESET_indelay,
        RXCDRRESETRSV        => RXCDRRESETRSV_indelay,
        RXCHBONDEN           => RXCHBONDEN_indelay,
        RXCHBONDI            => RXCHBONDI_indelay,
        RXCHBONDLEVEL        => RXCHBONDLEVEL_indelay,
        RXCHBONDMASTER       => RXCHBONDMASTER_indelay,
        RXCHBONDSLAVE        => RXCHBONDSLAVE_indelay,
        RXCOMMADETEN         => RXCOMMADETEN_indelay,
        RXDDIEN              => RXDDIEN_indelay,
        RXDFEAGCHOLD         => RXDFEAGCHOLD_indelay,
        RXDFEAGCOVRDEN       => RXDFEAGCOVRDEN_indelay,
        RXDFEAGCTRL          => RXDFEAGCTRL_indelay,
        RXDFECM1EN           => RXDFECM1EN_indelay,
        RXDFELFHOLD          => RXDFELFHOLD_indelay,
        RXDFELFOVRDEN        => RXDFELFOVRDEN_indelay,
        RXDFELPMRESET        => RXDFELPMRESET_indelay,
        RXDFESLIDETAP        => RXDFESLIDETAP_indelay,
        RXDFESLIDETAPADAPTEN => RXDFESLIDETAPADAPTEN_indelay,
        RXDFESLIDETAPHOLD    => RXDFESLIDETAPHOLD_indelay,
        RXDFESLIDETAPID      => RXDFESLIDETAPID_indelay,
        RXDFESLIDETAPINITOVRDEN => RXDFESLIDETAPINITOVRDEN_indelay,
        RXDFESLIDETAPONLYADAPTEN => RXDFESLIDETAPONLYADAPTEN_indelay,
        RXDFESLIDETAPOVRDEN  => RXDFESLIDETAPOVRDEN_indelay,
        RXDFESLIDETAPSTROBE  => RXDFESLIDETAPSTROBE_indelay,
        RXDFETAP2HOLD        => RXDFETAP2HOLD_indelay,
        RXDFETAP2OVRDEN      => RXDFETAP2OVRDEN_indelay,
        RXDFETAP3HOLD        => RXDFETAP3HOLD_indelay,
        RXDFETAP3OVRDEN      => RXDFETAP3OVRDEN_indelay,
        RXDFETAP4HOLD        => RXDFETAP4HOLD_indelay,
        RXDFETAP4OVRDEN      => RXDFETAP4OVRDEN_indelay,
        RXDFETAP5HOLD        => RXDFETAP5HOLD_indelay,
        RXDFETAP5OVRDEN      => RXDFETAP5OVRDEN_indelay,
        RXDFETAP6HOLD        => RXDFETAP6HOLD_indelay,
        RXDFETAP6OVRDEN      => RXDFETAP6OVRDEN_indelay,
        RXDFETAP7HOLD        => RXDFETAP7HOLD_indelay,
        RXDFETAP7OVRDEN      => RXDFETAP7OVRDEN_indelay,
        RXDFEUTHOLD          => RXDFEUTHOLD_indelay,
        RXDFEUTOVRDEN        => RXDFEUTOVRDEN_indelay,
        RXDFEVPHOLD          => RXDFEVPHOLD_indelay,
        RXDFEVPOVRDEN        => RXDFEVPOVRDEN_indelay,
        RXDFEVSEN            => RXDFEVSEN_indelay,
        RXDFEXYDEN           => RXDFEXYDEN_indelay,
        RXDLYBYPASS          => RXDLYBYPASS_indelay,
        RXDLYEN              => RXDLYEN_indelay,
        RXDLYOVRDEN          => RXDLYOVRDEN_indelay,
        RXDLYSRESET          => RXDLYSRESET_indelay,
        RXELECIDLEMODE       => RXELECIDLEMODE_indelay,
        RXGEARBOXSLIP        => RXGEARBOXSLIP_indelay,
        RXLPMEN              => RXLPMEN_indelay,
        RXLPMHFHOLD          => RXLPMHFHOLD_indelay,
        RXLPMHFOVRDEN        => RXLPMHFOVRDEN_indelay,
        RXLPMLFHOLD          => RXLPMLFHOLD_indelay,
        RXLPMLFKLOVRDEN      => RXLPMLFKLOVRDEN_indelay,
        RXMCOMMAALIGNEN      => RXMCOMMAALIGNEN_indelay,
        RXMONITORSEL         => RXMONITORSEL_indelay,
        RXOOBRESET           => RXOOBRESET_indelay,
        RXOSCALRESET         => RXOSCALRESET_indelay,
        RXOSHOLD             => RXOSHOLD_indelay,
        RXOSINTCFG           => RXOSINTCFG_indelay,
        RXOSINTEN            => RXOSINTEN_indelay,
        RXOSINTHOLD          => RXOSINTHOLD_indelay,
        RXOSINTID0           => RXOSINTID0_indelay,
        RXOSINTNTRLEN        => RXOSINTNTRLEN_indelay,
        RXOSINTOVRDEN        => RXOSINTOVRDEN_indelay,
        RXOSINTSTROBE        => RXOSINTSTROBE_indelay,
        RXOSINTTESTOVRDEN    => RXOSINTTESTOVRDEN_indelay,
        RXOSOVRDEN           => RXOSOVRDEN_indelay,
        RXOUTCLKSEL          => RXOUTCLKSEL_indelay,
        RXPCOMMAALIGNEN      => RXPCOMMAALIGNEN_indelay,
        RXPCSRESET           => RXPCSRESET_indelay,
        RXPD                 => RXPD_indelay,
        RXPHALIGN            => RXPHALIGN_indelay,
        RXPHALIGNEN          => RXPHALIGNEN_indelay,
        RXPHDLYPD            => RXPHDLYPD_indelay,
        RXPHDLYRESET         => RXPHDLYRESET_indelay,
        RXPHOVRDEN           => RXPHOVRDEN_indelay,
        RXPMARESET           => RXPMARESET_indelay,
        RXPOLARITY           => RXPOLARITY_indelay,
        RXPRBSCNTRESET       => RXPRBSCNTRESET_indelay,
        RXPRBSSEL            => RXPRBSSEL_indelay,
        RXQPIEN              => RXQPIEN_indelay,
        RXRATE               => RXRATE_indelay,
        RXRATEMODE           => RXRATEMODE_indelay,
        RXSLIDE              => RXSLIDE_indelay,
        RXSYNCALLIN          => RXSYNCALLIN_indelay,
        RXSYNCIN             => RXSYNCIN_indelay,
        RXSYNCMODE           => RXSYNCMODE_indelay,
        RXSYSCLKSEL          => RXSYSCLKSEL_indelay,
        RXUSERRDY            => RXUSERRDY_indelay,
        RXUSRCLK             => RXUSRCLK_indelay,
        RXUSRCLK2            => RXUSRCLK2_indelay,
        SETERRSTATUS         => SETERRSTATUS_indelay,
        SIGVALIDCLK          => SIGVALIDCLK_indelay,
        TSTIN                => TSTIN_indelay,
        TX8B10BBYPASS        => TX8B10BBYPASS_indelay,
        TX8B10BEN            => TX8B10BEN_indelay,
        TXBUFDIFFCTRL        => TXBUFDIFFCTRL_indelay,
        TXCHARDISPMODE       => TXCHARDISPMODE_indelay,
        TXCHARDISPVAL        => TXCHARDISPVAL_indelay,
        TXCHARISK            => TXCHARISK_indelay,
        TXCOMINIT            => TXCOMINIT_indelay,
        TXCOMSAS             => TXCOMSAS_indelay,
        TXCOMWAKE            => TXCOMWAKE_indelay,
        TXDATA               => TXDATA_indelay,
        TXDEEMPH             => TXDEEMPH_indelay,
        TXDETECTRX           => TXDETECTRX_indelay,
        TXDIFFCTRL           => TXDIFFCTRL_indelay,
        TXDIFFPD             => TXDIFFPD_indelay,
        TXDLYBYPASS          => TXDLYBYPASS_indelay,
        TXDLYEN              => TXDLYEN_indelay,
        TXDLYHOLD            => TXDLYHOLD_indelay,
        TXDLYOVRDEN          => TXDLYOVRDEN_indelay,
        TXDLYSRESET          => TXDLYSRESET_indelay,
        TXDLYUPDOWN          => TXDLYUPDOWN_indelay,
        TXELECIDLE           => TXELECIDLE_indelay,
        TXHEADER             => TXHEADER_indelay,
        TXINHIBIT            => TXINHIBIT_indelay,
        TXMAINCURSOR         => TXMAINCURSOR_indelay,
        TXMARGIN             => TXMARGIN_indelay,
        TXOUTCLKSEL          => TXOUTCLKSEL_indelay,
        TXPCSRESET           => TXPCSRESET_indelay,
        TXPD                 => TXPD_indelay,
        TXPDELECIDLEMODE     => TXPDELECIDLEMODE_indelay,
        TXPHALIGN            => TXPHALIGN_indelay,
        TXPHALIGNEN          => TXPHALIGNEN_indelay,
        TXPHDLYPD            => TXPHDLYPD_indelay,
        TXPHDLYRESET         => TXPHDLYRESET_indelay,
        TXPHDLYTSTCLK        => TXPHDLYTSTCLK_indelay,
        TXPHINIT             => TXPHINIT_indelay,
        TXPHOVRDEN           => TXPHOVRDEN_indelay,
        TXPIPPMEN            => TXPIPPMEN_indelay,
        TXPIPPMOVRDEN        => TXPIPPMOVRDEN_indelay,
        TXPIPPMPD            => TXPIPPMPD_indelay,
        TXPIPPMSEL           => TXPIPPMSEL_indelay,
        TXPIPPMSTEPSIZE      => TXPIPPMSTEPSIZE_indelay,
        TXPISOPD             => TXPISOPD_indelay,
        TXPMARESET           => TXPMARESET_indelay,
        TXPOLARITY           => TXPOLARITY_indelay,
        TXPOSTCURSOR         => TXPOSTCURSOR_indelay,
        TXPOSTCURSORINV      => TXPOSTCURSORINV_indelay,
        TXPRBSFORCEERR       => TXPRBSFORCEERR_indelay,
        TXPRBSSEL            => TXPRBSSEL_indelay,
        TXPRECURSOR          => TXPRECURSOR_indelay,
        TXPRECURSORINV       => TXPRECURSORINV_indelay,
        TXQPIBIASEN          => TXQPIBIASEN_indelay,
        TXQPISTRONGPDOWN     => TXQPISTRONGPDOWN_indelay,
        TXQPIWEAKPUP         => TXQPIWEAKPUP_indelay,
        TXRATE               => TXRATE_indelay,
        TXRATEMODE           => TXRATEMODE_indelay,
        TXSEQUENCE           => TXSEQUENCE_indelay,
        TXSTARTSEQ           => TXSTARTSEQ_indelay,
        TXSWING              => TXSWING_indelay,
        TXSYNCALLIN          => TXSYNCALLIN_indelay,
        TXSYNCIN             => TXSYNCIN_indelay,
        TXSYNCMODE           => TXSYNCMODE_indelay,
        TXSYSCLKSEL          => TXSYSCLKSEL_indelay,
        TXUSERRDY            => TXUSERRDY_indelay,
        TXUSRCLK             => TXUSRCLK_indelay,
        TXUSRCLK2            => TXUSRCLK2_indelay        
      );

      
   drp_monitor: process (DRPCLK_indelay)

     variable drpen_r1 : std_logic := '0';
     variable drpen_r2 : std_logic := '0';
     variable drpwe_r1 : std_logic := '0';
     variable drpwe_r2 : std_logic := '0';
     type statetype is (FSM_IDLE, FSM_WAIT);
     variable sfsm : statetype := FSM_IDLE;

   begin  -- process drp_monitor

     if (rising_edge(DRPCLK_indelay)) then

       -- pipeline the DRPEN and DRPWE
       drpen_r2 := drpen_r1;
       drpwe_r2 := drpwe_r1;
       drpen_r1 := DRPEN_indelay;
       drpwe_r1 := DRPWE_indelay;
    
    
       -- Check -  if DRPEN or DRPWE is more than 1 DCLK
       if ((drpen_r1 = '1') and (drpen_r2 = '1')) then 
         assert false
           report "DRC Error : DRPEN is high for more than 1 DRPCLK."
           severity failure;
       end if;
       
       if ((drpwe_r1 = '1') and (drpwe_r2 = '1')) then 
         assert false
           report "DRC Error : DRPWE is high for more than 1 DRPCLK."
           severity failure;
       end if;

       
       -- After the 1st DRPEN pulse, check the DRPEN and DRPRDY.
       case sfsm is
         when FSM_IDLE =>
           if (DRPEN_indelay = '1') then 
             sfsm := FSM_WAIT;
           end if;
           
         when FSM_WAIT =>

           -- After the 1st DRPEN, 4 cases can happen
           -- DRPEN DRPRDY NEXT STATE
           -- 0     0      FSM_WAIT - wait for DRPRDY
           -- 0     1      FSM_IDLE - normal operation
           -- 1     0      FSM_WAIT - display error and wait for DRPRDY
           -- 1     1      FSM_WAIT - normal operation. Per UG470, DRPEN and DRPRDY can be at the same cycle.;                       
           -- Add the check for another DPREN pulse
           if(DRPEN_indelay = '1' and DRPRDY_out = '0') then 
             assert false
               report "DRC Error :  DRPEN is enabled before DRPRDY returns."
               severity failure;
           end if;

           -- Add the check for another DRPWE pulse
           if ((DRPWE_indelay = '1') and (DRPEN_indelay = '0')) then
             assert false
               report "DRC Error :  DRPWE is enabled before DRPRDY returns."
               severity failure;
           end if;
                    
           if ((DRPRDY_out = '1') and (DRPEN_indelay = '0')) then
             sfsm := FSM_IDLE;
           end if;
             
               
           if ((DRPRDY_out = '1') and (DRPEN_indelay = '1')) then
             sfsm := FSM_WAIT;
           end if;


         when others =>
           assert false
             report "DRC Error : Default state in DRP FSM."
             severity failure;

       end case;
    
     end if;

   end process drp_monitor;

      
    INIPROC : process
    begin
    -- case ALIGN_COMMA_DOUBLE is
      if((ALIGN_COMMA_DOUBLE = "FALSE") or (ALIGN_COMMA_DOUBLE = "false")) then
        ALIGN_COMMA_DOUBLE_BINARY <= '0';
      elsif((ALIGN_COMMA_DOUBLE = "TRUE") or (ALIGN_COMMA_DOUBLE= "true")) then
        ALIGN_COMMA_DOUBLE_BINARY <= '1';
      else
        assert FALSE report "Error : ALIGN_COMMA_DOUBLE = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case ALIGN_MCOMMA_DET is
      if((ALIGN_MCOMMA_DET = "TRUE") or (ALIGN_MCOMMA_DET = "true")) then
        ALIGN_MCOMMA_DET_BINARY <= '1';
      elsif((ALIGN_MCOMMA_DET = "FALSE") or (ALIGN_MCOMMA_DET= "false")) then
        ALIGN_MCOMMA_DET_BINARY <= '0';
      else
        assert FALSE report "Error : ALIGN_MCOMMA_DET = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case ALIGN_PCOMMA_DET is
      if((ALIGN_PCOMMA_DET = "TRUE") or (ALIGN_PCOMMA_DET = "true")) then
        ALIGN_PCOMMA_DET_BINARY <= '1';
      elsif((ALIGN_PCOMMA_DET = "FALSE") or (ALIGN_PCOMMA_DET= "false")) then
        ALIGN_PCOMMA_DET_BINARY <= '0';
      else
        assert FALSE report "Error : ALIGN_PCOMMA_DET = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case CBCC_DATA_SOURCE_SEL is
      if((CBCC_DATA_SOURCE_SEL = "DECODED") or (CBCC_DATA_SOURCE_SEL = "decoded")) then
        CBCC_DATA_SOURCE_SEL_BINARY <= '1';
      elsif((CBCC_DATA_SOURCE_SEL = "ENCODED") or (CBCC_DATA_SOURCE_SEL= "encoded")) then
        CBCC_DATA_SOURCE_SEL_BINARY <= '0';
      else
        assert FALSE report "Error : CBCC_DATA_SOURCE_SEL = is not DECODED, ENCODED." severity error;
      end if;
    -- end case;
    -- case CHAN_BOND_KEEP_ALIGN is
      if((CHAN_BOND_KEEP_ALIGN = "FALSE") or (CHAN_BOND_KEEP_ALIGN = "false")) then
        CHAN_BOND_KEEP_ALIGN_BINARY <= '0';
      elsif((CHAN_BOND_KEEP_ALIGN = "TRUE") or (CHAN_BOND_KEEP_ALIGN= "true")) then
        CHAN_BOND_KEEP_ALIGN_BINARY <= '1';
      else
        assert FALSE report "Error : CHAN_BOND_KEEP_ALIGN = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case CHAN_BOND_SEQ_2_USE is
      if((CHAN_BOND_SEQ_2_USE = "FALSE") or (CHAN_BOND_SEQ_2_USE = "false")) then
        CHAN_BOND_SEQ_2_USE_BINARY <= '0';
      elsif((CHAN_BOND_SEQ_2_USE = "TRUE") or (CHAN_BOND_SEQ_2_USE= "true")) then
        CHAN_BOND_SEQ_2_USE_BINARY <= '1';
      else
        assert FALSE report "Error : CHAN_BOND_SEQ_2_USE = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case CLK_CORRECT_USE is
      if((CLK_CORRECT_USE = "TRUE") or (CLK_CORRECT_USE = "true")) then
        CLK_CORRECT_USE_BINARY <= '1';
      elsif((CLK_CORRECT_USE = "FALSE") or (CLK_CORRECT_USE= "false")) then
        CLK_CORRECT_USE_BINARY <= '0';
      else
        assert FALSE report "Error : CLK_CORRECT_USE = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case CLK_COR_KEEP_IDLE is
      if((CLK_COR_KEEP_IDLE = "FALSE") or (CLK_COR_KEEP_IDLE = "false")) then
        CLK_COR_KEEP_IDLE_BINARY <= '0';
      elsif((CLK_COR_KEEP_IDLE = "TRUE") or (CLK_COR_KEEP_IDLE= "true")) then
        CLK_COR_KEEP_IDLE_BINARY <= '1';
      else
        assert FALSE report "Error : CLK_COR_KEEP_IDLE = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case CLK_COR_PRECEDENCE is
      if((CLK_COR_PRECEDENCE = "TRUE") or (CLK_COR_PRECEDENCE = "true")) then
        CLK_COR_PRECEDENCE_BINARY <= '1';
      elsif((CLK_COR_PRECEDENCE = "FALSE") or (CLK_COR_PRECEDENCE= "false")) then
        CLK_COR_PRECEDENCE_BINARY <= '0';
      else
        assert FALSE report "Error : CLK_COR_PRECEDENCE = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case CLK_COR_SEQ_2_USE is
      if((CLK_COR_SEQ_2_USE = "FALSE") or (CLK_COR_SEQ_2_USE = "false")) then
        CLK_COR_SEQ_2_USE_BINARY <= '0';
      elsif((CLK_COR_SEQ_2_USE = "TRUE") or (CLK_COR_SEQ_2_USE= "true")) then
        CLK_COR_SEQ_2_USE_BINARY <= '1';
      else
        assert FALSE report "Error : CLK_COR_SEQ_2_USE = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case DEC_MCOMMA_DETECT is
      if((DEC_MCOMMA_DETECT = "TRUE") or (DEC_MCOMMA_DETECT = "true")) then
        DEC_MCOMMA_DETECT_BINARY <= '1';
      elsif((DEC_MCOMMA_DETECT = "FALSE") or (DEC_MCOMMA_DETECT= "false")) then
        DEC_MCOMMA_DETECT_BINARY <= '0';
      else
        assert FALSE report "Error : DEC_MCOMMA_DETECT = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case DEC_PCOMMA_DETECT is
      if((DEC_PCOMMA_DETECT = "TRUE") or (DEC_PCOMMA_DETECT = "true")) then
        DEC_PCOMMA_DETECT_BINARY <= '1';
      elsif((DEC_PCOMMA_DETECT = "FALSE") or (DEC_PCOMMA_DETECT= "false")) then
        DEC_PCOMMA_DETECT_BINARY <= '0';
      else
        assert FALSE report "Error : DEC_PCOMMA_DETECT = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case DEC_VALID_COMMA_ONLY is
      if((DEC_VALID_COMMA_ONLY = "TRUE") or (DEC_VALID_COMMA_ONLY = "true")) then
        DEC_VALID_COMMA_ONLY_BINARY <= '1';
      elsif((DEC_VALID_COMMA_ONLY = "FALSE") or (DEC_VALID_COMMA_ONLY= "false")) then
        DEC_VALID_COMMA_ONLY_BINARY <= '0';
      else
        assert FALSE report "Error : DEC_VALID_COMMA_ONLY = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case ES_ERRDET_EN is
      if((ES_ERRDET_EN = "FALSE") or (ES_ERRDET_EN = "false")) then
        ES_ERRDET_EN_BINARY <= '0';
      elsif((ES_ERRDET_EN = "TRUE") or (ES_ERRDET_EN= "true")) then
        ES_ERRDET_EN_BINARY <= '1';
      else
        assert FALSE report "Error : ES_ERRDET_EN = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case ES_EYE_SCAN_EN is
      if((ES_EYE_SCAN_EN = "FALSE") or (ES_EYE_SCAN_EN = "false")) then
        ES_EYE_SCAN_EN_BINARY <= '0';
      elsif((ES_EYE_SCAN_EN = "TRUE") or (ES_EYE_SCAN_EN= "true")) then
        ES_EYE_SCAN_EN_BINARY <= '1';
      else
        assert FALSE report "Error : ES_EYE_SCAN_EN = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case FTS_LANE_DESKEW_EN is
      if((FTS_LANE_DESKEW_EN = "FALSE") or (FTS_LANE_DESKEW_EN = "false")) then
        FTS_LANE_DESKEW_EN_BINARY <= '0';
      elsif((FTS_LANE_DESKEW_EN = "TRUE") or (FTS_LANE_DESKEW_EN= "true")) then
        FTS_LANE_DESKEW_EN_BINARY <= '1';
      else
        assert FALSE report "Error : FTS_LANE_DESKEW_EN = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case PCS_PCIE_EN is
      if((PCS_PCIE_EN = "FALSE") or (PCS_PCIE_EN = "false")) then
        PCS_PCIE_EN_BINARY <= '0';
      elsif((PCS_PCIE_EN = "TRUE") or (PCS_PCIE_EN= "true")) then
        PCS_PCIE_EN_BINARY <= '1';
      else
        assert FALSE report "Error : PCS_PCIE_EN = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case RXBUF_ADDR_MODE is
      if((RXBUF_ADDR_MODE = "FULL") or (RXBUF_ADDR_MODE = "full")) then
        RXBUF_ADDR_MODE_BINARY <= '0';
      elsif((RXBUF_ADDR_MODE = "FAST") or (RXBUF_ADDR_MODE= "fast")) then
        RXBUF_ADDR_MODE_BINARY <= '1';
      else
        assert FALSE report "Error : RXBUF_ADDR_MODE = is not FULL, FAST." severity error;
      end if;
    -- end case;
    -- case RXBUF_EN is
      if((RXBUF_EN = "TRUE") or (RXBUF_EN = "true")) then
        RXBUF_EN_BINARY <= '1';
      elsif((RXBUF_EN = "FALSE") or (RXBUF_EN= "false")) then
        RXBUF_EN_BINARY <= '0';
      else
        assert FALSE report "Error : RXBUF_EN = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case RXBUF_RESET_ON_CB_CHANGE is
      if((RXBUF_RESET_ON_CB_CHANGE = "TRUE") or (RXBUF_RESET_ON_CB_CHANGE = "true")) then
        RXBUF_RESET_ON_CB_CHANGE_BINARY <= '1';
      elsif((RXBUF_RESET_ON_CB_CHANGE = "FALSE") or (RXBUF_RESET_ON_CB_CHANGE= "false")) then
        RXBUF_RESET_ON_CB_CHANGE_BINARY <= '0';
      else
        assert FALSE report "Error : RXBUF_RESET_ON_CB_CHANGE = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case RXBUF_RESET_ON_COMMAALIGN is
      if((RXBUF_RESET_ON_COMMAALIGN = "FALSE") or (RXBUF_RESET_ON_COMMAALIGN = "false")) then
        RXBUF_RESET_ON_COMMAALIGN_BINARY <= '0';
      elsif((RXBUF_RESET_ON_COMMAALIGN = "TRUE") or (RXBUF_RESET_ON_COMMAALIGN= "true")) then
        RXBUF_RESET_ON_COMMAALIGN_BINARY <= '1';
      else
        assert FALSE report "Error : RXBUF_RESET_ON_COMMAALIGN = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case RXBUF_RESET_ON_EIDLE is
          if((RXBUF_RESET_ON_EIDLE = "FALSE") or (RXBUF_RESET_ON_EIDLE = "false")) then
        RXBUF_RESET_ON_EIDLE_BINARY <= '0';
      elsif((RXBUF_RESET_ON_EIDLE = "TRUE") or (RXBUF_RESET_ON_EIDLE= "true")) then
        RXBUF_RESET_ON_EIDLE_BINARY <= '1';
      else
        assert FALSE report "Error : RXBUF_RESET_ON_EIDLE = is not FALSE, TRUE." severity error;
      end if;
     -- end case;
    -- case RXBUF_RESET_ON_RATE_CHANGE is
      if((RXBUF_RESET_ON_RATE_CHANGE = "TRUE") or (RXBUF_RESET_ON_RATE_CHANGE = "true")) then
        RXBUF_RESET_ON_RATE_CHANGE_BINARY <= '1';
      elsif((RXBUF_RESET_ON_RATE_CHANGE = "FALSE") or (RXBUF_RESET_ON_RATE_CHANGE= "false")) then
        RXBUF_RESET_ON_RATE_CHANGE_BINARY <= '0';
      else
        assert FALSE report "Error : RXBUF_RESET_ON_RATE_CHANGE = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case RXBUF_THRESH_OVRD is
      if((RXBUF_THRESH_OVRD = "FALSE") or (RXBUF_THRESH_OVRD = "false")) then
        RXBUF_THRESH_OVRD_BINARY <= '0';
      elsif((RXBUF_THRESH_OVRD = "TRUE") or (RXBUF_THRESH_OVRD= "true")) then
        RXBUF_THRESH_OVRD_BINARY <= '1';
      else
        assert FALSE report "Error : RXBUF_THRESH_OVRD = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case RXGEARBOX_EN is
      if((RXGEARBOX_EN = "FALSE") or (RXGEARBOX_EN = "false")) then
        RXGEARBOX_EN_BINARY <= '0';
      elsif((RXGEARBOX_EN = "TRUE") or (RXGEARBOX_EN= "true")) then
        RXGEARBOX_EN_BINARY <= '1';
      else
        assert FALSE report "Error : RXGEARBOX_EN = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case RXOOB_CLK_CFG is
      if((RXOOB_CLK_CFG = "PMA") or (RXOOB_CLK_CFG = "pma")) then
        RXOOB_CLK_CFG_BINARY <= '0';
      elsif((RXOOB_CLK_CFG = "FABRIC") or (RXOOB_CLK_CFG= "fabric")) then
        RXOOB_CLK_CFG_BINARY <= '1';
      else
        assert FALSE report "Error : RXOOB_CLK_CFG = is not PMA, FABRIC." severity error;
      end if;
    -- end case;
    -- case RXSLIDE_MODE is
      if((RXSLIDE_MODE = "OFF") or (RXSLIDE_MODE = "off")) then
        RXSLIDE_MODE_BINARY <= "00";
      elsif((RXSLIDE_MODE = "AUTO") or (RXSLIDE_MODE= "auto")) then
        RXSLIDE_MODE_BINARY <= "01";
      elsif((RXSLIDE_MODE = "PCS") or (RXSLIDE_MODE= "pcs")) then
        RXSLIDE_MODE_BINARY <= "10";
      elsif((RXSLIDE_MODE = "PMA") or (RXSLIDE_MODE= "pma")) then
        RXSLIDE_MODE_BINARY <= "11";
      else
        assert FALSE report "Error : RXSLIDE_MODE = is not OFF, AUTO, PCS, PMA." severity error;
      end if;
    -- end case;
    -- case RX_DEFER_RESET_BUF_EN is
      if((RX_DEFER_RESET_BUF_EN = "TRUE") or (RX_DEFER_RESET_BUF_EN = "true")) then
        RX_DEFER_RESET_BUF_EN_BINARY <= '1';
      elsif((RX_DEFER_RESET_BUF_EN = "FALSE") or (RX_DEFER_RESET_BUF_EN= "false")) then
        RX_DEFER_RESET_BUF_EN_BINARY <= '0';
      else
        assert FALSE report "Error : RX_DEFER_RESET_BUF_EN = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case RX_DISPERR_SEQ_MATCH is
      if((RX_DISPERR_SEQ_MATCH = "TRUE") or (RX_DISPERR_SEQ_MATCH = "true")) then
        RX_DISPERR_SEQ_MATCH_BINARY <= '1';
      elsif((RX_DISPERR_SEQ_MATCH = "FALSE") or (RX_DISPERR_SEQ_MATCH= "false")) then
        RX_DISPERR_SEQ_MATCH_BINARY <= '0';
      else
        assert FALSE report "Error : RX_DISPERR_SEQ_MATCH = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case RX_XCLK_SEL is
      if((RX_XCLK_SEL = "RXREC") or (RX_XCLK_SEL = "rxrec")) then
        RX_XCLK_SEL_BINARY <= '0';
      elsif((RX_XCLK_SEL = "RXUSR") or (RX_XCLK_SEL= "rxusr")) then
        RX_XCLK_SEL_BINARY <= '1';
      else
        assert FALSE report "Error : RX_XCLK_SEL = is not RXREC, RXUSR." severity error;
      end if;
    -- end case;
    -- case SATA_CPLL_CFG is
      if((SATA_CPLL_CFG = "VCO_3000MHZ") or (SATA_CPLL_CFG = "vco_3000mhz")) then
        SATA_CPLL_CFG_BINARY <= "00";
      elsif((SATA_CPLL_CFG = "VCO_750MHZ") or (SATA_CPLL_CFG= "vco_750mhz")) then
        SATA_CPLL_CFG_BINARY <= "10";
      elsif((SATA_CPLL_CFG = "VCO_1500MHZ") or (SATA_CPLL_CFG= "vco_1500mhz")) then
        SATA_CPLL_CFG_BINARY <= "01";
      else
        assert FALSE report "Error : SATA_CPLL_CFG = is not VCO_3000MHZ, VCO_750MHZ, VCO_1500MHZ." severity error;
      end if;
    -- end case;
    -- case SHOW_REALIGN_COMMA is
      if((SHOW_REALIGN_COMMA = "TRUE") or (SHOW_REALIGN_COMMA = "true")) then
        SHOW_REALIGN_COMMA_BINARY <= '1';
      elsif((SHOW_REALIGN_COMMA = "FALSE") or (SHOW_REALIGN_COMMA= "false")) then
        SHOW_REALIGN_COMMA_BINARY <= '0';
      else
        assert FALSE report "Error : SHOW_REALIGN_COMMA = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case TXBUF_EN is
      if((TXBUF_EN = "TRUE") or (TXBUF_EN = "true")) then
        TXBUF_EN_BINARY <= '1';
      elsif((TXBUF_EN = "FALSE") or (TXBUF_EN= "false")) then
        TXBUF_EN_BINARY <= '0';
      else
        assert FALSE report "Error : TXBUF_EN = is not TRUE, FALSE." severity error;
      end if;
    -- end case;
    -- case TXBUF_RESET_ON_RATE_CHANGE is
      if((TXBUF_RESET_ON_RATE_CHANGE = "FALSE") or (TXBUF_RESET_ON_RATE_CHANGE = "false")) then
        TXBUF_RESET_ON_RATE_CHANGE_BINARY <= '0';
      elsif((TXBUF_RESET_ON_RATE_CHANGE = "TRUE") or (TXBUF_RESET_ON_RATE_CHANGE= "true")) then
        TXBUF_RESET_ON_RATE_CHANGE_BINARY <= '1';
      else
        assert FALSE report "Error : TXBUF_RESET_ON_RATE_CHANGE = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case TXGEARBOX_EN is
      if((TXGEARBOX_EN = "FALSE") or (TXGEARBOX_EN = "false")) then
        TXGEARBOX_EN_BINARY <= '0';
      elsif((TXGEARBOX_EN = "TRUE") or (TXGEARBOX_EN= "true")) then
        TXGEARBOX_EN_BINARY <= '1';
      else
        assert FALSE report "Error : TXGEARBOX_EN = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case TXPI_PPMCLK_SEL is
      if((TXPI_PPMCLK_SEL = "TXUSRCLK2") or (TXPI_PPMCLK_SEL = "txusrclk2")) then
        TXPI_PPMCLK_SEL_BINARY <= '1';
      elsif((TXPI_PPMCLK_SEL = "TXUSRCLK") or (TXPI_PPMCLK_SEL= "txusrclk")) then
        TXPI_PPMCLK_SEL_BINARY <= '0';
      else
        assert FALSE report "Error : TXPI_PPMCLK_SEL = is not TXUSRCLK2, TXUSRCLK." severity error;
      end if;
    -- end case;
    -- case TX_DRIVE_MODE is
      if((TX_DRIVE_MODE = "DIRECT") or (TX_DRIVE_MODE = "direct")) then
        TX_DRIVE_MODE_BINARY <= "00000";
      elsif((TX_DRIVE_MODE = "PIPE") or (TX_DRIVE_MODE= "pipe")) then
        TX_DRIVE_MODE_BINARY <= "00001";
      elsif((TX_DRIVE_MODE = "PIPEGEN3") or (TX_DRIVE_MODE= "pipegen3")) then
        TX_DRIVE_MODE_BINARY <= "00010";
      else
        assert FALSE report "Error : TX_DRIVE_MODE = is not DIRECT, PIPE, PIPEGEN3." severity error;
      end if;
    -- end case;
    -- case TX_LOOPBACK_DRIVE_HIZ is
      if((TX_LOOPBACK_DRIVE_HIZ = "FALSE") or (TX_LOOPBACK_DRIVE_HIZ = "false")) then
        TX_LOOPBACK_DRIVE_HIZ_BINARY <= '0';
      elsif((TX_LOOPBACK_DRIVE_HIZ = "TRUE") or (TX_LOOPBACK_DRIVE_HIZ= "true")) then
        TX_LOOPBACK_DRIVE_HIZ_BINARY <= '1';
      else
        assert FALSE report "Error : TX_LOOPBACK_DRIVE_HIZ = is not FALSE, TRUE." severity error;
      end if;
    -- end case;
    -- case TX_XCLK_SEL is
      if((TX_XCLK_SEL = "TXUSR") or (TX_XCLK_SEL = "txusr")) then
        TX_XCLK_SEL_BINARY <= '1';
      elsif((TX_XCLK_SEL = "TXOUT") or (TX_XCLK_SEL= "txout")) then
        TX_XCLK_SEL_BINARY <= '0';
      else
        assert FALSE report "Error : TX_XCLK_SEL = is not TXUSR, TXOUT." severity error;
      end if;
    -- end case;
    case CPLL_FBDIV_45 is
      when  5   =>  CPLL_FBDIV_45_BINARY <= '1';
      when  4   =>  CPLL_FBDIV_45_BINARY <= '0';
      when others  =>  assert FALSE report "Error : CPLL_FBDIV_45 is not in range 4 .. 5." severity error;
    end case;
    case RX_INT_DATAWIDTH is
      when  0   =>  RX_INT_DATAWIDTH_BINARY <= '0';
      when  1   =>  RX_INT_DATAWIDTH_BINARY <= '1';
      when others  =>  assert FALSE report "Error : RX_INT_DATAWIDTH is not in range 0 .. 1." severity error;
    end case;
    case TX_INT_DATAWIDTH is
      when  0   =>  TX_INT_DATAWIDTH_BINARY <= '0';
      when  1   =>  TX_INT_DATAWIDTH_BINARY <= '1';
      when others  =>  assert FALSE report "Error : TX_INT_DATAWIDTH is not in range 0 .. 1." severity error;
    end case;
    if ((ALIGN_COMMA_WORD >= 1) and (ALIGN_COMMA_WORD <= 4)) then
      ALIGN_COMMA_WORD_BINARY <= CONV_STD_LOGIC_VECTOR(ALIGN_COMMA_WORD, 3);
    else
      assert FALSE report "Error : ALIGN_COMMA_WORD is not in range 1 .. 4." severity error;
    end if;
    if ((CHAN_BOND_MAX_SKEW >= 1) and (CHAN_BOND_MAX_SKEW <= 14)) then
      CHAN_BOND_MAX_SKEW_BINARY <= CONV_STD_LOGIC_VECTOR(CHAN_BOND_MAX_SKEW, 4);
    else
      assert FALSE report "Error : CHAN_BOND_MAX_SKEW is not in range 1 .. 14." severity error;
    end if;
    if ((CHAN_BOND_SEQ_LEN >= 1) and (CHAN_BOND_SEQ_LEN <= 4)) then
      CHAN_BOND_SEQ_LEN_BINARY <= CONV_STD_LOGIC_VECTOR(CHAN_BOND_SEQ_LEN, 2);
    else
      assert FALSE report "Error : CHAN_BOND_SEQ_LEN is not in range 1 .. 4." severity error;
    end if;
    if ((CLK_COR_MAX_LAT >= 3) and (CLK_COR_MAX_LAT <= 60)) then
      CLK_COR_MAX_LAT_BINARY <= CONV_STD_LOGIC_VECTOR(CLK_COR_MAX_LAT, 6);
    else
      assert FALSE report "Error : CLK_COR_MAX_LAT is not in range 3 .. 60." severity error;
    end if;
    if ((CLK_COR_MIN_LAT >= 3) and (CLK_COR_MIN_LAT <= 60)) then
      CLK_COR_MIN_LAT_BINARY <= CONV_STD_LOGIC_VECTOR(CLK_COR_MIN_LAT, 6);
    else
      assert FALSE report "Error : CLK_COR_MIN_LAT is not in range 3 .. 60." severity error;
    end if;
    if ((CLK_COR_REPEAT_WAIT >= 0) and (CLK_COR_REPEAT_WAIT <= 31)) then
      CLK_COR_REPEAT_WAIT_BINARY <= CONV_STD_LOGIC_VECTOR(CLK_COR_REPEAT_WAIT, 5);
    else
      assert FALSE report "Error : CLK_COR_REPEAT_WAIT is not in range 0 .. 31." severity error;
    end if;
    if ((CLK_COR_SEQ_LEN >= 1) and (CLK_COR_SEQ_LEN <= 4)) then
      CLK_COR_SEQ_LEN_BINARY <= CONV_STD_LOGIC_VECTOR(CLK_COR_SEQ_LEN, 2);
    else
      assert FALSE report "Error : CLK_COR_SEQ_LEN is not in range 1 .. 4." severity error;
    end if;
    if ((CPLL_FBDIV >= 1) and (CPLL_FBDIV <= 20)) then
      CPLL_FBDIV_BINARY <= CONV_STD_LOGIC_VECTOR(CPLL_FBDIV, 7);
    else
      assert FALSE report "Error : CPLL_FBDIV is not in range 1 .. 20." severity error;
    end if;
    if ((CPLL_REFCLK_DIV >= 1) and (CPLL_REFCLK_DIV <= 20)) then
      CPLL_REFCLK_DIV_BINARY <= CONV_STD_LOGIC_VECTOR(CPLL_REFCLK_DIV, 5);
    else
      assert FALSE report "Error : CPLL_REFCLK_DIV is not in range 1 .. 20." severity error;
    end if;
    if ((RXBUF_THRESH_OVFLW >= 0) and (RXBUF_THRESH_OVFLW <= 63)) then
      RXBUF_THRESH_OVFLW_BINARY <= CONV_STD_LOGIC_VECTOR(RXBUF_THRESH_OVFLW, 6);
    else
      assert FALSE report "Error : RXBUF_THRESH_OVFLW is not in range 0 .. 63." severity error;
    end if;
    if ((RXBUF_THRESH_UNDFLW >= 0) and (RXBUF_THRESH_UNDFLW <= 63)) then
      RXBUF_THRESH_UNDFLW_BINARY <= CONV_STD_LOGIC_VECTOR(RXBUF_THRESH_UNDFLW, 6);
    else
      assert FALSE report "Error : RXBUF_THRESH_UNDFLW is not in range 0 .. 63." severity error;
    end if;
    if ((RXOUT_DIV >= 1) and (RXOUT_DIV <= 16)) then
      RXOUT_DIV_BINARY <= CONV_STD_LOGIC_VECTOR(RXOUT_DIV, 3);
    else
      assert FALSE report "Error : RXOUT_DIV is not in range 1 .. 16." severity error;
    end if;
    if ((RXSLIDE_AUTO_WAIT >= 0) and (RXSLIDE_AUTO_WAIT <= 15)) then
      RXSLIDE_AUTO_WAIT_BINARY <= CONV_STD_LOGIC_VECTOR(RXSLIDE_AUTO_WAIT, 4);
    else
      assert FALSE report "Error : RXSLIDE_AUTO_WAIT is not in range 0 .. 15." severity error;
    end if;
    if ((RX_CLK25_DIV >= 1) and (RX_CLK25_DIV <= 32)) then
      RX_CLK25_DIV_BINARY <= CONV_STD_LOGIC_VECTOR(RX_CLK25_DIV, 5);
    else
      assert FALSE report "Error : RX_CLK25_DIV is not in range 1 .. 32." severity error;
    end if;
    if ((RX_DATA_WIDTH >= 16) and (RX_DATA_WIDTH <= 80)) then
      RX_DATA_WIDTH_BINARY <= CONV_STD_LOGIC_VECTOR(RX_DATA_WIDTH, 3);
    else
      assert FALSE report "Error : RX_DATA_WIDTH is not in range 16 .. 80." severity error;
    end if;
    if ((RX_SIG_VALID_DLY >= 1) and (RX_SIG_VALID_DLY <= 32)) then
      RX_SIG_VALID_DLY_BINARY <= CONV_STD_LOGIC_VECTOR(RX_SIG_VALID_DLY, 5);
    else
      assert FALSE report "Error : RX_SIG_VALID_DLY is not in range 1 .. 32." severity error;
    end if;
    if ((SAS_MAX_COM >= 1) and (SAS_MAX_COM <= 127)) then
      SAS_MAX_COM_BINARY <= CONV_STD_LOGIC_VECTOR(SAS_MAX_COM, 7);
    else
      assert FALSE report "Error : SAS_MAX_COM is not in range 1 .. 127." severity error;
    end if;
    if ((SAS_MIN_COM >= 1) and (SAS_MIN_COM <= 63)) then
      SAS_MIN_COM_BINARY <= CONV_STD_LOGIC_VECTOR(SAS_MIN_COM, 6);
    else
      assert FALSE report "Error : SAS_MIN_COM is not in range 1 .. 63." severity error;
    end if;
    if ((SATA_MAX_BURST >= 1) and (SATA_MAX_BURST <= 63)) then
      SATA_MAX_BURST_BINARY <= CONV_STD_LOGIC_VECTOR(SATA_MAX_BURST, 6);
    else
      assert FALSE report "Error : SATA_MAX_BURST is not in range 1 .. 63." severity error;
    end if;
    if ((SATA_MAX_INIT >= 1) and (SATA_MAX_INIT <= 63)) then
      SATA_MAX_INIT_BINARY <= CONV_STD_LOGIC_VECTOR(SATA_MAX_INIT, 6);
    else
      assert FALSE report "Error : SATA_MAX_INIT is not in range 1 .. 63." severity error;
    end if;
    if ((SATA_MAX_WAKE >= 1) and (SATA_MAX_WAKE <= 63)) then
      SATA_MAX_WAKE_BINARY <= CONV_STD_LOGIC_VECTOR(SATA_MAX_WAKE, 6);
    else
      assert FALSE report "Error : SATA_MAX_WAKE is not in range 1 .. 63." severity error;
    end if;
    if ((SATA_MIN_BURST >= 1) and (SATA_MIN_BURST <= 61)) then
      SATA_MIN_BURST_BINARY <= CONV_STD_LOGIC_VECTOR(SATA_MIN_BURST, 6);
    else
      assert FALSE report "Error : SATA_MIN_BURST is not in range 1 .. 61." severity error;
    end if;
    if ((SATA_MIN_INIT >= 1) and (SATA_MIN_INIT <= 63)) then
      SATA_MIN_INIT_BINARY <= CONV_STD_LOGIC_VECTOR(SATA_MIN_INIT, 6);
    else
      assert FALSE report "Error : SATA_MIN_INIT is not in range 1 .. 63." severity error;
    end if;
    if ((SATA_MIN_WAKE >= 1) and (SATA_MIN_WAKE <= 63)) then
      SATA_MIN_WAKE_BINARY <= CONV_STD_LOGIC_VECTOR(SATA_MIN_WAKE, 6);
    else
      assert FALSE report "Error : SATA_MIN_WAKE is not in range 1 .. 63." severity error;
    end if;
    if ((TXOUT_DIV >= 1) and (TXOUT_DIV <= 16)) then
      TXOUT_DIV_BINARY <= CONV_STD_LOGIC_VECTOR(TXOUT_DIV, 3);
    else
      assert FALSE report "Error : TXOUT_DIV is not in range 1 .. 16." severity error;
    end if;
    if ((TX_CLK25_DIV >= 1) and (TX_CLK25_DIV <= 32)) then
      TX_CLK25_DIV_BINARY <= CONV_STD_LOGIC_VECTOR(TX_CLK25_DIV, 5);
    else
      assert FALSE report "Error : TX_CLK25_DIV is not in range 1 .. 32." severity error;
    end if;
    if ((TX_DATA_WIDTH >= 16) and (TX_DATA_WIDTH <= 80)) then
      TX_DATA_WIDTH_BINARY <= CONV_STD_LOGIC_VECTOR(TX_DATA_WIDTH, 3);
    else
      assert FALSE report "Error : TX_DATA_WIDTH is not in range 16 .. 80." severity error;
    end if;
    wait;
    end process INIPROC;
    CPLLFBCLKLOST <= CPLLFBCLKLOST_out;
    CPLLLOCK <= CPLLLOCK_out;
    CPLLREFCLKLOST <= CPLLREFCLKLOST_out;
    DMONITOROUT <= DMONITOROUT_out;
    DRPDO <= DRPDO_out;
    DRPRDY <= DRPRDY_out;
    EYESCANDATAERROR <= EYESCANDATAERROR_out;
    GTHTXN <= GTHTXN_out;
    GTHTXP <= GTHTXP_out;
    GTREFCLKMONITOR <= GTREFCLKMONITOR_out;
    PCSRSVDOUT <= PCSRSVDOUT_out;
    PHYSTATUS <= PHYSTATUS_out;
    RSOSINTDONE <= RSOSINTDONE_out;
    RXBUFSTATUS <= RXBUFSTATUS_out;
    RXBYTEISALIGNED <= RXBYTEISALIGNED_out;
    RXBYTEREALIGN <= RXBYTEREALIGN_out;
    RXCDRLOCK <= RXCDRLOCK_out;
    RXCHANBONDSEQ <= RXCHANBONDSEQ_out;
    RXCHANISALIGNED <= RXCHANISALIGNED_out;
    RXCHANREALIGN <= RXCHANREALIGN_out;
    RXCHARISCOMMA <= RXCHARISCOMMA_out;
    RXCHARISK <= RXCHARISK_out;
    RXCHBONDO <= RXCHBONDO_out;
    RXCLKCORCNT <= RXCLKCORCNT_out;
    RXCOMINITDET <= RXCOMINITDET_out;
    RXCOMMADET <= RXCOMMADET_out;
    RXCOMSASDET <= RXCOMSASDET_out;
    RXCOMWAKEDET <= RXCOMWAKEDET_out;
    RXDATA <= RXDATA_out;
    RXDATAVALID <= RXDATAVALID_out;
    RXDFESLIDETAPSTARTED <= RXDFESLIDETAPSTARTED_out;
    RXDFESLIDETAPSTROBEDONE <= RXDFESLIDETAPSTROBEDONE_out;
    RXDFESLIDETAPSTROBESTARTED <= RXDFESLIDETAPSTROBESTARTED_out;
    RXDFESTADAPTDONE <= RXDFESTADAPTDONE_out;
    RXDISPERR <= RXDISPERR_out;
    RXDLYSRESETDONE <= RXDLYSRESETDONE_out;
    RXELECIDLE <= RXELECIDLE_out;
    RXHEADER <= RXHEADER_out;
    RXHEADERVALID <= RXHEADERVALID_out;
    RXMONITOROUT <= RXMONITOROUT_out;
    RXNOTINTABLE <= RXNOTINTABLE_out;
    RXOSINTSTARTED <= RXOSINTSTARTED_out;
    RXOSINTSTROBEDONE <= RXOSINTSTROBEDONE_out;
    RXOSINTSTROBESTARTED <= RXOSINTSTROBESTARTED_out;
    RXOUTCLK <= RXOUTCLK_out;
    RXOUTCLKFABRIC <= RXOUTCLKFABRIC_out;
    RXOUTCLKPCS <= RXOUTCLKPCS_out;
    RXPHALIGNDONE <= RXPHALIGNDONE_out;
    RXPHMONITOR <= RXPHMONITOR_out;
    RXPHSLIPMONITOR <= RXPHSLIPMONITOR_out;
    RXPMARESETDONE <= RXPMARESETDONE_out;
    RXPRBSERR <= RXPRBSERR_out;
    RXQPISENN <= RXQPISENN_out;
    RXQPISENP <= RXQPISENP_out;
    RXRATEDONE <= RXRATEDONE_out;
    RXRESETDONE <= RXRESETDONE_out;
    RXSTARTOFSEQ <= RXSTARTOFSEQ_out;
    RXSTATUS <= RXSTATUS_out;
    RXSYNCDONE <= RXSYNCDONE_out;
    RXSYNCOUT <= RXSYNCOUT_out;
    RXVALID <= RXVALID_out;
    TXBUFSTATUS <= TXBUFSTATUS_out;
    TXCOMFINISH <= TXCOMFINISH_out;
    TXDLYSRESETDONE <= TXDLYSRESETDONE_out;
    TXGEARBOXREADY <= TXGEARBOXREADY_out;
    TXOUTCLK <= TXOUTCLK_out;
    TXOUTCLKFABRIC <= TXOUTCLKFABRIC_out;
    TXOUTCLKPCS <= TXOUTCLKPCS_out;
    TXPHALIGNDONE <= TXPHALIGNDONE_out;
    TXPHINITDONE <= TXPHINITDONE_out;
    TXPMARESETDONE <= TXPMARESETDONE_out;
    TXQPISENN <= TXQPISENN_out;
    TXQPISENP <= TXQPISENP_out;
    TXRATEDONE <= TXRATEDONE_out;
    TXRESETDONE <= TXRESETDONE_out;
    TXSYNCDONE <= TXSYNCDONE_out;
    TXSYNCOUT <= TXSYNCOUT_out;
  end GTHE2_CHANNEL_FAST_V;
