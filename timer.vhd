library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity timerA is
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
    CNT     : in  std_logic; -- counter
-- OUTPUTS
    TMR_OUT_N      : out std_logic; -- timer A output to PORTB
    TMRA_UNDERFLOW : out std_logic; -- timer A underflow pulses for timer B.
    PB_ON_EN       : out std_logic; -- enable timer A output on PB6 else PB6 is I/O
    IRQ            : out std_logic
  );
end entity timerA;

architecture rtl of timerA is
-- REGISTERS
  signal TA_LO       : unsigned(7 downto 0); -- TMR LATCH LOAD VALUE LO
  signal TA_HI       : unsigned(7 downto 0); -- TMR LATCH LOAD VALUE HI
  signal CRA_START   : std_logic; -- 1=start TMRA, 0=Stop TMRA
  signal CRA_PBON    : std_logic; -- 1=PB6 TMRA output, 0=PB6 I/O
  signal CRA_OUTMODE : std_logic; -- 1=toggle, 0=pulse
  signal CRA_RUNMODE : std_logic; -- 1=oneshot, 0=continuous
  signal CRA_LOAD    : std_logic; -- 1=Force Load (strobe)
  signal CRA_INMODE  : std_logic; -- 1=Count on rising CNT, 0=Count PHI2
  signal CRA_SPMODE  : std_logic; -- 1=Serial Port output, 0=SP input (req ext shift clock)
  signal CRA_TODIN   : std_logic; -- 1=50Hz clock on TOD pin, 0=60Hz.
  signal TMRA        : unsigned(15 downto 0); -- read only timer counter
-- OTHER
  signal TMRACLOCK   : std_logic;
  signal TMROUT_N    : std_logic;
-- flags and other data
  signal underflow_flag : std_logic;
  signal data      : std_logic_vector(7 downto 0); -- data for DO
  signal read_flag : std_logic; -- tristate control of DO
  signal mydebug : std_logic;

begin

TMR_OUT_N <= TMROUT_N;
TMRA_UNDERFLOW <= underflow_flag;
PB_ON_EN <= CRA_PBON;
IRQ <= underflow_flag;

  timeroutput: process (RES_N,underflow_flag) is
  begin
    if RES_N = '0' then 
      TMROUT_N <= '1';
    elsif underflow_flag = '1' then
      TMROUT_N <= not TMROUT_N;
    elsif CRA_OUTMODE = '0' then
      TMROUT_N <= '1';
    end if;       
  end process;


-- TIMER CLOCK
    TMRACLOCK <= PHI2 when CRA_INMODE = '0' else CNT;

-- TIMER
  timerA: process (TMRACLOCK,RES_N,CRA_LOAD) is
    variable TMR : unsigned(15 downto 0);
  begin
    if RES_N = '0' then
      TMRA <= x"ffff";
      underflow_flag <= '0';
    elsif CRA_LOAD = '1' then
      TMRA <= TA_HI & TA_LO;
    elsif rising_edge(TMRACLOCK) then
        underflow_flag <= '0';
      if TMRA = "0000000000000000" and CRA_START = '1' then
        underflow_flag <= '1';
        TMRA <= TA_HI & TA_LO;
      elsif CRA_START = '1' then
          TMR := TMRA;
          TMR := TMR - 1;
          TMRA <= TMR;
      end if;
    end if;
  end process timerA;

-- WRITE REGISTERS
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      TA_LO <= x"ff";
      TA_HI <= x"ff";
      CRA_START   <= '0';
      CRA_PBON    <= '0';
      CRA_OUTMODE <= '0';
      CRA_RUNMODE <= '0';
      CRA_LOAD   <= '0';
      CRA_INMODE <= '0';
      CRA_SPMODE <= '0';
      CRA_TODIN  <= '0';
    elsif rising_edge(PHI2) then
      CRA_LOAD <= '0';
      if CRA_RUNMODE = '1' and TMRA = "0000000000000000" then
        CRA_START <= '0';
      end if;
      if Wr = '1' then 
        case RS is
          when x"4" => TA_LO <= unsigned(DI);
          when x"5" => TA_HI <= unsigned(DI);
          when x"E" => CRA_TODIN   <= DI(7);
                       CRA_SPMODE  <= DI(6);
                       CRA_INMODE  <= DI(5);
                       CRA_LOAD    <= DI(4);
                       CRA_RUNMODE <= DI(3);
                       CRA_OUTMODE <= DI(2);
                       CRA_PBON    <= DI(1);
                       CRA_START   <= DI(0);
          when others => null;
        end case;
        if RS = x"5" and CRA_START = '0' then
          CRA_LOAD <= '1';
        end if;
      end if;
    end if;
  end process;


-- READ REGISTER
  DO <= data when read_flag = '1' else (others => 'Z');
  process (PHI2,RES_N) is
  begin
    if rising_edge(PHI2) then
      read_flag <= '0';
      if Rd = '1' then
        case RS is
          when x"4" => data <= std_logic_vector(TMRA(7 downto 0));  read_flag <= '1';
          when x"5" => data <= std_logic_vector(TMRA(15 downto 8)); read_flag <= '1';
          when x"E" => data <= (
                                 CRA_TODIN   &
                                 CRA_SPMODE  &
                                 CRA_INMODE  &
                                 '0'         &
                                 CRA_RUNMODE &
                                 CRA_OUTMODE &
                                 CRA_PBON    &
                                 CRA_START  ); read_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;

end architecture;


