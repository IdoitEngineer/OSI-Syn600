;
        .org $FC00
;        *=     $FC00
;
; ----------------------------------------------------------------------------
; Start of the SYN-600 ROM
romStart:

; ----------------------------------------------------------------------------
; When you type D you do the Disk boot and end up here
dskBoot:
        jsr     dskInit                                                        ; FC00 20 0C FC      ..
        jmp     (zp_monLoadTmp)                                                ; FC03 6C FD 00     l..

; ----------------------------------------------------------------------------
        jsr     dskInit                                                        ; FC06 20 0C FC      ..
        jmp     monStart                                                       ; FC09 4C 00 FE     L..

; ----------------------------------------------------------------------------
dskInit:                                ;
        ldy     #$00                    ; b0000 0000 - Disable all             ; FC0C A0 00        ..
        sty     floppy_piaCRA                                                  ; FC0E 8C 01 C0     ...
        sty     floppy_piaDRA                                                  ; FC11 8C 00 C0     ...
        ldx     #$04                    ; b0000 0100 - Watch CA2 state         ; FC14 A2 04        ..
        stx     floppy_piaCRA                                                  ; FC16 8E 01 C0     ...
        sty     floppy_piaCRB                                                  ; FC19 8C 03 C0     ...
        dey                                                                    ; FC1C 88           .
        sty     floppy_piaDRB                                                  ; FC1D 8C 02 C0     ...
        stx     floppy_piaCRB                                                  ; FC20 8E 03 C0     ...
        sty     floppy_piaDRB                                                  ; FC23 8C 02 C0     ...
        lda     #$FB                                                           ; FC26 A9 FB        ..
        bne     dskSeekTrk                                                     ; FC28 D0 09        ..
dskSeekTrk_0:
        lda     #$02                    ; b0000 0010                           ; FC2A A9 02        ..
        bit     floppy_piaDRA                                                  ; FC2C 2C 00 C0     ,..
        beq     dskSetDrive                                                    ; FC2F F0 1C        ..
        lda     #$FF                    ; b1111 1111                           ; FC31 A9 FF        ..
dskSeekTrk:
        sta     floppy_piaDRB           ; b1111 1111 - set to all output       ; FC33 8D 02 C0     ...
        jsr     dskExitRtn                                                     ; FC36 20 A5 FC      ..
        and     #$F7                    ; b1111 0111                           ; FC39 29 F7        ).
        sta     floppy_piaDRB           ; b1111 0111 - Set bit 3 INPUT         ; FC3B 8D 02 C0     ...
        jsr     dskExitRtn                                                     ; FC3E 20 A5 FC      ..
        ora     #$08                    ; b0000 1000                           ; FC41 09 08        ..
        sta     floppy_piaDRB           ; b1111 1111 - Set bit 3 back OUTPUT   ; FC43 8D 02 C0     ...
        ldx     #$18                                                           ; FC46 A2 18        ..
        jsr     dskDelay                                                       ; FC48 20 91 FC      ..
        beq     dskSeekTrk_0                                                   ; FC4B F0 DD        ..
dskSetDrive:
        ldx     #$7F                    ; b0111 1111                           ; FC4D A2 7F        ..
        stx     floppy_piaDRB           ; b0111 1111 - Set bit 7 INPUT         ; FC4F 8E 02 C0     ...
        jsr     dskDelay                                                       ; FC52 20 91 FC      ..
dskWaitIndex:
        lda     floppy_piaDRA                                                  ; FC55 AD 00 C0     ...
        bmi     dskWaitIndex                                                   ; FC58 30 FB        0.
dskWaitReady:
        lda     floppy_piaDRA                                                  ; FC5A AD 00 C0     ...
        bpl     dskWaitReady                                                   ; FC5D 10 FB        ..
        lda     #$03                    ; b0000 0011 - Master Reset            ; FC5F A9 03        ..
        sta     floppy_aciaStatus                                              ; FC61 8D 10 C0     ...
        lda     #$58                    ; b0101 1000 - RTS,!IRQ,8n2,div-1      ; FC64 A9 58        .X
        sta     floppy_aciaStatus                                              ; FC66 8D 10 C0     ...
        jsr     dskWaitData                                                    ; FC69 20 9C FC      ..
        sta     zp_monLoadAddrLo                                               ; FC6C 85 FE        ..
        tax                                                                    ; FC6E AA           .
        jsr     dskWaitData                                                    ; FC6F 20 9C FC      ..
        sta     zp_monLoadTmp                                                  ; FC72 85 FD        ..
        jsr     dskWaitData                                                    ; FC74 20 9C FC      ..
        sta     zp_monLoadAddrHi                                               ; FC77 85 FF        ..
        ldy     #$00                                                           ; FC79 A0 00        ..
