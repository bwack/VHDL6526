library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity timeofday is
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
-- for debugging with 7seg display
--    abcdefgdec_n   : out std_logic_vector(7 downto 0);
--    a_n            : out std_logic_vector(3 downto 0)
  );
end entity timeofday;

architecture rtl of timeofday is
  signal data_out   : std_logic_vector(7 downto 0);
-- Please excuse the daft code. These are BCD formatted.
-- signal names are from the datasheet
  signal THS, A_THS : unsigned(3 downto 0); -- Tenths of seconds
  signal SH,  A_SH  : unsigned(2 downto 0); -- Seconds, high bits time and alarm.
  signal SL,  A_SL  : unsigned(3 downto 0); -- Seconds, low bits
  signal MH,  A_MH  : unsigned(2 downto 0); -- Minutes, high bits
  signal ML,  A_ML  : unsigned(3 downto 0); -- Minutes, low bits
  signal HH,  A_HH  : std_logic;            -- Hours high bit
  signal HL,  A_HL  : unsigned(3 downto 0); -- Hours, low bits
  signal PM,  A_PM  : std_logic;            -- PM=1: PM, PM=0: AM or rather day or night
-- PM is treated as day or night, where hours are 0-11 no matter if its am or pm.
-- the correct format is converted back on the output latches. Internally it doesn't make sense.
-- other
  signal tod_0, tod_int, tod_pulse, tick_strobe : std_logic; -- synchronize tod to phi2
  signal latch_outputs, tod_run, write_flag, read_flag, alarm, alarm0: std_logic;
-- standard logic vectors representation of time
  signal TOD_10THS, TOD_SEC, TOD_MIN, TOD_HR : std_logic_vector(7 downto 0);
-- tod write and read latches
  signal TOD_10THS_RL, TOD_SEC_RL, TOD_MIN_RL, TOD_HR_RL : std_logic_vector(7 downto 0);
  signal TOD_10THS_WL, TOD_SEC_WL, TOD_MIN_WL, TOD_HR_WL : std_logic_vector(7 downto 0);
  -- 7 segment
--  signal d0,d1,d2,d3  : std_logic_vector(3 downto 0);
 
begin

--  SEG7CTRL_0: entity work.seg7ctrl(rtl)
--    generic map(3) -- 14 !
--    port map(PHI2,RES_N,d0,d1,d2,d3,abcdefgdec_n,a_n);
--    d0 <= TOD_MIN_WL(3 downto 0);
--    d1 <= TOD_MIN_WL(7 downto 4);
--    d2 <= TOD_MIN_RL(3 downto 0);
--    d3 <= TOD_MIN_RL(7 downto 4);

  alarm <= '1' when THS=A_THS and SH=A_SH and SL=A_SL and MH=A_MH and ML=A_ML and HH=A_HH and HL=A_HL and PM=A_PM else '0';

  interruptgen: process(PHI2)
  begin
    if falling_edge(PHI2) then
      alarm0 <= alarm;
    end if;
  end process;
  INT_TODALARM <= '1' when alarm = '1' and alarm0 = '0' else '0';

  tod_ticker_0: process(PHI2)
  variable count : integer := 0;
  begin
    if falling_edge(PHI2) then
      tod_0 <= TOD;
      tod_int <= tod_0;
      tod_pulse <= '0';
      tick_strobe <= '0';
      if tod_0 = '1' and tod_int = '0' then
        tod_pulse <= '1';
      end if;
      if tod_run = '0' then
        count := 0;
      end if ;
      if tod_pulse = '1' then
        count := count + 1;
        if CRA_TODIN = '1' then -- 50 Hz
          if count = 5 then
            count := 0;
            tick_strobe <= '1';
          end if;
        else
          if count = 6 then -- 60 Hz
            count := 0;
            tick_strobe <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

