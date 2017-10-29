onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/RES_N
add wave -noupdate /testbench/PHI2
add wave -noupdate /testbench/CS_N
add wave -noupdate /testbench/RW
add wave -noupdate /testbench/RS
add wave -noupdate /testbench/DB
add wave -noupdate /testbench/SP
add wave -noupdate /testbench/CNT
add wave -noupdate /testbench/FLAG_N
add wave -noupdate /testbench/PC_N
add wave -noupdate /testbench/TOD
add wave -noupdate /testbench/UUT_0/TIMEOFDAY_0/tod_int
add wave -noupdate /testbench/PA
add wave -noupdate /testbench/PB
add wave -noupdate /testbench/IRQ_N
add wave -noupdate /testbench/UUT_0/TIMERA_0/CRA_START
add wave -noupdate /testbench/UUT_0/TIMERA_0/TMRA
add wave -noupdate /testbench/UUT_0/TIMERA_0/underflow_flag
add wave -noupdate /testbench/UUT_0/TIMEOFDAY_0/TOD_10THS_L
add wave -noupdate /testbench/UUT_0/TIMEOFDAY_0/TOD_SEC_L
add wave -noupdate /testbench/UUT_0/TIMEOFDAY_0/TOD_MIN_L
add wave -noupdate /testbench/UUT_0/TIMEOFDAY_0/TOD_HR_L
add wave -noupdate /testbench/UUT_0/INTERRUPT_0/ICR_DATA_L
add wave -noupdate -expand /testbench/UUT_0/SERIALPORT_0/SR
add wave -noupdate /testbench/UUT_0/SERIALPORT_0/SR_OUT
add wave -noupdate /testbench/UUT_0/SERIALPORT_0/SPMODE_old
add wave -noupdate /testbench/UUT_0/SERIALPORT_0/SPMODE_delay
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {448980 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 281
configure wave -valuecolwidth 39
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
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ns} {525 us}
