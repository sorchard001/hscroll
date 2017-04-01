;**********************************************************
; Dragon 32 Horizontal scroll demo
; Stewart Orchard 2017
;**********************************************************
;
; Scroll right
;
; Horizontal scrolling is achieved by selecting one of the
; four background buffers to match the desired degree of
; shift.
;
; A vertical stripe of data, 1 byte wide, is drawn into the
; current buffer. Buffer is organised in stack-friendly
; octets, allowing fast copy using stack instructions.
;
; Each time a byte boundary is crossed, the buffer pointer
; is adjusted right by one byte. (And 16 bytes subtracted
; if an octet boundary is crossed)
;
; Drawing into the zero shift buffer is the quickest.
; Drawing into the shifted buffers is much slower because
; 2 source bytes are required to make a shifted destination
; byte.
;
; To even out the workload, tile addresses are calculated
; on the zero-shift frames.
;
;**********************************************************

	section "CODE"


; macro to check if x has moved off top the buffer
; and correct if necessary
;
td_check_bb_pos	macro
	cmpx #\1
	bhs 99f
	leax TD_SBSIZE,x
99
	endm

	
; macro to shift word left 0-3 colour pixels & store result at x
; \1 is pixel shift left 0-3
; \2 is store offset
;
td_pixel_shift_store	macro
	if (\1 == 0)
		if (\2 == 0)
		  sta ,x
		else
		  sta \2,x
		endif
	elsif (\1 == 1)
		lslb
		rola
		lslb
		rola
		if (\2 == 0)
		  sta ,x
		else
		  sta \2,x
		endif
	elsif (\1 == 2)
		lslb
		rola
		lslb
		rola
		lslb
		rola
		lslb
		rola
		if (\2 == 0)
		  sta ,x
		else
		  sta \2,x
		endif
	elsif (\1 == 3)
		lsra
		rorb
		lsra
		rorb
		if (\2 == 0)
		  stb ,x
		else
		  stb \2,x
		endif
	endif
	endm

;**********************************************************
; scroll right
;**********************************************************

td_scroll_right

	inc td_hcoord

	; if moving to buffer 0 then need to move pointers
	lda td_hcoord
	bita #3
	lbne 5f

	; move buffer pointer 1 byte to right
	ldd td_bptr
	addd #1

	; adjustment for stack space mapping
	bitb #7
	bne 1f
	subd #16		; 1 step forward, 16 steps back.
	bpl 1f			; We go together because I am a cat.
	addd #TD_SBSIZE
1	std td_bptr

	; move map pointer
	ldu td_mptr
	ldb 4f+2
	eorb #1
	stb 4f+2	; Mod tile base address to alternate left/right half of tile
	lsrb
	bcs 2f		; still in same tile
	leau TD_TILEROWS,u		; next column in map
	cmpu #MAPEND
	blo 1f
	ldu #MAPSTART			; reset to start of map
1	stu td_mptr	
2	
	; calculate new tile addresses
	lda #TD_TILEROWS
	sta td_count
	ldx td_addr_buf_r_ptr0
3	lda ,u+
	ldb #16
	mul
4	addd #TILES		; modified depending which half of tile
	std ,x++
	dec td_count
	bne 3b

	; rotate tile address buffer pointers
	ldu #td_addr_buf_r_ptr0
	pulu d,x
	pshu d
	pshu x

5	
	; offset in destination buffer to start drawing
	ldx td_bptr	
	leax -32,x

	; point to tile addresses
	ldy td_addr_buf_r_ptr0
	ldd td_addr_buf_r_ptr1
	subd td_addr_buf_r_ptr0
	stb td_temp

	; jump to required drawing routine
	lda td_hcoord
	anda #3
	lsla
	ldu #td_draw_shift_jmp_table
	jmp [a,u]


;**********************************************************
; draw vertical stripe of shifted bytes
;
; x is start position in buffer
; (x is possibly out of bounds so check/adjust first)
; y points to address buffer containing left tile fragments
; temp contains offset to buffer containing right tile fragments
;**********************************************************

td_draw_shift	macro

	; \1 is number of pixels to shift left (0, 1, 2 or 3)
	; \2 is destination buffer

td_drawsh\1
	clr td_temp+1

	; position to start drawing in buffer
	ldd #\2
	std td_sbuf
	leax d,x

  if \1 != 0
	sts 9f+2		; save stack
  endif

  if \1 != 0
	lda td_temp		; offset to 2nd buffer
	sta 50f+3		; save buffer offset for loop
  endif
	
	lda #TD_TILEROWS
	sta td_count
5

  if \1 != 0
50	lds <0,y
  endif
	ldu ,y++
	
	; Check if tile contains buffer boundary
	cmpx #\2+32*8
	bhs 2f			; draw tile without boundary check
	
	; slow tile draw (checks for buffer boundary)
	ldb #8
	stb td_count2
1	td_check_bb_pos \2
	lda ,u++
  if \1 != 0
	ldb ,s++
  endif
	td_pixel_shift_store \1,0
	leax -32,x
	dec td_count2
	bne 1b

	dec td_count
	lbne 5b		; next tile
	jmp 3f

2	
	; fast tile draw (no check for buffer boundary)
	lda ,u
  if \1 != 0
	ldb ,s
  endif
	td_pixel_shift_store \1,0
	lda 2,u
  if \1 != 0
	ldb 2,s
  endif
	td_pixel_shift_store \1,-32
	lda 4,u
  if \1 != 0
	ldb 4,s
  endif
	td_pixel_shift_store \1,-64
	lda 6,u
  if \1 != 0
	ldb 6,s
  endif
	td_pixel_shift_store \1,-96
	lda 8,u
  if \1 != 0
	ldb 8,s
  endif
	td_pixel_shift_store \1,-128
	leax -256,x
	lda 10,u
  if \1 != 0
	ldb 10,s
  endif
	td_pixel_shift_store \1,96
	lda 12,u
  if \1 != 0
	ldb 12,s
  endif
	td_pixel_shift_store \1,64
	lda 14,u
  if \1 != 0
	ldb 14,s
  endif
	td_pixel_shift_store \1,32

	dec td_count
	lbne 5b		; next tile

3	
  if \1 != 0
9	lds #0		; restore stack
  endif
  
	rts

	endm

	
	td_draw_shift 0,TD_SBUFF
	td_draw_shift 1,TD_SBUFF+TD_SBSIZE
	td_draw_shift 2,TD_SBUFF+TD_SBSIZE*2
	td_draw_shift 3,TD_SBUFF+TD_SBSIZE*3

td_draw_shift_jmp_table
	fdb td_drawsh0, td_drawsh1, td_drawsh2, td_drawsh3

;**********************************************************