dskReadSector:
        jsr     dskWaitData                                                    ; FC7B 20 9C FC      ..
        sta     (zp_monLoadTmp),y                                              ; FC7E 91 FD        ..
        iny                                                                    ; FC80 C8           .
        bne     dskReadSector                                                  ; FC81 D0 F8        ..
        inc     zp_monLoadAddrLo                                               ; FC83 E6 FE        ..
        dec     zp_monLoadAddrHi                                               ; FC85 C6 FF        ..
        bne     dskReadSector                                                  ; FC87 D0 F2        ..
        stx     zp_monLoadAddrLo                                               ; FC89 86 FE        ..
        lda     #$FF                    ; b1111 1111 - Set Bit 7 INPUT         ; FC8B A9 FF        ..
        sta     floppy_piaDRB                                                  ; FC8D 8D 02 C0     ...
        rts                                                                    ; FC90 60           `

; ----------------------------------------------------------------------------
dskDelay:
        ldy     #$F8                                                           ; FC91 A0 F8        ..
dskDelayLoopEOR:
        dey                                                                    ; FC93 88           .
        bne     dskDelayLoopEOR                                                ; FC94 D0 FD        ..
        eor     zp_monLoadAddrHi,x                                             ; FC96 55 FF        U.
        dex                                                                    ; FC98 CA           .
        bne     dskDelay                                                       ; FC99 D0 F6        ..
        rts                                                                    ; FC9B 60           `

; ----------------------------------------------------------------------------
dskWaitData:
        lda     floppy_aciaStatus                                              ; FC9C AD 10 C0     ...
        lsr     a                                                              ; FC9F 4A           J
        bcc     dskWaitData                                                    ; FCA0 90 FA        ..
        lda     floppy_aciaData                                                ; FCA2 AD 11 C0     ...
dskExitRtn:
        rts                                                                    ; FCA5 60           `

; ----------------------------------------------------------------------------
; Init the ACIA
aciaInit:
        lda     #$03                    ; b0000 0011 - Master Reset            ; FCA6 A9 03        ..
        sta     aciaStatus                                                     ; FCA8 8D 00 F0     ...
        lda     #$11                    ; b0001 0001 - !RTS,!IRQ,8n2,Div-16    ; FCAB A9 11        ..
;        lda     #$10                    ; b0001 0001 - !RTS,!IRQ,8n2,Div-1     ; FCAB A9 11        ..
        sta     aciaStatus                                                     ; FCAD 8D 00 F0     ...
        rts                                                                    ; FCB0 60           `

; ----------------------------------------------------------------------------
; Send char to the ACIA
aciaPut:
        pha                                                                    ; FCB1 48           H
aciaPut_wait:
        lda     aciaStatus                                                     ; FCB2 AD 00 F0     ...
        lsr     a                                                              ; FCB5 4A           J
        lsr     a                                                              ; FCB6 4A           J
        bcc     aciaPut_wait                                                   ; FCB7 90 F9        ..
        pla                                                                    ; FCB9 68           h
        sta     aciaData                                                       ; FCBA 8D 01 F0     ...
        rts                                                                    ; FCBD 60           `

; ----------------------------------------------------------------------------
; Strobe the KEYB column port
kbdStrobe:
        eor     #$FF                    ; b1111 1111                           ; FCBE 49 FF        I.
        sta     kbdPort                                                        ; FCC0 8D 00 DF     ...
        eor     #$FF                    ; b1111 1111                           ; FCC3 49 FF        I.
        rts                                                                    ; FCC5 60           `

; ----------------------------------------------------------------------------
; Read the KEYB row from port
kbdGet:
        pha                                                                    ; FCC6 48           H
        jsr     kbdGetRaw                                                      ; FCC7 20 CF FC      ..
        tax                                                                    ; FCCA AA           .
        pla                                                                    ; FCCB 68           h
        dex                                                                    ; FCCC CA           .
        inx                                                                    ; FCCD E8           .
        rts                                                                    ; FCCE 60           `

; ----------------------------------------------------------------------------
; Read the KEYB row from port
kbdGetRaw:
        lda     kbdPort                                                        ; FCCF AD 00 DF     ...
        eor     #$FF                    ; b1111 1111                           ; FCD2 49 FF        I.
        rts                                                                    ; FCD4 60           `

; ----------------------------------------------------------------------------
irqJump:
        jmp     (zp_irq_vec)                                                   ; FCD5
;
nmiJump:
        jmp     (zp_nmi_vec)                                                   ; FCD8
;
intrStub:
        rti
;
initIrqNmi:
.if     _OLD_IRQ_BEHAVIOUR_ > 0
; NMI
        lda     #<(stack+$30)
        sta     zp_nmi_vec
        lda     #>(stack+$31)
        sta     zp_nmi_vec+1
; IRQ
        lda     #<(stack+$C0)
        sta     zp_irq_vec
        lda     #>(stack+$C1)
        sta     zp_irq_vec+1
.else
        lda     #<intrStub
        sta     zp_irq_vec
        sta     zp_nmi_vec
        lda     #>intrStub
        sta     zp_irq_vec+1
        sta     zp_nmi_vec+1
.endif
;
        rts
;
        .res    $FD00-*, $FF
