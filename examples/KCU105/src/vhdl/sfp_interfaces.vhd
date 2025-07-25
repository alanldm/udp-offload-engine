-- Copyright (c) 2022-2024 THALES. All Rights Reserved
--
-- Licensed under the SolderPad Hardware License v 2.1 (the "License");
-- you may not use this file except in compliance with the License, or,
-- at your option. You may obtain a copy of the License at
--
-- https://solderpad.org/licenses/SHL-2.1/
--
-- Unless required by applicable law or agreed to in writing, any
-- work distributed under the License is distributed on an "AS IS"
-- BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
-- either express or implied. See the License for the specific
-- language governing permissions and limitations under the
-- License.
--
-- File subject to timestamp TSP22X5365 Thales, in the name of Thales SIX GTS France, made on 10/06/2022.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library common;
use common.axis_utils_pkg.axis_dwidth_converter;
use common.axis_utils_pkg.axis_mux;
use common.axis_utils_pkg.axis_demux;
use common.axis_utils_pkg.axis_fifo;

entity sfp_interfaces is
    generic(
        G_DEBUG : boolean := false
    );
    port(
        -- Clocking
        GT_REFCLK_P        : in  std_logic;
        GT_REFCLK_N        : in  std_logic;
        CLK_50_MHZ         : in  std_logic; -- Free running clock
        CLK_100_MHZ        : in  std_logic; -- Free running clock
        -- Resets
        SYS_RST            : in  std_logic; -- Global async reset active high
        SYS_RST_N          : in  std_logic; -- Global async reset active low
        RX_RST             : in  std_logic; -- Reset of Rx part
        TX_RST             : in  std_logic; -- Reset of Tx part
        RX_RST_N           : in  std_logic; -- Reset of Rx part
        TX_RST_N           : in  std_logic; -- Reset of Tx part
        -- SFP
        SFP_TX_N           : out std_logic;
        SFP_TX_P           : out std_logic;
        SFP_RX_N           : in  std_logic;
        SFP_RX_P           : in  std_logic;
        -- Rx interface
        M_RX_ACLK          : out std_logic_vector(1 downto 0);
        M_RX_RST           : out std_logic_vector(1 downto 0);
        M_RX_TDATA         : out std_logic_vector(127 downto 0);
        M_RX_TKEEP         : out std_logic_vector(15 downto 0);
        M_RX_TVALID        : out std_logic_vector(1 downto 0);
        M_RX_TUSER         : out std_logic_vector(1 downto 0); -- 1 when frame is ok
        M_RX_TLAST         : out std_logic_vector(1 downto 0);
        -- Pause don't connect yet as not implemented in SFP10G
        --PAUSE_REQ          : in  std_logic_vector(1 downto 0);
        --PAUSE_VAL          : in  std_logic_vector(31 downto 0);
        -- Tx 10G interface
        S_TX_ACLK          : out std_logic_vector(1 downto 0);
        S_TX_RST           : out std_logic_vector(1 downto 0);
        S_TX_TDATA         : in  std_logic_vector(127 downto 0);
        S_TX_TKEEP         : in  std_logic_vector(15 downto 0);
        S_TX_TVALID        : in  std_logic_vector(1 downto 0);
        S_TX_TLAST         : in  std_logic_vector(1 downto 0);
        S_TX_TUSER         : in  std_logic_vector(1 downto 0); -- 1 when frame is ok
        S_TX_TREADY        : out std_logic_vector(1 downto 0);
        -- Control/status
        SFP_MOD_DEF0       : in  std_logic_vector(1 downto 0); -- '0' = module present   '1' = module not present
        SFP_RX_LOS         : in  std_logic;
        PHY_LAYER_READY    : out std_logic_vector(1 downto 0);
        STATUS_VECTOR_SFP  : out std_logic_vector(31 downto 0);
        -- DBG
        DBG_LOOPBACK_EN    : in  std_logic; -- 1 : loopback enable
        DBG_CLK_PHY_ACTIVE : out std_logic_vector(1 downto 0)
    );
end sfp_interfaces;

