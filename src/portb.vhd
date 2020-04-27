library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity port_b is
-- IO port b
  port (
-- DATA AND CONTROL
    PHI2       : in  std_logic; -- clock 1MHz
    DI         : in  std_logic_vector(7 downto 0);
    DO         : out std_logic_vector(7 downto 0);
    RS         : in  std_logic_vector(3 downto 0); -- register select
    RES_N      : in  std_logic; -- global reset
    Rd         : in  std_logic; -- read and write registers
-- I/O
    PB         : inout std_logic_vector(7 downto 0);
    TMRA_PB_IN : in std_logic; -- from TMRA to PB6 if TMRA_PB_ON = '1'
    TMRB_PB_IN : in std_logic; -- from TMRB to PB7 if TMRB_PB_ON = '1'
    TMRA_PB_ON : in std_logic; -- puts TMRA_OUT on PB, overrides bit in DDRB.
    TMRB_PB_ON : in std_logic; -- puts TMRB_OUT on PB, overrides bit in DDRB.
    PC_N       : out std_logic -- Goes low for one clock cycle following
                                   -- a read or write of PORT B.
   );
end entity port_b;

architecture rtlb of port_b is
-- REGISTERS 
  signal PRB : std_logic_vector(7 downto 0); -- PB0-PB7 Peripheral Data Register
  signal DDRB : std_logic_vector(7 downto 0); -- data direction of PB0-PB7 (1=out)
  signal PB_IN : std_logic_vector(7 downto 0);
  signal reg_read_flag, reg_write_flag, port_read_flag, port_write_flag : std_logic;

  begin

  PB(0) <= PRB(0) when DDRB(0) = '1' else 'H';
  PB(1) <= PRB(1) when DDRB(1) = '1' else 'H';
  PB(2) <= PRB(2) when DDRB(2) = '1' else 'H';
  PB(3) <= PRB(3) when DDRB(3) = '1' else 'H';
  PB(4) <= PRB(4) when DDRB(4) = '1' else 'H';
  PB(5) <= PRB(5) when DDRB(5) = '1' else 'H';
  PB(6) <= PRB(6) when DDRB(6) = '1' and TMRA_PB_ON = '0' else
           TMRA_PB_IN when TMRA_PB_ON = '1' else 'H';
  PB(7) <= PRB(7) when DDRB(7) = '1' and TMRB_PB_ON = '0' else
           TMRB_PB_IN when TMRB_PB_ON = '1' else 'H';
  PB_IN <= PB;
  PC_N <= '0'  when port_read_flag = '1' or port_write_flag = '1' else '1';

  DO <= data_out
  
-- WRITE REGISTERS
  process (PHI2,RES_N) is 
  begin
    if RES_N = '0' then
      PRB <= x"00";
      DDRB <= x"00";
    elsif falling_edge(PHI2) then
      port_write_flag <= '0';
      reg_write_flag <= '0';
      if Wr = '1' then
        case RS is
          when x"1" => PRB <= DI;  reg_write_flag <= '1'; port_write_flag <= '1';
          when x"3" => DDRB <= DI; reg_write_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;

-- READ REGISTERS;
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      data_out <= (others => '1');
    elsif rising_edge(PHI2) then
      port_read_flag <= '0';
      reg_read_flag <= '0';
      if Wr = '0' then
        case RS is
          when x"1" => reg_read_flag <= '1'; port_read_flag <= '1';
          when x"3" => reg_read_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;
  
  DO <= PB_IN when RS = x"1" else
        DDRB  when RS = x"3" else
        (others=>'0');

end architecture rtlb;
