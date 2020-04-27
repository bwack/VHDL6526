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
--    PC_N       : out   std_logic;                    -- pin 18
--    IRQ_N      : out   std_logic;                    -- pin 21
    TOD        : in    std_logic;                     -- pin 19
	abcdefgdec_n   : out std_logic_vector(7 downto 0);
    a_n            : out std_logic_vector(3 downto 0)
  );
end entity cia;

architecture str of cia is

  component timerA is
  port ( 
-- DATA AND CONTROL
    PHI2           : in  std_logic; -- clock 1MHz
    DI             : in  std_logic_vector(7 downto 0);
    DO             : out std_logic_vector(7 downto 0);
    RS             : in  std_logic_vector(3 downto 0); -- register select
    RES_N          : in  std_logic; -- global reset
    Wr             : in  std_logic; -- read and write registers
-- INPUTS
    CNT            : in std_logic; -- counter
-- OUTPUTS
    TMRA_UNDERFLOW : out std_logic; -- timer A underflow pulses for timer B.
    TMR_OUT        : out std_logic; -- timer A output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer A output on PB6 else PB6 is I/O
    SPMODE         : out std_logic; -- CRA_SPMODE forwarding to serial port
    TODIN          : out std_logic; -- CRA_TODIN forwarding to tod
    INT            : out std_logic;
		abcdefgdec_n   : out std_logic_vector(7 downto 0);
    a_n            : out std_logic_vector(3 downto 0)
  );
  end component timerA;

