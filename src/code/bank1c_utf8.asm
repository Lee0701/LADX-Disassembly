
; param l: mode ($00 = dialog, $01 = tile)
GetUTF8Char::
    push de
    ld e, $00

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
    call PreQuadByte
    call ReadNextByte
    push af
    call MidQuadByte1
    pop af
    call MidQuadByte2
    call ReadNextByte
    push af
    call PostQuadByte
    jr .lastByte
.tripleByte
    call PreTripleByte
    call ReadNextByte
    push af
    call PostTripleByte
    jr .lastByte
.doubleByte
    push af
    call DoubleByte
    jr .lastByte
.lastByte
    pop af
    call PreLastByte
    call ReadNextByte
    call PostLastByte
    jr .endUTF8
.singleByte
    call SingleByte
.endUTF8
    pop de
    ret

SingleByte::
    and a, $7f
    ld b, $00
    ld c, a
    ret

DoubleByte::
    and a, $1c
    rrca
    rrca
    ld b, a
    ret

PreTripleByte::
    and a, $0f
    rlca
    rlca
    rlca
    rlca
    ld b, a
    ret

PostTripleByte::
    and a, $3c
    rrca
    rrca
    or b
    ld b, a
    ret

PreQuadByte::
    and a, $07
    rlca
    rlca
    ld e, a
    ret

MidQuadByte1::
    and a, $30
    rrca
    rrca
    rrca
    rrca
    or e
    ld e, a
    ret

MidQuadByte2::
    and a, $0f
    rlca
    rlca
    rlca
    rlca
    ld b, a
    ret

PostQuadByte::
    and a, $3c
    rrca
    rrca
    or b
    ld b, a
    ret

PreLastByte::
    and a, $03
    rrca
    rrca
    ld c, a
    ret

PostLastByte::
    and a, $3f
    or c
    ld c, a
    ret

ReadNextByte::
    push af
    ld a, l
    and a
    jr z, .dialog
    cp a, $01
    jr z, .file_menu
    pop af
    ret

.dialog
    pop af
    jp IncrementAndReadNextChar

.file_menu
    pop af
    pop de
    ldh  a, [hMultiPurpose0]
    call FileMenuNextChar
    push de
    ret

GetFontAddr::
    call GetFontId
    call GetFontOffset
    ret

GetFontId::
    ld a, e
    and a, $1f
    rlca
    rlca
    rlca
    ld e, a
    ld a, b
    and a, $e0
    rrca
    rrca
    rrca
    rrca
    rrca
    or a, e

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
    
    call ReadByteFromBankA
    ld b, a
    pop af
    push af
    inc hl
    call ReadByteFromBankA
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
    pop af

    sla l
    rl h
    sla l
    rl h
    sla l
    rl h
    sla l
    rl h

    push af
    ld a, h
    add a, $40
    ld h, a
    pop af
    
    ret