architecture rtl of sfp_interfaces is

    --constant C_CHANNEL_1 : integer := 0;
    constant C_CHANNEL_2 : integer := 1;

    -- Component declaration
    component sfp_1g is
        generic(
            G_DEBUG              : boolean := false;
            G_EXAMPLE_SIMULATION : integer := 0 --To select simulation for PCS/PMA Ip in 1G

        );
        port(
            -- Clocks
            GT_REFCLK          : in  std_logic; -- GT Refclk @156.25 MHz
            CLK_50_MHZ         : in  std_logic; -- Free running clock
            -- Resets
            SYS_RST            : in  std_logic; -- Global async reset active high
            SYS_RST_N          : in  std_logic; -- Global async reset active low
            RX_RST_N           : in  std_logic; -- Reset of Rx part
            TX_RST_N           : in  std_logic; -- Reset of Tx part
            -- SFP
            SFP_TX_N           : out std_logic;
            SFP_TX_P           : out std_logic;
            SFP_RX_N           : in  std_logic;
            SFP_RX_P           : in  std_logic;
            -- Rx interface
            M_RX_ACLK          : out std_logic;
            M_RX_RST           : out std_logic;
            M_RX_TDATA         : out std_logic_vector(7 downto 0);
            M_RX_TVALID        : out std_logic;
            M_RX_TUSER         : out std_logic_vector(0 downto 0); -- 1 when frame is ok
            M_RX_TLAST         : out std_logic;
            -- Pause
            PAUSE_REQ          : in  std_logic;
            PAUSE_VAL          : in  std_logic_vector(15 downto 0);
            -- TX interface
            S_TX_ACLK          : out std_logic;
            S_TX_RST           : out std_logic;
            S_TX_TDATA         : in  std_logic_vector(7 downto 0);
            S_TX_TVALID        : in  std_logic;
            S_TX_TLAST         : in  std_logic;
            S_TX_TUSER         : in  std_logic_vector(0 downto 0);
            S_TX_TREADY        : out std_logic;
            -- Control and status signals
            MAC_ADDRESS        : in  std_logic_vector(47 downto 0);
            SFP_MOD_DEF0       : in  std_logic; -- '0' = module present   '1' = module not present
            SFP_RX_LOS         : in  std_logic;
            PHY_LAYER_READY    : out std_logic;
            STATUS_VECTOR_SFP  : out std_logic_vector(15 downto 0);
            -- DBG
            DBG_CLK_PHY_ACTIVE : out std_logic
        );
    end component sfp_1g;

    signal gt_refclk : std_ulogic;

    signal m_rx_in_tdata  : std_logic_vector(127 downto 0);
    signal m_rx_in_tkeep  : std_logic_vector(15 downto 0);
    signal m_rx_in_tvalid : std_logic_vector(1 downto 0);
    signal m_rx_in_tuser  : std_logic_vector(1 downto 0); -- 1 when frame is ok
    signal m_rx_in_tlast  : std_logic_vector(1 downto 0);

    signal s_tx_in_tdata  : std_logic_vector(127 downto 0);
    signal s_tx_in_tkeep  : std_logic_vector(15 downto 0);
    signal s_tx_in_tvalid : std_logic_vector(1 downto 0);
    signal s_tx_in_tlast  : std_logic_vector(1 downto 0);
    signal s_tx_in_tuser  : std_logic_vector(1 downto 0); -- 1 when frame is ok
    signal s_tx_in_tready : std_logic_vector(1 downto 0);
