library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

use work.tables.all;

package gl_components is
	component tff2 is
		generic(tsu: time:=g_tsu; 
				th: time:=g_th; 
				tplh: time:=g_tplh; 
				tphl: time:=g_tphl; 
				tpd: time:=g_tpd);
		port(T, CLK, PRE, CLR: in std_logic; Q,Qnot: buffer std_logic:='0');
	end component tff2;
	
	component xor2 is
		generic(tpd:time := g_tpd);
		port(A,B: in std_logic; F: out std_logic := 'U');
	end component xor2;
	
	component and2 is
		generic(tpd: time := g_tpd);
		port(A,B: in std_logic; F: out std_logic := 'U');
	end component and2;
end package;