	VWRAP = 0

draw_line = P% + 8*16
{
.lulo : EQUB LO(lu80), LO(lu40), LO(lu20), LO(lu10), LO(lu08), LO(lu04), LO(lu02), LO(lu01)
.luhi : EQUB HI(lu80), HI(lu40), HI(lu20), HI(lu10), HI(lu08), HI(lu04), HI(lu02), HI(lu01)
.ullo : EQUB LO(ul80), LO(ul40), LO(ul20), LO(ul10), LO(ul08), LO(ul04), LO(ul02), LO(ul01)
.ulhi : EQUB HI(ul80), HI(ul40), HI(ul20), HI(ul10), HI(ul08), HI(ul04), HI(ul02), HI(ul01)
.urlo : EQUB LO(ur80), LO(ur40), LO(ur20), LO(ur10), LO(ur08), LO(ur04), LO(ur02), LO(ur01)
.urhi : EQUB HI(ur80), HI(ur40), HI(ur20), HI(ur10), HI(ur08), HI(ur04), HI(ur02), HI(ur01)
.rulo : EQUB LO(ru80), LO(ru40), LO(ru20), LO(ru10), LO(ru08), LO(ru04), LO(ru02), LO(ru01)
.ruhi : EQUB HI(ru80), HI(ru40), HI(ru20), HI(ru10), HI(ru08), HI(ru04), HI(ru02), HI(ru01)
.rdlo : EQUB LO(rd80), LO(rd40), LO(rd20), LO(rd10), LO(rd08), LO(rd04), LO(rd02), LO(rd01)
.rdhi : EQUB HI(rd80), HI(rd40), HI(rd20), HI(rd10), HI(rd08), HI(rd04), HI(rd02), HI(rd01)
.drlo : EQUB LO(dr80), LO(dr40), LO(dr20), LO(dr10), LO(dr08), LO(dr04), LO(dr02), LO(dr01)
.drhi : EQUB HI(dr80), HI(dr40), HI(dr20), HI(dr10), HI(dr08), HI(dr04), HI(dr02), HI(dr01)
.dllo : EQUB LO(dl80), LO(dl40), LO(dl20), LO(dl10), LO(dl08), LO(dl04), LO(dl02), LO(dl01)
.dlhi : EQUB HI(dl80), HI(dl40), HI(dl20), HI(dl10), HI(dl08), HI(dl04), HI(dl02), HI(dl01)
.ldlo : EQUB LO(ld80), LO(ld40), LO(ld20), LO(ld10), LO(ld08), LO(ld04), LO(ld02), LO(ld01)
.ldhi : EQUB HI(ld80), HI(ld40), HI(ld20), HI(ld10), HI(ld08), HI(ld04), HI(ld02), HI(ld01)

.vectors

IF draw_line <> vectors
	ERROR "draw_line doesn't match vectors"
ENDIF

;	INCLUDE "vectors.equ"
;	PRINT "vectors",P%-vectors
;	INCLUDE "linedraw4.asm"

	lda y1 : sec : sbc y0 :: bcs down ;; : beq horizontal
	eor #&FF : sbc #&FE
.up          ; C=1 A=dy
	sta dy : lsr A : sta err

	lda x0 : and #&F8 : sta scr : eor x0 : tax   ; x = pix offset for jumping to
	lda y0 : and #7 : tay                        ; y = byte within char
	lda y0 : lsr A : lsr A : lsr A : ora #HI(scr_addr) : sta scr+1

	lda x1 : SEC : sbc x0 :: bcs up_or_right ;; : beq straight_up
	eor #&FF : sbc #&FE : sta dx
.up_or_left  ; C=1 A=dx
	cmp dy : bcs left_up
.up_left     ; C=0 A=dx
	lda ullo,x : sta x0 : lda ulhi,x : sta y0 : sec : ldx dy : jmp (x0)

.left_up     ; C=1 A=dx
	lsr A : sec : sta err : lda lulo,x : sta x0 : lda luhi,x : sta y0 : ldx dx : jmp (x0)
.up_or_right ; C=1 A=dx
	sta dx : cmp dy : bcs right_up
.up_right    ; C=0 A=dx
	lda urlo,x : sta x0 : lda urhi,x : sta y0 : sec : ldx dy : jmp (x0)
.right_up    ; C=1 A=dx
	lsr A : sec : sta err : lda rulo,x : sta x0 : lda ruhi,x : sta y0 : ldx dx : jmp (x0)

;.horizontal    ; C=1 A=0
;.straight_up   ; C=1 A=0
;RTS

.down        ; C=1 A=dy
	sta dy : lsr A : sta err

	lda x1 : and #&F8 : sta scr : eor x1 : tax   ; x = pix offset for jumping to
	lda y1 : and #7 : tay                        ; y = byte within char
	lda y1 : lsr A : lsr A : lsr A : ora #HI(scr_addr) : sta scr+1

	lda x1 : SEC : sbc x0 :: bcs down_or_right ;; : beq straight_down
	eor #&FF : sbc #&FE

.down_or_left ; C=1 A=dx
	sta dx : cmp dy : bcs left_down
.down_left    ; C=0 A=dx
	lda dllo,x : sta x0 : lda dlhi,x : sta y0 : sec : ldx dy : jmp (x0)
.left_down    ; C=1 A=dx
	lsr A : sec : sta err : lda ldlo,x : sta x0 : lda ldhi,x : sta y0 : ldx dx : jmp (x0)

.down_or_right ; C=1 A=dx
	sta dx : cmp dy : bcs right_down
.down_right    ; C=0 A=dx
	lda drlo,x : sta x0 : lda drhi,x : sta y0 : sec : ldx dy : .sm_jdr : jmp (x0)
.right_down    ; C=1 A=dx
	lsr A : sec : sta err : lda rdlo,x : sta x0 : lda rdhi,x : sta y0 : ldx dx : jmp (x0)

;.straight_down ; C=1 A=0
;RTS


.done0 : RTS

	;;; C=1
.lu01s
	sta err
.lu01
	lda #&01 : eor (scr),y : sta (scr),y : dex : beq done0   ; 2+5+6+2+2 (+4 per line) = 17 (+1+RTS)
.rd01
	lda err : sbc dy : bcs lu02s ; 3+3+3+2.5  = 11.5
	adc dx                       ; (3+3)/2    =  3    = 51+1+RTS (42+)
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
.lu02s
	sta err
.lu02
	lda #&02 : eor (scr),y : sta (scr),y : dex : beq done0
.rd02
	lda err : sbc dy : bcs lu04s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.lu04s
	sta err
.lu04
	lda #&04 : eor (scr),y : sta (scr),y : dex : beq done0
.rd04
	lda err : sbc dy : bcs lu08s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.lu08s
	sta err
.lu08
	lda #&08 : eor (scr),y : sta (scr),y : dex : beq done0
.rd08
	lda err : sbc dy : bcs lu10s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.lu10s
	sta err
.lu10
	lda #&10 : eor (scr),y : sta (scr),y : dex : beq done0
.rd10
	lda err : sbc dy : bcs lu20s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.lu20s
	sta err
.lu20
	lda #&20 : eor (scr),y : sta (scr),y : dex : beq done1
.rd20
	lda err : sbc dy : bcs lu40s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.lu40s
	sta err
.lu40
	lda #&40 : eor (scr),y : sta (scr),y : dex : beq done1
.rd40
	lda err : sbc dy : bcs lu80s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.lu80s
	sta err
.lu80
	lda #&80 : eor (scr),y : sta (scr),y : dex : beq done1
.rd80
	lda scr : sbc #8 : sta scr : sec
	lda err : sbc dy { bcc line : jmp lu01s : .line }
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line} : jmp lu01s

