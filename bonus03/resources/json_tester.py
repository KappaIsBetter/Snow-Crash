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

    time.sleep(0.15)

print("[+] Finished.")
