LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY debounce IS
    GENERIC (
        clk_freq : INTEGER := 50_000_000; --system clock frequency in Hz
        stable_time : INTEGER := 10); --time button must remain stable in ms
    PORT (
        clk : IN STD_LOGIC; --input clock
        rst : IN STD_LOGIC; --asynchronous active high reset
        button : IN STD_LOGIC; --input signal to be debounced
        result : OUT STD_LOGIC); --debounced signal
END debounce;

ARCHITECTURE Behavioral OF debounce IS
    SIGNAL ffs : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL sclr : STD_LOGIC;
BEGIN
    PROCESS (clk, rst)
        VARIABLE count : INTEGER := 0;
    BEGIN
        IF rst = '1' THEN
            result <= '0';
            ffs <= "00";
        ELSIF rising_edge(clk) THEN
            ffs(0) <= button;
            ffs(1) <= ffs(0);
            IF sclr = '1' THEN
                count := 0;
            ELSIF count < clk_freq * stable_time/1000 THEN
                count := count + 1;
            ELSE
                result <= ffs(1);
            END IF;
        END IF;
    END PROCESS;
    sclr <= ffs(0) XOR ffs(1);
END Behavioral;