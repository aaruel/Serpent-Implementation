-------------------------
-- Linear Transformation
--
-- LT  for encryption
-------------------------	 

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;

use work.tables.all;

entity linear_transformation is
	generic(clock_delay: time);
	port(
		proc_start: in std_logic := '0';
		CLK: in std_logic := '0';
		cryption: in std_logic;
		plaintext: in unsigned(127 downto 0) := (others => '0');
		subkeys_in: in uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
		proc_complete: out std_logic := '0';
		encrypted: out unsigned(127 downto 0) := (others => '0')
	);
end entity;

architecture l_t of linear_transformation is
	-- Internal state machine
	signal state: integer := 0;
	
	component state_counter is
		generic(state_rollover: integer);
		port(CLK: in std_logic := '0'; 
		 	 EN: in std_logic := '0'; 
		 	 state: buffer integer := 0);
	end component;
	
	component n_register is
		generic(size: integer);
		port(d: in unsigned;
			 CLK: in std_logic;
			 EN: in std_logic;
			 q: out unsigned);
	end component;
	
	-- Block enable signals
	signal LT_EN: std_logic := '0';
	signal RG_EN: std_logic := '1';
	
	-- Registers
	--signal X: uintArray2d(0 to 32, 0 to 11) := (others => (others => X"00000000"));
	signal X, D: uintArray(0 to 3) := (others => X"00000000");
	--signal i: integer := 0;
	alias unsigned_to_int is to_integer[unsigned return integer];
begin
	LT_MAIN: block(proc_start='1' and cryption='0')
	begin
		-- State counter
		ST_C_LT: state_counter generic map(96) port map(CLK, proc_start, state);
		
		-- register
		R0: n_register generic map (32) port map (D(0), CLK, RG_EN, X(0));
		R1: n_register generic map (32) port map (D(1), CLK, RG_EN, X(1));
		R2: n_register generic map (32) port map (D(2), CLK, RG_EN, X(2));
		R3: n_register generic map (32) port map (D(3), CLK, RG_EN, X(3));
		
		-- 1 clock cycle
		D(0) <= plaintext(31  downto 0 ) when state=0 else (others => 'Z');
		D(1) <= plaintext(63  downto 32) when state=0 else (others => 'Z');
		D(2) <= plaintext(95  downto 64) when state=0 else (others => 'Z');
		D(3) <= plaintext(127 downto 96) when state=0 else (others => 'Z');
		LT_EN <= '1' when state=0;
		
		-- 93 clock cycles total
		LT_FIRSTROUNDS: block(LT_EN='1')
		begin
			LT_G: for i in 0 to 30 generate
				D(0) <= X(0) xor subkeys_in(i, 0) when (state-1)=(i*3)+0 else (others => 'Z');
				D(1) <= X(1) xor subkeys_in(i, 1) when (state-1)=(i*3)+0 else (others => 'Z');
				D(2) <= X(2) xor subkeys_in(i, 2) when (state-1)=(i*3)+0 else (others => 'Z');
				D(3) <= X(3) xor subkeys_in(i, 3) when (state-1)=(i*3)+0 else (others => 'Z');
				LT_SBOX: for j in 0 to 31 generate
					D(0)(j) <= to_unsigned(Sbox(i mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(0) when (state-1)=(i*3)+1 else 'Z';
					D(1)(j) <= to_unsigned(Sbox(i mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(1) when (state-1)=(i*3)+1 else 'Z';
					D(2)(j) <= to_unsigned(Sbox(i mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(2) when (state-1)=(i*3)+1 else 'Z';
					D(3)(j) <= to_unsigned(Sbox(i mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(3) when (state-1)=(i*3)+1 else 'Z';
				end generate;
				D(1) <= rotate_left(X(1) xor rotate_left(X(0), 13) xor rotate_left(X(2), 3), 1) when (state-1)=(i*3)+2 else (others => 'Z');
				D(3) <= rotate_left(X(3) xor rotate_left(X(2),  3) xor (rotate_left(X(0), 13) sll 3), 7) when (state-1)=(i*3)+2 else (others => 'Z');
				D(0) <= rotate_left(rotate_left(X(0), 13) xor rotate_left(X(1) xor rotate_left(X(0), 13) xor rotate_left(X(2), 3), 1) xor rotate_left(X(3) xor rotate_left(X(2),  3) xor (rotate_left(X(0), 13) sll 3), 7), 5) when (state-1)=(i*3)+2 else (others => 'Z');
				D(2) <= rotate_left(rotate_left(X(2), 3 ) xor rotate_left(X(3) xor rotate_left(X(2),  3) xor (rotate_left(X(0), 13) sll 3), 7) xor (rotate_left(X(1) xor rotate_left(X(0), 13) xor rotate_left(X(2), 3), 1) sll 7), 22) when (state-1)=(i*3)+2 else (others => 'Z');
			end generate;
		end block;
		
		-- 3 clock cycles
		LT_LASTROUND: block(LT_EN='1')
		begin
			D(0) <= X(0) xor subkeys_in(31, 0) when (state)=94 else (others => 'Z');
			D(1) <= X(1) xor subkeys_in(31, 1) when (state)=94 else (others => 'Z');
			D(2) <= X(2) xor subkeys_in(31, 2) when (state)=94 else (others => 'Z');
			D(3) <= X(3) xor subkeys_in(31, 3) when (state)=94 else (others => 'Z');
			LT_SBOX: for j in 0 to 31 generate
				D(0)(j) <= to_unsigned(Sbox(31 mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(0) when state=95 else 'Z';
				D(1)(j) <= to_unsigned(Sbox(31 mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(1) when state=95 else 'Z';
				D(2)(j) <= to_unsigned(Sbox(31 mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(2) when state=95 else 'Z';
				D(3)(j) <= to_unsigned(Sbox(31 mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(3) when state=95 else 'Z';
			end generate;
			encrypted(31  downto 0 ) <= X(0) xor subkeys_in(32, 0) when state=96 else (others => 'Z');
			encrypted(63  downto 32) <= X(1) xor subkeys_in(32, 1) when state=96 else (others => 'Z');
			encrypted(95  downto 64) <= X(2) xor subkeys_in(32, 2) when state=96 else (others => 'Z');
			encrypted(127 downto 96) <= X(3) xor subkeys_in(32, 3) when state=96 else (others => 'Z');
		end block;
		proc_complete <= '1' when state=96;
	end block;
end architecture;
