\\ Some line drawing tests in MODE 4(S)

\\ Want to be able to:
\\ Increase / decrease #lines - done
\\ Set line draw routine Tricky, RTW, NJ - done
\\ Set min frame rate - done
\\ Debug rasters on / off - done

MIN_LINES = 3
MAX_LINES = 64
NUM_LINES = 4

PAL_black = 0 EOR 7
PAL_red = 1 EOR 7

MACRO SET_BGGCOL pal
{
    LDA #&00 + pal:STA &FE21
    LDA #&10 + pal:STA &FE21
    LDA #&20 + pal:STA &FE21
    LDA #&30 + pal:STA &FE21
    LDA #&40 + pal:STA &FE21
    LDA #&50 + pal:STA &FE21
    LDA #&60 + pal:STA &FE21
    LDA #&70 + pal:STA &FE21
}
ENDMACRO

ORG &70

\\ RTW ZP vars
.startx				SKIP 1
.starty				SKIP 1
.endx				SKIP 1
.endy				SKIP 1
.scrn				SKIP 2
.accum				SKIP 1
.dx					SKIP 1
.dy					SKIP 1
.count				SKIP 1
.temp				SKIP 1

\\ NJ ZP vars
y0 = starty
y1 = endy
x0 = startx
x1 = endx
scr = scrn
cnt = count
err = accum
errs = temp
.scrstrt            SKIP 1
.ls                 SKIP 1

\\ Tricky ZP vars
scr_addr = &6000

\\ Kieran ZP vars
.test_x0            SKIP 1
.test_y0            SKIP 1
.test_x1            SKIP 1
.test_y1            SKIP 1

.index              SKIP 1

.table_ptr          SKIP 2
.store_ptr          SKIP 2

.vsync_count        SKIP 1
.min_frame_rate     SKIP 1
.debounce           SKIP 1

.num_lines          SKIP 1
.num_lines2         SKIP 1
.num_lines2_less1   SKIP 1

.debug_rasters      SKIP 1
.draw_fn_num        SKIP 1

.do_anim            SKIP 1

\\ CODE
ORG &3000
GUARD &5800

.start

INCLUDE "rtw-linedraw.asm"
INCLUDE "nj-linedraw4.asm"
INCLUDE "tricky-linedraw.asm"

.set_num_lines
{
    STA num_lines
    ASL A
    STA num_lines2
    SEC
    SBC #2
    STA num_lines2_less1
    .return
    RTS
}

.main
{
    \\ MODE 4
    LDA #22
    JSR &FFEE
    LDA #4
    JSR &FFEE

    LDA #&FF
    STA debounce
    STA do_anim
    STA debug_rasters

    LDA #NUM_LINES
    JSR set_num_lines

    LDA #1
    JSR set_draw_fn

    \\ 32 character columns (256x256 pixels)
    IF 1
    LDA #1:STA &FE00
    LDX #32:STX &FE01
    LDA #10:STA &FE00
    STX &FE01
    LDA #13:STA &FE00
    LDA #LO(scr_addr/8):STA &FE01
    LDA #12:STA &FE00
    LDA #HI(scr_addr/8):STA &FE01
    ENDIF

    \\ Count vsyncs
    SEI
    LDA &204:STA old_irqv1
    LDA &205:STA old_irqv1+1
    LDA #LO(irq_handler):STA &204
    LDA #HI(irq_handler):STA &205
    LDA #&7F:STA &FE4E
    LDA #&82:STA &FE4E
    CLI

    \\ Init
    LDA #HI(scr_addr)
    STA scrstrt

    LDA #1
    STA min_frame_rate

IF 0

    \\ L to R
    LDA #0:STA test_x0
    LDA #0:STA test_y0
    LDA #0:STA test_x1
    LDA #255:STA test_y1
    .loop1
    JSR draw_test_line
    INC test_x0
    INC test_x1
    BNE loop1

    \\ T to B
    LDA #0:STA test_x0
    LDA #0:STA test_y0
    LDA #255:STA test_x1
    LDA #0:STA test_y1
    .loop2
    JSR draw_test_line
    INC test_y0
    INC test_y1
    BNE loop2

    \\ Corner
    LDA #0:STA test_x0
    LDA #0:STA test_y0
    LDA #0:STA test_x1
    LDA #255:STA test_y1
    .loop3a
    JSR draw_test_line
    INC test_x1
    BNE loop3a
    LDA #255:STA test_x1
    .loop3b
    JSR draw_test_line
    DEC test_y1
    BNE loop3b
    LDA #0:STA test_x0
    LDA #0:STA test_y0
    LDA #0:STA test_x1
    LDA #255:STA test_y1
    .loop3c
    JSR draw_test_line
    INC test_x1
    BNE loop3c
    LDA #255:STA test_x1
    .loop3d
    JSR draw_test_line
    DEC test_y1
    BNE loop3d
ENDIF

    JSR random_lines
    JSR random_lines

    JSR move_lines

    RTS
}

