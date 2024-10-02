''***************************************************************************
''* Superboard III firmware
''* Copyright (C) 2013 Briel Computers
''*
''* TERMS OF USE: MIT License. See bottom of file.
''***************************************************************************
''
''Revision 0.0 first booted to monitor prompt 3/27/2013 at 1:05AM
''Revision 0.1 fixed ROM pointer so 2K monitor file would work
''Revision 0.2 fixed ROM read so it ignores $F000 and F001 for ACIA seiral port
''Revision 0.3 Begins ACIA code
''Revision 0.4 First prototype board RED with BREAK KEY 3 seconds
''Revision 0.5 Reversed polarity for BREAK, now active if HIGH BLUE PROTOTYPE
''Revision 0.6 Cleaned up code for release
''
''Special thanks to Jac Goudsmit without his help, this would still be a concept
''
''Jac re-wrote the 1 pin driver to emulate the OSI display so that we could have
''enough pins for addressing. He also helped make the memory addressing so I would
''not need to pull the READY signal and hold up the CPU.
''
''The firmware below creates a random access memory map for video RAM and ROM
''that is used to create a system replica of the OSI 600 Superboard II rev b
''
''Using the Propeller eliminates much of the original logic IC's, RAM and ROM
''needed for the system to operate. The idea of this project is to emulate the
''functionality of the original board as close as possible. I choose the rev b
''version to replicate because this is the early version that was available.
''Later revisions of the OSI 600 had higher screen resolution and color.

'' The address bus of the 6502 is connected to a 74x138 which decodes the top
'' 4 bits. The outputs of the 74x138 are connected to three inputs of the Propeller
'' to decode the address as follows:
'' 6502        | pin_VID pin_VA13 pin_VA12 | "Virtual Address" VA13/VA12/A11-A0
'' ------------+---------------------------+-----------------------------------
'' $D000-$DFFF |      0       0        0   |
'' $F000-$FFFF |      1       0        1   | $1000v-$1FFFv
'' $A000-$AFFF |      1       1        0   | $2000v-$2FFFv
'' $B000-$BFFF |      1       1        1   | $3000v-$3FFFv
'' All others  |      1       0        0   | $0000v-$0FFFv




CON
'system clock constants
  _clkmode      = xtal1 + pll16x
  _xinfreq      = 5_000_000
'keyboard constants
  KB1           = 10
  KB2           = 11
'video constants
  tvPin         = 13
'PHI0 constant pin #
  CLK0          = 28                                    ' must use P28, can't use for anything else
  CLK1          = 12                                    ' Clock pin for ACIA clock
  RESET         = 11                                    ' Goes to RESET of 65C02 to control RESET circuit
  BUTTON        = 10                                    ' This will be the BREAK button
  ONE           = 1
  Rx            = 31
  Tx            = 30
  BAUD          = 9600
VAR
  LONG                cursor
OBJ
  tv1:   "1pintv256_32"                                  ' Video driver modified for OSI replica
  tv2:   "1pintv256"                                     ' Video driver 25x25
  font: "OSIfont"                                       ' font to use

PUB main | serialdata, ran, x, i, temp, count, serial

'  serial := (ser.start(rx, tx, 0, baud) > 0)
'  ROMfix := ACIA_DAT
  dira[CLK1]~~                                          ' Set clk2 for serial port timing signal
  ctrb := %00100_000 << 23 + 1 << 9 + CLK1              '
  frqb := $07D_D000                                     ' set to 153.6K for 9600 buad 4.8K=300 BUAD (cassette mode

  'Code for RESET button "BREAK" key
  dira[RESET]~~                                         ' set RESET control signal line P11 as OUTPUT
  dira[BUTTON]~                                         ' set BREAK KEY BUTTON P10 as INPUT
  ran := $FF
  outa[RESET]~~
  temp:= ina[BUTTON]
  if temp > 0
     screenptr :=tv2.Start(tvPin, font.GetPtrToFontTable)' screenptr is memory point to video RAM  sandard 25x25 visible
  else
      screenptr := tv1.Start(tvPin, font.GetPtrToFontTable)
      cursor := screenptr
      'menu                                             ' Menu mode for future expansion of code options on power up BREAK
  ROMoffset := @basicrom - $2000                        ' set ROM pointer to offset for VA12-VA13
  dira[CLK0]~~                                          ' Set CLK0 pin to output for Phase 0 clock
  ctra := %00100_000 << 23 + 1 << 9 + CLK0              ' Calculate frequency setting
  frqa := $333_0000                                     ' Set FRQA so PHSA[31]
  ran := cnt                                            ' Seed random generator from clock counter
  repeat i from 0 to 1023                               ' Do all of video RAM to emulate garbage screen
    byte[screenptr + i] := ?ran                         ' Generate random byte and store it

