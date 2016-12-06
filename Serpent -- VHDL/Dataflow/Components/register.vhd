library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity n_register is
	generic(size: integer);
	port(d: in unsigned;
		 CLK: in std_logic; 
		 EN: in std_logic;
		 q: out unsigned);
end entity;

architecture reg of n_register is
begin		 
	R: for i in 0 to size-1 generate
		q(i) <= d(i) when rising_edge(CLK) and EN='1';
	end generate;
end architecture; 