;
; Dialog display
;

ExecuteDialog::
    ; If DialogState == 0, don't do anything.
    ld   a, [wDialogState]                        ; $2321: $FA $9F $C1
    and  a                                        ; $2324: $A7
    ret  z                                        ; $2325: $C8

    ; Configure the dialog background color
    ld   e, a                                     ; $2326: $5F
    ld   a, [wGameplayType]                       ; $2327: $FA $95 $DB
    cp   GAMEPLAY_CREDITS                         ; $232A: $FE $01
    ; By default use a dark background
    ld   a, DIALOG_BG_TILE_DARK                   ; $232C: $3E $7E
    jr   nz, .writeBackgroundTile                 ; $232E: $20 $02
.lightBackground
    ; but during credits use a light background
    ld   a, DIALOG_BG_TILE_LIGHT                  ; $2330: $3E $7F
.writeBackgroundTile
    ldh  [hDialogBackgroundTile], a               ; $2332: $E0 $E8

    ; If the character index is > 20 (i.e. past the first two lines),
    ; mask wDialogNextCharPosition around $10
    ld   a, [wDialogCharacterIndexHi]             ; $2334: $FA $64 $C1
    and  a                                        ; $2337: $A7
    ld   a, [wDialogCharacterIndex]               ; $2338: $FA $70 $C1
    ld a, [wDialogNextCharPosition]
    cp a, $10
    jr   z, .wrapPosition                        ; $233B: $20 $04
    cp   $20                                      ; $233D: $FE $20
    jr   c, .writePosition                        ; $233F: $38 $04
.wrapPosition
    and  $0F                                      ; $2341: $E6 $0F
    or   $10                                      ; $2343: $F6 $10
.writePosition
    ld   [wDialogNextCharPosition], a             ; $2345: $EA $71 $C1

    ; Discard wDialogState upper bit (dialog displayed on bottom)
    ld   a, e                                     ; $2348: $7B
    and  ~DIALOG_BOX_BOTTOM_FLAG                  ; $2349: $E6 $7F

    ; Dispatch according to the dialog state
    dec  a                                        ; $234B: $3D
    JP_TABLE                                      ; $234C: $C7
._00 dw DialogOpenAnimationStartHandler           ; $234D
._01 dw DialogOpenAnimationHandler                ; $234F
._02 dw DialogOpenAnimationHandler                ; $2351
._03 dw DialogOpenAnimationHandler                ; $2353
._04 dw DialogOpenAnimationEndHandler             ; $2355
._05 dw DialogLetterAnimationStartHandler         ; $2357
._06 dw DialogLetterAnimationEndHandler           ; $2359
._07 dw DialogDrawNextCharacterHandler            ; $235B
._08 dw DialogBreakHandler                        ; $235D
._09 dw DialogScrollingStartHandler               ; $235F
._0A dw DialogScrollingEndHandler                 ; $2361
._0B dw DialogFinishedHandler                     ; $2363
._0C dw DialogChoiceHandler                       ; $2365
._0D dw DialogClosingBeginHandler                 ; $2367
._0E dw DialogClosingEndHandler                   ; $2369

DialogOpenAnimationStartHandler::
    jp DialogOpenAnimationStart                 ; $236B: $3E $14 $EA $00 $21 $C3 $49 $54

DialogOpenAnimationHandler::
    ret                                           ; $23B0: $C9

DialogClosingEndHandler::
    xor  a                                        ; $23B1: $AF
    ld   [wDialogState], a                        ; $23B2: $EA $9F $C1
    ld   a, DIALOG_COOLDOWN                       ; $23B5: $3E $18
    ld   [wDialogCooldown], a                     ; $23B7: $EA $34 $C1
    ldh  a, [hIsGBC]                              ; $23BA: $F0 $FE
    and  a                                        ; $23BC: $A7
    ret  z                                        ; $23BD: $C8

    ld   a, [wGameplayType]                       ; $23BE: $FA $95 $DB
    cp   a, GAMEPLAY_WORLD                        ; $23C1: $FE $0B
    ret  nz                                       ; $23C3: $C0

    ld   a, [wBGPaletteEffectAddress]             ; $23C4: $FA $CC $C3
    cp   a, $08                                   ; $23C7: $FE $08
    ret  c                                        ; $23C9: $D8

    ; jpsb func_021_53CF                            ; $23CA: $3E $21 $EA $00 $21 $C3 $CF $53

    ld   hl, wFarcallParams                       ; $5498: $21 $01 $DE
    ld   a, BANK(func_021_53CF)                   ; $549B: $3E $21
    ld   [hl+], a                                 ; $549D: $22
    ld   a, HIGH(func_021_53CF)                   ; $549E: $3E $53
    ld   [hl+], a                                 ; $54A0: $22
    ld   a, LOW(func_021_53CF)                    ; $54A1: $3E $B6
    ld   [hl+], a                                 ; $54A3: $22
    ld   a, BANK(@)                               ; $54A4: $3E $14
    ld   [wFarcallReturnBank], a                  ; $54A6: $EA $04 $DE
    jp   Farcall                                  ; $54A9: $C3 $D7 $0B
    ret

; This array actually begins two bytes before,
; in the middle of the `jp` instruction,
; and so has two extra bytes at the beginning ($CF, $53).
data_23D2::
    db   $00, $24                                 ; $23D2
    db   $48, $00                                 ; $23D4

data_23D6::
    db   $24, $48, $98, $98, $98, $99             ; $23D6

data_23DC::
    db   $99, $99, $21, $61, $A1, $41, $81, $C1   ; $23DC

; Open dialog animation
; Saves tiles under the dialog box?
func_23E4::
    ld   a, [wDialogState]                        ; $23E4: $FA $9F $C1
    bit  DIALOG_BOX_BOTTOM_BIT, a                 ; $23E7: $CB $7F
    jr   z, .jr_23EF                              ; $23E9: $28 $04
    and  ~DIALOG_BOX_BOTTOM_FLAG                  ; $23EB: $E6 $7F
    add  a, $03                                   ; $23ED: $C6 $03
