; Screen Examples, User prompts

;
; "D/C/W/M ?"   <--- OLD
; "D/C/W/M/X"   <--- NEW
;   D)isk                               --- Existing Disk boot routine
;   C)old start                         --- Existing Cold start basic
;   W)arm Start                         --- Existing Warm start basic
;   M)onitor                            --- Existing Monitor
;       L) Load                         --- Load from serial port
;       .) Set ADDR mode  0000 -> FFFF
;       /) Set ADDR mode  00 ---> FF  
;          <Return> to skip to next ADDR
;       G) Start execution at ADDR
;   X)modem
;       R)eceive                        --- Xmodem Recv, First 16 bits is the Start ADDR
;       S)end                           --- Xmodem Send, First 16 bits is the Start ADDR
;       B)asic send/save                --- Is basically Xmodem Send with start set to $0000 --> End of BASIC prog
;
;
;
;   Note: SB3 has the UART CLK @ 153.6k which means a Div-1 Baud rate of 153600
;
; ---------------------------------------------------------------------------
        .setcpu  "6502"
        .segment "CODE"
        .org     $F800
;
;
;
; ---------------------------------------------------------------------------
.include        "./c1p_std.inc"             ; Standard defines
;
;
; ---------------------------------------------------------------------------
.include        "./xmodem.s"                ; The X-Modem code
;
;
;
.include        "./syn600-FC00.s"               ; The old syn600 code + my changes
;
;
