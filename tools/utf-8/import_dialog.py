
import sys
import yaml

def convert_char(c):
    if c == '@':
        return '\0'
    return c

def main(input_file, output_file):
    with open(input_file, 'r') as f:
        content = yaml.load(f, Loader=yaml.FullLoader)
    
    result = []
    for key, value in content.items():
        result.append(key + '::')
        for line in value.split('\n'):
            chars = ''.join([convert_char(c) for c in line])
            chars = list(chars.encode('utf-8'))
            if len(chars) == 0:
                continue
            chars = ['$%02x' % c for c in chars]
            chars = ' '*4 + 'db ' + ', '.join(chars)
            result.append(chars)

    result = '\n'.join(result)
    with open(output_file, 'w') as f:
        f.write(result)

if __name__ == '__main__':
    args = sys.argv[1:]
    input_file, output_file = args[:2]
    main(input_file, output_file)