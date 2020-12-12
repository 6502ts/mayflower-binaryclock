EDIT_MODE_COLOR = $40

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

    MAC CLOCK_BLOCK
        LDX #72 ;; (228 - 3 ) / 3 - 3
.display
        STA WSYNC
        LDA #$00        ; 2
        STA VBLANK      ; 5
        LDA colorLeft   ; 7
        STA COLUBK      ; 10
        Sleep 32
        LDA colorRight
        STA COLUBK

        DEX
        BNE .display
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

    MAC SETUP_CURSOR
        LDA #$00
        STA colorLeft
        STA colorRight

        LDX #EDIT_MODE_COLOR
        LDA editMode
        CMP #{1}
        BNE .cursorLeftDone
        STX colorLeft
.cursorLeftDone
        CMP #({1} + 1)
        BNE .cursorRightDone
        STX colorRight
.cursorRightDone
    ENDM

    MAC SETUP_DIGITS
        STA COLUP0
        STA COLUP1
        LDEXPAND {1}Hi
        STA GRP0
        LDEXPAND {1}Lo
        STA GRP1
    ENDM