.random_lines
{
    LDA #0:STA index

    .loop
    LDX index

    LDA random, X:STA test_x0
    INX
    LDA random, X:STA test_y0
    INX
    LDA random, X:STA test_x1
    INX
    LDA random, X:STA test_y1

    JSR draw_test_line

    INC index
    BNE loop

    RTS
}

.move_lines
{
    LDA #LO(table_1):STA table_ptr
    LDA #HI(table_1):STA table_ptr+1
    LDA #LO(table_2):STA store_ptr
    LDA #HI(table_2):STA store_ptr+1

    JSR draw_line_loop

    .loop_loop

    JSR test_keys

    \\ Update v'0,v'1,v'2,v'3

    LDA do_anim
    BEQ skip_anim

    LDY #0
    .update_loop
    JSR update_index
    CPY num_lines2
    BCC update_loop
    .skip_anim

    \\ Frame rate lock

    LDX min_frame_rate
    BEQ no_lock
    DEX
    .vsync_loop
    CPX vsync_count
    BCS vsync_loop
    .no_lock

    \\ Print frame rate

    LDA #31:JSR &FFEE
    LDA #7:JSR &FFEE
    LDA #7:JSR &FFEE
    CLC
    LDA vsync_count
    ADC #48
    JSR &FFEE

    LDA #0
    STA vsync_count

    \\ Debug rasters

    JSR do_debug_rasters

    \\ Erase line v0v1, draw line v'0v'1
    \\ Erase line v1v2, draw line v'1v'2
    \\ Erase line v2v3, draw line v'2v'3

    LDY #0
    .fast_loop
    STY index

    LDA (table_ptr), Y
    STA test_x0
    INY
    LDA (table_ptr), Y
    STA test_y0

    INY
    LDA (table_ptr), Y
    STA test_x1
    INY
    LDA (table_ptr), Y
    STA test_y1

    JSR draw_test_line

    LDY index

    LDA (store_ptr), Y
    STA test_x0
    INY
    LDA (store_ptr), Y
    STA test_y0

    INY
    STY index

    LDA (store_ptr), Y
    STA test_x1
    INY
    LDA (store_ptr), Y
    STA test_y1

    JSR draw_test_line

    LDY index
    CPY num_lines2_less1
    BCC fast_loop

    \\ Erase line v3v0, draw line v'3v'0

    LDA (table_ptr), Y
    STA test_x0
    INY
    LDA (table_ptr), Y
    STA test_y0

    LDY #0
    LDA (table_ptr), Y
    STA test_x1
    INY
    LDA (table_ptr), Y
    STA test_y1

    JSR draw_test_line

    LDY index

    LDA (store_ptr), Y
    STA test_x0
    INY
    LDA (store_ptr), Y
    STA test_y0

    LDY #0
    LDA (store_ptr), Y
    STA test_x1
    INY
    LDA (store_ptr), Y
    STA test_y1

    JSR draw_test_line

    SET_BGGCOL PAL_black

    \\ Flip buffer pointers

    LDX store_ptr:LDY table_ptr
    STY store_ptr:STX table_ptr

    LDX store_ptr+1:LDY table_ptr+1
    STY store_ptr+1:STX table_ptr+1

    JMP loop_loop

    RTS
}

.update_index
{
    LDA table_dir, Y
    BPL x_pos
    \\ x neg

    SEC
    LDA (table_ptr), Y
    SBC #1
    STA (store_ptr), Y
    BNE x_ok

    \\ x bounce
    LDA #1
    STA table_dir, Y
    BNE x_ok

    .x_pos
    CLC
    LDA (table_ptr), Y
    ADC #1
    STA (store_ptr), Y
    CMP #&FF
    BNE x_ok

    LDA #&FF
    STA table_dir, Y

    .x_ok

    INY

    LDA table_dir, Y
    BPL y_pos
    \\ y neg

    SEC
    LDA (table_ptr), Y
    SBC #1
    STA (store_ptr), Y
    BNE y_ok

    \\ y bounce
    LDA #1
    STA table_dir, Y
    BNE y_ok

    .y_pos
    CLC
    LDA (table_ptr), Y
    ADC #1
    STA (store_ptr), Y
    CMP #&FF
    BNE y_ok

    LDA #&FF
    STA table_dir, Y

    .y_ok

    INY

    RTS
}

