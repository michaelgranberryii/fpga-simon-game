LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY rand_gen IS
    PORT (
        clk, rst : IN STD_LOGIC;
        seed : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        rand_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
END rand_gen;

ARCHITECTURE Behavioral OF rand_gen IS

    SIGNAL currstate : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL nextstate : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL feedback : STD_LOGIC;
BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            currstate <= seed;
        ELSIF rising_edge(clk) THEN
            currstate <= nextstate;
        END IF;
    END PROCESS;

    feedback <= currstate(4) XOR currstate(3) XOR currstate(2) XOR currstate(0);
    nextstate <= feedback & currstate(7 DOWNTO 1);
    -- rand_out <= currstate(3 DOWNTO 0);
    rand_out <= "0001" when currstate(7 DOWNTO 6) = "00" else
                "0010" when currstate(7 DOWNTO 6) = "01" else
                "0100" when currstate(7 DOWNTO 6) = "10" else
                "1000" when currstate(7 DOWNTO 6) = "11";

END Behavioral;