all:
	acme nes_snes_controller_6502.asm

clean:
	rm -f nes_snes_controller_6502.prg

1541: all
	c1541 -format controller,61 d64 disk.d64 -write controller.prg
	d64copy -b disk.d64 10
