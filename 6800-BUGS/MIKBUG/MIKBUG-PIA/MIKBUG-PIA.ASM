        NAM    MIKBUG
*      REV 009
*      COPYRIGHT 1974 BY MOTOROLA INC
*
*      MIKBUG (TM)
*
*      L  LOAD
*      G  GO TO TARGET PROGRAM
*      M  MEMORY CHANGE
*      F  PRINT/PUNCH DUMP
*      R  DISPLAY CONTENTS OF TARGET STACK
*            CC   B   A   X   P   S
PIASB   EQU    $8007
PIADB   EQU    $8006     B DATA
PIAS    EQU    $8005     PIA STATUS
PIAD    EQU    $8004     PIA DATA
*       OPT    MEMORY
        ORG    $E000

*     I/O INTERRUPT SEQUENCE
IO      LDX    IOV
        JMP    0,X

* NMI SEQUENCE
POWDWN  LDX    NIO       GET NMI VECTOR
        JMP    0,X

LOAD    EQU    *
        LDAA   #$3C
        STAA   PIASB     READER RELAY ON
        LDAA   #@21
        BSR    OUTCH     OUTPUT CHAR

LOAD3   BSR    INCH
        CMPA   #'S
        BNE    LOAD3     1ST CHAR NOT (S)
        BSR    INCH      READ CHAR
        CMPA   #'9
        BEQ    LOAD21
        CMPA   #'1
        BNE    LOAD3     2ND CHAR NOT (1)
        CLR    CKSM      ZERO CHECKSUM
        BSR    BYTE      READ BYTE
        SUBA   #2
        STAA   BYTECT    BYTE COUNT
* BUILD ADDRESS
        BSR    BADDR
* STORE DATA
LOAD11  BSR    BYTE

        DEC    BYTECT
        BEQ    LOAD15    ZERO BYTE COUNT
        STAA   0,X       STORE DATA
        INX
        BRA    LOAD11

LOAD15  INC    CKSM
        BEQ    LOAD3
LOAD19  LDAA   #'?       PRINT QUESTION MARK
        BSR    OUTCH
LOAD21  EQU    *
C1      JMP    CONTRL

* BUILD ADDRESS
BADDR   BSR    BYTE      READ 2 FRAMES
        STAA   XHI
        BSR    BYTE
        STAA   XLOW
        LDX    XHI       (X) ADDRESS WE BUILT
        RTS

*INPUT BYTE (TWO FRAMES)
BYTE    BSR    INHEX     GET HEX CHAR
        ASLA
        ASLA
        ASLA
        ASLA
        TAB
        BSR    INHEX
        ABA
        TAB
        ADDB   CKSM
        STAB   CKSM
        RTS

OUTHL   LSRA            OUT HEX LEFT BCD DIGIT
        LSRA
        LSRA
        LSRA

OUTHR   ANDA   #$F       OUT HEX RIGHT BCD DIGIT
        ADDA   #$30
        CMPA   #$39
        BLS    OUTCH
        ADDA   #$7

* OUTPUT ONE CHAR
OUTCH   JMP    OUTEEE
INCH    JMP    INEEE

* PRINT DATA POINTED AT BY X-REG
PDATA2  BSR    OUTCH
        INX
PDATA1  LDAA   0,X
        CMPA   #4
        BNE    PDATA2
        RTS              STOP ON EOT

* CHANGE MENORY (M AAAA DD NN)
CHANGE  BSR    BADDR     BUILD ADDRESS
CHA51   LDX    #MCL
        BSR    PDATA1    C/R L/F
        LDX    #XHI
        BSR    OUT4HS    PRINT ADDRESS
        LDX    XHI
        BSR    OUT2HS    PRINT DATA (OLD)
        STX    XHI       SAYE DATA ADDRESS
        BSR    INCH      INPUT ONE CHAR
        CMPA   #$20
        BNE    CHA51     NOT SPACE
        BSR    BYTE      INPUT NEW DATA
        DEX
        STAA   0,X       CHANGE MEMORY
        CMPA   0,X
        BEQ    CHA51     DID CHANGE
        BRA    LOAD19    NOT CHANGED

