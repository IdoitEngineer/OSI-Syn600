; ----------------------------------------------------------------------------
zp_bas_JmpWarm                    :=  $0000
zp_bas_MsgPrint                   :=  $0003
zp_bas_usrInVar                   :=  $0006
zp_bas_usrOutVar                  :=  $0008
zp_bas_usrJump                    :=  $000A
zp_bas_usrJumpAddr                :=  $000B
zp_bas_nullCount                  :=  $000D
zp_bas_lineBuffCnt                :=  $000E
zp_bas_termWidth                  :=  $000F
zp_bas_inpColLim                  :=  $0010
zp_bas_integerAddr                :=  $0011
zp_bas_lineBuffer                 :=  $0013     ; 72 Bytes of line buffer
zp_bas_dec2bin                    :=  $005B
zp_bas_scanQuoteFlag              :=  $005C
zp_bas_lineBuffPtr                :=  $005D
zp_bas_dimFlag                    :=  $005E
zp_bas_dataType                   :=  $005F
zp_bas_dataScan                   :=  $0060
zp_bas_subScrFlag                 :=  $0061
zp_bas_inpOrRead                  :=  $0062
zp_bas_evalFlag                   :=  $0063
zp_bas_Ctrl_O                     :=  $0064
zp_bas_tmpStr_1                   :=  $0065
zp_bas_tmpStr_2                   :=  $0068
zp_bas_tmpStr_3                   :=  $006B
zp_bas_tmpStr_4                   :=  $006E
zp_bas_tmpPtr_1                   :=  $0071
zp_bas_tmpPtr_2                   :=  $0073
zp_bas_mulStge_1                  :=  $0075
zp_bas_srcStart                   :=  $0079
zp_bas_snglVars                   :=  $007B
zp_bas_arryVars                   :=  $007D
zp_bas_emptyRAM                   :=  $007F
zp_bas_strings                    :=  $0081
zp_bas_tmpStr                     :=  $0083
zp_bas_memTop                     :=  $0085
zp_bas_currLineNum                :=  $0087
zp_bas_pgmScanPtr                 :=  $008B
zp_bas_curDataStmt                :=  $008D
zp_bas_nxtDataStmt                :=  $008F
zp_bas_find_var_AD0B              :=  $0095
zp_bas_outVarAddr                 :=  $0097
zp_bas_jmp                        :=  $00A1
zp_bas_jmp_addr                   :=  $00A2
zp_bas_nextListLn                 :=  $00AA
zp_bas_prt_num_B962               :=  $00AD
zp_bas_getNxtC                    :=  $00BC
zp_bas_getC                       :=  $00C2
zp_bas_getC_Addr_L                :=  $00C3
zp_bas_getC_Addr_H                :=  $00C4
zp_bas_getC_Exit                  :=  $00D3
zp_bas_randSeed1                  :=  $00D4
zp_bas_randSeed2                  :=  $00D6
;---------
;zp_freeRAM                       :=  $00D8     ; cc65 Use?     (30 free bytes?)
;
;zp_irq_vec                       :=  $00F7     ; IRQ Vector    (2 Bytes )
;zp_nmi_vec                       :=  $00F9     ; NMI Vector    (2 Bytes )
;---------
zp_irq_vec                        :=  $00D8     ; IRQ Vector    (2 Bytes )
zp_nmi_vec                        :=  $00DA     ; NMI Vector    (2 Bytes )
;
zp_freeRAM                        :=  $00DC     ; cc65 Use?     (26 free bytes?)
;---------
;
zp_monLoadFlag                    :=  $00FB
zp_monLoadByte                    :=  $00FC
zp_monLoadTmp                     :=  $00FD
zp_monLoadAddrLo                  :=  $00FE
zp_monLoadAddrHi                  :=  $00FF
;
stack                             :=  $0100     ; Stack init $28 by default (OSI roms use stack for IRQ & NMI)
;
wa_cursorAtAddr                   :=  $0200
wa_printChar                      :=  $0201
wa_tempChar1                      :=  $0202
wa_loadFlag                       :=  $0203
wa_tempChar2                      :=  $0204
wa_saveFlag                       :=  $0205
wa_repeatRate                     :=  $0206
wa_scrollRtn                      :=  $0207
wa_unused1                        :=  $020F     ; 2 free bytes?
wa_ctrl_C_flag                    :=  $0212
wa_kbdTMP1                        :=  $0213
wa_kbdTMP2                        :=  $0214
wa_kbdTMP3                        :=  $0215
wa_kbdTMP4                        :=  $0216
wa_unused2                        :=  $0217     ; 1 Byte Free?
wa_inputVec                       :=  $0218
wa_outputVec                      :=  $021A
wa_ctrlCVec                       :=  $021C
wa_loadVec                        :=  $021E
wa_saveVec                        :=  $0220
wa_Free                           :=  $0222     ; People use this for small routines?  (222 bytes)
;
basicPGM                          :=  $0300     ; Basic programs Start here
;
;
;
basicROM_cmdJumpTable             :=  $A000
basicROM_keywordTable             :=  $A084
basicROM_errorMsgTable            :=  $A164
basicROM_msgOutRtn                :=  $A24E
basicROM_Input_str                :=  $A357
basicROM_Init                     :=  $A477
basicROM_Run                      :=  $A5C2
basicROM_CTRL_C                   :=  $A629
basicROM_STOP                     :=  $A638
basicROM_Print_Str                :=  $A8C3
basicROM_compl_16                 :=  $ABD8
basicROM_InVar                    :=  $AE05
basicROM_OutVar                   :=  $AFC1
basicROM_Print_Num                :=  $B962
basicROM_coldStart                :=  $BD11
basicROM_crtRtn                   :=  $BF2D
;
;
;
floppy_piaDRA                     :=  $C000                                                       ; The floppy PIA Data-A port (Input)
floppy_piaCRA                     :=  $C001                                                       ; The floppy PIA Control-A port
floppy_piaDRB                     :=  $C002                                                       ; The floppy PIA Data-B port (Output)
floppy_piaCRB                     :=  $C003                                                       ; The floppy PIA Control-B port
floppy_aciaStatus                 :=  $C010                                                      ; The floppy ACIA Status port
floppy_aciaData                   :=  $C011                                                       ; The floppy ACIA Data port
displayRAM                        :=  $D000
kbdPort                           :=  $DF00                                                       ; The keyboad port lives here
aciaStatus                        :=  $F000                                                       ; The TAPE ACIA Status port
aciaData                          :=  $F001                                                       ; The TAPE ACIA Data port
;
;
;
;
;
;
; The *NEW* X-Modem routines
syn600_XM_RomStart                     := $F800         ; X - option lands here
syn600_XM_Recv                         := $F820         ; Recv routine
syn600_XM_UpdateDisplay                := $F957         ; Display the Address held in zp_monLoadAddrLo:zp_monLoadAddrHi
syn600_XM_BasicSave                    := $F963         ; Save the BASIC program in memory
syn600_XM_clrScreen                    := $F986         ; A callable screen clear!
syn600_XM_Send                         := $F9A0         ; Save memory rand (It will prompt for the range)
syn600_XM_Init                         := $FAC5         ; Sets up everything the X-Modem code needs
syn600_XM_Flush                        := $FB0E         ; Flush the ACIA traffic (There maybe bytes inbound)
syn600_XM_aciaGet                      := $FB54         ; ACIA read char in A-reg bcc set if no char
syn600_XM_MakeCRCTable                 := $FB7F         ; Build the CRC table in video RAM
;
;
; The *OLD* Kernel routines with a few mods
; Most of the entry points should be the same
;
; Disk stuff
syn600_dsk_Boot                        := $FC00         ;
syn600_dsk_SeekTrk_0                   := $FC2A         ;
syn600_dsk_SeekTrk                     := $FC33         ;
syn600_dsk_SetDrive                    := $FC4D         ;
syn600_dsk_WaitIndex                   := $FC55         ;
syn600_dsk_WaitReady                   := $FC5A         ;
syn600_dsk_ReadSector                  := $FC7B         ;
syn600_dsk_Delay                       := $FC91         ;
syn600_dsk_DelayLoopEOR                := $FC93         ;
syn600_dsk_WaitData                    := $FC9C         ;
syn600_dsk_ExitRtn                     := $FCA5         ;
;
;
;
syn600_aciaInit                        := $FCA6         ; syn600 ROM Serial Acia Init Routine
syn600_aciaPut                         := $FCB1         ; syn600 ROM Serial Acia Send byte (A-Reg) Routine
;
;
;
syn600_irqJump                         := $FCD5         ; NEW - CPU IRQ lands here
syn600_nmiJump                         := $FCD8         ; NEW - CPU NMI land here
syn600_intrStub                        := $FCDB         ; NEW - The IRQ/NMI stub, just does an rti
syn600_initIrqNmi                      := $FCDC         ; NEW - Init the IRQ/NMI ZP vectors
;
;
;
syn600_pollKBD                         := $FD00         ; Keyboard poll routine - Result in A-reg
;
; Table of tables of valid keys brom keyboard
syn600_tbl_validKeysR0                 := $FDCF
syn600_tbl_validKeysR1                 := $FDD6
syn600_tbl_validKeysR2                 := $FDDD
syn600_tbl_validKeysR3                 := $FDE4
syn600_tbl_validKeysR4                 := $FDEB
syn600_tbl_validKeysR5                 := $FDF2
syn600_tbl_validKeysR6                 := $FDF9
;
;
;
syn600_mon_Start                       := $FE00
; Internal Monitor routines
syn600_mon_init                        := $FE0B         ; Monitor - Start up
syn600_mon_DspAddr                     := $FE43         ; Monitor - Display Address
syn600_mon_GoAddr                      := $FE4C         ; Monitor - Execute at Address store at zPage ($FE+$FF)
;
syn600_aciaGet_Wait                    := $FE80         ; Check to see if we have a char from the ACIA wait for char
syn600_aciaGet                         := $FE88         ; Check to see if we have a char from the ACIA (bcc set if not)
syn600_hex2bin                         := $FE93         ; hex2bin - Convert ascii hex to binary
;
syn600_disp4bytes                      := $FEAC         ; Display 4 bytes in $FF, FE, FD & FC
syn600_dispNybble                      := $FECA         ; Display Nybble - A-Reg Set Y-Reg to zero on entry (Its used as an index)
;
syn600_rollAD                          := $FEDA         ; Roll hex digits into 2 bytes of memory target $FC, FD
;
syn600_fetchByte                       := $FEE9         ; Check Fetch flag; Read from TAPE else KEYB
;
; Table of Vectors you should be able to
; jmp/jsr   (syn600_vec_blah)
syn600_vec_inputChar                   := $FEF0
syn600_vec_outChar                     := $FEF2
syn600_vec_ctrlC                       := $FEF4
syn600_vec_setLoadFlag                 := $FEF6
syn600_vec_setSaveFlag                 := $FEF8
syn600_vec_NMI                         := $FEFA
syn600_vec_RST                         := $FEFC
syn600_vec_IRQ                         := $FEFE
;
;
;
syn600_coldStart                       := $FF00         ; This is where we end up on a cold start
;
;
;
syn600_dcwmPrompt                      := $FF5F
syn600_outChar                         := $FF69         ; Output char to screen and/or TAPE(ACIA)
syn600_setLoadFlag                     := $FF8B         ; Set LOAD flag, reset SAVE flag
syn600_setSaveFlag                     := $FF96         ; Set SAVE flag
syn600_ctrlC                           := $FF9B         ; Control-C Check - CTRL-C disable flag in wrkArea+12
;
syn600_inputChar                       := $FFBA         ; Input char from KBD and/or TAPE(ACIA)
syn600_inputChar_ACIA                  := $FFBF         ; Input char from UART(ACIA)
syn600_inputChar_kbd                   := $FFD8         ; Input char from KBD
;
syn600_inputRtn                        := $FFEB         ; Input Routine
syn600_outputRtn                       := $FFEE         ; Output Routine
syn600_crtl_CRtn                       := $FFF1         ; Ctrl-C Routine
syn600_loadRtn                         := $FFF4         ; Load Routine
syn600_saveRtn                         := $FFF7         ; Save Routine
;
;
;
syn600_CPU_nmi                         := $FFFA
syn600_CPU_res                         := $FFFC
syn600_CPU_irq                         := $FFFE