.jr_23EF

    ld   e, a                                     ; $23EF: $5F
    ld   d, $00                                   ; $23F0: $16 $00
    ld   hl, data_23D2 - $02                      ; $23F2: $21 $D0 $23
    add  hl, de                                   ; $23F5: $19
    ld   a, [hl]                                  ; $23F6: $7E
    add  a, LOW(wD500)                            ; $23F7: $C6 $00
    ld   c, a                                     ; $23F9: $4F
    ld   a, HIGH(wD500)                           ; $23FA: $3E $D5
    adc  a, $00                                   ; $23FC: $CE $00
    ld   b, a                                     ; $23FE: $47

    ld   hl, data_23DC                            ; $23FF: $21 $DC $23
    add  hl, de                                   ; $2402: $19
    ld   a, [wBGOriginLow]                        ; $2403: $FA $2F $C1
    add  a, [hl]                                  ; $2406: $86
    ld   l, a                                     ; $2407: $6F
    ldh  [hMultiPurpose0], a                      ; $2408: $E0 $D7
    ld   hl, data_23D6                            ; $240A: $21 $D6 $23
    add  hl, de                                   ; $240D: $19
    ld   a, [wBGOriginHigh]                       ; $240E: $FA $2E $C1
    add  a, [hl]                                  ; $2411: $86
    ld   h, a                                     ; $2412: $67
    ldh  a, [hMultiPurpose0]                      ; $2413: $F0 $D7
    ld   l, a                                     ; $2415: $6F
    xor  a                                        ; $2416: $AF
    ld   e, a                                     ; $2417: $5F
    ld   d, a                                     ; $2418: $57
    ldh  a, [hIsGBC]                              ; $2419: $F0 $FE
    and  a                                        ; $241B: $A7
    jr   nz, label_2444                           ; $241C: $20 $26

    ; DMG version of the loop
.loop
    ld   a, [hli]                                 ; $241E: $2A
    ld   [bc], a                                  ; $241F: $02
    inc  bc                                       ; $2420: $03

    ld   a, l                                     ; $2421: $7D
    and  $1F                                      ; $2422: $E6 $1F
    jr   nz, .jr_242B                             ; $2424: $20 $05
    ld   a, l                                     ; $2426: $7D
    dec  a                                        ; $2427: $3D
    and  $E0                                      ; $2428: $E6 $E0
    ld   l, a                                     ; $242A: $6F
.jr_242B

    inc  e                                        ; $242B: $1C
    ld   a, e                                     ; $242C: $7B
    cp   $12                                      ; $242D: $FE $12
    jr   nz, .loop                                ; $242F: $20 $ED

    ld   e, $00                                   ; $2431: $1E $00
    ldh  a, [hMultiPurpose0]                      ; $2433: $F0 $D7
    add  a, $20                                   ; $2435: $C6 $20
    ldh  [hMultiPurpose0], a                      ; $2437: $E0 $D7
    jr   nc, .jr_243C                             ; $2439: $30 $01
    inc  h                                        ; $243B: $24
.jr_243C

    ld   l, a                                     ; $243C: $6F
    inc  d                                        ; $243D: $14
    ld   a, d                                     ; $243E: $7A
    cp   $02                                      ; $243F: $FE $02
    jr   nz, .loop                                ; $2441: $20 $DB
    ret                                           ; $2443: $C9

label_2444::
    ld   a, [hl]                                  ; $2444: $7E
    ld   [bc], a                                  ; $2445: $02
    ld   a, $01                                   ; $2446: $3E $01
    ld   [rVBK], a                                ; $2448: $E0 $4F

label_244A::
    ld   a, $02                                   ; $244A: $3E $02
    ld   [rSVBK], a                               ; $244C: $E0 $70
    ld   a, [hl]                                  ; $244E: $7E
    ld   [bc], a                                  ; $244F: $02
    xor  a                                        ; $2450: $AF
    ld   [rVBK], a                                ; $2451: $E0 $4F
    ld   [rSVBK], a                               ; $2453: $E0 $70
    inc  bc                                       ; $2455: $03
    ld   a, l                                     ; $2456: $7D
    add  a, $01                                   ; $2457: $C6 $01
    and  $1F                                      ; $2459: $E6 $1F
    jr   nz, label_2463                           ; $245B: $20 $06
    ld   a, l                                     ; $245D: $7D
    and  $E0                                      ; $245E: $E6 $E0
    ld   l, a                                     ; $2460: $6F
    jr   label_2464                               ; $2461: $18 $01

label_2463::
    inc  l                                        ; $2463: $2C

label_2464::
    inc  e                                        ; $2464: $1C
    ld   a, e                                     ; $2465: $7B
    cp   $12                                      ; $2466: $FE $12
    jr   nz, label_2444                           ; $2468: $20 $DA
    ld   e, $00                                   ; $246A: $1E $00
    ldh  a, [hMultiPurpose0]                      ; $246C: $F0 $D7
    add  a, $20                                   ; $246E: $C6 $20
    ldh  [hMultiPurpose0], a                      ; $2470: $E0 $D7
    jr   nc, label_2475                           ; $2472: $30 $01
    inc  h                                        ; $2474: $24

label_2475::
    ld   l, a                                     ; $2475: $6F
    inc  d                                        ; $2476: $14
    ld   a, d                                     ; $2477: $7A
    cp   $02                                      ; $2478: $FE $02
    jr   nz, label_2444                           ; $247A: $20 $C8
    ret                                           ; $247C: $C9

DialogOpenAnimationEndHandler::
    ; jpsb DialogOpenAnimationEnd                   ; $247D: $3E $1C $EA $00 $21 $C3 $2C $4A
    jp DialogOpenAnimationEnd

IncrementDialogState::
IncrementDialogStateAndReturn::
    ld   hl, wDialogState                         ; $2485: $21 $9F $C1
    inc  [hl]                                     ; $2488: $34
    ret                                           ; $2489: $C9

DialogFinishedHandler::
    ; If wC1AB == 0...
    ld   a, [wC1AB]                               ; $248A: $FA $AB $C1
    and  a                                        ; $248D: $A7
    jr   nz, UpdateDialogState_return             ; $248E: $20 $1E
    ; ... and A or B is pressed...
    ldh  a, [hJoypadState]                        ; $2490: $F0 $CC
    and  J_A | J_B                                ; $2492: $E6 $30
    jr   z, UpdateDialogState_return              ; $2494: $28 $18
    ; ... update dialog state