;
; ----------------------------------------------------------------------------
; Keyboard poll routine
pollKBD:
        txa                                                                    ; FD00 8A           .
        pha                                                                    ; FD01 48           H
        tya                                                                    ; FD02 98           .
        pha                                                                    ; FD03 48           H
pollKBD_firstRow:
        lda     #$01                                                           ; FD04 A9 01        ..
pollKBD_readKey:
        jsr     kbdStrobe                                                      ; FD06 20 BE FC      ..
        jsr     kbdGet                                                         ; FD09 20 C6 FC      ..
        bne     pollKBD_checkEnd                                               ; FD0C D0 05        ..
pollKBD_nextRow:
        asl     a                                                              ; FD0E 0A           .
        bne     pollKBD_readKey                                                ; FD0F D0 F5        ..
        beq     pollKBD_noKey                                                  ; FD11 F0 53        .S
pollKBD_checkEnd:
        lsr     a                                                              ; FD13 4A           J
        bcc     pollKBD_decode                                                 ; FD14 90 09        ..
        rol     a                                                              ; FD16 2A           *
        cpx     #$21                                                           ; FD17 E0 21        .!
        bne     pollKBD_nextRow                                                ; FD19 D0 F3        ..
        lda     #$1B                                                           ; FD1B A9 1B        ..
        bne     pollKBD_decodeDone                                             ; FD1D D0 21        .!
pollKBD_decode:
        jsr     pollKBD_getColumn                                              ; FD1F 20 C8 FD      ..
        tya                                                                    ; FD22 98           .
        sta     wa_kbdTMP1                                                     ; FD23 8D 13 02     ...
        asl     a                                                              ; FD26 0A           .
        asl     a                                                              ; FD27 0A           .
        asl     a                                                              ; FD28 0A           .
        sec                                                                    ; FD29 38           8
        sbc     wa_kbdTMP1                                                     ; FD2A ED 13 02     ...
        sta     wa_kbdTMP1                                                     ; FD2D 8D 13 02     ...
        txa                                                                    ; FD30 8A           .
        lsr     a                                                              ; FD31 4A           J
        jsr     pollKBD_getColumn                                              ; FD32 20 C8 FD      ..
        bne     pollKBD_noKey                                                  ; FD35 D0 2F        ./
        clc                                                                    ; FD37 18           .
        tya                                                                    ; FD38 98           .
        adc     wa_kbdTMP1                                                     ; FD39 6D 13 02     m..
        tay                                                                    ; FD3C A8           .
        lda     validKeysR0,y                                                  ; FD3D B9 CF FD     ...
pollKBD_decodeDone:
        cmp     wa_kbdTMP3                                                     ; FD40 CD 15 02     ...
        bne     pollKBD_invalid                                                ; FD43 D0 26        .&
        dec     wa_kbdTMP2                                                     ; FD45 CE 14 02     ...
        beq     LFD75                                                          ; FD48 F0 2B        .+
        ldy     #$05                                                           ; FD4A A0 05        ..
pollKBD_debounce:
        ldx     #$C8                                                           ; FD4C A2 C8        ..
pollKBD_debounceLoop:
        dex                                                                    ; FD4E CA           .
        bne     pollKBD_debounceLoop                                           ; FD4F D0 FD        ..
        dey                                                                    ; FD51 88           .
        bne     pollKBD_debounce                                               ; FD52 D0 F8        ..
        beq     pollKBD_firstRow                                               ; FD54 F0 AE        ..
pollKBD_debounceDone:
        cmp     #$01                                                           ; FD56 C9 01        ..
        beq     LFD8F                                                          ; FD58 F0 35        .5
        ldy     #$00                                                           ; FD5A A0 00        ..
        cmp     #$02                                                           ; FD5C C9 02        ..
        beq     pollKBD_SaveResults                                            ; FD5E F0 47        .G
        ldy     #$C0                                                           ; FD60 A0 C0        ..
        cmp     #$20                                                           ; FD62 C9 20        .
        beq     pollKBD_SaveResults                                            ; FD64 F0 41        .A
pollKBD_noKey:
        lda     #$00                                                           ; FD66 A9 00        ..
        sta     wa_kbdTMP4                                                     ; FD68 8D 16 02     ...
pollKBD_invalid:
        sta     wa_kbdTMP3                                                     ; FD6B 8D 15 02     ...
        lda     #$02                                                           ; FD6E A9 02        ..
        sta     wa_kbdTMP2                                                     ; FD70 8D 14 02     ...
        bne     pollKBD_firstRow                                               ; FD73 D0 8F        ..
LFD75:
        ldx     #$96                                                           ; FD75 A2 96        ..
        cmp     wa_kbdTMP4                                                     ; FD77 CD 16 02     ...
        bne     LFD7E                                                          ; FD7A D0 02        ..
        ldx     #$14                                                           ; FD7C A2 14        ..
