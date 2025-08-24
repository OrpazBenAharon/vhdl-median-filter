-- megafunction wizard: %ROM: 1-PORT%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altsyncram 

-- ============================================================
-- File Name: rom_r.vhd
-- Megafunction Name(s):
-- 			altsyncram
--
-- Simulation Library Files(s):
-- 			
-- ============================================================



LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY rom_r IS
	  generic (
		PIXEL_WIDTH : integer := 5;
		FILE_NAME   : string  := "r.mif"
	  );
	  port (
		address : in std_logic_vector (7 downto 0);
		clock   : in std_logic := '1';
		q       : out std_logic_vector (256 * PIXEL_WIDTH - 1 downto 0)
	  );
END rom_r;


ARCHITECTURE SYN_R OF rom_r IS

	SIGNAL sub_wire0	: std_logic_vector (256 * PIXEL_WIDTH - 1 downto 0);

BEGIN
	q    <= sub_wire0(256 * PIXEL_WIDTH - 1 downto 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => FILE_NAME,
		intended_device_family => "Cyclone IV E",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 256,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		widthad_a => 8,
		width_a => 256 * PIXEL_WIDTH,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => address,
		clock0 => clock,
		q_a => sub_wire0
	);



END SYN_R;


