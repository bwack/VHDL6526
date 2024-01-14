library ieee;
use ieee.std_logic_1164.all;

entity tb_io_ports is
-- empty
end entity tb_io_ports;

architecture behaviour of tb_io_ports is

  component port_a is
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- data in
    DO      : out std_logic_vector(7 downto 0); -- data out
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS & OUTPUTS
-- IO interface to  be used with IO buffer.
    PA_BUF_IN      : inout  std_logic_vector(7 downto 0);
    PA_BUF_OUT     : inout std_logic_vector(7 downto 0)
     );
  end component port_a;

  component port_b is
-- IO port b
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- data in
    DO      : out std_logic_vector(7 downto 0); -- data out
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- I/O
    PB_BUF_IN      : inout std_logic_vector(7 downto 0);
    PB_BUF_OUT     : inout std_logic_vector(7 downto 0);
    TMRA_OUT       : in std_logic; -- from TMRA to PB6 if TMRA_PB_ON = '1'
    TMRB_OUT       : in std_logic; -- from TMRB to PB7 if TMRB_PB_ON = '1'
    TMRA_PB_ON     : in std_logic; -- puts TMRA_OUT on PB, overrides bit in DDRB.
    TMRB_PB_ON     : in std_logic; -- puts TMRB_OUT on PB, overrides bit in DDRB.
    PC_N           : out std_logic -- Goes low for one clock cycle following
                                    -- a read or write of PORT B.
     );
  end component port_b;


  signal PHI2, RES_N, Rd, Wr : std_logic;
  signal DI         : std_logic_vector(7 downto 0);
  signal DO         : std_logic_vector(7 downto 0); --bus
--  signal DO, DO_PORTA, DO_PORTB : std_logic_vector(7 downto 0); --bus
--  signal PORTA_bus, PORTB_bus : std_logic; --buscontrol
  signal RS : std_logic_Vector(3 downto 0);
  signal PA_IN, PA_OUT : std_logic_vector(7 downto 0);
  signal PB_IN, PB_OUT : std_logic_vector(7 downto 0);
  signal TMRA_OUT, TMRB_OUT, TMRA_PB_ON, TMRB_PB_ON : std_logic := '0';
  signal PC_N : std_logic;

begin
  UUT_A: entity work.port_a(rtla)
    port map (
       PHI2  =>   PHI2 ,
       DI    =>   DI   ,
       DO    =>   DO   ,
       RS    =>   RS ,
       RES_N =>   RES_N,
       Rd    =>   Rd,
       Wr    =>   Wr,
       PA_BUF_IN => PA_IN,
       PA_BUF_OUT => PA_OUT
    ); 

  UUT_B: entity work.port_b(rtlb)
    port map (
       PHI2  =>   PHI2 ,
       DI    =>   DI   ,
       DO    =>   DO   ,
       RS    =>   RS ,
       RES_N =>   RES_N,
       Rd    =>   Rd,
       Wr    =>   Wr,
       PB_BUF_IN => PB_IN,
       PB_BUF_OUT => PB_OUT,
       TMRA_OUT => TMRA_OUT,
       TMRB_OUT => TMRB_OUT,
       TMRA_PB_ON => TMRA_PB_ON,
       TMRB_PB_ON => TMRB_PB_ON,
       PC_N    => PC_N
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
             '1' after  4.5 us, '0' after  5 us,
             '1' after  5.5 us, '0' after  6 us,
             '1' after  6.5 us, '0' after  7 us;

  Rd <= '0', '1' after  7.5 us, '0' after  8 us,
             '1' after  8.5 us, '0' after  9 us,
             '1' after  9.5 us, '0' after  10 us,
             '1' after  10.5 us, '0' after  11 us;

--process
--begin
--  TMRA_PB_ON <= not TMRA_PB_ON;
--  TMRB_PB_ON <= not TMRB_PB_ON;
--  TMRA_PB <= '0';
--  TMRB_PB <= '1';
--  wait for 50 ns;
--  TMRA_PB <= '1';
--  TMRB_PB <= '0';
--  wait for 50 ns;
--end process;
TMRA_PB_ON  <= '0';
TMRB_PB_ON  <= '0';

  --process
  --begin
  --  PA_IN <= (others => 'Z');
  --  wait for 5 us;
  --    for i in 0 to 9 loop
  --      PA_IN <= std_logic_vector(std_logic(i));
  --    end loop;
  --  wait;
  --end process;

 PA_IN <= "ZZZZZZZZ", "1111HHHH" after 5.5 us;
 PB_IN <= "ZZZZZZZZ", "111HHHHH" after 5.5 us;
  --process
  --begin
  --  for i in 0 to 7 loop
  --  PA_IN <= "1111HHHH";
  --  PB_IN <= "1111HHHH";
  --  PA_IN (i) <= '0';
  --  PB_IN (i) <= '0';
  --  wait for 200 ns;
  --  PA_IN (i) <= '1';
  --  PB_IN (i) <= '1';
  --  wait for 200 ns;
  --  end loop;
  --end process;
  RS <= x"0", x"2" after 4.5 us,  x"1" after  5.5 us, x"3" after  6.5 us,
        x"0" after 7.5 us, x"2" after 8.5 us, x"1" after 9.5 us, x"3" after 10.5 us;
  DI <= "ZZZZZZZZ", "00100001" after 3.5 us, "00000001" after 4.5 us, "00000011" after 5.5 us,
                    "00000111" after 6.5 us, "00001111" after 7.5 us, "00000111" after 8.5 us;
end architecture behaviour;