'add version code to upper left splash screen
  CURSOR := 133
  STR(STRING("0.06"))
  cognew(@vme, 0)                                       ' Start video RAM and ROM driver

  repeat                                                ' This loop checks BREAK key for 3 second hold, if true RESET 65C02
     temp := ina[BUTTON]
     if temp >> 0         ' was == 0
       pause(7)
       count++
       if count >> 200
         !outa[RESET]
         pause (10)
         repeat until ina[BUTTON] >> 0
         !outa[RESET]
         COUNT := 0
     else
       count := 0

'menu is not currently in use but can be added at power up for menu required functions

PRI menu  | i, zest, count

'   ADD OPTION FOR CASSETTE BAUD RATE SPEED IF I GET CASSETTE WORKING

    repeat i from 0 to 1023
      zest := 32
      byte[screenptr+ i] := zest
    repeat until ina
    CURSOR := 200
    STR(STRING("FLASH UPDATE?"))
    CURSOR := 260
    'CURSOR := CURSOR + 47
    STR(STRING("PRESS AND HOLD BREAK = YES"))
    CURSOR := 292
    STR(STRING("SHORT PRESS OF BREAK = NO"))
    CURSOR := 388
    STR(STRING("RELEASE THE BREAK KEY"))
    pause(1000)
    repeat until ina[BUTTON] >> 0
      pause(100)
      CURSOR := 388
      STR(STRING("                     "))
      PAUSE(100)
      CURSOR := 388
      STR(STRING("RELEASE THE BREAK KEY"))
    CURSOR := 388
    STR(STRING("                     "))
    'code here to check BREAK key and exit or flash
    repeat until ina[BUTTON] == 0                       ' sit here until BREAK key pressed
       pause(1)
    count := 0
    repeat until ina[BUTTON] >> 0
       pause(7)
       count++
'    if count >> 200
'       flash
PRI Pause( mS )

  waitcnt( ( clkfreq / 1000 ) * mS + cnt )
PUB out(c)
   byte[screenptr + cursor] := c
   cursor++
PUB str(stringptr)
'' Print a zero-terminated string

  repeat strsize(stringptr)
    out(byte[stringptr++])
