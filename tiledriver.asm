;**********************************************************
; Dragon 32 Horizontal scroll demo
; Stewart Orchard 2017
;**********************************************************

;these should be defined somewhere in project
TD_SBUFF		equ $5000	; start of shift buffers
TD_TILEROWS		equ 12		; number of rows of tiles

;**********************************************************

	section "DPVARS"

td_bptr		rmb 2	; offset of origin within shift buffers
td_hcoord	rmb 1	; horizontal pixel offset
td_mptr		rmb 2	; pointer to current map position
td_sbuf		rmb 2	; pointer to current shift buffer (copy source)
td_fbuf		rmb 2	; pointer to current frame buffer (copy dest)
td_count	rmb 1	; general purpose counter
td_count2	rmb 1	; general purpose counter
td_temp		rmb 2	; general purpose temporary


; Pointers to tile address buffers
td_addr_buf_r_ptr0	rmb 2
td_addr_buf_r_ptr1	rmb 2

;**********************************************************

	section "DATA"

; Tile address buffers
td_addr_buf		rmb TD_TILEROWS*4
td_addr_buf_end

;**********************************************************

TD_SBSIZE	equ TD_TILEROWS*256
TD_SBEND	equ TD_SBUFF + TD_SBSIZE*4

;**********************************************************

	section "CODE"

td_init
	clra
	clrb
	sta td_hcoord
	std td_bptr

	ldx #MAPSTART
	stx td_mptr

	ldx #TD_SBUFF
	stx td_sbuf
	
	; initialise tile address buffer pointers
	ldx #td_addr_buf
	stx td_addr_buf_r_ptr0
	leax TD_TILEROWS*2,x
	stx td_addr_buf_r_ptr1

	ldx #td_addr_buf
	ldb #TD_TILEROWS*2
	ldu #TILES
1	stu ,x++
	decb
	bne 1b

	rts

	

	include "td_right_adv.asm"
	include "td_copybuf_adv.asm"

