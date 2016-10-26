library ieee;
use ieee.std_logic_1164.all;

entity tb_sevensegmentdecoder is
end tb_sevensegmentdecoder;

architecture beh1 of tb_sevensegmentdecoder is
  component sevensegmentdecoder
    port ( 
      input     : in  std_logic_vector(3 downto 0);
      output    : out std_logic_vector(7 downto 0)
    );
  end component;

  signal indata  : std_logic_vector(3 downto 0) := "0000";
  signal outdata : std_logic_vector(7 downto 0);
 
begin
  UUT_0: entity work.sevensegmentdecoder(rtl)
    port map (
       input  => indata,
       output => outdata
    );

  -- Changed indata
  -- indata <= "0000", "0001" after 100 ns;
  indata(0) <= not indata(0) after 100 ns;
  indata(1) <= not indata(1) after 200 ns;
  indata(2) <= not indata(2) after 400 ns;
  indata(3) <= not indata(3) after 800 ns;

end beh1;