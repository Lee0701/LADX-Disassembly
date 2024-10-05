
include "constants/macros_ext.asm"

section "bank1C_ext",romx,bank[$1C]
include "data/text_entry_table.asm"
include "code/bank1c_unicode.asm"
include "code/bank1c_text.asm"

; Sections are defined in the asm file
; section "bank40",romx,bank[$40]
include "gfx/fonts/font_unicode_table.asm"

; Sections are defined in the asm file
; section "bank60",romx,bank[$60]
include "text/dialog.asm"

DEF BANK_LEN = $4000
DEF BANKS = 11
DEF BANK_NUM = $70
DEF OFFSET = $0

section "bank80",romx,bank[BANK_NUM]
gfx_font_unicode:
incbin "gfx/fonts/font_unicode.2bpp",OFFSET,BANK_LEN
REPT BANKS - 1
    REDEF BANK_NUM = BANK_NUM + $1
    REDEF OFFSET = OFFSET + BANK_LEN
    section "bank{BANK_NUM}",romx,bank[BANK_NUM]
    incbin "gfx/fonts/font_unicode.2bpp",OFFSET,BANK_LEN
ENDR
