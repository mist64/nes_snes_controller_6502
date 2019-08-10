!to "controller.prg",cbm

; C64 CIA#2 PB (user port)
nes_data = $dd01
nes_ddr  = $dd03

bit_latch = $08 ; PB3 (F)
bit_data1 = $10 ; PB4 (H)
bit_clk   = $20 ; PB5 (J)
bit_data2 = $40 ; PB6 (K)

joy1 = $e0
joy2 = $f0

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

*=$c000

start:
	jsr get_joystick
	lda joy1
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

	jmp start


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