UpdateDialogState::
    ; Clear wDialogOpenCloseAnimationFrame
    xor  a                                        ; $2496: $AF
    ld   [wDialogOpenCloseAnimationFrame], a      ; $2497: $EA $6F $C1

.if
    ; If GameplayType == PHOTO_ALBUM
    ld   a, [wGameplayType]                       ; $249A: $FA $95 $DB
    cp   GAMEPLAY_PHOTO_ALBUM                     ; $249D: $FE $0D
    jr   nz, .else                                ; $249F: $20 $03
.then
    ; A = 0
    xor  a                                        ; $24A1: $AF
    jr   .fi                                      ; $24A2: $18 $07
.else
    ; A = (wDialogState & $F0) | $E
    ld   a, [wDialogState]                        ; $24A4: $FA $9F $C1
    and  $F0                                      ; $24A7: $E6 $F0
    or   $0E                                      ; $24A9: $F6 $0E
.fi
    ; Set dialog state
    ld   [wDialogState], a                        ; $24AB: $EA $9F $C1

UpdateDialogState_return:
    ret                                           ; $24AE: $C9

DialogClosingBeginHandler::
    ; jpsb AnimateDialogClosing                     ; $24AF: $3E $1C $EA $00 $21 $C3 $A8 $4A
    jp AnimateDialogClosing

DialogLetterAnimationStartHandler::
    ; Check: safe (same bank)
    ; ld   a, BANK(ClearLetterPixels)               ; $24B7: $3E $1C
    ; ld   [rSelectROMBank], a                      ; $24B9: $EA $00 $21
    ld   a, [wDialogScrollDelay]                  ; $24BC: $FA $72 $C1
    and  a                                        ; $24BF: $A7
    jr   z, .delayOver                            ; $24C0: $28 $05
    dec  a                                        ; $24C2: $3D
    ld   [wDialogScrollDelay], a                  ; $24C3: $EA $72 $C1
    ret                                           ; $24C6: $C9

.delayOver
    call ClearLetterPixels                        ; $24C7: $CD $F1 $49
    jp   IncrementDialogStateAndReturn            ; $24CA: $C3 $85 $24

DialogLetterAnimationEndHandler::
    ; Check: safe (same bank)
    ; ld   a, BANK(DialogPointerTable)              ; $24CD: $3E $1C
    ; ld   [rSelectROMBank], a                      ; $24CF: $EA $00 $21
    ld   a, [wDialogState]                        ; $24D2: $FA $9F $C1
    ld   c, a                                     ; $24D5: $4F
    ld   a, [wDialogNextCharPosition]             ; $24D6: $FA $71 $C1
    bit  DIALOG_BOX_BOTTOM_BIT, c                 ; $24D9: $CB $79
    jr   z, .jp_24DF                              ; $24DB: $28 $02
    add  a, $20                                   ; $24DD: $C6 $20

.jp_24DF
    ; bc = [wDialogNextCharPosition]
    ld   c, a                                     ; $24DF: $4F
    ld   b, $00                                   ; $24E0: $06 $00
    ; de = $01
    ld   e, $01                                   ; $24E2: $1E $01
    ld   d, $00                                   ; $24E4: $16 $00
    ld   a, [wBGOriginHigh]                       ; $24E6: $FA $2E $C1
    ld   hl, Data_01C_45C1                        ; $24E9: $21 $C1 $45
    add  hl, bc                                   ; $24EC: $09
    add  a, [hl]                                  ; $24ED: $86
    ld   hl, wDrawCommandsSize                    ; $24EE: $21 $00 $D6
    add  hl, de                                   ; $24F1: $19
    ldi  [hl], a                                  ; $24F2: $22
    ld   [wC175], a                               ; $24F3: $EA $75 $C1
    push hl                                       ; $24F6: $E5
    ld   hl, Data_01C_4601                        ; $24F7: $21 $01 $46
    add  hl, bc                                   ; $24FA: $09
    ld   a, [hl]                                  ; $24FB: $7E
    and  $E0                                      ; $24FC: $E6 $E0
    add  a, $20                                   ; $24FE: $C6 $20
    ld   e, a                                     ; $2500: $5F
    ld   a, [wBGOriginLow]                        ; $2501: $FA $2F $C1
    add  a, [hl]                                  ; $2504: $86
    ld   d, a                                     ; $2505: $57
    cp   e                                        ; $2506: $BB
    jr   c, .jp_250D                              ; $2507: $38 $04
    ld   a, d                                     ; $2509: $7A
    sub  a, $20                                   ; $250A: $D6 $20
    ld   d, a                                     ; $250C: $57

.jp_250D
    ld   a, d                                     ; $250D: $7A
    ld   [wC176], a                               ; $250E: $EA $76 $C1
    pop  hl                                       ; $2511: $E1
    ldi  [hl], a                                  ; $2512: $22
    xor  a                                        ; $2513: $AF
    ldi  [hl], a                                  ; $2514: $22
    push hl                                       ; $2515: $E5
    ld   a, [wDialogCharacterOutIndex]               ; $2516: $FA $70 $C1
    and  $1F                                      ; $2519: $E6 $1F
    ld   c, a                                     ; $251B: $4F
    ld   hl, Data_01C_45A1                        ; $251C: $21 $A1 $45
    add  hl, bc                                   ; $251F: $09
    ld   a, [hl]                                  ; $2520: $7E
    pop  hl                                       ; $2521: $E1
    ldi  [hl], a                                  ; $2522: $22
    call IncrementDialogState                     ; $2523: $CD $85 $24
    jp   DialogDrawNextCharacterHandler           ; $2526: $C3 $29 $25

