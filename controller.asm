!to "controller.prg",cbm

*=$c000
	jmp demo

;----------------------------------------------------------------------

; C64 CIA#2 PB (user port)
nes_data = $dd01
nes_ddr  = $dd03

bit_latch = $08 ; PB3 (user port pin F)
bit_data1 = $10 ; PB4 (user port pin H)
bit_clk   = $20 ; PB5 (user port pin J)
bit_data2 = $40 ; PB6 (user port pin K)

; zero page
joy1 = $e0 ; 3 bytes
joy2 = $f0 ; 3 bytes

;
; byte 0:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;         NES  | A | B |SEL|STA|UP |DN |LT |RT |
;         SNES | B | Y |SEL|STA|UP |DN |LT |RT |
;
; byte 1:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;         NES  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
;         SNES | A | X | L | R | 1 | 1 | 1 | 1 |
; byte 2:
;         $00 = controller present
;         $FF = controller not present
;
; * Presence can be detected by checking byte 2.
; * NES vs. SNES can be detected by checking bits 0-3 in byte 1.
; * Note that bits 6 and 7 in byte 0 are different between NES and SNES.


get_joystick:
	lda #$ff-bit_data1-bit_data2
	sta nes_ddr
	lda #$00
	sta nes_data

	; pulse latch
	lda #bit_latch
	sta nes_data
	lda #0
	sta nes_data

	; read 2x 8 bits
	ldx #0
l2:	ldy #8
l1:	lda nes_data
;.assert bit_data2 > bit_data1, error, "bit_data2 must be greater than bit_data1, otherwise swap 1 vs. 2 here"
	cmp #bit_data2
	rol joy2,x
	and #bit_data1
	cmp #bit_data1
	rol joy1,x
	lda #bit_clk
	sta nes_data
	lda #0
	sta nes_data
	dey
	bne l1
	inx
	cpx #3
	bne l2

	rts


;----------------------------------------------------------------------


; ****************************************
; C64 DEMO CODE
; ****************************************
demo:
	lda #<tx_clr
	ldy #>tx_clr
	jsr $ab1e
	lda #<tx_controller
	ldy #>tx_controller
	jsr $ab1e
	lda #'1'
	jsr $ffd2
	lda #<tx_buttons
	ldy #>tx_buttons
	jsr $ab1e
	lda #<tx_controller
	ldy #>tx_controller
	jsr $ab1e
	lda #'2'
	jsr $ffd2
	lda #<tx_buttons
	ldy #>tx_buttons
	jsr $ab1e

loop:
	lda $d012
	bne loop
	lda $d011
	bpl loop

; clear
	ldx #39
clear:	lda $0400 + 2 * 40,x
	and #$7f
	sta $0400 + 2 * 40,x
	lda $0400 + 3 * 40,x
	and #$7f
	sta $0400 + 3 * 40,x
	lda $0400 + 8 * 40,x
	and #$7f
	sta $0400 + 8 * 40,x
	lda $0400 + 9 * 40,x
	and #$7f
	sta $0400 + 9 * 40,x
	dex
	bpl clear

	jsr get_joystick

	lda #<($0400 + 2 * 40)
	sta 2
	lda #>($0400 + 2 * 40)
	sta 3
	jsr display_controller

	lda joy2
	sta joy1
	lda joy2 + 1
	sta joy1 + 1
	lda joy2 + 2
	sta joy1 + 2

	lda #<($0400 + 8 * 40)
	sta 2
	lda #>($0400 + 8 * 40)
	sta 3
	jsr display_controller
	jmp loop

display_controller:
; detect type
	ldy #13       ; default: NES, print into first line
	lda joy1 + 1 ; type
	lsr
	bcc pr3      ; is NES
; SNES
	ldy #41      ; SNES, print into second line
	lda joy1 + 1
	ldx #4
pr4:	asl
	bcs pr5
	pha
	lda (2),y
	ora #$80
	sta (2),y
	iny
	lda (2),y
	ora #$80
	sta (2),y
	pla
	dey
pr5:	iny
	iny
	iny
	dex
	bne pr4
	ldy #40+13

; NES
pr3:	lda joy1
	ldx #8
pr1:	asl
	bcs pr2
	pha
	lda (2),y
	ora #$80
	sta (2),y
	iny
	lda (2),y
	ora #$80
	sta (2),y
	pla
	dey
pr2:	iny
	iny
	iny
	dex
	bne pr1
	rts



	lda joy1 + 0
	sta $0400
	lda joy1 + 1
	sta $0401
	lda joy1 + 2
	sta $0402

	lda joy2
	sta $0403
	lda joy2 + 1
	sta $0404
	lda joy2 + 2
	sta $0405

	jmp loop

!ct pet
tx_clr:
	!by $93, 0
tx_controller:
	!tx "controller "
	!by 0
tx_buttons:
	!by 13, 13
	!tx "             a  b  sl st up dn lt rt"
	!by 13
	!tx " a  x  l  r  b  y  sl st up dn lt rt"
	!tx 13, 13, 13, 0
!ct scr



