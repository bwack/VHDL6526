
library ieee;
use ieee.std_logic_1164.all;
use work.base_pck.all;

entity tb_timer is
-- empty
end tb_timer;

architecture behaviour of tb_timer is

  component timerA is
  port ( 
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0);
    DO      : out std_logic_vector(7 downto 0);
    RS      : in  std_logic_vector(3 downto 0); -- address - register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
--  Rd and Wr are driven by CS_N and Rd/Wr in the chip access control
-- INPUTS
    CNT     : in std_logic; -- counter
-- OUTPUTS
    TMRA_UNDERFLOW : out std_logic; -- timer A underflow pulses for timer B.
    TMR_OUT        : out std_logic; -- timer A output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer A output on PB6 else PB6 is I/O
    SPMODE         : out std_logic; -- CRA_SPMODE forwarding to serial port
    TODIN          : out std_logic; -- CRA_TODIN forwarding to tod
    INT            : out std_logic
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
    CNT            : in  std_logic; -- counter
    TMRA_UNDERFLOW : in std_logic; -- underflow pulses from timer A.
-- OUTPUTS
    TMR_OUT        : out std_logic; -- timer B output to PORTB
    PB_ON_EN       : out std_logic; -- enable timer B output on PB7 else PB7 is I/O
    ALARM          : out std_logic; -- CRB_ALARM forwarding to tod
    INT            : out std_logic
  );
  end component timerB;
  
  signal run : boolean := true;

  signal PHI2, RES_N, RW, Rd, Wr, CS_N: std_logic;
  signal DI                           : std_logic_vector(7 downto 0);
  signal TMRA_DO, TMRB_DO             : std_logic_vector(7 downto 0);
  signal RS                           : std_logic_Vector(3 downto 0);
  signal CNT                          : std_logic;
  signal TMRA_UNDERFLOW               : std_logic; -- shared with TimerA and B
  signal TMRA_OUT, TMRB_OUT           : std_logic;
  signal TMRA_PB_ON_EN, TMRB_PB_ON_EN : std_logic;
  signal TMRA_INT, TMRB_INT           : std_logic;
  signal CRB_ALARM                    : std_logic;
  
begin
  -- on the top structure RW is decoded into Rd and Wr
  -- Rd <=     RW and not CS_N;
  -- Wr <= not RW and not CS_N;

  UUT_TMRA: entity work.timerA(rtl)
    port map (
      PHI2           => PHI2,
      DI             => DI,
      DO             => TMRA_DO,
      RS             => RS,
      RES_N          => RES_N,
      Rd             => Rd,
      Wr             => Wr,
      CNT            => CNT,
      TMRA_UNDERFLOW => TMRA_UNDERFLOW,
      TMR_OUT        => TMRA_OUT,
      PB_ON_EN       => TMRA_PB_ON_EN,
      INT            => TMRA_INT
    );

  UUT_TMRB: entity work.timerB(rtl)
    port map (
      PHI2           => PHI2,
      DI             => DI,
      DO             => TMRB_DO,
      RS             => RS,
      RES_N          => RES_N,
      Rd             => Rd,
      Wr             => Wr,
      CNT            => CNT,
      TMRA_UNDERFLOW => TMRA_UNDERFLOW,
      TMR_OUT        => TMRB_OUT,
      PB_ON_EN       => TMRB_PB_ON_EN,
      ALARM          => CRB_ALARM,
      INT            => TMRB_INT
    );

  P_CLK_0: process
  begin
    while run loop
      PHI2 <= '0';
      wait for HALFPERIOD;
      PHI2 <= '1';
      wait for HALFPERIOD;    
    end loop;
    wait;
  end process P_CLK_0;

-- an alternative and slower cnt signal than the PHI2 for the timer tick input
  P_CNT_0: process
  begin
    while run loop
      CNT <= '0';
      wait for 11.3 us;
      CNT <= '1';
      wait for 11.3 us;
    end loop;
    wait;
  end process P_CNT_0;

  STIMULI_0:
  process
  begin
    -- init at time zero
    RES_N <= '1';
    CS_N  <= '1';
    Rd    <= '0';
    Wr    <= '0';
    DI <= (others => '0');
    RS    <= x"0";
    wait until rising_edge(PHI2);
    
-- simple start stop test
-----------    res_n <= '0';
-----------    Wr <= '0';
-----------    Rd <= '0';
-----------    wait for HALFPERIOD*3;
-----------    res_n <= '1';
-----------    wait for HALFPERIOD*4;
  reset_proc(PHI2, RES_N);
  nop_proc(PHI2, 4);

