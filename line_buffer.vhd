library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity line_buffer is
    generic (
        N           : integer;
        PIXEL_WIDTH : integer
    );
    port (
        clk          : in std_logic;
        reset        : in std_logic;
        load_new_row : in std_logic;
        new_row      : in std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
        line0        : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
        line1        : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
        line2        : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0)
    );
end line_buffer;

architecture behavioral of line_buffer is
    signal buffer0 : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0) := (others => '0');
    signal buffer1 : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0) := (others => '0');
    signal buffer2 : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0) := (others => '0');
begin
    process (clk, reset)
    begin
        if reset = '1' then
            buffer0 <= (others => '0');
            buffer1 <= (others => '0');
            buffer2 <= (others => '0');
        elsif rising_edge(clk) then
            if load_new_row = '1' then
                buffer0 <= buffer1;
                buffer1 <= buffer2;
                buffer2 <= new_row;
            end if;
        end if;
    end process;

    line0 <= buffer0;
    line1 <= buffer1;
    line2 <= buffer2;
end behavioral;