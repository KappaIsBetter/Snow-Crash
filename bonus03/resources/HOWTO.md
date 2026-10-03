# Bonus 03

Once again, we have an ELF that we cannot do anything with :

```bash
$ ls -la /opt/snowcrash/bonus03
total 28
drwxr-xr-x  2 root        root         4096 Jun  9 19:04 .
drwxr-xr-x 18 root        root         4096 Jun  9 19:04 ..
-rwxr-x---  1 flagbonus03 flagbonus03 17056 Jun  9 19:04 cic
$ groups
bonus03 levelgroup cic_grp
```

We try to find other files and folders related :

```bash
$ find / -type f -name *cic* -ls 2>/dev/null
   ... # Removed unecesary files
   524497      4 -rw-r--r--   1 root        root             273 Jun  9 19:04 /etc/systemd/system/cic.service
   394441     20 -rwxr-x---   1 flagbonus03 flagbonus03    17056 Jun  9 19:04 /opt/snowcrash/bonus03/cic
```

We have a service, that we can read :

```ini
# /etc/systemd/system/cic.service
[Unit]
Description=Snow Crash bonus03 — CIC inotify spool daemon
After=network.target

[Service]
Type=forking
User=flagbonus03
Group=flagbonus03
ExecStart=/opt/snowcrash/bonus03/cic
Restart=always
RestartSec=5
KillMode=control-group

[Install]
WantedBy=multi-user.target
```

```bash
$ systemctl status cic.service
● cic.service - Snow Crash bonus03 — CIC inotify spool daemon
     Loaded: loaded (/etc/systemd/system/cic.service; enabled; preset: enabled)
     Active: active (running) since Sat 2026-10-03 10:50:48 UTC; 1h 3min left
    Process: 631 ExecStart=/opt/snowcrash/bonus03/cic (code=exited, status=0/SUCCESS)
   Main PID: 668 (cic)
      Tasks: 1 (limit: 14777)
     Memory: 252.0K (peak: 1.6M)
        CPU: 8ms
     CGroup: /system.slice/cic.service
             └─668 /opt/snowcrash/bonus03/cic

Warning: some journal files were not opened due to insufficient permissions.
```

We can note that `cic` is currently running, launched by user `flagbonus03` ! As a spool daemon, we have a spool folder :

```bash
$ ls -lda /var/spool/cic
drwxrwsr-x 2 flagbonus03 cic_grp 4096 Oct  3 09:43 /var/spool/cic
$ ls -la /var/spool/cic
total 8
drwxrwsr-x 2 flagbonus03 cic_grp 4096 Oct  3 09:43 .
drwxr-xr-x 5 root        root    4096 Jun  9 19:04 ..
```

Well, no access anywhere, and no data to be `find`-ed or `grep`-ed... Let's rainbow-table it again, it's not like we have much choice. The service being a `inotify` spool daemon, it must mean that we can catch `open`, `read`, `close` and `access` signals by `inotify-wait`, if it does anything. Let's first try to find a file that it wants to read... Well that's just pure luck. No mention of it anywhere, and even after inputting hundreds of possible filenames, the only one that triggered anything was `delivery.json`. Watching with `inotify-wait` outputs, when we create this file :

```bash
$ inotifywait -m /var/spool/cic
Setting up watches.
Watches established.
/var/spool/cic/ OPEN delivery.json
/var/spool/cic/ ATTRIB delivery.json
/var/spool/cic/ CLOSE_WRITE,CLOSE delivery.json
/var/spool/cic/ OPEN delivery.json
/var/spool/cic/ CLOSE_NOWRITE,CLOSE delivery.json
```

A second open, with `NOWRITE` is done, probably by `cic`... We can safely assume the inside being a JSON object, so let's test for the most obvious ones, and hope for the best :

```python
#!/usr/bin/env python3

import json
import time
import itertools

PAYLOAD = "/var/spool/cic/delivery.json"

keys = [
    "action",
    "command",
    "operation",
    "request",
    "type",
    "task",
    "event",
    "mode",
]

values = [
    "read",
    "get",
    "fetch",
    "show",
    "dump",
    "export",
    "send",
    "write",
    "process",
    "execute",
    "run",
    "dispatch",
    "deliver",
    "submit",
    "request",
    "status",
    "info",
    "list",
    "manifest",
    "record",
    "data",
    "test",
]

tests = []

for key in keys:
    for value in values:
        tests.append({key: value})

for key in keys:
    tests.append({key: "report"})

print(f"[+] Testing {len(tests)} JSON payloads")

for i, payload in enumerate(tests, 1):
    print(f"[{i}/{len(tests)}] {payload}", flush=True)

    try:
        with open(PAYLOAD, "w") as f:
            json.dump(payload, f)
            f.write("\n")
    except OSError as e:
        print(f"[!] Error: {e}")
        break

print("[+] Finished.")
```

and after that, we search for new files :

```bash
$ find / -type f -name *cic* -ls 2>/dev/null
	...
    15504      4 -rw-r--r--   1 flagbonus03 flagbonus03       52 Oct  3 14:19 /tmp/cic_report
   524497      4 -rw-r--r--   1 root        root             273 Jun  9 19:04 /etc/systemd/system/cic.service
   394441     20 -rwxr-x---   1 flagbonus03 flagbonus03    17056 Jun  9 19:04 /opt/snowcrash/bonus03/cic
```

and there is ! If we look inside the file `/tmp/cic_report`, we find the flag : mof3b3iud5c3p35bsv9aua0bj

(After looking more closely and waiting between tests, we find that the culprit is `{ "action": "report" }`. It seems like a sort of cheat, rainbowing our way around like that... But after grepping and finding, there is not any sort of hint anywhere. If we decompile the ova (sorry wil), we can easily find the solution in the `strings` of `cic`. And looking at the code with Ghidra, it's the only way to access the flag... Either the project has a mistake, or half-brute-force is the only solution...)