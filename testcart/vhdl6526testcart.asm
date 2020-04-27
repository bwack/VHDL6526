// java -jar c:\kickass\KickAss.jar -showmem -binfile vhdl6526testcart.asm
// cartconv -t ulti -i vhdl6526testcart.bin -o testcart.crt

.var VIC_BORDER_COLOR     = $d020
.var VIC_BACKGROUND_COLOR = $d021
.var VIC_MEMORY_CONTROL   = $d018
.var VIC_CONTROL_REG_1    = $d011
.var VIC_CONTROL_REG_2    = $d016
.var SCREEN_COLOR         = $d800
.var CIA_PRA              = $dd00
.var VIDEOMEM             = $0400
.var CHARSET              = $0800

.var PARAM1               = $03
.var PARAM2               = $05
.var PARAM3               = $07
.var PARAM4               = $09
.var PARAM5               = $0b
.var ZEROPAGE_POINTER_1   = $17
.var ZEROPAGE_POINTER_2   = $19
.var ZEROPAGE_POINTER_3   = $21
.var ZEROPAGE_POINTER_4   = $23

.var tmra                 = $25
.var tmrb                 = $27

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

	lda #<titlemsg
	sta ZEROPAGE_POINTER_3
	lda #>titlemsg
	sta ZEROPAGE_POINTER_3+1
	lda #$07    // color
	sta PARAM1
	ldx #$01     // row
	ldy #$07     // column
	jsr print_text
	
	lda #<subtitlemsg
	sta ZEROPAGE_POINTER_3
	lda #>titlemsg
	sta ZEROPAGE_POINTER_3+1
	lda #$07    // color
	sta PARAM1
	ldx #$02     // row
	ldy #$1a     // column
	jsr print_text
main:
	jsr test_1
	jsr test_2
	jsr test_3
	jsr reset_timer_a
	jmp main
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

get_tmra:
	lda $dc04
	sta tmra
	lda $dc05
	sta tmra+1
	rts
	
get_tmrb:
	lda $dc06
	sta tmrb
	lda $dc07
	sta tmrb+1
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
*/
test_1:
	jsr get_tmra
	jsr get_tmrb

	ldx #$04     // row
	ldy #$01     // column
	lda #$01     // testnumber
	jsr print_test_prompt

	// test FFFF
	lda #$02     // red
	sta PARAM1+1 // color
	lda tmra
	cmp #$ff
	bne test_1_print_timera
	lda tmra+1
	cmp #$ff
	bne test_1_print_timera
	lda #$0d     // lightgreen
	sta PARAM1+1 // color
test_1_print_timera:
	lda tmra+1
	sta PARAM1
	ldx #$04 // row
	ldy #$06 // column
	jsr printhex
	lda tmra
	sta PARAM1
	ldx #$04 // row
	ldy #$08 // column
	jsr printhex
	
	// test FFFF
	lda #$02     // red
	sta PARAM1+1 // color
	lda tmrb
	cmp #$ff
	bne test_1_print_timerb
	lda tmrb+1
	cmp #$ff
	bne test_1_print_timerb
	lda #$0d     // lightgreen
	sta PARAM1+1 // color
test_1_print_timerb:
	lda tmrb+1
	sta PARAM1
	ldx #$04 // row
	ldy #$0b // column
	jsr printhex
	lda tmrb
	sta PARAM1
	ldx #$04 // row
	ldy #$0d // column
	jsr printhex
	rts

/*	function: test_2
	Stop timera, Set timera latch, check, start-stop, check
*/
test_2:
	ldx #$05     // row
	ldy #$01     // column
	lda #$02     // testnumber
	jsr print_test_prompt

	// timer is loaded with latches
	// when timer is stopped
	lda	#$00     // stop timera
	sta $dc0e
	lda #$aa     // set latches
	sta $dc04
	sta $dc05
	lda $dc04    // read timera
	sta PARAM2
	lda $dc05
	sta PARAM2+1

	// run the timer for six cycles
	jsr waitvertical
	lda #$01     // start timer a
	sta $dc0e
	lda #$00     // stop timer a
	sta $dc0e
	lda $dc04    // read timera
	sta PARAM3
	lda $dc05
	sta PARAM3+1
 
	// test AAAA
	lda #$02     // red
	sta PARAM1+1 // color
	lda PARAM2+1
	cmp #$aa
	bne test_2_print_timera_1
	lda PARAM2
	cmp #$aa
	bne test_2_print_timera_1
	lda #$0d     // lightgreen
	sta PARAM1+1 // color
test_2_print_timera_1:
	lda PARAM2+1
	sta PARAM1
	ldx #$05 // row
	ldy #$06 // column
	jsr printhex
	lda PARAM2
	sta PARAM1
	ldx #$05 // row
	ldy #$08 // column
	jsr printhex

	// test AAA4
	lda #$02     // red
	sta PARAM1+1 // color
	lda PARAM3+1
	cmp #$aa
	bne test_2_print_timera_2
	lda PARAM3
	cmp #$a4
	bne test_2_print_timera_2
	lda #$0d     // lightgreen
	sta PARAM1+1 // color
test_2_print_timera_2:
	lda PARAM3+1
	sta PARAM1
	ldx #$05 // row
	ldy #$0b // column
	jsr printhex
	lda PARAM3
	sta PARAM1
	ldx #$05 // row
	ldy #$0d // column
	jsr printhex
	rts

