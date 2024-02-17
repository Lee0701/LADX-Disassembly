
macro read_byte_from_bank_a_and_return
    push bc
    ld b, a
    ld c, BANK(@)
    call ReadByteFromBankBAndReturnToC
    pop bc
endm
