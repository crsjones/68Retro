* TITLE   DREAM INVADERS (C) 1980; M.J. Bauer
*
*
* SCRATCHPAD RAM ASSIGNMENTS (PAGE ZERO):
* ARRAY OF ALIEN X-COORDS;  5 ROWS BY 8 COLS:
ALNARR  EQU     $C0     ALIEN ARRAY (40 BYTES)
*
* ARRAY OF ALIEN MISSILE COORDINATES;  4 X-Y PAIRS:
MISARR  EQU     $88     ALIENS' MISSILE ARRAY
*
* POINTERS:
	    ORG     $0090
MVAPTR  RMB     2       POINTS TO NEXT ALIEN TO MOVE
ALAPTR  RMB     2       GENERAL--PURPOSE PTR TO ALNARR
MISPTR  RMB     2       POINTS TO MISARR
ROW     RMB     1       TEMP ROW COUNT
COL     RMB     1       TEMP COL COUNT
*
* FLAGS.  (NON-ZERO IS 'TRUE' CONDITION)
NOALFG  RMB     1       NO ALIENS LEFT
LFLAG   RMB     1       ALIEN MISSILE HAS BEEN LAUNCHED
DROPFG  RMB     1       ALIEN DROPPED TO LOWER ROW
NGFLG   RMB     1       NO GUN TURRETS LEFT
ALNDFG  RMB     1       ALIEN LANDED
KMOVE   RMB     1       ALIEN MOVE COMPLETED
*
* VARIABLES:
	    ORG     $00A0
