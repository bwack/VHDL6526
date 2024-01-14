# The VHDL6526-TESTCART

Detailed description of the cart will come later.

Build with build script:
[buildandrun.bat](buildandrun.bat).

convert to crt format:
cartconv.exe -t ulti -i vhdl6526testcart.bin -o testcart.crt

run in VICE:
x64.exe -cartcrt testcart.crt

Burn the bin file to eeprom. Use a cartridge configured for Ultimax mode (see VersaCart64).
