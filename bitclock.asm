	processor 6502
	include vcs.h
	include macro.h

    include bitclock_macros.h
    include variables.h

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
; ================ HOURS ================

    SETUP_CURSOR 0
    LDA #$57
    SETUP_DIGITS hours

    CLOCK_BLOCK

; LINES: 119
; =============== MINUTES ===============

    STA WSYNC
    LDA #$02
    STA VBLANK

    SETUP_CURSOR 2
    LDA #$47
    SETUP_DIGITS minutes

    STA WSYNC
    STA WSYNC

; LINES : 122

    CLOCK_BLOCK

; LINES : 194
; =============== SECONDS ===============

    STA WSYNC
    LDA #$02
    STA VBLANK

    SETUP_CURSOR 4
    LDA #$87
    SETUP_DIGITS seconds

    STA WSYNC
    STA WSYNC

; LINES : 197

    CLOCK_BLOCK

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

    include constants.h

    org $FFFC
	.word Start
	.word Start
