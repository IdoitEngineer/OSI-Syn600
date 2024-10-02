; XMODEM/CRC Receiver for the 65C02
;
; By Daryl Rictor & Ross Archer  Aug 2002
;
; 21st century code for 20th century CPUs (tm?)
;
; A simple file transfer program to allow upload from a console device
; to the SBC utilizing the x-modem/CRC transfer protocol.  Requires just
; under 1k of either RAM or ROM, 132DBs of RAM for the receive buffer,
; and 8DBs of zero page RAM for variable storage.
;
;**************************************************************************
; This implementation of XMODEM/CRC does NOT conform strictly to the
; XMODEM protocol standard in that it (1) does not accurately time character
; reception or (2) fall back to the Checksum mode.

; (1) For timing, it uses a crude timing loop to provide approximate
; delays.  These have been calibrated against a 1MHz CPU clock.  I have
; found that CPU clock speed of up to 5MHz also work but may not in
; every case.  Windows HyperTerminal worked quite well at both speeds!
;
; (2) Most modern terminal programs support XMODEM/CRC which can detect a
; wider range of transmission errors so the fallback to the simple checksum
; calculation was not implemented to save space.
;**************************************************************************
;
; Files uploaded via XMODEM-CRC must be
; in .o64 format -- the first twoDBs are the load address in
; little-endian format:
;  FIRST BLOCK
;     offset(0) = lo(load start address),
;     offset(1) = hi(load start address)
;     offset(2) = dataDB (0)
;     offset(n) = dataDB (n-2)
;
; Subsequent blocks
;     offset(n) = dataDB (n)
;
; The TASS assembler and most Commodore 64-based tools generate this
; data format automatically and you can transfer their .obj/.o64 output
; file directly.
;
; The only time you need to do anything special is if you have
; a raw memory image file (say you want to load a data
; table into memory). For XMODEM you'll have to
; "insert" the start addressDBs to the front of the file.
; Otherwise, XMODEM would have no idea where to start putting
; the data.
;
;-------------------------- The Code ----------------------------
;
; zero page variables (adjust these to suit your needs)
;
;
;            .include        "osic1p.inc"
;            .include        "osiscreen.inc"

            .setcpu         "6502"
            .smart          on
            .autoimport     on
            .case           on
            .debuginfo      off
            .importzp       sp, sreg, regsave, regbank
            .importzp       tmp1, tmp2, tmp3, tmp4, ptr1, ptr2, ptr3, ptr4
            .FEATURE        STRING_ESCAPES

            .segment  "STARTUP"
            .segment        "CODE"
            .proc           _main: near

.export     XM_RomStart
.export     clrScreen

.ifdef      _StandAlone_
            .org  $7000                             ; Start of program (adjust to your needs)
.endif            

;
; Variables, Some live in Display RAM to save space (EG The CRC Table)
;
SR_Flag         =       $D093
lastblk         =       $D094           ; flag for last block
blkno           =       $D095           ; block number
errcnt          =       $D096           ; error counter 10 is the limit
bflag           =       $D097           ; block flag

crc             =       $D098           ; CRC lo byte  (two byte variable)
crch            =       $D099           ; CRC hi byte



eofp            =       $D0B5           ; end of file address pointer (2 bytes)
eofph           =       $D0B6           ;  "    "       "       "
debugChar       =       $D0B7

retry           =       $D090           ; retry counter
retryh          =       $D091



;
; Syn600 ROM std variables
zp_bas_tmpStr_1 =       $0065
zp_bas_tmpStr_2 =       $0068
zp_bas_tmpStr_3 =       $006B
zp_bas_tmpStr_4 =       $006E
zp_bas_snglVars =       $007B
zp_bas_arryVars =       $007D
zp_bas_emptyRAM =       $007F
zp_bas_memTop   =       $0085
zp_monLoadFlag  =       $00FB
zp_monLoadByte  =       $00FC
zp_monLoadAddrLo=       $00FE
zp_monLoadAddrHi=       $00FF
;
displayRAM      =       $D000
;