-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00000001"; -- start B
-----------    wait for HALFPERIOD*2;
  print("Start TMRB");
  module_write_proc(PHI2,DI,RS,Wr,x"F",data=>"00000001");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"F",expected=>"00000001");
  nop_proc(PHI2, 2);

-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00000001"; -- start A
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*6;
  print("Start TMRA");
  module_write_proc(PHI2,DI,RS,Wr,x"E",data=>"00000001");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"E",expected=>"00000001");
  nop_proc(PHI2, 8);
  
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00000000"; -- stop B
-----------    wait for HALFPERIOD*2;
  print("Stop TMRB");
  module_write_proc(PHI2,DI,RS,Wr,x"F",data=>"00000000");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"F",expected=>"00000000");
  nop_proc(PHI2, 2);

--    Wr <= '1';
--    RS <= x"E";
--    DI <= "00000000"; -- stop A
--    wait for HALFPERIOD*2;
--    Wr <= '0';
--    wait for HALFPERIOD*2*6;
  print("Stop TMRA");
  module_write_proc(PHI2,DI,RS,Wr,x"E",data=>"00000000");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"E",expected=>"00000000");
  nop_proc(PHI2, 2);

  -- Check TMRA and TMRB values
  print("Check TIMER values");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"4",expected=>x"F1");
  nop_proc(PHI2, 1);
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"5",expected=>x"FF");

  print("Wait for a while");
  nop_proc(PHI2, 100);
  print("Verify timer stopped");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"6",expected=>x"F1");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"7",expected=>x"FF");
  nop_proc(PHI2, 1);

  -- Verify timer stopped
  print("Verify timer stopped");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"4",expected=>x"F1");
  nop_proc(PHI2, 1);
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"5",expected=>x"FF");
  nop_proc(PHI2, 1);
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"6",expected=>x"F1");
  nop_proc(PHI2, 1);
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"7",expected=>x"FF");
  nop_proc(PHI2, 1);


  ---- test one-shot mode, verify output toggle

--    res_n <= '0';
--    wait for HALFPERIOD*2;
--    res_n <= '1';
--    wait for HALFPERIOD*4;
  reset_proc(PHI2, RES_N);
  nop_proc(PHI2, 1);

--  Wr <= '1';
--  RS <= x"4";             -- Write to TA_LO (TMRA latch low)
--  DI <= "00001010";
--  wait for HALFPERIOD*2;
  print("Write TA_LO.");
  module_write_proc(PHI2,DI,RS,Wr,x"4",data=>x"0A");
-- note: You can't read TA_LO. A read at x"4" returns TMRA_LO.
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"4",expected=>x"FF");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"5",expected=>x"FF");
  
--  Wr <= '1';
--  RS <= x"5";        -- TA_HI. TMRA auto loads after this write.
--  DI <= "00000000";
--  wait for HALFPERIOD*2;
  print("Write TA_HI. TMRA loads latch");
  module_write_proc(PHI2,DI,RS,Wr,x"5",data=>x"02");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"4",expected=>x"0A");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"5",expected=>x"02");

-----------    Wr <= '1';
-----------    RS <= x"6";             -- TB_LO
-----------    DI <= "00001010";
-----------    wait for HALFPERIOD*2;
  print("Write TB_LO.");
  module_write_proc(PHI2,DI,RS,Wr,x"6",data=>x"0A");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"6",expected=>x"FF");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"7",expected=>x"FF");

-----------    Wr <= '1';
-----------    RS <= x"7";             -- TB_HI (timerB auto loads after this write)
-----------    DI <= "00000000";       -- therefor TB_LO was written before TB_HI
-----------    wait for HALFPERIOD*2;
  print("Write TB_HI. TMRB loads latch");
  module_write_proc(PHI2,DI,RS,Wr,x"7",data=>x"02");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"6",expected=>x"0A");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"7",expected=>x"02");

