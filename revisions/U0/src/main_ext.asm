
; Sections are defined in the asm file
; section "bank50",romx,bank[$50]
include "gfx/fonts/font_unicode_table.asm"

DEF BANK_LEN = $4000
DEF BANK_NUM = $60
DEF OFFSET = $0
gfx_font_unicode:
REPT 8
    section "bank{BANK_NUM}",romx,bank[{BANK_NUM}]
    incbin "gfx/fonts/font_unicode.2bpp",OFFSET,BANK_LEN
    REDEF BANK_NUM = BANK_NUM + $1
    REDEF OFFSET = OFFSET + BANK_LEN
ENDR