ALIENX  RMB     1       GENERAL ALIEN COORDS
ALIENY  RMB     1
AMISX   RMB     1       GENERAL MISSILE COORDS
AMISY   RMB     1
GMISX   RMB     1       GUN MISSILE COORDS
GMISY   RMB     1
GUNPOS  RMB     1       GUN-TURRET POSITION (X)
SCORE   RMB     1       NO, OF ALIENS EXTERMINATED
KSTEP   RMB     1       ALIEN STEPS BEFORE DIR'N CHANGER
NMOVE   RMB     1       MAX. )(MOVE PER CYCLE
ALSTEP  RMB     1       ALIEN STEP (+1 RIGHT;  -1 LEFT)
KALIEN  RMB     1       ALIENS ON SCREEN COUNTER
KGUNS   RMB     1       GUN-TURRETS LEFT COUNT
QUOT    RMB     1       DIV QUOTIENT (TEMP)
KMISS   RMB     1       ALIEN'S ACTIVE-MISSILE COUNT
NMISS   RMB     1       MAX. SIMULTANEOUS ALIEN MISSILES
MDELAY  RMB     1       MAIN CYCLE DELAY (GAME SPEED)
CLOCK1  RMB     1       CONTROL-CYCLE TIMERS
CLOCK2  RMB     1
KSHOT   RMB     1       SHOT COUNTER (used for DROP)
NDROP   RMB     1       * SHOTS BEFORE ALIEN CAN DROP
ROUND   RMB     1       ROUND ( 24 aliens per round)
DECIM   RMB     4       DECIMAL EQUIV. WORKSPACE
*
* EXTERNAL (CHIPOS) REFERENCES:
*
SHOWX   EQU     $C226   Show symbol  @ X, @(VX,VY),  B byte
ERASE   EQU     $C079   Clear screen
RANDOM  EQU     $C132   Get random byte (A)
BTON    EQU     $C2E5   Bleeper   (variable)
PAINZ   EQU     $C287   Initialize keypad port
FILL    EQU     $C07D   Fill screen memory with constant
BTONE   EQU     $C2E1   Bleep for (B)*20 mSec.
GETKEY  EQU     $C2C4   Wait for input from keypad
DIGOUT  EQU     $C3D2   Display digit  @ X
DECEQ   EQU     $C1E0   Store 3-digit decimal equiv @ X
CURS1   EQU     $C3E0   Set display  'cursor' Pos'n (A)
*
VX      EQU      $2E                                      
VY      EQU      $2F
VF      EQU      $3F
HITFLG  EQU      $3F     'Objects collided'  flag - VF
TIME    EQU      $20
TONE    EQU      $21
*
DISBUF  EQU      $0100
ENDBUF  EQU      $0200
*
*
*
PIAA    EQU      $8010   I/O PORT (KEYPAD)
PIAB    EQU      $8012   Spkr, RTC. etc.
*
*
*******************************************************
*           DREAM INVADERS - - - COPYRIGHT NOTICE     *
*                                                     *
* No part of this Program may be reproduced in any    *
* form or used in other software product for Purpose  *
* of distribution or commercial gain, except with     *
* Permission from the author.                         *
*                                                     *
*******************************************************
* MAINLINE (INITIALIZATION AND CONTROL CYCLE):
*
	ORG       $0200
*
MAINGO  JSR       PAINZ   Reset keypad port.
	    LDAA     #0       CLEAR VARIABLES 
        LDX       #$90
MAIN1   STAA     0,X
        INX
        CPX       #$00C0    
        BNE       MAIN1
*
*INITIALIZE FOR NEW GAME:
MAIN2   JSR       ADJ2     Set initial game parameters
        LDAA     #4       Start with 4 guns
        STAA     KGUNS
* INZ. FOR NEW ROUND:
MAIN3   INC       ROUND    Begin next round
        LDAA     #24      Alien count = 24
        STAA     KALIEN
        CLR       NOALFG
        CLR       KSTEP
        JSR       INZALA   SETUP ALIEN ARRAY
        JSR       ERASE
        JSR       SHOWAA   SHOW ALIEN ARRAY
        LDAA     #1
        STAA     ALSTEP   Start with aliens stepping right
        LDAA     #$1C     Start with gun centred
        STAA     GUNPOS
        BSR       INZMIS   Clear the missile array
*
MAIN4   CLR       CLOCK2
        CLR       CLOCK1
* START WITH JUST ALIENS MOVING (Insideous, isn't it?)
MAIN5   JSR       MOVALN
        LDAA     KSTEP    Move ALL aliens thru 8 steps
        CMPA     #8
        BEQ       MAIN6
        BSR       DELAY
        BRA       MAIN5
*
MAIN6   JSR       DSPGUN   Show gun turret
* A-C-T-T-O-N !
*
CONTRL  LDAA  CLOCK1
        ANDA    #$01
        BNE      CTRL1
        JSR      MOVGM        Move/fire qun-missile
        LDAA    NOALFG       Aliens depleted?
        BNE      MAIN3        If so, new round.
*
CTRL1   LDAA    CLOCK2
        BNE      CTRL2
        JSR      MOVALN       Move next alien in turn
        LDAA    ALNDFG       Alien landed?
        BNE      ENDGAM       If so. end game
        JSR      MOVGUN       Move gun
*
CTRL2   LDAA    CLOCK1
        ANDA    #$03
        BNE      CTRL3
        JSR      MVAMIS       Move (/launch) alien-missiles
        LDAA    NGFLG        Guns depleted?
        BNE      ENDGAM
*
CTRL3   BSR      DELAY
        LDAA    CLOCK1       Adjust clocks
        INCA
        CMPA    #12
        BNE      *+3
        CLRA
        STAA    CLOCK1
        LDAA    CLOCK2
        INCA
        CMPA    #3
        BNE      *+3
        CLRA
        STAA  CLOCK2
        BRA    CONTRL
*
*
* VARIABLE DELAY TO SET SAME SPFED (MDELAY*100 uSec.):
DELAY   LDAB  MDELAY
DEL1    LDAA  #9
        NOP
DEL2    NOP
        DECA
        BNE    DEL2
        DECB
        BNE    DEL1
        RTS

ENDGAM  JSR    STATUS     Show round, scrore, guns
        JSR    GETKEY     Wait for key to restart game
        JMP    MAINGO
*
*  INITIALIZE MISSILE ARRAY:
INZMIS  LDX    #MISARR
        LDAA   #$FF
        STAA   GMISY
INZM1   STAA   0,X
        INX
        CPX    #MISARR+8
        BNE    INZM1
        RTS
*
*  INITIALIZE ALIEN ARRAY FOR NEW ROUND:
INZALA  LDX     #ALNARR       point to alien array
        STX     MVAPTR        Reset 'Move Alien' pointer
        CLRA
        LDAB   #40           Do 40 times......
INZA1   CMPB   #16           Done first 24 (ie 3 rows)?
        BGT     *+4
        LDAA   #$FF          Last 2 rows = $FF
        STAA   0,X
        ADDA   #8            Next col.
        ANDA   #$3F          For 64 dot wide screen.
        INX                   )
        DECB                 ) Next element
        BNE     INZA1         )
        RTS
