; Screen Examples, User prompts
;
; Load/Save
; Start         | End           | Move          | Examine
; 0000 00       | 0000 00       | 0000 00       | 0000 00
;
; D/C/W/M  <--- OLD
;   D)isk                               --- Existing Disk boot routine
;   C)old start                         --- Existing Cold start basic
;   W)arm Start                         --- Existing Warm start basic
;   M)onitor                            --- Existing Monitor
;       L) Load                         --- Load from serial port
;       .) Set ADDR mode  0000 -> FFFF
;       /) Set ADDR mode  00 --> FF  <Return> to skip to next ADDR
;       G) Start at ADDR
;   X)modem <--- NEW
;       R)eceive                        --- Xmodem Recv, First 16 bits is the Start ADDR
;       S)end                           --- Xmodem Send, First 16 bits is the Start ADDR
;       B)asic send/save                --- Is basically Xmodem Send with start set to $0000 --> $3FFF (We need a better Idea here)
;
;
;
; ?????????????
;     M)ove                             --- Move a block of data
;     E)xamine                          --- Hex dump addr
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
.include        "./c1p_std.inc"
;
;
; ---------------------------------------------------------------------------
.include        "./xmodem.s"
;
;
;
.include        "./jhe-c1p.s"
;
;
