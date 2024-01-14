library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

-- Interval Timer: 16 bit read-only Timer Counter
-- The timer decrements.

entity timerA is

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
end entity timerA;

architecture rtl of timerA is

-- REGISTERS
  signal TA_LO       : std_logic_vector(7 downto 0); -- TMR LATCH LOAD VALUE LO
  signal TA_HI       : std_logic_vector(7 downto 0); -- TMR LATCH LOAD VALUE HI
  signal CRA_START   : std_logic; -- 1=start TMRA, 0=Stop TMRA
  signal CRA_PBON    : std_logic; -- 1=PB6 TMRA output, 0=PB6 I/O
  signal CRA_OUTMODE : std_logic; -- 1=toggle, 0=pulse
  signal CRA_RUNMODE : std_logic; -- 1=oneshot, 0=continuous
  signal CRA_LOAD    : std_logic; -- 1=Force Load (strobe)
  signal CRA_INMODE  : std_logic; -- 1=Count on rising CNT, 0=Count PHI2
  signal CRA_SPMODE  : std_logic; -- 1=Serial Port output, 0=SP input (req ext shift clock)
  signal CRA_TODIN   : std_logic; -- 1=50Hz clock on TOD pin, 0=60Hz.
  signal CRA_REG     : std_logic_vector(7 downto 0); -- alias for CRA
  signal TMRA        : std_logic_vector(15 downto 0); -- read only timer counter
  signal TMRA_2      : std_logic_vector(15 downto 0); -- read only timer counter
-- OTHER
  signal TICK        : std_logic;
  signal CNTSYNCED   : std_logic;
  signal CNTSYNCED2  : std_logic;
  signal TMRTOGGLE   : std_logic;
-- flags and other data
  signal underflow_flag : std_logic;
  signal old_underflow  : std_logic;



begin

  --TMR_OUT        <= (underflow_flag and not old_underflow) when CRA_OUTMODE = '0'
  --                  else TMRTOGGLE;
  TMR_OUT <= TMRTOGGLE;
  TMRA_UNDERFLOW <= underflow_flag and not old_underflow;
  PB_ON_EN       <= CRA_PBON;
  --CNT            <= TMRTOGGLE when CRA_SPMODE = '1' and TMRTOGGLE = '0' else 'H';
  INT_TMRA       <= underflow_flag and not old_underflow;
  SPMODE         <= CRA_SPMODE;
  TODIN          <= CRA_TODIN;

  DO <= TMRA_2( 7 downto 0) when RS = x"4" else
        TMRA_2(15 downto 8) when RS = x"5" else
        CRA_REG when RS = x"E" else
        (others=>'0');

  timertoggle: process(PHI2,RES_N,CRA_START,underflow_flag)
    variable old_start : std_logic ;
  begin
    if RES_N = '0' then
      --TMRTOGGLE <= '1';
      TMRTOGGLE <= '1';
    elsif CRA_START = '1' and old_start = '0' then
      --TMRTOGGLE <= '1';
      TMRTOGGLE <= '1';
    elsif rising_edge(phi2) then
      if CRA_RUNMODE = '0' then
        TMRTOGGLE <= '0';
	if underflow_flag = '1' and old_underflow = '0' then
	  TMRTOGGLE <= '1';
	end if;
      elsif CRA_RUNMODE = '1' then
	if underflow_flag = '1' and old_underflow = '0' then
          TMRTOGGLE <= not TMRTOGGLE;
        end if;      
      end if;
--      if underflow_flag = '1' then
--        TMRTOGGLE <= not TMRTOGGLE;
--      end if;
    end if;
    old_start := CRA_START;
  end process;

  timeroutput: process (PHI2,RES_N) is
  begin
    if rising_edge(PHI2) then
      old_underflow <= underflow_flag;
    end if;      
  end process;

-- Resyncing CNT is important to maintain one-cycle length underflow pulses.
  cntsync: process (PHI2) is
  begin
    if rising_edge(PHI2) then
      CNTSYNCED <= CNT;
      CNTSYNCED2 <= CNTSYNCED;
    end if;      
  end process;

-- TIMER CLOCK
    --TMRCLOCK <= PHI2 when CRA_INMODE = '0' else CNTSYNCED;

-- TIMER
  timerA: process (PHI2,RES_N,CRA_LOAD,TA_HI,TA_LO) is
  begin
    if RES_N = '0' then
      TMRA <= x"ffff";
      underflow_flag <= '0';
  --elsif CRA_LOAD = '1' then
  --    TMRA <= TA_HI & TA_LO;
    elsif falling_edge(PHI2) then
      underflow_flag <= '0';
      TMRA_2 <= TMRA;
      if TMRA = x"0000" and CRA_START = '1' then
        underflow_flag <= '1';
        TMRA <= TA_HI & TA_LO;
      elsif CRA_LOAD = '1' then
        TMRA <= TA_HI & TA_LO;
      elsif CRA_START = '1' then
        if CRA_INMODE = '0' then
          TMRA <= std_logic_vector(unsigned(TMRA) - 1);
        elsif CNTSYNCED = '1' and CNTSYNCED2 = '0' then
          TMRA <= std_logic_vector(unsigned(TMRA) - 1);
        end if;
      end if;
    end if;
  end process timerA;

  CRA_REG <= ( CRA_TODIN   &
               CRA_SPMODE  &
               CRA_INMODE  &
               '0'         &
               CRA_RUNMODE &
               CRA_OUTMODE &
               CRA_PBON    &
               CRA_START  );
  
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
    elsif falling_edge(PHI2) then
      CRA_LOAD <= '0';
      if CRA_RUNMODE = '1' and TMRA = x"0000" then
        CRA_START <= '0';
      end if;
      if Wr = '1' then 
        case RS is
          when x"4" => TA_LO <= DI;
          when x"5" => TA_HI <= DI;
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


end architecture;
