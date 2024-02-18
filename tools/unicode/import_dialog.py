
import sys
import yaml

def convert_char(c):
    if c == '@' or c == '＠':
        return '\0'
    elif c =='%' or c == '％':
        return '\x01'
    elif c == '#' or c == '＃':
        return '\x02'
    elif c == ' ':
        return '　'
    else:
        return c

def main(base_file, input_file, output_file):
    with open(base_file, 'r') as f:
        base = yaml.load(f, Loader=yaml.FullLoader)
    with open(input_file, 'r') as f:
        content = yaml.load(f, Loader=yaml.FullLoader)
    
    result = []
    for key, base_value in base.items():
        value = content[key] if key in content else base_value
        result.append(key + '::')
        for line in value.split('\n'):
            chars = ''.join([convert_char(c) for c in line])
            if '\0' not in chars:
                chars = chars.ljust(16, '　')
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
    base_file,  input_file, output_file = args[:3]
    main(base_file, input_file, output_file)
