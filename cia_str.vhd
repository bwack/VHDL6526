library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

-- top-level
entity cia is
  port (
--
    RES_N      : in    std_logic;                    -- pin 34
    PHI2       : in    std_logic;                    -- pin 25
    CS_N       : in    std_logic;                    -- pin 23
    RW         : in    std_logic;                    -- pin 22
    DB         : inout std_logic_vector(7 downto 0); -- pin 26..33
    RS         : in    std_logic_vector(3 downto 0); -- pin 35..38
--
    PA         : inout std_logic_vector(7 downto 0); -- pin 9..2
    PB         : inout std_logic_vector(7 downto 0); -- pin 17..10
    SP         : inout std_logic;                    -- pin 39
    CNT        : inout std_logic;                    -- pin 40
    FLAG_N     : in    std_logic;                    -- pin 24
    PC_N       : out   std_logic;                    -- pin 18
    IRQ_N      : out   std_logic;                    -- pin 21
    TOD        : inout std_logic;                    -- pin 19
  );
end entity cia;

architecture str of cia is
begin
  component timerA is
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
    SPMODE         : out std_logic; -- CRA_SPMODE forwarding to serial port
    TODIN          : out std_logic; -- CRA_TODIN forwarding to tod
    INT            : out std_logic
  );
  end component timerA;

  component timerB is
  port ( 
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- databus
    DO      : out std_logic_vector(7 downto 0); -- databus
    RS      : in  std_logic_vector(3 downto 0); -- address - register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS
    CNT     : in  std_logic; -- counter
    TMRA_UNDERFLOW : in std_logic; -- underflow pulses from timer A.
-- OUTPUTS
    TMR_OUT        : out std_logic; -- timer B output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer B output on PB7 else PB7 is I/O
    ALARM          : out std_logic; -- CRB_ALARM forwarding to tod
    INT            : out std_logic
  );
  end component timerB;

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

  component serialport is
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
  end component serialport;

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
--    INTIN  : in std_logic_vector(4 downto 0);
    INT_TMRA       : in std_logic; -- bit 0
    INT_TMRB       : in std_logic; -- bit 1
    INT_TODALARM   : in std_logic; -- bit 2
    INT_SP         : in std_logic; -- bit 3
    INT_FLAG       : in std_logic; -- bit 4
-- OUTPUTS
    IRQ            : out std_logic
  );
  end component interrupt;

  component timeofday is
  port ( 
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- databus
    DO      : out std_logic_vector(7 downto 0); -- databus
    RS      : in  std_logic_vector(3 downto 0); -- address - register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
--
    TODIN     : in std_logic; -- 50 or 60 Hz timer input.
    CRA_TODIN : in std_logic;
    CRB_ALARM : in std_logic; -- Writing to TOD registers: 1=sets ALARM, 0=sets time
    INT       : out std_logic -- interrupt on alarm
  );
  end component timeofday;

begin

  TIMERA_0: entity work.timera
  port map (
    PHI2=>PHI2, DI=>DI_TMRA, DO=>DO_TMRA, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
  );

  TIMERB_0: entity work.timerb
  port map (
    PHI2=>PHI2, DI=>DI_TMRB, DO=>DO_TMRB, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
  );

  PORTA_0: entity work.port_a
  port map (
    PHI2=>PHI2, DI=>DI_PORTA, DO=>DO_PORTA, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
  );

  PORTB_0: entity work.port_b
  port map (
    PHI2=>PHI2, DI=>DI_PORTB, DO=>DO_PORTB, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
  );

  SERIALPORT_0: entity work.serialport
  port map (
    PHI2=>PHI2, DI=>DI_SP, DO=>DO_SP, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
  );

  INTERRUPT_0: entity work.port_b
  port map (
    PHI2=>PHI2, DI=>DI_INT, DO=>DO_INT, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
  );

  TIMEOFDAY_0: entity work.timeofday
  port map (
    PHI2=>PHI2, DI=>DI_TOD, DO=>DO_TOD, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,

  );
end architecture str;
