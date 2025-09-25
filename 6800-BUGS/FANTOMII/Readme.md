
## FANTOM II Monitor  6800

Monitor code starts at $FC00
RAM is normally at $EDBE, I have moved it down to $DDBE as the 68retro has 8k banks so #E000 and above must be ROM.
Switch the 'C' RAM bank switch on to enable RAM in the C000-DFFF range.
Switch the 'E' ROM bank switch on to enable ROM in the E000-FFFF range. 

FANTOM II uses an ACIA at $EE08.
Set the I/O page Switch to $EE on the 68retro MP-02.
Use A=A2,B=A3 and C=A4 for 4 memory address decoding on the MP-IO board and use J3-2 to set address for the ACIA to $08.


The ACIA is initialised to 7 bit word length, Even Parity and 2 stop bits. The clock divider is set to divide by 16.

Retrieved from groups.io  ET3400 group files area.


