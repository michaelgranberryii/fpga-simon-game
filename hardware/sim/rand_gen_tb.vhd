LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE std.env.stop;

ENTITY rand_gen_tb IS

END rand_gen_tb;

ARCHITECTURE Behavioral OF rand_gen_tb IS
    SIGNAL clk_tb : STD_LOGIC := '0';
    SIGNAL rst_tb : STD_LOGIC;
    SIGNAL seed_tb : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL output_tb : STD_LOGIC_VECTOR (3 DOWNTO 0);
    CONSTANT CP : TIME := 8 ns;
BEGIN

    uut : ENTITY work.rand_gen
        PORT MAP(
            clk => clk_tb,
            rst => rst_tb,
            seed => seed_tb,
            output => output_tb
        );

    clock : PROCESS
    BEGIN
        clk_tb <= NOT clk_tb;
        WAIT FOR CP/2;
    END PROCESS;

    seed : PROCESS
    BEGIN
        seed_tb <= x"A4";
        rst_tb <= '0';
        WAIT FOR CP;
        rst_tb <= '1';
        WAIT FOR CP;
        rst_tb <= '0';
        WAIT FOR 10 * CP;

        -- Reset
        rst_tb <= '1';
        WAIT FOR 2 * CP;
        rst_tb <= '0';
        WAIT FOR 20 * CP;

        -- Reset
        rst_tb <= '1';
        WAIT FOR 3 * CP;
        rst_tb <= '0';
        WAIT FOR 30 * CP;
        stop;
    END PROCESS;

END Behavioral;