ptr             =       zp_bas_tmpStr_2
ptrh            =       zp_bas_tmpStr_2+1
move_ptr        =       zp_bas_tmpStr_3
move_ptr_h      =       zp_bas_tmpStr_3+1
screen_ptr      =       zp_monLoadByte
;
BAS_SaveAddr    =       $0000
;
;
; Syn600 Rom entry points
pollKBD         =       $FD00
hex2bin         =       $FE93           ; hex2bin - Convert ascii hex to binary
rollAD          =       $FEDA           ; Roll hex digits into 2 bytes of memory target $FC, FD
fetchByte       =       $FEE9           ; Check Fetch flag; Read from TAPE else KEYB

aciaInit        =       $FCA6           ; syn600 ROM Serial Acia Init Routine
aciaPut         =       $FCB1           ; syn600 ROM Serial Acia Send byte (A-Reg) Routine
aciaGetW        =       $FE80           ; syn600 ROM Serial Acia Recv Waits for data

monStart        =       $FE00
disp4bytes      =       $FEAC           ; Display 4 bytes in $FF, FE, FD & FC
dispNybble      =       $FECA           ; Display Nybble - A-Reg Set Y-Reg to zero on entry (Its used as an index)

;
; The ACIA adapter chip
aciaStatus      =       $F000          ; The 6850
aciaData        =       $F001          ; The 6850

;
;
Rbuff           =       $D100           ; temp 132DB receive buffer (In video memory)
;
;
;  tables and constants
;
;
; The crclo & crchi labels are used to point to a lookup table to calculate
; the CRC for the 128DB data blocks.  There are two implementations of these
; tables.  One is to use the tables included (defined towards the end of this
; file) and the other is to build them at run-time.  If building at run-time,
; then these two labels will need to be un-commented and declared in RAM.
;
crclo           =       $D200       ; Two 256DB tables for quick lookup  (In video memory)
crchi           =       $D300       ; (should be page-aligned for speed) (In video memory)
;
;
;
; XMODEM Control Character Constants
SOH     = $01  ; start block
EOT     = $04  ; end of text marker
ACK     = $06  ; good block acknowledged
NAK     = $15  ; bad block acknowledged
CAN     = $18  ; cancel (not standard, not supported)
CR      = $0d  ; carriage return
LF      = $0a  ; line feed
ESC     = $1b  ; ESC to exit

;
;^^^^^^^^^^^^^^^^^^^^^^ Start of Program ^^^^^^^^^^^^^^^^^^^^^^
;
; Xmodem/CRC upload routine
; By Daryl Rictor, July 31, 2002
;
; v0.3  tested good minus CRC
; v0.4  CRC fixed!!! init to $0000 rather than $FFFF as stated
; v0.5  added CRC tables vs. generation at run time
; v 1.0 recode for use with SBC2
; v 1.1 added block 1 masking (block 257 would be corrupted)
;


;
;
XM_RomStart:
            jsr     clrScreen
            jsr     XModemInit
GetOpt:
;           inc     errcnt
            jsr     DispPrompt
            jsr     pollKBD
            cmp     #'S'
            beq     @DoXModemSend
;
@CheckRecv:            
            cmp     #'R'
            beq     XModemRecv
;
@CheckBasSave:            
            cmp     #'B'
            beq     @DoXMBasicSave
            bne     GetOpt
;
@DoXModemSend:            
            jmp     XModemSend
@DoXMBasicSave:            
            jmp     XMBasicSave
XModemRecv:

;
            lda     #'R'
            sta     SR_Flag
;
;            jsr     XModemInit
;            jsr     DispRecv
            jsr     PrintMsg                        ; send prompt and info
;
            lda     #$01
            sta     blkno                           ; set block # to 1
            sta     bflag                           ; set flag to get address from block 1
;
StartCrc:
            lda     #'C'                            ; "C" start with CRC mode
            jsr     aciaPut                         ; send it
            lda     #$FF
            sta     retryh                          ; set loop counter for ~3 sec delay
            lda     #$00
            sta     crc
            sta     crch                            ; init CRC value
            jsr     GetByte                         ; wait for input
            bcs     GotByte                         ; DB received, process it
            bcc     StartCrc                        ; resend "C"
