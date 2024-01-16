;     Nam Prom Monitor
; edited Herb Johnson July 2020 from deramp.com file
;**
;**altair 680b Prom Monitor
;**acia Version 1.0
;**
Mivec       Equ   $100
Nmivec      Equ   $104
Straps      Equ   $f002
Noterm      Equ   $0000
Aciacs      Equ   $f000
Aciada      Equ   $f001
;**
;**monitor Stack And Flags
;**
      Org $f1
Stack       Rmb 1       ;bottom Of Monitor's Stack
Brkadr      Rmb 1       ;breakpoint Address Flag
Echo        Rmb 1       ;tty Echo Flag
Extflg      Rmb 1       ;entended Character Flag
Bufull      Rmb 1       ;buffer Full Flag
Savstk      Rmb 2       ;temp For Stack Pointer
Temp        Rmb 1       ;temporary Storage
Bytect      Rmb 1       ;byte Count
Xhi         Rmb 1       ;xreg High
Xlow        Rmb 1       ;xreg Low
Shift       Rmb 1       ;baudot Shift Flag
Savex       Rmb 2       ;temp For Index Rg
Buffer      Rmb 1       ;baudot Character Flag
;**
;* Start Of Prom
;**
      Org $ff00
;**
;* Input One Char Into A-register
;* Echo Character If Bit 7 Of Echo Flag Is Clear
;**
Inch  Bsr   Polcat      ;acia Statuc To A Reg
      Bcc   Inch        ;receive Not Ready
      LdaB #$7f     ;mask For Parity Removal
      CmpB  Echo     ;check Echo Flag
      AndB  Aciada   ;get Character
      Bcc   Outch       ;echo
      Rts               ;no Echo
;**
;* The Following Nop Lines Lines Up The Entry
;* Points To Polcat In The Two Versions
;* Of The Monitor
;**
      Nop
;**
;* Input One Hex Digit Into B Reg
;* Return To Calling Program If
;* Character Received Is A Hex
;* Digit. If Not Hex, Go To Crlf
;**
Inhex Bsr   Inch        ;get A Character
      SubB  #'0'
      Bmi   C1          ;not Hex
      CmpB  #$09
      Ble   In1hg       ;not Hex
      CmpB  #$11
      Bmi   C1          ;not Hex 
      CmpB  #$16
      Bgt   C1          ;not Hex
      SubB  #$07     ;it's A Letter-get Bcd
In1hg Rts               ;return
;**
;* Pole For Character
;* Sets Carry If Character Is In Buffer
;* Clobbers 8 Reg
;**
Polcat LdaB  Aciacs   ;acia Status T0 B
      Asrb              ;rotate Rdrf Bit Into Carry
      Rts               ;return
;**
;* Load Paper Tape
;* Load Only S1 Type Records 
;* Terminate On S9 Or Checksum Error
;**
Load  Bsr   Inch        ;read Frame
      SubB  #'S'
      Bne   Load        ;first Char Not (s)
      Bsr   Inch        ;read Frame
      CmpB  #'9'
      Beq   C1          ;s9 End Of File
      CmpB  #'1'
      Bne   Load        ;second Char Not (1)
      ClrA           ;zero The Checksum
      Bsr   Byte        ;read Byte
      SubB  #$02
      StaB  Bytect   ;byte Count
      Bsr   Baddr       ;get Address Of Block
Load11 Bsr  Byte        ;get Data Byte
      Dec   Bytect      ;decrement Byte Count
      Beq   Load15      ;done With This Block
      StaB  0,X         ;store Data
      Inx               ;bump Pointer
      Bra   Load11      ;go Back For More
Load15 IncA           ;increment Checksum
Lload Beq   Load        ;all Ok - It's Zero
C1    Bra   Crlf        ;checksum Error - Quit
;**
;* Read Byte (2 Hex Digits)
;* Into B Reg
;* A Is Used For Paper Tape Checksum
;**
Byte  Bsr   Inhex       ;get First Hex Dig
      AslB              ;get Shift To High Order 4 Bits
      AslB
      AslB
      AslB
      Aba               ;add To Cheksum
      StaB  Temp     ;store Digit
      Bsr   Inhex       ;get 2nd Hex Dig
      Aba               ;add To Checksum
      AddB  Temp     ;combine Digits To Get Byte
      Rts               ;return