LFD7E:
        stx     wa_kbdTMP2                                                     ; FD7E 8E 14 02     ...
        sta     wa_kbdTMP4                                                     ; FD81 8D 16 02     ...
        lda     #$01                                                           ; FD84 A9 01        ..
        jsr     kbdStrobe                                                      ; FD86 20 BE FC      ..
        jsr     kbdGetRaw                                                      ; FD89 20 CF FC      ..
        lsr     a                                                              ; FD8C 4A           J
        bcc     LFDC2                                                          ; FD8D 90 33        .3
LFD8F:
        tax                                                                    ; FD8F AA           .
        and     #$03                                                           ; FD90 29 03        ).
        beq     LFD9F                                                          ; FD92 F0 0B        ..
        ldy     #$10                                                           ; FD94 A0 10        ..
        lda     wa_kbdTMP3                                                     ; FD96 AD 15 02     ...
        bpl     pollKBD_SaveResults                                            ; FD99 10 0C        ..
        ldy     #$F0                                                           ; FD9B A0 F0        ..
        bne     pollKBD_SaveResults                                            ; FD9D D0 08        ..
LFD9F:
        ldy     #$00                                                           ; FD9F A0 00        ..
        cpx     #$20                                                           ; FDA1 E0 20        .
        bne     pollKBD_SaveResults                                            ; FDA3 D0 02        ..
        ldy     #$C0                                                           ; FDA5 A0 C0        ..
pollKBD_SaveResults:
        lda     wa_kbdTMP3                                                     ; FDA7 AD 15 02     ...
        and     #$7F                                                           ; FDAA 29 7F        ).
        cmp     #$20                                                           ; FDAC C9 20        .
        beq     pollKBD_Exit                                                   ; FDAE F0 07        ..
        sty     wa_kbdTMP1                                                     ; FDB0 8C 13 02     ...
        clc                                                                    ; FDB3 18           .
        adc     wa_kbdTMP1                                                     ; FDB4 6D 13 02     m..
pollKBD_Exit:
        sta     wa_kbdTMP1                                                     ; FDB7 8D 13 02     ...
        pla                                                                    ; FDBA 68           h
        tay                                                                    ; FDBB A8           .
        pla                                                                    ; FDBC 68           h
        tax                                                                    ; FDBD AA           .
        lda     wa_kbdTMP1                                                     ; FDBE AD 13 02     ...
        rts                                                                    ; FDC1 60           `

; ----------------------------------------------------------------------------
LFDC2:
        bne     pollKBD_debounceDone                                           ; FDC2 D0 92        ..
        ldy     #$20                                                           ; FDC4 A0 20        .
        bne     pollKBD_SaveResults                                            ; FDC6 D0 DF        ..
pollKBD_getColumn:
        ldy     #$08                                                           ; FDC8 A0 08        ..
pollKBD_getColumnNext:
        dey                                                                    ; FDCA 88           .
        asl     a                                                              ; FDCB 0A           .
        bcc     pollKBD_getColumnNext                                          ; FDCC 90 FC        ..
        rts                                                                    ; FDCE 60           `

; ----------------------------------------------------------------------------
validKeysR0:
        .byte   $D0,$BB                                                        ; FDCF D0 BB        ..
        .byte   "/ ZAQ"                                                        ; FDD1 2F 20 5A 41 51/ ZAQ
validKeysR1:
        .byte   ",MNBVCX"                                                      ; FDD6 2C 4D 4E 42 56 43 58,MNBVCX
validKeysR2:
        .byte   "KJHGFDS"                                                      ; FDDD 4B 4A 48 47 46 44 53KJHGFDS
validKeysR3:
        .byte   "IUYTREW"                                                      ; FDE4 49 55 59 54 52 45 57IUYTREW
validKeysR4:
        .byte   $00,$00,$0D,$0A                                                ; FDEB 00 00 0D 0A  ....
        .byte   "OL."                                                          ; FDEF 4F 4C 2E     OL.
validKeysR5:
        .byte   $00,$FF                                                        ; FDF2 00 FF        ..
        .byte   "-"                                                            ; FDF4 2D           -
        .byte   $BA                                                            ; FDF5 BA           .
        .byte   "0"                                                            ; FDF6 30           0
        .byte   $B9,$B8                                                        ; FDF7 B9 B8        ..
; ----------------------------------------------------------------------------
validKeysR6:
        .byte   $B7,$B6,$B5,$B4,$B3,$B2,$B1                                    ; FDF9 B7 B6 B5 B4 B3 B2 B1.......
; ----------------------------------------------------------------------------
; When you type M to enter the monitor you end up here
monStart:
        ldx     #$28                                                           ; FE00 A2 28        .(
        txs                                                                    ; FE02 9A           .
        cld                                                                    ; FE03 D8           .
        nop                                                                    ; FE04 EA           .
        nop                                                                    ; FE05 EA           .
        nop                                                                    ; FE06 EA           .
        nop                                                                    ; FE07 EA           .
        nop                                                                    ; FE08 EA           .
        nop                                                                    ; FE09 EA           .
        nop                                                                    ; FE0A EA           .