--  component timerB is
--  port ( 
---- DATA AND CONTROL
--    PHI2              : in  std_logic; -- clock 1MHz
--    DI                : in  std_logic_vector(7 downto 0);
--    DO                : out std_logic_vector(7 downto 0);
--    RES_N             : in  std_logic; -- global reset
--    Wr                : in  std_logic;
---- register strobes
--    TMRB_REG_TIMER_LO : in  std_logic; -- address 6
--    TMRB_REG_TIMER_HI : in  std_logic; -- address 7
--    TMRB_REG_CONTROL  : in  std_logic; -- address f
---- INPUTS
--    CNT               : in  std_logic; -- counter
--    TMRA_UNDERFLOW    : in std_logic; -- underflow pulses from timer A.
---- OUTPUTS
--    TMR_OUT           : out std_logic; -- timer B output to PORTB
--    PB_ON_EN          : out std_logic; -- enable timer B output on PB7 else PB7 is I/O
--    ALARM             : out std_logic; -- CRB_ALARM forwarding to tod
--    INT               : out std_logic
--  );
--  end component timerB;
--
--  component port_a is
--  port (
---- DATA AND CONTROL
--    PHI2    : in  std_logic; -- clock 1MHz
--    DI      : in  std_logic_vector(7 downto 0);
--    DO      : out std_logic_vector(7 downto 0);
--    RS      : in  std_logic_vector(3 downto 0); -- register select
--    RES_N   : in  std_logic; -- global reset
--    Wr      : in  std_logic; -- read and write registers
---- INPUTS & OUTPUTS
---- IO interface to be used with IO buffer.
--    PA      : inout std_logic_vector(7 downto 0)
--  );
--  end component port_a;
--
--  component port_b is
--  port (
---- DATA AND CONTROL
--    PHI2       : in  std_logic; -- clock 1MHz
--    DI         : in  std_logic_vector(7 downto 0);
--    DO         : out std_logic_vector(7 downto 0);
--    RS         : in  std_logic_vector(3 downto 0); -- register select
--    RES_N      : in  std_logic; -- global reset
--    Rd         : in  std_logic; -- read and write registers
---- I/O
--    PB         : inout std_logic_vector(7 downto 0);
--    TMRA_PB_IN : in std_logic; -- from TMRA to PB6 if TMRA_PB_ON = '1'
--    TMRB_PB_IN : in std_logic; -- from TMRB to PB7 if TMRB_PB_ON = '1'
--    TMRA_PB_ON : in std_logic; -- puts TMRA_OUT on PB, overrides bit in DDRB.
--    TMRB_PB_ON : in std_logic; -- puts TMRB_OUT on PB, overrides bit in DDRB.
--    PC_N       : out std_logic -- Goes low for one clock cycle following
--                                   -- a read or write of PORT B.
--   );
--  end component port_b;
--
--  component serialport is
--  port (
---- DATA AND CONTROL
--    PHI2    : in  std_logic; -- clock 1MHz
--    DB      : inout std_logic_vector(7 downto 0); -- data in
--    RS      : in  std_logic_vector(3 downto 0); -- register select
--    RES_N   : in  std_logic; -- global reset
--    Rd, Wr  : in  std_logic; -- read and write registers
---- INPUTS & OUTPUTS
--    SPMODE  : in std_logic; -- input from CRA register
--    INT     : out std_logic; -- interrupt after 8 cnt.
--    SP      : inout std_logic;
--    CNT     : in std_logic; -- CNT line input from external devices
--    TMRA_IN : in std_logic; -- input from TimerA.TMR_OUT, toggle mode.
--    CNT_OUT : out std_logic; -- output to CNT line. Controls tristate buffer.
--    CNT_OUT_EN : out std_logic
--  );
--  end component serialport;
--
--  component interrupt is
--  port (
---- DATA AND CONTROL
--    PHI2    : in  std_logic; -- clock 1MHz
--    DB      : inout std_logic_vector(7 downto 0); -- data in
--    RS      : in  std_logic_vector(3 downto 0); -- register select
--    RES_N   : in  std_logic; -- global reset
--    Rd, Wr  : in  std_logic; -- read and write registers
---- INPUTS
----    INTIN  : in std_logic_vector(4 downto 0);
--    INT_TMRA       : in std_logic; -- bit 0
--    INT_TMRB       : in std_logic; -- bit 1
--    INT_TODALARM   : in std_logic; -- bit 2
--    INT_SP         : in std_logic; -- bit 3
--    INT_FLAG       : in std_logic; -- bit 4
---- OUTPUTS
--    IRQ            : out std_logic
--  );
--  end component interrupt;
--
--  component timeofday is
--  port ( 
---- DATA AND CONTROL
--    PHI2    : in  std_logic; -- clock 1MHz
--    DB      : inout std_logic_vector(7 downto 0); -- data in
--    RS      : in  std_logic_vector(3 downto 0); -- address - register select
--    RES_N   : in  std_logic; -- global reset
--    Rd, Wr  : in  std_logic; -- read and write registers
----
--    TOD       : in std_logic; -- 50 or 60 Hz timer input.
--    CRA_TODIN : in std_logic;
--    CRB_ALARM : in std_logic; -- Writing to TOD registers: 1=sets ALARM, 0=sets time
--    INT       : out std_logic -- interrupt on alarm
--  );
--  end component timeofday;

  signal Rd, Wr : std_logic;
  signal CNT_OUT_i, CNT_OUT_EN_i, TMRA_OUT_i, TMRB_OUT_i  : std_logic;
  signal TMRA_UNDERFLOW_i, TMRA_PB_ON_i, TMRB_PB_ON_i, SPMODE_i : std_logic;
  signal TODIN_i, ALARM_i : std_logic;
  signal INT_TMRA_i, INT_TMRB_i, INT_TODALARM_i, INT_SP_i : std_logic;
  signal INT_FLAG_i, IRQ_i : std_logic;
  signal data_out                 : std_logic_vector(7 downto 0);
  signal data_out_tmra            : std_logic_vector(7 downto 0);
--  signal data_out_tmrb            : std_logic_vector(7 downto 0);
--  signal data_out_porta           : std_logic_vector(7 downto 0);
--  signal data_out_portb           : std_logic_vector(7 downto 0);