.done1 : RTS

	;;; C=1
.ul01s
	sta err
.ul01
	lda #&01 : eor (scr),y : sta (scr),y : dex : beq done1   ; 2+5+6+2+2 (+4 per line) = 17 (+1+RTS)
.dr01
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line} ; 2+(7*3+(2+2+3+2+2+3))/8 = 19.5
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ul01s        ; 3+3+3+2.5  = 11.5
	adc dy                             ; (3+3)/2    =  3    = 51+1+RTS (42+)
.ul02s
	sta err
.ul02
	lda #&02 : eor (scr),y : sta (scr),y : dex : beq done1
.dr02
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ul02s
	adc dy
.ul04s
	sta err
.ul04
	lda #&04 : eor (scr),y : sta (scr),y : dex : beq done1
.dr04
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ul04s
	adc dy
.ul08s
	sta err
.ul08
	lda #&08 : eor (scr),y : sta (scr),y : dex : beq done1
.dr08
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ul08s
	adc dy
.ul10s
	sta err
.ul10
	lda #&10 : eor (scr),y : sta (scr),y : dex : beq done1
.dr10
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : sta err : bcs ul10s
	adc dy
.ul20s
	sta err
.ul20
	lda #&20 : eor (scr),y : sta (scr),y : dex : beq done2
