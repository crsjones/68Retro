## 6x09 Hardware debugging ROM programs

A collection of simple ROMs to help solve hardware problems with the MP-09 6809/6309 processor board.

Each ROM is 8k, for a AT28C64 EEPROM or you can paste the object code into the top of any size ROM.



### Start

The start ROM simply loops reading a single address, $E000.

By setting the I/O PAGE switch to $E000 and monitoring the nIO signal (IC7 pin 3 or the SS50 bus) you can see the address being selected. 

Switching the I/O PAGE switch to say, $C000, the signal should disappear indicating that the Microprocessor is running the ROM code.