begin
  Wr <= not RW and not CS_N;
  DB <= data_out when RW = '1' and CS_N = '0' else (others => 'Z');

  TIMERA_0: entity work.timera
  port map (
    PHI2           => PHI2,
    DI             => DB,
    DO             => data_out_tmra,
	 RS             => RS,
    RES_N          => RES_N,
    Wr             => Wr,
    CNT            => CNT,
    TMRA_UNDERFLOW => TMRA_UNDERFLOW_i,
    TMR_OUT        => TMRA_OUT_i,
    PB_ON_EN       => TMRA_PB_ON_i,
    SPMODE         => SPMODE_i,
    TODIN          => TODIN_i,
    INT            => INT_TMRA_i,
		abcdefgdec_n   => abcdefgdec_n,
    a_n            => a_n
  );

--  TIMERB_0: entity work.timerb
--  port map (
--    PHI2              => PHI2,
--    DI                => DB,
--    DO                => data_out_tmrb,
--    RES_N             => RES_N,
--    Wr                => Wr,
--    TMRB_REG_TIMER_LO => reg_tmrb_timerlo_en,
--    TMRB_REG_TIMER_HI => reg_tmrb_timerhi_en,
--    TMRB_REG_CONTROL  => reg_tmrb_control_en,
--    CNT               => CNT,
--    TMRA_UNDERFLOW    => TMRA_UNDERFLOW_i,
--    TMR_OUT           => TMRB_OUT_i,
--    PB_ON_EN          => TMRB_PB_ON_i,
--    ALARM             => ALARM_i,
--    INT               => INT_TMRB_i
--  );
--
--  PORTA_0: entity work.port_a
--  port map (
--    PHI2    => PHI2,
--    DI      => DB,
--    DO      => data_out_porta,
--    RS      => RS,
--    RES_N   => RES_N,
--    Wr      => Wr,
--    PA      => PA
--  );
-- 
--  PORTB_0: entity work.port_b
--  port map (
--    PHI2       => PHI2
--    DI         => DB
--    DO         => data_out_partb
--    RS         => RS
--    RES_N      => RES_N
--    Rd         => Rd
--    PB         => 
--    TMRA_PB_IN => 
--    TMRB_PB_IN => 
--    TMRA_PB_ON => 
--    TMRB_PB_ON => 
--    PC_N       => 
--
--    PHI2=>PHI2, DB=>DB, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
--    PB=>PB, TMRA_PB_IN=>TMRA_OUT_i, TMRB_PB_IN=>TMRB_OUT_i,
--    TMRA_PB_ON=>TMRA_PB_ON_i, TMRB_PB_ON=>TMRB_PB_ON_i, PC_N=>PC_N
--  );
-- 
--  SERIALPORT_0: entity work.serialport
--  port map (
--    PHI2=>PHI2, DB=>DB, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
--    CNT=>CNT, CNT_OUT=>CNT_OUT_i, CNT_OUT_EN=>CNT_OUT_EN_i, SPMODE=>SPMODE_i,
--    INT=>INT_SP_i, SP=>SP, TMRA_IN=>TMRA_OUT_i
--  );
--  CNT <= CNT_OUT_i when CNT_OUT_EN_i = '1' else 'Z';
-- 
--  INTERRUPT_0: entity work.interrupt
--  port map (
--    PHI2=>PHI2, DB=>DB, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
--    INT_TMRA=>INT_TMRA_i, INT_TMRB=>INT_TMRB_i, INT_TODALARM=>INT_TODALARM_i,
--    INT_SP=>INT_SP_i, INT_FLAG=>INT_FLAG_i, IRQ=>IRQ_i
--  );
--  INT_FLAG_i <= FLAG_N;
--  IRQ_N <= not IRQ_i;
-- 
--  TIMEOFDAY_0: entity work.timeofday
--  port map (
--    PHI2=>PHI2, DB=>DB, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
--    TOD=>TOD, CRA_TODIN=>TODIN_i, CRB_ALARM=>ALARM_i, INT=>INT_TODALARM_i
--  );

--  data_out <= data_out_porta when RS = x"0" or RS = x"2" else
--              data_out_portb when RS = x"1" or RS = x"3" else
--              data_out_tmra  when RS = x"4" or RS = x"5" or RS = x"E" else
--              data_out_tmrb  when RS = x"6" or RS = x"7" or RS = x"F" else
--              (others=>'0');
  data_out <= data_out_tmra;
  
end architecture str;
