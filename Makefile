.POSIX:
.SUFFIXES:
.PRECIOUS: %.2bpp oam_%.2bpp
.PHONY: default build build-all test test-all all clean

#
# Dev tools binaries and options
#

2BPP    := rgbgfx
ASM     := rgbasm
PYTHON  := python

# Get assembler version
ASMVER    := $(shell $(ASM) --version | cut -f2 -dv)
ASMVERMAJ := $(shell echo $(ASMVER) | cut -f1 -d.)
ASMVERMIN := $(shell echo $(ASMVER) | cut -f2 -d.)

# Abort if RGBDS version is too low and 'clean' is not the only target
ifneq ($(MAKECMDGOALS), "clean")
  ifeq ($(shell expr \
    \( $(ASMVERMAJ) = 0 \) \&\
    \( $(ASMVERMIN) \< 5 \)\
  ), 1)
    $(error Requires RGBDS version >= 0.5.0)
  endif
endif

ASFLAGS := --export-all

# If we're using RGBDS >= 0.6.0, add flags to force behavior that used to be default
ifeq ($(shell expr \
  \( $(ASMVERMAJ) \> 0 \) \|\
  \(\
    \( $(ASMVERMAJ) = 0 \) \&\
    \( $(ASMVERMIN) \> 5 \)\
  \)\
), 1)
  ASFLAGS += \
    --auto-ldh\
    --nop-after-halt
endif

LD      := rgblink
LDFLAGS :=

FX      := rgbfix
FXFLAGS := \
  --color-compatible \
  --sgb-compatible \
  --ram-size 0x03 \
  --old-licensee 0x33 \
  --new-licensee "01" \
  --mbc-type 0x1B \
  --pad-value 0xFF \
  --validate

# Default target: build and test only the US 1.0 revision.
# (Use `make all` to build and test all targets.)
default: all

#
# Generic rules
#

# Dependencies for the base version (English 1.0)
asm_files =  $(shell find src     -type f -name '*.asm' -o -name '*.inc')
gfx_files =  $(shell find src/gfx -type f -name '*.png')
bin_files =  $(shell find src     -type f -name '*.tilemap.encoded' -o -name '*.attrmap.encoded')

# Compile an PNG file for OAM memory to a 2BPP file
# (inverting the palette and de-interleaving the tiles).
oam_%.2bpp: oam_%.png
	tools/gfx/gfx.py --invert --interleave --out $@ 2bpp $<

# Compile a PNG file to a 2BPP file, without any special conversion.
# (This typically uses `rgbgfx`, which is much faster than the
# Python-based `gfx.py`.)
%.2bpp: %.png
	$(2BPP) -o $@ $<

# Compile all dependencies (ASM, 2BPP) into an single object file.
# (This means all the source code is always fully recompiled: for now,
# we don't compile the different ASM files separately.)
# Locale-specific rules below (e.g. `src/main.azlj.o`) will add their own
# pre-requisites to the ones defined by this rule.
src/main.%.o: src/main.asm $(asm_files) $(gfx_files:.png=.2bpp) $(bin_files)
	$(ASM) $(ASFLAGS) $($*_ASFLAGS) -i src/ -o $@ $<

# Link object files into a GBC executable rom
# The arguments used are both the global options (e.g. `LDFLAGS`) and the
# locale-specific options (e.g. `azlg-r1_LDFLAGS`).
%.gbc: src/main.%.o
	$(LD) $(LDFLAGS) $($*_LDFLAGS) -n $*.sym -o $@ $^
	$(FX) $(FXFLAGS) $($*_FXFLAGS) $@

# Make may attempt to re-generate the Makefile; prevent this.
Makefile: ;

#
# UTF-8 (ko_KORE)
#

azuk_lang = ko_KORE
base_lang = ja

azuk_asm = $(shell find revisions/K8 -type f -name '*.asm')
azuk_gfx = $(shell find revisions/K8 -type f -name '*.png')
azuk_bin = $(shell find revisions/K8 -type f -name '*.tilemap.encoded' -o -name '*.attrmap.encoded')

azuk_src_dir = revisions/K8/src
azuk_font_dir = $(azuk_src_dir)/gfx/fonts
azuk_font_png = $(azuk_font_dir)/font_unicode.png
azuk_font_bin = $(azuk_font_dir)/font_unicode.2bpp
azuk_font_table = $(azuk_font_dir)/font_unicode_table.asm

