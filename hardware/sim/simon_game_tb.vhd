
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE std.env.stop;

entity simon_game_tb is
--  Port ( );
end simon_game_tb;

architecture Behavioral of simon_game_tb is
        type p_array is array (0 to 9) of integer range 0 to 8;
        signal pattern : p_array := (1, 2, 4, 1, 2, 1, 8, 2, 1, 8);
                                               --2  
        signal clk_tb : std_logic := '1';
        signal btn_tb : std_logic_vector(3 downto 0);
        signal switches_tb : std_logic_vector(3 downto 0);
        signal led_tb : std_logic_vector(3 downto 0);
        signal rgb_r_tb, rgb_g_tb, rgb_b_tb : std_logic;

        constant CP : time := 8 ns;
        constant CLK_FREQ_tb : positive := 125_000_000;

        constant wait_time : time := 11 ms;
        signal add_time : time;
        constant two_ms : time := 4 ms;


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

    uut_test : process
    begin
        -- reset
        btn_tb <= x"0";
        wait for 1 ms;
        btn_tb(0) <= '1';
        btn_tb(3) <= '1';
        wait for wait_time;
        btn_tb(0) <= '0';
        btn_tb(3) <= '0';
        wait for 7 ms;

        -- Set speed
        switches_tb <= x"f";

        -- Capture a pattern
        btn_tb(1) <= '1';
        wait for wait_time;
        btn_tb(1) <= '0';
        wait for 5 ms;

        -- Play game
        add_time <= wait_time;
        l1: for i in 0 to 9 loop
            l2: for j in 0 to i loop
                btn_tb <= std_logic_vector(to_unsigned(pattern(j), btn_tb'length));
                wait for wait_time;
                btn_tb <= x"0";
                wait for CP;
            end loop;
            add_time <= add_time + two_ms;
            wait for add_time;
        end loop;
        wait for add_time;


        stop;
    end process;

end Behavioral;
