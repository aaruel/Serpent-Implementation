library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.tables.all;
use work.gl_components.all;
use work.str_components.all;

entity sKey_s is
	port(proc_start: in std_logic := '0';
		 CLK: in std_logic;
		 key_in: in unsigned(127 downto 0);
		 subkeys_out: out uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
		 proc_complete: out std_logic := '0');
end entity;


architecture s_Ks of sKey_s is
	signal ouut: std_logic_vector(7 downto 0);
	signal dout: std_logic_vector(0 to 255);

   	-- the appended 1 is a constant bit in block 4 bit 0
	signal prekeys: uintArray(0 to 139) := (4 => X"00000001", others => X"00000000");
	
	alias unsigned_to_int is to_integer[unsigned return integer];
begin
	-- The proc_complete signal should act as an asynchronous interrupt signal
	-- On a key change, execution halts to wait for the final subkey generation
	
	-- one successful key generation out of 33 is (tpd * `12)
	proc_complete <= '1' after g_tpd*12*34 when proc_start='1' else '0';
	
	STRUCT_KEYGEN: block(proc_start='1')
	begin
--		SC: str_scounter generic map(8) port map(CLK, proc_start, '1', ouut);
--		D8: decoder_8 port map(ouut, dout);
		
		prekeys(0) <= key_in(31  downto 0 );
		prekeys(1) <= key_in(63  downto 32);
		prekeys(2) <= key_in(95  downto 64);
		prekeys(3) <= key_in(127 downto 96);
		
		PK_OP: block
			signal xstage: uintArray2d(0 to 4, 0 to 131);	
		begin
			PKG: for i in 8 to 139 generate	 
				-- somewhat heavy on hardware, but fast and reliable
				PKXOR0: xor_array port map(prekeys(i-8), prekeys(i-5), xstage(0, i-8));
				PKXOR1: xor_array port map(xstage(0, i-8), prekeys(i-3), xstage(1, i-8));
				PKXOR2: xor_array port map(xstage(1, i-8), prekeys(i-1), xstage(2, i-8));
				PKXOR3: xor_array port map(xstage(2, i-8), phi, xstage(3, i-8));
				PKXOR4: xor_array port map(xstage(3, i-8), to_unsigned(i-8, 32), xstage(4, i-8));
				
				-- 11 bit rotate though rearranging wires
				prekeys(i) <= xstage(4, i-8)(20 downto 0)&xstage(4, i-8)(31 downto 21);
			end generate;
		end block;
		
		-- SBox is a LUT using 4 prekey bits as input, output onto subkeys_Out
		SK_CURRBOX: for i in 0 to 32 generate
			SK_BITSHIFT: for j in 0 to 31 generate
				SK_BITPLACE: for l in 0 to 3 generate
					subkeys_Out(i, l)(j) <= to_unsigned(Sbox((32+3-i)mod 8, unsigned_to_int(prekeys(8+3+(4*i))(j)&
																							prekeys(8+2+(4*i))(j)&
																							prekeys(8+1+(4*i))(j)&
																							prekeys(8+0+(4*i))(j))), 32)(l);
				end generate;
			end generate;
		end generate;
	end block;
end architecture;