;
StartBlk:
            lda     #$FF                            ;
            sta     retryh                          ; set loop counter for ~3 sec delay
            lda     #$00                            ;
            sta     crc                             ;
            sta     crch                            ; init CRC value
            jsr     GetByte                         ; get firstDB of block
            bcc     StartBlk                        ; timed out, keep waiting...
;
GotByte:
            cmp     #ESC                            ; quitting?
            bne     GotByte1                        ; no
            lda     #$FE                            ; Error code in "A" of desired
            jmp     monStart                        ; YES - do BRK or change to RTS if desired
;
;
;
GotByte1:
            cmp     #SOH                            ; start of block?
            beq     BegBlk                          ; yes
            cmp     #EOT                            ;
            bne     BadCRC                          ; Not SOH or EOT, so flush buffer & send NAK
            jmp     XM_Done                         ; EOT - all done!
;
;
;
BegBlk:
            ldx     #$00
GetBlk:
            lda     #$ff                            ; 3 sec window to receive characters
            sta     retryh                          ;
GetBlk1:
            jsr     GetByte                         ; get next character
            bcc     BadCRC                          ; chr rcv error, flush and send NAK
GetBlk2:
            sta     Rbuff,x                         ; good char, save it in the rcv buffer
            inx                                     ; inc buffer pointer
            cpx     #$84                            ; <01> <FE> <128DBs> <CRCH> <CRCL>
            bne     GetBlk                          ; get 132 characters
            ldx     #$00                            ;
            lda     Rbuff,x                         ; get block # from buffer
            cmp     blkno                           ; compare to expected block #
            beq     GoodBlk1                        ; matched!
            jsr     PrintErr                        ; Unexpected block number - abort
            jsr     Flush                           ; mismatched - flush buffer and then do BRK
            lda     #$FD                            ; put error code in "A" if desired
            jmp     monStart                        ; unexpected block # - fatal error - BRK or RTS
;
;
;
GoodBlk1:
            eor     #$ff                            ; 1's comp of block #
            inx                                     ;
            cmp     Rbuff,x                         ; compare with expected 1's comp of block #
            beq     GoodBlk2                        ; matched!
            jsr     PrintErr                        ; Unexpected block number - abort
            jsr     Flush                           ; mismatched - flush buffer and then do BRK
            lda     #$FC                            ; put error code in "A" if desired
            jmp     monStart                        ; bad 1's comp of block#
;
;
;
GoodBlk2:
            ldy     #$02                            ;
;
XMR_CalcCRC:
            lda     Rbuff,y                         ; calculate the CRC for the 128DBs of data
            jsr     UpdCRC                          ; could inline sub here for speed
            iny                                     ;
            cpy     #$82                            ; 128DBs
            bne     XMR_CalcCRC                     ;
            lda     Rbuff,y                         ; get hi CRC from buffer
            cmp     crch                            ; compare to calculated hi CRC
            bne     BadCRC                          ; bad crc, send NAK
            iny                                     ;
            lda     Rbuff,y                         ; get lo CRC from buffer
            cmp     crc                             ; compare to calculated lo CRC
            beq     GoodCRC                         ; good CRC
;
BadCRC:
            jsr     Flush                           ; flush the input port
            lda     #NAK                            ;
            jsr     aciaPut                         ; send NAK to resend block
            jmp     StartBlk                        ; start over, get the block again
;
GoodCRC:
            ldx     #$02                            ;
            lda     blkno                           ; get the block number
            cmp     #$01                            ; 1st block?
            bne     CopyBlk                         ; no, copy all 128DBs
            lda     bflag                           ; is it really block 1, not block 257, 513 etc.
            beq     CopyBlk                         ; no, copy all 128DBs
;
            lda     Rbuff,x                         ; get target address from 1st 2DBs of blk 1
            sta     ptr                             ; save lo address
            sta     zp_monLoadAddrLo
;
            inx                                     ;
            lda     Rbuff,x                         ; get hi address
            sta     ptrh                            ; save it
            sta     zp_monLoadAddrHi
;
            jsr     UpdateDisplay
