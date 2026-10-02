# Bonus01

This level may have been the biggest headache of this project, but here's how to "find" the flag :

First, we are presented with an unreadable, unwritable and unexecutable file in `/opt/snowcrash/bonus01/ng` :
```bash
$ ls -la /opt/snowcrash/bonus01
total 28
drwxr-xr-x  2 root        root         4096 Jun  9 19:04 .
drwxr-xr-x 18 root        root         4096 Jun  9 19:04 ..
-rwxr-x---  1 flagbonus01 flagbonus01 16936 Jun  9 19:04 ng
```

This means, no `strings`, no `strace`, no `objdump`. `ng` is a black box. Thankfully, we have a systemd service that allows us to know more about it :
```ini
$ systemctl cat ng.service 2>/dev/null
# /etc/systemd/system/ng.service
[Unit]
Description=Snow Crash bonus01 — NG shared-memory channel daemon
After=network.target

[Service]
Type=forking
User=flagbonus01
Group=flagbonus01
ExecStart=/opt/snowcrash/bonus01/ng
Restart=always
RestartSec=5

# Allow the daemon to create /dev/shm/ng_channel world-writable.
# The binary calls shm_open with O_CREAT | O_TRUNC and mode 0666;
# the kernel applies the process umask before storing the mode bits,
# so we must clear the umask entirely.
UMask=0000

# Keep a PID file so forking detection works correctly.
# (The binary double-forks; systemd tracks the final child via cgroup.)
KillMode=control-group

[Install]
WantedBy=multi-user.target

```

The service is launched by `flagbonus01`, which is probably our entrypoint.
We learn that `ng` has some kind of link with the shared-memory file `/dev/shm/ng_channel`. This file is set to 64 bytes, all zeroes. We can write inside, but nothing happens.

If we do the following command :
```bash
inotifywait -m \
  -e open,modify,close \
  --format '%T %e' \
  --timefmt '%s.%N' \
  /dev/shm/ng_channel
```
we learn that there is no access after the initial set to 0. We can either assume that the file is never read, or `ng` reads through `mmap`. Let's try to truncate the file size and look at file access with `inotify` :

```python
import subprocess, time

p = "/dev/shm/ng_channel"

for size in range(0,100):
    with open(p, "r+b", buffering=0) as f:
        f.truncate(size)

    try:
        pid = subprocess.check_output(
            ["pgrep", "-u", "flagbonus01", "-x", "ng"],
            text=True
        ).strip()
    except subprocess.CalledProcessError:
        pid = "ABSENT"

    print(f"{size:2d} -> {pid}")
```

With this, we learn that if the file is truncated to a size of 0, `ng` crashes, but does nothing if set to a different size. A crash for a size of 0 might be because of an unchecked `mmap` usage. Well we can hope anyway.

Nothing is readable anywhere, the only interaction we have is with `/dev/shm/ng_channel`. We can assume of a protocol-like message to share with the service. Let's check maybe for a command or magic number in the first 8 bits. With the tests above, it seems it takes 1 to 2 seconds for `ng` to read, so let's do a slow script that runs with a very small rainbow table that fits the spirit of our school :

```python
#!/usr/bin/env python3

import mmap
import os
import struct
import time

SHM = "/dev/shm/ng_channel"

# Little rainbow table
parts = [
    0x0042,
    0x4242,
    0x1234,
    0x1337,
    0x4321,
]

fd = os.open(SHM, os.O_RDWR)
shm = mmap.mmap(
    fd, 64,
    mmap.MAP_SHARED,
    mmap.PROT_READ | mmap.PROT_WRITE,
)

for hi in parts:
    for lo in parts:
        magic = (hi << 16) | lo

        print(f"[*] Trying 0x{magic:08x} ...")

        shm[0:4] = struct.pack("<I", magic)
        shm.flush()

        time.sleep(2)

        # If the daemon answered, it must have changed our protocol
        current = struct.unpack("<I", shm[0:4])[0]

        if current != magic:
            print(f"[+] Something happened: 0x{current:08x}")
            data = bytes(shm[:64])

            print("\n[+] ASCII:")
            print("".join(chr(b) if 32 <= b < 127 else "." for b in data))

            raise SystemExit

print("[-] Nothing found...")

shm.close()
os.close(fd)
```

Well, would you look at that ! It outputs :

```bash
$ python3 lol.py 
[*] Trying 0x00420042 ...
[*] Trying 0x00424242 ...
[*] Trying 0x00421234 ...
[*] Trying 0x00421337 ...
[*] Trying 0x00424321 ...
[*] Trying 0x42420042 ...
[*] Trying 0x42424242 ...
[*] Trying 0x42421234 ...
[*] Trying 0x42421337 ...
[*] Trying 0x42424321 ...
[*] Trying 0x12340042 ...
[*] Trying 0x12344242 ...
[*] Trying 0x12341234 ...
[*] Trying 0x12341337 ...
[*] Trying 0x12344321 ...
[*] Trying 0x13370042 ...
[+] Something happened: 0x00000000

[+] ASCII:
............fa6v5ateaw21peobuub8ipe6s...........................
```

And just like that, we have the flag : fa6v5ateaw21peobuub8ipe6s