-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00001011"; -- CRB: start, pb-on, pulse, one-shot
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00001011"; -- CRA: same
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*4;
  print("Start TMRA and TMRB, PB_ON, PULSE, ONE-SHOT");
  assert TMRA_PB_ON_EN = '0' report "TMRA_PB_ON not 0" severity failure;
  assert TMRB_PB_ON_EN = '0' report "TMRB_PB_ON not 0" severity failure;
  module_write_proc(PHI2,DI,RS,Wr,x"F",data=>"00001011"); -- start
  module_write_proc(PHI2,DI,RS,Wr,x"E",data=>"00001011"); -- start
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"F",expected=>"00001011");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"E",expected=>"00001011");
  nop_proc(PHI2, 1);
  assert TMRA_OUT = '0' report "TMRA_OUT not 0" severity failure;
  assert TMRB_OUT = '0' report "TMRB_OUT not 0" severity failure;
  assert TMRA_UNDERFLOW = '0' report "TMRA_UNDERFLOW not 0" severity failure;

  -- Check TMRA and TMRB valuse
  print("Check TMRA and TMRB");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"4",expected=>x"06");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"5",expected=>x"02");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"6",expected=>x"03");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"7",expected=>x"02");
  assert TMRA_PB_ON_EN = '1' report "TMRA_PB_ON not 1" severity failure;
  assert TMRB_PB_ON_EN = '1' report "TMRB_PB_ON not 1" severity failure;

  print("wait for rising edge TMRB_OUT (timeout)");
  while(TMRB_OUT = '0') loop -- wait for rising edge TMRB_OUT
    assert TMRA_OUT = '0' report "TMRA_OUT not 0" severity failure;
    assert TMRA_INT = '0' report "TMRA_INT not 0" severity failure;
    assert TMRB_INT = '0' report "TMRB_INT not 0" severity failure;
    assert TMRA_UNDERFLOW = '0' report "TMRA_UNDERFLOW not 0" severity failure;
    wait until falling_edge(PHI2);
  end loop;
  
  print("check TMRA_OUT and TMRB_OUT");
  assert TMRA_OUT = '0' report "TMRA_OUT not 0" severity failure;
  assert TMRB_OUT = '1' report "TMRB_OUT not 1" severity failure;
  assert TMRA_INT = '0' report "TMRA_INT not 0" severity failure;
  assert TMRB_INT = '1' report "TMRB_INT not 1" severity failure;
  wait until falling_edge(PHI2);
  assert TMRA_OUT = '1' report "TMRA_OUT not 1" severity failure;
  assert TMRB_OUT = '0' report "TMRB_OUT not 0" severity failure;
  assert TMRA_INT = '1' report "TMRA_INT not 1" severity failure;
  assert TMRB_INT = '0' report "TMRB_INT not 0" severity failure;
  wait until falling_edge(PHI2);
  assert TMRA_OUT = '0' report "TMRA_OUT not 0" severity failure;
  assert TMRB_OUT = '0' report "TMRB_OUT not 0" severity failure;
  assert TMRA_INT = '0' report "TMRA_INT not 0" severity failure;
  assert TMRB_INT = '0' report "TMRB_INT not 0" severity failure;
  print("check TMRA and TMRB reloaded");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"4",expected=>x"0A");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"5",expected=>x"02");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"6",expected=>x"0A");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"7",expected=>x"02");
  nop_proc(PHI2, 10);
  print("check TMRA and TMRB stopped (one-shot)");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"4",expected=>x"0A");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"5",expected=>x"02");
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"6",expected=>x"0A"); -- check stopped
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"7",expected=>x"02"); -- and reloaded
  assert CRB_ALARM = '0' report "CRB_ALARM not 0" severity failure;

--  nop_proc(PHI2, 1);
  
-----------    -- timer still running, do force loads.
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00011011"; -- CRB: force load, pb_on, pulse, one-shot
-----------    wait for HALFPERIOD*2;

-- "timer still running" this older comment is conflicting. The timer is
-- not running. Perhaps what is meant is "when the timer wraps, do a reload"
-- but then again we have the "force load" bit set on CRB. Double conflict.
-- ok so accoring to the following, this CRB is a "strobe bit", meaning that
-- when set it will automatially clear, and also the TMR will load from latch.
--   "Force Load: tested ok
--   A strobe bit allows the timer latch to be loaded into the
--   timer counter at any time, whether the timer is running or
--   not."
-- Since the timer was stopped by one-shot mode above, the value has already
-- been loaded. We can check that ofcourse, then restart it, stop it,
-- then start with force-load bit and check again.
  print("Start TMRA and TMRB. force load, pb_on, pulse, one-shot");

  module_write_proc(PHI2,DI,RS,Wr,x"F",data=>"00011011"); -- start
  module_write_proc(PHI2,DI,RS,Wr,x"E",data=>"00011011"); -- start
  module_read_proc(PHI2,TMRB_DO,RS,Rd,x"F",expected=>"00001011");
  module_read_proc(PHI2,TMRA_DO,RS,Rd,x"E",expected=>"00001011");
  wait for 0.1 ms;
  run <= false;
  wait;
  
-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00011011"; -- CRA: same
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*35;

-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00011011";
-----------    wait for HALFPERIOD*2;