-- WRITE REGISTERS
  process (PHI2,RES_N) is
    variable ths_v : integer;
    variable sech : integer;
    variable secl : integer;
    variable minh : integer;
    variable minl : integer;
    variable hrsh : std_logic;
    variable hrsl : integer;
  begin
    if RES_N = '0' then
      TOD_10THS_WL <= x"00";
      TOD_SEC_WL   <= x"00";
      TOD_MIN_WL   <= x"00";
      TOD_HR_WL    <= x"00";
      THS <= "0000";   A_THS <= "0000";
      SH <= "000";     A_SH <= "000";
      SL <= "0000";    A_SL <= "0000";
      MH <= "000";     A_MH <= "000";
      ML <= "0000";    A_ML <= "0000";
      PM <= '0';       A_PM <= '0';
      HH <= '0';       A_HH <= '0';
      HL <= x"1";      A_HL <= x"1";
      tod_run <= '1';
    elsif falling_edge(PHI2) then
      write_flag <= '0';
      if Wr = '1' then
        if CRB_ALARM = '0' then
          case RS is
            when x"8"   => TOD_10THS_WL <= DI;
	                   THS <= unsigned(DI(3 downto 0));
                           SH <= unsigned(TOD_SEC_WL(6 downto 4));
                           SL <= unsigned(TOD_SEC_WL(3 downto 0));
	                   MH <= unsigned(TOD_MIN_WL(6 downto 4));
                           ML <= unsigned(TOD_MIN_WL(3 downto 0));
                           HH <= TOD_HR_WL(4);
                           HL <= unsigned(TOD_HR_WL(3 downto 0));
                           PM <= TOD_HR_WL(7);
                           write_flag <= '1';
                           tod_run <= '1';
            when x"9"   => TOD_SEC_WL <= DI;
            when x"A"   => TOD_MIN_WL <= DI;
            when x"B"   =>
	      if DI(4) = '1' and DI(3 downto 0) = x"2" then -- 12 am/pm ?
	        TOD_HR_WL <= not DI(7) & '0' & '0' & DI(4 downto 0);
	      else
	        TOD_HR_WL <= DI(7) & '0' & '0' & DI(4 downto 0);
	      end if;
              tod_run <= '0';
            when others => null;
          end case;
        else
          case RS is
            when x"8"   => A_THS <= unsigned(DI(3 downto 0));
            when x"9"   => A_SH  <= unsigned(DI(6 downto 4));
                           A_SL  <= unsigned(DI(3 downto 0));
            when x"A"   => A_MH  <= unsigned(DI(6 downto 4));
                           A_ML  <= unsigned(DI(3 downto 0));
            when x"B"   => A_PM  <= DI(7);
                           A_HH  <= DI(4);
                           A_HL  <= unsigned(DI(3 downto 0));
            when others => null;
          end case;
        end if;
      elsif tod_run = '1' and tick_strobe = '1' then
        ths_v := to_integer(THS);
        sech  := to_integer(SH);
        secl  := to_integer(SL);
        minh  := to_integer(MH);
        minl  := to_integer(ML);
        hrsh  := HH;
        hrsl  := to_integer(HL);
        ths_v := ths_v + 1;
        if (ths_v=10) then
          ths_v := 0;
          secl := secl + 1;
        end if;
        if secl = 10 then
           secl := 0;
           sech := sech + 1;
        end if;
        if sech = 6 then
          sech := 0;
          minl := minl + 1;
        end if;
        if minl = 10 then
          minl := 0;
          minh := minh + 1;
        end if;
        if minh = 6 then
          minh := 0;
          hrsl := hrsl + 1;
          if hrsh = '1' and hrsl = 2 then -- from 11:59 to 12:00
            PM <= not PM;
          end if;
        end if;
        if hrsh = '0' and hrsl = 10 then -- from 09:59 to 10:00
            hrsl := 0;
            hrsh := '1';
        end if;
        if hrsh = '1' and hrsl = 3 then -- from 12:59 to 01:00
            hrsl := 1;
            hrsh := '0';
        end if;
        THS<= to_unsigned(ths_v,4);
        SH <= to_unsigned(sech,3);
        SL <= to_unsigned(secl,4);
        MH <= to_unsigned(minh,3);
        ML <= to_unsigned(minl,4);
        HH <= hrsh;
        HL <= to_unsigned(hrsl,4);
      else
        if A_HH = '1' and A_HL = 2 and A_PM = '1' then
          A_HH <= '0';
          A_HL <= x"0";
        end if;
      end if;
    end if;
  end process;

-- READ REGISTER
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      latch_outputs <= '0';
      TOD_10THS_RL <= x"00";
      TOD_SEC_RL   <= x"00";
      TOD_MIN_RL   <= x"00";
      TOD_HR_RL    <= x"00";
    elsif falling_edge(PHI2) then
      read_flag  <= '0';
      if Rd = '1' then
        case RS is
          when x"B" =>
	    TOD_10THS_RL <= TOD_10THS;
            TOD_SEC_RL   <= TOD_SEC;
            TOD_MIN_RL   <= TOD_MIN;
            TOD_HR_RL    <= TOD_HR;
          when others => null;
        end case;
      end if;
    end if;
  end process;


  TOD_10THS <= "0000" & std_logic_vector(THS);
  TOD_SEC   <= '0' & std_logic_vector(SH) & std_logic_vector(SL);
  TOD_MIN   <= '0' & std_logic_vector(MH) & std_logic_vector(ML);
  TOD_HR    <= PM & "00" & '1' & x"2" when PM = '1' and HL = 0 else
               PM & "00" & HH  & std_logic_vector(HL);

-- The cpu shall always read hours first.

  DO <= TOD_10THS_RL when RS = x"8" else
        TOD_SEC_RL   when RS = x"9" else
	TOD_MIN_RL   when RS = x"A" else
	TOD_HR       when RS = x"B" else
	(others=>'0');

end architecture rtl;