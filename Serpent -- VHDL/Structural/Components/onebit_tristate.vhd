library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity onebit_tristate is
	port(iput: in std_logic;
		 eble: in std_logic;
		 oput:out std_logic);
end entity;

architecture ts of onebit_tristate is
begin
	oput <= iput when eble='1' else 'Z';
end architecture;