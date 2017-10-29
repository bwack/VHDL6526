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
    TMR_OUT        : out std_logic; -- timer A output to PORTB
    TMRA_UNDERFLOW : out std_logic; -- timer A underflow pulses for timer B.
    PB_ON_EN       : out std_logic; -- enable timer A output on PB6 else PB6 is I/O
    IRQ            : out std_logic
  );
  end component timerA;

  component timerB is
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
    TMR_OUT        : out std_logic; -- timer B output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer B output on PB7 else PB7 is I/O
    IRQ            : out std_logic
  );
  end component timerB;

  signal PHI2, RES_N, Rd, Wr : std_logic;
  signal DI, DO              : std_logic_vector(7 downto 0);
  signal RS                  : std_logic_Vector(3 downto 0);
  signal TMRA_OUT, TMRB_OUT, TMRA_UNDERFLOW : std_logic;
  signal TMRA_PB_ON_EN, TMRB_PB_ON_EN, CNT, TMRA_IRQ, TMRB_IRQ : std_logic;
  constant HALFPERIOD : time := 500 ns;
begin
  UUT_TMRA: entity work.timerA(rtl)
    port map (
      PHI2=>PHI2, DI=>DI, DO=>DO, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
      CNT => CNT, TMR_OUT => TMRA_OUT, TMRA_UNDERFLOW => TMRA_UNDERFLOW,
      PB_ON_EN => TMRA_PB_ON_EN, IRQ => TMRA_IRQ
    );

  UUT_TMRB: entity work.timerB(rtl)
    port map (
      PHI2=>PHI2, DI=>DI, DO=>DO, RS=>RS, RES_N=>RES_N, Rd=>Rd, Wr=>Wr,
      CNT => CNT, TMRA_UNDERFLOW => TMRA_UNDERFLOW,
      TMR_OUT => TMRB_OUT, PB_ON_EN  => TMRB_PB_ON_EN, IRQ => TMRB_IRQ
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
    wait for HALFPERIOD*3;
    res_n <= '1';
    wait for HALFPERIOD*4;
    Wr <= '1';
    RS <= x"F";
    DI <= "00000001"; -- start B
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000001"; -- start A
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*6;
    Wr <= '1';
    RS <= x"F";
    DI <= "00000000"; -- stop B
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000000"; -- stop A
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*6;


-- test one-shot mode, verify output toggle
    res_n <= '0';
    wait for HALFPERIOD*2;
    res_n <= '1';
    wait for HALFPERIOD*4;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00001010";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";             -- TA_HI (timerA auto loads after this write)
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"6";             -- TB_LO
    DI <= "00001010";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"7";             -- TB_HI (timerB auto loads after this write)
    DI <= "00000000";       -- therefor TB_LO was written before TB_HI
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"F";
    DI <= "00001011"; -- CRB: start, pb-on, pulse, one-shot
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00001011"; -- CRA: same
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*4;
    -- timer still running, do force loads.
    Wr <= '1';
    RS <= x"F";
    DI <= "00011011";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00011011";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*35;
    Wr <= '1';
    RS <= x"F";
    DI <= "00011011";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00011011";
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*25;


-- toggle or single phi2-period pulses on timer underflow
    res_n <= '0';
    wait for HALFPERIOD*2;
    res_n <= '1';
    wait for HALFPERIOD*4;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00000011";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";             -- TA_HI (timerA auto loads after this write)
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"6";             -- TB_LO
    DI <= "00000011";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"7";             -- TB_HI (timerB auto loads after this write)
    DI <= "00000000";       -- therefor TB_LO was written before TB_HI
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"F";
    DI <= "00000011"; -- CRB: start, pb-on, pulse, continuous
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000011"; -- CRA: same
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*15;
    Wr <= '1';
    RS <= x"F";
    DI <= "00000111"; -- CRB: start, pb-on, toggles, continuous
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000111"; -- CRA: same
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*15;

    res_n <= '0';
    wait for HALFPERIOD*2;
    res_n <= '1';
    wait for HALFPERIOD*4;

--  2. TIMER A can count 02 clock pulses
--  => tested ok above

--     or external pulses applied to the CNT pin. (testing B here also)
    res_n <= '0';
    wait for HALFPERIOD*2;
    res_n <= '1';
    wait for HALFPERIOD*4;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00000011";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";             -- TA_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"6";             -- TB_LO
    DI <= "00000011";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"7";             -- TB_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"F";
    DI <= "00100001"; -- CRB: start and count using CNT
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00100001"; -- CRA: same
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*300; -- long one, CNT is slow

--  3. TIMER B can count 02 pulses, external CNT pulses,
--  => tested OK.

--     TIMER B can count TIMER A underflow pulses
    res_n <= '0';
    wait for HALFPERIOD*2;
    res_n <= '1';
    wait for HALFPERIOD*4;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00000010";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";             -- TA_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"6";             -- TB_LO
    DI <= "00000010";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"7";             -- TB_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"F";
    DI <= "01000001"; -- CRB: start TIMER B, count TIMER A underflow pulses
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000001"; -- CRA: start TIMER A.
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*25; -- long one, CNT is slow

--     TIMER A underflow pulses while the CNT pin is held high.
    res_n <= '0';
    wait for HALFPERIOD*2;
    res_n <= '1';
    wait for HALFPERIOD*4;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00000010";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";             -- TA_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"6";             -- TB_LO
    DI <= "00000010";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"7";             -- TB_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"F";
    DI <= "01100001"; -- CRB: start TIMER B, count TIMER A underflow pulses
                      -- when CNT is high.
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000001"; -- CRA: start TIMER A.
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*70; -- long one, CNT is slow

--  4. The timer latch is loaded into the timer on any timer
--     underflow, on a force load or following a write to the high
--     byte of the prescaler while the timer is stopped.
-- => tested correct beh when writing to high byte while timer is stopped.

--  5. If the timer is running, a write to the high byte will load the
--     timer latch, but not reload the counter.
    res_n <= '0';
    wait for HALFPERIOD*2;
    res_n <= '1';
    wait for HALFPERIOD*4;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00000110";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";             -- TA_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"6";             -- TB_LO
    DI <= "00000110";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"7";             -- TB_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"F";
    DI <= "00000001"; -- CRB: start TIMER B
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"E";
    DI <= "00000001"; -- CRA: start TIMER A.
    wait for HALFPERIOD*2;
    Wr <= '0';
    wait for HALFPERIOD*2*10;
    Wr <= '1';
    RS <= x"4";             -- TA_LO
    DI <= "00001110";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"5";             -- TA_HI
    DI <= "00000000";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"6";             -- TB_LO
    DI <= "00001110";
    wait for HALFPERIOD*2;
    Wr <= '1';
    RS <= x"7";             -- TB_HI
    DI <= "00000000";
    wait for HALFPERIOD*2*10;

    res_n <= '0';
    wait for HALFPERIOD*2;
    res_n <= '1';
    wait for HALFPERIOD*4;

--   Wr <= '0';

 --   Wr <= '1';
 --   RS <= x"4";
 --   DI <= "00001110";
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"5";
 --   DI <= "00000000";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"6";
 --   DI <= "00001110";
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"7";
 --   DI <= "00000000";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"F";
 --   DI <= "00000001";
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"E";
 --   DI <= "00000001";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2*125;
 --   Wr <= '1';
 --   RS <= x"4";
 --   DI <= "00000011";
 --   wait for HALFPERIOD*2;
 --   RS <= x"6";
 --   DI <= "00010011";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2*125;
 --   Wr <= '1';
 --   RS <= x"E";
 --   DI <= "00000101";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2*250;
 --   Wr <= '1';
 --   RS <= x"5";
 --   DI <= "00000000";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2*55;
 --   Wr <= '1';
 --   RS <= x"E";
 --   DI <= "00001011";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2*55;
 --   Wr <= '1';
 --   RS <= x"F";
 --   DI <= "00001011";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2*55;
 --
 --
 --   res_n <= '0';
 --   wait for HALFPERIOD*2;
 --   res_n <= '1';
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"4";
 --   DI <= "00000011";
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"5";
 --   DI <= "00000000";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"6";
 --   DI <= "00001110";
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"7";
 --   DI <= "00000000";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"E";
 --   DI <= "00000001";
 --   wait for HALFPERIOD*2;
 --   Wr <= '0';
 --   wait for HALFPERIOD*2;
 --   Wr <= '1';
 --   RS <= x"F";
 --   DI <= "01000001";
 --   wait for HALFPERIOD*2;

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

