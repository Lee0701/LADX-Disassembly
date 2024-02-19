
include "constants/macros_ext.asm"

section "bank1C_ext",romx,bank[$1C]
include "data/text_entry_table.asm"
include "code/bank1c_unicode.asm"
include "code/bank1c_text.asm"

; Sections are defined in the asm file
; section "bank40",romx,bank[$40]
include "text/dialog.asm"

; Sections are defined in the asm file
; section "bank50",romx,bank[$50]
include "gfx/fonts/font_unicode_table.asm"

section "bank80",romx,bank[$80]
gfx_font_unicode:
incbin "gfx/fonts/font_unicode.2bpp",$0,$4000
DEF BANK_LEN = $4000
DEF BANK_NUM = $81
DEF OFFSET = $4000
REPT 7
    section "bank{BANK_NUM}",romx,bank[{BANK_NUM}]
    incbin "gfx/fonts/font_unicode.2bpp",OFFSET,BANK_LEN
    REDEF BANK_NUM = BANK_NUM + $1
    REDEF OFFSET = OFFSET + BANK_LEN
ENDR
