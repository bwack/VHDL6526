// java -jar c:\kickass\KickAss.jar -showmem -binfile vhdl6526testcart.asm
// cartconv -t ulti -i vhdl6526testcart.bin -o testcart.crt

.var VIC_BORDER_COLOR     = $d020
.var VIC_BACKGROUND_COLOR = $d021
.var VIC_MEMORY_CONTROL   = $d018
.var VIC_CONTROL_REG_1    = $d011
.var VIC_CONTROL_REG_2    = $d016
.var SCREEN_COLOR         = $d800
.var PRA                  = $dc00
.var PRB                  = $dc01
.var DDRA                 = $dc02
.var DDRB                 = $dc03
.var VIDEOMEM             = $0400
.var CHARSET              = $0800

// Le Zeropage
.var PARAM1               = $03
.var PARAM2               = $05
.var PARAM3               = $07
.var PARAM4               = $09
.var PARAM5               = $0b
.var PARAM6               = $0d
.var COLOR                = $0f
.var RESULT               = $10
.var ZEROPAGE_POINTER_1   = $17
.var ZEROPAGE_POINTER_2   = $19
.var ZEROPAGE_POINTER_3   = $21
.var ZEROPAGE_POINTER_4   = $23

.var TIMER_LO_PTR         = $29
.var TIMER_HI_PTR         = $2b
.var TIMER_CTRL_PTR       = $2d

.var TESTS_PASSED         = $0c

