;**********************************************************
; Dragon 32 Horizontal scroll demo
; Stewart Orchard 2017
;**********************************************************

GMODE	equ $e0


DBG_RASTER equ 1

assert	macro
	if !(\1)
	tst __\2
	endif
	endm

align	macro
	; have to use '&1' form of parameter within string?
	assert (\1 != 0) && ((\1 & (\1 - 1)) == 0), "align_arg_not_pwr2__<&1>"
	org * + (-* & (\1-1))
	endm

	
;**********************************************************

	section "DPVARS"

	org $0

DPVARS

frmflag		rmb 1
keytable	rmb 8

  if DBG_RASTER
dbg_raster	rmb 1
  endif

;**********************************************************

	section "DATA"

;**********************************************************

FBUF0	equ $0400
FBUF1	equ FBUF0+3072

FRAME0 macro
	sta $ffc9	; 1K on
	sta $ffcc	; 4K off
	endm

FRAME1 macro
	sta $ffc8	; 1K off
	sta $ffcd	; 4K on
	endm

TOGMODE	macro
	lda $ff22
	eora #8
	sta $ff22
	endm
	
;**********************************************************

	section "CODE"

	org $2000
 
	lda #$34		; disable interrupts in pias
	ldx #$ff00
	sta 1,x
	sta 3,x
	sta $21,x
	sta $23,x

	lds #$2000
	
	lda #DPVARS >> 8
	tfr a,dp
	setdp DPVARS >> 8

	jsr td_init
	
	lda #GMODE
	sta $ff22
    sta $ffc5

	ldd #FBUF0
	std td_fbuf
	
	clr frmflag
	jsr flip_frame_buffers
	
	ldd #$aaaa
	ldx #TD_SBUFF
1	std ,x++
	cmpx #TD_SBEND
	blo 1b

	jsr prefill_buffers

  if DBG_RASTER
	clr dbg_raster
  endif

	
MLOOP 

	jsr td_copybuf

 if DBG_RASTER
	lda dbg_raster
	beq 1f
	TOGMODE
	TOGMODE
1
 endif

	jsr flip_frame_buffers


	jsr scan_keys

	; RIGHT (. on CoCo)
	;lda #$20
	;bita keytable+6
	;bne 1f

	jsr td_scroll_right
1
 if DBG_RASTER
	; 1 (A on CoCo)
	clr dbg_raster
	lda #1
	bita keytable+1
	bne 1f
	sta dbg_raster
1
  endif


	jmp MLOOP


;*************************************
; Swap front and back frame buffers
;*************************************

flip_frame_buffers
	lda $ff02
1	lda $ff03
	bpl 1b
	com frmflag
	beq 90f
	lda #(FBUF0 >> 8)
	sta td_fbuf
	FRAME1
	rts
90	lda #(FBUF1 >> 8)
	sta td_fbuf
	FRAME0
	rts

;*************************************

prefill_buffers	

	ldx #td_addr_buf
	ldd #TILES
1	std ,x++
	cmpx #td_addr_buf_end
	blo 1b
	rts

;*************************************

scan_keys
	ldu #$ff00
	lda #$fe
	comb		; set carry
	sta 2,u
	lda ,u
	rol 2,u
	ldb ,u
	std keytable
	rol 2,u
	lda ,u
	rol 2,u
	ldb ,u
	std keytable+2
	rol 2,u
	lda ,u
	rol 2,u
	ldb ,u
	std keytable+4
	rol 2,u
	lda ,u
	rol 2,u
	ldb ,u
	std keytable+6
	rts

;*************************************

MAPSTART
	includebin "tilemap.bin"
MAPEND

MAPSIZE equ MAPEND-MAPSTART

    align 2
	include "tiledata.asm"

	include "tiledriver.asm"
