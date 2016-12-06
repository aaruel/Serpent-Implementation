--
-- Serpent_Decrypt_Behavioral
--

architecture encrypt of serpent is
begin
	process	
	-- registers
	variable eax, ebx: unsigned(31 downto 0) := (X"00000000");
	
	variable extended_key: uintArray(0 to 7) := (others => X"00000000");
	variable prekeys: uintArray(0 to 139) := (others => X"00000000");
	variable subkeys: uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
	variable X, uX: uintArray(0 to 3) := (others => X"00000000"); 
	
	alias unsigned_to_int is to_integer[unsigned return integer];
	begin
		-- execution on rising edge and data_ready
		wait until (CLK'event and CLK='1') and data_ready='1'; 
		-- disallow more data to cross over
		--data_ready <= '0';
		
		-- bit extend 128bit key into 256bits
		extended_key(4) := X"00000001";

		for i in 0 to 127 loop
			assert(key(i) /= 'X') report "KEY NOT INITIALIZED :: keybit = "& integer'image(i)& " is " & std_logic'image(key(i)) severity failure;
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
			eax := to_unsigned((32+3-i) mod 32, eax'length);
			for j in 0 to 31 loop
				ebx(3 downto 0) := prekeys(8+3+(4*i))(j)&prekeys(8+2+(4*i))(j)&prekeys(8+1+(4*i))(j)&prekeys(8+0+(4*i))(j);	
				ebx := to_unsigned(Sbox(to_integer(eax) mod 8, to_integer(ebx)), ebx'length);
				for l in 0 to 3 loop
					subkeys(i, l)(j) := ebx(l);
				end loop;
			end loop;
		end loop;
		-- end key processing
		
		-- plaintext processing
		
		-- split plaintext into 4 words
		for i in 0 to 127 loop
			X(i/32)(i mod 32) := inputtext(i);
		end loop;
		
		-- Linear Transformation - 32 rounds
		
		for i in 0 to 31 loop
			for j in 0 to 3 loop
				uX(j) := X(j) xor subkeys(i, j);
				X(j) := X"00000000";
			end loop;
			-- Sbox input
			for j in 0 to 31 loop
				X(0)(j) := to_unsigned(Sbox(i mod 8, unsigned_to_int(uX(3)(j)&uX(2)(j)&uX(1)(j)&uX(0)(j))), 32)(0);
				X(1)(j) := to_unsigned(Sbox(i mod 8, unsigned_to_int(uX(3)(j)&uX(2)(j)&uX(1)(j)&uX(0)(j))), 32)(1);
				X(2)(j) := to_unsigned(Sbox(i mod 8, unsigned_to_int(uX(3)(j)&uX(2)(j)&uX(1)(j)&uX(0)(j))), 32)(2);
				X(3)(j) := to_unsigned(Sbox(i mod 8, unsigned_to_int(uX(3)(j)&uX(2)(j)&uX(1)(j)&uX(0)(j))), 32)(3);
			end loop;
			if i < 31 then
				X(1) := rotate_left(X(1) xor rotate_left(X(0), 13) xor rotate_left(X(2), 3 ), 1);
	            X(3) := rotate_left(X(3) xor rotate_left(X(2), 3 ) xor (rotate_left(X(0), 13) sll 3), 7);
	            X(0) := rotate_left(rotate_left(X(0), 13) xor X(1) xor X(3), 5);
	            X(2) := rotate_left(rotate_left(X(2), 3 ) xor X(3) xor (X(1) sll 7), 22);
			else
				-- last iteration routine
				X(0) := X(0) xor subkeys(32, 0);
				X(1) := X(1) xor subkeys(32, 1);
				X(2) := X(2) xor subkeys(32, 2);
				X(3) := X(3) xor subkeys(32, 3);
			end if;
		end loop;
		
		-- copy final result into the output
		for i in 0 to 127 loop
			outputtext(i) <= X(i/32)(i mod 32);
		end loop;
	end process;
end architecture encrypt;