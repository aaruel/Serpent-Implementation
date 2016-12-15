-- Structural Main
--
-- Serpent Structural implementation
------------------

use work.gl_components.all;
use work.str_components.all;


architecture structural of serpent is

component sKey_s is
	port(proc_start: in std_logic := '0';
		 CLK: in std_logic;
		 key_in: in unsigned(127 downto 0);
		 subkeys_out: out uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
		 proc_complete: out std_logic := '0');
end component;

component linear_transformation_str is
	port(
		proc_start: in std_logic := '0';
		CLK: in std_logic := '0';
		plaintext: in unsigned(127 downto 0) := (others => '0');
		subkeys_in: in uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
		proc_complete: out std_logic := '0';
		encrypted: out unsigned(127 downto 0) := (others => '0')
	);
end component;

component inv_linear_transformation_str is
	port(
		proc_start: in std_logic := '0';
		CLK: in std_logic := '0';
		ciphertext: in unsigned(127 downto 0) := (others => '0');
		subkeys_in: in uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
		proc_complete: out std_logic := '0';
		decrypted: out unsigned(127 downto 0) := (others => '0')
	);
end component;

signal sko: uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
	signal next_state, e_complete, d_complete: std_logic := '0';
	signal e_output, d_output: unsigned(127 downto 0);
begin
	SKM: sKey_s port map('1', CLK, inputtext, sko, next_state);
	LTM: linear_transformation_str port map(next_state, CLK, inputtext, sko, e_complete, e_output);
	ILTM:inv_linear_transformation_str port map(next_state, CLK, inputtext, sko, d_complete, d_output);
	outputtext <= e_output when cryption='1' else d_output;
end architecture;