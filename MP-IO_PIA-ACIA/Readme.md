## MP-IO ACIA and PIA PCA

#### Current PCB Version 1
#### Current PCA Version 2

### Changes to version 1 of the PCA

The values of the pull down resistors of the modem control input signals DCD and CTS (R5,R6) have been decreased to 3k3 from 100k. To rationalise the BOM, the in-line TX and RX resistors (R3,R4) have been changed from 2k7 to 3k3.

The original 100k values are OK for pull downs on CMOS HD63B50's but don't pull the pin down hard enough for NMOS MC6850's. 

I had some unusual communication problems with some NMOS ACIA's I tried. It's possible that the 100k pulldown resistors allowed internal or external noise on the CTS pin to start and stop the receiver mid character. Since most simple serial communication does not handle receiver errors you can't detect that this is happening.

Needless to say the problem disappeared when the resistors were changed.     