$(azuk_src_dir)/data/backgrounds/menu_file_creation.tilemap.encoded: $(azuk_src_dir)/data/backgrounds/menu_file_creation.tilemap.decoded
	$(PYTHON) tools/convert_background.py encode -o $@ $<

$(azuk_font_table) $(azuk_font_png): revisions/K8/src/font/fontset.yaml
	mkdir -p $(azuk_font_dir)
	$(PYTHON) tools/utf-8/generate_fontset.py $< $(azuk_font_table) $(azuk_font_png) 50

$(azuk_font_bin): $(azuk_font_png) $(azuk_font_table)
	mkdir -p $(azuk_font_dir)
	$(2BPP) -o $@ $<

azuk_text = revisions/K8/src/text/dialog.asm
$(azuk_text): weblate/$(azuk_lang)/dialog.yaml weblate/$(base_lang)/dialog.yaml $(azuk_font_bin)
	$(PYTHON) tools/utf-8/import_dialog.py weblate/$(base_lang)/dialog.yaml $< $@
	$(PYTHON) tools/utf-8/split_sections.py $@ $@

games += azuk-r2.gbc
src/main.azuk-r2.o: $(azuk_font_bin) $(azuk_font_table) $(azuk_text) $(azuk_asm) $(azuk_gfx:.png=.2bpp) $(azuk_bin)
azuk-r2_ASFLAGS = -DLANG=JP -DVERSION=2 -i revisions/K8/src/
azuk-r2_FXFLAGS = --rom-version 2 --title "ZELDA" --game-id "azuk"

#
# UTF-8 (ja_JPAN)
#

azuj_lang = ja_JPAN
base_lang = ja

azuj_asm = $(shell find revisions/J8 -type f -name '*.asm')
azuj_gfx = $(shell find revisions/J8 -type f -name '*.png')
azuj_bin = $(shell find revisions/J8 -type f -name '*.tilemap.encoded' -o -name '*.attrmap.encoded')

azuj_src_dir = revisions/J8/src
azuj_font_dir = $(azuj_src_dir)/gfx/fonts
azuj_font_png = $(azuj_font_dir)/font_unicode.png
azuj_font_bin = $(azuj_font_dir)/font_unicode.2bpp
azuj_font_table = $(azuj_font_dir)/font_unicode_table.asm

$(azuj_font_table) $(azuj_font_png): revisions/J8/src/font/fontset.yaml
	mkdir -p $(azuj_font_dir)
	$(PYTHON) tools/utf-8/generate_fontset.py $< $(azuj_font_table) $(azuj_font_png) 50

$(azuj_font_bin): $(azuj_font_png) $(azuj_font_table)
	mkdir -p $(azuj_font_dir)
	$(2BPP) -o $@ $<

azuj_text = revisions/J8/src/text/dialog.asm
$(azuj_text): weblate/$(azuj_lang)/dialog.yaml weblate/$(base_lang)/dialog.yaml $(azuj_font_bin)
	$(PYTHON) tools/utf-8/import_dialog.py weblate/$(base_lang)/dialog.yaml $< $@
	$(PYTHON) tools/utf-8/split_sections.py $@ $@

games += azuj-r2.gbc
src/main.azuj-r2.o: $(azuj_font_bin) $(azuj_font_table) $(azuj_text) $(azuj_asm) $(azuj_gfx:.png=.2bpp) $(azuj_bin)
azuj-r2_ASFLAGS = -DLANG=JP -DVERSION=2 -i revisions/J8/src/
azuj-r2_FXFLAGS = --rom-version 2 --title "ZELDA" --game-id "azuj"

#
# Main targets
#

# By default, build the US 1.0 revision.
build: azuk-r2.gbc

# Build all revisions.
build-all: $(games)

all: build-all

clean:
	rm -f $(games)
	rm -f $(games:%.gbc=src/main.%.o)
	rm -f $(games:.gbc=.map)
	rm -f $(games:.gbc=.sym)
	rm -f $(gfx_files:.png=.2bpp)
	rm -f $(azlj_gfx:.png=.2bpp)
	rm -f $(azuj_gfx:.png=.2bpp)
	rm -f $(azuk_gfx:.png=.2bpp)
