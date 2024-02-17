
; Open a dialog in the $100-$1FF range
; Input:
;   a: dialog index in table 1
OpenDialogInTable1::
    call OpenDialogInTable0                       ; $2373: $CD $85 $23
    ; Overwrite the table number
    ld   a, $01                                   ; $2376: $3E $01
    ld   [wDialogIndexHi], a                      ; $2378: $EA $12 $C1
    ret                                           ; $237B: $C9

; Open a dialog in the $200-$2FF range
; Input:
;   a: dialog index in table 2
OpenDialogInTable2::
    call OpenDialogInTable0                       ; $237C: $CD $85 $23
    ; Overwrite the table number
    ld   a, $02                                   ; $237F: $3E $02
    ld   [wDialogIndexHi], a                      ; $2381: $EA $12 $C1
    ret                                           ; $2384: $C9

; Open a dialog in the $00-$FF range
; Input:
;   a: dialog index in table 0
OpenDialogInTable0::
    ; Clear wDialogAskSelectionIndex
    push af                                       ; $2385: $F5
    xor  a                                        ; $2386: $AF
    ld   [wDialogAskSelectionIndex], a            ; $2387: $EA $77 $C1
    pop  af                                       ; $238A: $F1

    ; Save the dialog index
    ld   [wDialogIndex], a                        ; $238B: $EA $73 $C1

    ; Initialize dialog variables
    xor  a                                        ; $238E: $AF
    ld   [wDialogOpenCloseAnimationFrame], a      ; $238F: $EA $6F $C1
    ld   [wDialogCharacterIndex], a               ; $2392: $EA $70 $C1
    ld [wDialogNextCharPosition], a
    ld [wDialogCharacterOutIndex], a
    ld   [wDialogCharacterIndexHi], a             ; $2395: $EA $64 $C1
    ld   [wNameIndex], a                          ; $2398: $EA $08 $C1
    ld   [wDialogIndexHi], a                      ; $239B: $EA $12 $C1

    ld   a, $0F                                   ; $239E: $3E $0F
    ld   [wDialogSFX], a                          ; $23A0: $EA $AB $C5

    ; Determine if the dialog is displayed on top or bottom
    ; wDialogState = hLinkPositionY < $48 ? $81 : $01
    ldh  a, [hLinkPositionY]                      ; $23A3: $F0 $99
    cp   $48                                      ; $23A5: $FE $48
    rra                                           ; $23A7: $1F
    and  DIALOG_BOX_BOTTOM_FLAG                   ; $23A8: $E6 $80
    or   DIALOG_OPENING_1                         ; $23AA: $F6 $01
    ld   [wDialogState], a                        ; $23AC: $EA $9F $C1

    ret                                           ; $23AF: $C9

IncrementDialogNextCharOutIndex::
    push hl
    ld hl, wDialogCharacterOutIndex
    inc [hl]
    pop hl
    ret

IncrementAndReadNextChar::
    call IncrementDialogNextCharIndex
    call ReadDialogNextChar
    ret

