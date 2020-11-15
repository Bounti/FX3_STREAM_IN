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

entity gpif is
  port(
        aclk                   : in std_logic;
        aresetn                : in std_logic;
        clk_out                : out std_logic;
        data                   : inout std_logic_vector(31 downto 0);
        fx3_data_available     : out std_logic;
        fx3_resetn             : in std_logic;
        fx3_read_ready         : in std_logic;
        led                    : out std_logic_vector(7 downto 0);
        overflow               : in std_logic;

        fifo_read              : out std_logic;
        fifo_prog_empty        : in std_logic;
        fifo_out               : in std_logic_vector(31 downto 0)
      );
end entity gpif;

architecture gpif_arch of gpif is

  component P_ODDR2 is
    port (
           aclk       : in std_logic;
           clk_out    : out std_logic;
           aresetn    : in std_logic
         );
  end component;

--stream IN fsm
  type states is (idle, write);
  signal current_state, next_state : states;

  signal word_counter         : natural range 0 to 4095;

  signal fx3_read_ready_d     : std_logic;
  signal status               : std_logic_vector(4 downto 0);
  signal fx3_resetn_d         : std_logic;
  signal fifo_read_d          : std_logic;

begin --architecture begining


  ODDR2_inst: P_ODDR2
  port map(
            aclk      => aclk,
            clk_out   => clk_out,
            aresetn   => aresetn
          );

process(aclk, aresetn)begin
  if(aresetn = '0')then
    fx3_resetn_d <= '0';
  elsif(aclk'event and aclk = '1')then
    fx3_resetn_d <= fx3_resetn;
  end if;
end process;

process(aclk, fx3_resetn_d)begin
  if(fx3_resetn_d = '0')then
    word_counter <= 0;
  elsif(aclk'event and aclk = '1')then
    if(current_state = write)then
      word_counter <= word_counter + 1;
    else 
      word_counter <= 0;
    end if;
  end if;
end process;

process(fx3_resetn_d, fifo_prog_empty, fifo_out)begin
  if(fx3_resetn_d = '0')then
    data               <= (others => '0');
    fx3_data_available <= '0';
  else
    data               <= fifo_out;
    fx3_data_available <= (not fifo_prog_empty);
  end if;
end process;

--flopping the INPUTs flags
process(aclk, aresetn)begin
  if(aresetn = '0')then
    fx3_read_ready_d <= '0';
  elsif(aclk'event and aclk = '1')then
    fx3_read_ready_d <= fx3_read_ready;
  end if;
end process;

--streamIN mode state machine
stream_in_fsm_f : process(aclk, fx3_resetn_d)begin
  if(fx3_resetn_d = '0')then 
    current_state <= idle;
    --fifo_read     <= '0';
  elsif(aclk'event and aclk = '1')then 
    --fifo_read     <= fifo_read_d;
    current_state <= next_state;
  end if;	
end process;

fifo_read <= '1' when (current_state = write) else '0';

--StreamIN mode state machine combo
stream_in_fsm : process(current_state, fx3_read_ready_d, word_counter)begin
  next_state <= current_state;
  case current_state is
    when idle => 
      status <= "10000";
      if(fx3_read_ready_d = '1' and word_counter = 0) then
        next_state  <= write;
        fifo_read_d <= '1';
      else
        next_state <= idle;
        fifo_read_d <= '0';
      end if;

    when write =>
      status <= "11011";
      if(word_counter = 4095) then
        next_state <= idle;
        fifo_read_d <= '0';
      else
        fifo_read_d <= '1';
        next_state <= write;
      end if;

    when others =>
      status <= "00000";
      next_state <= idle;
      fifo_read_d <= '0';
  end case;
end process;

led(0) <=  fx3_read_ready_d;
led(1) <=  fx3_resetn_d;
led(2) <=  overflow;
led(7 downto 3) <= status;

end architecture;

