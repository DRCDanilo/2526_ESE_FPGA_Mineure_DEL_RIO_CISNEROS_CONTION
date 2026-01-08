library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encodeur is
    port (
        i_clk : in std_logic;
        i_rst_n: in std_logic;
        i_ch_a : in std_logic;
        i_ch_b : in std_logic;
        o_led : out std_logic_vector(9 downto 0);
		  o_counter : out unsigned(9 downto 0)
    );
end entity;

architecture rtl of encodeur is
    signal QA : std_logic_vector(1 downto 0) := "00";
    signal QB : std_logic_vector(1 downto 0) := "00";
    signal count : unsigned(9 downto 0) := (others => '0');

    signal state_prev, state_curr : std_logic_vector(1 downto 0);
begin

    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            QA <= "00";
            QB <= "00";
            count <= (others => '0');
            state_prev <= "00";

        elsif rising_edge(i_clk) then

            QA(1) <= QA(0);
            QA(0) <= i_ch_a;

            QB(1) <= QB(0);
            QB(0) <= i_ch_b;


            state_curr <= QA(0) & QB(0);

            case state_prev & state_curr is
                when "0001" | "0111" | "1110" | "1000" =>
                    count <= count + 1;

                when "0010" | "1011" | "1101" | "0100" =>
                    count <= count - 1;

                when others =>
                    null;
            end case;

            state_prev <= state_curr;
        end if;
    end process;

    o_led <= std_logic_vector(count);
	 o_counter <= count;

end architecture rtl;
