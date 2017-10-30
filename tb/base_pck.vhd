library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- for use with the testbenches. Lets keep these bus functions in one place.

package base_pck is
  constant HALFPERIOD : time := 500 ns;

  procedure reset_proc( signal PHI2  : in  std_logic ;
                        signal RES_N : out std_logic );
  
  procedure nop_proc ( signal PHI2   : in std_logic;
                       cycles        : in positive := 1);
  
  procedure bus_proc ( signal PHI2 : in std_logic;
                       signal CS_N : out std_logic;
                       signal RW   : out std_logic;
                       signal DB   : inout std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       dir  : in std_logic;
                       data : in std_logic_vector(7 downto 0);
                       addr : in std_logic_vector(3 downto 0) );
end base_pck;


package body base_pck is
------------------------------
-- Bus Functions procedures
------------------------------

  procedure reset_proc( signal PHI2  : in  std_logic ;
                        signal RES_N : out std_logic ) is
  begin
      RES_N<='0';      
      wait until falling_edge(PHI2);
      RES_N<='1' after HALFPERIOD*0.9;     
      wait until rising_edge(PHI2);
  end procedure reset_proc;

  
  procedure nop_proc ( signal PHI2   : in std_logic;
                       cycles        : in positive := 1) is
  begin
    for i in 1 to cycles loop
      wait until rising_edge(PHI2);
    end loop;
  end procedure nop_proc;

  
  procedure bus_proc ( signal PHI2 : in std_logic;
                       signal CS_N : out std_logic;
                       signal RW   : out std_logic;
                       signal DB   : inout std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       dir  : in std_logic;
                       data : in std_logic_vector(7 downto 0);
                       addr : in std_logic_vector(3 downto 0) ) is
  begin
    --PHI2 <= '0';
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
    --wait for 390 ns;
    wait until falling_edge(PHI2);
    --PHI2 <= '1';

    wait for HALFPERIOD*0.9;
    --PHI2 <= '0';
    CS_N <= '1';
    if dir = '0' then -- read
      DB <= "ZZZZZZZZ";
    end if;
    wait until rising_edge(PHI2);
    DB <= (others => 'Z');
  end procedure bus_proc;
 
end package body;