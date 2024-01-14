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
    TOD        : in    std_logic;                     -- pin 19
    IRQ_N      : out   std_logic                    -- pin 21
--    abcdefgdec_n   : out std_logic_vector(7 downto 0);
--    a_n            : out std_logic_vector(3 downto 0)
  );
end entity cia;

architecture str of cia is

  component timerA is
  port ( 
-- DATA AND CONTROL
    PHI2           : in  std_logic; -- clock 1MHz
    DI             : in  std_logic_vector(7 downto 0);
    DO             : out std_logic_vector(7 downto 0);
    RS             : in  std_logic_vector(3 downto 0);
    RES_N          : in  std_logic;
    Wr             : in  std_logic; -- read and write registers
-- INPUTS
    CNT            : in  std_logic; -- counter
-- OUTPUTS
    TMRA_UNDERFLOW : out std_logic; -- timer A underflow pulses for timer B.
    TMR_OUT        : out std_logic; -- timer A output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer A output on PB6 else PB6 is I/O
    SPMODE         : out std_logic; -- CRA_SPMODE forwarding to serial port
    TODIN          : out std_logic; -- CRA_TODIN forwarding to tod
    INT_TMRA       : out std_logic
  );
  end component timerA;

  component timerB is
  port ( 
-- DATA AND CONTROL
    PHI2           : in  std_logic; -- clock 1MHz
    DI             : in  std_logic_vector(7 downto 0);
    DO             : out std_logic_vector(7 downto 0);
    RS             : in  std_logic_vector(3 downto 0);
    RES_N          : in  std_logic;
    Wr             : in  std_logic;
-- INPUTS
    CNT            : in  std_logic; -- counter
    TMRA_UNDERFLOW : in  std_logic; -- underflow pulses from timer A.
-- OUTPUTS
    TMR_OUT        : out std_logic; -- timer B output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer B output on PB7 else PB7 is I/O
    ALARM          : out std_logic; -- CRB_ALARM forwarding to tod
    INT_TMRB       : out std_logic
  );
  end component timerB;

  component port_a is
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
  end component port_a;

  component port_b is
  port (
-- DATA AND CONTROL
    PHI2       : in  std_logic; -- clock 1MHz
    DI         : in  std_logic_vector(7 downto 0);
    DO         : out std_logic_vector(7 downto 0);
    RS         : in  std_logic_vector(3 downto 0); -- register select
    RES_N      : in  std_logic; -- global reset
    Wr         : in  std_logic; -- read and write registers
-- I/O
    PB         : inout std_logic_vector(7 downto 0);
-- INPUTS
    TMRA_PB_IN : in std_logic; -- from TMRA to PB6 if TMRA_PB_ON = '1'
    TMRB_PB_IN : in std_logic; -- from TMRB to PB7 if TMRB_PB_ON = '1'
    TMRA_PB_ON : in std_logic; -- puts TMRA_OUT on PB, overrides bit in DDRB.
    TMRB_PB_ON : in std_logic; -- puts TMRB_OUT on PB, overrides bit in DDRB.
--OUTPUTS
    PC_N       : out std_logic -- Goes low for one clock cycle following a read or write of PORT B.
   );
  end component port_b;

  component serialport is
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DB      : inout std_logic_vector(7 downto 0); -- data in
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
    PHI2           : in  std_logic;
    DI             : in  std_logic_vector(7 downto 0);
    DO             : out std_logic_vector(7 downto 0);
    RS             : in  std_logic_vector(3 downto 0);
    RES_N          : in  std_logic;
    Wr             : in  std_logic;
    Rd             : in  std_logic;
-- INPUTS
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
    PHI2         : in  std_logic;
    DI           : in  std_logic_vector(7 downto 0);
    DO           : out std_logic_vector(7 downto 0);
    RS           : in  std_logic_vector(3 downto 0);
    RES_N        : in  std_logic;
    Wr           : in  std_logic;
    Rd           : in  std_logic;
-- INPUTS        
    TOD          : in std_logic; -- 50 or 60 Hz timer input.
    CRA_TODIN    : in std_logic;
    CRB_ALARM    : in std_logic; -- 1=set ALARM, 0=set time
