library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity port_a is
-- IO port a
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0);
    DO      : out std_logic_vector(7 downto 0);
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Wr      : in  std_logic; -- read and write registers
-- I/O
    PA      : inout std_logic_vector(7 downto 0)
  );
end entity port_a;

architecture rtla of port_a is
-- REGISTERS      
  signal PRA       : std_logic_vector(7 downto 0); -- PA0-PA7 Peripheral Data Register
  signal DDRA      : std_logic_vector(7 downto 0); -- data direction of PA0-PA7 (1=out)
  signal read_flag : std_logic;

begin

  BUFFERBITS: for i in 0 to 7 generate
    PA(i) <= PRA(i) when DDRA(i) = '1' else 'Z';
  end generate BUFFERBITS;
 
  --  PA_tris <= DDRA;
-- WRITE REGISTERS
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      PRA <= x"00";
      DDRA <= x"00";
    elsif falling_edge(PHI2) then
      if Wr = '1' then
        case RS is
          when x"0" => PRA <= DI;
          when x"2" => DDRA <= DI;
          when others => null;
        end case;
      end if;
    end if;
  end process;

-- READ REGISTER
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      read_flag <= '0';
    elsif rising_edge(PHI2) then
      read_flag <= '0';
      if Wr = '0' then
        case RS is
          when x"0" => read_flag <= '1';
          when x"2" => read_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;

  DO <= PA    when RS = x"0" else
        DDRA  when RS = x"2" else
        (others=>'0');

end architecture rtla;