library IEEE;
use IEEE.std_logic_1164.all;

use work.tables.all;

entity and2 is
	generic(tpd: time := g_tpd);
	port(A,B: in std_logic; F: out std_logic := 'U');
end entity and2;

architecture arch of and2 is
begin
	process
	begin
		wait on A,B;
		if A='1' and B='1' then
			F<='1' after tpd;
		elsif A='Z' or A='W' or A='L' or A='H' or A='-' then
			F<='X' after tpd;
		elsif B='Z' or B='W' or B='L' or B='H' or B='-' then
			F<='X' after tpd;
		else  
			F<='0' after tpd;
		end if;
	end process;
end arch;