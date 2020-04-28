library IEEE;
use IEEE.std_logic_1164.all;

use work.tables.all;

entity xor2 is
	generic(tpd:time := g_tpd);
	port(A,B: in std_logic; F: out std_logic := 'U');
end entity xor2;

architecture arch of xor2 is
begin
	process(A,B)
	begin
		--wait on A,B;
		if (A=B) then
			F<='0' after tpd;
		else	
			F<='1' after tpd;
		end if;
	end process;
end arch;