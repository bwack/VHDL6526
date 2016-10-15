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
-- DATAFLOW
  signal DFF : std_logic_vector(7 downto 0);
  signal data      : std_logic_vector(7 downto 0); -- data for DO
-- CONTROL
  signal CNT_old, CNT_flag : std_logic;
  signal sdr_loaded, loadsreg, shift_f : std_logic;
  type state_t is (START, INIT, WAITCNT, SHIFT);
  signal present_state, next_state : state_t;
  signal read_flag, write_flag, timed, dec : std_logic;
begin
  SP <= DFF(7);
  IRQ_N <= '0';
  process(PHI2) is
  begin
    if rising_edge(PHI2) then
       CNT_flag <= '0';
       CNT_old <= CNT;
       if CNT_old = '0' and CNT = '1' then
         CNT_flag <= '1';
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


  timeder: process(PHI2) is
    variable count : integer;
  begin
    if RES_N = '0' then
      count := 7;
      timed <= '1';
    elsif rising_edge(PHI2) then
      if loadsreg = '1' then
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

  com: process(present_state,sdr_loaded,CNT_flag,shift_f) is
  begin
    loadsreg <= '0';
    shift_f <= '0';
    dec <= '0';
    case present_state is
      when START =>
        if sdr_loaded = '1' then
          next_state <= INIT;
        else
          next_state <= START;
        end if;
      when INIT =>
        loadsreg <= '1';
        next_state <= WAITCNT;
      when WAITCNT =>
        loadsreg <= '0';
        if timed = '1' then
           next_state <= START;
        elsif CNT_flag = '1' then
          next_state <= SHIFT;
        else
          next_state <= WAITCNT;
        end if;
      when SHIFT =>
        shift_f <= '1';
        dec <= '1';
        next_state <= WAITCNT;
    end case;    
  end process com;

  process(PHI2) is
  begin
    if RES_N = '0' then
      DFF <= "00000000";
    elsif rising_edge(PHI2) then
      if shift_f = '1' then
        DFF(0) <= SP;
        DFF(1) <= DFF(0);
        DFF(2) <= DFF(1);
        DFF(3) <= DFF(2);
        DFF(4) <= DFF(3);
        DFF(5) <= DFF(4);
        DFF(6) <= DFF(5);
        DFF(7) <= DFF(6);
      elsif loadsreg = '1' then
        DFF <= SDR;
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