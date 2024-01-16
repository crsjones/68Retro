
## SWTBUG 'SWATBUG'

SWTBUG is the SWTPC replacement for Motorola's Mask ROM MIKBUG. 

The SWTBUG monitor can use either the PIA bit-banged serial or an ACIA at the Control Port Address, it figures out which one is attached.

CODE: $E000 - $E3FF (1k)

Image (for vectors)  at  $FE00 - $FFFF

RAM: $A000 - $A080 (128 bytes)

Control Port: 'CTLPOR'   PIA/ACIA  $8004 - $8007    

Comms parameters: 8 bits, no parity ,2 stop

ACIA can do 9600 Baud, PIA just 300 Baud.

### links

http://www.swtpcemu.com/mholley/

http://www.deramp.com/swtpc.com/


