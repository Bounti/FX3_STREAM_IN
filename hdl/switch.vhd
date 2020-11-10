library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity switch is
	port(
                aclk                   : in std_logic;
                aresetn                : in std_logic;

                data_0                 : in std_logic_vector(31 downto 0)
                addr_0                 : in std_logic_vector(31 downto 0)
                write_enable_0         : in std_logic;

                data_1                 : in std_logic_vector(31 downto 0);
                addr_1                 : in std_logic_vector(31 downto 0);
                write_enable_1         : in std_logic;

                data_out               : out std_logic_vector(63 downto 0);
                write_enable           : out std_logic;
);
end entity switch;

architecture switch_arch of switch is

signal in_0                        : std_logic_vector(63 downto 0);
signal in_1                        : std_logic_vector(63 downto 0);

begin --architecture begining

in_0 <= data_0&addr_0;
in_1 <= data_1&addr_1;

data_out     <= in_0 when write_enable_0 else in_1;
write_enable <= write_enablei_0 or write_enable_1;

end architecture;
 
