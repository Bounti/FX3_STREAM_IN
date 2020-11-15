------------------------------------------------------------------------
--
--        gpif.vhd
--
--        Copyright (C) 2018 Nassim Corteggiani
--
--        This file is part of DMon project.
--
--        DMon is free software: you can redistribute it and/or
--        modify it under the terms of the GNU General Public License as
--        published by the Free Software Foundation, either version 3 of the
--        License, or (at your option) any later version.
--
--        This program is distributed in the hope that it will be useful,
--        but WITHOUT ANY WARRANTY; without even the implied warranty of
--        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--        GNU General Public License for more details.
--
--        You should have received a copy of the GNU General Public License
--        along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--        Email: n.corteggiani@gmail.com
------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity producer is
  port(
        aclk                   : in std_logic;
        aresetn                : in std_logic;

        fifo_write              : out std_logic;
        fifo_almost_full       : in std_logic;
        fifo_in                : out std_logic_vector(63 downto 0)
      );
end entity producer;

architecture producer_arch of producer is

--  signal counter              : std_logic_vector(31 downto 0);
  signal counter              : natural range 0 to 102400;

begin --architecture begining

process(aclk, aresetn, fifo_almost_full)begin
  if(aresetn = '0')then
    --counter <= (others => '0');
    counter <= 0;
    fifo_write <= '0';
  elsif(aclk'event and aclk = '1')then
    if(fifo_almost_full = '0') then
      counter <= counter + 1;
      fifo_write <= '1';
    else
      fifo_write <= '0';
    end if;
  end if;
end process;

fifo_in <= std_logic_vector(to_unsigned(counter,32))&std_logic_vector(to_unsigned(counter,32));

end architecture;