; Monitor - Initialise everything
mon_init:
        nop                                                                    ; FE0B EA           .
        ldx     #$D4                                                           ; FE0C A2 D4        ..
        lda     #$D0                                                           ; FE0E A9 D0        ..
        sta     zp_monLoadAddrHi                                               ; FE10 85 FF        ..
        lda     #$00                                                           ; FE12 A9 00        ..
        sta     zp_monLoadAddrLo                                               ; FE14 85 FE        ..
        sta     zp_monLoadFlag                                                 ; FE16 85 FB        ..
        tay                                                                    ; FE18 A8           .
        lda     #$20                                                           ; FE19 A9 20        .
; Monitor - Display char on screen
mon_DspChar:
        sta     (zp_monLoadAddrLo),y                                           ; FE1B 91 FE        ..
        iny                                                                    ; FE1D C8           .
        bne     mon_DspChar                                                    ; FE1E D0 FB        ..
        inc     zp_monLoadAddrHi                                               ; FE20 E6 FF        ..
        cpx     zp_monLoadAddrHi                                               ; FE22 E4 FF        ..
        bne     mon_DspChar                                                    ; FE24 D0 F5        ..
        sty     zp_monLoadAddrHi                                               ; FE26 84 FF        ..
        beq     mon_DspAddr                                                    ; FE28 F0 19        ..
; Monitor - Main loop
mon_MainLoop:
        jsr     fetchByte                                                      ; FE2A 20 E9 FE      ..
        cmp     #'/'                                                           ; FE2D C9 2F        ./
        beq     mon_DataMode                                                   ; FE2F F0 1E        ..
        cmp     #'G'                                                           ; FE31 C9 47        .G
        beq     mon_GoAddr                                                     ; FE33 F0 17        ..
        cmp     #'L'                                                           ; FE35 C9 4C        .L
        beq     mon_SetLoadSaveFlag                                            ; FE37 F0 43        .C
        jsr     hex2bin                                                        ; FE39 20 93 FE      ..
        bmi     mon_MainLoop                                                   ; FE3C 30 EC        0.
        ldx     #$02                                                           ; FE3E A2 02        ..
        jsr     rollAD                                                         ; FE40 20 DA FE      ..
; Monitor - Display Address
mon_DspAddr:
        lda     (zp_monLoadAddrLo),y                                           ; FE43 B1 FE        ..
        sta     zp_monLoadByte                                                 ; FE45 85 FC        ..
        jsr     disp4bytes                                                     ; FE47 20 AC FE      ..
        bne     mon_MainLoop                                                   ; FE4A D0 DE        ..
; Monitor - Execute at Address store at zPage ($FE+$FF)
mon_GoAddr:
        jmp     (zp_monLoadAddrLo)                                             ; FE4C 6C FE 00     l..

; ----------------------------------------------------------------------------
; Monitor - Data mode
mon_DataMode:
        jsr     fetchByte                                                      ; FE4F 20 E9 FE      ..
        cmp     #$2E                                                           ; FE52 C9 2E        ..
        beq     mon_MainLoop                                                   ; FE54 F0 D4        ..
        cmp     #$0D                                                           ; FE56 C9 0D        ..
        bne     mon_DspData                                                    ; FE58 D0 0F        ..
        inc     zp_monLoadAddrLo                                               ; FE5A E6 FE        ..
        bne     mon_GetByteAt                                                  ; FE5C D0 02        ..
        inc     zp_monLoadAddrHi                                               ; FE5E E6 FF        ..
mon_GetByteAt:
        ldy     #$00                                                           ; FE60 A0 00        ..
        lda     (zp_monLoadAddrLo),y                                           ; FE62 B1 FE        ..
        sta     zp_monLoadByte                                                 ; FE64 85 FC        ..
        jmp     mon_DspAddr2                                                   ; FE66 4C 77 FE     Lw.

; ----------------------------------------------------------------------------
mon_DspData:
        jsr     hex2bin                                                        ; FE69 20 93 FE      ..
        bmi     mon_DataMode                                                   ; FE6C 30 E1        0.
        ldx     #$00                                                           ; FE6E A2 00        ..
        jsr     rollAD                                                         ; FE70 20 DA FE      ..
        lda     zp_monLoadByte                                                 ; FE73 A5 FC        ..
        sta     (zp_monLoadAddrLo),y                                           ; FE75 91 FE        ..
mon_DspAddr2:
        jsr     disp4bytes                                                     ; FE77 20 AC FE      ..
        bne     mon_DataMode                                                   ; FE7A D0 D3        ..
mon_SetLoadSaveFlag:
        sta     zp_monLoadFlag                                                 ; FE7C 85 FB        ..
        beq     mon_DataMode                                                   ; FE7E F0 CF        ..


; ----------------------------------------------------------------------------
; Get char from the ACIA
aciaGet:                                                                       ; FE80
        jsr     aciaGetR
        bcc     aciaGet
        and     #$7F
        rts
;
aciaGetR:
        lda     aciaStatus
        lsr     a
        bcc     @Done
        lda     aciaData
@Done:
        rts

; ----------------------------------------------------------------------------
        .byte   $00  ; ,$00,$00,$00                                                ; FE8F 00 00 00 00  ....
