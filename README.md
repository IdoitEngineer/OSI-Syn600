# OSI-Syn600

## OSI Super-board 2/C1P and SB-3 new kernel rom image

What I've done here is to put an X-Modem implementation into the lower 1k of the normal syn600 Kernel image.
It turns out the Super-Board machines never used this lower 1k for anything.
So I grabbed the X-Modem source code courtesy of Daryl Rictor & Ross Archer Cira Aug 2002.

---

## Licences

The X-Modem code is copyright to  Daryl Rictor & Ross Archer

The Propeller spin code copyright belongs to Vince Briel

The Propeller IDE & Tool chain stuff is copyright Parallax Semiconductor

The OSI syn600 code that survives is Ohio Scientific Instrument

The work I did should be considered GPL v3

---

## Description

The New ROM image now has an added **X** option that takes you to the X-Modem addition

From there you can send, receive or save a basic program (Which just dumps everything from hex 0000 to the end of the basic programs as 
defined by the BASIC zero page pointers

The X-Modem code assumes the file is in the o64 format, which is the c64 way of storing a binary.

That is the very first two bytes is both the load address and the start address.

## New D/C/W/M prompt

Will now appear as D/C/W/M/X where X are the new X-Modem routines 

## X  Modem options

S/R/B

### Save

When saving to a file, select the **S** option. The machine will then prompt you for the START address
type that in as you normally would in the monitor but hit **\<enter\>** to complete
The next entry is the END address once again type that in and hit **\<enter\>**
the send option will then wait for the terminal program to start up.

One thing to note: if you are using Tera-Term, you will need to make sure the CRC option is selected... 
You can find the option at the bottom of the x-modem receive page.

### Recieve

Hit **R** to receive a file 

The loader has some special logic so that when it sees an incoming start/load address of $0000 then it assumes a 
BASIC program is being loaded and will jump to the BASIC warm start location,
other wise it will jump to the load address when the upload is finished.

### Basic

The next option is **B** for BASIC... It won't ask you anything as it starts at address $0000 and grabs 
the end of the basic program from BASICs data pointers in the zero page.

## Notes

This project rquires the CC65 compiler you can grab it here https://github.com/cc65/cc65.git

> **git clone https://github.com/cc65/cc65.git** </br>
> 
> Check the CC65 README & build it </br>
> 
> Then add the following to your **.profile** or **.bashrc** file </br>
> 
> **CC65_HOME=/home/\<your user name\>/path/to/cc65** </br>

source the new value </br>

> **source ~/.profile**  or .bashrc </br>

This repo has a copy of the Propeller IDE and spin code as developed by Vince Briel
This is so the update can easily be applied to the SuperBoard-3 machines. 

The **old** section of the syn600 ROM was disassembled via da65 and annotated by me.
This process was to re-assemble and check the resulting binary for any differences.
I made a **few** changes here and there, but most of the entry points should be the same



## Other changes

## IRQ

The IRQ handler has changed. The **old** ROM code would jump directly to 

> NMI = stack+\$30</br>
> 
> IRQ = stack+\$C0</br>

The **new** ROM code uses some ZP addresses as vectors, and by default will jump to the old NMI/IRQ locations. 
There is a IRQ/NMI stub that just does an **rti** available which you can use, if you don't have anything that relies on the OLD IRQ/NMI vectors.

The new stub routine currently lives at $FCDB

IRQ/NMI Zero Page Vectors
> IRQ = \$D8,\$D9 ---> stack+\$C0</br>
> 
> NMI = \$DA,\$DB ---> stack+\$30</br>


## Screen

I've also taken the liberty of changing the default screen resolution to 32x32; As I was finding it a pain to always switch it. 
The old hold the **\<break\>** key down on power up will give you the old 24x24 screen again. 

## Stand alone X-Modem

Also in the repo there is a stand-alone X-Modem c1p file which currently loads at hex 7000, so if you want to use that you will 
need a 32k machine.

You can however easily rebuild the C1P file by modifying the build script from in the same directory and specify your own load address
The same build bash script will also generate the new ROM image for you

## Special thanks

Vince Briel without whom the SuperBoard-3 would never exit

Daryl Rictor & Ross Archer for the X-Modem 6502 code