* INPUT HEX CHAR
INHEX   BSR    INCH
        SUBA   #$30
        BMI    C1        NOT HEX
        CMPA   #$09
        BLE    IN1HG
        CMPA   #$11
        BMI    C1        NOT HEX
        CMPA   #$16
        BGT    C1        NOT HEX
        SUBA   #7
IN1HG   RTS

OUT2H   LDAA   0,X       OUTPUT 2 HEX CHAR
OUT2HA  BSR    OUTHL     OUT LEFT HEX CHAR
        LDAA   0,X
        INX
        BRA    OUTHR     OUTPUT RIGHT HEX CHAR AND R

OUT4HS  BSR    OUT2H     OUTPUT 4 HEX CHAR + SPACE
OUT2HS  BSR    OUT2H     OUTPUT 2 HEX CHAR + SPACE

OUTS    LDAA   #$20      SPACE
        BRA    OUTCH     (BSR & RTS)

* ENTER POWER  ON SEQUENCE
START   EQU    *
        LDS    #STACK
        STS    SP        INZ TARGET'S STACK PNTR
* INZ PIA
        LDX    #PIAD     (X) POINTER TO DEVICE PIA
        INC    0,X       SET DATA DIR PIAD
        LDAA   #$7
        STAA   1,X       INIT CON PIAS
        INC    0,X       MARK COM LINE
        STAA   2,X       SET DATA DIR PIADB
CONTRL  LDAA   #$34
        STAA   PIASB     SET CONTROL PIASB TURN READ
        STAA   PIADB     SET TIMER INTERVAL
        LDS    #STACK    SET CONTRL STACK POINTER
        LDX    #MCLOFF

        BSR    PDATA1    PRINT DATA STRING

        BSR    INCH      READ CHARACTER
        TAB
        BSR    OUTS      PRINT SPACE
        CMPB   #'L
        BNE    *+5
        JMP    LOAD
        CMPB   #'M
        BEQ    CHANGE
        CMPB   #'R
        BEQ    PRINT     STACK
        CMPB   #'P
        BEQ    PUNCH     PRINT/PUNCH
        CMPB   #'G
        BNE    CONTRL
        LDS    SP        RESTORE PGM'S STACK PTR
        RTI              GO

* ENTER FROM SOFTWARE INTERRUPT
SFE     EQU    *
        STS    SP        SAVE TARGET'S STACK POINTER
* DECREMENT P-COUNTER
        TSX
        TST    6,X
        BNE    *+4
        DEC    5,X
        DEC    6,X

* PRINT CONTENTS OF STACK
PRINT   LDX    SP
        INX
        BSR    OUT2HS    CONDITION CODES
        BSR    OUT2HS    ACC-B
        BSR    OUT2HS    ACC-A
        BSR    OUT4HS    X-REG
        BSR    OUT4HS    P-COUNTER
        LDX    #SP
        BSR    OUT4HS    STACK POINTER
C2      BRA    CONTRL

* PUNCH DUMP
* PUNCH FROM BEGINNING ADDRESS (BEGA) THRU ENDING
* ADDRESS (ENDA)
*
MTAPE1  FCB    $D,$A,0,0,0,0,'S,'1,4 PUNCH FORMAT


PUNCH   EQU    *

        LDAA   #$12      TURN TTY PUNCH ON
        JSR    OUTCH     OUT CHAR  

        LDX    BEGA
        STX    TW        TEMP BEGINNING ADDRESS
PUN11   LDAA   ENDA+1
        SUBA   TW+1
        LDAB   ENDA
        SBCB   TW
        BNE    PUN22
        CMPA   #16
        BCS    PUN23
PUN22   LDAA   #15
PUN23   ADDA   #4
        STAA   MCONT     FRAME COUNT THIS RECORD
        SUBA   #3
        STAA   TEMP      BYTE COUNT THIS RECORD
* PUNCH C/R,L/F,NULL,S,1
        LDX    #MTAPE1
        JSR    PDATA1
        CLRB             ZERO CHECKSUM
* PUNCH FRAME COUNT
        LDX    #MCONT
        BSR    PUNT2     PUNCH 2 HEX CHAR
