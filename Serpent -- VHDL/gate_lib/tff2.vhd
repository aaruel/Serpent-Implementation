library IEEE;
use IEEE.std_logic_1164.all;

use work.tables.all;

entity tff2 is
	generic(tsu: time:=g_tsu; 
			th: time:=g_th; 
			tplh: time:=g_tplh; 
			tphl: time:=g_tphl; 
			tpd: time:=g_tpd);
	port(T, CLK, PRE, CLR: in std_logic; Q,Qnot: inout std_logic:='0');
end entity tff2;

architecture tff of tff2 is
begin
	process
	begin
		wait on CLK, CLR, PRE;
		if clr='0' and PRE='1' then
			Q <= '0' after tpd;
			Qnot <= '1' after tpd;
		elsif CLR='1' and PRE='0' then
			Q <= '1' after tpd;
			Qnot <= '0' after tpd;
		elsif (PRE='1' and CLR='1') then
			if CLK'event and CLK='1' and CLR='1' then
				if T'stable(tsu) then
					wait for th;
					if T'delayed'stable(th) then
						if T='0' then
							Q <= Q after tpd;
							Qnot <= Qnot after tpd;
						elsif T='1' then
							if Q='0' then
								Q <= '1' after tplh-th;
								Qnot <= '0' after tphl-th;
							elsif Q='1' then
								Q <= '0' after tphl-th;
								Qnot <= '1' after tplh-th;
							end if;
						end if;
					else
						report "TH violation";
						Q <= 'X' after tpd;
						Qnot <= 'X' after tpd;
					end if;
				else
					report "TSU violation";
					Q <= 'X' after tpd;
					Qnot <= 'X' after tpd;
				end if;
			end if;
		end if;
	end process;
end architecture;