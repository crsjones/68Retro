## Hardware debugging ROM programs

A collection of simple ROMs to help solve hardware problems.

Each ROM is 8k, for a AT28C64 EEPROM or you paste the object code into the top of any size ROM.

### HCF 

Halt and Catch Fire  HCF

Executing the HCF opcode on the MC6802 puts the microprocessor into a test mode in which it outputs each address on the address bus until the microprocessor is reset.

If the microprocessor won't enter HCF test mode then it's possible that the data bus may have a problem.

### Start

The start ROM simply loops reading a single address, $E000.

By setting the I/O PAGE switch to $E000 and monitoring the nIO signal (IC7 pin 3 or the SS50 bus) you can see 
the address being selected. 

Switching the I/O PAGE switch to say, $C000, the signal should disappear indicating that the Microprocessor is running the ROM code.

### ACIA-RTS

The ACIA-RTS ROM turns the RTS signal from the ACIA on and off, it can be useful just to see that the ACIA can be programmed before trying to transmit and receive serial data. 

The ACIA is addressed at $E000.

### ACIA-TX
This ROM uses the ACIA to continuously transmits the 'U' character.
The 'U'character (0x55) including the start bit and 1 stop bit produces a square wave output at the selected baud rate.

### ACIA-RLB

The ACIA-RL 'Remote Loopback' transmits back every character received by the ACIA.