.dr20
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ul20s
	adc dy
.ul40s
	sta err
.ul40
	lda #&40 : eor (scr),y : sta (scr),y : dex : beq done2
.dr40
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ul40s
	adc dy
.ul80s
	sta err
.ul80
	lda #&80 : eor (scr),y : sta (scr),y : dex : beq done2
.dr80
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ul80s
	adc dy : sta err : lda scr : sbc #8 : sta scr : sec : jmp ul01

.done2 : RTS

	;;; C=1

.ur80s
	sta err
.ur80
	lda #&80 : eor (scr),y : sta (scr),y : dex : beq done2
.dl80
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ur80s
	adc dy
.ur40s
	sta err
.ur40
	lda #&40 : eor (scr),y : sta (scr),y : dex : beq done2
.dl40
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ur40s
	adc dy
.ur20s
	sta err
.ur20
	lda #&20 : eor (scr),y : sta (scr),y : dex : beq done2
.dl20
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ur20s
	adc dy
.ur10s
	sta err
.ur10
	lda #&10 : eor (scr),y : sta (scr),y : dex : beq done2
.dl10
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ur10s
	adc dy
.ur08s
	sta err
.ur08
	lda #&08 : eor (scr),y : sta (scr),y : dex : beq done2
.dl08
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ur08s
	adc dy
.ur04s
	sta err
.ur04
	lda #&04 : eor (scr),y : sta (scr),y : dex : beq done3
.dl04
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ur04s
	adc dy
.ur02s
	sta err
.ur02
	lda #&02 : eor (scr),y : sta (scr),y : dex : beq done3
.dl02
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ur02s
	adc dy
.ur01s
	sta err
.ur01
	lda #&01 : eor (scr),y : sta (scr),y : dex : beq done3
