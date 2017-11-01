library STD;
use STD.textio.all;                     -- basic I/O
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
  
  
  procedure module_read_proc (
                       signal PHI2 : in std_logic;
                       signal DO   : in  std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       signal Rd   : out std_logic;
                       address     : in std_logic_vector(3 downto 0);
                       expected    : in std_logic_vector(7 downto 0)                       );

  procedure module_write_proc (
                       signal PHI2 : in std_logic;
                       signal DI   : out std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       signal Wr   : out std_logic;
                       constant address : in std_logic_vector(3 downto 0);
                       constant data    : in std_logic_vector(7 downto 0)
                 );
                 
                 
  procedure bus_proc ( signal PHI2 : in std_logic;
                       signal CS_N : out std_logic;
                       signal RW   : out std_logic;
                       signal DB   : inout std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       dir  : in std_logic;
                       data : in std_logic_vector(7 downto 0);
                       addr : in std_logic_vector(3 downto 0) );
                       
  procedure print( str : string );

end base_pck;


package body base_pck is
------------------------------
-- Bus Functions procedures
------------------------------

  procedure reset_proc( signal PHI2  : in  std_logic ;
                        signal RES_N : out std_logic ) is
  begin
    print("reset_proc");
    RES_N<='0';      
    wait until falling_edge(PHI2);
    RES_N<='1' after HALFPERIOD*0.9;     
    wait until rising_edge(PHI2);
  end procedure reset_proc;

  
  procedure nop_proc ( signal PHI2   : in std_logic;
                       cycles        : in positive := 1) is
  begin
    print("nop_proc");
    for i in 1 to cycles loop
      wait until rising_edge(PHI2);
    end loop;
  end procedure nop_proc;


  procedure module_read_proc (
                       signal PHI2 : in std_logic;
                       signal DO   : in  std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       signal Rd   : out std_logic;
                       address     : in std_logic_vector(3 downto 0);
                       expected    : in std_logic_vector(7 downto 0)                       ) is
  begin
    print("module_read_proc");
    --PHI2 <= '0';
    --wait for 100 ns;
    Rd <= '1';
    RS <= address;
    --wait for 10 ns;
    --wait for 390 ns;
    wait until falling_edge(PHI2);
    --PHI2 <= '1';
    assert DO = expected report "not expected"
      severity failure;
    --wait for HALFPERIOD*0.9;
    --PHI2 <= '0';
    wait until rising_edge(PHI2);
    Rd <= '0';
    --DB <= (others => 'Z');

  end procedure module_read_proc;
  
  
  procedure module_write_proc (
                       signal PHI2 : in std_logic;
                       signal DI   : out std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       signal Wr   : out std_logic;
                       constant address : in std_logic_vector(3 downto 0);
                       constant data    : in std_logic_vector(7 downto 0)
                 ) is
  begin
    print("module_write_proc");
    --PHI2 <= '0';
    --wait for 100 ns;
    Wr <= '1';
    RS <= address;
    DI <= data;
    --wait for 10 ns;
    --wait for 390 ns;
    wait until falling_edge(PHI2);
    --PHI2 <= '1';
    --wait for HALFPERIOD*0.9;
    --PHI2 <= '0';
    wait until rising_edge(PHI2);
    Wr <= '0';
    --DB <= (others => 'Z');

  end procedure module_write_proc;
  
  
  procedure bus_proc ( signal PHI2 : in std_logic;
                       signal CS_N : out std_logic;
                       signal RW   : out std_logic;
                       signal DB   : inout std_logic_vector(7 downto 0);
                       signal RS   : out std_logic_vector(3 downto 0);
                       dir  : in std_logic;
                       data : in std_logic_vector(7 downto 0);
                       addr : in std_logic_vector(3 downto 0) ) is
  begin
    print("bus_proc");
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
 
 
  procedure print( str : string ) is
    variable my_line : line;
  begin
    write(my_line, str);
    writeline(output, my_line);
  end print;
  
end package body;