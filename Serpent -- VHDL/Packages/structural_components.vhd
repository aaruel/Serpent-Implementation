library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

package str_components is
	component str_scounter is
		generic(bits: integer);
		port(CLK: in std_logic := '0'; 
			 start: in std_logic := '0';
			 reset: in std_logic := '1';
			 state: buffer std_logic_vector);
	end component;
	
	component decoder_8 is
		port(iin: in std_logic_vector(7 downto 0);
			 ouut: out std_logic_vector(0 to 255));
	end component;
	
	component xor_array is
		port(a: in unsigned;
			 b: in unsigned;
			 x: out unsigned);
	end component;
	
	component n_tristate is
		port(iput: in unsigned;
			 eble: in std_logic;
			 oput:out unsigned);
	end component;
	
	component onebit_tristate is
		port(iput: in std_logic;
			 eble: in std_logic;
			 oput:out std_logic);
	end component;
	
	
	--- Deprecated CLB components
	component tsw_clb is
		generic(t_d: time);
		port(EN: in std_logic;
			 i1: in std_logic;
			 i2: in std_logic;
			 o1: out std_logic;
			 o2: out std_logic;
			 output: out unsigned);
	end component;
	
	component n_xor is
		generic(t_d: time);
		port(EN: in std_logic;
			 input1, input2: in unsigned;
			 output: out unsigned);
	end component; 
	
	component state_counter_clb is
		generic(t_su:time := 0.5ns; t_h:time := 0.5ns; t_d:time:=1ns; states:integer);
		port(CLK: in std_logic := '0'; 
			 start: in std_logic := '0';
			 EN: in std_logic := '0';
			 reset: in std_logic := '1';
			 state: buffer std_logic_vector);
	end component;
	
	component tff_clb is
		generic(t_su: time := 0.5ns; t_h: time := 0.5ns; t_d: time := 1ns);
		port(
			CLK: in std_logic;
			EN: in std_logic;
			T: in unsigned;
			Q: buffer std_logic := '0'
		);
	end component;
	---------------------
end package;