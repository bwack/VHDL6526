library ieee;
use ieee.std_logic_1164.all;

entity tb_timerA is
-- empty
end tb_timerA;

architecture behaviour of tb_timerA is
  component timerA is
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
    TMR_OUT_N     : out std_logic; -- timer output to PORTB
    TMR_UNDERFLOW : out std_logic; -- timer A underflow pulses for timer B.
    PB_ON_EN      : out std_logic; -- enable TMR_OUT_N on PB6 else PB6 is I/O
    IRQ           : out std_logic
  );
  end component timerA;

  signal PHI2, RES_N, Rd, Wr, CNT, IRQ : std_logic;
  signal DI, DO : std_logic_vector(7 downto 0);
  signal RS : std_logic_Vector(3 downto 0);
  signal TMR_OUT_N, TMR_UNDERFLOW, PB_ON_EN : std_logic;
  constant HALFPERIOD : time := 500 ns;
begin
  UUT: entity work.timerA(rtl)
    port map (
      PHI2 => PHI2, DI => DI, DO => DO, RS => RS, RES_N => RES_N, Rd => Rd, Wr => Wr,
      CNT => CNT, 
      TMR_OUT_N => TMR_OUT_N, TMR_UNDERFLOW => TMR_UNDERFLOW,
      PB_ON_EN  => PB_ON_EN,   IRQ => IRQ
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
    wait for 1300 ns;
    CNT <= '1';
    wait for 1300 ns;
  end process P_CNT_0;

  process
  begin
    res_n <= '0';
    Wr <= '0';
    Rd <= '0';
    wait for HALFPERIOD*3;
    res_n <= '1';
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"4";
    DI <= "00001110";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000001";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*125;
    Wr <= '1';
    RS <= x"4";
    DI <= "00000011";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*125;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000101";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*250;
    Wr <= '1';
    RS <= x"5";
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*55;
    Wr <= '1';
    RS <= x"E";
    DI <= "00001011";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait;
  end process;


--  res_n  <= '1', '0' after 1000 ns, '1' after 2000 ns;
--
--  DO <= "ZZZZZZZZ";
--  Wr <= '0', '1' after  2.5 us, '0' after  3 us,
--             '1' after  3.5 us, '0' after  4 us,
--             '1' after  4.5 us, '0' after  5 us,
--             '1' after  5.5 us, '0' after  6 us,
--             '1' after  10.5 us, '0' after  11 us,
--             '1' after  19.5 us, '0' after  20 us;
--  Rd <= '0', '1' after 12.5 us, '0' after 13 us,
--             '1' after 13.5 us, '0' after 14 us,
--             '1' after 14.5 us, '0' after 15 us,
--             '1' after 20.5 us, '0' after 21 us,
--             '1' after 21.5 us, '0' after 22 us,
--             '1' after 22.5 us, '0' after 23 us,
--             '1' after 23.5 us, '0' after 24 us;



  --RS <= "ZZZZ", "0100" after  2 us, "0101" after  4 us, "1110" after  5 us, 
  --              "0100" after 12 us, "0101" after 13 us, "1110" after 14 us, "ZZZZ" after 15 us,
  --              "1110" after 19 us, "0100" after 20 us;
  --DI <= "00000000", "00000010" after  2 us, "00000011" after  3 us, "00000000" after  4 us, "00011101" after 5 us,                  "00001001" after 10 us, "00001001" after 19 us;
end architecture behaviour;


