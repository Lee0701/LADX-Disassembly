
macro read_byte_from_bank_a_hl
    push bc
    ld b, a
    ld c, BANK(@)
    call ReadByteFromBankBAndReturnToC
    pop bc
endm

macro read_byte_from_bank_a_de
    push hl
    ld h, d
    ld l, e
    push bc
    ld b, a
    ld c, BANK(@)
    call ReadByteFromBankBAndReturnToC
    pop bc
    pop hl
endm

macro read_next_byte
    inc de
    call ReadNextByte
endm
