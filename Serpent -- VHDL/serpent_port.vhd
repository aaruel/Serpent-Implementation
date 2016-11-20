-------------------------------------------------------------------------------
--
-- Title       : Serpent Symmetric Key Block Cipher
--
-- Description : AES encryption finalist VHDL implementation
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;

use work.tables.all;

entity serpent is
	port(inputtext, key: in std_logic_vector(127 downto 0) := (others=>'0'); 
	data_ready: in std_logic := '0'; 
	CLK: in std_logic := '0'; 
	outputtext: out std_logic_vector(127 downto 0) := (others=>'0'));
end entity;