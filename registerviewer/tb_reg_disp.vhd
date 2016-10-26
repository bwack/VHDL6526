library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_reg_disp is
-- empty
end tb_reg_disp;

architecture beh1 of tb_reg_disp is
  signal PHI2, RES_N, RW, CS_N : std_logic;
  signal DATA, ABCDEFGDEC_N : std_logic_vector(7 downto 0);
  signal RS, DISPREG, A_N : std_logic_vector(3 downto 0);
  signal disp0,disp1,disp2,disp3:std_logic_vector(3 downto 0);
  constant HALFPERIOD : time := 500 ns;
begin
  -- dispreg is sw3..0
  REG_DISP_0: entity work.reg_disp(rtl)
  port map(phi2,res_n,rw,cs_n,data,rs,dispreg,abcdefgdec_n,a_n);

  seg7model_0: entity work.seg7model
  port map(a_n,abcdefgdec_n,disp3,disp2,disp1,disp0);

  P_CLK_0: process
  begin
    PHI2 <= '1';
    wait for HALFPERIOD;
    PHI2 <= '0';
    wait for HALFPERIOD;    
  end process P_CLK_0;

  STIMULI_0: process
  begin
    RES_N <= '0'; RW <= '1'; CS_N <= '1'; DATA <= x"00"; RS <= x"0"; DISPREG<=x"A";
    wait for HALFPERIOD*4;
    RES_N <= '1'; RW <= '1'; CS_N <= '1'; DATA <= x"00"; RS <= x"0"; DISPREG<=x"A";
    wait for HALFPERIOD*6;
    RES_N <= '1'; RW <= '0'; CS_N <= '0'; DATA <= x"13"; RS <= x"A"; DISPREG<=x"A";
    wait for HALFPERIOD*2;
    RES_N <= '1'; RW <= '1'; CS_N <= '1'; DATA <= x"00"; RS <= x"0"; DISPREG<=x"A";
    wait for HALFPERIOD*2;
    RES_N <= '1'; RW <= '1'; CS_N <= '1'; DATA <= x"00"; RS <= x"0"; DISPREG<=x"A";
    wait;
  end process stimuli_0;

end architecture beh1;

