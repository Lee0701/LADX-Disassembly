
import sys

line_prefix = '    db '

def process_line(line):
    if not line.startswith(line_prefix):
        return line
    line_content = line.replace(line_prefix, '')[1:-1]
    if line_content == '@':
        return line_prefix + '$ff'
    line_content = line_content.encode('utf-8')
    return line_prefix + ', '.join(['$' + hex(c)[2:] for c in line_content])

def main(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()
    lines = [process_line(line[:-1]) for line in lines]
    output = '\n'.join(lines)
    with open(output_file, 'w') as f:
        f.write(output)

if __name__ == '__main__':
    args = sys.argv[1:]
    if len(args) < 2:
        print('Usage: python3 {} <input_file> <output_file>'.format(sys.argv[0]))
        sys.exit(1)
    main(args[0], args[1])