; ----------------------------------------------------------------------------
; hex2bin - Convert ascii hex to binary
hex2bin:
        cmp     #$30                                                           ; FE93 C9 30        .0
        bmi     hex2bin_err                                                    ; FE95 30 12        0.
        cmp     #$3A                                                           ; FE97 C9 3A        .:
        bmi     hex2bin_ok                                                     ; FE99 30 0B        0.
        cmp     #$41                                                           ; FE9B C9 41        .A
        bmi     hex2bin_err                                                    ; FE9D 30 0A        0.
        cmp     #$47                                                           ; FE9F C9 47        .G
        bpl     hex2bin_err                                                    ; FEA1 10 06        ..
        sec                                                                    ; FEA3 38           8
        sbc     #$07                                                           ; FEA4 E9 07        ..
; hex2bin - Success exit
hex2bin_ok:
        and     #$0F                                                           ; FEA6 29 0F        ).
        rts                                                                    ; FEA8 60           `

; ----------------------------------------------------------------------------
; hex2bin - Error exit
hex2bin_err:
        lda     #$80                                                           ; FEA9 A9 80        ..
        rts                                                                    ; FEAB 60           `

; ----------------------------------------------------------------------------
; Display 4 bytes in $FF, FE, FD & FC
disp4bytes:
        ldx     #$03                                                           ; FEAC A2 03        ..
        ldy     #$00                                                           ; FEAE A0 00        ..
; Display 4 bytes - Loop
disp4bytes_loop:
        lda     zp_monLoadByte,x                                               ; FEB0 B5 FC        ..
        lsr     a                                                              ; FEB2 4A           J
        lsr     a                                                              ; FEB3 4A           J
        lsr     a                                                              ; FEB4 4A           J
        lsr     a                                                              ; FEB5 4A           J
        jsr     dispNybble                                                     ; FEB6 20 CA FE      ..
        lda     zp_monLoadByte,x                                               ; FEB9 B5 FC        ..
        jsr     dispNybble                                                     ; FEBB 20 CA FE      ..
        dex                                                                    ; FEBE CA           .
        bpl     disp4bytes_loop                                                ; FEBF 10 EF        ..
        lda     #$20                                                           ; FEC1 A9 20        .
        sta     displayRAM+$CA                                                 ; FEC3 8D CA D0     ...
        sta     displayRAM+$CB                                                 ; FEC6 8D CB D0     ...
        rts                                                                    ; FEC9 60           `

; ----------------------------------------------------------------------------
; Display Nybble - A-Reg
dispNybble:
        and     #$0F                                                           ; FECA 29 0F        ).
        ora     #$30                                                           ; FECC 09 30        .0
        cmp     #$3A                                                           ; FECE C9 3A        .:
        bmi     dispNybble_exit                                                ; FED0 30 03        0.
        clc                                                                    ; FED2 18           .
        adc     #$07                                                           ; FED3 69 07        i.
; Display Nybble - Exit
dispNybble_exit:
        sta     displayRAM+$C6,y                                               ; FED5 99 C6 D0     ...
        iny                                                                    ; FED8 C8           .
        rts                                                                    ; FED9 60           `

; ----------------------------------------------------------------------------
; Roll hex digits into 2 bytes of memory target $FC, FD
rollAD:
        ldy     #$04                                                           ; FEDA A0 04        ..
        asl     a                                                              ; FEDC 0A           .
        asl     a                                                              ; FEDD 0A           .
        asl     a                                                              ; FEDE 0A           .
        asl     a                                                              ; FEDF 0A           .
