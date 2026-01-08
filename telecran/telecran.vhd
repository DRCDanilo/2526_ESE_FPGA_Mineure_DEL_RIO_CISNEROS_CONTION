library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pll;
use pll.all;

entity telecran is
    port (
        i_clk_50 : in std_logic;

        io_hdmi_i2c_scl : inout std_logic;
        io_hdmi_i2c_sda : inout std_logic;
        o_hdmi_tx_clk  : out std_logic;
        o_hdmi_tx_d    : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de   : out std_logic;
        o_hdmi_tx_hs   : out std_logic;
        o_hdmi_tx_vs   : out std_logic;
        i_hdmi_tx_int  : in std_logic;

        i_rst_n : in std_logic;

        i_left_ch_a  : in std_logic;
        i_left_ch_b  : in std_logic;
		  i_left_pb : in std_logic;
        i_right_ch_a : in std_logic;
        i_right_ch_b : in std_logic
    );
end entity;

architecture rtl of telecran is

    --------------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------------
    constant H_RES : natural := 720;
    constant V_RES : natural := 480;
    constant FB_SIZE : natural := H_RES * V_RES;

    --------------------------------------------------------------------
    -- Signals
    --------------------------------------------------------------------
    signal s_clk_27 : std_logic;
    signal s_rst_n  : std_logic;

    signal s_hdmi_hs : std_logic;
    signal s_hdmi_vs : std_logic;
    signal s_hdmi_de : std_logic;

    signal s_x_hdmi : natural range 0 to H_RES-1;
    signal s_y_hdmi : natural range 0 to V_RES-1;

    signal s_x_enc  : unsigned(9 downto 0);
    signal s_y_enc  : unsigned(9 downto 0);

    signal x_enc_pos : natural range 0 to H_RES-1;
    signal y_enc_pos : natural range 0 to V_RES-1;

    signal addr_wr : natural range 0 to FB_SIZE-1;
    signal addr_rd : natural range 0 to FB_SIZE-1;

    signal pixel_rd : std_logic_vector(7 downto 0);
	 
	 signal clear_active : std_logic := '0';
    signal clear_addr   : natural range 0 to FB_SIZE-1 := 0;
    signal pixel_wr     : std_logic_vector(7 downto 0);
	 signal left_pb_prev : std_logic := '0';

    --------------------------------------------------------------------
    -- Components
    --------------------------------------------------------------------
    component pll
        port (
            refclk   : in std_logic;
            rst      : in std_logic;
            outclk_0 : out std_logic;
            locked   : out std_logic
        );
    end component;

    component hdmi_controller
        generic(
            h_res  : positive;
            v_res  : positive;
            h_sync : positive;
            h_fp   : positive;
            h_bp   : positive;
            v_sync : positive;
            v_fp   : positive;
            v_bp   : positive
        );
        port(
            i_clk : in std_logic;
            i_rst_n : in std_logic;
            o_hdmi_hs : out std_logic;
            o_hdmi_vs : out std_logic;
            o_hdmi_de : out std_logic;
            o_pixel_en : out std_logic;
            o_pixel_address : out unsigned(18 downto 0);
            o_x_counter : out natural range 0 to H_RES-1;
            o_y_counter : out natural range 0 to V_RES-1
        );
    end component;

    component encodeur
        port (
            i_clk : in std_logic;
            i_rst_n : in std_logic;
            i_ch_a : in std_logic;
            i_ch_b : in std_logic;
            o_led : out std_logic_vector(9 downto 0);
            o_counter : out unsigned(9 downto 0)
        );
    end component;

    component dpram
        generic (
            mem_size   : natural;
            data_width : natural
        );
        port (
            i_clk_a  : in std_logic;
            i_clk_b  : in std_logic;
            i_data_a : in std_logic_vector(7 downto 0);
            i_data_b : in std_logic_vector(7 downto 0);
            i_addr_a : in natural range 0 to mem_size-1;
            i_addr_b : in natural range 0 to mem_size-1;
            i_we_a   : in std_logic;
            i_we_b   : in std_logic;
            o_q_a    : out std_logic_vector(7 downto 0);
            o_q_b    : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    --------------------------------------------------------------------
    -- PLL
    --------------------------------------------------------------------
    pll0 : pll
        port map (
            refclk   => i_clk_50,
            rst      => not i_rst_n,
            outclk_0 => s_clk_27,
            locked   => s_rst_n
        );

    --------------------------------------------------------------------
    -- HDMI controller
    --------------------------------------------------------------------
    hdmi0 : hdmi_controller
        generic map (
            h_res => H_RES, v_res => V_RES,
            h_sync => 61, h_fp => 58, h_bp => 18,
            v_sync => 5,  v_fp => 30, v_bp => 9
        )
        port map (
            i_clk => s_clk_27,
            i_rst_n => s_rst_n,
            o_hdmi_hs => s_hdmi_hs,
            o_hdmi_vs => s_hdmi_vs,
            o_hdmi_de => s_hdmi_de,
            o_pixel_en => open,
            o_pixel_address => open,
            o_x_counter => s_x_hdmi,
            o_y_counter => s_y_hdmi
        );

    --------------------------------------------------------------------
    -- Encodeurs
    --------------------------------------------------------------------
    enc_x : encodeur
        port map (
            i_clk => s_clk_27,
            i_rst_n => s_rst_n,
            i_ch_a => i_left_ch_a,
            i_ch_b => i_left_ch_b,
            o_led => open,
            o_counter => s_x_enc
        );

    enc_y : encodeur
        port map (
            i_clk => s_clk_27,
            i_rst_n => s_rst_n,
            i_ch_a => i_right_ch_a,
            i_ch_b => i_right_ch_b,
            o_led => open,
            o_counter => s_y_enc
        );

    --------------------------------------------------------------------
    -- Positions encodeurs
    --------------------------------------------------------------------
    x_enc_pos <= to_integer(s_x_enc) mod H_RES;
    y_enc_pos <= to_integer(s_y_enc) mod V_RES;

    process(s_clk_27, s_rst_n)
	begin
		 if s_rst_n = '0' then
			  clear_active <= '0';
			  clear_addr   <= 0;
			  left_pb_prev <= '0';

		 elsif rising_edge(s_clk_27) then
			  -- mémorisation état précédent
			  left_pb_prev <= i_left_pb;

			  -- détection front montant
			  if i_left_pb = '1' and left_pb_prev = '0' then
					clear_active <= '1';
					clear_addr   <= 0;

			  elsif clear_active = '1' then
					if clear_addr = FB_SIZE-1 then
						 clear_active <= '0';
					else
						 clear_addr <= clear_addr + 1;
					end if;
			  end if;
		 end if;
	end process;

    addr_wr <= clear_addr when clear_active = '1'
               else (y_enc_pos * H_RES + x_enc_pos);

    pixel_wr <= x"00" when clear_active = '1'
                else x"FF";

    addr_rd <= s_y_hdmi * H_RES + s_x_hdmi;

    --------------------------------------------------------------------
    -- Framebuffer
    --------------------------------------------------------------------
    fb : dpram
        generic map (
            mem_size => FB_SIZE,
            data_width => 8
        )
        port map (
            i_clk_a  => s_clk_27,
            i_clk_b  => s_clk_27,
            i_data_a => pixel_wr,
            i_data_b => (others => '0'),
            i_addr_a => addr_wr,
            i_addr_b => addr_rd,
            i_we_a   => '1',
            i_we_b   => '0',
            o_q_a    => open,
            o_q_b    => pixel_rd
        );

    --------------------------------------------------------------------
    -- HDMI output
    --------------------------------------------------------------------
    process(s_hdmi_de, pixel_rd)
    begin
        if s_hdmi_de = '1' and pixel_rd = x"FF" then
            o_hdmi_tx_d <= x"FFFFFF";
        else
            o_hdmi_tx_d <= x"000000";
        end if;
    end process;

    o_hdmi_tx_clk <= s_clk_27;
    o_hdmi_tx_hs  <= s_hdmi_hs;
    o_hdmi_tx_vs  <= s_hdmi_vs;
    o_hdmi_tx_de  <= s_hdmi_de;

end architecture rtl;