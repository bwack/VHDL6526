library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
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
    CNT     : in std_logic -- in or out depending on input or output mode.
  );
end entity;

architecture rtl of SerialPort is
-- REGISTERS
  signal SDR : std_logic_vector(7 downto 0); -- Serial Data Register
  signal SR  : std_logic_vector(7 downto 0); -- shift register
  signal SR_OUT : std_logic; -- SR output register
  signal data      : std_logic_vector(7 downto 0); -- data for DO
-- CONTROL
  signal CNT_old, CNT_rising, CNT_falling : std_logic;
  signal sdr_loaded, loadsreg, shift_in, shift_out, interrupt : std_logic;
  type state_t is (START, WAIT_CNT_FALLING, WAIT_CNT_RISING, DUMP_SHIFT_REGISTER);
  signal present_state, next_state : state_t;
  signal read_flag, write_flag, timed, dec, start_timer, dumpsr : std_logic;
--  signal cnt_pulse : std_logic;
begin
  SP <= SR_OUT when CRA_SPMODE = '1' else 'Z';
  IRQ_N <= '0';

-- synchronizing CNT and creating a pulses for the rising and falling edges.
  process(PHI2) is
  begin
    if rising_edge(PHI2) then
       CNT_rising  <= '0';
       CNT_falling <= '0';
       CNT_old <= CNT;
       if CNT_old = '0' and CNT = '1' then
         CNT_rising <= '1';
       elsif CNT_old = '1' and CNT = '0' then
         CNT_falling <= '1';
       end if;
    end if;
  end process;

  sdrload: process(PHI2) is
  begin
    if RES_N = '0' then
      sdr_loaded <= '0';
    elsif rising_edge(PHI2) then
      if write_flag = '1' then
        sdr_loaded <= '1';
      elsif loadsreg = '1' then
        sdr_loaded <= '0';
      end if;
    end if;
  end process;

-- 8 cnt pulses timer
  timeder: process(PHI2) is
    variable count : integer;
  begin
    if RES_N = '0' then
      count := 7;
      timed <= '1';
    elsif rising_edge(PHI2) then
      if start_timer = '1' then
         count := 7;
         timed <= '0';
      elsif dec = '1' then
        if count > 0 then
          count := count - 1;
        else
          timed <= '1';
        end if;
      end if;
    end if;
  end process timeder;

  seq: process(RES_N,PHI2) is
  begin
    if RES_N = '0' then
      present_state <= START;
    elsif rising_edge(PHI2) then
      present_state <= next_state;
    end if;
  end process seq;

  com: process(present_state,CRA_SPMODE,sdr_loaded,timed,CNT_falling,CNT_rising) is
  begin
    loadsreg <= '0';
    shift_out <= '0';
    shift_in  <= '0';
    dec <= '0';
    start_timer <= '0';
    interrupt <= '0';
    dumpsr <= '0';
    case present_state is

      when START => 
        if CRA_SPMODE = '1' then
          if sdr_loaded ='1' then
            next_state <= WAIT_CNT_FALLING;
            loadsreg <= '1';    -- mealy output
            start_timer <= '1'; -- mealy output
          else
            next_state <= START;
          end if;
        else
          start_timer <= '1';
          next_state <= WAIT_CNT_FALLING;
        end if;

      when WAIT_CNT_FALLING =>
        if timed = '1' then
          if CRA_SPMODE = '1' then
            interrupt <= '1';
            next_state <= START;
          else
            next_state <= DUMP_SHIFT_REGISTER;
          end if;          
        else
          if CNT_falling = '1' then
            shift_out <= '1';
            next_state <= WAIT_CNT_RISING;
          else
            next_state <= WAIT_CNT_FALLING;
          end if;
        end if;

      when WAIT_CNT_RISING =>
        if timed = '1' then
          next_state <= WAIT_CNT_FALLING;
        else
          if CNT_rising = '1' then
            shift_in <= '1';
            dec <= '1';
            next_state <= WAIT_CNT_FALLING;
          else
            next_state <= WAIT_CNT_RISING;
          end if;
        end if;

      when DUMP_SHIFT_REGISTER =>
        dumpsr <= '1';
        interrupt <= '1';
        next_state <= START;

    end case;    
  end process com;

  process(PHI2) is
  begin
    if RES_N = '0' then
      SR <= "00000000";
    elsif rising_edge(PHI2) then
      if shift_in = '1' then
        SR(0) <= SP;
        SR(1) <= SR(0);
        SR(2) <= SR(1);
        SR(3) <= SR(2);
        SR(4) <= SR(3);
        SR(5) <= SR(4);
        SR(6) <= SR(5);
        SR(7) <= SR(6);
      elsif shift_out = '1' then
        SR_OUT <= SR(7);       
      elsif loadsreg = '1' then
        SR <= SDR;
      end if;
    end if;
  end process;

-- WRITE REGISTERS
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      SDR <= x"00";
    elsif falling_edge(PHI2) then
      write_flag <= '0';
      if Wr = '1' then
        case RS is
          when x"C"   => SDR <= DI; write_flag <= '1';
          when others => null;
        end case;
      elsif dumpsr = '1' then
        SDR <= SR;
      end if;
    end if;
  end process;

  DO <= data when read_flag = '1' else (others => 'Z');
-- READ REGISTERS
  process (PHI2,RES_N) is
  begin
    if falling_edge(PHI2) then
      read_flag <= '0';
      if Rd = '1' then
        case RS is
          when x"C"   => data <= DI; read_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;

end architecture rtl;