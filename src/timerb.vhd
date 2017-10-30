library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity timerB is
-- Interval Timer: 16 bit read-only Timer Counter
-- The timer decrements.
  port ( 
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0);
    DO      : out std_logic_vector(7 downto 0);
    RS      : in  std_logic_vector(3 downto 0); -- address - register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS
    CNT            : in  std_logic; -- counter
    TMRA_UNDERFLOW : in std_logic; -- underflow pulses from timer A.
-- OUTPUTS
    TMR_OUT        : out std_logic; -- timer B output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer B output on PB7 else PB7 is I/O
    ALARM          : out std_logic; -- CRB_ALARM forwarding to tod
    INT            : out std_logic
  );
end entity timerB;

architecture rtl of timerB is
  signal data_out    : std_logic_vector(7 downto 0);
  signal enable : std_logic;
-- REGISTERS
  signal TB_LO   : std_logic_vector(7 downto 0); -- TMR LATCH LOAD VALUE LO
  signal TB_HI   : std_logic_vector(7 downto 0); -- TMR LATCH LOAD VALUE HI
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
  signal CRB_REG     : std_logic_vector(7 downto 0); -- alias for CRB
  signal TMRB        : std_logic_vector(15 downto 0); -- read only timer counter
-- OTHER
  signal TMRCLOCK    : std_logic;
  signal CNTSYNCED   : std_logic; -- synced to phi2
  signal TMRTOGGLE   : std_logic;
-- flags and other data
  signal underflow_flag : std_logic;
  signal old_underflow  : std_logic;
  --signal old_start      : std_logic;
  signal read_flag : std_logic; -- tristate control of DO
  signal mydebug : std_logic;

begin 

  TMR_OUT  <= (underflow_flag and not old_underflow) when CRB_OUTMODE = '0'
              else TMRTOGGLE;
  PB_ON_EN <= CRB_PBON;
  INT      <= underflow_flag and not old_underflow;
  ALARM    <= CRB_ALARM;

  enable <= '1' when Rd = '1' and (RS=x"6" or RS=x"7" or RS=x"F") else '0';
  DO <= data_out;
  --DI <= DB;

  timertoggle: process(PHI2,RES_N,underflow_flag)
    variable old_start : std_logic ;
  begin
    if RES_N = '0' then
      TMRTOGGLE <= '0';
    elsif rising_edge(phi2) then
      if CRB_START = '1' and old_start = '0' then
        TMRTOGGLE <= '1';
      elsif underflow_flag = '1' then
        TMRTOGGLE <= not TMRTOGGLE;
      end if;
    end if;
    old_start := CRB_START;
  end process;

  timeroutput: process (PHI2,RES_N) is
  begin
    if rising_edge(PHI2) then
      old_underflow <= underflow_flag;
    end if;      
  end process;

  cntsync: process (PHI2,RES_N) is
  begin
    if rising_edge(PHI2) then
      CNTSYNCED <= CNT;
    end if;      
  end process;


-- TIMER CLOCK
  with CRB_INMODE select
      TMRCLOCK <= PHI2                         when "00",
                  CNTSYNCED                    when "01",
                  TMRA_UNDERFLOW               when "10",
                  TMRA_UNDERFLOW and CNTSYNCED when "11",
                  '0' when others;

-- TIMER
  timerB: process (TMRCLOCK,RES_N,CRB_LOAD) is
  begin
    if RES_N = '0' then
      TMRB <= x"ffff";
      underflow_flag <= '0';
    elsif rising_edge(TMRCLOCK) then
      if CRB_LOAD = '1' then
        TMRB <= TB_HI & TB_LO;
      else
          underflow_flag <= '0';
        if TMRB = "0000000000000000" and CRB_START = '1' then
          underflow_flag <= '1';
          TMRB <= TB_HI & TB_LO;
        elsif CRB_START = '1' then
            TMRB <= std_logic_vector(unsigned(TMRB) - 1);
        end if;
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
    elsif falling_edge(PHI2) then
      CRB_LOAD <= '0';
      if CRB_RUNMODE = '1' and underflow_flag = '1' then
        CRB_START <= '0';
      end if;
      if Wr = '1' then 
        case RS is
          when x"6" => TB_LO <= DI;
          when x"7" => TB_HI <= DI;
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
  process (PHI2,RES_N) is
  begin
    if rising_edge(PHI2) then
      read_flag <= '0';
      if Rd = '1' then
        case RS is
          when x"6" => read_flag <= '1';
          when x"7" => read_flag <= '1';
          when x"F" => read_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;
  
  CRB_REG <= (
                CRB_ALARM   &
                CRB_INMODE  &
                '0'         &
                CRB_RUNMODE &
                CRB_OUTMODE &
                CRB_PBON    &
                CRB_START  );

  with RS select
    data_out <= TMRB( 7 downto 0) when x"6",
                TMRB(15 downto 8) when x"7",
                CRB_REG when x"F",
                (others => '0') when others;
               
  
end architecture;

