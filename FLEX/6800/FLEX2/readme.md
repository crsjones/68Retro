
### FLEX 2 on the 68retro boards

The CF Card in IDE mode requires 8 I/O addresses so the MP-IO card must be configued as A=A4,B=A5,C=A6 and the MP-S card should be switched to the $8000 I/O PAGE.

The SWTBUG Control Port, 'CTLPOR' ($8004) can be either the equivalent MP-C PIA or the MP-S, the ACIA. Strap either the ACIA or the PIA to position '0' of the I/O port jumper block  on the MP-IO board.

As shown on the Schematic diagram, the CF card Chip Select is connected to the middle pin of position '7' of the I/O port jumper block.

The easiest RAM and ROM configuration is to use an 8k EEPROM and a SRAM that is larger than 64k x 8.
A large SRAM will give FLEX the maximum amount of RAM and provide SWTBUG with RAM at $A000.

### BOOTING FLEX

Use the SWTBUG-BOOT 8k EEPROM Image. When SWTBUG starts with the $ prompt press the D key to boot flex.