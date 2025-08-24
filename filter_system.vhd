library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.filter_pkg.all;

entity filter_system is
    generic (
        N           : integer := 256; 
        PIXEL_WIDTH : integer := 5    
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;
        start : in std_logic;
        done  : out std_logic
    );
end filter_system;

architecture rtl of filter_system is

    ------------------------------------------------------------------------------
    -- Component Declarations
    ------------------------------------------------------------------------------

    -- Control FSM
    component control_fsm is
        port (
            clk        : in std_logic;
            reset      : in std_logic;
            start      : in std_logic;
            done       : out std_logic;
            push_en    : out std_logic;
            write_en   : out std_logic;
            read_addr  : out std_logic_vector(7 downto 0);
            write_addr : out std_logic_vector(7 downto 0)
        );
    end component;

    -- ROMs for R, G, B Channels
    component rom_r is
        generic (
            PIXEL_WIDTH : integer := PIXEL_WIDTH
        );
        port (
            address : in std_logic_vector(7 downto 0);
            clock   : in std_logic;
            q       : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0)
        );
    end component;

    component rom_g is
        generic (
            PIXEL_WIDTH : integer := PIXEL_WIDTH
        );
        port (
            address : in std_logic_vector(7 downto 0);
            clock   : in std_logic;
            q       : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0)
        );
    end component;

    component rom_b is
        generic (
            PIXEL_WIDTH : integer := PIXEL_WIDTH
        );
        port (
            address : in std_logic_vector(7 downto 0);
            clock   : in std_logic;
            q       : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0)
        );
    end component;

    -- Line Buffers for R, G, B Channels
    component line_buffer is
        generic (
            N           : integer := N;
            PIXEL_WIDTH : integer := PIXEL_WIDTH
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
    end component;

    -- Optimized Median Filters for R, G, B Channels
    component median_filter is
        generic (
            N           : integer := N;
            PIXEL_WIDTH : integer := PIXEL_WIDTH
        );
        port (
            line0       : in std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
            line1       : in std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
            line2       : in std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
            medians_out : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0)
        );
    end component;

    -- RAMs for R, G, B Channels
    component ram_r is
        generic (
            PIXEL_WIDTH : integer := PIXEL_WIDTH
        );
        port (
            address : in std_logic_vector(7 downto 0);
            clock   : in std_logic;
            data    : in std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
            wren    : in std_logic;
            q       : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0)
        );
    end component;

    component ram_g is
        generic (
            PIXEL_WIDTH : integer := PIXEL_WIDTH
        );
        port (
            address : in std_logic_vector(7 downto 0);
            clock   : in std_logic;
            data    : in std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
            wren    : in std_logic;
            q       : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0)
        );
    end component;

    component ram_b is
        generic (
            PIXEL_WIDTH : integer := PIXEL_WIDTH
        );
        port (
            address : in std_logic_vector(7 downto 0);
            clock   : in std_logic;
            data    : in std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
            wren    : in std_logic;
            q       : out std_logic_vector(N * PIXEL_WIDTH - 1 downto 0)
        );
    end component;

    ------------------------------------------------------------------------------
    -- Signals for Control and Data Flow
    ------------------------------------------------------------------------------

    -- Control FSM Signals
    signal line_push    : std_logic;
    signal ram_write_en : std_logic;
    signal rom_address  : std_logic_vector(7 downto 0);
    signal ram_address  : std_logic_vector(7 downto 0);

    -- ROM Outputs
    signal rom_r_data : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal rom_g_data : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal rom_b_data : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);

    -- Line Buffer Outputs
    signal line0_r : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal line1_r : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal line2_r : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal line0_g : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal line1_g : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal line2_g : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal line0_b : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal line1_b : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal line2_b : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);

    -- Median Filter Outputs
    signal medians_out_r : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal medians_out_g : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal medians_out_b : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);

    -- Internal signals to capture RAM outputs 
    signal ram_r_q : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal ram_g_q : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);
    signal ram_b_q : std_logic_vector(N * PIXEL_WIDTH - 1 downto 0);

    ------------------------------------------------------------------------------
    -- Architecture Body: Instantiations and Signal Assignments
    ------------------------------------------------------------------------------
