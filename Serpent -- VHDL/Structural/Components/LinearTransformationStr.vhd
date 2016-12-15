-------------------------
-- Linear Transformation
--
-- LT  for encryption
-------------------------	 

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;

use work.tables.all;
use work.gl_components.all;
use work.str_components.all;

entity linear_transformation_str is
	port(
		proc_start: in std_logic := '0';
		CLK: in std_logic := '0';
		plaintext: in unsigned(127 downto 0) := (others => '0');
		subkeys_in: in uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
		proc_complete: out std_logic := '0';
		encrypted: out unsigned(127 downto 0) := (others => '0')
	);
end entity;

architecture l_t of linear_transformation_str is
	-- Internal state machine
	signal state: std_logic_vector(0 to 255);
	signal cout: std_logic_vector(7 downto 0);
	
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
	LT_MAIN: block(proc_start='1')
	begin
		-- State counter
		SC: str_scounter generic map(8) port map(CLK, proc_start, '1', cout);
		D8: decoder_8 port map(cout, state);
		
		-- register
		R0: n_register generic map (32) port map (D(0), CLK, RG_EN, X(0));
		R1: n_register generic map (32) port map (D(1), CLK, RG_EN, X(1));
		R2: n_register generic map (32) port map (D(2), CLK, RG_EN, X(2));
		R3: n_register generic map (32) port map (D(3), CLK, RG_EN, X(3));
		
		-- 1 clock cycle
		PT0: n_tristate port map (plaintext(31  downto 0 ), state(1), D(0));
		PT1: n_tristate port map (plaintext(63  downto 32), state(1), D(1));
		PT2: n_tristate port map (plaintext(95  downto 64), state(1), D(2));
		PT3: n_tristate port map (plaintext(127 downto 96), state(1), D(3)); 
		
		-- 125 clock cycles total
		LT_FIRSTROUNDS: block
			signal initxorvalues, sboxvalues: uintArray2d(3 downto 0, 30 downto 0);
			signal LTvalues: uintArray2d(15 downto 0, 30 downto 0);
			
		begin
			LT_G: for i in 0 to 30 generate
				-- enable when state counter == 
				XLT0: xor_array port map (X(0), subkeys_in(i,0), initxorvalues(0, i));
				XLT1: xor_array port map (X(1), subkeys_in(i,1), initxorvalues(1, i));
				XLT2: xor_array port map (X(2), subkeys_in(i,2), initxorvalues(2, i));
				XLT3: xor_array port map (X(3), subkeys_in(i,3), initxorvalues(3, i));
				
				TLT0: n_tristate port map(initxorvalues(0, i), state((i*4)+2), D(0));
				TLT1: n_tristate port map(initxorvalues(1, i), state((i*4)+2), D(1));
				TLT2: n_tristate port map(initxorvalues(2, i), state((i*4)+2), D(2));
				TLT3: n_tristate port map(initxorvalues(3, i), state((i*4)+2), D(3));
				
				LT_SBOX: for j in 0 to 31 generate
					-- using the previous output as a selector for the Sbox LUT
					sboxvalues(0, i)(j) <= to_unsigned(Sbox(i mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(0);
					sboxvalues(1, i)(j) <= to_unsigned(Sbox(i mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(1);
					sboxvalues(2, i)(j) <= to_unsigned(Sbox(i mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(2);
					sboxvalues(3, i)(j) <= to_unsigned(Sbox(i mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(3);
					
					TLT4: onebit_tristate port map(sboxvalues(0,i)(j), state((i*4)+3), D(0)(j));
					TLT5: onebit_tristate port map(sboxvalues(1,i)(j), state((i*4)+3), D(1)(j));
					TLT6: onebit_tristate port map(sboxvalues(2,i)(j), state((i*4)+3), D(2)(j));
					TLT7: onebit_tristate port map(sboxvalues(3,i)(j), state((i*4)+3), D(3)(j));
				end generate;
				-- Linear transformation equation broken up
				LTvalues(0, i) <= X(0)(18 downto 0)&X(0)(31 downto 19); --X0
				LTvalues(1, i) <= X(2)(28 downto 0)&X(2)(31 downto 29); --X2
				LTvalues(2, i) <= LTvalues (0,i)(28 downto 0)&"000";
				
				XLT4: xor_array port map(LTvalues(0, i), LTvalues(1,i), LTvalues(3,i));
				XLT5: xor_array port map(X(1), LTvalues(3,i), LTvalues(4, i)); --X1
				XLT6: xor_array port map(X(3), LTvalues(1, i), LTvalues(5, i));
				XLT7: xor_array port map(LTvalues(2,i), LTvalues(5, i), LTvalues(6, i)); --X3
				
				TLT8: n_tristate port map(LTvalues(0, i), state((i*4)+4), D(0));
				TLT9: n_tristate port map(LTvalues(4, i), state((i*4)+4), D(1));
				TLTA: n_tristate port map(LTvalues(1, i), state((i*4)+4), D(2));
				TLTB: n_tristate port map(LTvalues(6, i), state((i*4)+4), D(3));
				
				----------------------------
				
				LTvalues(7, i) <= X(1)(30 downto 0)&X(1)(31); --X1
				LTvalues(8, i) <= X(3)(24 downto 0)&X(3)(31 downto 25); --X3
				LTvalues(9, i) <= LTvalues(7,i)(24 downto 0)&"0000000";
				
				XLT8: xor_array port map(X(0), LTvalues(7,i), LTvalues(10, i));
				XLT9: xor_array port map(LTvalues(10,i), LTvalues(8,i), LTvalues(11, i));
				XLTA: xor_array port map(X(2), LTvalues(8,i), LTvalues(12, i));
				XLTB: xor_array port map(LTvalues(12,i), LTvalues(9,i), LTvalues(13, i));
				
				LTvalues(14,i) <= LTvalues(11,i)(26 downto 0)&LTvalues(11,i)(31 downto 27); --X0
				LTvalues(15,i) <= LTvalues(13,i)(9 downto 0)&LTvalues(13,i)(31 downto 10); --X2
				
				TLT00 : n_tristate port map(LTvalues(14,i), state((i*4)+5), D(0));
				TLT01 : n_tristate port map(LTvalues(7, i), state((i*4)+5), D(1));
				TLT02 : n_tristate port map(LTvalues(15,i), state((i*4)+5), D(2));
				TLT03 : n_tristate port map(LTvalues(8, i), state((i*4)+5), D(3));
				
			end generate;
		end block;
		
		-- 3 clock cycles
		LT_LASTROUND: block
			signal initxorvalues, sboxvalues, final: uintArray(3 downto 0);
		begin
			-- enable when state counter == 
			XLT10: xor_array port map (X(0), subkeys_in(31,0), initxorvalues(0));
			XLT11: xor_array port map (X(1), subkeys_in(31,1), initxorvalues(1));
			XLT12: xor_array port map (X(2), subkeys_in(31,2), initxorvalues(2));
			XLT13: xor_array port map (X(3), subkeys_in(31,3), initxorvalues(3));
			
			TLT10: n_tristate port map(initxorvalues(0), state(126), D(0));
			TLT11: n_tristate port map(initxorvalues(1), state(126), D(1));
			TLT12: n_tristate port map(initxorvalues(2), state(126), D(2));
			TLT13: n_tristate port map(initxorvalues(3), state(126), D(3));
			
			LT_SBOX: for j in 0 to 31 generate
				-- using the previous output as a selector for the Sbox LUT
				sboxvalues(0)(j) <= to_unsigned(Sbox(31 mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(0);
				sboxvalues(1)(j) <= to_unsigned(Sbox(31 mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(1);
				sboxvalues(2)(j) <= to_unsigned(Sbox(31 mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(2);
				sboxvalues(3)(j) <= to_unsigned(Sbox(31 mod 8, unsigned_to_int(X(3)(j)&X(2)(j)&X(1)(j)&X(0)(j))), 32)(3);
				
				TLT14: onebit_tristate port map(sboxvalues(0)(j), state(127), D(0)(j));
				TLT15: onebit_tristate port map(sboxvalues(1)(j), state(127), D(1)(j));
				TLT16: onebit_tristate port map(sboxvalues(2)(j), state(127), D(2)(j));
				TLT17: onebit_tristate port map(sboxvalues(3)(j), state(127), D(3)(j));
			end generate;
			XLT110: xor_array port map (X(0), subkeys_in(32,0), final(0));
			XLT111: xor_array port map (X(1), subkeys_in(32,1), final(1));
			XLT112: xor_array port map (X(2), subkeys_in(32,2), final(2));
			XLT113: xor_array port map (X(3), subkeys_in(32,3), final(3));
			
			TLT_0: n_tristate port map(final(0), state(128), encrypted(31  downto 0 ));
			TLT_1: n_tristate port map(final(1), state(128), encrypted(63  downto 32));
			TLT_2: n_tristate port map(final(2), state(128), encrypted(95  downto 64));
			TLT_3: n_tristate port map(final(3), state(128), encrypted(127 downto 96));
		end block;
		proc_complete <= '1' when state(128)='1';
	end block;
end architecture;
