vcom -work work -2008 -explicit -stats=none ../VHDL6526/src/timera.vhd
vcom -work work -2008 -explicit -stats=none ../VHDL6526/src/timerb.vhd
vcom -work work -2008 -explicit -stats=none ../VHDL6526/tb/base_pck.vhd
vcom -work work -2008 -explicit -stats=none ../VHDL6526/tb/tb_timer.vhd
# do ../VHDL6526/timerwave.do
restart -f
run -all
