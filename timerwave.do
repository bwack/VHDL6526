onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_timera/PHI2
add wave -noupdate /tb_timera/RES_N
add wave -noupdate /tb_timera/Rd
add wave -noupdate /tb_timera/Wr
add wave -noupdate /tb_timera/DI
add wave -noupdate /tb_timera/DO
add wave -noupdate /tb_timera/RS
add wave -noupdate /tb_timera/TMRA_OUT
add wave -noupdate /tb_timera/TMRB_OUT
add wave -noupdate /tb_timera/TMRA_UNDERFLOW
add wave -noupdate /tb_timera/TMRA_PB_ON_EN
add wave -noupdate /tb_timera/TMRB_PB_ON_EN
add wave -noupdate /tb_timera/CNT
add wave -noupdate /tb_timera/TMRA_IRQ
add wave -noupdate /tb_timera/TMRB_IRQ
add wave -noupdate /tb_timera/HALFPERIOD
add wave -noupdate /tb_timera/UUT_TMRA/TMRA
add wave -noupdate /tb_timera/UUT_TMRB/TMRB
add wave -noupdate /tb_timera/UUT_TMRA/TA_LO
add wave -noupdate /tb_timera/UUT_TMRA/TA_HI
add wave -noupdate /tb_timera/UUT_TMRA/CRA_START
add wave -noupdate /tb_timera/UUT_TMRA/CRA_PBON
add wave -noupdate /tb_timera/UUT_TMRA/CRA_OUTMODE
add wave -noupdate /tb_timera/UUT_TMRA/CRA_RUNMODE
add wave -noupdate /tb_timera/UUT_TMRA/CRA_LOAD
add wave -noupdate /tb_timera/UUT_TMRA/CRA_INMODE
add wave -noupdate /tb_timera/UUT_TMRA/CRA_SPMODE
add wave -noupdate /tb_timera/UUT_TMRA/CRA_TODIN
add wave -noupdate /tb_timera/UUT_TMRA/TMRCLOCK
add wave -noupdate /tb_timera/UUT_TMRA/CNTSYNCED
add wave -noupdate /tb_timera/UUT_TMRB/TB_LO
add wave -noupdate /tb_timera/UUT_TMRB/TB_HI
add wave -noupdate /tb_timera/UUT_TMRB/CRB_START
add wave -noupdate /tb_timera/UUT_TMRB/CRB_PBON
add wave -noupdate /tb_timera/UUT_TMRB/CRB_OUTMODE
add wave -noupdate /tb_timera/UUT_TMRB/CRB_RUNMODE
add wave -noupdate /tb_timera/UUT_TMRB/CRB_LOAD
add wave -noupdate /tb_timera/UUT_TMRB/CRB_INMODE
add wave -noupdate /tb_timera/UUT_TMRB/CRB_ALARM
add wave -noupdate /tb_timera/UUT_TMRB/TMRCLOCK
add wave -noupdate /tb_timera/UUT_TMRA/CNTSYNCED
add wave -noupdate /tb_timera/UUT_TMRB/TMRTOGGLE
add wave -noupdate /tb_timera/UUT_TMRB/underflow_flag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {213889 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 248
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
WaveRestoreZoom {0 ns} {1050 us}