*
* SHOW ALIENS STORED IN ARRAY:
SHOWAA  LDX     #ALNARR
        CLR     ALIENY        First row; alien y = 0
        LDAB   #5            For 5 rows....... 
SHAA1   PSHB
        LDAB   #8            For 8 cols 
SHAA2   PSHB
        STX     ALAPTR
        LDAA   0,X           Get x-coord
        BMI     SHAA3        Null. forget it
        STAA   ALIENX
        JSR     DSPAL        Show alien
SHAA3   LDX     ALAPTR       )
        INX                  )
        PULB                 )   Next col.
        DECB                 )
        BNE     SHAA2
        LDAA   ALIENY        )
        ADDA   #5            )
        STAA   ALIENY        )   Next row.
        PULB                 )
        DECB                 )
        BNE     SHAA1        )
        RTS
*
*  MOVE NEXT ALIEN IN SEQUENCE:
MOVALN  CLR     KMOVE
MVA2    LDX     MVAPTR
        LDAA    0,X           Fetch alien-x
        STAA    ALIENX
        BMI     MVA7          Skip if  null.
        LDAA   KSHOT         Check if OK to drop down
        CMPA   NDROP
        BLT     MVA4          NO
        BSR     DROP          Attempt to drop down 1 row
        LDAA   DROPFG        Success?
        BNE     MVA6          YES
MVA4    BSR     CALCY         Compute alien y-coord
        JSR     DSPAL         Erase alien at old coords
        LDX     MVAPTR        Point to alien array
        LDAA   0,X
        ADDA   ALSTEP        Step x-coord
        ANDA   #$3F
        STAA   0,X
        STAA   ALIENX
        JSR     DSPAL         Show alien at new coords
MVA6    INC     KMOVE         Bump counter
MVA7    LDX     MVAPTR        Bump Pointer
        INX
        CPX     #ALNARR+40    Done?
        BNE     MVA8
        BSR     DIRECT        Set direction of alien movement
        LDX     #ALNARR       Reset pointer
MVA8    STX     MVAPTR
        LDAA   KMOVE         Move commleted ?
        BEQ     MVA2
        RTS
*
*  CALCULATE ROW (B) AND Y-COORD (A) FROM POINTER:
CALCY   LDAA   MVAPTR+1
        LSRA
        LSRA
        LSRA                A = row count
        ANDA   #$7
        TAB                   B = ROW
        ASLA
        ASLA
        ABA                   Y = ROW*5 (=A)
        STAA   ALIENY
        RTS
*
*  SET DIRCTION OF ALIEN MOVEMENT:
DIRECT LDAA   KSTEP          Incr. step counter
       INCA                                                       -.
       STAA   KSTEP
       CMPA   #96          Reverse if all aliens done 96 steps
       BNE     DIR1
       CLR     KSTEP
       NEG     ALSTEP
DIR1   RTS
*
* ATTEMPT TO DROP ALIEN DOWN TO LOWER ROW:
DROP   CLR     DROPFG         Clear 'alien dropped' flag
       BSR     CALCY          Compute ROW (= B)
       CMPB   #4             This alien on row 4 ?
       BEQ     DROP6          Yes; alien just landed! (End)
       LDAA   MVAPTR+1       NO, check for clear below
       ADDA   #8
       STAA   ALAPTR+1
       LDX     ALAPTR         Look at next row down
       LDAA   0,X
       CMPA   #$FF           Is there a vacant slot ?
       BNE     DROP4          No; forget it.
DROP2  LDX     MVAPTR         Make null entry in old row
       LDAA   #$FF
       STAA   0,X
       JSR     DSPAL          Remove alien from old row
       LDX     ALAPTR         Store x-coord in new row.
       LDAA   ALIENX
       STAA   0,X       
DROP3  LDAA   ALIENY         calc. y-coord in new row
       ADDA   #5
       STAA   ALIENY
       JSR     DSPAL          Show alien in new row
       CLR     KSHOT          Reset shot counter
       INC     DROPFG         Set 'alien dropped' flag
