library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.filter_pkg.all;

entity median_filter is
	generic (
        N           : integer;
        PIXEL_WIDTH : integer
	);
	port (
		line0       : in std_logic_vector((N * PIXEL_WIDTH) - 1 downto 0);
		line1       : in std_logic_vector((N * PIXEL_WIDTH) - 1 downto 0);
		line2       : in std_logic_vector((N * PIXEL_WIDTH) - 1 downto 0);
		medians_out : out std_logic_vector((N * PIXEL_WIDTH) - 1 downto 0)
	);
end median_filter;

architecture rtl of median_filter is

	subtype pixel_type is unsigned(PIXEL_WIDTH - 1 downto 0);
	type pixel_array is array (0 to N - 1) of pixel_type;

	-- Each column's TIS outputs
	signal max_arr : pixel_array := (others => (others => '0'));
	signal mid_arr : pixel_array := (others => (others => '0'));
	signal min_arr : pixel_array := (others => (others => '0'));

begin

	------------------------------------------------------------------------------
	-- Triple Input Sort for Each Column
	------------------------------------------------------------------------------
	gen_sorters : for c in 0 to N - 1 generate
		process (line0, line1, line2)
			variable px0, px1, px2 : pixel_type;
			variable sorted        : triple_sort_result;
		begin
			-- Extract the three pixels for column c
			px0 := unsigned(line0((c * PIXEL_WIDTH) + PIXEL_WIDTH - 1 downto c * PIXEL_WIDTH));
			px1 := unsigned(line1((c * PIXEL_WIDTH) + PIXEL_WIDTH - 1 downto c * PIXEL_WIDTH));
			px2 := unsigned(line2((c * PIXEL_WIDTH) + PIXEL_WIDTH - 1 downto c * PIXEL_WIDTH));

			-- Perform sorting
			sorted := triple_sort(px0, px1, px2);

			-- Decompose sorted result
			max_arr(c) <= sorted((3 * PIXEL_WIDTH) - 1 downto (2 * PIXEL_WIDTH));
			mid_arr(c) <= sorted((2 * PIXEL_WIDTH) - 1 downto PIXEL_WIDTH);
			min_arr(c) <= sorted((PIXEL_WIDTH) - 1 downto 0);
		end process;
	end generate;

	------------------------------------------------------------------------------
	-- Compute Final Median for Each Column
	------------------------------------------------------------------------------
	gen_final_medians : for c in 0 to N - 1 generate
		process (max_arr, mid_arr, min_arr)
			variable L, R                                 : integer;
			variable min_val, mid_val, max_val, final_med : pixel_type;
		begin
			-- Handle edge cases with virtual padding
			if c = 0 then
				L := 0;
			else
				L := c - 1;
			end if;

			if c = (N - 1) then
				R := N - 1;
			else
				R := c + 1;
			end if;

			-- Compute min, mid, max values
			min_val := find_min3(max_arr(L), max_arr(c), max_arr(R));
			mid_val := find_med3(mid_arr(L), mid_arr(c), mid_arr(R));
			max_val := find_max3(min_arr(L), min_arr(c), min_arr(R));

			-- Final median
			final_med := find_med3(min_val, mid_val, max_val);

			-- Assign output
			medians_out((c * PIXEL_WIDTH) + PIXEL_WIDTH - 1 downto c * PIXEL_WIDTH) <= std_logic_vector(final_med);
		end process;
	end generate;

end rtl;