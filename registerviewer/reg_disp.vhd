library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.numeric_std.all;

entity reg_disp is
  port (
    PHI2   : in std_logic;
    RES_N : in std_logic;
    rw  : in std_logic;
    cs_n : in std_logic; 
    data : in std_logic_vector(7 downto 0); -- data bus
    rs   : in std_logic_vector(3 downto 0); -- address bus
    dispreg : in std_logic_vector(3 downto 0); -- SW3..0;
    abcdefgdec_n : out std_logic_vector(7 downto 0);
    a_n        : out std_logic_vector(3 downto 0)
  );
end entity reg_disp;

architecture rtl of reg_disp is
-- registers
  type registerFile_t is array(0 to 15) of std_logic_vector(7 downto 0);
  signal registers : registerFile_t;
  signal d0,d1,d2,d3 : std_logic_vector(3 downto 0);
  
begin
  SEG7CTRL_0: entity work.seg7ctrl(rtl)
    generic map(3) -- 14 !
    port map(PHI2,RES_N,d0,d1,d2,d3,abcdefgdec_n,a_n);

-- sw3..0 selects register to display
  process(phi2)
  begin
    if rising_edge(phi2) then
      d3 <= x"0";
      d2 <= dispreg;
      d1 <= registers(to_integer(unsigned(dispreg)))(7 downto 4);
      d0 <= registers(to_integer(unsigned(dispreg)))(3 downto 0);
    end if ;
  end process;

-- write register
  write_0: process(PHI2,RES_N) is
  begin
    if RES_N = '0' then
      for i in 0 to 15 loop
        registers(i) <= x"00";
      end loop;
    elsif falling_edge(PHI2) then
      if rw = '0' and cs_n = '0' then
        registers(to_integer(unsigned(rs))) <= data;
      end if;
    end if;
  end process write_0;
  
end architecture rtl;