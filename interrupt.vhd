library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity interrupt is
-- Interrupt data and mask registers
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DB      : inout std_logic_vector(7 downto 0); -- data in
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS
--    INTIN  : in std_logic_vector(4 downto 0);
    INT_TMRA       : in std_logic; -- bit 0
    INT_TMRB       : in std_logic; -- bit 1
    INT_TODALARM   : in std_logic; -- bit 2
    INT_SP         : in std_logic; -- bit 3
    INT_FLAG       : in std_logic; -- bit 4
-- OUTPUTS
    IRQ            : out std_logic
  );
end entity interrupt;

architecture rtl of interrupt is
  signal DI, data     : std_logic_vector(7 downto 0);
  signal enable : std_logic;
-- REGISTERS (Interrupt Control Register - x"D")
  signal ICR_DATA_L : std_logic_vector(7 downto 0); -- read only data latch
  signal ICR_MASK_L : std_logic_vector(7 downto 0); -- write only interrupt mask
-- FLAGS
  signal ICR_READ_FLAG : std_logic; 
begin

  enable <= '1' when Rd = '1' and (RS = x"D") else '0';
  DB <= data when enable = '1' else "ZZZZZZZZ";
  DI <= DB;

-- Interrupt registers, write
  process(PHI2,ICR_READ_FLAG,RES_N) is
    variable IR : std_logic;
  begin

    IR := '0';
    if RES_N = '0' then
      ICR_DATA_L <= "00000000";
      ICR_MASK_L <= "00000000";
    elsif ICR_READ_FLAG = '1' then
        ICR_DATA_L <= x"00";
    elsif falling_edge(PHI2) then
      if Wr = '1' and RS = x"D" then
        if DI(7) = '1' then
          ICR_MASK_L <= DI or ICR_MASK_L;
        else
          ICR_MASK_L <= not(DI) and ICR_MASK_L;
        end if;
      end if;
      if ICR_MASK_L(0) = '1' and INT_TMRA = '1' then
        ICR_DATA_L(0) <= '1'; IR := '1';
      end if;
      if ICR_MASK_L(1) = '1' and INT_TMRB = '1' then
        ICR_DATA_L(1) <= '1'; IR := '1';
      end if;
      if ICR_MASK_L(2) = '1' and INT_TODALARM = '1' then
        ICR_DATA_L(2) <= '1'; IR := '1';
      end if;
      if ICR_MASK_L(3) = '1' and INT_SP = '1' then
        ICR_DATA_L(3) <= '1'; IR := '1';
      end if;
      if ICR_MASK_L(4) = '1' and INT_FLAG = '1' then
        ICR_DATA_L(4) <= '1'; IR := '1';
      end if;
      if IR = '1' or ICR_DATA_L(4 downto 0) > "00000"  then
         ICR_DATA_L(7) <= '1'; -- data latch has interrupts
      else
         ICR_DATA_L(7) <= '0'; 
      end if;
    end if;
  end process;

-- IRQ_N
  IRQ <= ICR_DATA_L(7);

-- WRITE REGISTERS
--  process (PHI2,RES_N) is
--  begin
--    if RES_N = '0' then
--    elsif rising_edge(PHI2) then
--      if Wr = '1' and RS = x"D" then 
----      bit 7 of the mask latch tells if bits shall be either set or cleared.
--        if DI(7) = '1' then
--          ICR_MASK_L <= DI or ICR_MASK_L;
--        else
--          ICR_MASK_L <= not(DI) and ICR_MASK_L;
--        end if;
--      end if;
--    end if;
--  end process;

-- READ REGISTER
  process (PHI2) is
  begin
    if rising_edge(PHI2) then
      ICR_READ_FLAG <= '0';
      if Rd = '1' and RS = x"D" then
        data <= ICR_DATA_L(7) & '0' & '0' & ICR_DATA_L(4 downto 0);
        ICR_READ_FLAG <= '1';
      end if;
    end if;
  end process;

end architecture rtl;