DROP4  RTS
*
* ALIEN LANDED; FLAG END OF GAME:
DROP6  INC     ALNDFG         Set 'alien landed' flag
       JSR     DSPAL          Remove old alien
       BSR     DROP3          Show it in new row
       JSR     DSBLOT         Blot it
       LDAB   #100           Bleep 2 sec
       JSR     BTONE
       RTS
*
* MOVE GUN (If left or right key closed):
MOVGUN LDAA   #$01           Check for LEFT key closed.
       BITA   PIAA
       BNE     MVG2
       JSR     DSPGUN         Erase gun at old x.
       LDAA   GUNPOS
       CMPA   #$02           (Don't want GUNPOS = 0 or 1)
       BEQ     MVG1           Skip if hard left
       DECA                  Move left
       STAA   GUNPOS
MVG1   JSR     DSPGUN         Show gun at new x.
       RTS
*
MVG2   LDAA   #$02
       BITA   PIAA           Check for RIGHT key closed.
       BNE     MVG4
       JSR     DSPGUN
       LDAA   GUNPOS
       CMPA   #$3B           Skip if gun is hard right
       BGE     MVG3
       INCA                  Move right
       STAA   GUNPOS
MVG3   JSR     DSPGUN
MVG4   RTS
*
*MOVE GUN MISSILE; TEST FOR HIT:
MOVGM  LDAA   GMISY          See if missile active
       BMI     MGM2
       BEQ     DISAGM         Disable if top of screen.
       JSR     DSPGM          Move UP 1 unit.
       DEC     GMISY
       JSR     DSPGM
       LDAA   HITFLG         Hit anything?
       BNE     MGM4           Yes.
       RTS
MGM2   LDAA   #$08           FIRE button pressed?
       BITA   PIAA
       BEQ     FIREGM
       RTS
*
* DISABLE GUN MISSILE:
DISAGM JSR     DSPGM          Erase missile
DGM1   LDAA   #$FF
       STAA   GMISY          Store null code.
       RTS
*
* FIRE GUN MISSILE:
FIREGM LDAA   GUNPOS
       ADDA   #2             = centre of gun
       STAA   GMISX
       LDAA   #$1B
       STAA   GMISY
       JSR     DSPGM          Show missile
       INC     KSHOT          Bump shot counter
       RTS
*
* DETERMINE WHAT GUN MISSILE INTERCEPTED:
MGM4   LDX     #MISARR        Was it an alien missile?
MGM5   LDAA   0,X
       CMPA   GMISX          Compare missile coords.
       BNE     MGM6
       LDAA   1,X
       CMPA   GMISY
       BEQ     MGM8           Yes, hit missile.
MGM6   INX                    No, try next missile.
       INX
       CPX     #MISARR+8 
       BNE     MGM5
       BSR     HITALN         Must have hit alien
       RTS
*
* GUN MISSILE HITS ALIEN MISSILE:
MGM8   LDAA   #$FF           Kill alien missile
       STAA   0,X
       STAA   1,X
       JSR     DISMIS         Display missile collision
       BSR     DGM1           Disable gun missile 
       RTS
*
* SEARCH ALIEN ARRAY FOR X-COORD OF HIT ALIEN: 
HITALN LDAA   GMISY          Get gun missile y-coord. 
       LDAB   #5
       JSR     DIV            A=A/5 = row of #
       TAB                    Alien-Y-coord = row x 5
       ASLA
       ASLA
       ABA
       STAA   ALIENY
       TBA                    Compute array pointer
       ASLA 
       ASLA 
       ASLA 
       ORAA   #$C0
       STAA   ALAPTR+1       Search this row....
       LDAB    #8           For 8 columns............
HIT2   LDX     ALAPTR 
       LDAA   0,X            Get alien-x 
       BMI     HIT3           Skip if null
       LDAA   GMISX          Get gun missile x-coord. 
       SUBA   0,X            Subtract alien missile x.
       BPL     *+3            Convert to absolute value
       NEGA
       CMPA   #4             Diff <= 4?
       BLE     HIT4           Yes. found the sucker! 
HIT3   INC     ALAPTR+1       No, try next col.
       DECB
       BNE    HIT2
       RTS                    Search failed; forget it