* PUNCH ADDRESS
        LDX    #TW
        BSR    PUNT2
        BSR    PUNT2
* PUNCH DATA
        LDX    TW
PUN32   BSR    PUNT2     PUNCH ONE BYTE (2 FRAMES)
        DEC    TEMP      DEC BYTE COUNT
        BNE    PUN32
        STX    TW
        COMB
        PSHB
        TSX
        BSR    PUNT2     PUNCH CHECKSUM
        PULB             RESTORE STACK
        LDX    TW
        DEX
        CPX    ENDA
        BNE    PUN11
        BRA    C2        JMP TO CONTRL

* PUNCH 2 HEX CHAR UPDATE CHECKSUM
PUNT2   ADDB   0,X       UPDATE CHECKSUM
        JMP    OUT2H     OUTPUT TWO HEX CHAR AND RTS


MCLOFF  FCB    $13       READER OFF
MCL     FCB    $D,$A,$14,0,0,0,'*,4 C/R,L/F,PUNCH

*
SAV     STX    XTEMP
        LDX    #PIAD
        RTS

*INPUT   ONE CHAR INTO A-REGISTER
INEEE   PSHB             SAVE ACC-B
        BSR    SAV       SAV XR
IN1     LDAA   0,X       LOOK FOR START BIT
        BMI    IN1
        CLR    2,X       SET COUNTER FOR HALF BIT TI
        BSR    DE        START TIMER
        BSR    DEL       DELAY HALF BIT TIME
        LDAB   #4        SET DEL FOR FULL BIT TIME
        STAB   2,X
        ASLB             SET UP CNTR WITH 8

IN3     BSR    DEL       WAIT ONE CHAR TIME
        SEC              NARK CON LINE
        ROL    0,X       GET BIT INTO CFF
        RORA             CFF TO AR
        DECB
        BNE    IN3
        BSR    DEL       WAIT FOR STOP BIT
        ANDA   #$7F      RESET PARITY BIT
        CMPA   #$7F
        BEQ    IN1       IF RUBOUT, GET NEXT CHAR
        BRA    IOUT2     GO RESTORE REG

* OUTPUT ONE CHAR 
OUTEEE  PSHB             SAV BR
        BSR    SAV       SAV XR
IOUT    LDAB   #$A       SET UP COUNTER
        DEC    0,X       SET START BIT
        BSR    DE        START TIMER
OUT1    BSR    DEL       DELAY ONE BIT TIME
        STAA   0,X       PUT OUT ONE DATA BIT
        SEC              SET CARRY BIT
        RORA             SHIFT IN NEXT BIT
        DECB             DECREMENT COUNTER
        BNE    OUT1      TEST FOR 0
IOUT2   LDAB   2,X       TEST FOR STOP BITS
        ASLB             SHIFT BIT TO SIGN
        BPL    IOS       BRANCH FOR 1 STOP BIT
        BSR    DEL       DELAY-FOR STOP BITS
IOS     LDX    XTEMP     RES XR
        PULB             RESTORE BR
        RTS

DEL     TST    2,X       IS TIME UP
        BPL    DEL
DE      INC    2,X       RESET TIMER
        DEC    2,X
        RTS
	
        FDB    IO
        FDB    SFE
        FDB    POWDWN
        FDB    START
		
        ORG    $A000
IOV     RMB    2         IO INTERRUPT POINTER
BEGA    RMB    2         BEGINNING ADDR PRINT/PUNCH
ENDA    RMB    2         ENDING ADDR PRINT/PUNCH
NIO     RMB    2         NMI INTERRUPT POINTER
SP      RMB    1         S-HIGH
        RMB    1         S-LOW
CKSM    RMB    1         CHECKSUM

BYTECT  RMB    1         BYTE COUNT
XHI     RMB    1         XREG HIGH
XLOW    RMB    1         XREG LOW
TEMP    RMB    1         CHAR COUNT (INADD)
TW      RMB    2         TEMP/
MCONT   RMB    1         TEMP
XTEMP   RMB    2         X-REG TEMP STORAGE
        RMB    46
STACK   RMB    1         STACK POINTER


        END    
