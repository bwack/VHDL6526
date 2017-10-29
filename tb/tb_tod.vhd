library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity tb_tod is
end entity;

architecture beh1 of tb_tod is
  component tod is
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
    CRB_ALARM : in std_logic;
-- outputs
    INT       : out std_logic -- interrupt on alarm
  );
  end component tod;
  signal PHI2, RES_N, Rd, Wr : std_logic;
  signal DI, DO              : std_logic_vector(7 downto 0);
  signal RS                  : std_logic_Vector(3 downto 0);
  signal CRA_TODIN, CRB_ALARM, TODIN, INT : std_logic;
  constant HALFPERIOD : time := 500 ns ;
begin

  TOD_0: entity work.tod
  port map (
    PHI2=>PHI2, DI=>DI, DO=>DO, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
    TODIN=>TODIN, CRA_TODIN=>CRA_TODIN, CRB_ALARM=>CRB_ALARM, INT=>INT
  );

CRA_TODIN <= '0';


P_CLK_0: process
  begin
    PHI2 <= '1';
    wait for HALFPERIOD;
    PHI2 <= '0';
    wait for HALFPERIOD;    
  end process P_CLK_0;

TOD_PIN_0: process
  variable todtime : time;
  begin
    wait for 10 us;
    if CRA_TODIN = '0' then
      todtime := 8.333333333 ms;
    else
      todtime := 10 ms;
    end if;
    loop
      TODIN <= '1'; 
      wait for todtime;
      TODIN <= '0'; 
      wait for todtime;
    end loop;
  end process TOD_PIN_0;


  process
  begin
-- simple start stop test

    res_n <= '0'; Wr <= '0'; Rd <= '0'; CRB_ALARM <= '0';
    -- SP <= '1';
    wait for HALFPERIOD*2;
    res_n <= '1';
    Wr <= '1';
    RS <= x"D";             -- Interrupt
    DI <= "10011110";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00000111";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*10;
    Wr <= '1';
    Rs <= x"B";
    DI <= "10000000";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*4;
    Wr <= '1';
    Rs <= x"A";
    DI <= x"59";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*4;
    Wr <= '1';
    Rs <= x"9";
    DI <= x"59";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*4;
    Wr <= '1';
    Rs <= x"8";
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*180000;
    Rd <= '1'; Rs <= x"B";
    wait for HALFPERIOD*2;
    Rd <= '0';
    wait for HALFPERIOD*2*200000;
    Rd <= '1'; Rs <= x"A";
    wait for HALFPERIOD*2*2;
    Rd <= '0';
    wait for HALFPERIOD*2*10000;
    Rd <= '1'; Rs <= x"9";
    wait for HALFPERIOD*2;
    Rd <= '0';
    wait for HALFPERIOD*2*10000;
    Rd <= '1'; Rs <= x"8";
    wait for HALFPERIOD*2;
    Rd <= '0';
    wait for HALFPERIOD*2*200000;
    CRB_ALARM <= '1'; Wr <= '1'; Rs <= x"8"; DI <= "00001000";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2;
    Wr <= '1'; Rs <= x"B"; DI <= "10000001";
    wait for HALFPERIOD*2;
    Wr <= '0'; CRB_ALARM <= '0';
    wait;
  end process;
end architecture beh1;