.draw_line_loop
{
    \\ Draw lines v0v1, v1v2, v2v3, v3v0

    LDY #0
    LDA (table_ptr), Y
    STA test_x1
    INY
    LDA (table_ptr), Y
    STA test_y1

    .draw_loop
    LDA test_x1:STA test_x0
    LDA test_y1:STA test_y0

    INY
    LDA (table_ptr), Y
    STA test_x1
    INY
    LDA (table_ptr), Y
    STA test_y1
    STY index

    JSR draw_test_line

    LDY index
    CPY num_lines2_less1
    BCC draw_loop

    LDA test_x1:STA test_x0
    LDA test_y1:STA test_y0
    LDY #0
    LDA (table_ptr), Y
    STA test_x1
    INY
    LDA (table_ptr), Y
    STA test_y1
    JSR draw_test_line

    RTS
}

.draw_test_line
{
    LDA test_x0:STA x0
    LDA test_y0:STA y0
    LDA test_x1:STA x1
    LDA test_y1:STA y1

;    LDA #0 + PAL_red:STA &FE21
}
.draw_test_fn
    JMP linedraw4

.draw_fn_table
{
    EQUW linedraw4      ; NJ
    EQUW drawline       ; RTW
    EQUW draw_line      ; Tricky
}

.set_draw_fn
{
    STA draw_fn_num
    TAX
    DEX
    TXA
    ASL A
    TAX
    LDA draw_fn_table, X
    STA draw_test_fn+1
    LDA draw_fn_table+1, X
    STA draw_test_fn+2
    RTS
}

.irq_handler
{
    LDA &FE4D
    AND #2
    BEQ return
    STA &FE4D

    INC vsync_count

    .return
    LDA &FC
    JMP (old_irqv1)
}

.old_irqv1
EQUW &FFFF

.test_keys
{
    LDA #&79
    LDX #&10
    JSR &FFF4
    CPX debounce
    BNE key_pressed
    RTS

    .key_pressed
    STX debounce

    CPX #&10    ; q
    BNE not_q
    LDY min_frame_rate
    INY
    .save_min
    STY min_frame_rate
    RTS

    .not_q
    CPX #&41    ; a
    BNE not_a
    LDY min_frame_rate
    BEQ return
    DEY
    BPL save_min

    .not_a
    CPX #&37    ; p
    BNE not_p
    LDY num_lines
    CPY #MAX_LINES
    BCS return
    JSR draw_line_loop    
    LDY num_lines
    INY:TYA
    JSR set_num_lines
    JMP draw_line_loop

    .not_p
    CPX #&56    ; l
    BNE not_l
    LDY num_lines
    CPY #MIN_LINES
    BCC return
    BEQ return
    JSR draw_line_loop    
    LDY num_lines
    DEY:TYA
    JSR set_num_lines
    JMP draw_line_loop    

    .not_l
    CPX #&32    ; d
    BNE not_d
    LDA debug_rasters
    EOR #&FF
    STA debug_rasters
    RTS

    .not_d
    CPX #&30    ; 1
    BNE not_1
    JSR draw_line_loop    
    LDA #1
    JSR set_draw_fn
    JMP draw_line_loop    

    .not_1
    CPX #&31    ; 2
    BNE not_2
    JSR draw_line_loop    
    LDA #2
    JSR set_draw_fn
    JMP draw_line_loop    

    .not_2
    CPX #&11    ; 3
    BNE not_3
    JSR draw_line_loop    
    LDA #3
    JSR set_draw_fn
    JMP draw_line_loop    

    .not_3 
    CPX #&65    ; m
    BNE not_m
    LDA do_anim
    EOR #&FF
    STA do_anim
    RTS

    .not_m

    .return
    RTS
}

.do_debug_rasters
{
    LDA debug_rasters
    BEQ return

    LDA draw_fn_num         ; &00
    CMP #3  ; yellow too bright
    BNE ok
    LDA #4
    .ok
    EOR #7
    STA &FE21
    EOR #&10:STA &FE21      ; &10
    EOR #&30:STA &FE21      ; &20
    EOR #&10:STA &FE21      ; &30
    EOR #&70:STA &FE21      ; &40
    EOR #&10:STA &FE21      ; &50
    EOR #&30:STA &FE21      ; &60
    EOR #&10:STA &FE21      ; &70

    .return
    RTS
}

.data

ALIGN &100
.random
FOR n,0,255,1
EQUB RND(255)
NEXT

ALIGN &100
.table_1
FOR n,0,(MAX_LINES*2)-1,1
EQUB RND(255)
NEXT
.table_2
FOR n,0,(MAX_LINES*2)-1,1
EQUB RND(255)
NEXT
.table_dir
FOR n,0,(MAX_LINES*2)-1,1
IF RND(256)>128
EQUB 1
ELSE
EQUB &FF
ENDIF
NEXT

.end

.bss

SAVE "MyCode", start, end, main
