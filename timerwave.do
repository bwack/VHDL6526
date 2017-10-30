onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_timer/PHI2
add wave -noupdate /tb_timer/RES_N
add wave -noupdate /tb_timer/Rd
add wave -noupdate /tb_timer/Wr
add wave -noupdate /tb_timer/DI
add wave -noupdate /tb_timer/DO
add wave -noupdate /tb_timer/RS
add wave -noupdate /tb_timer/TMRA_OUT
add wave -noupdate /tb_timer/TMRB_OUT
add wave -noupdate /tb_timer/TMRA_UNDERFLOW
add wave -noupdate /tb_timer/TMRA_PB_ON_EN
add wave -noupdate /tb_timer/TMRB_PB_ON_EN
add wave -noupdate /tb_timer/CNT
add wave -noupdate /tb_timer/TMRA_IINT
add wave -noupdate /tb_timer/TMRB_IINT
add wave -noupdate /tb_timer/HALFPERIOD
add wave -noupdate /tb_timer/UUT_TMRA/TMRA
add wave -noupdate /tb_timer/UUT_TMRB/TMRB
add wave -noupdate /tb_timer/UUT_TMRA/TA_LO
add wave -noupdate /tb_timer/UUT_TMRA/TA_HI
add wave -noupdate /tb_timer/UUT_TMRA/CRA_START
add wave -noupdate /tb_timer/UUT_TMRA/CRA_PBON
add wave -noupdate /tb_timer/UUT_TMRA/CRA_OUTMODE
add wave -noupdate /tb_timer/UUT_TMRA/CRA_RUNMODE
add wave -noupdate /tb_timer/UUT_TMRA/CRA_LOAD
add wave -noupdate /tb_timer/UUT_TMRA/CRA_INMODE
add wave -noupdate /tb_timer/UUT_TMRA/CRA_SPMODE
add wave -noupdate /tb_timer/UUT_TMRA/CRA_TODIN
add wave -noupdate /tb_timer/UUT_TMRA/TMRCLOCK
add wave -noupdate /tb_timer/UUT_TMRA/CNTSYNCED
add wave -noupdate /tb_timer/UUT_TMRB/TB_LO
add wave -noupdate /tb_timer/UUT_TMRB/TB_HI
add wave -noupdate /tb_timer/UUT_TMRB/CRB_START
add wave -noupdate /tb_timer/UUT_TMRB/CRB_PBON
add wave -noupdate /tb_timer/UUT_TMRB/CRB_OUTMODE
add wave -noupdate /tb_timer/UUT_TMRB/CRB_RUNMODE
add wave -noupdate /tb_timer/UUT_TMRB/CRB_LOAD
add wave -noupdate /tb_timer/UUT_TMRB/CRB_INMODE
add wave -noupdate /tb_timer/UUT_TMRB/CRB_ALARM
add wave -noupdate /tb_timer/UUT_TMRB/TMRCLOCK
add wave -noupdate /tb_timer/UUT_TMRA/CNTSYNCED
add wave -noupdate /tb_timer/UUT_TMRB/TMRTOGGLE
add wave -noupdate /tb_timer/UUT_TMRB/underflow_flag
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
