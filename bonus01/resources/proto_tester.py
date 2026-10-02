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