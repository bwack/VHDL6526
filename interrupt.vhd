library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity interrupt is
-- Interrupt data and mask registers
  port (
-- DATA AND CONTROL
    PHI2    : in  std_logic; -- clock 1MHz
    DI      : in  std_logic_vector(7 downto 0); -- data in
    DO      : out std_logic_vector(7 downto 0); -- data out
    RS      : in  std_logic_vector(3 downto 0); -- register select
    RES_N   : in  std_logic; -- global reset
    Rd, Wr  : in  std_logic; -- read and write registers
-- INPUTS
    INTIN  : in std_logic_vector(4 downto 0);
--    INT_TMRA       : in std_logic;
--    INT_TMRB       : in std_logic;
--    INT_TODALARM   : in std_logic;
--    INT_SERIALPORT : in std_logic;
--    INT_FLAG       : in std_logic;
-- OUTPUTS
    IRQ_N          : out std_logic
  );
end entity interrupt;

architecture rtl of interrupt is
-- REGISTERS (Interrupt Control Register - x"D")
  signal ICR_DATA_L : std_logic_vector(7 downto 0); -- read only data latch
  signal ICR_MASK_L : std_logic_vector(7 downto 0); -- write only interrupt mask
-- FLAGS
  signal ICR_READ_FLAG : std_logic; 
begin

-- Interrupt registers
  process(PHI2,INTIN,ICR_READ_FLAG,RES_N) is
    variable IR : std_logic;
  begin
    IR := '0';
    if RES_N = '0' then
      ICR_DATA_L <= "00000000";
      ICR_MASK_L <= "00000000";
    elsif ICR_READ_FLAG = '1' then
        ICR_DATA_L <= x"00";
    elsif rising_edge(PHI2) then
      if Wr = '1' and RS = x"D" then
        if DI(7) = '1' then
          ICR_MASK_L <= DI or ICR_MASK_L;
        else
          ICR_MASK_L <= not(DI) and ICR_MASK_L;
        end if;
      end if;
      for i in 0 to 4 loop
        if INTIN(i) = '1' and ICR_MASK_L(i) = '1' then
          ICR_DATA_L(i) <= '1';
          IR := '1';
        end if;
      end loop;
      if IR = '1' or ICR_DATA_L(4 downto 0) > "00000"  then
         ICR_DATA_L(7) <= '1'; -- data latch has interrupts
      else
         ICR_DATA_L(7) <= '0'; 
      end if;
    end if;
  end process;

-- IRQ_N
  IRQ_N <= not ICR_DATA_L(7);

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
      if Rd = '1' and RES_N = '1' then
        DO <= ICR_DATA_L(7) & '0' & '0' & ICR_DATA_L(4 downto 0);
        ICR_READ_FLAG <= '1';
      else
        ICR_READ_FLAG <= '0';
      end if;
    end if;
  end process;

end architecture rtl;
