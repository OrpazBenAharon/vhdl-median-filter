library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_fsm is
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
end control_fsm;

architecture behavioral of control_fsm is

    type state_type is (IDLE, PROCESSING, LAST_ROW, FINISHED);
    signal current_state, next_state : state_type := IDLE;

    -- Registers
    signal write_delay_sr : std_logic_vector(2 downto 0) := (others => '0');
    signal read_counter   : integer range 0 to 255       := 0;
    signal write_counter  : integer range 0 to 255       := 0;
    signal at_last_row    : std_logic                    := '0';
    signal write_en_delay : std_logic                    := '0';
    signal push_en_delay  : std_logic                    := '0';

    -- Control Signals
    signal read_en_sig  : std_logic := '0';
    signal write_en_sig : std_logic := '0';
    signal push_en_sig  : std_logic := '0';
    signal done_sig     : std_logic := '0';

begin

    --------------------------------------------------------------------
    -- Sequential Process for State, Counters, and Delays
    --------------------------------------------------------------------
    process (clk, reset)
    begin
        if reset = '1' then
            current_state  <= IDLE;
            read_counter   <= 0;
            write_counter  <= 0;
            write_en_delay <= '0';
            at_last_row    <= '0';
            write_delay_sr <= (others => '0');

        elsif rising_edge(clk) then
            -- Update State
            current_state <= next_state;

            if read_counter = 254 then
                at_last_row <= '1';
            end if;

            -- Update Read Counter
            if read_en_sig = '1' then
                read_counter <= read_counter + 1;
            end if;

            -- Update Write Counter
            if write_en_delay = '1' and write_counter < 255 then
                write_counter <= write_counter + 1;
            end if;

            -- Update pipeline registers
            write_delay_sr <= write_delay_sr(1 downto 0) & write_en_sig;
            write_en_delay <= write_delay_sr(2);
            push_en_delay  <= push_en_sig;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Combinational Next State & Control Outputs
    --------------------------------------------------------------------
    process (current_state, start, at_last_row)
    begin
        -- Defaults
        next_state   <= current_state;
        read_en_sig  <= '0';
        push_en_sig  <= '0';
        write_en_sig <= '0';
        done_sig     <= '0';
        case current_state is
                ----------------------------------------------------------------
            when IDLE =>
                next_state   <= IDLE;
                read_en_sig  <= '0';
                push_en_sig  <= '0';
                write_en_sig <= '0';
                done_sig     <= '0';
                if start = '1' then
                    read_en_sig  <= '1';
                    push_en_sig  <= '1';
                    write_en_sig <= '1';
                    next_state   <= PROCESSING;
                end if;
                ----------------------------------------------------------------
            when PROCESSING =>
                read_en_sig  <= '1';
                push_en_sig  <= '1';
                write_en_sig <= '1';
                next_state   <= PROCESSING;
                if at_last_row = '1' then
                    read_en_sig  <= '0';
                    push_en_sig  <= '1';
                    write_en_sig <= '1';
                    next_state   <= LAST_ROW;
                end if;
                ----------------------------------------------------------------
            when LAST_ROW =>
                read_en_sig  <= '0';
                push_en_sig  <= '1';
                write_en_sig <= '0';
                next_state   <= FINISHED;

                ----------------------------------------------------------------
            when FINISHED =>
                read_en_sig  <= '0';
                push_en_sig  <= '1';
                write_en_sig <= '0';
                done_sig     <= '1';
                next_state   <= FINISHED;

            when others =>
                next_state <= IDLE;
        end case;
    end process;

    --------------------------------------------------------------------
    -- Output Assignments
    --------------------------------------------------------------------
    done       <= done_sig;
    push_en    <= push_en_delay;
    write_en   <= write_en_delay;
    read_addr  <= std_logic_vector(to_unsigned(read_counter, 8));
    write_addr <= std_logic_vector(to_unsigned(write_counter, 8));

end behavioral;