DialogDrawNextCharacterHandler::
    ; Check: safe (same bank)
    ; ld   a, BANK(DialogPointerTable)              ; $2529: $3E $1C
    ; ld   [rSelectROMBank], a                      ; $252B: $EA $00 $21
    ld   a, [wDialogCharacterOutIndex]               ; $252E: $FA $70 $C1
    and  $1F                                      ; $2531: $E6 $1F
    ld   c, a                                     ; $2533: $4F
    ld   b, $00                                   ; $2534: $06 $00
    ld   e, $05                                   ; $2536: $1E $05
    ld   d, $00                                   ; $2538: $16 $00
    ld   hl, DialogCharacterYTable                ; $253A: $21 $81 $45
    add  hl, bc                                   ; $253D: $09
    ld   a, [hl]                                  ; $253E: $7E

    ld   hl, wDrawCommandsSize                    ; $253F: $21 $00 $D6
    add  hl, de                                   ; $2542: $19
    ldi  [hl], a ; high byte of tile destination address ; $2543: $22
    push hl                                       ; $2544: $E5
    ld   hl, DialogCharacterXTable                ; $2545: $21 $61 $45
    add  hl, bc                                   ; $2548: $09
    ld   a, [hl]                                  ; $2549: $7E
    pop  hl                                       ; $254A: $E1
    ldi  [hl], a ; low byte of tile destination address ; $254B: $22
    ld   a, $0F                                   ; $254C: $3E $0F
    ldi  [hl], a ; number of bytes                ; $254E: $22
    push hl                                       ; $254F: $E5

    call ReadDialogNextChar

    ldh  [hMultiPurpose0], a                      ; $258A: $E0 $D7
    cp   $01 ; $fe                            ; $258C: $FE $FE
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
    cp   $00 ; $ff                                ; $25A4: $FE $FF
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
INDEX = 0
REPT 5
IF CHARLEN("{THIEF_NAME}") < INDEX + 1
    db 0
ELSE
    db CHARSUB("{THIEF_NAME}", INDEX + 1) + 1     ; $25B8
ENDC
INDEX = INDEX + 1
ENDR

.notEnd
    cp   $20                                      ; $25BD: $FE $20
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
    cp   $02 ; character of player name           ; $25E2: $FE $23
    jr   nz, .notName                             ; $25E4: $20 $22
    ld   a, [wNameIndex]                          ; $25E6: $FA $08 $C1
    ld   e, a                                     ; $25E9: $5F
    inc  a                                        ; $25EA: $3C
    cp   NAME_LENGTH                              ; $25EB: $FE $05
    jr   nz, .notOver                             ; $25ED: $20 $01
    ; Prevent name from being drawn multiple times with UTF-8
    ; xor  a                                        ; $25EF: $AF
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
    ; dec  a                                        ; $2601: $3D
    ; Convert NameEntryCharmap space ($00) to
    ; DialogCharmap/ASCII space ($20)
    ; PUSHC
    ; SETCHARMAP NameEntryCharmap
    ; cp   $20 - 1                                  ; $2602: $FE $FF
    ; POPC
    and a
    jr   nz, .handleNameChar                      ; $2604: $20 $02
    ld   a, $20                                   ; $2606: $3E $20

.handleNameChar
    ldh  [hMultiPurpose1], a
    ld l, $01
    call UTF16BE_to_UTF32
    call GetFontAddr
    jr .endChar

.notName
    ldh  [hMultiPurpose1], a                      ; $2608: $E0 $D8
    ; ld   e, a                                     ; $260A: $5F
    ld l, $00
    call UTF8_to_UTF32
    call GetFontAddr

.endChar
    ld b, h
    ld c, l
    pop  hl                                       ; $2630: $E1

    ; ld a, e
    ; ld   e, $10                                   ; $2631: $1E $10
    call CopyTile
    ld   [hl], $00                                ; $2639: $36 $00
    ; push hl                                       ; $263B: $E5

    ; Check if the current character has a diacritic tile above
    ; (if compiled with support for diacritics)
    ; Check: safe (same bank)
    ; ld   a, BANK(CodepointToDiacritic)            ; $263C: $3E $1C
    ; ld   [rSelectROMBank], a ; current character  ; $263E: $EA $00 $21
    ; ldh  a, [hMultiPurpose1]                      ; $2641: $F0 $D8
    ; ld   e, a                                     ; $2643: $5F
    ; ld   d, $00                                   ; $2644: $16 $00
    ; xor  a                                        ; $2646: $AF
    ; pop  hl                                       ; $2647: $E1

    call IncrementDialogNextCharOutIndex
    call IncrementDialogNextCharIndex
    xor  a                                        ; $2673: $AF
    ld   [wDialogIsWaitingForButtonPress], a      ; $2674: $EA $CC $C1
    ; check if we've filled the dialog box with 32 characters
    ld   a, [wDialogNextCharPosition]             ; $2677: $FA $71 $C1
    cp   $1F                                      ; $267A: $FE $1F
    jr   z, .dialogBoxFull                        ; $267C: $28 $10

.nextCharacter
    ld a, [wDialogNextCharPosition]
    inc a
    ld [wDialogNextCharPosition], a
    ld   a, [wDialogState]                        ; $267E: $FA $9F $C1
    and  $F0 ; mask DIALOG_BOX_BOTTOM_FLAG        ; $2681: $E6 $F0
    or   DIALOG_LETTER_IN_1                       ; $2683: $F6 $06
    ld   [wDialogState], a                        ; $2685: $EA $9F $C1
    ld   a, $00                                   ; $2688: $3E $00
    ld   [wDialogScrollDelay], a                  ; $268A: $EA $72 $C1
    ret                                           ; $268D: $C9

.dialogBoxFull
    jp   IncrementDialogStateAndReturn            ; $268E: $C3 $85 $24

data_2691::
    db $22, $42                                   ; $2691

data_2693::
    db $98, $99                                   ; $2693

; Handle a break in the dialog. Checks the NEXT character
; to see if it's more text (if so, display arrow and
; allow scrolling), or if it's a terminating character
; ("@" or "<ask>"), which allows terminators to lie beyond
; the maximum line length (otherwise a line of 16 characters
; followed by "@" would print an empty line).
DialogBreakHandler::
    ld   a, [wDialogCharacterOutIndex]               ; $2695: $FA $70 $C1
    and  $1F                                      ; $2698: $E6 $1F
    jr   nz, .jp_26E1                             ; $269A: $20 $45
    ld   a, [wDialogNextChar]                     ; $269C: $FA $C3 $C3
    cp   $00                                      ; $269F: $FE $FF
    jp   z, DialogDrawNextCharacterHandler.end    ; $26A1: $CA $AD $25
    cp   $01                                  ; $26A4: $FE $FE
    jp   z, DialogDrawNextCharacterHandler.choice ; $26A6: $CA $95 $25
    ld   a, [wDialogIsWaitingForButtonPress]      ; $26A9: $FA $CC $C1
    and  a                                        ; $26AC: $A7
    jr   nz, .dialogButtonPressHandler            ; $26AD: $20 $07
    inc  a                                        ; $26AF: $3C
    ld   [wDialogIsWaitingForButtonPress], a      ; $26B0: $EA $CC $C1
    call DialogDrawNextCharacterHandler.endDialog ; $26B3: $CD $9F $25

