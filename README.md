# OSI-Syn600

## OSI Super board 3 new kernel rom image

What I've done here is to put an X-Modem implementation into the lower 1k of the normal syn600 Kernel image
It turns out the Super-Board machines never used this lower 1k for anything
So I grabbed the X-Modem source code courtesy of Daryl Rictor & Ross Archer Cira Aug 2002

The New ROM image now has an added **X** option that takes you to the X-Modem addition

From there you can send, receive or save a basic program (Which just dumps everything from hex 0000 to the end of the basic programs as 
defined by the BASIC zero page pointers

The X-Modem code assumes the file is in the o64 format, which is the c64 way of storing a binary
That is the very first two bytes is both the load address and the start address

## New D/C/W/M prompt

Will now appear as D/C/W/M/X where X are the new X-Modem routines 

## X  Modem options

S/R/B

### Save

When saving to a file, select the **S** option. The machine will then prompt you for the START address
type that in as you normally would in the monitor but hit **\<enter\>** to complete
The next entry is the END address once again type that in and hit **\<enter\>**
the send option will then wait for the terminal program to start up

One thing to note: if you are using Tera-Term, you will need to make sure the CRC is selected... 
You can find the option at the bottom of the x-modem receive page

### Recieve

Hit **R** to receive a file 
The loader has some special logic so that when it sees an incoming start/load address of $0000 then it assumes a 
BASIC program is being loaded and will jump to the basic warm start location.

> Note:  I've had issues with the BASIC interpreter having a bit of a hissy fit with the newly loaded program
> 
> >       Run the following after the OK prompt  
> >       PRINT FRE(1)
> >       It will barf the first time, but run OK the second; BASIC programs usually work fine after that

other wise it will jump to the load address when the upload is finished

### Basic

The next option is **B** for BASIC... It won't ask you anything as it starts at address $0000 and grabs 
the end of the basic program from BASICs data pointers in the zero page

## Notes

This project rquires the CC65 compiler you can grab it here https://github.com/cc65/cc65.git

**git clone https://github.com/cc65/cc65.git**

Then add the following to your **.profile** or **.bashrc** file

**CC65_HOME=/home/\<your user name\>/path/to/cc65**

source the new value

**source ~/.profile**  or .bashrc

This repo has a copy of the Propeller IDE and spin code as developed by Vince Briel
This is so the update can easily be applied to the SuperBoard-3 machines. 

This new ROM should work in an original SuperBoard-2. The baud rates are clocked on those machines to be set at 300 Baud
But you can "poke" a new multiplier into the UART at \$F000, the divide by one Hex is \$10 which should give you 4800 baud (I think)
From the **Monitor**

* **.**               <--- to get to ADDR mode
* **F000**        <--- Address of the UART
* **/**               <--- Switch to DATA mode
* **10**            <--- The new divisor value for the UART
* .               <--- Back to ADDR mode


The **old** section of the syn600 ROM was disasembled via da65 and annotated by me.
This process was to re-assemble and check the resulting binary for any differences.
I made a **few** changes here, but most of the entry points should be the same


## Other changes

I've also taken the liberty of changing the default screen resolution to 32x32, as I was finding it a pain to always switch it
The old hold **\<break\>** key down on power up will give you the old 24x24 screen again
also in the repo there is a stand-alone X-Modem dot c1p file which currently loads at hex 7000, so if you want to use that you will need a 32k machine

You can however easily rebuild the C1P file by modifying the build script from in the same directory and specify your own load address
The build bash script will also generate the new ROM image for you

##  Special thanks

Vince Briel without whom the SuperBoard-3 would never exit
Daryl Rictor & Ross Archer for the X-Modem 6502 code