begin

    ---------------------------------------------------------------------------------------------------
    --      GT Refclk buffering
    ---------------------------------------------------------------------------------------------------
    inst_ibufds_gte3 : ibufds_gte3      -- @suppress "Generic map uses default values. Missing optional actuals: REFCLK_EN_TX_PATH, REFCLK_HROW_CK_SEL, REFCLK_ICNTL_RX"
        port map(
            o     => gt_refclk,
            odiv2 => open,
            ceb   => '0',
            i     => GT_REFCLK_P,
            ib    => GT_REFCLK_N
        );

    ---------------------------------------------------------------------------------------------------
    --      1G SFP on channel 2
    ---------------------------------------------------------------------------------------------------
    inst_sfp_1g : sfp_1g
        generic map(
            G_DEBUG              => G_DEBUG,
            G_EXAMPLE_SIMULATION => 0
        )
        port map(
            GT_REFCLK          => gt_refclk,
            CLK_50_MHZ         => CLK_50_MHZ,
            SYS_RST            => SYS_RST,
            SYS_RST_N          => SYS_RST_N,
            RX_RST_N           => RX_RST_N,
            TX_RST_N           => TX_RST_N,
            SFP_TX_N           => SFP_TX_N,
            SFP_TX_P           => SFP_TX_P,
            SFP_RX_N           => SFP_RX_N,
            SFP_RX_P           => SFP_RX_P,
            M_RX_ACLK          => M_RX_ACLK(C_CHANNEL_2),
            M_RX_RST           => M_RX_RST(C_CHANNEL_2),
            M_RX_TDATA         => m_rx_in_tdata((C_CHANNEL_2 * 64) + 7 downto (C_CHANNEL_2 * 64)),
            M_RX_TVALID        => m_rx_in_tvalid(C_CHANNEL_2),
            M_RX_TUSER         => m_rx_in_tuser((C_CHANNEL_2 * 1) + 0 downto (C_CHANNEL_2 * 1)),
            M_RX_TLAST         => m_rx_in_tlast(C_CHANNEL_2),
            PAUSE_REQ          => '0',  -- PAUSE_REQ(C_CHANNEL_2), -- Don't connect pause as it is not implemented yet in 10G
            PAUSE_VAL          => (others => '0'), -- PAUSE_VAL((C_CHANNEL_2 * 16) + 15 downto (C_CHANNEL_2 * 16)),
            S_TX_ACLK          => S_TX_ACLK(C_CHANNEL_2),
            S_TX_RST           => S_TX_RST(C_CHANNEL_2),
            S_TX_TDATA         => s_tx_in_tdata((C_CHANNEL_2 * 64) + 7 downto (C_CHANNEL_2 * 64)),
            S_TX_TVALID        => s_tx_in_tvalid(C_CHANNEL_2),
            S_TX_TLAST         => s_tx_in_tlast(C_CHANNEL_2),
            S_TX_TUSER         => s_tx_in_tuser((C_CHANNEL_2 * 1) + 0 downto (C_CHANNEL_2 * 1)),
            S_TX_TREADY        => s_tx_in_tready(C_CHANNEL_2),
            MAC_ADDRESS        => x"cafedecabeef",
            SFP_MOD_DEF0       => SFP_MOD_DEF0(C_CHANNEL_2),
            SFP_RX_LOS         => SFP_RX_LOS,
            PHY_LAYER_READY    => PHY_LAYER_READY(C_CHANNEL_2),
            STATUS_VECTOR_SFP  => STATUS_VECTOR_SFP((C_CHANNEL_2 * 16) + 15 downto (C_CHANNEL_2 * 16)),
            DBG_CLK_PHY_ACTIVE => DBG_CLK_PHY_ACTIVE(C_CHANNEL_2)
        );

    m_rx_in_tkeep((C_CHANNEL_2 * 8) + 7 downto (C_CHANNEL_2 * 8)) <= ((C_CHANNEL_2 * 8) => '1', others => '0');

    M_RX_TDATA  <= m_rx_in_tdata;
    M_RX_TKEEP  <= m_rx_in_tkeep;
    M_RX_TVALID <= m_rx_in_tvalid;
    M_RX_TUSER  <= m_rx_in_tuser;
    M_RX_TLAST  <= m_rx_in_tlast;

    s_tx_in_tdata  <= S_TX_TDATA;
    s_tx_in_tkeep  <= S_TX_TKEEP;
    s_tx_in_tvalid <= S_TX_TVALID;
    s_tx_in_tlast  <= S_TX_TLAST;
    s_tx_in_tuser  <= S_TX_TUSER;
    S_TX_TREADY    <= s_tx_in_tready;

end rtl;
