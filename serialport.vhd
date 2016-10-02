library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity SerialPort is
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- data in
    DO      : out std_logic_vector(7 downto 0); -- data out
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS & OUTPUTS
    CRA_SPMODE : in std_logic; -- input from CRA register
    IRQ_N   : out std_logic; -- interrupt after 8 cnt in input mode.
    SP      : inout std_logic;
    CNT     : inout std_logic; -- in or out depending on input or output mode.
}
end entity;

architecture rtl of SerialPort is
  signal SDR : std_logic_vector(7 downto 0); -- Serial Data Register
  signal DFF : std_logic_vector(7 downto 0);
begin
  DFF(0) <= SP when CRA_SPMODE = '1' else 'Z';
  process(CNT) is
  begin
    if rising_edge(CNT) then
      DFF(1) <= DFF(0);
      DFF(2) <= DFF(1);
      DFF(3) <= DFF(2);
      DFF(4) <= DFF(3);
      DFF(5) <= DFF(4);
      DFF(6) <= DFF(5);
      DFF(7) <= DFF(6);
  end process;
end architecture rtl;