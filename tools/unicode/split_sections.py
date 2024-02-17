
import sys

line_prefix = '    db '
base_bank = 0x40

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

def main(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.read().split('\n')
    sections = make_sections(lines)
    output = format_sections(sections)
    with open(output_file, 'w') as f:
        f.write(output)

if __name__ == '__main__':
    args = sys.argv[1:]
    if len(args) < 2:
        print('Usage: python3 {} <input_file> <output_file>'.format(sys.argv[0]))
        sys.exit(1)
    main(args[0], args[1])