*=$e000 "Program"
.pseudopc $E000 {
irq1:
	lda $dc04
	lda $dc05
	
start:
	sei
	ldx #$FF
	txs
	cld
	lda #$e7
	sta $01
	lda #$37
	sta $00

loadcharset:
	lda #<font
	ldx #>font
	sta ZEROPAGE_POINTER_1   // source lower address
	stx ZEROPAGE_POINTER_1+1 // source higher address
	lda #<CHARSET
	ldx #>CHARSET
	sta ZEROPAGE_POINTER_2   // destination lower address
	stx ZEROPAGE_POINTER_2+1 // destination high address
	ldx #$01
	ldy #$00
loop1:
	lda (ZEROPAGE_POINTER_1),y
	sta (ZEROPAGE_POINTER_2),y
	iny
	bne loop1
	inc ZEROPAGE_POINTER_1+1
	inc ZEROPAGE_POINTER_2+1
	dex
	bpl loop1

	ldx #$04
	lda #$00
clear_tod:
	sta $dc07,x
	sta $dd07,x
	dex
	bne clear_tod
	ldx #$00
	stx $02
	stx $03

	ldx #$00
clear_screen:
	lda #$20
	sta VIDEOMEM,x
	sta VIDEOMEM+$100,x
	sta VIDEOMEM+$200,x
	sta VIDEOMEM+$300,x
	lda #$20
	sta $d800,x
	sta $d900,x
	sta $da00,x
	sta $db00,x
	inx
	bne clear_screen

vic_values:
	ldx #$2f
vic_values_1:
	lda vicvalues,x
	sta $cfff,x
	dex
	bne vic_values_1
	
	lda #%10011011
	sta VIC_CONTROL_REG_1
	lda #%00001000
	sta VIC_CONTROL_REG_2

	lda #$0d
	sta VIC_BORDER_COLOR
	lda #$05
	sta VIC_BACKGROUND_COLOR
	lda #$12
	sta VIC_MEMORY_CONTROL
	ldx #$00

	lda #<title_top
	sta ZEROPAGE_POINTER_3
	lda #>title_top
	sta ZEROPAGE_POINTER_3+1
	lda #$00    // color
	sta PARAM1
	ldx #$01     // row
	ldy #$02     // column
	jsr print_text

	lda #<title_timer
	sta ZEROPAGE_POINTER_3
	lda #>title_timer
	sta ZEROPAGE_POINTER_3+1
	lda #$07    // color
	sta PARAM1
	ldx #$03     // row
	ldy #$02     // column
	jsr print_text


main:

	jsr set_timer_pointers_to_timer_a
	jsr cursor_move_to_position

	ldx #$04     // row
	ldy #$01     // column
	jsr cursor_move_to_position
	jsr test_1

	ldx #$05     // row
	ldy #$01     // column
	jsr cursor_move_to_position
	jsr test_2

	ldx #$06     // row
	ldy #$01     // column
	jsr cursor_move_to_position
	jsr test_3

	ldx #$07     // row
	ldy #$01     // column
	jsr cursor_move_to_position
	jsr test_4

// tests 1-4 repeated for timer b
	jsr set_timer_pointers_to_timer_b
	
	ldx #$04     // row
	ldy #$15     // column
	jsr cursor_move_to_position
	jsr test_1

	ldx #$05     // row
	ldy #$15     // column
	jsr cursor_move_to_position
	jsr test_2

	ldx #$06     // row
	ldy #$15     // column
	jsr cursor_move_to_position
	jsr test_3

	ldx #$07     // row
	ldy #$15     // column
	jsr cursor_move_to_position
	jsr test_4

	ldx #$09     // row
	ldy #$01     // column
	jsr cursor_move_to_position
	jsr test_5

	jsr reset_timer_a
	//jmp main
end:
	jmp end
// ----------------------------------

reset_timer_a:
	lda	#$00
	sta $dc0e
	lda #$ff
	sta $dc04
	sta $dc05
	rts
	
reset_ports:
	lda #$00
	sta DDRA
	sta DDRB
	sta PRA
	sta PRB
	rts

set_timer_pointers_to_timer_a:
	lda #$04
	sta TIMER_LO_PTR
	lda #$05
	sta TIMER_HI_PTR
	lda #$0e
	sta TIMER_CTRL_PTR
	lda #$dc
	sta TIMER_LO_PTR+1
	sta TIMER_HI_PTR+1
	sta TIMER_CTRL_PTR+1
	rts

set_timer_pointers_to_timer_b:
	lda #$06
	sta TIMER_LO_PTR
	lda #$07
	sta TIMER_HI_PTR
	lda #$0f
	sta TIMER_CTRL_PTR
	lda #$dc
	sta TIMER_LO_PTR+1
	sta TIMER_HI_PTR+1
	sta TIMER_CTRL_PTR+1
	rts

	/* From the datasheet:
	The timer latch is loaded into the timer on any timer
	underflow, on a force load or following a write to the high
	byte of the prescaler while the timer is stopped. If the
	timer is running, a write to the high byte will load the
	timer latch, but not reload the counter.
*/

/*	function: test_1
	Check that default value of timera and timerb are FFFF
	Count pulses on CNT pin
*/
test_1:
	lda #$01                // testnumber
	jsr print_test_prompt

	ldy #$00
	lda (TIMER_LO_PTR),y
	sta PARAM2
	lda (TIMER_HI_PTR),y
	sta PARAM2+1

	// test FFFF
	lda #$02                // red
	sta COLOR               // color
	lda PARAM2
	cmp #$ff
	bne test_1_print_timer
	lda PARAM2+1
	cmp #$ff
	bne test_1_print_timer
	lda #$0d                // lightgreen
	sta COLOR               // color
test_1_print_timer:
	lda PARAM2+1
	jsr printhex
	lda PARAM2
	jsr printhex

	// test CNT as timer input, positive edges
	// CNT low initially
	// ------------------------------------------

	jsr reset_ports
	lda #$00                // PA6 low initially
	sta PRA
	lda #$40                // PA6 as output
	sta DDRA

	lda	#$00                // stop timer
	ldy #$00
	sta (TIMER_CTRL_PTR),y
	lda #$ff                // set latches
	sta (TIMER_LO_PTR),y
	sta (TIMER_HI_PTR),y
	lda #$21                // cnt=input, start
	sta (TIMER_CTRL_PTR),y
	nop
	lda #$40                // positive edge
	sta PRA
	lda #$00
	sta PRA
	lda #$40                // positive edge
	sta PRA
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM2
	lda (TIMER_HI_PTR),y
	sta PARAM2+1
	lda	#$00                // stop timer
	ldy #$00
	sta (TIMER_CTRL_PTR),y

	// test CNT as timer input, positive edges
	// CNT high initially
	// -------------------------------------------

	sta (TIMER_CTRL_PTR),y
	lda #$ff                // set latches
	sta (TIMER_LO_PTR),y
	sta (TIMER_HI_PTR),y
	lda #$40                // PA6 high initially
	sta PRA
	lda #$21                // cnt=input, start
	sta (TIMER_CTRL_PTR),y
	lda #$00                // negative edge
	sta PRA
	lda #$40
	sta PRA
	lda #$00                // negative edge
	sta PRA
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM3
	lda (TIMER_HI_PTR),y
	sta PARAM3+1
	lda	#$00                // stop timer
	ldy #$00
	sta (TIMER_CTRL_PTR),y

	// print
	// --------------------------------------

	lda #$20
	jsr printit

	lda #$02                // red
	sta COLOR
	lda PARAM2+1
	cmp #$ff
	bne test_1_print_cnt_input_1
	lda PARAM2
	cmp #$fd
	bne test_1_print_cnt_input_1
	lda #$0d                // lightgreen
	sta COLOR
test_1_print_cnt_input_1:
	lda PARAM2+1
	jsr printhex
	lda PARAM2
	jsr printhex
	lda #$20
	jsr printit

	lda #$02                // red
	sta COLOR
	lda PARAM3+1
	cmp #$ff
	bne test_1_print_cnt_input_2
	lda PARAM3
	cmp #$fe
	bne test_1_print_cnt_input_2
	lda #$0d                // lightgreen
	sta COLOR
test_1_print_cnt_input_2:
	lda PARAM3+1
	jsr printhex
	lda PARAM3
	jsr printhex

	rts


/*	function: test_2
	Set timer latch, check, start-stop, check
*/
test_2:
	lda #$02     // testnumber
	jsr print_test_prompt

	// timer is loaded with latches
	// when timer is stopped
	lda	#$00                // stop timer
	ldy #$00
	sta (TIMER_CTRL_PTR),y
	lda #$aa                // set latches
	sta (TIMER_LO_PTR),y
	sta (TIMER_HI_PTR),y
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM2
	lda (TIMER_HI_PTR),y
	sta PARAM2+1

	// run the timer for some cycles
	jsr waitvertical
	ldy #$00
	lda #$01                // start timer
	sta (TIMER_CTRL_PTR),y
	lda #$00                // stop timer
	sta (TIMER_CTRL_PTR),y
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM3
	lda (TIMER_HI_PTR),y
	sta PARAM3+1
 
	// test AAAA
	lda #$02     // red
	sta COLOR // color
	lda PARAM2+1
	cmp #$aa
	bne test_2_print_timera_1
	lda PARAM2
	cmp #$aa
	bne test_2_print_timera_1
	lda #$0d     // lightgreen
	sta COLOR // color
test_2_print_timera_1:
	lda PARAM2+1
	jsr printhex
	lda PARAM2
	jsr printhex
	lda #$20
	jsr printit

	// test AAA2
	lda #$02     // red
	sta COLOR // color
	lda PARAM3+1
	cmp #$aa
	bne test_2_print_timera_2
	lda PARAM3
	cmp #$a2
	bne test_2_print_timera_2
	lda #$0d     // lightgreen
	sta COLOR // color
test_2_print_timera_2:
	lda PARAM3+1
	jsr printhex
	lda PARAM3
	jsr printhex
	rts

/*	function: test_3
	continuous: timer underflows, loads latches, and continues, check,
	continuous: loads latches on a forced load, and continues, check,
	one-shot: timer underflows, loads latches, then stops, check.
	continues: check underflow flag on PB6 and PB7
*/
test_3:
	lda #$03     // testnumber
	jsr print_test_prompt

	// continuous mode: load latches on a forced load, and continues

	ldy #$00
	sta (TIMER_CTRL_PTR),y
	lda #$00                // stop timer
	sta (TIMER_CTRL_PTR),y
	lda #$aa                // set latches
	sta (TIMER_LO_PTR),y
	sta (TIMER_HI_PTR),y
	lda #$01                // start timer
	sta (TIMER_CTRL_PTR),y
	nop
	nop
	nop
	nop
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM2
	lda (TIMER_HI_PTR),y
	sta PARAM2+1
	lda #$11     // force reload and sustain running
	sta (TIMER_CTRL_PTR),y
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM3
	lda (TIMER_HI_PTR),y
	sta PARAM3+1

	// PARAM2 < PARAM3
	lda #$0d     // lightgreen
	sta COLOR
	jsr sub_16_param2_minus_param3_into_result
	bmi test3_print_reload_test
	lda #$02     // red
	sta COLOR
test3_print_reload_test:
//	lda PARAM2+1
//	sta PARAM1
//	jsr printhex
//	lda PARAM2
//	sta PARAM1
//	jsr printhex
//	lda #$20
//	jsr printit
//
//	lda PARAM3+1
//	sta PARAM1
//	jsr printhex
//	lda PARAM3
//	sta PARAM1
//	jsr printhex
//	lda #$20
//	jsr printit

	lda #$00
	jsr printit
	lda #$20
	jsr printit
	jsr printit
	jsr printit
	jsr printit
	jsr printit


	// continuous mode, reload latches on underflow

	ldy #$00
	lda #$00                // stop timer
	sta (TIMER_CTRL_PTR),y
	lda #$ff                // set latches
	sta (TIMER_LO_PTR),y
	sta (TIMER_HI_PTR),y
	lda	#$01                // start timer
	sta (TIMER_CTRL_PTR),y

	lda #$50     // loop 16 times to show the number spinning
test3_reload_test:
	pha          // loop index is used further down, stacking it
	ldy #$00
	
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM2
	lda (TIMER_HI_PTR),y
	sta PARAM2+1

	// test not stopped at ffff or 0000
	lda #$02     // red
	sta COLOR
	lda PARAM2+1
	cmp #$ff
	beq test_3_print_timera_1
	lda PARAM2
	cmp #$ff
	beq test_3_print_timera_1
	lda PARAM2+1
	cmp #$00
	beq test_3_print_timera_1
	lda PARAM2
	cmp #$00
	beq test_3_print_timera_1
	lda #$0d                // lightgreen
	sta COLOR               // color

test_3_print_timera_1:
	jsr cursor_move_left
	jsr cursor_move_left
	jsr cursor_move_left
	jsr cursor_move_left
	lda PARAM2+1
	jsr printhex
	lda PARAM2
	jsr printhex

	jsr waitvertical
	pla
	clc
	adc #$ff
	bne test3_reload_test

	lda	#$00                // stop timer
	ldy #$00
	sta (TIMER_CTRL_PTR),y

	lda #$20     // space
	jsr printit


	// one-shot mode: reload latches on underflow, and stop


	lda #$01                // set latches
	ldy #$00
	sta (TIMER_LO_PTR),y
	sta (TIMER_HI_PTR),y
	lda	#$09     // start timera, oneshot mode
	sta (TIMER_CTRL_PTR),y
	nop
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM3
	lda (TIMER_HI_PTR),y
	sta PARAM3+1
	ldy #$30
test3_loop_2:    // it shall stop in this loop
	dey
	bne test3_loop_2
	ldy #$00
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM4
	lda (TIMER_HI_PTR),y
	sta PARAM4+1
	lda #$00                // stop timera
	sta (TIMER_CTRL_PTR),y

	// timer < 0101 (check that it was running)
	lda #$01
	sta PARAM2
	lda #$01
	sta PARAM2+1
	lda #$02     // red
	sta COLOR    // color
	jsr sub_16_param2_minus_param3_into_result
	jsr dec_result_16
	bmi test_3_print_timera_2
	lda #$0d     // lightgreen
	sta COLOR // color
test_3_print_timera_2:
	//lda PARAM3+1
	//sta PARAM1
	//jsr printhex
	//lda PARAM3
	//sta PARAM1
	//jsr printhex
	//lda #$20
	//jsr printit
	//lda #$20
	//jsr printit
	lda #$00
	jsr printit

	// timer == 0101 (timer stopped and reloaded latch)
	lda #$02     // red
	sta COLOR // color
	lda PARAM4+1
	cmp #$01
	bne test_3_print_timera_3
	lda PARAM4
	cmp #$01
	bne test_3_print_timera_3
	lda #$0d     // lightgreen
	sta COLOR // color
test_3_print_timera_3:
	//lda PARAM4+1
	//sta PARAM1
	//jsr printhex
	//lda PARAM4
	//sta PARAM1
	//jsr printhex
	lda #$00
	jsr printit
	lda #$20
	jsr printit
	rts

/*	function: test_4
	timer loaded on write to high byte, while running
*/
test_4:
	lda #$04     // testnumber
	jsr print_test_prompt

	// test that timer is uninterupted by
	// a write to high byte, while running!
	lda	#$00                // stop timer
	ldy #$00
	sta (TIMER_CTRL_PTR),y
	lda #$aa                // set latches
	sta (TIMER_LO_PTR),y
	sta (TIMER_HI_PTR),y
	lda #$01                // start timer
	sta (TIMER_CTRL_PTR),y
	nop
	nop
	nop
	nop
	nop
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM2              // old value
	lda (TIMER_HI_PTR),y
	sta PARAM2+1
	lda #$aa                // set latches
	sta (TIMER_LO_PTR),y
	sta (TIMER_HI_PTR),y    // the high byte write
	nop
	lda (TIMER_LO_PTR),y    // read timer
	sta PARAM3              // new value
	lda (TIMER_HI_PTR),y
	sta PARAM3+1
	lda #$00                // stop timer
	sta (TIMER_CTRL_PTR),y

	// calculate difference
	//jsr sub_16_param2_minus_param3_into_result
	//lda RESULT
	//sta PARAM4
	//lda RESULT+1
	//sta PARAM4+1
	//jsr dec_result_16 // RESULT - 1
    //beq test_4_print_timera

	lda #$02     // red
	sta COLOR // color
	lda PARAM2+1
	cmp #$aa
	bne test_4_print_timer
	lda PARAM2
	cmp #$9d
	bne test_4_print_timer
	lda PARAM3+1
	cmp #$aa
	bne test_4_print_timer
	lda PARAM3
	cmp #$7d
	bne test_4_print_timer
	lda #$0d     // lightgreen
	sta COLOR    // color
test_4_print_timer:
	lda PARAM2+1
	jsr printhex
	lda PARAM2
	jsr printhex
	lda #$20
	jsr printit
	lda PARAM3+1
	jsr printhex
	lda PARAM3
	jsr printhex
	lda #$20
	jsr printit
	lda #$20
	jsr printit
	rts

/*	function: test_5
	check underflow flag on PB6
	- timer a counts systemcycles and underflows are
	  pulsed on PB6. PB6 is wired to CNT. timer b
	  counts pulses on CNT and shows if PB6 is working
*/
test_5:
	lda #$05                // testnumber
	jsr print_test_prompt

	// count PB6 one-cycle long pulses
	
	jsr reset_ports
	lda	#$00                // stop timer a and b
	sta $dc0e
	sta $dc0f
	lda #$01                // set latches timer a
	sta $dc04
	sta $dc05
	lda #$ff                // set latches timer b
	sta $dc06
	sta $dc07
	lda #$21                // count=cnt, start timer b
	sta $dc0f
	lda #$03                // PB out, start timer a
	sta $dc0e
	ldx #$ff                // run for a while
test_5_loop:
	dex
	bne test_5_loop
	lda	#$00                // stop timer a and b
	sta $dc0e
	sta $dc0f
	lda $dc05               // read timer b
	sta PARAM2
	lda $dc06
	sta PARAM2+1

	// count PB6 toggles

	lda #$01                // set latches timer a
	sta $dc04
	sta $dc05
	lda #$ff                // set latches timer b
	sta $dc06
	sta $dc07
	lda #$21                // count=cnt, start timer b
	sta $dc0f
	lda #$07                // PB out toggle, start timer a
	sta $dc0e
	ldx #$ff                // run for a while
test_5_loop2:
	dex
	bne test_5_loop2
	lda	#$00                // stop timer a and b
	sta $dc0e
	sta $dc0f
	lda $dc05               // read timer b
	sta PARAM3
	lda $dc06
	sta PARAM3+1

	// print
	// calculate difference
	jsr sub_16_param2_minus_param3_into_result
	lda RESULT
	sta PARAM4
	lda RESULT+1
	sta PARAM4+1
	jsr dec_result_16 // RESULT - 1
    beq test_5_print
	lda #$02     // red
	sta COLOR // color
test_5_print:
	lda PARAM2+1
	jsr printhex
	lda PARAM2
	jsr printhex
	lda #$2d                // -
	jsr printit
	lda PARAM3+1
	jsr printhex
	lda PARAM3
	jsr printhex
	lda #$3d                // =
	jsr printit
	lda PARAM4+1
	jsr printhex
	lda PARAM4
	jsr printhex
	lda #$20
	jsr printit
	rts


	rts
	
add_16:
	clc
	lda PARAM5
	adc PARAM6
	sta RESULT
	lda PARAM5+1
	adc PARAM6+1
	sta RESULT
	rts

sub_16_param2_minus_param3_into_result:
	sec
	lda PARAM2
	sbc PARAM3
	sta RESULT
	lda PARAM2+1
	sbc PARAM3+1
	sta RESULT+1
	rts

sub_16:
	sec
	lda PARAM5
	sbc PARAM6
	sta RESULT
	lda PARAM5+1
	sbc PARAM6+1
	sta RESULT+1
	rts

dec_result_16:
	sec
	lda RESULT
	sbc #$01
	sta RESULT
	lda RESULT+1
	sbc #$00
	sta RESULT+1
	rts

/*	function: printit
	input: acc=character, COLOR=color,
	ZEROPAGE_POINTER_1 (char) and ZEROPAGE_POINTER_2 (charcolor)
	moves ZEROPAGE_POINTER_1 and ZEROPAGE_POINTER_2
*/
printit:
	pha
	ldy #$00
	sta (ZEROPAGE_POINTER_1),y
	lda COLOR
	sta (ZEROPAGE_POINTER_2),y
	clc
	lda ZEROPAGE_POINTER_1
	adc #$01
	sta ZEROPAGE_POINTER_1
	lda ZEROPAGE_POINTER_1+1
	adc #$00
	sta ZEROPAGE_POINTER_1+1
	// screen_color pointer
	clc
	lda ZEROPAGE_POINTER_2
	adc #$01
	sta ZEROPAGE_POINTER_2
	lda ZEROPAGE_POINTER_2+1
	adc #$00
	sta ZEROPAGE_POINTER_2+1
	pla
	rts

/*	function: print_test_prompt
	Prints "#01: "
*/
print_test_prompt:
	pha
	lda #$07
	sta COLOR
	lda #$23      // #
	jsr printit
	pla
	jsr printhex
	lda #$3a      // :
	jsr printit
	lda #$20      // space
	jsr printit
	rts

/*	function: printhex
	Prints two hexadecimal digits to desired position on the screen
	input:	acc=value, COLOR=color, Xreg=rowposition, Yreg=columnposition
	writes:	ZEROPAGE_POINTER_1 (char) and ZEROPAGE_POINTER_2 (charcolor)
*/
printhex:
	pha
	ldy #$00
	ror
	ror
	ror
	ror
	and #$0f
	jsr hexdigit
	jsr printit
	pla
	and #$0f
	jsr hexdigit
	jsr printit
	rts

/*
	https://www.atarimagazines.com/compute/issue36/060_MACHINE_LANGUAGE.php
	COMPUTE! ISSUE 36 / MAY 1983 / PAGE 156
	Jim Butterfield, MACHINE LANGUAGE
	
	Function input: acc, returns: acc.
*/
hexdigit:
	cmp #$0A   // alphabetic digit?
	bcc skip   // no, skip next part
	sbc #$09   // subtract 9
	rts
skip:
	adc #$30   // convert to ASCII
	rts
	
/*	function: print_text
	Prints #$ff terminated text string at desired position on the screen
	input:	ZEROPAGE_POINTER_3=stringaddress,
			PARAM1=color,
			Xreg=rowposition,
			Yreg=columnposition
	writes:	ZEROPAGE_POINTER_1 (char) and ZEROPAGE_POINTER_2 (charcolor), Yreg, Xreg
*/
print_text:
	jsr cursor_move_to_position
	ldy #$00
print_loop:
	lda (ZEROPAGE_POINTER_3),y // load char
	cmp #$ff                   // the end ? 
	beq print_end
	sta (ZEROPAGE_POINTER_1),y
	lda PARAM1                 // load color
	sta (ZEROPAGE_POINTER_2),y
	iny
	jmp print_loop
print_end:
	rts

cursor_move_left:
	sec
	lda RESULT
	sbc #$01
	sta RESULT
	lda RESULT+1
	sbc #$00
	sta RESULT+1
	
	sec
	lda ZEROPAGE_POINTER_1
	sbc #$01
	sta ZEROPAGE_POINTER_1
	lda ZEROPAGE_POINTER_1+1
	sbc #$00
	sta ZEROPAGE_POINTER_1+1
	sec
	lda ZEROPAGE_POINTER_2
	sbc #$01
	sta ZEROPAGE_POINTER_2
	lda ZEROPAGE_POINTER_2+1
	sbc #$00
	sta ZEROPAGE_POINTER_2+1
	rts

cursor_move_to_position:
	txa
	pha
	lda #<VIDEOMEM
	sta ZEROPAGE_POINTER_1
	lda #>VIDEOMEM
	sta ZEROPAGE_POINTER_1+1
	lda #<SCREEN_COLOR
	sta ZEROPAGE_POINTER_2
	lda #>SCREEN_COLOR
	sta ZEROPAGE_POINTER_2+1
	txa
	beq skip_line_done
	dex
skip_to_line:
	beq skip_line_done
	// videomem pointer
	clc
	lda ZEROPAGE_POINTER_1
	adc #$28
	sta ZEROPAGE_POINTER_1
	lda ZEROPAGE_POINTER_1+1
	adc #$00
	sta ZEROPAGE_POINTER_1+1
	// screen_color pointer
	clc
	lda ZEROPAGE_POINTER_2
	adc #$28
	sta ZEROPAGE_POINTER_2
	lda ZEROPAGE_POINTER_2+1
	adc #$00
	sta ZEROPAGE_POINTER_2+1
	dex
	jmp skip_to_line
skip_line_done:
	tya
	beq move_done
	dey
move_to_char:
	beq move_done
	clc
	lda ZEROPAGE_POINTER_1
	adc #$01
	sta ZEROPAGE_POINTER_1
	lda ZEROPAGE_POINTER_1+1
	adc #$00
	sta ZEROPAGE_POINTER_1+1
	// screen_color pointer
	clc
	lda ZEROPAGE_POINTER_2
	adc #$01
	sta ZEROPAGE_POINTER_2
	lda ZEROPAGE_POINTER_2+1
	adc #$00
	sta ZEROPAGE_POINTER_2+1
	dey
	jmp move_to_char
move_done:
	pla
	tax
	rts

waitvertical:
	lda #$00
wait:
	cmp $d012
	bne wait
	rts

	.align $0100
vicvalues:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$1b,$00,$00,$00,$00,$08,$00
	.byte $12,$00,$00,$00,$00,$00,$00,$00
	.byte $03,$01,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00

title_top: .text " vhdl6526-testcart 0.1     bwack 2020  "
.byte $ff // string terminator
title_timer: .text "   --- timer a ---     --- timer b --- "
.byte $ff // string terminator

font:
	.import c64 "action_wave.64c", $0, $200
}

	*=$fffa "Vectors"
	.word start
	.word start
	.word irq1

