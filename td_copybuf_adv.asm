;**********************************************************
; Dragon 32 Horizontal scroll demo
; Stewart Orchard 2017
;**********************************************************
;
; copy buffer to screen
;
; Source buffer is rendered in stack space
; allowing fast copy using stack instructions.
;
; Source buffer pointer indicates screen bottom-right.
; Octet containing pointer has to be split into two fragments
; and drawn at top-left & bottom-right corners.
;
; Remaining octets are pulled from buffer pointer and
; pushed to screen bottom. When end of buffer is reached,
; octets are pulled from buffer start.
;
; uses cc & dp to move data
; - interrupts must be completely disabled
; - care required when accessing dp vars
;
;*******************************************

	section "CODE"

	
; routines that handle the 8 versions of the octet
; containing the buffer pointer
td_frag_copy_table fdb _frag0, _frag1, _frag2, _frag3, _frag4, _frag5, _frag6, _frag7

; u points to octet
; y points to top left corner of display
; s points to byte after bottom right corner of display
; leaves u & s pointing to correct locations subsequent stack copy

_frag0
	pulu d,x
	pshs a				; 1 byte copied to bottom right
	stb ,y				; 7 bytes copied to top left
	stx 1,y
	pulu d,x
	std 3,y
	stx 5,y
	bra td_frag_ret
_frag1
	pulu d,x
	pshs d				; 2 bytes copied to bottom right
	stx ,y				; 6 bytes copied to top left
	pulu d,x
	std 2,y
	stx 4,y
	bra td_frag_ret
_frag2
	pulu cc,d,x
	pshs cc,d			; 3 bytes copied to bottom right
	stx ,y				; 5 bytes copied to top left
	pulu a,x
	sta 2,y
	stx 3,y
	bra td_frag_ret
_frag3
	pulu cc,d,dp,x
	pshs cc,d,dp		; 4 bytes copied to bottom right
	stx ,y				; 4 bytes copied to top left
	pulu d
	std 2,y
	bra td_frag_ret
_frag4
	pulu d,dp,x
	pshs d,dp,x			; 5 bytes copied to bottom right
	pulu a,x			; 3 bytes copied to top left
	sta ,y
	stx 1,y
	bra td_frag_ret
_frag5
	pulu cc,d,dp,x
	pshs cc,d,dp,x		; 6 bytes copied to bottom right
	pulu d				; 2 bytes copied to top left
	std ,y
	bra td_frag_ret
_frag6
	lda 7,u				; deal with top left byte first
	sta ,y				; before y gets clobbered
	pulu d,dp,x,y
	pshs d,dp,x,y		; 7 bytes copied to bottom right
	leau 1,u			; fix u
	bra td_frag_ret
_frag7
	pulu cc,d,dp,x,y	; all 8 bytes copied to bottom right
	pshs cc,d,dp,x,y
	bra td_frag_ret

	
;*******************************************
; Copy td_sbuf to td_fbuf
; td_sbuf is set up by the scroll routine

td_copybuf
	pshs cc,dp			; save system registers
	sts 99f+2			; as they are all going to get used

	ldy td_fbuf			; point y to display top left
	leas TD_SBSIZE,y	; point s to display bottom right

	ldd td_bptr			; copy starts from buffer offset
	andb #$f8			; move to start of octet
	addd td_sbuf		; add buffer base address
	tfr d,u				; u points to start of octet containing buffer pointer

	; deal with octet containing buffer pointer
	ldx #td_frag_copy_table
	ldb td_bptr+1
	andb #7
	lslb
	jmp [b,x]

td_frag_ret				; fragment routine returns here
	
	; (dp now clobbered so don't use direct addressing)

	ldd #TD_SBSIZE-1	; sneaky way of copying one octet fewer
	subd >td_bptr		; number of bytes to copy for first section
	ldx #1f				; return address
	bra td_copy_routine
1
	ldd >td_bptr		; number of bytes to copy for second section
	ldu >td_sbuf		; source address is now start of buffer
	ldx #1f				; return address
	bra td_copy_routine
1
99	lds #0				; restore system registers
	puls cc,dp,pc		; 

	
; macro to copy 8 bytes
td_copy8_mac	macro
	pulu cc,dp,d,x,y
	pshs cc,dp,d,x,y
	endm	


; fast octet copy routine
; u - source address
; s - destination address
; d - number of bytes to copy (bottom 3 bits ignored)
; x - return address
;
; care required: cc & dp regs are not preserved
	
td_copy_routine
	stx 99f+1		; save return address

	lslb			; set up td_count with number of
	rola			; 128 byte blocks for copy
	sta >td_count	;
	
	lslb
	stb >td_count2
	bcc 1f
	td_copy8_mac	; copy 64 bytes
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	
1	lsl >td_count2
	bcc 1f
	td_copy8_mac	; copy 32 bytes
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	
1	lsl >td_count2
	bcc 1f
	td_copy8_mac	; copy 16 bytes
	td_copy8_mac
	
1	lsl >td_count2
	bcc 1f
	td_copy8_mac	; copy 8 bytes

1	lda >td_count
	beq 90f			; nothing left to do
2	td_copy8_mac	; copy td_count * 128 bytes
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	td_copy8_mac
	dec >td_count
	bne 2b
90
99	jmp >0			; return to caller
