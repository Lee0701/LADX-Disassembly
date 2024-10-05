    ; Used to translate cursor position -> name letter
    ; on the name entry menu. Does not actually represent
    ; the graphics - this is just the letter that is chosen
    ; when you push A
    PUSHC
    SETCHARMAP NameEntryCharmap
    db $00, $31, $32, $33, $34, $35, $00, $00, $00, $00, $36, $37, $38, $39, $30, $00
    db $41, $42, $43, $44, $45, $46, $47, $00, $00, $61, $62, $63, $64, $65, $66, $67
    db $48, $49, $4a, $4b, $4c, $4d, $4e, $00, $00, $68, $69, $6a, $6b, $6c, $6d, $6e
    db $4f, $50, $51, $52, $53, $54, $55, $00, $00, $6f, $70, $71, $72, $73, $74, $75
    db $56, $57, $58, $59, $5a, $00, $00, $00, $00, $76, $77, $78, $79, $7a, $00, $00
    POPC
