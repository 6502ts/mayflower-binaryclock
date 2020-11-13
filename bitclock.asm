	processor 6502
	include ../vcs.h
	include ../macro.h

    seg.u vars
    org $80
hours   DS.B 1
minutes DS.B 1
seconds DS.B 1
frames  DS.B 1
    seg code_main
    org $F000

Start
	SEI	
	CLD  	

;;; Clear Page0
	LDX #$FF	
	TXS	
	LDA #0		
ClearMem 
	STA 0,X		
	DEX		
	BNE ClearMem

;;; Setup Players

	LDA #$00		
	STA COLUBK	
	LDA #$57
	STA COLUP0
	LDA #$67
	STA COLUP1
    LDA #%10101010
    STA GRP0
    STA GRP1
    LDA #$67
    STA NUSIZ0
    STA NUSIZ1

    LDA #02
    STA ENAM0
    STA ENAM1

    STA WSYNC

    STA RESM0
    STA RESM1

    Sleep 20
    STA RESM0
    STA RESM1

    NOP
    NOP

    STA RESP1

    Sleep 12

    STA RESP0
MainLoop
    LDA seconds
    STA GRP0
    LDA minutes
    STA GRP1

    LDA #$02
    STA VSYNC
    
    STA WSYNC
    STA WSYNC
    STA WSYNC
    
    LDA #0
    STA VSYNC

    LDX #45 ;; 48 - 3
    LDA #$02
    STA VBLANK
VBankLoop
    STA WSYNC
    DEX
    BNE VBankLoop

    LDX #228 ;; 228 
    LDA #$00
    STA VBLANK
Display
    STA WSYNC
    DEX
    BNE Display

    LDX #36 ;; overscan 36
OverScanLoop
    STA WSYNC
    DEX
    BNE OverScanLoop

    LDA frames
    ADC #1
    STA frames
    CMP #50 ; PAL has 50 frames / sec
    BNE MainLoop
    LDA #0
    STA frames
    LDA seconds
    ADC #1
    CMP #60
    STA seconds
    BNE MainLoop
    LDA #0
    STA seconds
    LDA minutes
    ADC #1
    STA minutes

    JMP MainLoop

 
    org $FFFC
	.word Start
	.word Start