PUB dec(value) | i
'' Print a decimal number
  if value < 0
    -value
    out("-")
  i := 1_000_000_000
  repeat 10
    if value => i
      out(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      out("0")
    i /= 10
DAT
        org   0
' This is the driver for Video and ROM read/write
VME                             ' Initialize the ports and begin scanning 65C02 BUS
  mov dira, #0
  mov outa, #0
  jmp #VORLoop                  ' jump to start the loop
' Constants
zero      LONG 0                ' Zero
mask_VID  LONG (|<9)            ' Video memory selected -> Pin 9 active when low
mask_RW   LONG (|<8)            ' R/W is on Pin 8
mask_CLK0 LONG (|<28)           ' Clock output to 6502 is on Pin 28
mask_FF   LONG $FF              ' Bit mask for data bus
mask_3FF  LONG $3FF             ' Bit mask for video address bits
mask_3FFF LONG $3FFF            ' Bit mask for ROM address bits
mask_EUV  LONG $17FF            ' End of Unmapped Virtual Memory ($1000v<=>$F000) ($1000v-$1001v=ACIA)
mask_FFF  LONG $FFF             ' mask to keep 12 bits
mask_C00  LONG $C00
shift     LONG 14               ' shift bit variable to move address bus into position
' Variables
addr      LONG 0                ' Current address
data      LONG 0                ' Data (only lowest 8 bits are significant)

screenptr LONG 0                ' Pointer to video memory
ROMoffset LONG 0                ' ROM pointer setup in spin
serialmem LONG 0
WaitForPhi2
  waitpne zero, mask_CLK0
VORLoop                         ' Begin Video or ROM Loop
  waitpeq zero, mask_CLK0
  andn DIRA, #$FF               ' deactivate outgoing data from previous cycle, if any
  nop                           ' With this loop code, there should be time for a NOP so the 6502 and glue logic can settle
  test mask_RW, INA WC          ' to test for read/write
  mov addr, INA                 ' copy address and other bits after the 6502 and glue logic had some time to set up
  test addr, mask_VID WZ        ' see if video enable line is low mask_VID=(|<9)
  if_z jmp #DoVID               ' yes, 6502 is accessing video memory
  shr addr, shift               ' Shift the address in place so it is A0-VA13 at bit 0-13
  and addr, mask_3FFF          ' Calculate virtual address. mask_3FFF=$3FFF
  if_c cmp mask_EUV, addr wc    ' If reading, test if address is in ROM area of virtual memory. mask_EUV=$1001
  if_nc jmp #WaitForPhi2        ' Not ROM or trying to write to it: nothing to do

  add addr, ROMoffset           ' Add to ROM pointer
  rdbyte data, addr             ' 6502 is always reading here, never writing
  mov OUTA, data                ' Put data on outputs
  mov DIRA, #$FF                ' Activate outputs
  jmp #VORLoop                  ' All done with ROM
DoVID
  shr addr, shift               ' Shift the address in place
  and addr, mask_FFF            ' Remove unwanted bits. mask_FFF=$FFF

  test addr, mask_C00 WZ        ' Test if request is within 1KB video memory area. mask_C00=$C00
  if_nz jmp #WaitForPhi2        ' Memory range outside D000-D3FF is handled by other cog(s)

  add addr, screenptr           ' map to start video buffer
  if_c rdbyte data, addr        ' if 6502 is reading, get data from hub now
  if_c mov OUTA, data           ' put data on outputs
  if_c mov DIRA, #$FF           ' activate outputs
  if_nc mov data, INA           ' if 6502 is writing, get data from 6502 now
  if_nc wrbyte data, addr       ' write data to hub
  jmp #VORLoop                  ' All done with video RAM

'DoACIA
'  jmp #VORLoop

'        org   0
'ACIACODE


'mask1_3FFF LONG $3FFF            ' Bit mask for ROM address bits
'shift1     LONG 14               ' shift bit variable to move address bus into position
'addr1      LONG 0                ' Current address
'data1      LONG 0                ' Data (only lowest 8 bits are significant)
'mask1_RW   LONG (|<8)            ' R/W is on Pin 8
'mask1_CLK0 LONG (|<28)           ' Clock output to 6502 is on Pin 28
'zero1      LONG 0                ' Zero
'mask1_ACIA LONG $1000
'ROMfix     LONG 0
'  mov dira, #0
'  mov outa, #0
'  jmp #ACIALoop                 ' jump to start the loop

'Wait2
'  waitpne zero1, mask1_CLK0
'ACIALoop                        ' Begin ACIA Loop
'  waitpeq zero1, mask1_CLK0
'  andn DIRA, #$FF               ' deactivate outgoing data from previous cycle, if any
'  nop                           ' With this loop code, there should be time for a NOP so the 6502 and glue logic can settle
'  test mask1_RW, INA WC          ' to test for read/write
'  mov addr1, INA                 ' copy address and other bits after the 6502 and glue logic had some time to set up
'  shr addr1, shift1               ' Shift the address in place so it is A0-VA13 at bit 0-13
'  and addr1, mask1_3FFF           ' Calculate virtual address. mask_3FFF=$3FFF
'  test addr1, mask1_ACIA  wz

'  if_z jmp#Wait2
'  add addr1, ROMfix           ' Add to ROM pointer
'  if_c rdbyte data, addr        ' if 6502 is reading, get data from hub now
'  if_c mov data1, #$55


'  if_c mov OUTA, data1           ' put data on outputs
'ACIALoopend
'  jmp #toggle

'  if_c mov DIRA, #$FF           ' activate outputs
  'jmp #ACIALoop
'  if_nc mov data1, INA           ' if 6502 is writing, get data from 6502 now
'  if_nc wrbyte data1, addr1       ' write data to hub


'  jmp #ACIAloop



'ACIA_DAT
'        byte 0,0


'  org 0
'toggle





'  mov dira, mask
'  mov counter, period
'  add counter, cnt
'loop
'  xor outa, mask
'  waitcnt counter, period
'  jmp #loop
' variables
'counter long 0
' constants
'period long 40 ' half a second
' parameters initialized by spin
'mask long (|<31)

romfile
'         File "SYN600.ROM"       ' This file holds the boot monitor program
         File "jhe600.bin"
basicrom
         File "OSIBASIC.ROM"      ' This file holds the entire 8K BASIC
CON
''***************************************************************************
''*
''* Permission is hereby granted, free of charge, to any person obtaining a
''* copy of this software and associated documentation files (the
''* "Software"), to deal in the Software without restriction, including
''* without limitation the rights to use, copy, modify, merge, publish,
''* distribute, sublicense, and/or sell copies of the Software, and to permit
''* persons to whom the Software is furnished to do so, subject to the
''* following conditions:
''*
''* The above copyright notice and this permission notice shall be included
''* in all copies or substantial portions of the Software.
''*
''* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
''* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
''* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
''* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
''* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
''* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
''* THE USE OR OTHER DEALINGS IN THE SOFTWARE.
''***************************************************************************