.dialogButtonPressHandler
    call func_27BB                                ; $26B6: $CD $BB $27
    ldh  a, [hJoypadState]                        ; $26B9: $F0 $CC
    bit  J_BIT_A, a                               ; $26BB: $CB $67
    jr   nz, .jp_26E1                             ; $26BD: $20 $22
    bit  J_BIT_B, a                               ; $26BF: $CB $6F
    jr   z, DialogScrollingStartHandler           ; $26C1: $28 $51
    ; The following code looks up whether the
    ; current dialog can be skipped with the B
    ; button, but this information is only used
    ; if __SKIP_DIALOG_SUPPORT__ is set.
    ; Check: safe (same bank)
    ; ld   a, BANK(DialogBankTable)                 ; $26C3: $3E $1C
    ; ld   [rSelectROMBank], a                      ; $26C5: $EA $00 $21
    ld   a, [wGameplayType]                       ; $26C8: $FA $95 $DB
    cp   GAMEPLAY_WORLD_MAP                       ; $26CB: $FE $07
    jp   z, SkipDialog                            ; $26CD: $CA $8B $27
    ld   a, [wDialogIndex]                        ; $26D0: $FA $73 $C1
    ld   e, a                                     ; $26D3: $5F
    ld   a, [wDialogIndexHi]                      ; $26D4: $FA $12 $C1
    ld   d, a                                     ; $26D7: $57
    ld   hl, DialogBankTable                      ; $26D8: $21 $41 $47
    add  hl, de                                   ; $26DB: $19
IF __SKIP_DIALOG_SUPPORT__
    bit  7, [hl]
ELSE
    ld   a, [hl]                                  ; $26DC: $7E
    and  a                                        ; $26DD: $A7
ENDC
    jp   z, SkipDialog                            ; $26DE: $CA $8B $27

.jp_26E1
    ; Build a draw command for the dialog background

    ; e = (wDialogState == DIALOG_CLOSED ? 0 : 1)
    ld   e, $00                                   ; $26E1: $1E $00
    ld   a, [wDialogState]                        ; $26E3: $FA $9F $C1
    and  DIALOG_BOX_BOTTOM_FLAG                   ; $26E6: $E6 $80
    jr   z, .closed                               ; $26E8: $28 $01
    inc  e                                        ; $26EA: $1C
.closed

    ld   d, $00                                   ; $26EB: $16 $00
    ld   hl, data_2693                            ; $26ED: $21 $93 $26
    add  hl, de                                   ; $26F0: $19
    ld   a, [wBGOriginHigh]                       ; $26F1: $FA $2E $C1
    add  a, [hl]                                  ; $26F4: $86
    ld   [wDrawCommand.destinationHigh], a        ; $26F5: $EA $01 $D6
    ld   hl, data_2691                            ; $26F8: $21 $91 $26
    add  hl, de                                   ; $26FB: $19
    ld   a, [wBGOriginLow]                        ; $26FC: $FA $2F $C1
    add  a, [hl]                                  ; $26FF: $86
    ld   [wDrawCommand.destinationLow], a         ; $2700: $EA $02 $D6
    ld   a, DC_FILL_ROW | $0F                     ; $2703: $3E $4F
    ld   [wDrawCommand.length], a                 ; $2705: $EA $03 $D6
    ldh  a, [hDialogBackgroundTile]               ; $2708: $F0 $E8
    ld   [wDrawCommand.length+ 1], a              ; $270A: $EA $04 $D6
    xor  a                                        ; $270D: $AF
    ld   [wDrawCommand.data + 1], a               ; $270E: $EA $05 $D6
IF __OPTIMIZATIONS_2__
    jp   IncrementDialogState
ELSE
    call IncrementDialogState                     ; $2711: $CD $85 $24
    ; fallthrough
ENDC

DialogScrollingStartHandler::
    ret                                           ; $2714: $C9

data_2715:: ; BGOriginLow
    db $62 ; top
    db $82 ; bottom                                  ; $2715

data_2717:: ; BGOriginHigh
    db $98 ; top
    db $99 ; bottom                                  ; $2717

; Scroll dialog line?
DialogBeginScrolling::
    ld   e, $00                                   ; $2719: $1E $00
    ld   a, [wDialogState]                        ; $271B: $FA $9F $C1
    and  DIALOG_BOX_BOTTOM_FLAG                   ; $271E: $E6 $80
    jr   z, label_2723                            ; $2720: $28 $01
    inc  e                                        ; $2722: $1C

label_2723::
    ld   d, $00                                   ; $2723: $16 $00
    ld   hl, data_2717                            ; $2725: $21 $17 $27
    add  hl, de                                   ; $2728: $19
    ld   a, [wBGOriginHigh]                       ; $2729: $FA $2E $C1
    add  a, [hl]                                  ; $272C: $86
    ld   b, a                                     ; $272D: $47
    ld   hl, data_2715                            ; $272E: $21 $15 $27

label_2731::
    add  hl, de                                   ; $2731: $19
    ld   a, [wBGOriginLow]                        ; $2732: $FA $2F $C1
    add  a, [hl]                                  ; $2735: $86
    ld   c, a                                     ; $2736: $4F
    ld   e, $10                                   ; $2737: $1E $10

label_2739::
    ld   a, c                                     ; $2739: $79
    sub  a, $20                                   ; $273A: $D6 $20
    ld   l, a                                     ; $273C: $6F
    ld   h, b                                     ; $273D: $60
    ld   a, [bc]                                  ; $273E: $0A
    ld   [hl], a                                  ; $273F: $77
    push bc                                       ; $2740: $C5
    ld   a, c                                     ; $2741: $79
    add  a, $20                                   ; $2742: $C6 $20
    ld   c, a                                     ; $2744: $4F
    ld   a, l                                     ; $2745: $7D
    add  a, $20                                   ; $2746: $C6 $20
    ld   l, a                                     ; $2748: $6F
    ld   a, [bc]                                  ; $2749: $0A
    ld   [hl], a                                  ; $274A: $77
    ld   a, l                                     ; $274B: $7D
    add  a, $20                                   ; $274C: $C6 $20
    ld   l, a                                     ; $274E: $6F
    ldh  a, [hDialogBackgroundTile]               ; $274F: $F0 $E8
    ld   [hl], a                                  ; $2751: $77
    pop  bc                                       ; $2752: $C1
    inc  bc                                       ; $2753: $03
    ld   a, c                                     ; $2754: $79
    and  $1F                                      ; $2755: $E6 $1F
    jr   nz, label_275D                           ; $2757: $20 $04
    ld   a, c                                     ; $2759: $79
    sub  a, $20                                   ; $275A: $D6 $20
    ld   c, a                                     ; $275C: $4F