;
            lda     ptr
            cmp     #<BAS_SaveAddr
            bne     @Skip
            lda     ptrh
            cmp     #>BAS_SaveAddr
            bne     @Skip
;
            lda     #'B'
            sta     SR_Flag
;
@Skip:
            inx                                     ; point to firstDB of data
            dec     bflag                           ; set the flag so we won't get another address
;
CopyBlk:
            ldy     #$00                            ; set offset to zero
CopyBlk3:
            lda     Rbuff,x                         ; get dataDB from buffer
            sta     (ptr),y                         ; save to target
            inc     ptr                             ; point to next address
            bne     CopyBlk4                        ; did it step over page boundary?
            inc     ptr+1                           ; adjust high address for page crossing
;
CopyBlk4:
            inx                                     ; point to next dataDB
            cpx     #$82                            ; is it the lastDB
            bne     CopyBlk3                        ; no, get the next one
;
IncBlk:
            inc     blkno                           ; done.  Inc the block #
            lda     blkno
            sta     zp_monLoadByte
            jsr     UpdateDisplay
            lda     #ACK                            ; send ACK
            jsr     aciaPut                         ;
            jmp     StartBlk                        ; get next block
;
;
;
XM_Done:
            lda     #ACK                            ; last block, send ACK and exit.
            jsr     aciaPut                         ;
XM_Exit:            
            cld                                                                    ; FF00 D8           .
            ldx     #$28                                                           ; FF01 A2 28        .(
            txs   
;
            jsr     Flush                           ; get leftover characters, if any
            jsr     PrintGood                       ;

            lda     SR_Flag                         ; SR_Flag lives in screen RAM, so grab it before we blow it away!
            jsr     clrScreen                       ; Clear the screen
;
            cmp     #'B'
            beq     BAS_Start
;
MON_Start:
            cmp     #'R'
            beq     PGM_Start
;            
            jmp     monStart
;          
PGM_Start:
            jmp     (zp_monLoadAddrLo)
;            
BAS_Start:
            jmp     $A274
;
halt:       jmp     halt            
;
;
UpdateDisplay:
            txa
            pha
            tya
            pha
            jsr     disp4bytes
            pla
            tay
            pla
            tax

            rts
;
;
;================================================================================
XMBasicSave:
;            cld                                     ; Prep the CPU & Stack
;            ldx     #$28                            ;
;            txs                                     ;
;
            ldy     #$00                            ; Display the Send/Recv Flag
            lda     #'B'                            ; We are Sending
            sta     SR_Flag                         ; It in the display RAM so it just shows up!
;
;            jsr     XModemInit
;
;           Basic Start ADDR
            lda     #<BAS_SaveAddr
            sta     ptr
            sta     zp_monLoadAddrLo
            
            lda     #>BAS_SaveAddr
            sta     ptrh
            sta     zp_monLoadAddrHi
;            
;           Basic End Addr            
            lda     zp_bas_emptyRAM
            sta     eofp
            lda     zp_bas_emptyRAM+1
            sta     eofph
            
            jsr     UpdateDisplay
            jmp     XMSendStart
;
;================================================================================
clrScreen:
        pha
        tya
        pha 
        lda     #$20
        ldy     #$00
;
@Loop:
        sta     displayRAM+$300,y
        sta     displayRAM+$200,y
        sta     displayRAM+$100,y
        sta     displayRAM,y
        iny
        bne     @Loop
;
        pla 
        tay
        pla
        rts
;
;================================================================================
;            .org    $7200
;            .align   256
XModemSend:
;            cld                                 ; Prep the CPU & Stack
;            ldx     #$28                        ;
;            txs                                 ;

            ldy     #$00                        ; Display the Send/Recv Flag
            lda     #'S'                        ; We are Sending
            sta     SR_Flag                     ; It in the display RAM so it just shows up!
;
;            jsr     XModemInit
;            jsr     DispSend
;
;
; Get the start address
            jsr     DispStart
GetStartAddr:
            jsr     GetAddr
            cmp     #CR
            bne     GetStartAddr
;
            lda     zp_monLoadAddrLo
            sta     ptr
            lda     zp_monLoadAddrHi
            sta     ptrh
