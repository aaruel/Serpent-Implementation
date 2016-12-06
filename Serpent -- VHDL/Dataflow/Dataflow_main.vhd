architecture dataflow_main of serpent is

	component key_stage is
		generic(clock_delay: time);
		port(
			proc_start: in std_logic := '0';
			CLK: in std_logic;
			key_in: in unsigned(127 downto 0);
			subkeys_out: out uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
			proc_complete: out std_logic := '0'
		);
	end component;

	component linear_transformation is
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
	end component;
	
	component inverse_linear_transformation is
		generic(clock_delay: time);
		port(
			proc_start: in std_logic := '0';
			CLK: in std_logic := '0';
			cryption: in std_logic;
			ciphertext: in unsigned(127 downto 0) := (others => '0');
			subkeys_in: in uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
			proc_complete: out std_logic := '0';
			decrypted: out unsigned(127 downto 0) := (others => '0')
		);
	end component;
	
	signal key_gen: std_logic := '1';
	signal next_state, e_complete, d_complete: std_logic := '0';
	signal sk_o: uintArray2d(0 to 32, 0 to 3) := (others => (others => X"00000000"));
	signal e_outputtext, d_outputtext: unsigned(127 downto 0) := (others=>'0');
	
	-- convenience
	constant clk_dly: time := 4ns;
begin
	-- 250 MHz
	KSE: key_stage generic map (clk_dly) port map (key_gen, CLK, key, sk_o, next_state);
	key_gen <= '0' when next_state='1';
	LT:  linear_transformation generic map (clk_dly) port map (next_state, CLK, cryption, inputtext, sk_o, e_complete, e_outputtext);
	ILT: inverse_linear_transformation generic map (clk_dly) port map (next_state, CLK, cryption, inputtext, sk_o, d_complete, d_outputtext);
	outputtext <= e_outputtext when cryption='0' else d_outputtext;
end architecture;