label_275D::
    dec  e                                        ; $275D: $1D
    jr   nz, label_2739                           ; $275E: $20 $D9
    ld   a, $08  ; Pause the scrolling for 8 frames ; $2760: $3E $08
    ld   [wDialogScrollDelay], a                  ; $2762: $EA $72 $C1
    jp   IncrementDialogStateAndReturn            ; $2765: $C3 $85 $24

DialogScrollingEndHandler::
    ret                                           ; $2768: $C9

data_2769::
    db $42, $62                                   ; $2769

data_276B::
    db $98, $99                                   ; $276B

DialogFinishScrolling::
    ld   e, 0                                     ; $276D: $1E $00
    ld   a, [wDialogState]                        ; $276F: $FA $9F $C1
    and  DIALOG_BOX_BOTTOM_FLAG                   ; $2772: $E6 $80
    jr   z, label_2777                            ; $2774: $28 $01
    inc  e                                        ; $2776: $1C

label_2777::
    ld   d, $00                                   ; $2777: $16 $00
    ld   hl, data_276B                            ; $2779: $21 $6B $27
    add  hl, de                                   ; $277C: $19
    ld   a, [wBGOriginHigh]                       ; $277D: $FA $2E $C1
    add  a, [hl]                                  ; $2780: $86
    ld   b, a                                     ; $2781: $47
    ld   hl, data_2769                            ; $2782: $21 $69 $27
    call label_2731                               ; $2785: $CD $31 $27
    jp   DialogDrawNextCharacterHandler.nextCharacter ; $2788: $C3 $7E $26

SkipDialog::
    ld   a, $02                                   ; $278B: $3E $02
    ld   [wDialogAskSelectionIndex], a            ; $278D: $EA $77 $C1
    jp   UpdateDialogState                        ; $2790: $C3 $96 $24

DialogChoiceHandler::
    ; Was A pushed?
    ldh  a, [hJoypadState]                        ; $2793: $F0 $CC
    bit  J_BIT_A, a                               ; $2795: $CB $67
    jp   nz, .jp_27B7                             ; $2797: $C2 $B7 $27
    and  J_RIGHT | J_LEFT                         ; $279A: $E6 $03
    jr   z, .jp_27AA                              ; $279C: $28 $0C
    ld   hl, wDialogAskSelectionIndex             ; $279E: $21 $77 $C1
    ld   a, [hl]                                  ; $27A1: $7E
    inc  a                                        ; $27A2: $3C
    and  $01                                      ; $27A3: $E6 $01
    ld   [hl], a                                  ; $27A5: $77
    ld   a, JINGLE_MOVE_SELECTION                 ; $27A6: $3E $0A
    ldh  [hJingle], a                             ; $27A8: $E0 $F2

.jp_27AA
    ldh  a, [hFrameCounter]                       ; $27AA: $F0 $E7
    and  $10                                      ; $27AC: $E6 $10
    ret  z                                        ; $27AE: $C8
    ; jpsb func_017_7DCC                            ; $27AF: $3E $17 $EA $00 $21 $C3 $CC $7D

    ld   hl, wFarcallParams                       ; $5498: $21 $01 $DE
    ld   a, BANK(func_017_7DCC)                   ; $549B: $3E $21
    ld   [hl+], a                                 ; $549D: $22
    ld   a, HIGH(func_017_7DCC)                   ; $549E: $3E $53
    ld   [hl+], a                                 ; $54A0: $22
    ld   a, LOW(func_017_7DCC)                    ; $54A1: $3E $B6
    ld   [hl+], a                                 ; $54A3: $22
    ld   a, BANK(@)                               ; $54A4: $3E $14
    ld   [wFarcallReturnBank], a                  ; $54A6: $EA $04 $DE
    jp   Farcall                                  ; $54A9: $C3 $D7 $0B
    ret

.jp_27B7
IF __OPTIMIZATIONS_2__
    jp   UpdateDialogState
ELSE
    call UpdateDialogState                        ; $27B7: $CD $96 $24
    ret                                           ; $27BA: $C9
ENDC

func_27BB::
    ; jpsb func_017_7D7C                            ; $27BB: $3E $17 $EA $00 $21 $C3 $7C $7D

    ld   hl, wFarcallParams                       ; $5498: $21 $01 $DE
    ld   a, BANK(func_017_7D7C)                   ; $549B: $3E $21
    ld   [hl+], a                                 ; $549D: $22
    ld   a, HIGH(func_017_7D7C)                   ; $549E: $3E $53
    ld   [hl+], a                                 ; $54A0: $22
    ld   a, LOW(func_017_7D7C)                    ; $54A1: $3E $B6
    ld   [hl+], a                                 ; $54A3: $22
    ld   a, BANK(@)                               ; $54A4: $3E $14
    ld   [wFarcallReturnBank], a                  ; $54A6: $EA $04 $DE
    jp   Farcall                                  ; $54A9: $C3 $D7 $0B
    ret

jr_014_5444:
    xor  a                                        ; $5444: $AF
    ld   [wDialogState], a                        ; $5445: $EA $9F $C1
    ret                                           ; $5448: $C9

DialogOpenAnimationStart::
    ld   a, [wC3C9]                               ; $5449: $FA $C9 $C3
    and  a                                        ; $544C: $A7
    jr   nz, .jr_545A                             ; $544D: $20 $0B

    ld   a, [wLinkMotionState]                    ; $544F: $FA $1C $C1
    cp   LINK_MOTION_MAP_FADE_OUT                 ; $5452: $FE $03
    jr   z, jr_014_5444                           ; $5454: $28 $EE

    cp   LINK_MOTION_MAP_FADE_IN                  ; $5456: $FE $04
    jr   z, jr_014_5444                           ; $5458: $28 $EA

