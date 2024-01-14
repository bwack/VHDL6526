library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity interrupt is
-- Interrupt data and mask registers
  port (
-- DATA AND CONTROL
    PHI2           : in  std_logic;
    DI             : in  std_logic_vector(7 downto 0);
    DO             : out std_logic_vector(7 downto 0);
    RS             : in  std_logic_vector(3 downto 0);
    RES_N          : in  std_logic;
    Wr             : in  std_logic;
    Rd             : in  std_logic;
-- INPUTS
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
-- REGISTERS (Interrupt Control Register - x"D")
  signal DATA_REG : std_logic_vector(4 downto 0); -- read only
  signal IR_REG   : std_logic;                    -- read only 
  signal MASK_REG : std_logic_vector(4 downto 0); -- write only

  signal INTERRUPT_INPUTS : std_logic_vector(4 downto 0);


begin
  DO <= IR_REG & '0' & '0' & DATA_REG;
  INTERRUPT_INPUTS <= INT_FLAG & INT_SP & INT_TODALARM & INT_TMRB & INT_TMRA;
  IRQ <= IR_REG;

  process(PHI2,RES_N) is
  begin

    if RES_N = '0' then
      DATA_REG <= "00000";
      IR_REG   <= '0';
      MASK_REG <= "00000";

    elsif falling_edge(PHI2) then
      DATA_REG(4 downto 0) <= DATA_REG(4 downto 0) or INTERRUPT_INPUTS;
      if (MASK_REG and DATA_REG) /= x"00" then
        IR_REG <= '1';
      end if;
      if RS = x"D" then
        if Wr = '1' then
          if DI(7) = '1' then
            MASK_REG <= DI(4 downto 0) or MASK_REG;
          else
            MASK_REG <= not(DI(4 downto 0)) and MASK_REG;
          end if;
        elsif Rd = '1' then
          DATA_REG <= "00000";
          IR_REG   <= '0';
        end if;
      end if;
    end if;
  end process;


end architecture rtl;
