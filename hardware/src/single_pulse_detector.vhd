LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY single_pulse_detector IS
    Generic (
        detect_type : std_logic_vector(1 downto 0) := "00" -- edge detection type
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        input_signal : IN STD_LOGIC;
        output_pulse : OUT STD_LOGIC);
END single_pulse_detector;

ARCHITECTURE Behavioral OF single_pulse_detector IS
    SIGNAL ff0 : STD_LOGIC;
    SIGNAL ff1 : STD_LOGIC;
BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            ff0 <= '0';
            ff1 <= '0';
        ELSIF rising_edge(clk) THEN
            ff0 <= input_signal;
            ff1 <= ff0;
        END IF;
    END PROCESS;

    with detect_type select output_pulse <= 
        not ff1 and ff0 when "00", -- rising edge
        not ff0 and ff1 when "01", -- falling edge
        ff0 xor ff1 when "10", -- both edges
        '0' when others; -- none

END Behavioral;