;
; Get the end address
            jsr     DispEnd
GetEndAddr:
            jsr     GetAddr
            cmp     #CR
            bne     GetEndAddr
;
            lda     zp_monLoadAddrLo
            sta     eofp
            lda     zp_monLoadAddrHi
            sta     eofph
;
;            jsr     DispAddr
XMSendStart:       
            jsr     PrintMsg                                 ; send prompt and info
;
            lda     #$00                                     ;
            sta     errcnt                                   ; error counter set to 0
            sta     lastblk                                  ; set flag to false
            lda     #$01                                     ;
            sta     blkno                                    ; set block # to 1
;
Wait4CRC:
            lda     #$ff                                     ; 3 seconds
            sta     retryh                                   ;

            jsr     GetByte                                  ;
            bcc     Wait4CRC                                 ; wait for something to come in...

            sta     debugChar

            cmp     #'C'                                     ; is it the "C" to start a CRC xfer?
            beq     SetstAddr                                ; yes
            cmp     #ESC                                     ; is it a cancel? <Esc> Key
            bne     Wait4CRC                                 ; No, wait for another character
            jmp     PrtAbort                                 ; Print abort msg and exit
;
;
;
SetstAddr:
            ldy     #$00                                     ; init data block offset to 0
            ldx     #$04                                     ; preload X to Receive buffer
            lda     #$01                                     ; manually load Blk #1
            sta     Rbuff                                    ; into 1st byte
            lda     #$FE                                     ; load 1's comp of block #
            sta     Rbuff+1                                  ; into 2nd byte
            lda     ptr                                      ; load low byte of start address
            sta     Rbuff+2                                  ; into 3rd byte
            lda     ptrh                                     ; load hi byte of start address
            sta     Rbuff+3                                  ; into 4th byte

            jmp     LdBuff1                                  ; jump into buffer load routine
;
LdBuffer:
            lda     blkno
            sta     zp_monLoadByte
            lda     ptr
            sta     zp_monLoadAddrLo
            lda     ptrh
            sta     zp_monLoadAddrHi
            jsr     UpdateDisplay
;
            lda     lastblk                                  ; Was the last block sent?
            beq     LdBuff0                                  ; no, send the next one
            
            jmp     XM_Done
;            
LdBuff0:
            ldx     #$02                                     ; init pointers
            ldy     #$00                                     ;
            inc     blkno                                    ; inc block counter
            lda     blkno                                    ;
            sta     Rbuff                                    ; save in 1st byte of buffer
            eor     #$FF                                     ;
            sta     Rbuff+1                                  ; save 1's comp of blkno next

LdBuff1:
            lda     (ptr),y                                  ; save 128 bytes of data
            sta     Rbuff,x                                  ;
LdBuff2:
            sec                                              ;
            lda     eofp                                     ;
            sbc     ptr                                      ; Are we at the last address?
            bne     LdBuff4                                  ; no, inc pointer and continue
            lda     eofph                                    ;
            sbc     ptrh                                     ;
            bne     LdBuff4                                  ;
            inc     lastblk                                  ; Yes, Set last byte flag
LdBuff3:
            inx                                              ;
            cpx     #$82                                     ; Are we at the end of the 128 byte block?
            beq     XMS_CalcCRC                              ; Yes, calc CRC
            lda     #$00                                     ; Fill rest of 128 bytes with $00
            sta     Rbuff,x                                  ;
            beq     LdBuff3                                  ; Branch always

LdBuff4:
            inc     ptr                                      ; Inc address pointer
            bne     LdBuff5                                  ;
            inc     ptrh                                     ;
LdBuff5:
            inx                                              ;
            cpx     #$82                                     ; last byte in block?
            bne     LdBuff1                                  ; no, get the next
;
XMS_CalcCRC:
            lda     #$00                                     ; yes, calculate the CRC for the 128 bytes
            sta     crc                                      ;
            sta     crch                                     ;
            ldy     #$02                                     ;
