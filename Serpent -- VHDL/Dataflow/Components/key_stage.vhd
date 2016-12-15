-------------------------
-- Universal key stage
--
-- Output of this stage is the same for encryption and decryption
-------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;

use work.tables.all;

entity key_stage is
	generic(clock_delay: time);
	port(
		-- external state to execute this component
		proc_start: in std_logic := '0';
		CLK: in std_logic;
		key_in: in unsigned(127 downto 0);
		subkeys_out: out uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
		proc_complete: out std_logic := '0'
	);
end entity;

architecture k_s of key_stage is
	-- Internal state machine
	signal state: integer := 0;
	component state_counter is
		generic(state_rollover: integer);
		port(CLK: in std_logic := '0'; 
		 	 EN: in std_logic := '0'; 
		 	 state: buffer integer := 0);
	end component;
	
	-- Block control signals
	signal PK_EN, SK_EN: std_logic := '0';

	-- anticipate block 4 to be appended with one X"1"
	signal prekeys: uintArray(0 to 139) := (4 => X"00000001", others => X"00000000");
	
	alias unsigned_to_int is to_integer[unsigned return integer];
begin
	KEYGEN_MAIN: block(proc_start='1')
	begin
		-- State counter
		ST_C: state_counter generic map(133) port map(CLK, proc_start, state);
		PK_EN <= '1' when state=0
			else '0' when state=132;
		
		SK_EN <= '1' when state=132
			else '0' when state=133;
				
		proc_complete <= '1' when state=133;
		
		-- load input key into prekey block	
		-- 1 clock cycle
		prekeys(0) <= key_in(31  downto 0 ) when state=0;
		prekeys(1) <= key_in(63  downto 32) when state=0;
		prekeys(2) <= key_in(95  downto 64) when state=0;
		prekeys(3) <= key_in(127 downto 96) when state=0;
		
		PK_LOAD: block(PK_EN='1')
		begin
			PK_GEN: for i in 8 to 139 generate
				prekeys(i) <= rotate_left(	prekeys(i-8) xor 
											prekeys(i-5) xor 
											prekeys(i-3) xor
											prekeys(i-1) xor
											phi xor
											to_unsigned(state-1,32), 11) when state=i-7;
			end generate;
		end block;
		
		-- 1 clock cycle 
		SK_LOAD: block(SK_EN='1')
		begin
			SK_CURRBOX: for i in 0 to 32 generate
				SK_BITSHIFT: for j in 0 to 31 generate
					SK_BITPLACE: for l in 0 to 3 generate
						subkeys_Out(i, l)(j) <= to_unsigned(Sbox((32+3-i)mod 8, unsigned_to_int(prekeys(8+3+(4*i))(j)&
																								prekeys(8+2+(4*i))(j)&
																								prekeys(8+1+(4*i))(j)&
																								prekeys(8+0+(4*i))(j))), 32)(l) when state=133;
					end generate;
				end generate;
			end generate;
		end block;
	end block;
end architecture;