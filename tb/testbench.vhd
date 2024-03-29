library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

-- top-level
entity testbench is
--  port (
----
--    RES_N      : in    std_logic;                    -- pin 34
--    PHI2       : in    std_logic;                    -- pin 25
--    CS_N       : in    std_logic;                    -- pin 23
--    RW         : in    std_logic;                    -- pin 22
--    DB         : inout std_logic_vector(7 downto 0); -- pin 26..33
--    RS         : in    std_logic_vector(3 downto 0); -- pin 35..38
----
--    PA         : inout std_logic_vector(7 downto 0); -- pin 9..2
--    PB         : inout std_logic_vector(7 downto 0); -- pin 17..10
--    SP         : inout std_logic;                    -- pin 39
--    CNT        : inout std_logic;                    -- pin 40
--    FLAG_N     : in    std_logic;                    -- pin 24
--    PC_N       : out   std_logic;                    -- pin 18
--    IRQ_N      : out   std_logic;                    -- pin 21
--    TOD        : inout std_logic                     -- pin 19
--  );
end entity testbench;

architecture beh1 of testbench is
  signal RES_N,PHI2,CS_N,RW,SP,CNT,FLAG_N,PC_N,IRQ_N,TOD : std_logic;
  signal DB,PA,PB : std_logic_vector(7 downto 0);
  signal RS : std_logic_vector(3 downto 0);

  procedure reset_proc( signal PHI2, RES_N : out std_logic ) is
  begin
      PHI2 <= '1';
      RES_N<='0';      
      wait for 500 ns;
      PHI2 <= '0';
      wait for 500 ns;
      RES_N<='1';     
  end procedure reset_proc;

  procedure nop_proc ( signal PHI2,CS_N,RW : out std_logic;
                       signal RS : out std_logic_vector(3 downto 0);
                       cycles : in positive := 1) is
  begin
    for i in 1 to cycles loop
      PHI2 <= '0';
      wait for 100 ns;
      RW <= '1';
      RS <= x"0";
      wait for 10 ns;
      CS_N <= '1';
      wait for 390 ns;
      PHI2 <= '1';
      wait for 500 ns;
    end loop;
  end procedure nop_proc;

  procedure bus_proc ( signal PHI2 : out std_logic;
                       signal CS_N : out std_logic;
                       signal RW   : out std_logic;
                       signal DB   : inout std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       dir  : in std_logic;
                       data : in std_logic_vector(7 downto 0);
                       addr : in std_logic_vector(3 downto 0) ) is
  begin
    PHI2 <= '0';
    wait for 100 ns;
    RW <= dir;
    RS <= addr;
    wait for 10 ns;
    CS_N <= '0';
    if dir = '0' then -- read
      DB <= data;
    else
      DB <= "ZZZZZZZZ";
    end if;
    wait for 390 ns;
    PHI2 <= '1';

    wait for 480 ns;
    PHI2 <= '0';
    wait for 20 ns;
    --DB <= (others => 'Z');
  end procedure bus_proc;
 

begin

  UUT_0: entity work.cia(str)
  port map(
    RES_N    => RES_N   ,
    PHI2     => PHI2    ,
    CS_N     => CS_N    ,
    RW       => RW      ,
    DB       => DB      ,
    RS       => RS      ,
    PA       => PA      ,
    PB       => PB      ,
    SP       => SP      ,
    CNT      => CNT     ,
    FLAG_N   => FLAG_N  ,
    PC_N     => PC_N    ,
    IRQ_N    => IRQ_N   ,
    TOD      => TOD     
  );

  IRQ_N <= 'Z';


  STIMULI_0: process
  begin
    CNT <= '1';
    SP <= 'H';
    DB <= "ZZZZZZZZ";
    CS_N <= '1';
    RW <= '1';
    RS <= x"F";
    reset_proc(PHI2,RES_n);
    nop_proc(PHI2,CS_N,RW,RS,1);
--    nop_proc(PHI2,1);
--    nop_proc(PHI2,4);
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"05",x"4");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"00",x"5");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"11",x"E");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"FF",x"3");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"FF",x"1");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"03",x"E");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"0F",x"2");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"33",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"D");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"3");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"4");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"5");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"E");
    nop_proc(PHI2,CS_N,RW,RS,7);
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"01",x"E");
    nop_proc(PHI2,CS_N,RW,RS,7);
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"81",x"D");
    nop_proc(PHI2,CS_N,RW,RS,7);
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"D");
    nop_proc(PHI2,CS_N,RW,RS,7);
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"80",x"E");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"01",x"D");
    nop_proc(PHI2,CS_N,RW,RS,7);
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"D");
    nop_proc(PHI2,CS_N,RW,RS,7);
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"00",x"F");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"80",x"B");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"59",x"A");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"59",x"9");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"08",x"8");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"84",x"D");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"80",x"F");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"81",x"B");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"00",x"A");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"00",x"9");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"00",x"8");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"25",x"4");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"00",x"5");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"11",x"E");
--    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"81",x"D");
--    loop
--      nop_proc(PHI2,CS_N,RW,RS,1);
--      if IRQ_N = '0' then
--        nop_proc(PHI2,CS_N,RW,RS,6);
--        bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"D");
--        nop_proc(PHI2,CS_N,RW,RS,6);
--      end if;
--    end loop;

-- scan keyboard
    -- PB(3) <= PA(4); -- keypress
    nop_proc(PHI2,CS_N,RW,RS,10);
    reset_proc(PHI2,RES_n);
    nop_proc(PHI2,CS_N,RW,RS,1);
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"FF",x"2");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',"11111110",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"1");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',"11111101",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"1");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',"11111011",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"1");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',"11110111",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"1");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',"11101111",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"1");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',"11011111",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"1");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',"10111111",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"1");
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',"01111111",x"0");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"1");

-- serial port as input
    nop_proc(PHI2,CS_N,RW,RS,10);
    reset_proc(PHI2,RES_n);
    nop_proc(PHI2,CS_N,RW,RS,1);
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"00",x"E"); -- spmode=input
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"88",x"D"); -- set interrupt mask
    SP<='1';
    for i in 0 to 7 loop
      CNT <= '0';
      nop_proc(PHI2,CS_N,RW,RS,10);
      CNT <= '1';
      nop_proc(PHI2,CS_N,RW,RS,10);
    end loop;
    CNT <= '0';
    SP<='0';    
    nop_proc(PHI2,CS_N,RW,RS,6);
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"D");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"C");
    nop_proc(PHI2,CS_N,RW,RS,6);
    for i in 0 to 7 loop
      CNT <= '0';
      nop_proc(PHI2,CS_N,RW,RS,10);
      CNT <= '1';
      nop_proc(PHI2,CS_N,RW,RS,10);
    end loop;
    CNT <= '0';
    nop_proc(PHI2,CS_N,RW,RS,6);
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"D");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"00",x"C");
    nop_proc(PHI2,CS_N,RW,RS,6);

    wait;
  end process STIMULI_0;
  
  TOD_0: process
  begin
    TOD <= '0';
    wait for 10.3 us;
    TOD <= '1';
    wait for 10.3 us;
  end process;


end architecture beh1;