@Loop:
            lda     Rbuff,y                                  ;
            jsr     UpdCRC                                   ;
            iny                                              ;
            cpy     #$82                                     ; done yet?
            bne     @Loop                                    ; no, get next
            lda     crch                                     ; save Hi byte of CRC to buffer
            sta     Rbuff,y                                  ;
            iny                                              ;
            lda     crc                                      ; save lo byte of CRC to buffer
            sta     Rbuff,y                                  ;
;
Resend:
            ldx     #$00                                     ;
            lda     #SOH                                     ; Send start block command
            jsr     aciaPut                                  ;
;
SendBlk:
            lda     Rbuff,x                                  ; Send 133 bytes in buffer to the console
            jsr     aciaPut                                  ;
            inx                                              ;
            cpx     #$84                                     ; last byte?
            bne     SendBlk                                  ; no, get next
            lda     #$FF                                     ; yes, set 3 second delay
            sta     retryh                                   ; and
            jsr     GetByte                                  ; Wait for Ack/Nack
            bcc     Seterror                                 ; No chr received after 3 seconds, resend
            cmp     #ACK                                     ; Chr received... is it:
            bne     SendBlk2                                 ; --- UGLY: beq can't reach LdBuffer, it' stoo far away!
            jmp     LdBuffer                                 ; ACK, send next block
SendBlk2:
            cmp     #NAK                                     ;
            beq     Seterror                                 ; NAK, inc errors and resend
            cmp     #ESC                                     ;
            beq     PrtAbort                                 ; Esc pressed to abort
                                                             ; fall through to error counter
Seterror:
            inc     errcnt                                   ; Inc error counter
            lda     errcnt                                   ;
            cmp     #$0A                                     ; are there 10 errors? (Xmodem spec for failure)
            bne     Resend                                   ; no, resend block

PrtAbort:
            jsr     PrintErr
            jmp     XM_Exit
;
;
XModemInit:
            lda     #<displayRAM+$85
            sta     screen_ptr
            lda     #>displayRAM
            sta     screen_ptr+1
;
            lda     #$00
            sta     zp_monLoadFlag
;           
            jsr     aciaInit
            jsr     Flush
            jsr     disp4bytes
;            jsr     DispBlocks
;            jsr     DispAddr
            jsr     MakeCRCTable                             ; Build the CRC tables
            rts

;
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
GetAddr:
            jsr     pollKBD                               ; Get a CHAR from KDB (or TAPE/Serial)
            cmp     #CR                                     ; Return Key?
            beq     @Done
;
            jsr     hex2bin                                 ; Convert Ascii Hex to binary
            ldx     #$02                                    ; ???? Why?
            jsr     rollAD                                  ; Roll the incomming Hybble into the ADDR ptr
            lda     (zp_monLoadAddrLo),y                    ; Grab the data stored at this new addr
            sta     zp_monLoadByte                          ; Store it for display
            jsr     disp4bytes                              ; Display the Addr & Data  "0000  00"
@Done:
            rts
;
;
; Get a char from the ACIA UART with a time out
GetByte:
            lda     #$FF                                    ; wait for chr input and cycle timing loop
            sta     retry                                   ; set low value of timing loop
            sta     retryh
@Loop:
            jsr     aciaGet                                 ; get chr from serial port, don't wait
            bcs     @Done                                   ; got one, so exit
            dec     retry                                   ; no character received, so dec counter
            bne     @Loop                                   ;
            dec     retryh                                  ; dec hiDB of counter
            bne     @Loop                                   ; look for character again
            clc                                             ; if loop times out, CLC, else SEC and return
@Done:
            rts                                             ; with character in "A"
;
;
; Drain any incomming cars from the ACIA UART.
; When chars stop we exit
Flush:
            lda     #$70                                    ; flush receive buffer
            sta     retryh                                  ; flush until empty for ~1 sec.
@Loop:
            jsr     GetByte                                 ; read the port
            bcs     @Loop                                   ; if chr recvd, wait for another
            rts                                             ; else done
;
PrintMsg:
@offset = ( strPrintMsg - stringTable )&$FF
            ldx     #@offset
            jsr     aciaStrOut
            rts

;
;
;
PrintErr:
@offset = ( strErrMsg - stringTable )&$FF
            ldx     #@offset
            jsr     aciaStrOut
            rts
