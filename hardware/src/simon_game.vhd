library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity simon_game is
    Generic (
        CLK_FREQ : positive := 125_000_000;
        ADDR_WIDTH : integer := 4;
        DATA_WIDTH : integer := 4
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
    type mem_2d_type is array (0 to 2**ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal array_reg : mem_2d_type;

    -- Reset
    signal rst : std_logic;

    --***LEDS***----------------------------------------------
    signal led_sig : std_logic_vector(3 downto 0);


    --***FSM States***-----------------------------------------
    TYPE GameStateType IS (CAPTURE, HOLD, LOAD, PATTERN, CHECK, CORRECT, HIGHSCORE ,WRONG, SCORE, GAMEOVER); -- game states
    SIGNAL state : GameStateType; -- current game state
    constant load_pattern : natural := 15;
    constant max_pattern : natural := 9;

    --***Random Number Generator Signals***--------------------
    signal seed_top : std_logic_vector(7 DOWNTO 0) := x"64";
    signal rand_out_top : std_logic_vector(3 downto 0);
    signal rand_num : std_logic_vector(3 downto 0);

    --***Clock***----------------------------------------------
    constant HALF_PERIOD : integer := (CLK_FREQ/8); -- for 4Hz
    signal SPEED : integer;
    signal FLASH : integer;
  
    signal clk_div : std_logic;
    signal clk_diff : std_logic;
    signal clk_fl : std_logic;
    signal counter_div : natural;
    signal counter_diff : natural;
    signal counter_flash : natural;
    signal conter_hold : natural;
    signal pattern_flash_toggle : boolean;


    signal speed_sel : std_logic_vector(4 downto 0);
    signal counter_speed : integer;
    signal clk_game_speed : std_logic;
    constant SPEED0 : integer := (CLK_FREQ/2); -- for 1Hz
    constant SPEED1 : integer := (CLK_FREQ/4); -- for 2Hz
    constant SPEED2 : integer := (CLK_FREQ/16); -- for 8Hz
    constant SPEED4 : integer := (CLK_FREQ/32); -- for 16Hz
    constant SPEED88 : integer := (CLK_FREQ/64); -- for 32Hz
    constant SPEED_SIM : integer := (CLK_FREQ/1024); -- for 512Hz


    --***Counters***---------------------------------------
    signal counter_correct : natural;
    signal counter_score : natural;
    signal high_score_counter : natural;
    signal counter_wrong : natural;
    signal load_counter : natural;
    signal pattern_counter : natural;
    signal curr_game_counter : natural;
    signal btn_counter : natural;

    --***Button***-------------------------------------------------
    signal btn_debounce : std_logic_vector(3 downto 0);
    signal btn_pulse : std_logic_vector(3 downto 0);
    signal btn_led : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal data : std_logic_vector(DATA_WIDTH-1 downto 0);
    

begin

    --***Port Mapping***----------------------------------------------
    -- Random Number Generator
    rand_gen: entity work.rand_gen
        port map (
            clk => clk,
            rst => rst,
            seed => seed_top,
            rand_out => rand_out_top
        );

    -- Button 0
    btn0: entity work.debounce
        generic map (
            CLK_FREQ => CLK_FREQ,
            STABLE_TIME => 10
        )
        port map (
            clk => clk,
            rst => '0',
            button => btn(0),
            result => btn_debounce(0)
        );

    -- Button 1
    btn1: entity work.debounce
        generic map (
            CLK_FREQ => CLK_FREQ,
            STABLE_TIME => 10
        )
        port map (
            clk => clk,
            rst => '0',
            button => btn(1),
            result => btn_debounce(1)
        );

    -- Button 2
    btn2: entity work.debounce
        generic map (
            CLK_FREQ => CLK_FREQ,
            STABLE_TIME => 10
        )
        port map (
            clk => clk,
            rst => '0',
            button => btn(2),
            result => btn_debounce(2)
        );

    -- Button 3
    btn3: entity work.debounce
        generic map (
            CLK_FREQ => CLK_FREQ,
            STABLE_TIME => 10
        )
        port map (
            clk => clk,
            rst => '0',
            button => btn(3),
            result => btn_debounce(3)
        );
    
    -- Pulse 0
    p0: entity work.single_pulse_detector    
        generic map (
            detect_type => "00" -- edge detection type
        )
        port map (
            clk => clk,
            rst => rst,
            input_signal => btn_debounce(0),
            output_pulse => btn_pulse(0)
        );

    -- Pulse 1
    p1: entity work.single_pulse_detector    
        generic map (
            detect_type => "00" -- edge detection type
        )
        port map (
            clk => clk,
            rst => rst,
            input_signal => btn_debounce(1),
            output_pulse => btn_pulse(1)
        );

    -- Pulse 2
    p2: entity work.single_pulse_detector    
        generic map (
            detect_type => "00" -- edge detection type
        )
        port map (
            clk => clk,
            rst => rst,
            input_signal => btn_debounce(2),
            output_pulse => btn_pulse(2)
        );

    -- Pulse 3   
    p3: entity work.single_pulse_detector    
        generic map (
            detect_type => "00" -- edge detection type
        )
        port map (
            clk => clk,
            rst => rst,
            input_signal => btn_debounce(3),
            output_pulse => btn_pulse(3)
        );

    --***Signals***----------------------------------------------
    -- Reset Signal
    rst <= btn(0) and btn(3);
    
    led <= led_sig;

    btn_led <=  x"1" when btn_pulse(0) = '1' else 
                x"2" when btn_pulse(1) = '1' else 
                x"4" when btn_pulse(2) = '1' else
                x"8" when btn_pulse(3) = '1' else 
                x"0";


    --***Processes***----------------------------------------------

    rand_num_shift: process (rand_out_top)
    begin
        rand_num <= rand_out_top(0) & rand_out_top(3 downto 1);
    end process;

    -- FSM
    FSM: process(clk, rst)
    begin
        if rst = '1' then
            state <= CAPTURE;
            curr_game_counter <= 1;
            high_score_counter <= 0;
        elsif rising_edge(clk) then
            case state is
                when CAPTURE =>
                if btn_pulse(1) = '1' then
                    state <= LOAD;
                else
                    state <= CAPTURE;
                end if;

                when LOAD =>
                    if load_counter = load_pattern then
                        state <= HOLD;
                    else
                        state <= LOAD;
                    end if;
                
                when HOLD =>
                    if conter_hold = 4 then
                        state <= PATTERN;
                    else
                        state <= HOLD;
                    end if;

                when PATTERN =>
                    if pattern_counter = curr_game_counter then
                        state <= CHECK;
                    else
                        state <= PATTERN;
                    end if; 

                when CHECK =>
                    if (or btn_pulse = '1') then
                        if (btn_led = array_reg(btn_counter))  then
                            state <= CHECK;
                        elsif (btn_led /= array_reg(btn_counter)) then
                            state <= WRONG;
                        end if;
                    elsif (btn_counter = curr_game_counter) then
                            state <= CORRECT;
                    end if;

                when CORRECT =>
                    if counter_correct = 4 then
                        curr_game_counter <= curr_game_counter + 1;
                        high_score_counter <= high_score_counter + 1;
                        if high_score_counter = max_pattern then 
                            state <= HIGHSCORE;
                        else
                            state <= PATTERN;
                        end if;   
                    end if;

                when HIGHSCORE =>
                        state <= SCORE;

                when WRONG =>
                    if counter_wrong = 4 then
                        state <= SCORE;
                    else
                        state <= WRONG;
                    end if;

                when SCORE =>
                    if counter_score = 2*high_score_counter then
                        state <= GAMEOVER;
                    end if;    
                    
                when GAMEOVER =>
                        -- no-op
                
                when others =>
                    state <= CAPTURE;
            end case;
        end if;
    end process;

    -- Holding
    -- for zybo: clk_div 
    -- for sim: clk_game_speed and switch = x"f'
    holding_p: process(clk_div, rst)
    begin
        if rst = '1' then
            conter_hold <= 0;
        elsif rising_edge(clk_div) then
            if state = HOLD then
                conter_hold <= conter_hold + 1;
            else
                conter_hold <= 0;
            end if;
        end if;
    end process;

    -- Loading 
    loading_p: process(clk, rst)
    begin
        if rst = '1' then
            load_counter <= 0;
        elsif rising_edge(clk) then
            if state = LOAD then
                array_reg(load_counter) <= rand_num;
                load_counter <= load_counter + 1;
            else
                load_counter <= 0;
            end if;
        end if;
    end process;

    -- Pattern
    flash_p: process(clk_game_speed, rst)
    begin
        if rst = '1' then
            led_sig <= x"0";
            pattern_flash_toggle <= true;
            pattern_counter <= 0;
        elsif rising_edge(clk_game_speed) then
            if state = PATTERN then
                if pattern_flash_toggle then
                    pattern_counter <= pattern_counter + 1;
                    led_sig <=  array_reg(pattern_counter);
                    pattern_flash_toggle <= false;
                else
                    pattern_flash_toggle <= true;
                    led_sig <= x"0";
                end if;
            else
            pattern_counter <= 0;
                led_sig <= x"0";
            end if;
            if state = GAMEOVER or state = CAPTURE then
                led_sig <= rand_out_top;
            end if;
        end if;
    end process;

    -- Checking
    checking_p: process(clk, rst)
    begin
        if rst = '1' then
            btn_counter <= 0;
        elsif rising_edge(clk) then
            if state = CHECK then
                if (btn_led = array_reg(btn_counter)) and (or btn_pulse = '1') then
                    btn_counter <= btn_counter + 1;
                end if;
            else
                btn_counter <= 0;
            end if;
        end if;
    end process;


    -- Correct Flash: Green LED
    -- for zybo: clk_div 
    -- for sim: clk_game_speed and switch = x"f'
    corresct_flash_p: process(clk_div, rst)
    begin
        if rst = '1' then
            counter_correct <= 0;
            green_led <= '0';
        elsif rising_edge(clk_div) then
            if state = CORRECT then
                counter_correct <= counter_correct + 1;
                green_led <= not green_led;
            else
                counter_correct <= 0;
                green_led <= '0';
            end if;
        end if;
    end process;

    

    -- Wrong: Red LED
    -- for zybo: clk_div 
    -- for sim: clk_game_speed and switch = x"f'
    wrong_p: process(clk_div, rst)
    begin
        if rst = '1' then
            counter_wrong <= 0;
            red_led <= '0';
        elsif rising_edge(clk_div) then
            if state = WRONG then
                counter_wrong <= counter_wrong + 1;
                red_led <= '1';
            else
            red_led <= '0';
            counter_wrong <= 0;
            end if;
        end if;
    end process;

    -- Score Flash: Blue LED
    -- for zybo: clk_div
    -- for sim: clk_game_speed and switch = x"f'
    score_p: process(clk_div, rst)
    begin
        if rst = '1' then
            counter_score <= 0;
            blue_led <= '0';
        elsif rising_edge(clk_div) then
            if state = SCORE then
                if counter_score /= 2*high_score_counter then
                counter_score <= counter_score + 1;
                blue_led <= not blue_led;
                end if;
            else
            counter_score <= 0;
            blue_led <= '0';
            end if;
        end if;
    end process;

    -- Clk Div:
    clk_div_p : process (clk, rst)
    begin
        if rst = '1' then
            clk_div <= '0';
            counter_div <= 0;
        elsif rising_edge(clk) then
            counter_div <= counter_div + 1;
            if counter_div = HALF_PERIOD-1 then
                clk_div <= not clk_div;
                counter_div <= 0;
            end if;
        end if;
    end process;

    -- Game Speed
    game_speed_p : process(clk, rst)
    begin
        if rst = '1' then
            clk_game_speed <= '0';
            counter_speed <= 0;
            speed_sel <= "00000";
        elsif rising_edge(clk) then
            counter_speed <= counter_speed + 1;
            case switches is
                when x"0" =>
                    if speed_sel(0) = '0' then
                        counter_speed <= 0;
                        speed_sel <= "00001";
                    end if;
                    if counter_speed = SPEED0-1 then
                        clk_game_speed <= not clk_game_speed;
                        counter_speed <= 0;
                    end if;
                when x"1" =>
                    if speed_sel(1) = '0' then
                        counter_speed <= 0;
                        speed_sel <= "00010";
                    end if;
                    if counter_speed = SPEED1-1 then
                        clk_game_speed <= not clk_game_speed;
                        counter_speed <= 0;
                    end if;
                when x"2" =>
                    if speed_sel(2) = '0' then
                        counter_speed <= 0;
                        speed_sel <= "00100";
                    end if;
                    if counter_speed = SPEED2-1 then
                        clk_game_speed <= not clk_game_speed;
                        counter_speed <= 0;
                    end if;
                when x"4" =>
                    if speed_sel(3) = '0' then
                        counter_speed <= 0;
                        speed_sel <= "01000";
                    end if;
                    if counter_speed = SPEED4-1 then
                        clk_game_speed <= not clk_game_speed;
                        counter_speed <= 0;
                    end if;

                when x"8" =>
                    if speed_sel(4) = '0' then
                        counter_speed <= 0;
                        speed_sel <= "10000";
                    end if;
                    if counter_speed = SPEED88-1 then
                        clk_game_speed <= not clk_game_speed;
                        counter_speed <= 0;
                    end if;

                    when x"f" =>
                    if speed_sel(4 downto 3) = "00" then
                        counter_speed <= 0;
                        speed_sel <= "11000";
                    end if;
                    if counter_speed = SPEED_SIM-1 then
                        clk_game_speed <= not clk_game_speed;
                        counter_speed <= 0;
                    end if;

                when others =>
                    if speed_sel(0) = '0' then
                        counter_speed <= 0;
                        speed_sel <= "00001";
                    end if;
                    if counter_speed = SPEED0-1 then
                        clk_game_speed <= not clk_game_speed;
                        counter_speed <= 0;
                    end if;
            end case;
        end if;
    end process;
                    
end Behavioral;
