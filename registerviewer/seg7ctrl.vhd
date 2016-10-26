library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.numeric_std.all;

entity seg7ctrl is 
  generic ( CONSTANT prescalersize : integer := 21 );
  port ( 
    PHI2        : in  std_logic;
    res_n      : in  std_logic;
    DISP0      : in  std_logic_vector(3 downto 0);
    DISP1      : in  std_logic_vector(3 downto 0);
    DISP2      : in  std_logic_vector(3 downto 0);
    DISP3      : in  std_logic_vector(3 downto 0);
    abcdefgdec_n  : out std_logic_vector(7 downto 0);
    a_n        : out std_logic_vector(3 downto 0)
  );
end seg7ctrl;

architecture rtl of seg7ctrl is 
  signal prescaler : std_logic_vector(prescalersize-1 downto 0);
  signal dispsel   : std_logic_vector(1 downto 0);
  signal disp_i : std_logic_vector(3 downto 0); -- output of mux
  signal encoded : std_logic_vector(6 downto 0);

--  signal disp_tick_old : std_logic;
begin

  dispsel <= prescaler(prescalersize-1 downto prescalersize-2);
  abcdefgdec_n <= encoded & '0';

--  dispticker: process(PHI2)
--  begin
--    if rising_edge(PHI2) then
--      disp_tick_old <= prescaler(prescalersize-2);
--    end if;
--  end process dispticker;

  prescaling: process(PHI2,RES_N)
  begin
    if res_n = '0' then
      prescaler <= (others => '0');
    elsif rising_edge(PHI2) then
      prescaler <= prescaler + 1;
    end if;
  end process prescaling;



--  with dispsel select disp_i <=
--    DISP0 when "00",
--    DISP1 when "01",
--    DISP2 when "10",
--    DISP3 when "11",
--    "0000" when others;

  process(PHI2,dispsel)
  begin
    if rising_edge(PHI2) then
      if prescaler(prescalersize-3) = '1' then
        case dispsel is
           when "00" => disp_i <= DISP0; a_n <= "1110";
           when "01" => disp_i <= DISP1; a_n <= "1101";
           when "10" => disp_i <= DISP2; a_n <= "1011";
           when "11" => disp_i <= DISP3; a_n <= "0111";
           when others => disp_i <= (others => '0'); a_n <= "1111";
        end case;
      end if;
    end if;
  end process;

-- with dispsel select a_n <=
--   "1110" when "00",
--   "1101" when "01",
--   "1011" when "10",
--   "0111" when "11",
--   "1111" when others;

  decode: process(disp_i)
  begin
    case disp_i is
        when x"0" => encoded <= "0000001";
        when x"1" => encoded <= "1001111";
        when x"2" => encoded <= "0010010";
        when x"3" => encoded <= "0000110";
        when x"4" => encoded <= "1001100";
        when x"5" => encoded <= "0100100";
        when x"6" => encoded <= "0100000";
        when x"7" => encoded <= "0001111";
        when x"8" => encoded <= "0000000";
        when x"9" => encoded <= "0000100";
        when x"a" => encoded <= "0001000";
        when x"b" => encoded <= "1100000";
        when x"c" => encoded <= "0110001";
        when x"d" => encoded <= "1000010";
        when x"e" => encoded <= "0110000";
        when x"f" => encoded <= "0111000";
        when others => null;
      end case;
  end process;
end rtl;

