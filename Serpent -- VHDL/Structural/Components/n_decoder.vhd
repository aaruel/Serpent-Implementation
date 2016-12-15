library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity decoder_8 is
	port(iin: in std_logic_vector(7 downto 0);
		 ouut: out std_logic_vector(0 to 255));
end entity;

architecture nd of decoder_8 is
	signal internal: std_logic_vector(0 to 255);
begin
	-- vhdl doesn't allow variable aggregate assignments
	--ouut <= (to_integer(unsigned(iin))=>'1', others=>'0');
	ouut <= inertial internal after 1ns;
	process(iin)
	begin
		for i in ouut'range loop
			if i=to_integer(unsigned(iin)) then
				internal(i) <= '1'; 
			else
				internal(i) <= '0';
			end if;
		end loop;
	end process;
end architecture;