;
;
;
PrintGood:
@offset = ( strGoodMsg - stringTable )&$FF
            ldx     #@offset
            jsr     aciaStrOut
            rts
;
;
.IF 0
DispBlocks:
@offset = ( strBlocks - stringTable )&$FF
            ldx     #@offset
            lda     #$CF
            jsr     screenOut
            rts
;


DispAddr:
@offset = ( strAddr - stringTable )&$FF
            ldx     #@offset
            lda     #$A5
            jsr     screenOut
            rts
.ENDIF
;
DispStart:
@offset = ( strStart - stringTable )&$FF
            ldx     #@offset
            lda     #$A5
            jsr     screenOut
            rts
;
DispEnd:
@offset = ( strEnd - stringTable )&$FF
            ldx     #@offset
            lda     #$A5
            jsr     screenOut
            rts
;
.IF 0  
DispSend:
@offset = ( strXM_Send - stringTable )&$FF      ; Get the string location in the Table
            ldx     #@offset                    ; Save it for screenOut
            lda     #$85                        ; Display @ this offset
            jsr     screenOut                   ; Display the string
            rts

;
DispRecv:
@offset = ( strXM_Recv - stringTable )&$FF
            ldx     #@offset
            lda     #$85
            jsr     screenOut
            rts
.ENDIF          
;
DispPrompt:
@offset = ( strPrompt - stringTable )&$FF
            ldx     #@offset
            lda     #$85
            jsr     screenOut
            rts
;======================================================================
;
screenOut:
            ldy     #$00
            sta     screen_ptr
@Loop:
            lda     stringTable,x
            beq     @Done
            sta     (screen_ptr),y
            inx
            iny
            jmp     @Loop
@Done:
            rts
;
;
;
aciaGet:
            lda     aciaStatus
            lsr     a
            bcc     @Done
            lda     aciaData
@Done:
            rts

;
;
;
aciaStrOut:
@Loop:
            lda     stringTable,x
            beq     @Done
            jsr     aciaPut
            inx
            jmp     @Loop
@Done:
            rts




;
;  CRC subroutines
;
;
UpdCRC:     eor     crc+1                       ; Quick CRC computation with lookup tables
            tax                                 ; updates the twoDBs at crc & crc+1
            lda     crc                         ; with theDB send in the "A" register
            eor     crchi,X
            sta     crc+1
            lda     crclo,X
            sta     crc
            rts
;
; Alternate solution is to build the two lookup tables at run-time.  This might
; be desirable if the program is running from ram to reduce binary upload time.
; The following code generates the data for the lookup tables.  You would need to
; un-comment the variable declarations for crclo & crchi in the Tables and Constants
; section above and call this routine to build the tables before calling the
; "xmodem" routine.
;
MakeCRCTable:
            ldx     #$00
            LDA     #$00
zeroloop:
            sta     crclo,x
            sta     crchi,x
            inx
            bne     zeroloop
            ldx     #$00
fetch:
            txa
            eor     crchi,x
            sta     crchi,x
            ldy     #$08
fetch1:
            asl     crclo,x
            rol     crchi,x
            bcc     fetch2
            lda     crchi,x
            eor     #$10
            sta     crchi,x
            lda     crclo,x
            eor     #$21
            sta     crclo,x
fetch2:
            dey
            bne     fetch1
            inx
            bne     fetch
            rts

;
;
;                .align  256
stringTable:
strPrompt:      .asciiz     "S/R/B"
strPrintMsg:    .asciiz     "XMODEM/CRC\r\n"
strErrMsg:      .asciiz     "Error\r\n"
strGoodMsg:     .byte       EOT,CR,LF,EOT,CR,LF,EOT,CR,LF,CR,LF
                .asciiz     "Good\r\n"
;strXM_Send:     .asciiz     "Send"
;strXM_Recv:     .asciiz     "Recv"
;strBlocks:      .asciiz     "Blocks"
;strAddr:        .asciiz     "Addr "
strStart:       .asciiz     "Start"
strEnd:         .asciiz     "End  "

;
; End of string table
.align 256
.endproc
