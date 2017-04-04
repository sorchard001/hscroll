# Dragon 32 HScroll Demo

Horizontal scrolling demo for the Dragon 32

Drawing into the scroll buffers is compensated to allow optimal pul/psh fast copy to frame buffer.

Runs at video frame rate (50Hz PAL, 60Hz NTSC)

assembled with asm6809  (www.6809.org.uk/asm6809)
asm6809 -D -o hscroll.bin hscroll.asm

(Or CoCo DECB: asm6809 -C -o hscroll.bin hscroll.asm)

Requires 32K

Graphics adapted from Konami Scramble screenshots found online
