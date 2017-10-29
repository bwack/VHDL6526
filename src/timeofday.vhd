library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity timeofday is
  port ( 
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DB      : inout std_logic_vector(7 downto 0); -- data in
    RS      : in  std_logic_vector(3 downto 0); -- address - register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
--
    TOD       : in std_logic; -- 50 or 60 Hz timer input.
    CRA_TODIN : in std_logic;
    CRB_ALARM : in std_logic; -- Writing to TOD registers: 1=sets ALARM, 0=sets time
    INT       : out std_logic -- interrupt on alarm
  );
end entity timeofday;

architecture rtl of timeofday is
  signal DI, data      : std_logic_vector(7 downto 0);
  signal enable : std_logic;
-- Please excuse the daft code. These are BCD formatted.
  signal THS, A_THS : unsigned(3 downto 0); -- Tenths of seconds
  signal SH,  A_SH  : unsigned(2 downto 0); -- Seconds, high bits
  signal SL,  A_SL  : unsigned(3 downto 0); -- Seconds, low bits
  signal MH,  A_MH  : unsigned(2 downto 0); -- Minutes, high bits
  signal ML,  A_ML  : unsigned(3 downto 0); -- Minutes, low bits
  signal HH,  A_HH  : std_logic;                    -- Hours high bit
  signal HL,  A_HL  : unsigned(3 downto 0); -- Hours, low bits
  signal PM,  A_PM  : std_logic;                    -- PM=1: PM, PM=0: AM or rather day or night
-- PM is treated as day or night, where hours are 0-11 no matter if its am or pm.
-- the correct format is converted back on the output latches. Internally it doesn't make sense.
-- other
  signal tod_0, tod_int, tod_pulse, tick_strobe : std_logic; -- synchronize tod to phi2
  signal latch_outputs, tod_run, write_flag, read_flag, alarm, alarm0: std_logic;
  signal TOD_10THS_L, TOD_SEC_L, TOD_MIN_L, TOD_HR_L : std_logic_vector(7 downto 0);
begin

  alarm <= '1' when THS=A_THS and SH=A_SH and SL=A_SL and MH=A_MH and ML=A_ML and HH=A_HH and HL=A_HL and PM=A_PM else '0';
  enable <= '1' when Rd = '1' and (RS=x"8" or RS=x"9" or RS=x"A" or RS=x"B") else '0';
  DB <= data when enable = '1' else (others => 'Z');
  DI <= DB;

  interruptgen: process(PHI2)
  begin
    if rising_edge(PHI2) then
      INT <= '0';
      alarm0 <= alarm;
      if alarm = '1' and alarm0 = '0' then
         INT <= '1';
      end if;
    end if;
  end process;

  tod_ticker_0: process(PHI2)
  variable count : integer := 0;
  begin
    if rising_edge(PHI2) then
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

-- TOD LATCH
  tod_latch: process(PHI2,RES_N)
  begin
    if RES_N = '0' then
      TOD_10THS_L <= x"00";
      TOD_SEC_L   <= x"00";
      TOD_MIN_L   <= x"00";
      TOD_HR_L    <= x"00";
    elsif rising_edge(PHI2) then
      if latch_outputs = '0' then
        TOD_10THS_L <= "0000" & std_logic_vector(THS);
        TOD_SEC_L   <= '0' & std_logic_vector(SH) & std_logic_vector(SL);
        TOD_MIN_L   <= '0' & std_logic_vector(MH) & std_logic_vector(ML);
        if PM = '1' and HL = 0 then
          TOD_HR_L    <= PM & "00" & '1' & x"2"; -- special case
        else
          TOD_HR_L    <= PM & "00" & HH & std_logic_vector(HL);
        end if;
      end if;
    end if;
  end process tod_latch;

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
      THS <= "0000";   A_THS <= "0000";
      SH <= "000";     A_SH <= "000";
      SL <= "0000";    A_SL <= "0000";
      MH <= "000";     A_MH <= "000";
      ML <= "0000";    A_ML <= "0000";
      PM <= '0';       A_PM <= '0';
      HH <= '0';       A_HH <= '0';
      HL <= "0000";    A_HL <= "0000";
      tod_run <= '0';
    elsif falling_edge(PHI2) then
      write_flag <= '0';
      if Wr = '1' then
        if CRB_ALARM = '0' then
          case RS is
            when x"8"   => THS <= unsigned(DI(3 downto 0));
                           write_flag <= '1';
                           tod_run <= '1';
            when x"9"   => SH <= unsigned(DI(6 downto 4));
                           SL <= unsigned(DI(3 downto 0));
                           write_flag <= '1';
            when x"A"   => MH <= unsigned(DI(6 downto 4));
                           ML <= unsigned(DI(3 downto 0));
                           write_flag <= '1';
            when x"B"   => PM <= DI(7);
                           HH <= DI(4);
                           HL <= unsigned(DI(3 downto 0));
                           write_flag <= '1';
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
        end if;
        if hrsh = '0' and hrsl = 10 then -- the daft AM-PM format. treating 12pm as 0pm.
            hrsl := 0;
            hrsh := '1';
        end if;
        if hrsh = '1' and hrsl = 2 then
            hrsl := 0;
            hrsh := '0';
            PM <= not PM;
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
    elsif rising_edge(PHI2) then
      read_flag  <= '0';
      if Rd = '1' then
        case RS is
          when x"8" => data <= TOD_10THS_L; read_flag <= '1'; latch_outputs <= '0';
          when x"9" => data <= TOD_SEC_L;   read_flag <= '1'; 
          when x"A" => data <= TOD_MIN_L;   read_flag <= '1'; 
          when x"B" => data <= TOD_HR_L;    read_flag <= '1'; latch_outputs <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;

end architecture rtl;