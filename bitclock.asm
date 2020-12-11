	processor 6502
	include vcs.h
	include macro.h

EDIT_MODE_COLOR = $40

    seg.u vars
    org $80
hours   DS.B 1
minutes DS.B 1
seconds DS.B 1
frames  DS.B 1

timeBcDStart
hoursHi   DS.B 1
hoursLo   DS.B 1
minutesHi DS.B 1
minutesLo DS.B 1
secondsHi DS.B 1
secondsLo DS.B 1

editMode  DS.B 1
lastInpt4 DS.B 1
lastSwcha DS.B 1
scratch   DS.B 1
colorLeft DS.B 1
colorRight DS.B 1

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
    LDA INPT4
    STA lastInpt4
    LDA SWCHA
    STA lastSwcha
InitVariableComplete

;;; Setup TIA
	LDA #$00
	STA COLUBK
	LDA #$57
	STA COLUP0
	LDA #$67
	STA COLUP1

    LDA 20
    STA COLUPF
    LDA #$01
    STA CTRLPF
    LDA #%00000000
    STA PF0
    LDA #%00000010
    STA PF1
    LDA #%00010101
    STA PF2

    LDA #$67
    STA NUSIZ0
    STA NUSIZ1

    STA WSYNC

    Sleep 30

    STA RESP0

    Sleep 14
    STA RESP1

    LDA #$10
    STA HMP0
    STA WSYNC
    STA HMOVE

MainLoop

    LDA #$02
    STA VSYNC

    STA WSYNC
    STA WSYNC
    STA WSYNC

    LDA #0
    STA VSYNC

    LDX #44 ;; 47 - 3
    LDA #$02
    STA VBLANK
VBankLoop
    STA WSYNC
    DEX
    BNE VBankLoop

    LDA #$00
    STA colorLeft
    STA colorRight

    LDX #EDIT_MODE_COLOR
    LDA editMode
    CMP #$1
    BNE HourHighColorDone
    STX colorLeft
HourHighColorDone
    CMP #$2
    BNE HourLowColorDone
    STX colorRight
HourLowColorDone

    LDA #$57
    STA COLUP0
    STA COLUP1
    LDX hoursHi
    LDA expandTable,X
    STA GRP0
    LDX hoursLo
    LDA expandTable,X
    STA GRP1

    LDX #72 ;; (228 - 3 ) / 3
DisplayHour
    STA WSYNC
    LDA #$00        ; 2
    STA VBLANK      ; 5
    LDA colorLeft   ; 7
    STA COLUBK      ; 10
    Sleep 32
    LDA colorRight
    STA COLUBK

    DEX
    BNE DisplayHour

    STA WSYNC
    LDA #$02
    STA VBLANK

    LDA #$00
    STA colorLeft
    STA colorRight

    LDX #EDIT_MODE_COLOR
    LDA editMode
    CMP #$3
    BNE MinuteHighColorDone
    STX colorLeft
MinuteHighColorDone
    CMP #$4
    BNE MinuteLowColorDone
    STX colorRight
MinuteLowColorDone

    LDA #$47
    STA COLUP0
    STA COLUP1
    LDX minutesHi
    LDA expandTable,X
    STA GRP0
    LDX minutesLo
    LDA expandTable,X
    STA GRP1

    STA WSYNC
    STA WSYNC

    LDX #72 ;; (228 - 3 ) / 3
DisplayMinute
    STA WSYNC
    LDA #$00
    STA VBLANK      ; 5
    LDA colorLeft   ; 7
    STA COLUBK      ; 10
    Sleep 32
    LDA colorRight
    STA COLUBK

    DEX
    BNE DisplayMinute

    STA WSYNC
    LDA #$02
    STA VBLANK

    LDA #$00
    STA colorLeft
    STA colorRight

    LDX #EDIT_MODE_COLOR
    LDA editMode
    CMP #$5
    BNE SecondHighColorDone
    STX colorLeft
SecondHighColorDone
    CMP #$6
    BNE SecondLowColorDone
    STX colorRight
SecondLowColorDone

    LDA #$87
    STA COLUP0
    STA COLUP1
    LDX secondsHi
    LDA expandTable,X
    STA GRP0
    LDX secondsLo
    LDA expandTable,X
    STA GRP1

    STA WSYNC
    STA WSYNC

    LDX #72 ;; (228 - 3 ) / 3
DisplaySecond
    STA WSYNC
    LDA #$0
    STA VBLANK      ; 5
    LDA colorLeft   ; 7
    STA COLUBK      ; 10
    Sleep 32
    LDA colorRight
    STA COLUBK

    DEX
    BNE DisplaySecond

    STA WSYNC
    LDA #$02
    STA VBLANK

    ;; overscan 42
    LDA #49 ;; 48 * 64 cycles = 40.something lines
    STA TIM64T

OverscanLogicStart
AdvanceClock
    LDA editMode
    BNE ClockIncrementDone

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
    STA seconds
    CMP #$60
    BCC ClockIncrementDone
    LDA #0
    STA seconds
    LDA minutes
    CLC
    ADC #1
    STA minutes
    CMP #$60
    BCC ClockIncrementDone
    LDA #0
    STA minutes
    LDA hours
    CLC
    ADC #1
    STA hours
    CMP #$24
    BCC ClockIncrementDone
    LDA #0
    STA hours

ClockIncrementDone
    CLD

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

    LDA INPT4
    TAX
    EOR lastInpt4
    STA scratch
    TXA
    EOR #$FF
    AND scratch
    BPL processFireEnd
    LDA editMode
    CLC
    ADC #1
    CMP #7
    BNE toggleEditModeDone
    LDA #0
    STA frames
toggleEditModeDone
    STA editMode
processFireEnd
    STX lastInpt4

    LDA editMode
    BEQ OverscanLogicEnd
    LDA SWCHA
    TAX
    EOR lastSwcha
    STA scratch
    TXA
    EOR #$FF
    AND scratch
    STA scratch
joystickTestUp
    LDY editMode
    DEY
    LDA #$10
    BIT scratch
    BEQ joystickTestUpEnd
    LDA timeBcDStart,Y
    CLC
    ADC #1
    CMP #10
    BNE joystickTestUpStore
    LDA #0
joystickTestUpStore
    STA timeBcDStart,Y
joystickTestUpEnd
joystickTestDown
    LDA #$20
    BIT scratch
    BEQ joystickTestDownEnd
    LDA timeBcDStart,Y
    SEC
    SBC #1
    BCS joystickTestDownStore
    LDA #9
joystickTestDownStore
    STA timeBcDStart,Y
joystickTestDownEnd
    STX lastSwcha

    LDA hoursHi
    ASL
    ASL
    ASL
    ASL
    EOR hoursLo
    STA hours

    LDA minutesHi
    ASL
    ASL
    ASL
    ASL
    EOR minutesLo
    STA minutes

    LDA secondsHi
    ASL
    ASL
    ASL
    ASL
    EOR secondsLo
    STA seconds

OverscanLogicEnd
WaitTimer
    LDA INTIM
    BNE WaitTimer

    ;; somewhere in line 40 and a few cycles left
    STA WSYNC
    STA WSYNC

    JMP MainLoop

ExtractLowerNibble SUBROUTINE
    AND #$0F
    RTS

ExtractHigherNibble SUBROUTINE
    AND #$F0
    LSR
    LSR
    LSR
    LSR
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
