
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE std.env.stop;

entity simon_game_tb is
--  Port ( );
end simon_game_tb;

architecture Behavioral of simon_game_tb is
        signal clk_tb : std_logic := '1';
        signal btn_tb : std_logic_vector(3 downto 0);
        signal switches_tb : std_logic_vector(3 downto 0);
        signal led_tb : std_logic_vector(3 downto 0);
        signal rgb_r_tb, rgb_g_tb, rgb_b_tb : std_logic;

        constant CP : time := 8 ns;
        constant CLK_FREQ_tb : positive := 1024;

        constant wait_time : time := 50 us;
begin

    uut: entity work.simon_game
        generic map (
            CLK_FREQ => CLK_FREQ_tb
        )
        port map (
            clk => clk_tb,
            btn => btn_tb,
            switches => switches_tb,
            led => led_tb,
            red_led => rgb_r_tb,
            green_led => rgb_g_tb,
            blue_led => rgb_b_tb
        );

    clock: process
    begin
        clk_tb <= not clk_tb;
        wait for CP/2;
    end process;

    reset: process
    begin
        -- reset
        btn_tb(0) <= '1';
        btn_tb(3) <= '1';
        switches_tb <= x"0";
        wait for CP;
        btn_tb(0) <= '0';
        btn_tb(3) <= '0';
        wait for CP;

        switches_tb <= x"0";
        wait for wait_time;

        switches_tb <= x"1";
        wait for wait_time;

        switches_tb <= x"2";
        wait for wait_time;

        switches_tb <= x"4";
        wait for wait_time;

        switches_tb <= x"8";
        wait for wait_time;
        
        stop;
    end process;

end Behavioral;
