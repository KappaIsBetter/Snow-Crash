# -- hash_start.py --

# Hash function of JS script
def h(s):
    x = 0x811c9dc5
    for c in s:
        x = ((x ^ ord(c)) * 0x01000193) & 0xffffffff
    return x

# Converting to base 36
def b36(n):
    chars = "0123456789abcdefghijklmnopqrstuvwxyz"
    out = ""
    while n:
        n, r = divmod(n, 36)
        out = chars[r] + out
    return out or "0"

for i in range(256):
    xx = f"{i:02x}"
    if b36(h("1" + xx)) == "teo3gp":
        print("XX =", xx)