*
* EXTERMINATE HIT ALIEN:
HIT4    LDAA   0,X            Get its x-coord.
        STAA   ALIENX
        LDAA   #$FF
        STAA   0,X            Deposit null code in array.
        JSR     DISAGM         Disable gun missile.
        LDAB   #1
        JSR     PAUSE          Wait  for RTC tick
        JSR     DSBLOT         Blot alien
        LDAB   #3
        JSR     BTONE          Bleep for 60 mSec
        JSR     DSBLOT         Remove blot
        JSR     DSPAL          Remove alien
*
* ADJUST SCORER DIFFICULTY LEVEL, ETC:
HIT5    JSR     ADJUST
        DEC     KALIEN
        BEQ     HIT6
        RTS
*
* ALL ALIENS DEPLETED; END OF ROUND:
HIT6    INC     NOALFG        Set 'aliens depleted' flag
        LDAA   ROUND         Add bonus 2 guns at....
        CMPA   #10           ....end of round 10
        BNE     *+8
        INC     KGUNS
        INC     KGUNS
        JSR     STATUS        Show round, score, guns.
        RTS
* 
*   ALIEN MISSILE MANAGEMENT; MOVE ALIEN MISSILES:
MVAMIS  CLR     LFLAG          Reset 'launch' flag.
        LDX     #MISARR
        LDAB   NMISS          For (N) missiles.........
MVM1    STAB   KMISS 
        STX     MISPTR
        LDAA   0,X            Get missile(I) x-coord.
        STAA   AMISX
        BMI     MVM4           Null; try a launch.
        LDAA   1,X            Get missile(I) Y-coord.
        STAA   AMISY
        CMPA   #$1F           Is it at bottom of screen?
        BEQ     MVM8
MVM2    JSR     DSPALM         Erase from old Pos'n.
        LDX     MISPTR
        INC     AMISY          Show in new pos'n.
        LDAA   AMISY
        STAA   1,X
        JSR     DSPALM
        LDAA   HITFLG         Hit anything?
        BEQ     MVM3           if not.
        JSR     DSTROY         if so: destroy it.
        LDAA   NGFLG          Guns depleted?
        BNE     MVMR           If so, return
MVM3    LDX     MISPTR         )
        INX                    )
        INX                    ) next missile
        LDAB   KMISS          )
        DECB                  )
        BNE     MVM1           )
MVMR    RTS 
*
*   TEST FOR 'CLEAR-TO-LAUNCH' CONDITION:
MVM4    LDAA   LFLAG          Already launched 1 this cycle?
        BNE     MVM3           Yes: next I.
        LDAA   CLOCK1         Launch every 12th control cycle
        BNE     MVM3
        BSR     LAUNCH
        BRA     MVM3           Next missile.
*
*   DE-ACTIVATE ALIEN MISSILE:
MVM8    BSR     KILALM 
        BRA     MVM3
*
KILALM  JSR     DSPALM         Erase it 
KIL1    LDX     MISPTR
        LDAA   #$FF
        STAA   0,X            Store null code.
        STAA   1,X
        RTS
*
* DESTROY OBJECT HIT BY ALIEN MISSILE:
DSTROY  LDAA    GMISX  Check for missile/missile hit
        CMPA    AMISX
        BNE      DST1
        LDAA    GMISY
        CMPA    AMISY
        BNE      DST1         No; try gun
        BSR      KIL1         Yes; kill missiles.
        JSR      DISMIS       Show missiles exploding.
        JSR      DGM1         Disable gun missile.
        RTS

DST1    LDAA    AMISY        Check for gun-turret hit
        CMPA    #$1C
        BGE      KILGUN
        RTS
*
* DESTROY GUN-TURRET;
KILGUN  BSR     KILALM        First remove alien missile
        JSR     DSPCLD        Show 'cloud' on dead gun-turret
        JSR     INVERT        FLASH, ETC
        LDAB   #100
        STAB   TONE
        LDAB   #$40
        JSR     BTON          Make sound
        DEC     KGUNS         Decrement gun count
        BGT     KILG1
        INC     NGFLG         If no guns, set flag.
        RTS
*
KILG1   JSR    STATUS         Show score, pause.
        JSR    ERASE          Clear screen
        JSR    INZMIS         Remove missiles.
        JSR    SHOWAA         Replace aliens
        JSR    DSPGUN         Replace gun
        RTS
*
*   LAUNCH ALIEN MISSILE;  CH0OSE AT RANDOM:
LAUNCH  JSR      RANDOM         Select random col.
        LDAB    #8             For 8 columns............
