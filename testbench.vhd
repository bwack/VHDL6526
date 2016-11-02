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

  procedure nop_proc ( signal PHI2   : out std_logic;
                       cycles : in positive := 1) is
  begin
    for i in 1 to cycles loop
      PHI2 <= '1';
      wait for 500 ns;
      PHI2 <= '0';
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
    RS <= addr;
    wait for 25 ns;
    RW <= dir;
    wait for 25 ns;
    PHI2 <= '1';
    wait for 25 ns;
    CS_N <= '0';
    wait for 25 ns;
    if dir = '0' then -- read
      DB <= data;
    end if;
    wait for 450 ns;
    PHI2 <= '0';
    wait for 450 ns;
    DB <= (others => 'Z');
    CS_N <= '1';
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
    DB <= "ZZZZZZZZ";
    CS_N <= '1';
    RW <= '1';
    RS <= x"F";
    reset_proc(PHI2,RES_n);
    nop_proc(PHI2,1);
--    nop_proc(PHI2,1);
--    nop_proc(PHI2,4);
    bus_proc(PHI2,CS_N,RW,DB,RS,'0',x"05",x"5");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"04",x"4");
    bus_proc(PHI2,CS_N,RW,DB,RS,'1',x"05",x"5");
    wait;
  end process STIMULI_0;
  
  TOD_0: process
  begin
    TOD <= '0';
    wait for 10 ms;
    TOD <= '1';
    wait for 10 ms;
  end process;


end architecture beh1;