IncrementDialogNextCharIndex::
    ld   a, [wDialogCharacterIndex]               ; $2663: $FA $70 $C1
    ; increment character index
    ; (add is used because inc doesn't set the carry flag)
    add  a, $01                                   ; $2666: $C6 $01
    ld   [wDialogCharacterIndex], a               ; $2668: $EA $70 $C1
    ld   a, [wDialogCharacterIndexHi]             ; $266B: $FA $64 $C1
    adc  a, $00                                   ; $266E: $CE $00
    ld   [wDialogCharacterIndexHi], a             ; $2670: $EA $64 $C1
    ret

ReadDialogNextChar::
    push hl
    push de
    ld   a, [wDialogIndexHi]                      ; $2550: $FA $12 $C1
    ld   d, a                                     ; $2553: $57
    ld   a, [wDialogIndex]                        ; $2554: $FA $73 $C1
    ld   e, a                                     ; $2557: $5F
    sla  e                                        ; $2558: $CB $23
    rl   d                                        ; $255A: $CB $12
    ld   hl, DialogPointerTable                   ; $255C: $21 $01 $40
    add  hl, de                                   ; $255F: $19
    ld   a, [hli]                                 ; $2560: $2A
    ld   e, a                                     ; $2561: $5F
    ld   d, [hl]                                  ; $2562: $56

    push de                                       ; $2563: $D5
    ld   a, [wDialogIndex]                        ; $2564: $FA $73 $C1
    ld   e, a                                     ; $2567: $5F
    ld   a, [wDialogIndexHi]                      ; $2568: $FA $12 $C1
    ld   d, a                                     ; $256B: $57
    ld   hl, DialogBankTable                      ; $256C: $21 $41 $47
    add  hl, de                                   ; $256F: $19
    ld   a, [hl] ; bank                           ; $2570: $7E
    ; Mask out DIALOG_UNSKIPPABLE flag
    and  $7F                                      ; $2571: $E6 $3F
    ld   [rSelectROMBank], a                      ; $2573: $EA $00 $21
    pop  hl                                       ; $2576: $E1

    ld   a, [wDialogCharacterIndex]               ; $2577: $FA $70 $C1
    ld   e, a                                     ; $257A: $5F
    ld   a, [wDialogCharacterIndexHi]             ; $257B: $FA $64 $C1
    ld   d, a                                     ; $257E: $57
    add  hl, de                                   ; $257F: $19
    ld   a, [hli]                                 ; $2580: $2A
    ld   e, a                                     ; $2581: $5F
    ; Peek ahead and store the next character in
    ; the dialog, for later use in DialogBreakHandler
    ld   a, [hl]                                  ; $2582: $7E
    ld   [wDialogNextChar], a                     ; $2583: $EA $C3 $C3
    ; call ReloadSavedBank                          ; $2586: $CD $1D $08
    ld   a, $1c
    ld   [rSelectROMBank], a
    ld   a, e                                     ; $2589: $7B
    ldh  [hMultiPurpose0], a                      ; $258A: $E0 $D7
    cp   "<ask>" ; $fe                            ; $258C: $FE $FE
    jr   nz, .notChoice                           ; $258E: $20 $14
    pop  hl                                       ; $2590: $E1
    xor  a                                        ; $2591: $AF
    ld   [wDrawCommand], a                        ; $2592: $EA $01 $D6

.choice
    ld   a, [wDialogState]                        ; $2595: $FA $9F $C1
    ; Keep DIALOG_BOX_BOTTOM_FLAG
    and  $F0                                      ; $2598: $E6 $F0
    or   DIALOG_CHOICE                            ; $259A: $F6 $0D
    ld   [wDialogState], a                        ; $259C: $EA $9F $C1

.endDialog
    ld   a, JINGLE_DIALOG_BREAK                   ; $259F: $3E $15
    ldh  [hJingle], a                             ; $25A1: $E0 $F2
    ret                                           ; $25A3: $C9

.notChoice
    cp   "@" ; $ff                                ; $25A4: $FE $FF
    jr   nz, .notEnd                              ; $25A6: $20 $15
    pop  hl                                       ; $25A8: $E1
    xor  a                                        ; $25A9: $AF
    ld   [wDrawCommand], a                        ; $25AA: $EA $01 $D6

.end
    ld   a, [wDialogState]                        ; $25AD: $FA $9F $C1
    ; Keep DIALOG_BOX_BOTTOM_FLAG
    and  $F0                                      ; $25B0: $E6 $F0
    or   DIALOG_END                               ; $25B2: $F6 $0C
    ld   [wDialogState], a                        ; $25B4: $EA $9F $C1
    ret                                           ; $25B7: $C9

.ThiefString::
FOR INDEX, 5
    IF CHARLEN("{THIEF_NAME}") < INDEX + 1
        db 0
    ELSE
        db CHARSUB("{THIEF_NAME}", INDEX + 1) + 1 ; $25B8
    ENDC
ENDR

.notEnd
    cp   " "                                      ; $25BD: $FE $20
    jr   z, .noSFX                                ; $25BF: $28 $1F
    push af                                       ; $25C1: $F5
    ld   a, [wDialogSFX]                          ; $25C2: $FA $AB $C5
    ld   d, a                                     ; $25C5: $57
    ld   e, $01                                   ; $25C6: $1E $01
    cp   WAVE_SFX_TEXT_PRINT                      ; $25C8: $FE $0F
    jr   z, .handleFrequency                      ; $25CA: $28 $08
    ld   e, $07                                   ; $25CC: $1E $07
    cp   WAVE_SFX_OWL_HOOT                        ; $25CE: $FE $19
    jr   z, .handleFrequency                      ; $25D0: $28 $02
    ld   e, $03                                   ; $25D2: $1E $03
.handleFrequency
    ld   a, [wDialogCharacterIndex]               ; $25D4: $FA $70 $C1
    add  a, $04                                   ; $25D7: $C6 $04
    and  e                                        ; $25D9: $A3
    jr   nz, .skipSFX                             ; $25DA: $20 $03
    ld   a, d                                     ; $25DC: $7A
    ldh  [hWaveSfx], a                            ; $25DD: $E0 $F3
.skipSFX
    pop  af                                       ; $25DF: $F1

.noSFX
    ld   d, $00                                   ; $25E0: $16 $00
    cp   "#" ; character of player name           ; $25E2: $FE $23
    jr   nz, .notName                             ; $25E4: $20 $22
    ld   a, [wNameIndex]                          ; $25E6: $FA $08 $C1
    ld   e, a                                     ; $25E9: $5F
    inc  a                                        ; $25EA: $3C
    cp   NAME_LENGTH                              ; $25EB: $FE $05
    jr   nz, .notOver                             ; $25ED: $20 $01
    xor  a                                        ; $25EF: $AF
.notOver
    ld   [wNameIndex], a                          ; $25F0: $EA $08 $C1
    ld   hl, wName                                ; $25F3: $21 $4F $DB
    ld   a, [wIsThief]                            ; $25F6: $FA $6E $DB
    and  a                                        ; $25F9: $A7
    jr   z, .notThief                             ; $25FA: $28 $03
    ld   hl, .ThiefString                         ; $25FC: $21 $B8 $25
.notThief
    add  hl, de                                   ; $25FF: $19
    ld   a, [hl]                                  ; $2600: $7E
    ; Name characters are from NameEntryCharmap
    ; which is ASCII + 1, so decrement it here to
    ; convert it to DialogCharmap which is ASCII
    dec  a                                        ; $2601: $3D
    ; Convert NameEntryCharmap space ($00) to
    ; DialogCharmap/ASCII space ($20)
    PUSHC
    SETCHARMAP NameEntryCharmap
    cp   " " - 1                                  ; $2602: $FE $FF
    POPC
    jr   nz, .handleNameChar                      ; $2604: $20 $02
    ld   a, " "                                   ; $2606: $3E $20
.handleNameChar

.notName
    ldh  [hMultiPurpose1], a                      ; $2608: $E0 $D8
    ld   e, a                                     ; $260A: $5F
    ld   a, BANK(CodepointToTileMap)              ; $260B: $3E $1C
    ld   [rSelectROMBank], a                      ; $260D: $EA $00 $21
    ld   hl, CodepointToTileMap                   ; $2610: $21 $41 $46
    add  hl, de                                   ; $2613: $19
    ld   e, [hl]                                  ; $2614: $5E
    ld   d, $00                                   ; $2615: $16 $00
    sla  e                                        ; $2617: $CB $23
    rl   d                                        ; $2619: $CB $12
    sla  e                                        ; $261B: $CB $23
    rl   d                                        ; $261D: $CB $12
    sla  e                                        ; $261F: $CB $23
    rl   d                                        ; $2621: $CB $12
    sla  e                                        ; $2623: $CB $23
    rl   d                                        ; $2625: $CB $12
    call ReloadSavedBank                          ; $2627: $CD $1D $08
    ld   hl, FontTiles                            ; $262A: $21 $00 $50
    add  hl, de                                   ; $262D: $19
    ld   c, l                                     ; $262E: $4D
    ld   b, h                                     ; $262F: $44
    pop  hl                                       ; $2630: $E1
    ld   e, $10                                   ; $2631: $1E $10
    ; copy character tile data to wDrawCommandData
.copyTileLoop
    ld   a, [bc]                                  ; $2633: $0A
    ldi  [hl], a                                  ; $2634: $22
    inc  bc                                       ; $2635: $03
    dec  e                                        ; $2636: $1D
    jr   nz, .copyTileLoop                        ; $2637: $20 $FA
    ld   [hl], $00                                ; $2639: $36 $00
    push hl                                       ; $263B: $E5

    ; Check if the current character has a diacritic tile above
    ; (if compiled with support for diacritics)
    ld   a, BANK(CodepointToDiacritic)            ; $263C: $3E $1C
    ld   [rSelectROMBank], a ; current character  ; $263E: $EA $00 $21
    ldh  a, [hMultiPurpose1]                      ; $2641: $F0 $D8
    ld   e, a                                     ; $2643: $5F
    ld   d, $00                                   ; $2644: $16 $00
IF __DIACRITICS_SUPPORT__
    ld   hl, CodepointToDiacritic
    add  hl, de
    ld   a, [hl]
ELSE
    xor  a                                        ; $2646: $AF
ENDC
    pop  hl                                       ; $2647: $E1
    and  a                                        ; $2648: $A7
    jr   z, .noDiacritic                          ; $2649: $28 $18
    ld   e, a                                     ; $264B: $5F
    ld   a, [wC175]                               ; $264C: $FA $75 $C1
    ldi  [hl], a                                  ; $264F: $22
    ld   a, [wC176]                               ; $2650: $FA $76 $C1
    sub  a, $20                                   ; $2653: $D6 $20
    ldi  [hl], a                                  ; $2655: $22
    ld   a, $00                                   ; $2656: $3E $00
    ldi  [hl], a                                  ; $2658: $22
    ld   a, DIALOG_DIACRITIC_1                    ; $2659: $3E $C9
    rr   e                                        ; $265B: $CB $1B
    jr   c, .handleDiacriticTile                  ; $265D: $38 $01
    dec  a ; DIALOG_DIACRITIC_2                   ; $265F: $3D

.handleDiacriticTile
    ldi  [hl], a                                  ; $2660: $22
    ld   [hl], $00                                ; $2661: $36 $00

.noDiacritic
    ld   a, [wDialogCharacterIndex]               ; $2663: $FA $70 $C1
    ; increment character index
    ; (add is used because inc doesn't set the carry flag)
    add  a, $01                                   ; $2666: $C6 $01
    ld   [wDialogCharacterIndex], a               ; $2668: $EA $70 $C1
    ld   a, [wDialogCharacterIndexHi]             ; $266B: $FA $64 $C1
    adc  a, $00                                   ; $266E: $CE $00
    ld   [wDialogCharacterIndexHi], a             ; $2670: $EA $64 $C1
    xor  a                                        ; $2673: $AF
    ld   [wDialogIsWaitingForButtonPress], a      ; $2674: $EA $CC $C1
    ; check if we've filled the dialog box with 32 characters
    ld   a, [wDialogNextCharPosition]             ; $2677: $FA $71 $C1
    cp   $1F                                      ; $267A: $FE $1F
    jr   z, .dialogBoxFull                        ; $267C: $28 $10

.nextCharacter
    ld   a, [wDialogState]                        ; $267E: $FA $9F $C1
    and  $F0 ; mask DIALOG_BOX_BOTTOM_FLAG        ; $2681: $E6 $F0
    or   DIALOG_LETTER_IN_1                       ; $2683: $F6 $06
    ld   [wDialogState], a                        ; $2685: $EA $9F $C1
    ld   a, $00                                   ; $2688: $3E $00
    ld   [wDialogScrollDelay], a                  ; $268A: $EA $72 $C1
    ret                                           ; $268D: $C9

.dialogBoxFull
    jp   IncrementDialogStateAndReturn            ; $268E: $C3 $85 $24

DialogBoxOrigin::
    ; Background tile map address of the beginning of the
    ; text in a dialog box (one line above regular text, to
    ; make room for diacritics?)
.low
    db   $22 ; top
    db   $42 ; bottom
.high
    db   $98 ; top
    db   $99 ; bottom

; Read a byte from bank b, offset hl, and return to bank c.
ReadByteFromBankBAndReturnToC::
    ld [rSelectROMBank], a
    ld b, [hl]

    ld a, [hl]
    ld b, a

    ld a, c
    ld [rSelectROMBank], a

    ld a, b
    ret
