#!/bin/bash

INPUT=weblate/ja/dialog.yaml
OUTPUT=revisions/U8/src/text/dialog.asm

python tools/utf-8/import_dialog.py $INPUT $OUTPUT
python tools/utf-8/split_sections.py $OUTPUT $OUTPUT
