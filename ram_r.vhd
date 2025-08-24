-- megafunction wizard: %RAM: 1-PORT%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altsyncram 

-- ============================================================
-- File Name: ram_r.vhd
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

ENTITY ram_r IS
	generic (
		PIXEL_WIDTH : integer := 5
	);
	PORT
	(
		address : in std_logic_vector (7 downto 0);
		clock   : in std_logic := '1';
		data    : in std_logic_vector (256 * PIXEL_WIDTH - 1 downto 0);
		wren    : in std_logic;
		q       : out std_logic_vector (256 * PIXEL_WIDTH - 1 downto 0)
	);
END ram_r;


ARCHITECTURE SYN OF ram_r IS

	SIGNAL sub_wire0	: std_logic_vector (256 * PIXEL_WIDTH - 1 downto 0);

BEGIN
	q    <= sub_wire0(256 * PIXEL_WIDTH - 1 downto 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		intended_device_family => "Cyclone IV E",
		lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=R",
		lpm_type => "altsyncram",
		numwords_a => 256,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 8,
		width_a => 256 * PIXEL_WIDTH,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => address,
		clock0 => clock,
		data_a => data,
		wren_a => wren,
		q_a => sub_wire0
	);



END SYN;

