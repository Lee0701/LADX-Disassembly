
macro read_byte_from_bank_a_and_return
    push bc
    ld b, a
    ld c, BANK(@)
    call ReadByteFromBankBAndReturnToC
    pop bc
endm

macro read_next_byte_with_preserving_de
    pop de
    inc de
    call ReadNextByte
    push de
endm

macro call_Bank1C_func_001_4CDA
    ld a, $1c
    ld [rSelectROMBank], a
    call Bank1C_func_001_4CDA
    ld a, $01
    ld [rSelectROMBank], a
endm