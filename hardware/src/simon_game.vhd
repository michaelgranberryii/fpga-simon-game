library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity simon_game is
    Generic (
        CLK_FREQ : positive := 125_000_000
    );
    Port (
        clk: in std_logic;
        btn : in std_logic_vector(3 downto 0);
        switches : in std_logic_vector(3 downto 0);
        led : out std_logic_vector(3 downto 0);
        red_led, green_led, blue_led : out std_logic
    );
end simon_game;

architecture Behavioral of simon_game is
    -- Reset
    signal rst : std_logic;

    -- FSM States
    TYPE GameStateType IS (RESET, PATTERN, CHECK, SCORE); -- game states
    SIGNAL state : GameStateType; -- current game state
    signal game_counter : natural;
    signal curr_game_counter : natural;

    -- Random Number Generator Signals
    signal seed_top : std_logic_vector(7 DOWNTO 0) := x"a4";
    signal rand_gen_out : std_logic_vector(3 downto 0);

    -- Register File Constans
    constant ADDR_WIDTH : integer := 4;
    constant DATA_WIDTH : integer := 2;

    -- Register File Signals
    signal addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal r_data_led : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Clock Constans
    constant HALF_PERIOD : integer := (CLK_FREQ/4); -- for 2Hz
    constant SPEED0 : integer := (CLK_FREQ/2); -- for 1Hz
    constant SPEED1 : integer := (CLK_FREQ/4); -- for 2Hz
    constant SPEED2 : integer := (CLK_FREQ/8); -- for 4Hz
    constant SPEED4 : integer := (CLK_FREQ/16); -- for 8Hz
    constant SPEED8 : integer := (CLK_FREQ/32); -- for 16Hz

    -- Clock Signals
    signal clk_2Hz : std_logic;
    signal clk_sp : std_logic;
    signal count_2Hz : natural;
    signal count_sp : natural;
    signal speed : std_logic_vector(4 downto 0);


begin
    -- Reset Signal
    rst <= btn(0) and btn(3);

    -- Random Number Generator
    rand_gen: entity work.rand_gen
        port map (
            clk => clk,
            rst => rst,
            seed => seed_top,
            output => rand_gen_out
        );

    -- Register File
    reg_file: entity work.reg_file
        generic map (
            ADDR_WIDTH => ADDR_WIDTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map (
            clk => clk,
            wr_en => '1',
            w_addr => addr,
            r_addr => addr,
            w_data => rand_gen_out(DATA_WIDTH-1 downto 0),
            r_data => r_data_led
        );

    clk_div_2hz : process (clk, rst)
    begin
        if rst = '1' then
            clk_2Hz <= '0';
            count_2Hz <= 0;
        elsif rising_edge(clk) then
            count_2Hz <= count_2Hz + 1;
            if count_2Hz = HALF_PERIOD-1 then
                clk_2Hz <= not clk_2Hz;
                count_2Hz <= 0;
            end if;
        end if;
    end process;

    clk_div_dif : process(clk, rst)
    begin
        if rst = '1' then
            clk_sp <= '0';
            count_sp <= 0;
            speed <= "00000";
        elsif rising_edge(clk) then
            count_sp <= count_sp + 1;
            case switches is
                when x"0" =>
                    if speed(0) = '0' then
                        count_sp <= 0;
                        speed <= "00001";
                    end if;
                    if count_sp = SPEED0-1 then
                        clk_sp <= not clk_sp;
                        count_sp <= 0;
                    end if;
                when x"1" =>
                    if speed(1) = '0' then
                        count_sp <= 0;
                        speed <= "00010";
                    end if;
                    if count_sp = SPEED1-1 then
                        clk_sp <= not clk_sp;
                        count_sp <= 0;
                    end if;
                when x"2" =>
                    if speed(2) = '0' then
                        count_sp <= 0;
                        speed <= "00100";
                    end if;
                    if count_sp = SPEED2-1 then
                        clk_sp <= not clk_sp;
                        count_sp <= 0;
                    end if;
                when x"4" =>
                    if speed(3) = '0' then
                        count_sp <= 0;
                        speed <= "01000";
                    end if;
                    if count_sp = SPEED4-1 then
                        clk_sp <= not clk_sp;
                        count_sp <= 0;
                    end if;

                when x"8" =>
                    if speed(4) = '0' then
                        count_sp <= 0;
                        speed <= "10000";
                    end if;
                    if count_sp = SPEED8-1 then
                        clk_sp <= not clk_sp;
                        count_sp <= 0;
                    end if;
                when others =>
                    if speed(0) = '0' then
                        count_sp <= 0;
                        speed <= "00001";
                    end if;
                    if count_sp = SPEED0-1 then
                        clk_sp <= not clk_sp;
                        count_sp <= 0;
                    end if;
            end case;
        end if;
    end process;

    FSM: process(clk, rst)
    begin
        if rst = '1' then
            state <= RESET;
            game_counter <= 0;
        elsif rising_edge(clk) then
            case state is
                when RESET =>
                    state <= PATTERN;
                when PATTERN =>
                    if game_counter = curr_game_counter then
                        state <= CHECK;
                    end if; 
                when CHECK => 
                    if game_counter = curr_game_counter then
                        state <= PATTERN;
                    end if; 
                when SCORE =>
                    state <= RESET;
                when others =>
                    state <= RESET;
            end case;
        end if;
    end process;

    FSM_output: process(clk, rst)
    begin
        if rst = '1' then
            
        elsif rising_edge(clk) then
            case state is
                when RESET =>

                when PATTERN =>

                when CHECK => 

                when SCORE =>

                when others =>
            
            end case;
        end if;
    end process;

    

    red_led <= clk_sp;
    green_led <= clk_sp;
    blue_led <= clk_sp;
    led <= clk_2Hz & not clk_2Hz & clk_2Hz & not clk_2Hz;
end Behavioral;