.jr_545A
    ld   a, [wGameplayType]                       ; $545A: $FA $95 $DB
    cp   GAMEPLAY_CREDITS                         ; $545D: $FE $01
    jr   z, .jr_547F                              ; $545F: $28 $1E

    ld   a, [wObjectAffectingBGPalette]           ; $5461: $FA $CB $C3
    and  a                                        ; $5464: $A7
    jr   nz, .jr_547F                             ; $5465: $20 $18

    ldh  a, [hLinkAnimationState]                 ; $5467: $F0 $9D
    cp   LINK_ANIMATION_STATE_GOT_ITEM            ; $5469: $FE $6C
    jr   z, .jr_547F                              ; $546B: $28 $12

    ld   a, $04                                   ; $546D: $3E $04
    ld   [wTransitionSequenceCounter], a          ; $546F: $EA $6B $C1
    ld   a, $E4                                   ; $5472: $3E $E4
    ld   [wBGPalette], a                          ; $5474: $EA $97 $DB
    ld   [wOBJ1Palette], a                        ; $5477: $EA $99 $DB
    ld   a, $1C                                   ; $547A: $3E $1C
    ld   [wOBJ0Palette], a                        ; $547C: $EA $98 $DB

.jr_547F
    ld   a, [wDrawCommand]                        ; $547F: $FA $01 $D6
    and  a                                        ; $5482: $A7
    ret  nz                                       ; $5483: $C0

    ld   hl, wDialogState                         ; $5484: $21 $9F $C1
    inc  [hl]                                     ; $5487: $34
    ldh  a, [hIsGBC]                              ; $5488: $F0 $FE
    and  a                                        ; $548A: $A7
    ret  z                                        ; $548B: $C8

    ld   a, [wGameplayType]                       ; $548C: $FA $95 $DB
    cp   GAMEPLAY_WORLD                           ; $548F: $FE $0B
    ret  nz                                       ; $5491: $C0

    ld   a, [wBGPaletteEffectAddress]             ; $5492: $FA $CC $C3
    cp   $08                                      ; $5495: $FE $08
    ret  c                                        ; $5497: $D8

    ld   hl, wFarcallParams                       ; $5498: $21 $01 $DE
    ld   a, BANK(func_021_53B6)                   ; $549B: $3E $21
    ld   [hl+], a                                 ; $549D: $22
    ld   a, HIGH(func_021_53B6)                   ; $549E: $3E $53
    ld   [hl+], a                                 ; $54A0: $22
    ld   a, LOW(func_021_53B6)                    ; $54A1: $3E $B6
    ld   [hl+], a                                 ; $54A3: $22
    ld   a, BANK(@)                               ; $54A4: $3E $14
    ld   [wFarcallReturnBank], a                  ; $54A6: $EA $04 $DE
    jp   Farcall                                  ; $54A9: $C3 $D7 $0B

Bank1C_DrawSaveSlotName::
    push de                                       ; $4852: $D5
    ld   a, [wDrawCommandsSize]                   ; $4853: $FA $00 $D6
    ld   e, a                                     ; $4856: $5F
    ld   d, $00                                   ; $4857: $16 $00
    ld   hl, wDrawCommand                         ; $4859: $21 $01 $D6
    add  hl, de                                   ; $485C: $19
    add  a, $10                                   ; $485D: $C6 $10
    ld   [wDrawCommandsSize], a                   ; $485F: $EA $00 $D6
    ld   a, b                                     ; $4862: $78
    ldi  [hl], a                                  ; $4863: $22
    ld   a, c                                     ; $4864: $79
    ldi  [hl], a                                  ; $4865: $22
    ld   a, $04                                   ; $4866: $3E $04
    ldi  [hl], a                                  ; $4868: $22
    pop  de                                       ; $4869: $D1
    push de                                       ; $486A: $D5
    ld   a, $05                                   ; $486B: $3E $05

    push af
    ld a, [wDialogCharacterIndex]
    cp NAME_LENGTH
    jr nz, .continue
    pop af
    ; pop de
    jr .skip
.continue
    pop af
    ; xor a
    ; ld [wDialogCharacterOutIndex], a

.drawCharacterRowLoop
    ldh  [hMultiPurpose0], a                      ; $486D: $E0 $D7
    ld   a, [de]                                  ; $486F: $1A
    and  a                                        ; $4870: $A7
    ld   a, DIALOG_BG_TILE_DARK                   ; $4871: $3E $7E
    jr   z, .drawCharacterTile                    ; $4873: $28 $0C
    ld   a, [de]                                  ; $4875: $1A
    ; Not needed anymore with UTF-8
    ; dec  a                                        ; $4876: $3D
    push bc                                       ; $4877: $C5
    push hl                                       ; $4878: $E5
    ; ld   c, a                                     ; $4879: $4F
    ; ld   b, $00                                   ; $487A: $06 $00
    ; call ReadTileValueFromAsciiTable              ; $487C: $CD $25 $0C
    call ReadTileValueFromUTF8Table
    pop  hl                                       ; $487F: $E1
    pop  bc                                       ; $4880: $C1

.skip
.drawCharacterTile

    push af
    ld a, [wDialogCharacterIndex]
    inc a
    ld [wDialogCharacterIndex], a
    cp NAME_LENGTH
    jr nz, .notend
    ld a, $00
    ld [wDialogCharacterIndex], a
    pop af
    pop de
    ; Forcefully end drawing if name length limit is reached
    jr .end

.notend
    pop af

    ldi  [hl], a                                  ; $4881: $22
    inc  de                                       ; $4882: $13
    ldh  a, [hMultiPurpose0]                      ; $4883: $F0 $D7
    dec  a                                        ; $4885: $3D
    jr   nz, .drawCharacterRowLoop                ; $4886: $20 $E5
    ld   a, b                                     ; $4888: $78
    ldi  [hl], a                                  ; $4889: $22
    ld   a, c                                     ; $488A: $79
    sub  a, $20                                   ; $488B: $D6 $20
    ldi  [hl], a                                  ; $488D: $22
    ld   a, $04                                   ; $488E: $3E $04
    ldi  [hl], a                                  ; $4890: $22
    pop  de                                       ; $4891: $D1
    ld   a, $05                                   ; $4892: $3E $05

