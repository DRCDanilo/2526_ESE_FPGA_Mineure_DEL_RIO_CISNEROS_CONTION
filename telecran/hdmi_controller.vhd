library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controller is
    generic(
        h_res  : positive := 720;
        v_res  : positive := 480;
        h_sync : positive := 61;
        h_fp   : positive := 58;
        h_bp   : positive := 18;
        v_sync : positive := 5;
        v_fp   : positive := 30;
        v_bp   : positive := 9
    );
    port(
        i_clk : in std_logic;
        i_rst_n : in std_logic;

        o_hdmi_hs : out std_logic;
        o_hdmi_vs : out std_logic;
        o_hdmi_de : out std_logic;

        o_pixel_en : out std_logic;
        o_pixel_address : out unsigned(18 downto 0);
        o_x_counter : out natural range 0 to h_res-1;
        o_y_counter : out natural range 0 to v_res-1
    );
end entity hdmi_controller;

architecture rtl of hdmi_controller is

    --------------------------------------------------------------------
    -- Constantes timing
    --------------------------------------------------------------------
    constant h_start : natural := h_sync + h_fp;
    constant h_end   : natural := h_start + h_res;
    constant h_total : natural := h_end + h_bp;

    constant v_start : natural := v_sync + v_fp;
    constant v_end   : natural := v_start + v_res;
    constant v_total : natural := v_end + v_bp;
	 
	 constant PIXEL_ADDR_WIDTH : natural := 19;

    --------------------------------------------------------------------
    -- Registres internes
    --------------------------------------------------------------------
    signal r_h_count  : natural range 0 to h_total := 0;
    signal r_v_count  : natural range 0 to v_total := 0;

    signal r_h_active : std_logic := '0';
    signal r_v_active : std_logic := '0';

    signal r_x_counter     : natural range 0 to h_res-1 := 0;
    signal r_y_counter     : natural range 0 to v_res-1 := 0;
    signal r_pixel_address : unsigned(18 downto 0) := (others => '0');

begin

    --------------------------------------------------------------------
    -- Synchronisation horizontale
    --------------------------------------------------------------------
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_h_count  <= 0;
            o_hdmi_hs  <= '1';
            r_h_active <= '0';

        elsif rising_edge(i_clk) then

            -- compteur horizontal
            if r_h_count = h_total then
                r_h_count <= 0;
            else
                r_h_count <= r_h_count + 1;
            end if;

            -- synchro HS
            if (r_h_count >= h_sync) and (r_h_count /= h_total) then
                o_hdmi_hs <= '1';
            else
                o_hdmi_hs <= '0';
            end if;

            -- zone active horizontale
            if r_h_count = h_start then
                r_h_active <= '1';
            elsif r_h_count = h_end then
                r_h_active <= '0';
            end if;

        end if;
    end process;

    --------------------------------------------------------------------
    -- Synchronisation verticale
    --------------------------------------------------------------------
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_v_count  <= 0;
            o_hdmi_vs  <= '1';
            r_v_active <= '0';

        elsif rising_edge(i_clk) then
            if r_h_count = h_total then

                -- compteur vertical
                if r_v_count = v_total then
                    r_v_count <= 0;
                else
                    r_v_count <= r_v_count + 1;
                end if;

                -- synchro VS
                if (r_v_count >= v_sync) and (r_v_count /= v_total) then
                    o_hdmi_vs <= '1';
                else
                    o_hdmi_vs <= '0';
                end if;

                -- zone active verticale
                if r_v_count = v_start then
                    r_v_active <= '1';
                elsif r_v_count = v_end then
                    r_v_active <= '0';
                end if;

            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Data Enable + Génération pixels
    --------------------------------------------------------------------
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            o_hdmi_de       <= '0';
            o_pixel_en      <= '0';
            r_x_counter     <= 0;
            r_y_counter     <= 0;
            r_pixel_address <= to_unsigned(0,PIXEL_ADDR_WIDTH);
        elsif rising_edge(i_clk) then

            o_hdmi_de  <= r_h_active and r_v_active;
            o_pixel_en <= r_h_active and r_v_active;

            if (r_h_active = '1' and r_v_active = '1') then

                -- X
                if r_x_counter = h_res - 1 then
                    r_x_counter <= 0;

                    -- Y
                    if r_y_counter = v_res - 1 then
                        r_y_counter <= 0;
                    else
                        r_y_counter <= r_y_counter + 1;
                    end if;

                else
                    r_x_counter <= r_x_counter + 1;
                end if;

                -- adresse linéaire
                r_pixel_address <= to_unsigned(r_y_counter * h_res + r_x_counter, PIXEL_ADDR_WIDTH);

            else
                r_x_counter <= 0;
            end if;

        end if;
    end process;

    --------------------------------------------------------------------
    -- Sorties
    --------------------------------------------------------------------
    o_x_counter     <= r_x_counter;
    o_y_counter     <= r_y_counter;
    o_pixel_address <= r_pixel_address;

end architecture rtl;