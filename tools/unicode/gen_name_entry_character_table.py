
def group_n_elements(L, n):
    return [tuple(L[i:i+n]) for i in range(0, len(L), n)]

src = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽゃゅょっ'

l = ''.join([c + chr(0) for c in src])
l = list(l.encode('utf-8'))
l = ['$%02x' % c for c in l]
grouped = group_n_elements(l, 16)

output = ['    db ' + ', '.join(g) for g in grouped]
output = '\n'.join(output)
print(output)
