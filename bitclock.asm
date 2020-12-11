	processor 6502
	include vcs.h
	include macro.h

    seg.u vars
    org $80
hours   DS.B 1
minutes DS.B 1
seconds DS.B 1
frames  DS.B 1
hoursHi   DS.B 1
hoursLo   DS.B 1
minutesHi DS.B 1
minutesLo DS.B 1
secondsHi DS.B 1
secondsLo DS.B 1

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
InitComplete

;;; Setup time
    LDA #$23
    STA hours
    LDA #$58
    STA minutes
    LDA #$50
    STA seconds

;;; Setup Players
	LDA #$00
	STA COLUBK
	LDA #$57
	STA COLUP0

	LDA #$67
	STA COLUP1

    LDA #$67
    STA NUSIZ0
    STA NUSIZ1

    STA WSYNC

    Sleep 36

    STA RESP0

    Sleep 12
    STA RESP1

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

    LDA #$00
    STA VBLANK

    LDA #$67
    STA COLUP0
    LDA #$FF
    STA GRP0
    STA GRP1
    STA WSYNC
    STA WSYNC
    STA WSYNC

    LDA #$57
    STA COLUP0
    STA COLUP1
    LDA hoursHi
    STA GRP0
    LDA hoursLo
    STA GRP1

    LDX #75 ;; (228 - 3 ) / 3
DisplayHour
    STA WSYNC
    DEX
    BNE DisplayHour

    LDA #$47
    STA COLUP0
    STA COLUP1
    LDA minutesHi
    STA GRP0
    LDA minutesLo
    STA GRP1

    LDX #75 ;; (228 - 3 ) / 3
DisplayMinute
    STA WSYNC
    DEX
    BNE DisplayMinute

    LDA #$87
    STA COLUP0
    STA COLUP1
    LDA secondsHi
    STA GRP0
    LDA secondsLo
    STA GRP1

    LDX #75 ;; (228 - 3 ) / 3
DisplaySecond
    STA WSYNC
    DEX
    BNE DisplaySecond

    LDA #$02
    STA VBLANK

    ;; overscan 36
    LDA #43 ;; 42 * 64 cycles = 35.something lines
    STA TIM64T

OverscanLogicStart
AdvanceClock

    LDA frames
    CLC
    ADC #1
    STA frames
    CMP #50 ; PAL has 50 frames / sec
    BNE ClockIncrementDone
    SED
    LDA #0
    STA frames
    LDA seconds
    CLC
    ADC #1
    CMP #$60
    STA seconds
    BNE ClockIncrementDone
    LDA #0
    STA seconds
    LDA minutes
    CLC
    ADC #1
    STA minutes
    CMP #$60
    BNE ClockIncrementDone
    LDA #0
    STA minutes
    LDA hours
    CLC
    ADC #1
    STA hours
    CMP #$24
    BNE ClockIncrementDone
    LDA #0
    STA hours

ClockIncrementDone
    LDA hours
    JSR ExtractHigherNibble
    STA hoursHi
    LDA hours
    JSR ExtractLowerNibble
    STA hoursLo

    LDA minutes
    JSR ExtractHigherNibble
    STA minutesHi
    LDA minutes
    JSR ExtractLowerNibble
    STA minutesLo

    LDA seconds
    JSR ExtractHigherNibble
    STA secondsHi
    LDA seconds
    JSR ExtractLowerNibble
    STA secondsLo

OverscanLogicEnd
    CLD
WaitTimer
    LDA INTIM
    BNE WaitTimer

    ;; somewhere in line 35 and a few cycles left
    STA WSYNC

    JMP MainLoop

ExtractLowerNibble SUBROUTINE
    AND #$0F
    TAY
    LDA expandTable,Y
ExtractLowerNibbleEnd
    RTS

ExtractHigherNibble SUBROUTINE
    AND #$F0
    LSR
    LSR
    LSR
    LSR
    TAY
    LDA expandTable,Y
ExtractHigherNibbleEnd
    RTS

    org $FF00
expandTable
    DC.B #%00000000
    DC.B #%00000001
    DC.B #%00000100
    DC.B #%00000101
    DC.B #%00010000
    DC.B #%00010001
    DC.B #%00010100
    DC.B #%00010101
    DC.B #%01000000
    DC.B #%01000001


    org $FFFC
	.word Start
	.word Start