.dl01
IF VWRAP
	dey { bpl line : ldy #7 : lda scr+1 : sbc #1 : ora #HI(scr_addr) : sta scr+1 : .line}
ELSE
	dey { bpl line : ldy #7 : dec scr+1 : .line} ; 2+(7*3+(2+5))/8  =  5.5
ENDIF
	lda err : sbc dx : bcs ur01s
	adc dy : sta err : lda scr : adc #8-1 : sta scr : sec : jmp ur80

.done3 : RTS

;.done803
;	lda #&80 : eor (scr),y : sta (scr),y : RTS
;.done403
;	lda seg : and #&C0: eor (scr),y : sta (scr),y : RTS
;.done203
;	lda seg : and #&E0: eor (scr),y : sta (scr),y : RTS
;.done103
;	lda seg : and #&F0: eor (scr),y : sta (scr),y : RTS
;
;	;;; C=1
;.ru80
;	lda #&FF : sta seg
;	lda err
;.ru80s
;	dex : beq done803
;.ld80
;	sbc dy : bcs ru40s
;	adc dx : sta err
;	lda #&80 : eor (scr),y : sta (scr),y
;	dey { bpl line : ldy #7 : dec scr+1 : .line}
;.ru40
;	lda #&7F : sta seg
;	lda err
;.ru40s
;	dex : beq done403
;.ld40
;	sbc dy : bcs ru20s
;	adc dx : sta err
;	lda seg : and #&C0: eor (scr),y : sta (scr),y
;	dey { bpl line : ldy #7 : dec scr+1 : .line}
;.ru20
;	lda #&3F : sta seg
;	lda err
;.ru20s
;	dex : beq done203
;.ld20
;	sbc dy : bcs ru10s
;	adc dx : sta err
;	lda seg : and #&E0: eor (scr),y : sta (scr),y
;	dey { bpl line : ldy #7 : dec scr+1 : .line}
;.ru10
;	lda #&1F : sta seg
;	lda err
;.ru10s
;	dex : beq done103
;.ld10
;	sbc dy : bcs ru08s
;	adc dx : sta err
;	lda seg : and #&F0: eor (scr),y : sta (scr),y
;	dey { bpl line : ldy #7 : dec scr+1 : .line}
;.ru08
;	lda #&0F : sta seg
;	lda err
;.ru08s
;	dex : bne ld08
;.done084
;	lda seg : and #&F8: eor (scr),y : sta (scr),y : RTS
;
;.ld08
;	sbc dy : bcs ru04s
;	adc dx : sta err
;	lda seg : and #&F8: eor (scr),y : sta (scr),y
;	dey { bpl line : ldy #7 : dec scr+1 : .line}
;.ru04
;	lda #&07 : sta seg
;	lda err
;.ru04s
;	dex : beq done044
;.ld04
;	sbc dy : bcs ru02s
;	adc dx : sta err
;	lda seg : and #&FC: eor (scr),y : sta (scr),y
;	dey { bpl line : ldy #7 : dec scr+1 : .line}
;.ru02
;	lda #&03 : sta seg
;	lda err
;.ru02s
;	dex : beq done024
;.ld02
;	sbc dy : bcs ru01s
;	adc dx : sta err
;	lda seg : and #&FE: eor (scr),y : sta (scr),y
;	dey { bpl line : ldy #7 : dec scr+1 : .line}
;.ru01
;	lda #&01 : sta seg
;	lda err
;.ru01s
;	sta err
;	lda seg : eor (scr),y : sta (scr),y : dex : beq done4
;.ld01
;	lda scr : adc #8-1 : sta scr : sec
;	lda err : sbc dy { bcc line : jmp ru80s : .line }
;	adc dx
;	dey { bpl line : ldy #7 : dec scr+1 : .line} : jmp ru80s
;
;;.done084
;;	lda seg : and #&F8: eor (scr),y : sta (scr),y : RTS
;.done044
;	lda seg : and #&FC: eor (scr),y : sta (scr),y : RTS
;.done024
;	lda seg : and #&FE: eor (scr),y : sta (scr),y : RTS
;
;.done4 : RTS






	;;; C=1
.ru80s
	sta err
.ru80
	lda #&80 : eor (scr),y : sta (scr),y : dex : beq done3
.ld80
	lda err : sbc dy : bcs ru40s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.ru40s
	sta err
.ru40
	lda #&40 : eor (scr),y : sta (scr),y : dex : beq done3
.ld40
	lda err : sbc dy : bcs ru20s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.ru20s
	sta err
.ru20
	lda #&20 : eor (scr),y : sta (scr),y : dex : beq done3
.ld20
	lda err : sbc dy : bcs ru10s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.ru10s
	sta err
.ru10
	lda #&10 : eor (scr),y : sta (scr),y : dex : beq done3
.ld10
	lda err : sbc dy : bcs ru08s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.ru08s
	sta err
.ru08
	lda #&08 : eor (scr),y : sta (scr),y : dex : beq done3
.ld08
	lda err : sbc dy : bcs ru04s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.ru04s
	sta err
.ru04
	lda #&04 : eor (scr),y : sta (scr),y : dex : beq done4
.ld04
	lda err : sbc dy : bcs ru02s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.ru02s
	sta err
.ru02
	lda #&02 : eor (scr),y : sta (scr),y : dex : beq done4
.ld02
	lda err : sbc dy : bcs ru01s
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line}
.ru01s
	sta err
.ru01
	lda #&01 : eor (scr),y : sta (scr),y : dex : beq done4
.ld01
	lda scr : adc #8-1 : sta scr : sec
	lda err : sbc dy { bcc line : jmp ru80s : .line }
	adc dx
	dey { bpl line : ldy #7 : dec scr+1 : .line} : jmp ru80s

.done4 : RTS
}