AML1    PSHB
        ANDA    #7
        STAA    COL
        LDAA    #$20
        LDAB    #5             For 5 rows (max)....,....
AML2    PSHB
        STAA    ROW            Compute pointer from ROW,COL.
        ORAA    COL
        ORAA    #$C0
        STAA    ALAPTR+1
        LDX      ALAPTR
        LDAA    0,X              Fetch alien x (or null)
        BPL      AML3           If not $ff, we have alien to find
        LDAA    ROW            )
        SUBA    #8             )
        PULB                   ) next ROW up...
        DECB                   )
        BNE      AML2
        LDAA    COL
        LDAB    KSHOT          Try next col left or right....
        ANDB    #$01           ...depending on KSHOT! ...
        BEQ      *+4            ...(flgure that one out !!)
        DECA
        DECA
        INCA                   )
        PULB                   )   next column
        DECB                   )
        BNE      AML1           )
        RTS                     Search failed; forget it.
*
AML3    PULB                   Re-adjust stack
        PULB
        ADDA    #2             Missile-x is centre of alien
        STAA    AMISX
        LDX      MISPTR
        STAA    0,X              Store new missile in array
        LDAA    ROW
        LSRA
        LSRA
        LSRA
        TAB                     Mult. A by 5 giving y-coord.
        ASLA
        ASLA
        ABA
        ADDA    #3             ..... + 3
        STAA    AMISY
        STAA    1,X
        JSR      DSPALM         Show alien missile here
        INC      LFLAG          Set 'launch' flag
		RTS
*
* SHOW STATUS --- ROUND, SCORE, GUNS:
STATUS  CLRA             Make display 'window'
        LDX       #DISBUF+192
        JSR       FILL
        COMA
        LDX       #DISBUF+200
        JSR       FILL
        LDAA     #$10      Put gaps in window (3 fields)
        JSR       DSPGAP
        LDAA     #$2C
        JSR       DSPGAP
*
        LDAA    #4
        JSR       CURS1     Set  'invisible cursor' posn
        LDAA    ROUND     Convert ROUND to decimal
        LDX       #DECIM    Point  to workspace
        JSR       DECEQ
        LDX       #DECIM+1
        BSR       DISDIG    Show 'tens'
        INX
        BSR       DISDIG    Show  'units'
        LDAA    #$18      Convert & show SCORE x 10
        JSR       CURS1
        LDAA    SCORE
        LDX       #DECIM
        JSR       DECEQ
        CLRA
        STAA    0,X
        LDX       #DECIM
        LDAB    #4
STAT2   PSHB
        BSR       DISDIG
        INX
        PULB
        DECB
        BNE       STAT2
        LDAA    #$33      Show guns remaining
        JSR       CURS1
        LDX       #KGUNS
        BSR       DISDIG
        LDAA    #$39      Show gun symbol
        STAA    VX
        LDX       #GUN
        LDAB    #4
        JSR       SHOWX
        LDAB    #200      Pause for 4 seconds...
*
* PAUSE:  Wait for the Nth RTC interrupt (N = B-reg):
PAUSE   STAB    TIME 
PSE1    TST       TIME
        BNE       PSE1
        RTS
*
* DISPLAY BCD DIGIT (LSD) OF BYTE 0 X:
DISDIG  LDAA  0,X
        JMP   DIGOUT Use monitor display routine
*
* ADJUST DIFFICULTY LEVEL OF PLAY: 
ADJUST  LDAA SCORE   BUMP score
        CMPA #250   Stop at 250 !
        BEQ   ADJ2
        INC  SCORE
*
* COMPUTE MDELAY = MDMAX - SCORE/(255/(MDMAX-MDMIN))
ADJ2    LDAB  #$28   [ Maximum-Minimum delay ]
        LDAA  #255
        JSR   DIV
        TAB
        LDAA SCORE
        JSR   DIV
        TAB
        LDAA #$40   [ Maximum de1ay ]
        SBA
        STAA MDELAY
*
* COMPUTE DROP RATE; NDROP = (250 - SCORE)/64 + 1:
        LDAA #250
        SUBA SCORE
        LDAB #64
        JSR   DIV
        ADDA #1
        STAA NDROP
