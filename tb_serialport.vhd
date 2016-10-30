library ieee;
use ieee.std_logic_1164.all;

entity tb_SerialPort is
-- empty
end tb_SerialPort;

architecture behaviour of tb_SerialPort is
  component SerialPort is
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- data in
    DO      : out std_logic_vector(7 downto 0); -- data out
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS & OUTPUTS
    SPMODE  : in std_logic; -- input from CRA register
    INT     : out std_logic; -- interrupt after 8 cnt.
    SP      : inout std_logic;
    CNT     : in std_logic; -- CNT line input from external devices
    TMRA_IN : in std_logic; -- input from TimerA.TMR_OUT, toggle mode.
    CNT_OUT : out std_logic; -- output to CNT line. Controls tristate buffer.
    CNT_OUT_EN : out std_logic
  );
  end component;

  component timerA is
-- Interval Timer: 16 bit read-only Timer Counter
-- The timer decrements.
  port ( 
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- databus
    DO      : out std_logic_vector(7 downto 0); -- databus
    RS      : in  std_logic_vector(3 downto 0); -- address - register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
--  Rd and Wr are driven by CS_N and Rd/Wr in the chip access control
-- INPUTS
    CNT     : in std_logic; -- counter
-- OUTPUTS
    TMR_OUT        : out std_logic; -- timer A output to PORTB
    TMRA_UNDERFLOW : out std_logic; -- timer A underflow pulses for timer B.
    PB_ON_EN       : out std_logic; -- enable timer A output on PB6 else PB6 is I/O
    SPMODE         : out std_logic;
    INT            : out std_logic
  );
  end component;

  component Interrupt is
    port (
  -- DATA AND CONTROL
      PHI2    : in  std_logic; -- clock 1MHz
      DI      : in  std_logic_vector(7 downto 0); -- data in
      DO      : out std_logic_vector(7 downto 0); -- data out
      RS      : in  std_logic_vector(3 downto 0); -- register select
      RES_N   : in  std_logic; -- global reset
      Rd, Wr  : in  std_logic; -- read and write registers
  -- INPUTS
  --    INTIN  : in std_logic_vector(4 downto 0);
      INT_TMRA       : in std_logic; -- bit 0
      INT_TMRB       : in std_logic; -- bit 1
      INT_TODALARM   : in std_logic; -- bit 2
      INT_SP         : in std_logic; -- bit 3
      INT_FLAG       : in std_logic; -- bit 4
  -- OUTPUTS
      IRQ_N          : out std_logic
    );
  end component Interrupt;

  signal PHI2, RES_N, Rd, Wr : std_logic;
  signal DI, DO              : std_logic_vector(7 downto 0);
  signal RS                  : std_logic_Vector(3 downto 0);
  signal CRA_SPMODE, SP, INT_SP, CNT, CNT_OUT : std_logic;
  signal TMRA_OUT, TMRB_OUT, TMRA_UNDERFLOW : std_logic;
  signal TMRA_PB_ON_EN, INT_TMRA, CNT_OUT_EN,IRQ : std_logic;
  signal r0,r1,r2 : std_logic;
  constant HALFPERIOD : time := 500 ns;
begin

  UUT_SERIAL: entity work.SerialPort(rtl)
    port map (
      PHI2=>PHI2, DI=>DI, DO=>DO, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
      CNT => CNT, CNT_OUT => CNT_OUT, SPMODE => CRA_SPMODE, 
      INT => INT_SP, SP => SP, TMRA_IN => TMRA_OUT, CNT_OUT_EN => CNT_OUT_EN
    );

  TIMERA_0: entity work.timerA(rtl)
    port map (
      PHI2=>PHI2, DI=>DI, DO=>DO, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
      CNT => CNT, TMR_OUT => TMRA_OUT, TMRA_UNDERFLOW => TMRA_UNDERFLOW,
      PB_ON_EN => TMRA_PB_ON_EN, INT => INT_TMRA, SPMODE => CRA_SPMODE
    );

  INTERRUPT_0: entity work.Interrupt(rtl)
    port map (
      PHI2=>PHI2, DI=>DI, DO=>DO, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
      INT_TMRA => INT_TMRA, INT_TMRB => '0', INT_TODALARM => '0',
      INT_SP => INT_SP, INT_FLAG => '0', IRQ => IRQ
    );

  CNT <= '0' when CNT_OUT_EN = '1' and CNT_OUT = '0' else 'H'; -- possible tristate buffer
--  CNT <= 'H';
P_CLK_0: process
  begin
    PHI2 <= '0';
    wait for HALFPERIOD;
    PHI2 <= '1';
    wait for HALFPERIOD;    
  end process P_CLK_0;

process (PHI2)
begin
  if rising_edge(PHI2) then
    r0 <= '0';
    if IRQ='1' then
      r0 <= '1';
    end if;
    r1<=r0;
    r2<=r1;
    Rd <= r2;
  end if;
end process;

-- an alternative and slower cnt signal than the PHI2 for the timer tick input
--P_CNT_0: process
--  begin
--    CNT <= '0';
--    wait for 11.3 us;
--    CNT <= '1';
--    wait for 11.3 us;
--  end process P_CNT_0;

  
  process
  begin
-- simple start stop test
    SP <= 'Z';
    CNT <= 'Z';
    res_n <= '0';
    Wr <= '0';
    -- SP <= '1';
    wait for HALFPERIOD*3;
    res_n <= '1';
    Wr <= '1';
    RS <= x"D";             -- Interrupt
    DI <= "10011110";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00000111";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";             -- TA_HI (timerA auto loads after this write)
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "01000101"; -- CRA: START, toggle, continuous
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*4;
    Wr <= '1';
    RS <= x"C";
    DI <= "01010101";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*250;
    Wr <= '1';
    RS <= x"C";
    DI <= "00000001";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*100;
    Wr <= '1';
    RS <= x"C";
    DI <= "00000001";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*500;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*10;
    SP <= '1';
    CNT <= 'Z';
    RS <= x"D";
    wait for HALFPERIOD*2*10;
    CNT <= '0'; SP <= '0';
    wait for HALFPERIOD*2*10;
    CNT <= 'Z';
    wait for HALFPERIOD*2*10;
    CNT <= '0'; SP <= '1';
    wait for HALFPERIOD*2*10;
    CNT <= 'Z';
    wait for HALFPERIOD*2*10;
    CNT <= '0'; SP <= '0';
    wait for HALFPERIOD*2*10;
    CNT <= 'Z';
    wait for HALFPERIOD*2*10;
    CNT <= '0'; SP <= '1';
    wait for HALFPERIOD*2*10;
    CNT <= 'Z';
    wait for HALFPERIOD*2*10;
    CNT <= '0'; SP <= '0';
    wait for HALFPERIOD*2*10;
    CNT <= 'Z';
    wait for HALFPERIOD*2*10;
    CNT <= '0'; SP <= '1';
    wait for HALFPERIOD*2*10;
    CNT <= 'Z';
    wait for HALFPERIOD*2*10;
    CNT <= '0'; SP <= '1';
    wait for HALFPERIOD*2*10;
    CNT <= 'Z';
    wait for HALFPERIOD*2*10;
    CNT <= '0'; SP <= '0';
    wait for HALFPERIOD*2*10;
    CNT <= 'Z';
    wait for HALFPERIOD*2*10;
    SP <= 'Z';
     wait;
  end process;
end architecture behaviour;