begin

    ------------------------------------------------------------------------------
    -- Control FSM Instantiation
    ------------------------------------------------------------------------------
    control_fsm_inst : control_fsm
    port map(
        clk        => clk,
        reset      => reset,
        start      => start,
        done       => done,
        push_en    => line_push,
        write_en   => ram_write_en,
        read_addr  => rom_address,
        write_addr => ram_address
    );

    ------------------------------------------------------------------------------
    -- ROM Instantiation for R, G, B Channels
    ------------------------------------------------------------------------------
    rom_r_inst : rom_r
    port map(
        address => rom_address,
        clock   => clk,
        q       => rom_r_data
    );

    rom_g_inst : rom_g
    port map(
        address => rom_address,
        clock   => clk,
        q       => rom_g_data
    );

    rom_b_inst : rom_b
    port map(
        address => rom_address,
        clock   => clk,
        q       => rom_b_data
    );

    ------------------------------------------------------------------------------
    -- Line Buffer Instantiation for R, G, B Channels
    ------------------------------------------------------------------------------
    line_buffer_r_inst : line_buffer
    generic map(
        N           => N,
        PIXEL_WIDTH => PIXEL_WIDTH
    )
    port map(
        clk          => clk,
        reset        => reset,
        load_new_row => line_push,
        new_row      => rom_r_data,
        line0        => line0_r,
        line1        => line1_r,
        line2        => line2_r
    );

    line_buffer_g_inst : line_buffer
    generic map(
        N           => N,
        PIXEL_WIDTH => PIXEL_WIDTH
    )
    port map(
        clk          => clk,
        reset        => reset,
        load_new_row => line_push,
        new_row      => rom_g_data,
        line0        => line0_g,
        line1        => line1_g,
        line2        => line2_g
    );

    line_buffer_b_inst : line_buffer
    generic map(
        N           => N,
        PIXEL_WIDTH => PIXEL_WIDTH
    )
    port map(
        clk          => clk,
        reset        => reset,
        load_new_row => line_push,
        new_row      => rom_b_data,
        line0        => line0_b,
        line1        => line1_b,
        line2        => line2_b
    );

    ------------------------------------------------------------------------------
    -- Median Filter Instantiation for R, G, B Channels
    ------------------------------------------------------------------------------
    median_filter_r_inst : median_filter
    generic map(
        N           => N,
        PIXEL_WIDTH => PIXEL_WIDTH
    )
    port map(
        line0       => line0_r,
        line1       => line1_r,
        line2       => line2_r,
        medians_out => medians_out_r
    );

    median_filter_g_inst : median_filter
    generic map(
        N           => N,
        PIXEL_WIDTH => PIXEL_WIDTH
    )
    port map(
        line0       => line0_g,
        line1       => line1_g,
        line2       => line2_g,
        medians_out => medians_out_g
    );

    median_filter_b_inst : median_filter
    generic map(
        N           => N,
        PIXEL_WIDTH => PIXEL_WIDTH
    )
    port map(
        line0       => line0_b,
        line1       => line1_b,
        line2       => line2_b,
        medians_out => medians_out_b
    );
    ------------------------------------------------------------------------------
    -- RAM Instantiation for R, G, B Channels
    ------------------------------------------------------------------------------
    ram_r_inst : ram_r
    port map(
        address => ram_address,
        clock   => clk,
        data    => medians_out_r,
        wren    => ram_write_en,
        q       => ram_r_q
    );

    ram_g_inst : ram_g
    port map(
        address => ram_address,
        clock   => clk,
        data    => medians_out_g,
        wren    => ram_write_en,
        q       => ram_g_q
    );

    ram_b_inst : ram_b
    port map(
        address => ram_address,
        clock   => clk,
        data    => medians_out_b,
        wren    => ram_write_en,
        q       => ram_b_q
    );

end rtl;