*
* COMPUTE NMISS = 2, 3 OR 4; depending on which round:
        LDAA #4
        LDAB ROUND
        CMPB #6
        BGE   ADJ3
        DECA
        CMPB #3
        BGE   ADJ3
        DECA
ADJ3    STAA NMISS
        RTS
*
* DIVIDE A BY B;   8-BITS UNSIGNED; (SLOW);
DIV      CLR     QUOT
         TSTB
         BEQ     DIV2     Dividing by 0 !!!?
DIV1     SBA              Compare A with B.   (A-B)
         BCS     DIV2     Branch if A was LOWER (unsigned)
         INC     QUOT
         BRA     DIV1
DIV2     LDAA   QUOT
         RTS
*
* DISPLAY/ERASE GUN MISSILE:
DSPGM    LDAA   GMISX
         STAA   VX
         LDAA   GMISY
DSPM1    STAA   VY
         LDAB   #1
         LDX     #MISILE
         CLR     HITFLG   Reset  'overlap' flag.
         JMP     SHOWX    Jump to CHIPOS show routine
*
* DISPLAY/ERASE  ALIEN MISILE:
DSPALM   LDAA   AMISX
         STAA   VX
         LDAA   AMISY
         BRA     DSPM1
*
* DISPLAY/ERASE  GUN-TURRET:
DSPGUN   LDAA   GUNPOS
         STAA   VX
         LDAA   #$1C
         STAA   VY
         LDAB   #4
         LDX     #GUN
         JMP     SHOWX
*
* DISPLAY/ERASE ALIEN:
DSPAL    LDAB   #4
         LDAA   ALIENY
         STAA   VY
         LDAA   ALIENX
         STAA   VX
         ANDA   #1       Test for odd or even x coord
         BEQ     DSPAL1
         LDX    #ALIEN2
         JMP     SHOWX    Shcw alien  type I (odd x)
DSPAL1   LDX     #ALIEN1
         JMP     SHOWX    Show alien type 2 (even x)

*  DISPLAY MISSILE/MISSILE COLLISION:
DISMIS   BSR      DISM1     Show fragments
         LDAB    #2

         JSR     PAUSE     Delay 20 - 40 mSec.
DISM1    LDAA   GMISX     Use gun missile coords
         DECA
         STAA  VX
         LDAA  GMISY
         DECA
         STAA  VY
         LDAB  #3
         LDX     #FRAGM
         JMP     SHOWX
*
*  DISPLAY/ERASE 'BLOT' ON DECEASED ALIEN:
DSBLOT   LDAA    ALIENX
         DECA
         STAA    VX
         LDAA    ALIENY
         DECA
         STAA    VY
         LDAB    #6
         LDX       #BLOT
         JMP       SHOWX
*
*  DISPLAY/ERASE 'CLOUD' OVER HIT GUN-TURRET:
DSPCLD   LDAA     GUNPOS
         DECA
         STAA     VX
         LDAA     #$1B
         STAA     VY
         LDAB     #5
         LDX       #CLOUD 
         JMP       SHOWX
*
*  SHOW  GAP IN DISPLAY WINDOW:
DSPGAP    STAA     VX
          LDAA     #$19
          STAA     VY
          LDAB     #7
          LDX       #GAP
          JMP       SHOWX
*
*  INVERT VIDEO,    FULL SCREEN:
INVERT    LDX       #DISBUF
INV1      COM       0,X
          INX
          CPX       #ENDBUF
          BNE       INV1 
          RTS
*
*
* SYMBOL PATTERNS:
MISILE   FCB      $80
GUN      FDB      $2070
         FDB      $F888
		 
ALIEN1   FDB      $F8A8
         FDB      $F850
		 
ALIEN2   FDB      $F8A8
         FDB      $F888
		 
BLOT     FDB      $7CFE
         FDB      $FEFE
         FDB      $FE6C
		 
FRAGM    FDB      $A040
         FCB      $A0
		 
CLOUD    FDB      $387C
         FDB      $FEFE
         FCB      $FE
GAP      FDB      $F0F0
         FDB      $F0F0
         FDB      $F0F0
         FDB      $F0F0
*
*
*
*  CHECKSUM VERIFY ROUTINE:
         ORG      $0700
VERIFY   LDX      #$0200
         CLRA
VER1     LDAB    0,X
         ABA
         INX
         CPX      #$0700
         BNE      VER1
         STAA    $00FF
         JMP      $C360
         END
