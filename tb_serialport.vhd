library ieee;
use ieee.std_logic_1164.all;

entity tb_SerialPort is
-- empty
end tb_SerialPort;

architecture behaviour of tb_SerialPort is
  component SerialPort is
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
  end component;

  signal PHI2, RES_N, Rd, Wr : std_logic;
  signal DI, DO              : std_logic_vector(7 downto 0);
  signal RS                  : std_logic_Vector(3 downto 0);
  signal CRA_SPMODE, IRQ_N, SP, CNT : std_logic;
  constant HALFPERIOD : time := 500 ns;
begin

  UUT_SERIAL: entity work.SerialPort(rtl)
    port map (
      PHI2=>PHI2, DI=>DI, DO=>DO, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
      CNT => CNT, CRA_SPMODE => CRA_SPMODE, IRQ_N => IRQ_N,
      SP => SP
    );

P_CLK_0: process
  begin
    PHI2 <= '0';
    wait for HALFPERIOD;
    PHI2 <= '1';
    wait for HALFPERIOD;    
  end process P_CLK_0;

-- an alternative and slower cnt signal than the PHI2 for the timer tick input
P_CNT_0: process
  begin
    CNT <= '0';
    wait for 11.3 us;
    CNT <= '1';
    wait for 11.3 us;
  end process P_CNT_0;

  
  process
  begin
-- simple start stop test
    res_n <= '0';
    Wr <= '0';
    Rd <= '0';
    -- SP <= '1';
    CRA_SPMODE <= '1';
    wait for HALFPERIOD*3;
    res_n <= '1';
    wait for HALFPERIOD*2*20;
    Wr <= '1';
    RS <= x"C";
    DI <= "00000001";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*250;
    Wr <= '1';
    RS <= x"C";
    DI <= "00000001";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*100;
    Wr <= '1';
    RS <= x"C";
    DI <= "00000001";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait;
  end process;
end architecture behaviour;


