# MP-IO ACIA and PIA PCA

* Current PCB Version 2
* Current PCA Version 3

### MP-IO PCA Version 1
Initial Issue.  

PCB version 1

### MP-IO PCA Version 2
PCB version 1  

The values of the pull down resistors of the modem control input signals DCD and CTS (R5,R6) have been decreased to 3k3 from 100k. To rationalise the BOM, the in-line TX and RX resistors (R3,R4) have been changed from 2k7 to 3k3.

The original 100k values are OK for pull downs on CMOS HD63B50's but don't pull the pin down hard enough for NMOS MC6850's. 

I had some unusual communication problems with some NMOS ACIA's I tried. It's possible that the 100k pulldown resistors allowed internal or external noise on the CTS pin to start and stop the receiver mid character. Since most simple serial communication does not handle receiver errors you can't detect that this is happening.
Needless to say the problems disappeared when the resistors were changed.

### MP-IO PCA Version 3
PCB version 2  

* Added a jumper for  MC6809 /FIRQ or /IRQ selection for the ACIA.
* Added two jumpers to include the A7 address line in I/O selection. 
* Added additional holes to the PWR SEL jumper for more power switching options.
* Changed the mounting holes.









