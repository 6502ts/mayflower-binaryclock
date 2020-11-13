	processor 6502
	include ../vcs.h
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
    LDA #%10101010
    STA GRP0
    LDA #$07
    STA NUSIZ0

    STA WSYNC
    STA RESP0

MainLoop
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

    LDX #36 ;; overscan
OverScanLoop
    STA WSYNC
    DEX
    BNE OverScanLoop

    JMP MainLoop

 
    org $FFFC
	.word Start
	.word Start