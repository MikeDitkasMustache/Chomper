;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; this exercises used the baseline horizontal position code from Udemy 2600 course
;; the goal is to create an animated "pacman" character that moves across the screen
;; the character was created using https://alienbill.com/2600/playerpalnext.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with register mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start an uninitialized segment at $80 for var declaration.
;; We have memory from $80 to $FF to work with, minus a few at
;; the end if we use the stack.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80
P0XPos   byte      ; sprite X coordinate (stores P0xPos in RAM $80)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START    ; macro to clean memory and TIA

    ldx #$0       ; black background color
    stx COLUBK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #50
    sta P0XPos     ; initialize player X coordinate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
    lda #2         ; setting to 2 means activating (2 = binary 00000010)
    sta VBLANK     ; turn VBLANK on
    sta VSYNC      ; turn VSYNC on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 3 vertical lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 3
        sta WSYNC  ; first three VSYNC scanlines
    REPEND
    lda #0
    sta VSYNC      ; turn VSYNC off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set player horizontal position while we are in the VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda P0XPos     ; load register A with desired X position
    and #$7F       ; same as AND 01111111, forces bit 7 to zero
                   ; keeping the value inside A always positive
                   ; remember the bit positions go 76543210.  Two's complement bit 7 is zero for positive

    sec            ; set carry flag before subtraction

    sta WSYNC      ; wait for next scanline
    sta HMCLR      ; clear old horizontal position values

DivideLoop:
    sbc #15        ; Subtract 15 from A
    bcs DivideLoop ; loop while carry flag is still set

    eor #7         ; adjust the remainder in A between -8 and 7
    asl            ; shift left by 4, as HMP0 uses only 4 bits
    asl
    asl
    asl
    sta HMP0       ; set fine position value
    sta RESP0      ; reset rough position
    sta WSYNC      ; wait for next scanline
    sta HMOVE      ; apply the fine position offset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the (37-2) recommended lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 35
        sta WSYNC
    REPEND

    lda #0
    sta VBLANK     ; turn VBLANK off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 60
        sta WSYNC  ; wait for 60 empty scanlines
    REPEND

    ldy 9          ; counter to draw 8 rows of bitmap
DrawBitmap:
    lda P0Bitmap,Y ; load player bitmap slice of data
    sta GRP0       ; set graphics for player 0 slice

    lda P0Color,Y  ; load player color from lookup table
    sta COLUP0     ; set color for player 0 slice

    sta WSYNC      ; wait for next scanline

    dey
    bne DrawBitmap ; repeat next scanline until finished

    lda #0
    sta GRP0       ; disable P0 bitmap graphics

    REPEAT 124
        sta WSYNC  ; wait for remaining 124 empty scanlines
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Overscan:
    lda #2
    sta VBLANK     ; turn VBLANK on again for overscan
    REPEAT 30
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Increment X coordinate before next frame for animation.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    inc P0XPos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player graphics bitmap.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Bitmap:
    byte #%00000000 ; frame 4 from playerpal
    byte #%00011000 ;   XX      
    byte #%00111110 ;  XXXXX
    byte #%01111000 ; XXXX
    byte #%01110000 ; XXX
    byte #%01111000 ; XXX
    byte #%01101110 ; XX XXX
    byte #%00111100 ;  XXXX
    byte #%00011000 ;   XX  

P0Bitmap0
    .byte #%00000000 
    .byte #%00011000;$1E
    .byte #%00111100;$1E
    .byte #%01111110;$1E
    .byte #%01111110;$1E
    .byte #%01111110;$1E
    .byte #%01101110;$1E
    .byte #%00111100;$1E
    .byte #%00011000;$1E
P0Bitmap1
    .byte #%00000000 
    .byte #%00011000;$1E
    .byte #%00111100;$1E
    .byte #%01111110;$1E
    .byte #%01110000;$1E
    .byte #%01111110;$1E
    .byte #%01101110;$1E
    .byte #%00111100;$1E
    .byte #%00011000;$1E
P0Bitmap2
    .byte #%00000000
    .byte #%00011000;$1E
    .byte #%00111110;$1E
    .byte #%01111000;$1E
    .byte #%01110000;$1E
    .byte #%01111000;$1E
    .byte #%01101110;$1E
    .byte #%00111100;$1E
    .byte #%00011000;$1E
P0Bitmap3
    .byte #%00000000
    .byte #%00011010;$1E
    .byte #%00111100;$1E
    .byte #%01111000;$1E
    .byte #%01110000;$1E
    .byte #%01111000;$1E
    .byte #%01101100;$1E
    .byte #%00111110;$1E
    .byte #%00011000;$1E
P0Bitmap4
    .byte #%00000000 ; frame 4 from playerpal
    .byte #%00011000 ;   XX      
    .byte #%00111110 ;  XXXXX
    .byte #%01111000 ; XXXX
    .byte #%01110000 ; XXX
    .byte #%01111000 ; XXX
    .byte #%01101110 ; XX XXX
    .byte #%00111100 ;  XXXX
    .byte #%00011000 ;   XX  
P0Bitmap5
    .byte #%00000000
    .byte #%00011000;$1E
    .byte #%00111100;$1E
    .byte #%01111110;$1E
    .byte #%01110000;$1E
    .byte #%01111110;$1E
    .byte #%01101110;$1E
    .byte #%00111100;$1E
    .byte #%00011000;$1E
P0Bitmap6
    .byte #%00000000
    .byte #%00011000;$1E
    .byte #%00111100;$1E
    .byte #%01111110;$1E
    .byte #%01111110;$1E
    .byte #%01111110;$1E
    .byte #%01101110;$1E
    .byte #%00111100;$1E
    .byte #%00011000;$1E

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player colors.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Color:
    .byte #$00
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;    

P0ColorFrame0:
    .byte #$00
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;  

P0ColorFrame1:
    .byte #$00
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;  
    
P0ColorFrame2:
    .byte #$00
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;  
    
P0ColorFrame3:
    .byte #$00
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;  
    
P0ColorFrame4:
    .byte #$00
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;  
    
P0ColorFrame5:
    .byte #$00
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E; 

P0ColorFrame6:
    .byte #$00
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E;
    .byte #$1E; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    word Reset
    word Reset
