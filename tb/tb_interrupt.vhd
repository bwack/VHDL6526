library ieee;
use ieee.std_logic_1164.all;

entity tb_interrupt is
-- empty
end tb_interrupt;

architecture behaviour of tb_interrupt is
  component interrupt is
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- data in
    DO      : out std_logic_vector(7 downto 0); -- data out
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS
    INTIN  : in std_logic_vector(4 downto 0);
--    INT_TMRA       : in std_logic;
--    INT_TMRB       : in std_logic;
--    INT_TODALARM   : in std_logic;
--    INT_SERIALPORT : in std_logic;
--    INT_FLAG       : in std_logic;
-- OUTPUTS
    IRQ_N          : out std_logic
     );
  end component interrupt;

  signal PHI2, RES_N, Rd, Wr, IRQ_N : std_logic;
  signal INTIN : std_logic_vector(4 downto 0);
  signal DI, DO : std_logic_vector(7 downto 0);
  signal RS : std_logic_Vector(3 downto 0);

begin
  UUT: entity work.interrupt(rtl)
    port map (
       PHI2  =>   PHI2 ,
       DI    =>   DI   ,
       DO    =>   DO   ,
       RS    =>   RS ,
       RES_N =>   RES_N,
       Rd    =>   Rd,
       Wr    =>   Wr,
       INTIN   =>   INTIN,  
       IRQ_N   =>   IRQ_N
    ); 

P_CLK_0: process
  begin
    PHI2 <= '0';
    wait for 500 ns;
    PHI2 <= '1';
    wait for 500 ns;    
  end process P_CLK_0;

  res_n  <= '1', '0' after 1000 ns, '1' after 2000 ns;

  DO <= "ZZZZZZZZ";
  Wr <= '0', '1' after  3.5 us, '0' after  4 us,
             '1' after  7.5 us, '0' after  8 us,
             '1' after  9.5 us, '0' after  10 us;

  Rd <= '0', '1' after 12.5 us, '0' after 13 us,
             '1' after 13.5 us, '0' after 14 us;

  INTIN <= "00000", "00001" after 4.5 us, "00000" after 5.5 us ;

  RS <= x"D";
  DI <= "11111111", "00000001" after 7 us, "00011111" after 9 us;
end architecture behaviour;


