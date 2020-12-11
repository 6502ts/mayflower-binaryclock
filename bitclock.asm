	processor 6502
	include vcs.h
	include macro.h

    MAC ASLN
        REPEAT {1}
            ASL
        REPEND
    ENDM

    MAC LSRN
        REPEAT {1}
            LSR
        REPEND
    ENDM

    MAC LDEXPAND
        LDX {1}
        LDA expandTable,X
    ENDM

    MAC CLOCKLINE
        STA WSYNC
        LDA #$00        ; 2
        STA VBLANK      ; 5
        LDA colorLeft   ; 7
        STA COLUBK      ; 10
        Sleep 32
        LDA colorRight
        STA COLUBK
    ENDM

    MAC UNPACK
        LDA {1}
        LSRN 4
        STA {1}Hi
        LDA {1}
        AND #$0F
        STA {1}Lo
    ENDM

    MAC PACK
        LDA {1}Hi
        ASLN 4
        EOR {1}Lo
        STA {1}
    ENDM

    MAC CONSTRAIN_BCD
        LDA {1}
        CMP #$09
        BNE .underflowCheckDone
        LDA #{2}
        STA {1}
.underflowCheckDone
        CMP #({2} + 1)
        BCC .overflowCheckDone
        LDA #$0
        STA {1}
.overflowCheckDone
    ENDM

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
    LDA #$80
    STA editMode
InitVariableComplete

;;; Setup TIA
    ; setup PLayfield
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

    ; one copy, 4 pixels wide
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

; LINES: 3

    LDX #44 ;; 47 - 3
    LDA #$02
    STA VBLANK
VBankLoop
    STA WSYNC
    DEX
    BNE VBankLoop

; LINES: 47

    LDA #$00
    STA colorLeft
    STA colorRight

    LDX #EDIT_MODE_COLOR
    LDA editMode
    CMP #$0
    BNE HoursLeftColorDone
    STX colorLeft
HoursLeftColorDone
    CMP #$1
    BNE HoursRightColorDone
    STX colorRight
HoursRightColorDone

    LDA #$57
    STA COLUP0
    STA COLUP1
    LDEXPAND hoursHi
    STA GRP0
    LDEXPAND hoursLo
    STA GRP1

    LDX #72 ;; (228 - 3 ) / 3 - 3
DisplayHour
    CLOCKLINE
    DEX
    BNE DisplayHour

; LINES: 119

    STA WSYNC
    LDA #$02
    STA VBLANK

    LDA #$00
    STA colorLeft
    STA colorRight

    LDX #EDIT_MODE_COLOR
    LDA editMode
    CMP #$2
    BNE MinutesLeftColorDone
    STX colorLeft
MinutesLeftColorDone
    CMP #$3
    BNE MinutesRightColorDone
    STX colorRight
MinutesRightColorDone

    LDA #$47
    STA COLUP0
    STA COLUP1
    LDEXPAND minutesHi
    STA GRP0
    LDEXPAND minutesLo
    STA GRP1

    STA WSYNC
    STA WSYNC

; LINES : 122

    LDX #72 ;; (228 - 3 ) / 3 - 3
DisplayMinute
    CLOCKLINE
    DEX
    BNE DisplayMinute

; LINES : 194

    STA WSYNC
    LDA #$02
    STA VBLANK

    LDA #$00
    STA colorLeft
    STA colorRight

    LDX #EDIT_MODE_COLOR
    LDA editMode
    CMP #$4
    BNE SeconsLeftColorDone
    STX colorLeft
SeconsLeftColorDone
    CMP #$5
    BNE SecondsRightColorDone
    STX colorRight
SecondsRightColorDone

    LDA #$87
    STA COLUP0
    STA COLUP1
    LDEXPAND secondsHi
    STA GRP0
    LDEXPAND secondsLo
    STA GRP1

    STA WSYNC
    STA WSYNC

; LINES : 197

    LDX #72 ;; (228 - 3 ) / 3 - 3
DisplaySecond
    CLOCKLINE
    DEX
    BNE DisplaySecond

; LINES : 269

    STA WSYNC
    LDA #$02
    STA VBLANK

; LINES : 270

    ;; overscan 42
    LDA #49 ;; 48 * 64 cycles = 40.something lines
    STA TIM64T

OverscanLogicStart
AdvanceClock
    LDA editMode
    BPL ClockIncrementDone

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

    UNPACK hours
    UNPACK minutes
    UNPACK seconds

    LDA INPT4
    TAX
    EOR lastInpt4
    STA scratch
    TXA
    EOR #$FF
    AND scratch
    BPL processFireEnd
    LDA editMode
    EOR #$80
    STA editMode
    BMI processFireEnd
    LDA #0
    STA frames
processFireEnd
    STX lastInpt4

    LDA editMode
    BMI processJoystickEnd

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
joystickTestLeft
    LDA #$40
    BIT scratch
    BEQ joystickTestLeftEnd
    LDA editMode
    SEC
    SBC #1
    BCS joystickTestLeftStore
    LDA #5
joystickTestLeftStore
    STA editMode
joystickTestLeftEnd
joystickTestRight
    LDA #$80
    BIT scratch
    BEQ joystickTestRightEnd
    LDA editMode
    CLC
    ADC #1
    CMP #6
    BNE joystickTestRightStore
    LDA #0
joystickTestRightStore
    STA editMode
joystickTestRightEnd
    STX lastSwcha
processJoystickEnd

    CONSTRAIN_BCD hoursHi,$02

    CMP #$02
    BNE constrainHoursLoDone
    CONSTRAIN_BCD hoursLo,$04
constrainHoursLoDone

    CONSTRAIN_BCD minutesHi,$05
    CONSTRAIN_BCD secondsHi,$05

    PACK hours
    PACK minutes
    PACK seconds

OverscanLogicEnd
WaitTimer
    LDA INTIM
    BNE WaitTimer

; LINES: 310.something

    ;; somewhere in line 40 and a few cycles left
    STA WSYNC
    STA WSYNC

; LINES : 312

    JMP MainLoop

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