;**
;* Read 16 Bit Address Into X
;* Store Same Address In Xhi & Xlo
;* Clobbers B Reg
;**
Baddr Bsr   Byte        ;get High Order Address
      StaB  Xhi      ;store It
      Bsr   Byte        ;get Low Order Address
      StaB  Xlow     ;store It
      Ldx   Xhi         ;load X With Address Built
      Rts               ;return
;**
;* Print Byte In A Reg
;* Clobbers B Reg
;**
Out2h Tab               ;copy Byte To B
      LsrB           ;shift To Right
      LsrB
      LsrB
      LsrB
      Bsr   Outhr       ;output First Digit
      Tab               ;byte Into B Again
Outhr AndB #$0f     ;get Rid Of Left Dig
      AddB #$30     ;get Ascii
      CmpB #$39
      Bls   Outch
      AddB #$07     ;if It's A Letter Add 7
      Nop               ;line Up Outch Entry Points
      Nop
Outch Fcb   $8c         ;use Cpx Skip Trick
Outs  LdaB #$20     ;outs Prints A Space
;**
;* Outch Outputs Character In B
;**
      PshB              ;save Char
Outc1 Bsr   Polcat      ;acia Status To B Reg
      AsrB
      Bcc   Outc1       ;xmit Not Ready
      PulB              ;char Back To B Reg
      StaB  Aciada   ;output Character
      Rts
;**
;* Examine And Deposit Next
;* Uses Contents Of Xhi & Xlo As Pointer
;**
Nchang Ldx  Xhi         ;increment Pointer
      Inx
      Stx   Xhi
      LdaA  Xhi
      Bsr   Out2h       ;print Out Address
      LdaA  Xlow
      Bsr   Out2h
      Fcb   $8c         ;use Cpx Skip Trick
;**
;* Examine & Deposit
;**
Change Bsr  Baddr       ;build Address
      Bsr   Outs        ;print Space
      LdaA  0,X     ;byte Into A
      Bsr   Out2h       ;print Byte
      Bsr   Outs        ;print Space
      Bsr   Byte        ;get New Byte
      StaB  0,X     ;store New Byte
;**
;* Command Decoding Section
;**
Crlf  Lds   Savstk
      LdaB  #$0d     ;carriage Return
      Bsr   Outch
      LdaB  #$0a     ;line Feed
      Bsr   Outch
      LdaB  #'.'     ;prompt Character
      Bsr   Outch
      Jsr   Inch        ;read Character
      Tba               ;make A Copy
      Bsr   Outs        ;print Space
      CmpA  #'L'
      Beq   Lload       ;load Paper Tape
      CmpA  #'J'
      Bne   Notj
      Bsr   Baddr       ;get Address To Jump To
      Jmp   0,X        ;jump To It
Notj  CmpA  #'M'
      Beq   Change      ;examine & Deposit
      CmpA  #'N'
      Beq   Nchang      ;e & D Next
      CmpA  #'P'
      Bne   Crlf
      Rti               ;procede From Breakpoint
;**
;* Reset Entry Point
;**
Reset Lds   #Echo       ;initialize Stack Pointer
      LdaB  #$03     ;init Echo And Brkadr Flags
      PshB
      PshB
      StaB  Aciacs   ;master Reset Acia
      LdaB  Straps   ;look At Straps
      Bmi   Noterm      ;no Term - Jump To 0
      AndB  #$04     ;get # Of Stop Bits
      OraB  #$d1
      StaB  Aciacs   ;init Acia Port
;**
;* Software Interrupt Entry Point
;**
Intrpt Sts  Savstk      ;save Stack Pointer
      Sts   Xhi         ;save Sp For N Command
      LdaB  Brkadr   ;if Bit 7 Of Brkadr Is Set
      Bmi   Noterm      ;jump To 0
      Bra   Crlf        ;goto Command Decoder
;**
;* Now Come The Interrupt Vectors
;**
      Org   $fff8
      Fdb   Mivec       ;mi Vector
      Fdb   Intrpt      ;swi Vector
      Fdb   Nmivec      ;nmi Vector
      Fdb   Reset       ;reset Vector
      End
