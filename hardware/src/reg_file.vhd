library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity reg_file is
    Generic (
        ADDR_WIDTH : integer := 4;
        DATA_WIDTH : integer := 2
    );
    Port (
        clk : in std_logic;
        wr_en : in std_logic;
        w_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        r_addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
        w_data : in std_logic_vector(DATA_WIDTH-1 downto 0);
        r_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end reg_file;

architecture Behavioral of reg_file is
    type mem_2d_type is array (0 to 2**ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal array_reg : mem_2d_type;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if wr_en = '1' then
                array_reg(to_integer(unsigned(w_addr))) <= w_data;
            end if;
        end if;
    end process;

    -- read port
    r_data <= array_reg(to_integer(unsigned(r_addr)));
end Behavioral;