.end
    ; Jump destination to stop drawing characters

.drawSpacingRowLoop
    ; Draw the empty row above the save slot name;
    ; might contain diacritics
    ldh  [hMultiPurpose0], a                      ; $4894: $E0 $D7
    ld   a, [de]                                  ; $4896: $1A
    and  a                                        ; $4897: $A7

IF LANG_EN
    jr   .selectSpacingTile                       ; $4898: $18 $03
    ; Unreachable code:
    dec  a                                        ; $489A: $3D
    and  $C0                                      ; $489B: $E6 $C0
ELSE
    jr   z, .selectSpacingTile
    dec  a
    push hl
    push bc
    ld   c, a
    ld   b, $00
    call ReadTileValueFromDiacriticsTable
IF __DIACRITICS_SUPPORT__
    ldh  [hDialogBackgroundTile], a
ENDC
    pop  bc
    pop  hl
    cp   $00
ENDC

.selectSpacingTile::
    ; Select what tile to draw above the current character
IF __DIACRITICS_SUPPORT__
    ld   a, DIALOG_BG_TILE_DARK
    jr   z, .drawSpacingTile   ; Jump if no diacritic
    ldh  a, [hDialogBackgroundTile] ; Load value from CodepointToDiacritics table
    cp   2                     ; Check if diacritic had value 2
    ld   a, DIALOG_DIACRITIC_2 ; First diacritic tile
    jr   z, .drawSpacingTile   ; Jump if diacritic 2
    inc  a                     ; DIALOG_DIACRITIC_1
ELIF LANG_FR
    ld   a, DIALOG_BG_TILE_DARK
    jr   z, .drawSpacingTile   ; Jump if no diacritic
    ld   a, DIALOG_DIACRITIC_1 ; Second diacritic tile
ELSE
    ld   a, DIALOG_BG_TILE_DARK                   ; $489D: $3E $7E
    jr   .drawSpacingTile                         ; $489F: $18 $08
    ; Unreachable code, likely early diacritics
    ; support that has been stubbed out:
    ld   a, [de]                                  ; $48A1: $1A
    and  $80                                      ; $48A2: $E6 $80
    ld   a, DIALOG_DIACRITIC_2                    ; $48A4: $3E $C8
    jr   z, .drawSpacingTile                      ; $48A6: $28 $01
    inc  a                                        ; $48A8: $3C
ENDC

.drawSpacingTile::
    ldi  [hl], a                                  ; $48A9: $22
    inc  de                                       ; $48AA: $13
    ldh  a, [hMultiPurpose0]                      ; $48AB: $F0 $D7
    dec  a                                        ; $48AD: $3D
    jr   nz, .drawSpacingRowLoop                  ; $48AE: $20 $E4
    xor  a                                        ; $48B0: $AF
    ld   [hl], a                                  ; $48B1: $77
    ret                                           ; $48B2: $C9

; param a: bank number to read from
; param bc: address to read from
; param hl: address to copy to
CopyTile::
    ld e, $10
.copyTileLoop
    push af
    push hl
    ld h, b
    ld l, c
    ; ld   a, [bc]                                  ; $2633: $0A
    ; ld a, BANK(FontTiles)
    read_byte_from_bank_a_and_return
    pop hl
    ldi  [hl], a                                  ; $2634: $22
    pop af
    inc  bc                                       ; $2635: $03
    dec  e                                        ; $2636: $1D
    jr   nz, .copyTileLoop                        ; $2637: $20 $FA
    ret

; param a: bank number to read from
; param bc: address to read from
; param de: address to copy to
AppendDrawCommand::
    push af
    push de

    ld hl, wDrawCommand
    ld a, [wDrawCommandsSize]
    ld e, a
    add $10
    ld [wDrawCommandsSize], a
    ld d, $00
    add hl, de

    pop de
    ld a, d
    ldi [hl], a
    ld a, e
    ldi [hl], a
    ld a, $10
    ldi [hl], a

    ld e, $10
    pop af
.loop
    push af
    push hl
    ld h, b
    ld l, c
    read_byte_from_bank_a_and_return
    pop hl
    ldi [hl], a
    pop af
    inc bc
    dec e
    jr nz, .loop

    ret


Bank1C_func_001_4CDA::
    push de
    ld   a, [wNameEntryCurrentChar]               ; $4CDA: $FA $A9 $DB
    ld   c, a                                     ; $4CDD: $4F
    ld   b, $00                                   ; $4CDE: $06 $00
    ld   hl, NameEntryCharacterTable              ; $4CE0: $21 $B5 $4B
    add  hl, bc                                   ; $4CE3: $09
    ; ld   a, [hl]                                  ; $4CE4: $7E
    ld a, $01
    read_byte_from_bank_a_and_return

    ld c, a
    ld b, $00
    dec bc
    sla c
    rl b
    sla c
    rl b
    ld hl, TextEntryTable
    add hl, bc
    push hl

    ld   e, a                                     ; $4CE5: $5F
    ld   a, [wSaveSlot]                           ; $4CE6: $FA $A6 $DB
    ld b, $00
    ld   c, a                                     ; $4CE9: $4F
    sla  a                                        ; $4CEA: $CB $27
    sla  a                                        ; $4CEC: $CB $27
    add  a, c                                     ; $4CEE: $81
    ld   c, a                                     ; $4CEF: $4F
    ld   hl, wSaveSlot1Name                       ; $4CF0: $21 $80 $DB
    add  hl, bc                                   ; $4CF3: $09
    ld   a, [wSaveSlotNameCharIndex]              ; $4CF4: $FA $AA $DB
    ld   c, a                                     ; $4CF7: $4F
    add  hl, bc                                   ; $4CF8: $09
    ld   [hl], e                                  ; $4CF9: $73
    ld d, h
    ld e, l

    pop hl

    ld bc, $0000
.char_loop
    ldi a, [hl]
    or a
    jr z, .skip_byte
    ld [de], a
    inc de
    inc c
.skip_byte
    inc b
    ld a, b
    cp $04
    jr nz, .char_loop

; Increment cursor index
    ; ld hl, wSaveSlotNameCharIndex
    ; ld a, d
    ; ldi [hl], a
    ; ld a, e
    ; ld [hl], a
.end
    pop de
    ret                                           ; $4CFA: $C9