-- ----------------------
-- Timer B
-- ----------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity timerB is
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
-- INPUTS
    CNT     : in  std_logic; -- counter
    TMRA_UNDERFLOW : in std_logic; -- underflow pulses from timer A.
-- OUTPUTS
    TMR_OUT_N      : out std_logic; -- timer B output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer B output on PB7 else PB7 is I/O
    IRQ            : out std_logic
  );
end entity timerB;

architecture rtl of timerB is
-- REGISTERS
  signal TB_LO       : unsigned(7 downto 0); -- TMR LATCH LOAD VALUE LO
  signal TB_HI       : unsigned(7 downto 0); -- TMR LATCH LOAD VALUE HI
  signal CRB_START   : std_logic; -- 1=start TMRB, 0=Stop TMRB
  signal CRB_PBON    : std_logic; -- 1=PB7 TMRB output, 0=PB7 I/O
  signal CRB_OUTMODE : std_logic; -- 1=toggle, 0=pulse
  signal CRB_RUNMODE : std_logic; -- 1=oneshot, 0=continuous
  signal CRB_LOAD    : std_logic; -- 1=Force Load (strobe)
  signal CRB_INMODE  : std_logic_vector(1 downto 0); -- "00" = Count PHI2
                                                     -- "01" = Count CNT rising edges
                                                     -- "10" = Count TMRA underflows
                                                     -- "11" = Count TMRA underflows
                                                     --        while CNT is high
  signal CRB_ALARM   : std_logic; -- 1=Writing to TOD registers sets ALARM
                                  -- 0=Writing to TOD registers sets TOD clock
  signal TMRB        : unsigned(15 downto 0); -- read only timer counter
-- OTHER
  signal TMRBCLOCK   : std_logic;
  signal TMROUT_N    : std_logic;
-- flags and other data
  signal underflow_flag : std_logic;
  signal data      : std_logic_vector(7 downto 0); -- data for DO
  signal read_flag : std_logic; -- tristate control of DO
  signal mydebug : std_logic;

begin

TMR_OUT_N <= TMROUT_N;
PB_ON_EN <= CRB_PBON;
IRQ <= underflow_flag;

  timeroutput: process (RES_N,underflow_flag) is
  begin
    if RES_N = '0' then 
      TMROUT_N <= '1';
    elsif underflow_flag = '1' then
      TMROUT_N <= not TMROUT_N;
    elsif CRB_OUTMODE = '0' then
      TMROUT_N <= '1';
    end if;       
  end process;


-- TIMER CLOCK
  with CRB_INMODE select
      TMRBCLOCK <= PHI2                   when "00",
                   CNT                    when "01",
                   TMRA_UNDERFLOW         when "10",
                   TMRA_UNDERFLOW and CNT when "11",
                   '0' when others;

-- TIMER
  timerB: process (TMRBCLOCK,RES_N,CRB_LOAD) is
    variable TMR : unsigned(15 downto 0);
  begin
    if RES_N = '0' then
      TMRB <= x"ffff";
      underflow_flag <= '0';
    elsif CRB_LOAD = '1' then
      TMRB <= TB_HI & TB_LO;
    elsif rising_edge(TMRBCLOCK) then
        underflow_flag <= '0';
      if TMRB = "0000000000000000" and CRB_START = '1' then
        underflow_flag <= '1';
        TMRB <= TB_HI & TB_LO;
      elsif CRB_START = '1' then
          TMR := TMRB;
          TMR := TMR - 1;
          TMRB <= TMR;
      end if;
    end if;
  end process timerB;

-- WRITE REGISTERS
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      TB_LO <= x"ff";
      TB_HI <= x"ff";
      CRB_START   <= '0';
      CRB_PBON    <= '0';
      CRB_OUTMODE <= '0';
      CRB_RUNMODE <= '0';
      CRB_LOAD   <= '0';
      CRB_INMODE <= "00";
      CRB_ALARM  <= '0';
    elsif rising_edge(PHI2) then
      CRB_LOAD <= '0';
      if CRB_RUNMODE = '1' and TMRB = "0000000000000000" then
        CRB_START <= '0';
      end if;
      if Wr = '1' then 
        case RS is
          when x"6" => TB_LO <= unsigned(DI);
          when x"7" => TB_HI <= unsigned(DI);
          when x"F" => CRB_ALARM     <= DI(7);
                       CRB_INMODE(1) <= DI(6);
                       CRB_INMODE(0) <= DI(5);
                       CRB_LOAD      <= DI(4);
                       CRB_RUNMODE   <= DI(3);
                       CRB_OUTMODE   <= DI(2);
                       CRB_PBON      <= DI(1);
                       CRB_START     <= DI(0);
          when others => null;
        end case;
        if RS = x"7" and CRB_START = '0' then
          CRB_LOAD <= '1';
        end if;
      end if;
    end if;
  end process;


-- READ REGISTER
  DO <= data when read_flag = '1' else (others => 'Z');
  process (PHI2,RES_N) is
  begin
    if rising_edge(PHI2) then
      read_flag <= '0';
      if Rd = '1' then
        case RS is
          when x"6" => data <= std_logic_vector(TMRB(7 downto 0));  read_flag <= '1';
          when x"7" => data <= std_logic_vector(TMRB(15 downto 8)); read_flag <= '1';
          when x"F" => data <= (
                                 CRB_ALARM   &
                                 CRB_INMODE  &
                                 '0'         &
                                 CRB_RUNMODE &
                                 CRB_OUTMODE &
                                 CRB_PBON    &
                                 CRB_START  ); read_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;

end architecture;

