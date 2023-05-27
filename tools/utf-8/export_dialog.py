
import sys
import yaml

def main(input_file, output_file):
    with open(input_file, 'r') as f:
        content = f.read()
    content = content.split('\n')
    result = {}
    current_label = ''
    for line in content:
        if line.endswith('::'):
            current_label = line[:-2]
            result[current_label] = []
        elif line.strip().startswith('db'):
            chars = line.strip()[2:].split(',')
            chars = [int(c.strip()[1:], 16) for c in chars]
            chars = bytearray(chars)
            result[current_label].append(chars.decode('utf-8'))

    result = {key: '\n'.join(value) for key, value in result.items()}
    with open(output_file, 'w') as f:
        yaml.dump(result, f, allow_unicode=True)

if __name__ == '__main__':
    args = sys.argv[1:]
    input_file, output_file = args[:2]
    main(input_file, output_file)