/*	function: test_3
	timer reloads latches after underflow, check,
	timer stops at 0000, check.
*/
test_3:
	ldx #$06     // row
	ldy #$01     // column
	lda #$03     // testnumber
	jsr print_test_prompt

	// timer reloads latches after underflow
	lda	#$00     // stop timera
	sta $dc0e
	lda #$01     // set latches
	sta $dc04
	sta $dc05
	lda	#$01     // start timera
	sta $dc0e
	ldy #$30
test3_loop:
	dey
	bne test3_loop
	lda	#$00     // stop timera
	sta $dc0e
	lda $dc04    // read timera
	sta PARAM2
	lda $dc05
	sta PARAM2+1

	// timer stops at 0000, check.
	lda	#$00     // stop timera
	sta $dc0e
	lda #$01     // set latches
	sta $dc04
	sta $dc05
	lda	#$09     // start timera, stop timer after underflow
	sta $dc0e
	nop
	lda $dc04    // read timera (check that it is running)
	sta PARAM3
	lda $dc05
	sta PARAM3+1
	ldy #$30
test3_loop_2:
	dey
	bne test3_loop_2
	lda $dc04    // read timera (check stopped and loaded latch 0101)
	sta PARAM4
	lda $dc05
	sta PARAM4+1
	lda #$00     // stop timer a
	sta $dc0e 

	// test 00f8 (timer underflowed, and reloaded #$1010)
	lda #$02     // red
	sta PARAM1+1 // color
	lda PARAM2+1
	cmp #$00
	bne test_3_print_timera_1
	lda PARAM2
	cmp #$f8
	bne test_3_print_timera_1
	lda #$0d     // lightgreen
	sta PARAM1+1 // color
test_3_print_timera_1:
	lda PARAM2+1
	sta PARAM1
	ldx #$06 // row
	ldy #$06 // column
	jsr printhex
	lda PARAM2
	sta PARAM1
	ldx #$06 // row
	ldy #$08 // column
	jsr printhex

	// test 00fd
	lda #$02     // red
	sta PARAM1+1 // color
	lda PARAM3+1
	cmp #$00
	bne test_3_print_timera_2
	lda PARAM3
	cmp #$fd
	bne test_3_print_timera_2
	lda #$0d     // lightgreen
	sta PARAM1+1 // color
test_3_print_timera_2:
	lda PARAM3+1
	sta PARAM1
	ldx #$06 // row
	ldy #$0b // column
	jsr printhex
	lda PARAM3
	sta PARAM1
	ldx #$06 // row
	ldy #$0d // column
	jsr printhex
	
	// test 0101
	lda #$02     // red
	sta PARAM1+1 // color
	lda PARAM4+1
	cmp #$01
	bne test_3_print_timera_3
	lda PARAM4
	cmp #$01
	bne test_3_print_timera_3
	lda #$0d     // lightgreen
	sta PARAM1+1 // color
test_3_print_timera_3:
	lda PARAM4+1
	sta PARAM1
	ldx #$06 // row
	ldy #$10 // column
	jsr printhex
	lda PARAM4
	sta PARAM1
	ldx #$06 // row
	ldy #$12 // column
	jsr printhex
	rts

/*	function: print_test_prompt
	Prints "#01: "
*/
print_test_prompt:
	pha // push value to stack (we need it twice)
	txa
	pha // push row
	tya
	pha // push column

	lda #<testtxt
	sta ZEROPAGE_POINTER_3
	lda #>testtxt
	sta ZEROPAGE_POINTER_3+1
	lda #$07    // color
	sta PARAM1
	sta PARAM1+1
	//ldy #$01     // column
	jsr print_text
	//ldy #$02 // column

	pla // pull column
	clc
	adc #$01
	tay
	pla // pull row
	txa
	pla // pull value
	sta PARAM1
	jsr printhex
	rts

/*	function: printhex
	Prints two hexadecimal digits to desired position on the screen
	input:	PARAM1=value, PARAM1+1=color, Xreg=rowposition, Yreg=columnposition
	writes:	ZEROPAGE_POINTER_1 (char) and ZEROPAGE_POINTER_2 (charcolor)
*/
printhex:
	jsr _video_and_colormem_ptr_init_and_move_to_position
	lda PARAM1 // value to print
	ldy #$00
	ror
	ror
	ror
	ror
	and #$0f
	jsr hexdigit
	sta (ZEROPAGE_POINTER_1),y
	lda PARAM1+1
	sta (ZEROPAGE_POINTER_2),y

	lda PARAM1
	and #$0f
	jsr hexdigit
	iny // next char pos
	sta (ZEROPAGE_POINTER_1),y
	lda PARAM1+1
	sta (ZEROPAGE_POINTER_2),y
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
	jsr _video_and_colormem_ptr_init_and_move_to_position
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

_video_and_colormem_ptr_init_and_move_to_position:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
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

titlemsg: .text "cia testcart      bwack 2020"
.byte $ff // string terminator
subtitlemsg: .text "#vhdl6526"
.byte $ff // string terminator
testtxt: .text "#  :"
.byte $ff // string terminator

font:
	.import c64 "action_wave.64c", $0, $200
}

	*=$fffa "Vectors"
	.word start
	.word start
	.word irq1