-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00011011";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*25;
-----------
-----------
------------- toggle or single phi2-period pulses on timer underflow
-----------    res_n <= '0';
-----------    wait for HALFPERIOD*2;
-----------    res_n <= '1';
-----------    wait for HALFPERIOD*4;
-----------    Wr <= '1';
-----------    RS <= x"4";             -- TA_LO
-----------    DI <= "00000011";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"5";             -- TA_HI (timerA auto loads after this write)
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"6";             -- TB_LO
-----------    DI <= "00000011";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"7";             -- TB_HI (timerB auto loads after this write)
-----------    DI <= "00000000";       -- therefor TB_LO was written before TB_HI
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00000011"; -- CRB: start, pb-on, pulse, continuous
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00000011"; -- CRA: same
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*15;
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00000111"; -- CRB: start, pb-on, toggles, continuous
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00000111"; -- CRA: same
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*15;
-----------
-----------    res_n <= '0';
-----------    wait for HALFPERIOD*2;
-----------    res_n <= '1';
-----------    wait for HALFPERIOD*4;
-----------
-------------  2. TIMER A can count 02 clock pulses
-------------  => tested ok above
-----------
-------------     or external pulses applied to the CNT pin. (testing B here also)
-----------    res_n <= '0';
-----------    wait for HALFPERIOD*2;
-----------    res_n <= '1';
-----------    wait for HALFPERIOD*4;
-----------    Wr <= '1';
-----------    RS <= x"4";             -- TA_LO
-----------    DI <= "00000011";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"5";             -- TA_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"6";             -- TB_LO
-----------    DI <= "00000011";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"7";             -- TB_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00100001"; -- CRB: start and count using CNT
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00100001"; -- CRA: same
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*300; -- long one, CNT is slow
-----------
-------------  3. TIMER B can count 02 pulses, external CNT pulses,
-------------  => tested OK.
-----------
-------------     TIMER B can count TIMER A underflow pulses
-----------    res_n <= '0';
-----------    wait for HALFPERIOD*2;
-----------    res_n <= '1';
-----------    wait for HALFPERIOD*4;
-----------    Wr <= '1';
-----------    RS <= x"4";             -- TA_LO
-----------    DI <= "00000010";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"5";             -- TA_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"6";             -- TB_LO
-----------    DI <= "00000010";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"7";             -- TB_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "01000001"; -- CRB: start TIMER B, count TIMER A underflow pulses
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00000001"; -- CRA: start TIMER A.
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*25; -- long one, CNT is slow
-----------
-------------     TIMER A underflow pulses while the CNT pin is held high.
-----------    res_n <= '0';
-----------    wait for HALFPERIOD*2;
-----------    res_n <= '1';
-----------    wait for HALFPERIOD*4;
-----------    Wr <= '1';
-----------    RS <= x"4";             -- TA_LO
-----------    DI <= "00000010";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"5";             -- TA_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"6";             -- TB_LO
-----------    DI <= "00000010";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"7";             -- TB_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "01100001"; -- CRB: start TIMER B, count TIMER A underflow pulses
-----------                      -- when CNT is high.
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00000001"; -- CRA: start TIMER A.
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*70; -- long one, CNT is slow
-----------
-------------  4. The timer latch is loaded into the timer on any timer
-------------     underflow, on a force load or following a write to the high
-------------     byte of the prescaler while the timer is stopped.
------------- => tested correct beh when writing to high byte while timer is stopped.
-----------
-------------  5. If the timer is running, a write to the high byte will load the
-------------     timer latch, but not reload the counter.
-----------    res_n <= '0';
-----------    wait for HALFPERIOD*2;
-----------    res_n <= '1';
-----------    wait for HALFPERIOD*4;
-----------    Wr <= '1';
-----------    RS <= x"4";             -- TA_LO
-----------    DI <= "00000110";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"5";             -- TA_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"6";             -- TB_LO
-----------    DI <= "00000110";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"7";             -- TB_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"F";
-----------    DI <= "00000001"; -- CRB: start TIMER B
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"E";
-----------    DI <= "00000001"; -- CRA: start TIMER A.
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '0';
-----------    wait for HALFPERIOD*2*10;
-----------    Wr <= '1';
-----------    RS <= x"4";             -- TA_LO
-----------    DI <= "00001110";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"5";             -- TA_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"6";             -- TB_LO
-----------    DI <= "00001110";
-----------    wait for HALFPERIOD*2;
-----------    Wr <= '1';
-----------    RS <= x"7";             -- TB_HI
-----------    DI <= "00000000";
-----------    wait for HALFPERIOD*2*10;
-----------
-----------    res_n <= '0';
-----------    wait for HALFPERIOD*2;
-----------    res_n <= '1';
-----------    wait for HALFPERIOD*4;

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
    wait until rising_edge(PHI2);
    run <= false;
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


