library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity n_tristate is
	port(iput: in unsigned;
		 eble: in std_logic;
		 oput:out unsigned);
end entity;

architecture ts of n_tristate is
begin
	TS0: for i in iput'length-1 downto 0 generate
		oput(oput'low+i) <= iput(iput'low+i) when eble='1' else 'Z';
	end generate;
end architecture;