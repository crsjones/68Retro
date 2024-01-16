## MIKBUG PIA
This is the original unchanged from "Engineeering Note 100"
The EEPROM is 8k, minimal address decoding would have aliases from $E000 to $FFFF, I have just copied the code to $FE00 for the vectors.

The MIKBUG mask rom uses the PIA for Bit Banged serial. 

The schematic "MP-C68retro.pdf" shows the simplified connections required for the equivalent MEK6800D1 and SWTPC MP-C serial port. 

CODE: $E000 - $E1FF

Image (for vectors)  at  $FE00 - $FFFF

RAM: $A000 - $A080 (128 bytes)

PIA $8004 - $8007    

### links

http://www.swtpcemu.com/mholley/

http://www.deramp.com/swtpc.com/
