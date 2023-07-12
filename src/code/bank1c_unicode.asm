
macro read_next_byte_with_preserving_de
    pop de
    inc de
    call ReadNextByte
    push de
endm

; param l: mode ($00 = dialog, $01 = name (in dialog), $02 = tile)
; return e: codepoint, highest 1 byte
; return bc: codepoint, lower 2 bytes
GetUTF8Char::
    ; We need to keep de value for '.file_menu' mode
    push de
    ld e, $00
    ld h, $00

    bit 7, a
    jr z, .singleByte
    bit 6, a
    jp z, .endUTF8
    bit 5, a
    jr z, .doubleByte
    bit 4, a
    jr z, .tripleByte
    bit 3, a
    jr z, .quadByte
    jr .endUTF8

.quadByte
    and a, $07
    rlca
    rlca
    ld e, a
    read_next_byte_with_preserving_de
    push af
    and a, $30
    rrca
    rrca
    rrca
    rrca
    or h
    ld e, a
    pop af
    and a, $0f
    rlca
    rlca
    rlca
    rlca
    ld b, a
    read_next_byte_with_preserving_de
    push af
    and a, $3c
    rrca
    rrca
    or b
    ld b, a
    jr .lastByte
.tripleByte
    and a, $0f
    rlca
    rlca
    rlca
    rlca
    ld b, a
    read_next_byte_with_preserving_de
    push af
    and a, $3c
    rrca
    rrca
    or b
    ld b, a
    jr .lastByte
.doubleByte
    push af
    and a, $1c
    rrca
    rrca
    ld b, a
    jr .lastByte
.lastByte
    pop af
    and a, $03
    rrca
    rrca
    ld c, a
    read_next_byte_with_preserving_de
    and a, $3f
    or c
    ld c, a
    jr .endUTF8
.singleByte
    and a, $7f
    ld b, $00
    ld c, a
.endUTF8
    pop de
    ret

ReadNextByte::
    push af
    ld a, l
    and a
    jr z, .dialog
    cp a, $01
    jr z, .name
    cp a, $02
    jr z, .file_menu
    ; safety
    pop af
    ret

.dialog
    pop af
    call IncrementAndReadNextChar
    ret

.name
    pop af
    push hl
    push de
    ld d, $00
    ld hl, wNameIndex
    ld a, [hl]
    ld e, a
    inc a
    ld [wNameIndex], a
    ld hl, wName
    add hl, de
    ld a, [hl]
    pop de
    pop hl
    ret

.file_menu
    pop af
    ld a, [de]
    push hl
    ld hl, wDialogCharacterOutIndex
    inc [hl]
    pop hl
    ret

GetFontAddr::
    call GetFontId
    call GetFontOffset
    ret

; param h: codepoint, highest 1 byte
; param bc: codepoint, lower 2 bytes
GetFontId::
    ; calculate bank number
    ld a, h
    and a, $1f
    rlca
    rlca
    rlca
    ld h, a
    ld a, b
    and a, $e0
    rrca
    rrca
    rrca
    rrca
    rrca
    or a, h

    add a, BANK(gfx_font_unicode_table)
    push af
    sla c
    rl b
    ld a, b
    and a, $3f
    or a, $40
    ld h, a
    ld l, c
    pop af
    push af
    
    read_byte_from_bank_a_and_return
    ld b, a
    pop af
    push af
    inc hl
    read_byte_from_bank_a_and_return
    ld c, a
    pop af

    ret

GetFontOffset::
    ld a, b
    and a, $fc
    rrca
    rrca
    add a, BANK(gfx_font_unicode)
    push af
    ld a, b
    and a, $03
    ld h, a
    ld a, c
    ld l, a

    sla l
    rl h
    sla l
    rl h
    sla l
    rl h
    sla l
    rl h

    ld a, h
    add a, $40
    ld h, a
    pop af
    
    ret