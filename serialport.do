onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_serialport/PHI2
add wave -noupdate /tb_serialport/RES_N
add wave -noupdate /tb_serialport/Rd
add wave -noupdate /tb_serialport/Wr
add wave -noupdate /tb_serialport/DI
add wave -noupdate /tb_serialport/DO
add wave -noupdate /tb_serialport/RS
add wave -noupdate /tb_serialport/CRA_SPMODE
add wave -noupdate /tb_serialport/IRQ_N
add wave -noupdate /tb_serialport/SP
add wave -noupdate /tb_serialport/CNT
add wave -noupdate /tb_serialport/HALFPERIOD
add wave -noupdate /tb_serialport/UUT_SERIAL/SDR
add wave -noupdate -expand /tb_serialport/UUT_SERIAL/DFF
add wave -noupdate /tb_serialport/UUT_SERIAL/data
add wave -noupdate /tb_serialport/UUT_SERIAL/CNT_old
add wave -noupdate /tb_serialport/UUT_SERIAL/CNT_flag
add wave -noupdate /tb_serialport/UUT_SERIAL/sdr_loaded
add wave -noupdate /tb_serialport/UUT_SERIAL/loadsreg
add wave -noupdate /tb_serialport/UUT_SERIAL/shift_f
add wave -noupdate /tb_serialport/UUT_SERIAL/present_state
add wave -noupdate /tb_serialport/UUT_SERIAL/next_state
add wave -noupdate /tb_serialport/UUT_SERIAL/read_flag
add wave -noupdate /tb_serialport/UUT_SERIAL/write_flag
add wave -noupdate /tb_serialport/UUT_SERIAL/timed
add wave -noupdate /tb_serialport/UUT_SERIAL/dec
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {533500 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 264
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {840 us}
