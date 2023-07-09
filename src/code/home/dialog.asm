
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

    pop de
    pop hl
    ret

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

; param a: bank number to read from
; param bc: address to read from
; param hl: address to copy to
AppendDrawCommand::
    push bc
    push de
    ld [rSelectROMBank], a

    ld a, [wDrawCommandsSize]
    ld e, a
    add $10
    ld [wDrawCommandsSize], a
    ld d, $00
    ld hl, wDrawCommand
    add hl, de
    ld e, $10

.appendDrawCommand_loop
    ld a, [bc]
    inc bc
    ldi [hl], a
    dec e
    jr nz, .appendDrawCommand_loop

    ld [hl], $00

    ld a, $01
    ld [rSelectROMBank], a
    pop de
    pop bc
    ret