-- OUTPUTS
    INT_TODALARM : out std_logic
  );
  end component timeofday;

  signal Wr, Rd : std_logic;
  signal CNT_i, CNT_OUT_i, CNT_OUT_EN_i : std_logic;
  signal TMRA_OUT_i, TMRB_OUT_i : std_logic;
  signal TMRA_UNDERFLOW_i, TMRA_PB_ON_i : std_logic;
  signal TMRB_PB_ON_i, SPMODE_i : std_logic;
  signal TODIN_i, ALARM_i : std_logic;
  signal INT_TMRA_i, INT_TMRB_i : std_logic;
  signal INT_TODALARM_i, INT_SP_i : std_logic;
  signal IRQ_i : std_logic;
  signal data_out                 : std_logic_vector(7 downto 0);
  signal data_out_tmra            : std_logic_vector(7 downto 0);
  signal data_out_tmrb            : std_logic_vector(7 downto 0);
  signal data_out_porta           : std_logic_vector(7 downto 0);
  signal data_out_portb           : std_logic_vector(7 downto 0);
  signal data_out_timeofday       : std_logic_vector(7 downto 0);
  signal data_out_interrupt       : std_logic_vector(7 downto 0);

begin

  Wr <= not RW and not CS_N;
  Rd <=     RW and not CS_N;
  DB <= data_out when RW = '1' and CS_N = '0' else (others => 'Z');
--  IRQ_N <= '0' when IRQ_i ='1' else 'Z' ;

-- data_out_*
  with RS select
    data_out <= data_out_porta     when x"0",
                data_out_porta     when x"2",
                data_out_portb     when x"1",
                data_out_portb     when x"3",
                data_out_tmra      when x"4",
                data_out_tmra      when x"5",
                data_out_tmra      when x"e",
                data_out_tmrb      when x"6",
                data_out_tmrb      when x"7",
                data_out_tmrb      when x"f",
                data_out_timeofday when x"8",
                data_out_timeofday when x"9",
                data_out_timeofday when x"A",
                data_out_timeofday when x"B",
                data_out_interrupt when x"D",
                x"ff"              when others;

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
    INT_TMRA       => INT_TMRA_i
  );

  TIMERB_0: entity work.timerb
  port map (    
    PHI2              => PHI2,
    DI                => DB,
    DO                => data_out_tmrb,
    RS                => RS,
    RES_N             => RES_N,
    Wr                => Wr,
    CNT               => CNT,
    TMRA_UNDERFLOW    => TMRA_UNDERFLOW_i,
    TMR_OUT           => TMRB_OUT_i,
    PB_ON_EN          => TMRB_PB_ON_i,
    ALARM             => ALARM_i,
    INT_TMRB          => INT_TMRB_i
  );

  PORTA_0: entity work.port_a
  port map (
    PHI2    => PHI2,
    DI      => DB,
    DO      => data_out_porta,
    RS      => RS,
    RES_N   => RES_N,
    Wr      => Wr,
    PA      => PA
  );
 
  PORTB_0: entity work.port_b
  port map (
    PHI2       => PHI2,
    DI         => DB,
    DO         => data_out_portb,
    RS         => RS,
    RES_N      => RES_N,
    Wr         => Wr,
    PB         => PB,
    TMRA_PB_IN => TMRA_OUT_i,
    TMRB_PB_IN => TMRB_OUT_i,
    TMRA_PB_ON => TMRA_PB_ON_i,
    TMRB_PB_ON => TMRA_PB_ON_i,
    PC_N       => PC_N
  );

  SERIALPORT_0: entity work.serialport
  port map (
    PHI2=>PHI2, DB=>DB, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
    CNT=>CNT, CNT_OUT=>CNT_OUT_i, CNT_OUT_EN=>CNT_OUT_EN_i, SPMODE=>SPMODE_i,
    INT=>INT_SP_i, SP=>SP, TMRA_IN=>TMRA_OUT_i
  );
  CNT <= CNT_OUT_i when CNT_OUT_EN_i = '1' else 'Z';
 
  INTERRUPT_0: entity work.interrupt
  port map (
    PHI2         => PHI2,
    DI           => DB,
    DO           => data_out_interrupt,
    RS           => RS,
    RES_N        => RES_N,
    Wr           => Wr,
    Rd           => Rd,
    INT_TMRA     => INT_TMRA_i,
    INT_TMRB     => INT_TMRB_i,
    INT_TODALARM => INT_TODALARM_i,
    INT_SP       => INT_SP_i,
    INT_FLAG     => FLAG_N,
    IRQ          => IRQ_i
  );
  IRQ_N <= '0' when IRQ_i = '1' else 'Z';
 
  TIMEOFDAY_0: entity work.timeofday
  port map (
    PHI2         => PHI2,
    DI           => DB,
    DO           => data_out_timeofday,
    RS           => RS,
    RES_N        => RES_N,
    Wr           => Wr,
    Rd           => Rd,
    TOD          => TOD,
    CRA_TODIN    => TODIN_i,
    CRB_ALARM    => ALARM_i,
    INT_TODALARM => INT_TODALARM_i
--    abcdefgdec_n => abcdefgdec_n,
--    a_n          => a_n
  );
end architecture str;
