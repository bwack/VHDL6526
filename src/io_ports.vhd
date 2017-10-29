library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity port_a is
-- IO port a
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DB      : inout std_logic_vector(7 downto 0); -- data in
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS & OUTPUTS
-- IO interface to  be used with IO buffer.
    PA      : inout std_logic_vector(7 downto 0)
  );
end entity port_a;

architecture rtla of port_a is
  signal DI, data, PA_IN   : std_logic_vector(7 downto 0);
  signal enable : std_logic;
-- REGISTERS 
  signal PRA  : std_logic_vector(7 downto 0); -- PA0-PA7 Peripheral Data Register
  signal DDRA : std_logic_vector(7 downto 0); -- data direction of PA0-PA7 (1=out)
  signal read_flag : std_logic;

begin

  BUFFERBITS: for i in 0 to 7 generate
    PA(i) <= PRA(i) when DDRA(i) = '1' else 'H';
  end generate BUFFERBITS;
  PA_IN <= PA;
  enable <= '1' when Rd = '1' and (RS=x"0" or RS=x"2") else '0';
  DB <= data when enable = '1' else (others => 'Z');
  DI <= DB;

--  PA_tris <= DDRA;
-- WRITE REGISTERS
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      PRA <= x"00";
      DDRA <= x"00";
    elsif falling_edge(PHI2) then
      if Wr = '1' then
        case RS is
          when x"0" => PRA <= DI;
          when x"2" => DDRA <= DI;
          when others => null;
        end case;
      end if;
    end if;
  end process;

-- READ REGISTER
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      data <= (others => '1');
    elsif rising_edge(PHI2) then
      read_flag <= '0';
      if Rd = '1' then
        case RS is
          when x"0" => data <= PA;   read_flag <= '1';
          when x"2" => data <= DDRA; read_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;
end architecture rtla;



-- -----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity port_b is
-- IO port b
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DB      : inout std_logic_vector(7 downto 0); -- data in
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- I/O
    PB             : inout std_logic_vector(7 downto 0);
    TMRA_PB_IN     : in std_logic; -- from TMRA to PB6 if TMRA_PB_ON = '1'
    TMRB_PB_IN     : in std_logic; -- from TMRB to PB7 if TMRB_PB_ON = '1'
    TMRA_PB_ON     : in std_logic; -- puts TMRA_OUT on PB, overrides bit in DDRB.
    TMRB_PB_ON     : in std_logic; -- puts TMRB_OUT on PB, overrides bit in DDRB.
    PC_N           : out std_logic -- Goes low for one clock cycle following
                                    -- a read or write of PORT B.
   );
end entity port_b;

architecture rtlb of port_b is
  signal DI, data  : std_logic_vector(7 downto 0);
  signal enable : std_logic;
-- REGISTERS 
  signal PRB : std_logic_vector(7 downto 0); -- PB0-PB7 Peripheral Data Register
  signal DDRB : std_logic_vector(7 downto 0); -- data direction of PB0-PB7 (1=out)

  signal PB_IN : std_logic_vector(7 downto 0);
  signal reg_read_flag, reg_write_flag, port_read_flag, port_write_flag : std_logic;
begin

  PB(0) <= PRB(0) when DDRB(0) = '1' else 'H';
  PB(1) <= PRB(1) when DDRB(1) = '1' else 'H';
  PB(2) <= PRB(2) when DDRB(2) = '1' else 'H';
  PB(3) <= PRB(3) when DDRB(3) = '1' else 'H';
  PB(4) <= PRB(4) when DDRB(4) = '1' else 'H';
  PB(5) <= PRB(5) when DDRB(5) = '1' else 'H';
  PB(6) <= PRB(6) when DDRB(6) = '1' and TMRA_PB_ON = '0' else
           TMRA_PB_IN when TMRA_PB_ON = '1' else 'H';
  PB(7) <= PRB(7) when DDRB(7) = '1' and TMRB_PB_ON = '0' else
           TMRB_PB_IN when TMRB_PB_ON = '1' else 'H';
  PB_IN <= PB;
  PC_N <= '0'  when port_read_flag = '1' or port_write_flag = '1' else '1';

  enable <= '1' when Rd = '1' and (RS=x"1" or RS=x"3") else '0';
  DB <= data when enable = '1' else (others => 'Z');
  DI <= DB;


-- WRITE REGISTERS
  process (PHI2,RES_N) is 
  begin
    if RES_N = '0' then
      PRB <= x"00";
      DDRB <= x"00";
    elsif falling_edge(PHI2) then
      port_write_flag <= '0';
      reg_write_flag <= '0';
      if Wr = '1' then
        case RS is
          when x"1" => PRB <= DI;  reg_write_flag <= '1'; port_write_flag <= '1';
          when x"3" => DDRB <= DI; reg_write_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;

-- READ REGISTERS;
  process (PHI2,RES_N) is
  begin
    if RES_N = '0' then
      data <= (others => '1');
    elsif rising_edge(PHI2) then
      port_read_flag <= '0';
      reg_read_flag <= '0';
      if Rd = '1' then
        case RS is
          when x"1" => data <= PB_IN;  reg_read_flag <= '1'; port_read_flag <= '1';
          when x"3" => data <= DDRB;   reg_read_flag <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process;
end architecture rtlb;
