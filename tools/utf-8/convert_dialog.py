
import sys

line_prefix = '    db '
base_bank = 0x40

text_end = 0x00
text_end_ask = 0x01
player_name = 0x02

replacements = {
    "<dpad>": 0xe006,
    "<letter>": 0xe007,
    "<yoshi>": 0xe008,
    "<flower>": 0xe009,
    "<footprint>": 0xe00a,
    "Ｘ": 0xe00b,
    "<skull>": 0xe00c,
    "<link>": 0xe00d,
    "<marin>": 0xe00e,
    "<tarin>": 0xe00f,
    "<ribbon>": 0xe010,
    "<dogfood>": 0xe011,
    "<bananas>": 0xe012,
    "<stick>": 0xe013,
    "<honeycomb>": 0xe014,
    "<pineapple>": 0xe015,
    "<broom>": 0xe016,
    "<fishhook>": 0xe017,
    "<bra>": 0xe018,
    "<scale>": 0xe01b,
    "<glass>": 0xe01c,
    "<up>": 0xe01b,
    "<down>": 0xe01c,
    "<left>": 0xe01d,
    "<right>": 0xe01e,
}

def replace_icons(text):
    for icon, replacement in replacements.items():
        text = text.replace(icon, chr(replacement))
    return text

def process_line(line):
    if not line.startswith(line_prefix):
        return line
    line_content = line.replace(line_prefix, '')[1:-1]
    line_content = replace_icons(line_content)
    utf8 = line_content.encode('utf-8')
    if ord('#') in utf8:
        utf8 = [player_name if c == ord('#') else c for c in list(utf8)]
        utf8 = bytes(utf8)
    if line_content.endswith('<ask>'):
        utf8 = utf8[:-5] + bytes([text_end_ask])
    if line_content.endswith('@'):
        utf8 = utf8[:-1] + bytes([text_end])
    return line_prefix + ', '.join(['$' + hex(c)[2:].zfill(2) for c in utf8])

def make_sections(lines):
    sections = []
    section = [[]]
    section_len = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip() == '':
            i += 1
        elif line.endswith('::'):
            if len(section[-1]) > 0:
                section.append([])
            section[-1].append(line)
            i += 1
        elif line.startswith(line_prefix):
            section[-1].append(line)
            section_len += line.count('$')
            i += 1
        if section_len > 0x4000:
            current_text = section[-1]
            sections.append(section[:-1])
            print('$' + hex(base_bank + len(sections))[2:], current_text[0][:-2])
            section = [current_text]
            section_len = ''.join(current_text).count('$')

    sections.append(section)

    return sections

def format_sections(sections):
    result = []
    for i, section in enumerate(sections):
        bank = base_bank + i
        section_header = '\nsection "bank%x",romx[$4000],bank[$%x]' % (bank, bank)
        result.append(section_header)
        for text in section:
            for line in text:
                result.append(line)
    return '\n'.join(result)

def main(input_files, output_file):
    lines = '\n'.join([open(filename, 'r').read() for filename in input_files]).split('\n')
    lines = [process_line(line) for line in lines]
    sections = make_sections(lines)
    output = format_sections(sections)
    with open(output_file, 'w') as f:
        f.write(output)

if __name__ == '__main__':
    args = sys.argv[1:]
    if len(args) < 2:
        print('Usage: python3 {} <input_file_0,include_file_1,...> <output_file>'.format(sys.argv[0]))
        sys.exit(1)
    input_files = [arg.strip() for arg in args[0].split(',')]
    main(input_files, args[1])
