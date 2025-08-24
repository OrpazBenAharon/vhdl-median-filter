library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_filter_system is
end tb_filter_system;

architecture behavioral of tb_filter_system is

    ---------------------------------------------------------------------------
    -- Constants and Parameters
    ---------------------------------------------------------------------------
    constant CLK_PERIOD  : time    := 20 ns; 
    constant N           : integer := 256;   
    constant PIXEL_WIDTH : integer := 5;     

    ---------------------------------------------------------------------------
    -- DUT Port Signals
    ---------------------------------------------------------------------------
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal start : std_logic := '0';
    signal done  : std_logic := '0';

    ---------------------------------------------------------------------------
    -- DUT Instantiation
    ---------------------------------------------------------------------------
    component filter_system is
        generic (
            N           : integer := N;
            PIXEL_WIDTH : integer := PIXEL_WIDTH
        );
        port (
            clk   : in std_logic;
            reset : in std_logic;
            start : in std_logic;
            done  : out std_logic
        );
    end component;

begin

    -- DUT Instantiation
    dut : filter_system
    generic map(
        N           => N,
        PIXEL_WIDTH => PIXEL_WIDTH
    )
    port map(
        clk   => clk,
        reset => reset,
        start => start,
        done  => done
    );

    ---------------------------------------------------------------------------
    -- Clock Generation
    ---------------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD / 2;

    ---------------------------------------------------------------------------
    -- Stimulus Process
    ---------------------------------------------------------------------------
    stimulus : process
    begin
        -- Apply Reset
        reset <= '1';
        wait for CLK_PERIOD * 5;
        reset <= '0';

        -- Wait for reset to settle
        wait for CLK_PERIOD * 5;

        -- Start the Filtering Process
        start <= '1';
        wait for CLK_PERIOD * 5;
        start <= '0';

        -- Wait for the filtering to complete
        wait until done = '1';

        report "Simulation complete" severity note;

        wait;
    end process;

end behavioral;