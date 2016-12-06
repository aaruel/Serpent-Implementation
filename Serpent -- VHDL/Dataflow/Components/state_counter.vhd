library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity state_counter is
	generic(state_rollover: integer);
	port(CLK: in std_logic := '0'; 
		 EN: in std_logic := '0'; 
		 state: buffer integer := 0);
end entity;		 

architecture ste of state_counter is
begin
	process
	begin
		wait until (rising_edge(clk) and EN='1');
		if (state /= state_rollover) then
			state <= state + 1;	
		else
			state <= 0;
		end if;
	end process;
end architecture;
