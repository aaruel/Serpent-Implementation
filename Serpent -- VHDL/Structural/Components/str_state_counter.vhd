library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.gl_components.all;

entity str_scounter is
	generic(bits: integer);
	port(CLK: in std_logic := '0'; 
		 start: in std_logic := '0';
		 reset: in std_logic := '1';
		 state: buffer std_logic_vector);
end entity;

architecture sc of str_scounter is
	signal iin: std_logic_vector(bits-1 downto 0);
begin
	iin(0) <= '1';
	SC0: tff2 port map(iin(0), CLK, '1', reset, state(0), open);
	SC: for i in 1 to bits-1 generate
		ASC: and2 port map(iin(i-1), state(i-1), iin(i));
		SC1: tff2 port map(iin(i), CLK, start, reset, state(i), open);
	end generate;
end architecture;