; Roll hex digits - Loop
rollAD_loop:
        rol     a                                                              ; FEE0 2A           *
        rol     zp_monLoadByte,x                                               ; FEE1 36 FC        6.
        rol     zp_monLoadTmp,x                                                ; FEE3 36 FD        6.
        dey                                                                    ; FEE5 88           .
        bne     rollAD_loop                                                    ; FEE6 D0 F8        ..
        rts                                                                    ; FEE8 60           `

; ----------------------------------------------------------------------------
; Check Fetch flag; Read from TAPE else KEYB
fetchByte:
        lda     zp_monLoadFlag                                                 ; FEE9 A5 FB        ..
        bne     aciaGet                                                        ; FEEB D0 93        ..
oneBefore_jumpTable:= * + $0002
        jmp     pollKBD                                                        ; FEED 4C 00 FD     L..

; ----------------------------------------------------------------------------
jumpTable:
        .addr   inputChar                                                      ; FEF0 BA FF        ..
        .addr   outChar                                                        ; FEF2 69 FF        i.
        .addr   ctrlC                                                          ; FEF4 9B FF        ..
        .addr   setLoadFlag                                                    ; FEF6 8B FF        ..
        .addr   setSaveFlag                                                    ; FEF8 96 FF        ..
        .addr   stack+$30                     ; NMI                            ; FEFA 30 01        0.
        .addr   monStart                      ; ???                            ; FEFC 00 FE        ..
        .addr   stack+$C0                     ; IRQ                            ; FEFE C0 01        ..
; ----------------------------------------------------------------------------
; Cold start - Called on CPU reset
coldStart:
        ldx     #$28                          ; Start of Stack = $28           ; FF00
        txs                                   ; Xfer into SP
;
        jsr     initIrqNmi                    ; Prep IRQ/NMI handling & finish CPU setup
;
        cld
        ldy     #$0A
        nop
        nop
        nop
        nop

;                                                                              ; THESE ARE WRONG NOW!!!
; Cold start - Copy jump table to wrkArea
coldStart_copyJumpTable:                                                       ;
        lda     oneBefore_jumpTable,y                                          ; FF06 B9 EF FE     ...
        sta     wa_unused2,y                                                   ; FF09 99 17 02     ...
        dey                                                                    ; FF0C 88           .
        bne     coldStart_copyJumpTable                                        ; FF0D D0 F7        ..
        jsr     aciaInit                                                       ; FF0F 20 A6 FC      ..
        sty     wa_ctrl_C_flag                                                 ; FF12 8C 12 02     ...
        sty     wa_loadFlag                                                    ; FF15 8C 03 02     ...
        sty     wa_saveFlag                                                    ; FF18 8C 05 02     ...
        sty     wa_repeatRate                                                  ; FF1B 8C 06 02     ...
        lda     initialSetup                                                   ; FF1E AD E0 FF     ...
        sta     wa_cursorAtAddr                                                ; FF21 8D 00 02     ...
;
        jsr     clrScreen
;
coldStart_dspPrompt:
        lda     dcwmPrompt,y                                                   ; FF35 B9 5F FF     ._.
        beq     coldStart_goMonStart                                           ; FF38 F0 06        ..
        jsr     basicROM_crtRtn                                                ; FF3A 20 2D BF      -.
        iny                                                                    ; FF3D C8           .
        bne     coldStart_dspPrompt                                            ; FF3E D0 F5        ..
;
; Cold start - goto Mon Start?
coldStart_goMonStart:
        jsr     inputChar                                                      ; FF40 20 BA FF      ..
        cmp     #'M'                                                           ; FF43 C9 4D        .M
        bne     coldStart_goWarmStartBASIC                                     ; FF45 D0 03        ..
        jmp     monStart                                                       ; FF47 4C 00 FE     L..

; ----------------------------------------------------------------------------
; Cold start - goto Warm Start BASIC?
coldStart_goWarmStartBASIC:
        cmp     #'W'                                                           ; FF4A C9 57        .W
        bne     coldStart_goColdStartBASIC                                     ; FF4C D0 03        ..
        jmp     zp_bas_JmpWarm                                                 ; FF4E 4C 00 00     L..

; ----------------------------------------------------------------------------
; Cold start - goto Cold Start BASIC?
coldStart_goColdStartBASIC:
        cmp     #'C'                                                           ; FF51 C9 43        .C
        bne     coldStart_goDiskStart                                          ; FF53 D0 03        ..
        jmp     basicROM_coldStart                                             ; FF55 4C 11 BD     L..

; ----------------------------------------------------------------------------
; Cold start - goto Disk Start!
coldStart_goDiskStart:
        cmp     #'D'
        bne     coldstart_Xmodem
        jmp     dskBoot
; ----------------------------------------------------------------------------
; Cold start - goto XModem start
coldstart_Xmodem:
        cmp     #'X'
        bne     coldStart
        jmp     XM_RomStart
; ----------------------------------------------------------------------------
dcwmPrompt:
        .byte   "D/C/W/M/X"                                                    ; FF5F 44 2F 43 2F 57 2F 4D 20D/C/W/M
                                                                               ; FF67 3F           ?
        .byte   $00                                                            ; FF68 00           .
; ----------------------------------------------------------------------------
; Output char to screen and/or TAPE(ACIA)
outChar:
        jsr     basicROM_crtRtn                                                ; FF69 20 2D BF      -.
        pha                                                                    ; FF6C 48           H
        lda     wa_saveFlag                                                    ; FF6D AD 05 02     ...
        beq     outChar_exitRestore_A                                          ; FF70 F0 22        ."
        pla                                                                    ; FF72 68           h
        jsr     aciaPut                                                        ; FF73 20 B1 FC      ..
        cmp     #$0D                                                           ; FF76 C9 0D        ..
        bne     outChar_exit                                                   ; FF78 D0 1B        ..
        pha                                                                    ; FF7A 48           H
        txa                                                                    ; FF7B 8A           .
        pha                                                                    ; FF7C 48           H
        ldx     #$0A                                                           ; FF7D A2 0A        ..
        lda     #$00                                                           ; FF7F A9 00        ..
outChar_loop:
        jsr     aciaPut                                                        ; FF81 20 B1 FC      ..
        dex                                                                    ; FF84 CA           .
        bne     outChar_loop                                                   ; FF85 D0 FA        ..
        pla                                                                    ; FF87 68           h
        tax                                                                    ; FF88 AA           .
        pla                                                                    ; FF89 68           h
        rts                                                                    ; FF8A 60           `

