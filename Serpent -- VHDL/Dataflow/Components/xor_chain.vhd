library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.tables.all;
use work.gl_components.all;
use work.str_components.all;

entity xor_array is
	port(a: in unsigned;
		 b: in unsigned;
		 x: out unsigned);
end entity;

architecture xa of xor_array is
begin
	X_A: for i in a'range generate
		Xo: xor2 port map(a(i), b(i), x(i));
	end generate;
end architecture;