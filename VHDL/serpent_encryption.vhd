library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;

use work.tables.all;

entity serpent_encryption is
	-- (possible I/O model)
	---- Modelled after a UART
	-- | START | DATA 0 | DATA 1 | DATA 2 | DATA 3 | DATA 4 | DATA 5 | DATA 6 | DATA 7 | STOP |
	--            LSB             ----------- clock --------->			         MSB
	-- 10 bit chunks, Signal is idling active high, goes low for the start bit	and transmits 8 bits until the high stop bit back to idle
	
	-- the 128 wide input is just for testing!	
	port(plaintext, key: in std_logic_vector(127 downto 0); data_ready: buffer std_logic; CLK: in std_logic; encrypted: out std_logic_vector(127 downto 0));
end entity;

architecture encrypt of serpent_encryption is

function InitialPermutation(input: uintArray(0 to 3)) return uintArray is
variable output: uintArray(0 to 3);
variable replacer: integer;
begin
	-- save end bits
	output(0)(0) := input(0)(0);
	output(3)(31) := input(3)(31);
	for i in 1 to 126 loop
		replacer := ((32*i) mod 127);
		output(i/32)(i mod 32) := input(replacer/32)(replacer mod 32);
	end loop;
	return output;
end InitialPermutation;

function FinalPermutation(input: uintArray(0 to 3)) return uintArray is
variable output: uintArray(0 to 3);
variable replacer: integer;
begin
	-- save end bits
	output(0)(0) := input(0)(0);
	output(3)(31) := input(3)(31);
	for i in 1 to 126 loop
		replacer := ((4*i) mod 127);
		output(i/32)(i mod 32) := input(replacer/32)(replacer mod 32);
	end loop; 
	return output;
end FinalPermutation;

begin
	process	
	-- registers
	variable eax, ebx, ecx: unsigned(31 downto 0);
	
	variable extended_key: uintArray(0 to 7);
	variable prekeys: uintArray(0 to 139);
	variable subkeys: uintArray2d(0 to 32, 0 to 3);
	variable subkeysHat: uintArray2d(0 to 32, 0 to 3);
	variable X: uintArray(0 to 3);
	variable plaintextWordSplit: uintArray(0 to 3);
	variable finalResult: uintArray(0 to 3);  
	variable finalResultFP: uintArray(0 to 3);
	begin
		-- execution on rising edge and data_ready
		wait until (CLK'event and CLK='1') and data_ready='1'; 
		-- disallow more data to cross over
		data_ready <= '0';
		
		-- bit extend 128bit key into 256bits
		extended_key(4)(0) := '1';
		for i in 0 to 127 loop
			extended_key(i/32)(i mod 32) := key(i);
		end loop;
		
		-- generate prekeys	
		-- load extended key into prekey
		prekeys(0 to 7) := extended_key(0 to 7);
		
		for i in 8 to 139 loop
			-- prekey equation
			eax := prekeys(i-8) xor prekeys(i-5) xor prekeys(i-3) xor prekeys(i-1) xor phi xor to_unsigned(i-8, eax'length);
			prekeys(i) := rotate_left(eax, 11);
		end loop;
		eax := X"00000000";
		
		-- Load subkeys
		ebx := X"00000000";
		for i in 0 to 32 loop
			-- SBox selector
			eax := to_unsigned(32+3-i, eax'length);
			for j in 0 to 31 loop
				ebx := resize(prekeys(8+3+(4*i))(j)&prekeys(8+2+(4*i))(j)&prekeys(8+1+(4*i))(j)&prekeys(8+0+(4*i))(j), ebx'length);
				ebx := to_unsigned(Sbox(to_integer(eax), to_integer(ebx)), ebx'length);
				for l in 0 to 3 loop
					subkeys(i, l)(j) := ebx(l);
				end loop;
			end loop;
		end loop;
		
		-- permutate keys
		for i in 0 to 32 loop
			-- save end bits
			subkeysHat(i,0)(0) := subkeys(i,0)(0); 
			subkeysHat(i,3)(31) := subkeys(i,3)(31);
			for j in 1 to 126 loop
				subkeysHat(i, ((j*32)mod 127)/32)(j mod 32) := subkeys(i, ((j*32)mod 127)/32)(((j*32)mod 127) mod 32);
			end loop;
		end loop;
		-- end key processing
		
		-- plaintext processing
		-- Initial permutation
		
		-- split plaintext into 4 words
		for i in 0 to 127 loop
			plaintextWordSplit(i/32)(i mod 32) := plaintext(i);
		end loop;
		finalResult := InitialPermutation(plaintextWordSplit);
		
		-- Linear Transformation - 32 rounds
		
		for i in 0 to 31 loop
			for j in 0 to 3 loop
				X(j) := finalResult(j) xor subkeysHat(i, j);
			end loop;
			-- Sbox input
			for j in 0 to 3 loop
				-- Get 4 bits of data from SBox using 4bits sequentially from X as an SBox selector and append up to 32 bits
				X(j) := (to_unsigned(SBox(i, to_integer(X(j)(31 downto 28))), 4) and X"F") &
						(to_unsigned(SBox(i, to_integer(X(j)(27 downto 24))), 4) and X"F") &
						(to_unsigned(SBox(i, to_integer(X(j)(23 downto 20))), 4) and X"F") &
						(to_unsigned(SBox(i, to_integer(X(j)(19 downto 16))), 4) and X"F") &
						(to_unsigned(SBox(i, to_integer(X(j)(15 downto 12))), 4) and X"F") &
						(to_unsigned(SBox(i, to_integer(X(j)(11 downto 8 ))), 4) and X"F") &
						(to_unsigned(SBox(i, to_integer(X(j)(7  downto 4 ))), 4) and X"F") &
						(to_unsigned(SBox(i, to_integer(X(j)(3  downto 0 ))), 4) and X"F");
			end loop;
			if i < 31 then
				-- first 31 routines
				for a in 0 to 127 loop
					eax := X"00000000";	
					ebx := X"00000000";
					ecx := X"00000000";
					while (LTTable(a, to_integer(eax)) /= MARKER) loop
						-- xor the register bit with final result with LTTable as the bit selector
						ecx := to_unsigned(LTTable(a, to_integer(eax)), ecx'length);
						ebx(0) := ebx(0) xor (finalResult(to_integer(ecx/32))(to_integer(ecx mod 32)));
						eax := eax+1; 
					end loop;
					finalResult(a/32)(a mod 32) := ebx(0);
				end loop; 
			else
				-- last iteration routine
				finalResult(0) := X(0) xor subkeysHat(32, 0);
				finalResult(1) := X(1) xor subkeysHat(32, 1);
				finalResult(2) := X(2) xor subkeysHat(32, 2);
				finalResult(3) := X(3) xor subkeysHat(32, 3);
			end if;
		end loop;
		
		-- assuming pass by copy, might need another variable
		finalResultFP := FinalPermutation(finalResult);
		
		-- copy final result into the output
		for i in 0 to 127 loop
			encrypted(i) <= finalResultFP(i/32)(i mod 32);
		end loop;
	end process;
end architecture encrypt;