; ----------------------------------------------------------------------------
; Set LOAD flag, reset SAVE flag
setLoadFlag:
        pha                                                                    ; FF8B 48           H
        dec     wa_loadFlag                                                    ; FF8C CE 03 02     ...
        lda     #$00                                                           ; FF8F A9 00        ..
; Store the LOAD/SAVE flag
storeLSFlag:
        sta     wa_saveFlag                                                    ; FF91 8D 05 02     ...
outChar_exitRestore_A:
        pla                                                                    ; FF94 68           h
outChar_exit:
        rts                                                                    ; FF95 60           `

; ----------------------------------------------------------------------------
; Set SAVE flag
setSaveFlag:
        pha                                                                    ; FF96 48           H
        lda     #$01                                                           ; FF97 A9 01        ..
        bne     storeLSFlag                                                    ; FF99 D0 F6        ..
; Control-C Check - CTRL-C disable flag in wrkArea+12
ctrlC:
        lda     wa_ctrl_C_flag                                                 ; FF9B AD 12 02     ...
        bne     ctrlC_ignore                                                   ; FF9E D0 19        ..
        lda     #$FE                                                           ; FFA0 A9 FE        ..
        sta     kbdPort                                                        ; FFA2 8D 00 DF     ...
        bit     kbdPort                                                        ; FFA5 2C 00 DF     ,..
        bvs     ctrlC_ignore                                                   ; FFA8 70 0F        p.
        lda     #$FB                                                           ; FFAA A9 FB        ..
        sta     kbdPort                                                        ; FFAC 8D 00 DF     ...
        bit     kbdPort                                                        ; FFAF 2C 00 DF     ,..
        bvs     ctrlC_ignore                                                   ; FFB2 70 05        p.
        lda     #$03                                                           ; FFB4 A9 03        ..
        jmp     basicROM_CTRL_C+$0D                                            ; FFB6 4C 36 A6     L6.

; ----------------------------------------------------------------------------
ctrlC_ignore:
        rts                                                                    ; FFB9 60           `

; ----------------------------------------------------------------------------
; Input char from KBD and/or TAPE(ACIA)
inputChar:
        bit     wa_loadFlag                                                    ; FFBA 2C 03 02     ,..
        bpl     inputChar_kbd                                                  ; FFBD 10 19        ..
inputChar_loopACIA:
        lda     #$FD                                                           ; FFBF A9 FD        ..
        sta     kbdPort                                                        ; FFC1 8D 00 DF     ...
        lda     #$10                                                           ; FFC4 A9 10        ..
        bit     kbdPort                                                        ; FFC6 2C 00 DF     ,..
        beq     inputChar_endACIA                                              ; FFC9 F0 0A        ..
        lda     aciaStatus                                                     ; FFCB AD 00 F0     ...
        lsr     a                                                              ; FFCE 4A           J
        bcc     inputChar_loopACIA                                             ; FFCF 90 EE        ..
        lda     aciaData                                                       ; FFD1 AD 01 F0     ...
        rts                                                                    ; FFD4 60           `

; ----------------------------------------------------------------------------
inputChar_endACIA:
        inc     wa_loadFlag                                                    ; FFD5 EE 03 02     ...
inputChar_kbd:
        jmp     pollKBD                                                        ; FFD8 4C 00 FD     L..

; ----------------------------------------------------------------------------
        .byte   $FF,$FF,$FF,$FF,$FF                                            ; FFDB FF FF FF FF FF.....
initialSetup:
        .byte   $65,$17,$00,$00,$03,$FF,$9F,$00                                ; FFE0 65 17 00 00 03 FF 9F 00e.......
        .byte   $03,$FF,$9F                                                    ; FFE8 03 FF 9F     ...
; ----------------------------------------------------------------------------
; Input Routine
inputRtn:
        jmp     (wa_inputVec)                                                  ; FFEB 6C 18 02     l..

; ----------------------------------------------------------------------------
; Output Routine
outputRtn:
        jmp     (wa_outputVec)                                                 ; FFEE 6C 1A 02     l..

; ----------------------------------------------------------------------------
; Ctrl-C Routine
crtl_CRtn:
        jmp     (wa_ctrlCVec)                                                  ; FFF1 6C 1C 02     l..

; ----------------------------------------------------------------------------
; Load Routine
loadRtn:
        jmp     (wa_loadVec)                                                   ; FFF4 6C 1E 02     l..

; ----------------------------------------------------------------------------
; Save Routine
saveRtn:
        jmp     (wa_saveVec)                                                   ; FFF7 6C 20 02     l .

; ----------------------------------------------------------------------------
CPU_nmi:
        .addr   nmiJump
;       .addr   stack+$30                                                      ; FFFA 30 01        0.
CPU_res:
        .addr   coldStart                                                      ; FFFC 00 FF        ..
CPU_irq:
        .addr   irqJump
;       .addr   stack+$C0                                                      ; FFFE C0 01        ..
.reloc     ; back to normal
